abstrakcyjna klasa PrzepisNaNapoj {
    funkcja konstruktor() {}
    
    funkcja przygotuj() {
        zagotuj_wode()
        zaparz()
        przelej_do_kubka()
        jesli klient_chce_dodatki() {
            dodaj_dodatki()
        }
        pokazl "  ✓ Napój gotowy!"
    }
    
    funkcja zagotuj_wode() {
        pokazl "  [1] Gotuję wodę..."
    }
    
    funkcja przelej_do_kubka() {
        pokazl "  [3] Przelewam do kubka"
    }
    
    funkcja zaparz() {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja dodaj_dodatki() {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja klient_chce_dodatki() {
        zwroc prawda
    }
}

klasa Herbata < PrzepisNaNapoj {
    funkcja zaparz() {
        pokazl "  [2] Zaparzam herbatę"
    }
    
    funkcja dodaj_dodatki() {
        pokazl "  [4] Dodaję cytrynę i miód"
    }
}

klasa Kawa < PrzepisNaNapoj {
    funkcja zaparz() {
        pokazl "  [2] Zaparzam kawę"
    }
    
    funkcja dodaj_dodatki() {
        pokazl "  [4] Dodaję mleko i cukier"
    }
}

klasa KawaCzarna < PrzepisNaNapoj {
    funkcja zaparz() {
        pokazl "  [2] Zaparzam mocną kawę"
    }
    
    funkcja dodaj_dodatki() {
        pokazl "  [4] Brak dodatków"
    }
    
    funkcja klient_chce_dodatki() {
        zwroc falsz
    }
}

abstrakcyjna klasa GeneratorRaportu {
    funkcja konstruktor() {}
    
    funkcja generuj() {
        pokazl "=== Generowanie raportu ==="
        pokazl ""
        
        zbierz_dane()
        analizuj_dane()
        utworz_naglowek()
        utworz_tresc()
        utworz_stopke()
        
        jesli czy_eksportowac() {
            eksportuj()
        }
        
        pokazl ""
        pokazl "✓ Raport wygenerowany"
    }
    
    funkcja utworz_naglowek() {
        pokazl "[NAGŁÓWEK] Raport z dnia: 2024-12-22"
    }
    
    funkcja utworz_stopke() {
        pokazl "[STOPKA] Wygenerowano automatycznie"
    }
    
    funkcja zbierz_dane() {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja analizuj_dane() {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja utworz_tresc() {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja eksportuj() {
        pokazl "[EKSPORT] Eksportuję do PDF"
    }
    
    funkcja czy_eksportowac() {
        zwroc prawda
    }
}

klasa RaportSprzedazy < GeneratorRaportu {
    funkcja zbierz_dane() {
        pokazl "[DANE] Pobieram dane sprzedażowe z bazy..."
    }
    
    funkcja analizuj_dane() {
        pokazl "[ANALIZA] Obliczam sumy i średnie sprzedaży"
    }
    
    funkcja utworz_tresc() {
        pokazl "[TREŚĆ] Sprzedaż: 125,000 PLN (+15%)"
        pokazl "[TREŚĆ] Najlepszy produkt: Laptop XYZ"
    }
}

klasa RaportKadrowy < GeneratorRaportu {
    funkcja zbierz_dane() {
        pokazl "[DANE] Pobieram dane pracowników..."
    }
    
    funkcja analizuj_dane() {
        pokazl "[ANALIZA] Obliczam statystyki frekwencji"
    }
    
    funkcja utworz_tresc() {
        pokazl "[TREŚĆ] Pracowników: 45"
        pokazl "[TREŚĆ] Średnia frekwencja: 96%"
        pokazl "[TREŚĆ] Urlopy wykorzystane: 65%"
    }
    
    funkcja czy_eksportowac() {
        zwroc falsz
    }
}


pokazl "=== Test Template Method ==="
pokazl ""

pokazl "1. Przygotowanie herbaty:"
niech herbata = Herbata.nowy()
herbata.przygotuj()
pokazl ""
pokazl "================================"
pokazl ""

pokazl "2. Przygotowanie kawy z dodatkami:"
niech kawa = Kawa.nowy()
kawa.przygotuj()
pokazl ""
pokazl "================================"
pokazl ""

pokazl "3. Przygotowanie kawy czarnej (bez dodatków):"
niech kawa_czarna = KawaCzarna.nowy()
kawa_czarna.przygotuj()
pokazl ""
pokazl "================================"
pokazl ""

pokazl "4. Generowanie raportu sprzedaży (z eksportem):"
niech raport_sprzedaz = RaportSprzedazy.nowy()
raport_sprzedaz.generuj()
pokazl ""
pokazl "================================"
pokazl ""

pokazl "5. Generowanie raportu kadrowego (bez eksportu):"
niech raport_kadry = RaportKadrowy.nowy()
raport_kadry.generuj()