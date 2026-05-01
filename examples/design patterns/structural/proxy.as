abstrakcyjna klasa SerwisObrazu {
    funkcja konstruktor() {}
    
    funkcja wyswietl() {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa PrawdziwyObraz < SerwisObrazu {
    funkcja konstruktor(nazwa_pliku) {
        super()
        niech @nazwa_pliku = nazwa_pliku
        wczytaj_z_dysku()
    }
    
    funkcja wczytaj_z_dysku() {
        pokazl "  [OBRAZ] Wczytywanie " + @nazwa_pliku + " z dysku (operacja kosztowna)..."
    }
    
    funkcja wyswietl() {
        pokazl "  [OBRAZ] Wyświetlam obraz: " + @nazwa_pliku
    }
}

klasa ProxyObrazu < SerwisObrazu {
    funkcja konstruktor(nazwa_pliku) {
        super()
        niech @nazwa_pliku = nazwa_pliku
        niech @prawdziwy_obraz = nic
    }
    
    funkcja wyswietl() {
        jesli @prawdziwy_obraz == nic {
            pokazl "  [PROXY] Leniwa inicjalizacja obrazu"
            niech @prawdziwy_obraz = PrawdziwyObraz.nowy(@nazwa_pliku)
        }
        @prawdziwy_obraz.wyswietl()
    }
}

klasa ProxyObrazyZKontrolaDostepu < SerwisObrazu {
    funkcja konstruktor(nazwa_pliku, wymagana_rola) {
        super()
        niech @nazwa_pliku = nazwa_pliku
        niech @wymagana_rola = wymagana_rola
        niech @prawdziwy_obraz = nic
    }
    
    funkcja wyswietl_dla_uzytkownika(rola_uzytkownika) {
        jesli rola_uzytkownika != @wymagana_rola {
            pokazl "  [PROXY] ODMOWA DOSTĘPU: Wymagana rola '" + @wymagana_rola + "', masz '" + rola_uzytkownika + "'"
            zwroc
        }
        
        pokazl "  [PROXY] Dostęp przyznany"
        
        jesli @prawdziwy_obraz == nic {
            niech @prawdziwy_obraz = PrawdziwyObraz.nowy(@nazwa_pliku)
        }
        @prawdziwy_obraz.wyswietl()
    }
    
    funkcja wyswietl() {
        wyswietl_dla_uzytkownika("guest")
    }
}


pokazl "=== Test Proxy ==="
pokazl ""

pokazl "1. Lazy Proxy (opóźniona inicjalizacja):"
niech obraz1 = ProxyObrazu.nowy("zdjecie1.jpg")
niech obraz2 = ProxyObrazu.nowy("zdjecie2.jpg")
pokazl "Proxy utworzone (obrazy NIE wczytane jeszcze)"
pokazl ""

pokazl "Pierwsze wyświetlenie obraz1:"
obraz1.wyswietl()
pokazl ""

pokazl "Drugie wyświetlenie obraz1:"
obraz1.wyswietl()
pokazl ""

pokazl "Pierwsze wyświetlenie obraz2:"
obraz2.wyswietl()
pokazl ""

pokazl "2. Protection Proxy (kontrola dostępu):"
niech tajny_obraz = ProxyObrazyZKontrolaDostepu.nowy("tajne.jpg", "admin")
pokazl ""

pokazl "Próba dostępu jako guest:"
tajny_obraz.wyswietl_dla_uzytkownika("guest")
pokazl ""

pokazl "Próba dostępu jako admin:"
tajny_obraz.wyswietl_dla_uzytkownika("admin")
pokazl ""

pokazl "Ponowny dostęp jako admin:"
tajny_obraz.wyswietl_dla_uzytkownika("admin")