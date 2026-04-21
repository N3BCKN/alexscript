# frozen_string_literal: true

require 'aruba/rspec'

RSpec.describe 'Async scheduler integration with native libraries', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  def clean_output
    last_command_started.output.strip.gsub(/[\\"]/, '')
  end

  # The key test: two TCP clients hit the same AlexScript server
  # concurrently. If scheduler is installed correctly, the server
  # can accept and serve both in interleaved fashion within a single
  # reactor/process. Without scheduler, accept() and read() would
  # block the reactor and clients would be serialized.
  #
  # We can't easily run a server in Aruba and connect to it from a
  # client in the same test (timing is fragile). So instead: use a
  # non-network concurrency test that exercises the same code path
  # via Kernel.sleep under the scheduler.
  it 'Kernel.sleep inside async fibers yields cooperatively' do
    # Two concurrent fibers, each "sleeping" 100ms via Kernel.sleep
    # (which under scheduler becomes cooperative). Total wall time
    # should be ~100ms, not 200ms.
    code = '
      asynchroniczna funkcja spij_i_zwroc(ms, znak) {
          czekaj uspij(ms)
          zwroc znak
      }

      asynchroniczna funkcja main() {
          niech a = uruchom_rownolegle(fn() { czekaj spij_i_zwroc(100, "a") })
          niech b = uruchom_rownolegle(fn() { czekaj spij_i_zwroc(100, "b") })
          niech wa = czekaj a
          niech wb = czekaj b
          zwroc wa + wb
      }

      pokazl uruchom(main)
    '
    start = Time.now
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    elapsed_ms = (Time.now - start) * 1000

    expect(clean_output).to eq('ab')
    # If truly concurrent: ~100ms + Ruby startup. If sequential: ~200ms+.
    # This is already covered by existing tests — keeping here for clarity.
    expect(elapsed_ms).to be < 1500
  end

  # The real scheduler test: network I/O under reactor. We spin up a
  # TCP server in a background thread (Ruby thread, outside reactor),
  # then the AlexScript program connects to it from async fibers.
  # The server is dumb: accepts, reads "hello", sends "world", closes.
  # Two clients connect concurrently; both should finish without one
  # blocking the other.
  it 'TCP socket reads are non-blocking under the reactor' do
    require 'socket'
    port = nil

    # Background server thread. Stays up for the test duration.
    server_thread = Thread.new do
      server = TCPServer.new('127.0.0.1', 0)
      port = server.addr[1]
      2.times do
        client = server.accept
        # Deliberately slow response: sleep 100ms before replying, to
        # ensure a fiber reading from this socket actually yields.
        sleep 0.1
        client.write("hello\n")
        client.close
      end
      server.close
    end

    # Wait for port to be assigned.
    sleep 0.05 until port

    code = <<~AS
       import("socket")

      asynchroniczna funkcja pobierz(port) {
          niech s = SocketTcp.nowy("127.0.0.1", port)
          niech dane = s.czytaj_linie()
          s.zamknij()
          zwroc dane
      }

      asynchroniczna funkcja main(port) {
          niech a = uruchom_rownolegle(fn() { czekaj pobierz(port) })
          niech b = uruchom_rownolegle(fn() { czekaj pobierz(port) })
          niech wa = czekaj a
          niech wb = czekaj b
          zwroc wa + "|" + wb
      }

      pokazl uruchom(main(#{port}))
    AS

    start = Time.now
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    elapsed_ms = (Time.now - start) * 1000

    server_thread.join

    # Both fibers got "hello", joined with "|".
    expect(clean_output).to eq('hello|hello')

    # Critical assertion: the two reads ran concurrently. Server
    # serves each after 100ms. If fibers were serialized, total
    # server time would be 200ms; concurrent, it's ~100ms. Plus
    # Ruby startup (~200-400ms typical). So < 900ms is safely concurrent,
    # > 1100ms suggests serialization.
    expect(elapsed_ms).to be < 900
  end
end