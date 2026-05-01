klasa SystemPlikow {
    funkcja konstruktor() {}
    
    funkcja wczytaj_plik(sciezka) {
        pokazl "  [FS] Wczytywanie pliku: " + sciezka
        zwroc "zawartość pliku " + sciezka
    }
    
    funkcja zapisz_plik(sciezka, dane) {
        pokazl "  [FS] Zapisywanie do: " + sciezka
    }
}

klasa Kompresja {
    funkcja konstruktor() {}
    
    funkcja skompresuj(dane) {
        pokazl "  [ZIP] Kompresja danych"
        zwroc "skompresowane:" + dane
    }
    
    funkcja dekompresuj(dane) {
        pokazl "  [ZIP] Dekompresja danych"
        zwroc dane
    }
}

klasa Szyfrowanie {
    funkcja konstruktor() {}
    
    funkcja zaszyfruj(dane, klucz) {
        pokazl "  [CRYPTO] Szyfrowanie kluczem: " + klucz
        zwroc "zaszyfrowane:" + dane
    }
    
    funkcja odszyfruj(dane, klucz) {
        pokazl "  [CRYPTO] Odszyfrowywanie kluczem: " + klucz
        zwroc dane
    }
}

klasa FasadaBezpieczenstwa {
    funkcja konstruktor() {
        niech @system_plikow = SystemPlikow.nowy()
        niech @kompresja = Kompresja.nowy()
        niech @szyfrowanie = Szyfrowanie.nowy()
    }
    
    funkcja zapisz_bezpiecznie(sciezka, dane, klucz) {
        pokazl "Bezpieczne zapisywanie..."
        
        niech skompresowane = @kompresja.skompresuj(dane)
        niech zaszyfrowane = @szyfrowanie.zaszyfruj(skompresowane, klucz)
        @system_plikow.zapisz_plik(sciezka, zaszyfrowane)
        
        pokazl "✓ Dane zapisane bezpiecznie"
    }
    
    funkcja wczytaj_bezpiecznie(sciezka, klucz) {
        pokazl "Bezpieczne wczytywanie..."
        
        niech dane = @system_plikow.wczytaj_plik(sciezka)
        niech odszyfrowane = @szyfrowanie.odszyfruj(dane, klucz)
        niech zdekompresowane = @kompresja.dekompresuj(odszyfrowane)
        
        pokazl "✓ Dane wczytane bezpiecznie"
        zwroc zdekompresowane
    }
}


pokazl "=== Test Facade ==="
pokazl ""

niech fasada = FasadaBezpieczen stwa.nowy()

niech dane_tajne = "Tajne informacje firmy XYZ"
niech klucz = "super-tajny-klucz-123"

fasada.zapisz_bezpiecznie("/secure/data.enc", dane_tajne, klucz)
pokazl ""

niech odczytane = fasada.wczytaj_bezpiecznie("/secure/data.enc", klucz)
pokazl ""
pokazl "Odczytano: " + odczytane