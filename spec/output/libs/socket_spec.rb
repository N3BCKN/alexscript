require 'aruba/rspec'

RSpec.describe 'Socket native libraries', type: :aruba do
  let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', File.dirname(__FILE__)) }

  # ── 1. Socket static helpers ────────────────────────────────

  describe 'Socket static helpers' do
    it 'returns hostname' do
      code = '
        import("socket")
        niech h = Socket.nazwa_hosta()
        pokazl h.dlg() > 0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'resolves localhost IP' do
      code = '
        import("socket")
        niech ip = Socket.pobierz_adres_ip("localhost")
        pokazl ip
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("127.0.0.1")
    end

    it 'resolves multiple addresses for a domain' do
      code = '
        import("socket")
        niech adresy = Socket.pobierz_wszystkie_adresy("localhost")
        pokazl adresy.dlg() > 0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'finds a free port' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()
        pokazl p > 0
        pokazl p < 65536
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'checks port availability' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()
        pokazl Socket.czy_port_wolny(p)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'cannot be instantiated' do
      code = '
        import("socket")
        niech s = Socket.nowy()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Socket jest klasą statyczną/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  # ── 2. SerwerTcp ────────────────────────────────────────────

  describe 'SerwerTcp' do
    it 'creates and closes a TCP server' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()
        niech srv = SerwerTcp.nowy(p)
        pokazl srv.czy_zamkniety()
        pokazl srv.port()
        srv.zamknij()
        pokazl srv.czy_zamkniety()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      lines = last_command_started.output.strip.split("\n")
      expect(lines[0]).to eq("falsz")
      expect(lines[1].to_i).to be > 0
      expect(lines[2]).to eq("prawda")
    end

    it 'reports local address' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()
        niech srv = SerwerTcp.nowy(p)
        niech addr = srv.adres_lokalny()
        pokazl addr["port"] == p
        srv.zamknij()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'occupies port while open' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()
        niech srv = SerwerTcp.nowy(p)
        pokazl Socket.czy_port_wolny(p)
        srv.zamknij()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("falsz")
    end
  end

  # ── 3. TCP client-server communication ──────────────────────

  describe 'TCP client-server communication' do
    it 'sends and receives data between client and server' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()
        niech srv = SerwerTcp.nowy(p)
        niech kl = SocketTcp.nowy("127.0.0.1", p)
        niech pol = srv.akceptuj()

        kl.wyslij("Witaj!")
        niech dane = pol.odbierz(1024)
        pokazl dane

        pol.wyslij("Odpowiedz")
        niech odp = kl.odbierz(1024)
        pokazl odp

        kl.zamknij()
        pol.zamknij()
        srv.zamknij()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("Witaj!\nOdpowiedz")
    end

    it 'sends and receives lines' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()
        niech srv = SerwerTcp.nowy(p)
        niech kl = SocketTcp.nowy("127.0.0.1", p)
        niech pol = srv.akceptuj()

        kl.wyslij_linie("linia1")
        kl.wyslij_linie("linia2")
        kl.zamknij_zapis()

        niech l1 = pol.czytaj_linie()
        niech l2 = pol.czytaj_linie()
        pokazl l1
        pokazl l2

        kl.zamknij()
        pol.zamknij()
        srv.zamknij()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("linia1\nlinia2")
    end

    it 'reports remote and local addresses' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()
        niech srv = SerwerTcp.nowy(p)
        niech kl = SocketTcp.nowy("127.0.0.1", p)
        niech pol = srv.akceptuj()

        niech zdalny = kl.adres_zdalny()
        pokazl zdalny["port"] == p

        niech lok = kl.adres_lokalny()
        pokazl lok["port"] > 0

        kl.zamknij()
        pol.zamknij()
        srv.zamknij()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'reports closed state correctly' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()
        niech srv = SerwerTcp.nowy(p)
        niech kl = SocketTcp.nowy("127.0.0.1", p)
        niech pol = srv.akceptuj()

        pokazl kl.czy_zamkniety()
        kl.zamknij()
        pokazl kl.czy_zamkniety()

        pol.zamknij()
        srv.zamknij()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("falsz\nprawda")
    end
  end

  # ── 4. TCP socket options ───────────────────────────────────

  describe 'TCP socket options' do
    it 'sets keepalive and nodelay' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()
        niech srv = SerwerTcp.nowy(p)
        niech kl = SocketTcp.nowy("127.0.0.1", p)
        niech pol = srv.akceptuj()

        pokazl kl.ustaw_keepalive(prawda)
        pokazl kl.ustaw_nodelay(prawda)
        pokazl kl.flush()

        kl.zamknij()
        pol.zamknij()
        srv.zamknij()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda")
    end
  end

  # ── 5. UDP ──────────────────────────────────────────────────

  describe 'SocketUdp' do
    it 'sends and receives datagrams' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()

        niech srv = SocketUdp.nowy()
        srv.zwiaz(p)

        niech kl = SocketUdp.nowy()
        kl.wyslij("UDP dane", "127.0.0.1", p)

        niech wynik = srv.odbierz(1024)
        pokazl wynik["dane"]
        pokazl wynik["adres"]
        pokazl wynik["port"] > 0

        kl.zamknij()
        srv.zamknij()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("UDP dane\n127.0.0.1\nprawda")
    end

    it 'reports closed state' do
      code = '
        import("socket")
        niech u = SocketUdp.nowy()
        pokazl u.czy_zamkniety()
        u.zamknij()
        pokazl u.czy_zamkniety()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("falsz\nprawda")
    end

    it 'connects and sends without specifying host each time' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()

        niech srv = SocketUdp.nowy()
        srv.zwiaz(p)

        niech kl = SocketUdp.nowy()
        kl.polacz("127.0.0.1", p)
        kl.wyslij_polaczony("polaczony")

        niech wynik = srv.odbierz(1024)
        pokazl wynik["dane"]

        kl.zamknij()
        srv.zamknij()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("polaczony")
    end
  end

  # ── 6. Multi-message TCP exchange ───────────────────────────

  describe 'TCP multi-message exchange' do
    it 'handles multiple send/receive cycles' do
      code = '
        import("socket")
        niech p = Socket.wolny_port()
        niech srv = SerwerTcp.nowy(p)
        niech kl = SocketTcp.nowy("127.0.0.1", p)
        niech pol = srv.akceptuj()

        kl.wyslij("msg1")
        pokazl pol.odbierz(1024)

        pol.wyslij("ack1")
        pokazl kl.odbierz(1024)

        kl.wyslij("msg2")
        pokazl pol.odbierz(1024)

        kl.zamknij()
        pol.zamknij()
        srv.zamknij()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("msg1\nack1\nmsg2")
    end
  end
end
