klasa StaryPrinter {
    funkcja konstruktor() {}
    
    funkcja drukuj_tekst(tekst) {
        pokazl "[STARY PRINTER] Drukowanie: " + tekst
    }
}

klasa NowyPrinter {
    funkcja konstruktor() {}
    
    funkcja wydrukuj(dokument) {
        pokazl "[NOWY PRINTER] Dokument: " + dokument["tytul"]
        pokazl "[NOWY PRINTER] Zawartość: " + dokument["tresc"]
    }
}

klasa AdapterPrinter {
    funkcja konstruktor(stary_printer) {
        niech @printer = stary_printer
    }
    
    funkcja wydrukuj(dokument) {
        niech tekst = dokument["tytul"] + " - " + dokument["tresc"]
        @printer.drukuj_tekst(tekst)
    }
}

funkcja drukuj_dokument(printer, dokument) {
    printer.wydrukuj(dokument)
}



pokazl "=== Test Adapter ==="
pokazl ""

niech dokument = {
    "tytul": "Raport Q4",
    "tresc": "Wyniki finansowe za czwarty kwartał"
}

pokazl "Używam nowego printera:"
niech nowy = NowyPrinter.nowy()
drukuj_dokument(nowy, dokument)
pokazl ""

pokazl "Używam starego printera (przez adapter):"
niech stary = StaryPrinter.nowy()
niech adapter = AdapterPrinter.nowy(stary)
drukuj_dokument(adapter, dokument)