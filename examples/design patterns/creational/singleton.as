klasa KonfiguracjaAplikacji {
    statyczny niech instancja = nic
    statyczny niech zainicjalizowana = falsz
    
    funkcja konstruktor() {
        jesli KonfiguracjaAplikacji.zainicjalizowana {
            rzuc "Nie można tworzyć instancji Singleton! Użyj KonfiguracjaAplikacji.pobierz()"
        }
        
        niech @ustawienia = {}
        niech @wersja = "1.0.0"
        
        niech @ustawienia["baza_danych"] = "localhost"
        niech @ustawienia["port"] = 5432
        niech @ustawienia["timeout"] = 30
    }
    
    statyczny funkcja pobierz() {
        jesli KonfiguracjaAplikacji.instancja == nic {
            niech KonfiguracjaAplikacji.zainicjalizowana = prawda
            niech KonfiguracjaAplikacji.instancja = KonfiguracjaAplikacji.nowy()
            niech KonfiguracjaAplikacji.zainicjalizowana = falsz
        }
        zwroc KonfiguracjaAplikacji.instancja
    }
    
    funkcja ustaw(klucz, wartosc) {
        @ustawienia[klucz] = wartosc
    }
    
    funkcja pobierz_ustawienie(klucz) {
        zwroc @ustawienia[klucz]
    }
    
    funkcja wyswietl_konfiguracje() {
        pokazl "Konfiguracja aplikacji v" + @wersja + ":"
        dla klucz, wartosc w @ustawienia {
            pokazl "  " + klucz + " = " + wartosc
        }
    }
}



pokazl "=== Test Singleton ==="
pokazl ""

niech config1 = KonfiguracjaAplikacji.pobierz()
pokazl "Pierwsza instancja pobrana"
config1.wyswietl_konfiguracje()
pokazl ""

config1.ustaw("timeout", 60)
config1.ustaw("cache", "enabled")

niech config2 = KonfiguracjaAplikacji.pobierz()
pokazl "Druga instancja pobrana (ta sama?):"
config2.wyswietl_konfiguracje()
pokazl ""

pokazl "Czy to ta sama instancja? " + config1.identyczny(config2)
pokazl ""

pokazl "Próba bezpośredniego utworzenia (powinien być błąd):"
proba {
    niech config3 = KonfiguracjaAplikacji.nowy()
    pokazl "BŁĄD: Udało się utworzyć instancję!"
} zlap (e) {
    pokazl "Poprawnie zablokowano: " + e["wiadomosc"]
}