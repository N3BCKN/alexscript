klasa Iterator {
    funkcja konstruktor(kolekcja) {
        niech @kolekcja = kolekcja
        niech @pozycja = 0
    }
    
    funkcja nastepny() {
        jesli ma_nastepny() {
            niech element = @kolekcja[@pozycja]
            niech @pozycja = @pozycja + 1
            zwroc element
        }
        zwroc nic
    }
    
    funkcja ma_nastepny() {
        zwroc @pozycja < @kolekcja.dlg
    }
    
    funkcja reset() {
        niech @pozycja = 0
    }
    
    funkcja aktualny() {
        jesli @pozycja > 0 i @pozycja <= @kolekcja.dlg {
            zwroc @kolekcja[@pozycja - 1]
        }
        zwroc nic
    }
}

klasa IteratorOdwrotny {
    funkcja konstruktor(kolekcja) {
        niech @kolekcja = kolekcja
        niech @pozycja = kolekcja.dlg - 1
    }
    
    funkcja nastepny() {
        jesli ma_nastepny() {
            niech element = @kolekcja[@pozycja]
            niech @pozycja = @pozycja - 1
            zwroc element
        }
        zwroc nic
    }
    
    funkcja ma_nastepny() {
        zwroc @pozycja >= 0
    }
    
    funkcja reset() {
        niech @pozycja = @kolekcja.dlg - 1
    }
}

klasa KolekcjaKsiazek {
    funkcja konstruktor() {
        niech @ksiazki = []
    }
    
    funkcja dodaj(tytul, autor) {
        @ksiazki.dodaj({"tytul": tytul, "autor": autor})
    }
    
    funkcja utworz_iterator() {
        zwroc Iterator.nowy(@ksiazki)
    }
    
    funkcja utworz_iterator_odwrotny() {
        zwroc IteratorOdwrotny.nowy(@ksiazki)
    }
    
    funkcja rozmiar() {
        zwroc @ksiazki.dlg
    }
}


pokazl "=== Test Iterator ==="
pokazl ""

niech biblioteka = KolekcjaKsiazek.nowy()
biblioteka.dodaj("Wiedźmin", "Andrzej Sapkowski")
biblioteka.dodaj("Solaris", "Stanisław Lem")
biblioteka.dodaj("Pan Tadeusz", "Adam Mickiewicz")
biblioteka.dodaj("Quo Vadis", "Henryk Sienkiewicz")

pokazl "Liczba książek: " + biblioteka.rozmiar()
pokazl ""

pokazl "Iteracja w przód:"
niech iterator = biblioteka.utworz_iterator()
dopoki iterator.ma_nastepny() {
    niech ksiazka = iterator.nastepny()
    pokazl "- " + ksiazka["tytul"] + " (" + ksiazka["autor"] + ")"
}
pokazl ""

pokazl "Iteracja wstecz:"
niech iterator_odw = biblioteka.utworz_iterator_odwrotny()
dopoki iterator_odw.ma_nastepny() {
    niech ksiazka = iterator_odw.nastepny()
    pokazl "- " + ksiazka["tytul"] + " (" + ksiazka["autor"] + ")"
}
pokazl ""

pokazl "Reset i ponowna iteracja (pierwsze 2):"
iterator.reset()
niech licznik = 0
dopoki iterator.ma_nastepny() i licznik < 2 {
    niech ksiazka = iterator.nastepny()
    pokazl "- " + ksiazka["tytul"]
    niech licznik = licznik + 1
}