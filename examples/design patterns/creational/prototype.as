klasa Dokument {
    funkcja konstruktor(tytul, tresc) {
        niech @tytul = tytul
        niech @tresc = tresc
        niech @zakladki = []
        niech @metadane = {
            "autor": "Nieznany",
            "data": "2024"
        }
    }
    
    funkcja dodaj_zakladke(zakladka) {
        @zakladki.dodaj(zakladka)
    }
    
    funkcja ustaw_autora(autor) {
        @metadane["autor"] = autor
    }
    
    funkcja klonuj() {
        niech kopia = Dokument.nowy(@tytul, @tresc)
        
        dla zakladka w @zakladki {
            kopia.dodaj_zakladke(zakladka)
        }
        
        kopia.ustaw_autora(@metadane["autor"])
        
        zwroc kopia
    }
    
    funkcja wyswietl() {
        pokazl "=== " + @tytul + " ==="
        pokazl "Autor: " + @metadane["autor"]
        pokazl "Treść: " + @tresc
        pokazl "Zakładki: " + @zakladki.dlg
    }
    
    funkcja zmien_tytul(nowy_tytul) {
        niech @tytul = nowy_tytul
    }
    
    funkcja zmien_tresc(nowa_tresc) {
        niech @tresc = nowa_tresc
    }
}

klasa MenedzerSzablonow {
    funkcja konstruktor() {
        niech @szablony = {}
    }
    
    funkcja dodaj_szablon(nazwa, szablon) {
        @szablony[nazwa] = szablon
    }
    
    funkcja utworz_z_szablonu(nazwa) {
        niech szablon = @szablony[nazwa]
        jesli szablon == nic {
            rzuc "Nie znaleziono szablonu: " + nazwa
        }
        zwroc szablon.klonuj()
    }
}



pokazl "=== Test Prototype ==="
pokazl ""

niech szablon_raportu = Dokument.nowy("Raport miesięczny", "Sekcja danych...")
szablon_raportu.dodaj_zakladke("Wprowadzenie")
szablon_raportu.dodaj_zakladke("Wyniki")
szablon_raportu.dodaj_zakladke("Podsumowanie")
szablon_raportu.ustaw_autora("System")

niech menedzer = MenedzerSzablonow.nowy()
menedzer.dodaj_szablon("raport", szablon_raportu)

pokazl "Szablon oryginalny:"
szablon_raportu.wyswietl()
pokazl ""

pokazl "Dokument 1 (z szablonu):"
niech dok1 = menedzer.utworz_z_szablonu("raport")
dok1.zmien_tytul("Raport styczeń 2024")
dok1.ustaw_autora("Jan Kowalski")
dok1.wyswietl()
pokazl ""

pokazl "Dokument 2 (z szablonu):"
niech dok2 = menedzer.utworz_z_szablonu("raport")
dok2.zmien_tytul("Raport luty 2024")
dok2.ustaw_autora("Anna Nowak")
dok2.wyswietl()
pokazl ""

pokazl "Szablon (niezmieniony):"
szablon_raportu.wyswietl()