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
                server = TCPServer.new(adres, port.to_i)
                server.close
                true
              rescue Errno::EADDRINUSE, Errno::EACCES
                false
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