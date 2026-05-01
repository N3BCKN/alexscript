klasa EdytorMemento {
    funkcja konstruktor(tresc, kursor) {
        niech @tresc = tresc
        niech @kursor = kursor
    }
    
    funkcja pobierz_tresc() {
        zwroc @tresc
    }
    
    funkcja pobierz_kursor() {
        zwroc @kursor
    }
}

klasa EdytorTekstu {
    funkcja konstruktor() {
        niech @tresc = ""
        niech @pozycja_kursora = 0
    }
    
    funkcja wpisz(tekst) {
        niech @tresc = @tresc + tekst
        niech @pozycja_kursora = @tresc.dlg
        pokazl "Wpisano: '" + tekst + "'"
    }
    
    funkcja usun_znaki(ilosc) {
        jesli @tresc.dlg >= ilosc {
            niech nowa_dlugosc = @tresc.dlg - ilosc
            niech @tresc = @tresc.wydziel(0, nowa_dlugosc)
            niech @pozycja_kursora = @tresc.dlg
            pokazl "Usunięto " + ilosc + " znaków"
        }
    }
    
    funkcja utworz_memento() {
        zwroc EdytorMemento.nowy(@tresc, @pozycja_kursora)
    }
    
    funkcja przywroc_z_memento(memento) {
        niech @tresc = memento.pobierz_tresc()
        niech @pozycja_kursora = memento.pobierz_kursor()
        pokazl "Przywrócono stan"
    }
    
    funkcja wyswietl() {
        pokazl "Treść: '" + @tresc + "' (kursor: " + @pozycja_kursora + ")"
    }
}

klasa Historia {
    funkcja konstruktor() {
        niech @stany = []
    }
    
    funkcja zapisz(memento) {
        @stany.dodaj(memento)
        pokazl "[HISTORIA] Zapisano stan #" + @stany.dlg
    }
    
    funkcja cofnij() {
        jesli @stany.dlg > 0 {
            niech stan = @stany[@stany.dlg - 1]
            @stany.usun(@stany.dlg - 1)
            pokazl "[HISTORIA] Cofnięto do stanu #" + @stany.dlg
            zwroc stan
        }
        pokazl "[HISTORIA] Brak stanów do cofnięcia"
        zwroc nic
    }
    
    funkcja rozmiar() {
        zwroc @stany.dlg
    }
}


pokazl "=== Test Memento ==="
pokazl ""

niech edytor = EdytorTekstu.nowy()
niech historia = Historia.nowy()

pokazl "Stan początkowy:"
edytor.wyswietl()
pokazl ""

pokazl "Operacja 1:"
edytor.wpisz("Hello")
historia.zapisz(edytor.utworz_memento())
edytor.wyswietl()
pokazl ""

pokazl "Operacja 2:"
edytor.wpisz(" World")
historia.zapisz(edytor.utworz_memento())
edytor.wyswietl()
pokazl ""

pokazl "Operacja 3:"
edytor.wpisz("!!!")
historia.zapisz(edytor.utworz_memento())
edytor.wyswietl()
pokazl ""

pokazl "Cofam ostatnią operację:"
niech memento = historia.cofnij()
jesli memento != nic {
    edytor.przywroc_z_memento(memento)
}
edytor.wyswietl()
pokazl ""

pokazl "Cofam jeszcze raz:"
niech memento2 = historia.cofnij()
jesli memento2 != nic {
    edytor.przywroc_z_memento(memento2)
}
edytor.wyswietl()
pokazl ""

pokazl "Nowa operacja po cofnięciu:"
edytor.wpisz(" AlexScript")
historia.zapisz(edytor.utworz_memento())
edytor.wyswietl()