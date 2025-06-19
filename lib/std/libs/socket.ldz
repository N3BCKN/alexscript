# lib/std/libs/socket.ldz
require_ruby("socket")

klasa Socket {
    # Stałe
    statyczny niech AF_INET = ruby("Socket", "const_get", "AF_INET")
    statyczny niech SOCK_STREAM = ruby("Socket", "const_get", "SOCK_STREAM")
    statyczny niech SOCK_DGRAM = ruby("Socket", "const_get", "SOCK_DGRAM")
    statyczny niech SOL_SOCKET = ruby("Socket", "const_get", "SOL_SOCKET")
    statyczny niech SO_REUSEADDR = ruby("Socket", "const_get", "SO_REUSEADDR")
    statyczny niech SO_KEEPALIVE = ruby("Socket", "const_get", "SO_KEEPALIVE")
    
    # Pole przechowujące referencję do socketu Ruby
    niech @gniazdo = nic
    
    # Konstruktor - tworzy nowe gniazdo
    funkcja konstruktor(rodzina = Socket.AF_INET, typ = Socket.SOCK_STREAM) {
        # Utwórz instancję gniazda
        niech @gniazdo = ruby("Socket", "new", rodzina, typ)
    }
    
    # Połącz z serwerem
    funkcja polacz(adres, port) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        # Konwersja adresu IP i portu na sockaddr
        niech sockaddr = ruby("Socket", "sockaddr_in", port, adres)
        
        # Połączenie z serwerem
        ruby_obj(@gniazdo, "connect", sockaddr)
        
        zwroc prawda
    }
    
    # Wysyłanie danych
    funkcja wyslij(dane) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        # Wysyłanie danych
        niech wynik = ruby_obj(@gniazdo, "send", dane, 0)
        zwroc wynik
    }
    
    # Odbieranie danych
    funkcja odbierz(rozmiar = 1024) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        # Odbieranie danych
        niech dane = ruby_obj(@gniazdo, "recv", rozmiar, 0)
        zwroc dane
    }
    
    # Zamyka połączenie
    funkcja zamknij() {
        jesli @gniazdo == nic {
            zwroc falsz
        }
        
        ruby_obj(@gniazdo, "close")
        niech @gniazdo = nic
        zwroc prawda
    }
    
    # Nasłuchuje na połączenia przychodzące
    funkcja nasluchuj(ilosc_polaczen = 5) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        ruby_obj(@gniazdo, "listen", ilosc_polaczen)
        zwroc prawda
    }
    
    # Wiąże gniazdo z adresem i portem
    funkcja zwiaz(adres, port) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        niech sockaddr = ruby("Socket", "sockaddr_in", port, adres)
        ruby_obj(@gniazdo, "bind", sockaddr)
        
        zwroc prawda
    }
    
    # Akceptuje przychodzące połączenie
    funkcja akceptuj() {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        niech klient_socket = ruby_obj(@gniazdo, "accept")
        
        # Tworzymy nową instancję Socket w AlexScript i przypisujemy jej gniazdo klienta
        niech klient = Socket.nowy()
        klient.ustaw_gniazdo(klient_socket[0])
        
        zwroc klient
    }
    
    # Metoda pomocnicza do ustawiania gniazda (używana wewnętrznie)
    funkcja ustaw_gniazdo(gniazdo) {
        niech @gniazdo = gniazdo
        zwroc prawda
    }
    
    # Pobieranie adresu lokalnego
    funkcja adres_lokalny() {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        niech adres = ruby_obj(@gniazdo, "getsockname")
        niech port_adres = ruby("Socket", "unpack_sockaddr_in", adres)
        
        zwroc {
            "port": port_adres[0],
            "adres": port_adres[1]
        }
    }
    
    # Pobieranie adresu zdalnego
    funkcja adres_zdalny() {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        niech adres = ruby_obj(@gniazdo, "getpeername")
        niech port_adres = ruby("Socket", "unpack_sockaddr_in", adres)
        
        zwroc {
            "port": port_adres[0],
            "adres": port_adres[1]
        }
    }
    
    # Sprawdza, czy gniazdo jest zamknięte
    funkcja czy_zamkniete() {
        jesli @gniazdo == nic {
            zwroc prawda
        }
        
        niech wynik = ruby_obj(@gniazdo, "closed?")
        zwroc wynik
    }
    
    # Ustawienie opcji gniazda
    funkcja ustaw_opcje(opcja, wartosc) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        niech sol_socket = Socket.SOL_SOCKET
        ruby_obj(@gniazdo, "setsockopt", sol_socket, opcja, wartosc)
        zwroc prawda
    }
    
    # Pobranie opcji gniazda
    funkcja pobierz_opcje(opcja) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        niech sol_socket = Socket.SOL_SOCKET
        niech wynik = ruby_obj(@gniazdo, "getsockopt", sol_socket, opcja)
        zwroc wynik
    }
    
    # Ustawienie gniazda jako nieblokującego
    funkcja ustaw_nieblokujace(wlacz = prawda) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        niech f_setfl = ruby("Fcntl", "const_get", "F_SETFL")
        niech flaga = 0
        jesli wlacz == prawda {
            flaga = ruby("Fcntl", "const_get", "O_NONBLOCK")
        }
        
        ruby_obj(@gniazdo, "fcntl", f_setfl, flaga)
        zwroc prawda
    }
    
    # Tworzy serwer TCP
    statyczny funkcja utworz_serwer(port, adres = "0.0.0.0", max_polaczen = 5) {
        niech gniazdo = Socket.nowy(Socket.AF_INET, Socket.SOCK_STREAM)
        
        # Ustaw opcję ponownego użycia adresu
        gniazdo.ustaw_opcje(Socket.SO_REUSEADDR, 1)
        
        # Zwiąż z adresem i portem
        gniazdo.zwiaz(adres, port)
        
        # Rozpocznij nasłuchiwanie
        gniazdo.nasluchuj(max_polaczen)
        
        zwroc gniazdo
    }
    
    # Tworzy klienta TCP
    statyczny funkcja utworz_klienta(adres, port) {
        niech gniazdo = Socket.nowy(Socket.AF_INET, Socket.SOCK_STREAM)
        gniazdo.polacz(adres, port)
        
        zwroc gniazdo
    }
    
    # Konwersja adresu IP do formatu sieciowego
    statyczny funkcja inet_aton(adres) {
        niech wynik = ruby("Socket", "inet_aton", adres)
        zwroc wynik
    }
    
    # Konwersja adresu z formatu sieciowego do tekstowego
    statyczny funkcja inet_ntoa(adres_binarny) {
        niech wynik = ruby("Socket", "inet_ntoa", adres_binarny)
        zwroc wynik
    }
    
    # Pobiera nazwę hosta dla adresu IP
    statyczny funkcja pobierz_nazwe_hosta(adres) {
        niech wynik = ruby("Socket", "gethostbyaddr", ruby("Socket", "inet_aton", adres), Socket.AF_INET)
        zwroc wynik[0]
    }
    
    # Pobiera adres IP dla nazwy hosta
    statyczny funkcja pobierz_adres_ip(nazwa) {
        niech wynik = ruby("Socket", "gethostbyname", nazwa)
        zwroc ruby("Socket", "inet_ntoa", wynik[3])
    }
}

