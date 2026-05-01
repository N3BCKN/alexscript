klasa ZnakCzcionki {
    funkcja konstruktor(znak, czcionka, rozmiar) {
        niech @znak = znak
        niech @czcionka = czcionka
        niech @rozmiar = rozmiar
    }
    
    funkcja rysuj(x, y, kolor) {
        pokazl "Rysuję '" + @znak + "' (" + @czcionka + ", " + @rozmiar + "pt) na [" + x + "," + y + "] kolorem " + kolor
    }
    
    funkcja info() {
        zwroc @znak + ":" + @czcionka + ":" + @rozmiar
    }
}

klasa FabrykaZnakow {
    funkcja konstruktor() {
        niech @znaki = {}
        niech @licznik_utworzen = 0
    }
    
    funkcja pobierz_znak(znak, czcionka, rozmiar) {
        niech klucz = znak + ":" + czcionka + ":" + rozmiar
        
        jesli @znaki[klucz] == nic {
            niech @znaki[klucz] = ZnakCzcionki.nowy(znak, czcionka, rozmiar)
            niech @licznik_utworzen = @licznik_utworzen + 1
            pokazl "  [FABRYKA] Utworzono nowy obiekt: " + klucz
        }
        
        zwroc @znaki[klucz]
    }
    
    funkcja statystyki() {
        pokazl "Utworzono unikalnych obiektów: " + @licznik_utworzen
        pokazl "Klucze w pamięci:"
        dla klucz, obiekt w @znaki {
            pokazl "  - " + klucz
        }
    }
}

klasa EdytorTekstu {
    funkcja konstruktor(fabryka) {
        niech @fabryka = fabryka
        niech @znaki_dokumentu = []
    }
    
    funkcja dodaj_znak(znak, czcionka, rozmiar, x, y, kolor) {
        niech obiekt_znaku = @fabryka.pobierz_znak(znak, czcionka, rozmiar)
        niech @znaki_dokumentu = @znaki_dokumentu + [{
            "obiekt": obiekt_znaku,
            "x": x,
            "y": y,
            "kolor": kolor
        }]
    }
    
    funkcja renderuj() {
        pokazl "Renderowanie dokumentu:"
        dla element w @znaki_dokumentu {
            niech obj = element["obiekt"]
            obj.rysuj(element["x"], element["y"], element["kolor"])
        }
    }
    
    funkcja statystyki() {
        pokazl "Znaków w dokumencie: " + @znaki_dokumentu.dlg
    }
}


pokazl "=== Test Flyweight ==="
pokazl ""

niech fabryka = FabrykaZnakow.nowy()
niech edytor = EdytorTekstu.nowy(fabryka)

pokazl "Dodawanie znaków do dokumentu:"
edytor.dodaj_znak("H", "Arial", 12, 0, 0, "czarny")
edytor.dodaj_znak("e", "Arial", 12, 10, 0, "czarny")
edytor.dodaj_znak("l", "Arial", 12, 20, 0, "czarny")
edytor.dodaj_znak("l", "Arial", 12, 30, 0, "czarny")
edytor.dodaj_znak("o", "Arial", 12, 40, 0, "czarny")
edytor.dodaj_znak("!", "Arial", 12, 50, 0, "czerwony")
edytor.dodaj_znak("H", "Arial", 14, 0, 20, "niebieski")
edytor.dodaj_znak("i", "Arial", 14, 15, 20, "niebieski")
pokazl ""

edytor.renderuj()
pokazl ""

edytor.statystyki()
pokazl ""

fabryka.statystyki()