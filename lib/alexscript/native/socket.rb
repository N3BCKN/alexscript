# frozen_string_literal: true

# lib/alexscript/native/socket_lib.rb
#
# Native bindings for Ruby's Socket classes:
#   SocketTcp   → TCPSocket (client)
#   SerwerTcp   → TCPServer
#   SocketUdp   → UDPSocket
#   Socket      → static helpers (DNS, IP, port checks)

require 'socket'
require 'ipaddr'

module AlexScript
  module Native
    module SocketLibrary

      def self.register
        register_socket_tcp
        register_serwer_tcp
        register_socket_udp
        register_socket_helpers
      rescue => e
        $stderr.puts "[AlexScript] Socket registration error: #{e.message}"
        $stderr.puts e.backtrace.first(3).join("\n")
        raise
      end

      # ════════════════════════════════════════════════════════════
      # SocketTcp — TCP client (wraps TCPSocket)
      # ════════════════════════════════════════════════════════════

      def self.register_socket_tcp
        Utils::NativeClassRegistry.define_class('SocketTcp',
          ruby_class: TCPSocket,
          constructor: ->(host, port) {
            TCPSocket.new(host.to_s, port.to_i)
          },
          methods: {
            # ─── Sending ─────────────────────────────────────
            'wyslij' => ->(s, dane) {
              s.write(dane.to_s)
            },

            'zamknij_odlozone' => ->(s) {
              reactor = AlexScript::Async::Reactor.current
              reactor.odloz_zamkniecie(s)
              true
            },

            'wyslij_linie' => ->(s, dane) {
              s.puts(dane.to_s)
              dane.to_s.length + 1
            },

            # ─── Receiving ───────────────────────────────────
            'odbierz' => ->(s, *args) {
              rozmiar = args.empty? ? 4096 : args[0].to_i
              s.recv(rozmiar)
            },

            'czytaj' => ->(s, *args) {
              if args.empty?
                s.read
              else
                s.read(args[0].to_i)
              end
            },

            'czytaj_linie' => ->(s) {
              begin
                s.gets&.chomp || ''
              rescue EOFError
                ''
              end
            },

            'czytaj_wszystkie_linie' => ->(s) {
              s.readlines.map(&:chomp)
            },

            # ─── Connection state ────────────────────────────
            'zamknij' => ->(s) {
              return true if s.closed?
              s.close
              true
            },

            'zamknij_zapis' => ->(s) {
              s.close_write
              true
            },

            'zamknij_odczyt' => ->(s) {
              s.close_read
              true
            },

            'czy_zamkniety' => ->(s) {
              s.closed?
            },

            # ─── Info ────────────────────────────────────────
            'adres_lokalny' => ->(s) {
              addr = s.local_address
              { 'adres' => addr.ip_address, 'port' => addr.ip_port }
            },

            'adres_zdalny' => ->(s) {
              addr = s.remote_address
              { 'adres' => addr.ip_address, 'port' => addr.ip_port }
            },

            # ─── Options ────────────────────────────────────
            'ustaw_timeout' => ->(s, sekundy) {
              timeval = [sekundy.to_i, 0].pack('l_2')
              s.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_RCVTIMEO, timeval)
              s.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_SNDTIMEO, timeval)
              true
            },

            'ustaw_keepalive' => ->(s, wlacz) {
              s.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_KEEPALIVE, wlacz ? 1 : 0)
              true
            },

            'ustaw_nodelay' => ->(s, wlacz) {
              s.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, wlacz ? 1 : 0)
              true
            },

            'flush' => ->(s) {
              s.flush
              true
            }
          },
          static_methods: {},
          static_vars: {}
        )
      end

      # ════════════════════════════════════════════════════════════
      # SerwerTcp — TCP server (wraps TCPServer)
      # ════════════════════════════════════════════════════════════

      def self.register_serwer_tcp
        Utils::NativeClassRegistry.define_class('SerwerTcp',
          ruby_class: TCPServer,
          constructor: ->(port, *args) {
            adres = args.empty? ? '0.0.0.0' : args[0].to_s
            server = TCPServer.new(adres, port.to_i)
            server.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_REUSEADDR, 1)
            server
          },
          methods: {
            'akceptuj' => ->(s) {
              s.accept  # returns TCPSocket → auto-wrapped to SocketTcp
            },

            # TODO update docs with this metod
            'uruchom_petle' => ->(s, callback) {
              interpreter = Fiber[:alex_interpreter]
              unless interpreter
                raise 'SerwerTcp#uruchom_petle wymaga aktywnego interpretera'
              end

              # Extract AS function declaration for synthesizing calls from Ruby.
              # callback arrives as { declaration:, env: } after NativeTypeConverter.
              unless callback.is_a?(Hash) && callback[:declaration]
                raise 'uruchom_petle wymaga funkcji jako argumentu'
              end

              loop do
                begin
                  klient = s.accept
                rescue IOError, Errno::EBADF
                  # Server socket closed — exit loop gracefully.
                  break
                end

                Thread.new(klient) do |sock|
                  # Per-connection thread — isolated from the main reactor.
                  # Synthesize an AS call to the callback with the socket instance.
                  begin
                    call_env = callback[:env].new_env
                    socket_as_value = Utils::NativeClassRegistry.wrap_native_object('SocketTcp', sock)
                    call_env.set_local_var('__alex_cb__',  callback, :type_function)
                    call_env.set_local_var('__alex_sock__', socket_as_value[1], socket_as_value[0])

                    synthetic_call = AlexScript::AST::LambdaCall.new(
                      AlexScript::AST::Identifier.new('__alex_cb__', 0),
                      [AlexScript::AST::Identifier.new('__alex_sock__', 0)],
                      0
                    )

                    interpreter.interpret!(synthetic_call, call_env)
                  rescue Utils::AlexScriptError => e
                    warn "[SerwerTcp] handler error: #{e.message}"
                  rescue StandardError => e
                    warn "[SerwerTcp] handler ruby error: #{e.class}: #{e.message}"
                  ensure
                    begin
                      sock.close unless sock.closed?
                    rescue IOError, Errno::EBADF
                    end
                  end
                end
              end

              true
            },

            'zamknij' => ->(s) {
              return true if s.closed?
              s.close
              true
            },

            'czy_zamkniety' => ->(s) {
              s.closed?
            },

            'adres_lokalny' => ->(s) {
              addr = s.local_address
              { 'adres' => addr.ip_address, 'port' => addr.ip_port }
            },

            'port' => ->(s) {
              s.local_address.ip_port
            },

            'ustaw_nasluchiwanie' => ->(s, max) {
              s.listen(max.to_i)
              true
            }
          },
          static_methods: {},
          static_vars: {}
        )
      end

      # ════════════════════════════════════════════════════════════
      # SocketUdp — UDP socket (wraps UDPSocket)
      # ════════════════════════════════════════════════════════════

      def self.register_socket_udp
        Utils::NativeClassRegistry.define_class('SocketUdp',
          ruby_class: UDPSocket,
          constructor: ->() {
            UDPSocket.new
          },
          methods: {
            'zwiaz' => ->(s, port, *args) {
              adres = args.empty? ? '0.0.0.0' : args[0].to_s
              s.bind(adres, port.to_i)
              true
            },

            'wyslij' => ->(s, dane, host, port) {
              s.send(dane.to_s, 0, host.to_s, port.to_i)
            },

            'odbierz' => ->(s, *args) {
              rozmiar = args.empty? ? 4096 : args[0].to_i
              data, addr = s.recvfrom(rozmiar)
              {
                'dane' => data,
                'adres' => addr[3],
                'port' => addr[1]
              }
            },

            'polacz' => ->(s, host, port) {
              s.connect(host.to_s, port.to_i)
              true
            },

            'wyslij_polaczony' => ->(s, dane) {
              s.send(dane.to_s, 0)
            },

            'zamknij' => ->(s) {
              return true if s.closed?
              s.close
              true
            },

            'czy_zamkniety' => ->(s) {
              s.closed?
            },

            'adres_lokalny' => ->(s) {
              addr = s.local_address
              { 'adres' => addr.ip_address, 'port' => addr.ip_port }
            }
          },
          static_methods: {},
          static_vars: {}
        )
      end

      # ════════════════════════════════════════════════════════════
      # Socket — static helpers (DNS, port tools)
      # ════════════════════════════════════════════════════════════

      def self.register_socket_helpers
        Utils::NativeClassRegistry.define_class('Socket',
          constructor: ->(*) {
            raise "Socket jest klasą statyczną — użyj SocketTcp, SerwerTcp lub SocketUdp"
          },
          methods: {},
          static_methods: {
            'pobierz_adres_ip' => ->(nazwa) {
              # Force IPv4 (AF_INET) — consistent across platforms
              addrs = ::Socket.getaddrinfo(nazwa.to_s, nil, :INET)
              addrs.empty? ? IPSocket.getaddress(nazwa.to_s) : addrs.first[3]
            },

            'pobierz_nazwe_hosta' => ->(adres_ip) {
              begin
                ::Socket.gethostbyaddr(IPAddr.new(adres_ip.to_s).hton).first
              rescue
                adres_ip.to_s
              end
            },

            'pobierz_wszystkie_adresy' => ->(nazwa) {
              Addrinfo.getaddrinfo(nazwa.to_s, nil, :INET).map(&:ip_address).uniq
            },

            'nazwa_hosta' => ->() {
              ::Socket.gethostname
            },

            'czy_port_wolny' => ->(port, *args) {
              adres = args.empty? ? '127.0.0.1' : args[0].to_s
              begin
                # Try to connect — if something is listening, port is occupied
                sock = TCPSocket.new(adres, port.to_i)
                sock.close
                false  # connection succeeded → port is in use
              rescue Errno::ECONNREFUSED, Errno::ECONNRESET
                # Nothing listening → port is free
                true
              rescue Errno::EADDRNOTAVAIL
                true
              end
            },

            'wolny_port' => ->() {
              server = TCPServer.new('127.0.0.1', 0)
              port = server.addr[1]
              server.close
              port
            }
          },
          static_vars: {}
        )
      end
    end
  end
end