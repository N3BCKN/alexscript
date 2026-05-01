abstrakcyjna klasa ElementDokumentu {
    funkcja konstruktor() {}
    
    funkcja akceptuj(visitor) {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa Tekst < ElementDokumentu {
    funkcja konstruktor(tresc) {
        super()
        niech @tresc = tresc
    }
    
    funkcja pobierz_tresc() {
        zwroc @tresc
    }
    
    funkcja akceptuj(visitor) {
        zwroc visitor.odwiedz_tekst(pobierz_tresc())
    }
}

klasa Obraz < ElementDokumentu {
    funkcja konstruktor(sciezka, szerokosc, wysokosc) {
        super()
        niech @sciezka = sciezka
        niech @szerokosc = szerokosc
        niech @wysokosc = wysokosc
    }
    
    funkcja pobierz_sciezke() {
        zwroc @sciezka
    }
    
    funkcja pobierz_wymiary() {
        zwroc @szerokosc + "x" + @wysokosc
    }
    
    funkcja akceptuj(visitor) {
        zwroc visitor.odwiedz_obraz(pobierz_sciezke(), pobierz_wymiary())
    }
}

klasa Tabela < ElementDokumentu {
    funkcja konstruktor(wiersze, kolumny) {
        super()
        niech @wiersze = wiersze
        niech @kolumny = kolumny
    }
    
    funkcja pobierz_wiersze() {
        zwroc @wiersze
    }
    
    funkcja pobierz_kolumny() {
        zwroc @kolumny
    }
    
    funkcja akceptuj(visitor) {
        zwroc visitor.odwiedz_tabele(pobierz_wiersze(), pobierz_kolumny())
    }
}

abstrakcyjna klasa VisitorDokumentu {
    funkcja konstruktor() {}
    
    funkcja odwiedz_tekst(tresc) {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja odwiedz_obraz(sciezka, wymiary) {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja odwiedz_tabele(wiersze, kolumny) {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa EksporterHTML < VisitorDokumentu {
    funkcja konstruktor() {
        super()
        niech @html = ""
    }
    
    funkcja odwiedz_tekst(tresc) {
        niech fragment = "<p>" + tresc + "</p>"
        niech @html = @html + fragment
        pokazl "  [HTML] " + fragment
    }
    
    funkcja odwiedz_obraz(sciezka, wymiary) {
        niech fragment = "<img src='" + sciezka + "' width='" + wymiary + "'>"
        niech @html = @html + fragment
        pokazl "  [HTML] " + fragment
    }
    
    funkcja odwiedz_tabele(wiersze, kolumny) {
        niech fragment = "<table rows='" + wiersze + "' cols='" + kolumny + "'></table>"
        niech @html = @html + fragment
        pokazl "  [HTML] " + fragment
    }
    
    funkcja pobierz_wynik() {
        zwroc @html
    }
}

klasa AnalizatorRozmiar < VisitorDokumentu {
    funkcja konstruktor() {
        super()
        niech @calkowity_rozmiar = 0
    }
    
    funkcja odwiedz_tekst(tresc) {
        niech rozmiar = tresc.dlg
        niech @calkowity_rozmiar = @calkowity_rozmiar + rozmiar
        pokazl "  [ROZMIAR] Tekst: " + rozmiar + " znaków"
    }
    
    funkcja odwiedz_obraz(sciezka, wymiary) {
        niech rozmiar = 1500
        niech @calkowity_rozmiar = @calkowity_rozmiar + rozmiar
        pokazl "  [ROZMIAR] Obraz: ~" + rozmiar + " KB"
    }
    
    funkcja odwiedz_tabele(wiersze, kolumny) {
        niech rozmiar = wiersze * kolumny * 10
        niech @calkowity_rozmiar = @calkowity_rozmiar + rozmiar
        pokazl "  [ROZMIAR] Tabela: ~" + rozmiar + " bajtów"
    }
    
    funkcja pobierz_calkowity_rozmiar() {
        zwroc @calkowity_rozmiar
    }
}

klasa WalidatorTresci < VisitorDokumentu {
    funkcja konstruktor() {
        super()
        niech @bledy = []
    }
    
    funkcja odwiedz_tekst(tresc) {
        jesli tresc.dlg < 10 {
            @bledy.dodaj("Tekst za krótki (min. 10 znaków)")
            pokazl "  [WALIDACJA] ✗ Tekst za krótki"
        } albo {
            pokazl "  [WALIDACJA] ✓ Tekst OK"
        }
    }
    
    funkcja odwiedz_obraz(sciezka, wymiary) {
        jesli !sciezka.zawiera(".jpg") i !sciezka.zawiera(".png") {
            @bledy.dodaj("Nieobsługiwany format obrazu")
            pokazl "  [WALIDACJA] ✗ Zły format obrazu"
        } albo {
            pokazl "  [WALIDACJA] ✓ Obraz OK"
        }
    }
    
    funkcja odwiedz_tabele(wiersze, kolumny) {
        jesli wiersze < 1 lub kolumny < 1 {
            @bledy.dodaj("Tabela musi mieć przynajmniej 1 wiersz i 1 kolumnę")
            pokazl "  [WALIDACJA] ✗ Tabela nieprawidłowa"
        } albo {
            pokazl "  [WALIDACJA] ✓ Tabela OK"
        }
    }
    
    funkcja czy_jest_poprawny() {
        zwroc @bledy.dlg == 0
    }
    
    funkcja pobierz_bledy() {
        zwroc @bledy
    }
}

klasa Dokument {
    funkcja konstruktor() {
        niech @elementy = []
    }
    
    funkcja dodaj(element) {
        @elementy.dodaj(element)
    }
    
    funkcja akceptuj_visitor(visitor) {
        dla element w @elementy {
            element.akceptuj(visitor)
        }
    }
}


pokazl "=== Test Visitor ==="
pokazl ""

niech dokument = Dokument.nowy()
dokument.dodaj(Tekst.nowy("Witaj w AlexScript! To jest przykładowy dokument."))
dokument.dodaj(Obraz.nowy("logo.png", 200, 100))
dokument.dodaj(Tabela.nowy(5, 3))
dokument.dodaj(Tekst.nowy("Krótki"))
dokument.dodaj(Obraz.nowy("photo.jpg", 800, 600))

pokazl "1. Eksport do HTML:"
niech eksporter = EksporterHTML.nowy()
dokument.akceptuj_visitor(eksporter)
pokazl ""
pokazl "Wygenerowany HTML:"
pokazl eksporter.pobierz_wynik()
pokazl ""
pokazl "================================"
pokazl ""

pokazl "2. Analiza rozmiaru:"
niech analizator = AnalizatorRozmiar.nowy()
dokument.akceptuj_visitor(analizator)
pokazl ""
pokazl "Całkowity rozmiar: " + analizator.pobierz_calkowity_rozmiar()
pokazl ""
pokazl "================================"
pokazl ""

pokazl "3. Walidacja treści:"
niech walidator = WalidatorTresci.nowy()
dokument.akceptuj_visitor(walidator)
pokazl ""
jesli walidator.czy_jest_poprawny() {
    pokazl "✓ Dokument jest poprawny"
} albo {
    pokazl "✗ Znaleziono błędy:"
    niech bledy = walidator.pobierz_bledy()
    dla blad w bledy {
        pokazl "  - " + blad
    }
}