# Klasa TCPSocket - uproszczona wersja dla typowych przypadków
klasa TCPSocket {
    niech @gniazdo = nic
    
    funkcja konstruktor(host = nic, port = nic) {
        # Jeśli podano host i port, od razu nawiąż połączenie
        jesli host != nic i port != nic {
            niech @gniazdo = ruby("TCPSocket", "new", host, port)
        }
    }
    
    funkcja wyslij(dane) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        niech wynik = ruby_obj(@gniazdo, "write", dane)
        zwroc wynik
    }
    
    funkcja odbierz(rozmiar = 1024) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        niech dane = ruby_obj(@gniazdo, "read", rozmiar)
        zwroc dane
    }
    
    funkcja zamknij() {
        jesli @gniazdo == nic {
            zwroc falsz
        }
        
        ruby_obj(@gniazdo, "close")
        niech @gniazdo = nic
        zwroc prawda
    }
    
    funkcja ustaw_gniazdo(gniazdo) {
        niech @gniazdo = gniazdo
        zwroc prawda
    }
    
    funkcja czy_zamkniete() {
        jesli @gniazdo == nic {
            zwroc prawda
        }
        
        niech wynik = ruby_obj(@gniazdo, "closed?")
        zwroc wynik
    }
    
    statyczny funkcja otworz(host, port) {
        zwroc TCPSocket.nowy(host, port)
    }
}

# Klasa TCPServer - dedykowana dla serwera TCP
klasa TCPServer {
    niech @serwer = nic
    
    funkcja konstruktor(port, adres = "0.0.0.0") {
        niech @serwer = ruby("TCPServer", "new", adres, port)
    }
    
    funkcja akceptuj() {
        jesli @serwer == nic {
            rzuc "Serwer nie został utworzony"
        }
        
        niech klient_socket = ruby_obj(@serwer, "accept")
        
        niech klient = TCPSocket.nowy()
        klient.ustaw_gniazdo(klient_socket)
        
        zwroc klient
    }
    
    funkcja zamknij() {
        jesli @serwer == nic {
            zwroc falsz
        }
        
        ruby_obj(@serwer, "close")
        niech @serwer = nic
        zwroc prawda
    }
    
    funkcja czy_zamkniete() {
        jesli @serwer == nic {
            zwroc prawda
        }
        
        niech wynik = ruby_obj(@serwer, "closed?")
        zwroc wynik
    }
}

# Klasa UDPSocket - dla komunikacji UDP
klasa UDPSocket {
    niech @gniazdo = nic
    
    funkcja konstruktor() {
        niech @gniazdo = ruby("UDPSocket", "new")
    }
    
    funkcja zwiaz(port, adres = "0.0.0.0") {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        ruby_obj(@gniazdo, "bind", adres, port)
        zwroc prawda
    }
    
    funkcja wyslij(dane, host, port) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        niech wynik = ruby_obj(@gniazdo, "send", dane, 0, host, port)
        zwroc wynik
    }
    
    funkcja odbierz(rozmiar = 1024) {
        jesli @gniazdo == nic {
            rzuc "Gniazdo nie zostało utworzone"
        }
        
        niech dane = ruby_obj(@gniazdo, "recvfrom", rozmiar)
        zwroc { "dane": dane[0], "adres": dane[1][3], "port": dane[1][1] }
    }
    
    funkcja zamknij() {
        jesli @gniazdo == nic {
            zwroc falsz
        }
        
        ruby_obj(@gniazdo, "close")
        niech @gniazdo = nic
        zwroc prawda
    }
    
    funkcja czy_zamkniete() {
        jesli @gniazdo == nic {
            zwroc prawda
        }
        
        niech wynik = ruby_obj(@gniazdo, "closed?")
        zwroc wynik
    }
}