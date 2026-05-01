abstrakcyjna klasa ObslugaZgloszenia {
    funkcja konstruktor() {
        niech @nastepny = nic
    }
    
    funkcja ustaw_nastepny(obsluga) {
        niech @nastepny = obsluga
        zwroc obsluga
    }
    
    funkcja obsluz(zgloszenie) {
        jesli czy_moge_obsluzyc(zgloszenie) {
            przetwarzaj(zgloszenie)
        } albojesli @nastepny != nic {
            pokazl "  → Przekazuję dalej w łańcuchu"
            @nastepny.obsluz(zgloszenie)
        } albo {
            pokazl "  ✗ Brak obsługi dla poziomu: " + zgloszenie["poziom"]
        }
    }
    
    funkcja czy_moge_obsluzyc(zgloszenie) {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja przetwarzaj(zgloszenie) {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa ObslugaTechniczna < ObslugaZgloszenia {
    funkcja czy_moge_obsluzyc(zgloszenie) {
        zwroc zgloszenie["poziom"] == "techniczne"
    }
    
    funkcja przetwarzaj(zgloszenie) {
        pokazl "  [TECH] Obsługuję zgłoszenie: " + zgloszenie["tresc"]
        pokazl "  [TECH] Tworzę ticket w systemie IT"
    }
}

klasa ObslugaFinansowa < ObslugaZgloszenia {
    funkcja czy_moge_obsluzyc(zgloszenie) {
        zwroc zgloszenie["poziom"] == "finansowe"
    }
    
    funkcja przetwarzaj(zgloszenie) {
        pokazl "  [FINANSE] Obsługuję zgłoszenie: " + zgloszenie["tresc"]
        pokazl "  [FINANSE] Przekazuję do księgowości"
    }
}

klasa ObslugaKierownicza < ObslugaZgloszenia {
    funkcja czy_moge_obsluzyc(zgloszenie) {
        zwroc zgloszenie["poziom"] == "kierownicze"
    }
    
    funkcja przetwarzaj(zgloszenie) {
        pokazl "  [MANAGER] Obsługuję zgłoszenie: " + zgloszenie["tresc"]
        pokazl "  [MANAGER] Eskalacja do zarządu"
    }
}


pokazl "=== Test Chain of Responsibility ==="
pokazl ""

niech tech = ObslugaTechniczna.nowy()
niech finanse = ObslugaFinansowa.nowy()
niech manager = ObslugaKierownicza.nowy()

tech.ustaw_nastepny(finanse).ustaw_nastepny(manager)

niech zgloszenia = [
    {"poziom": "techniczne", "tresc": "Awaria serwera"},
    {"poziom": "finansowe", "tresc": "Zatwierdzenie budżetu"},
    {"poziom": "kierownicze", "tresc": "Decyzja strategiczna"},
    {"poziom": "inne", "tresc": "Nieznana kategoria"}
]

dla zgloszenie w zgloszenia {
    pokazl "Zgłoszenie: " + zgloszenie["tresc"]
    tech.obsluz(zgloszenie)
    pokazl ""
}