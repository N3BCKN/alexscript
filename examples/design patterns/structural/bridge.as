abstrakcyjna klasa Ksztalt {
    funkcja konstruktor(kolor) {
        niech @kolor = kolor
    }
    
    funkcja rysuj() {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa Kolo < Ksztalt {
    funkcja konstruktor(kolor, promien) {
        super(kolor)
        niech @promien = promien
    }
    
    funkcja rysuj() {
        niech opis = @kolor.zastosuj("koło o promieniu " + @promien)
        pokazl opis
    }
}

klasa Kwadrat < Ksztalt {
    funkcja konstruktor(kolor, bok) {
        super(kolor)
        niech @bok = bok
    }
    
    funkcja rysuj() {
        niech opis = @kolor.zastosuj("kwadrat o boku " + @bok)
        pokazl opis
    }
}

abstrakcyjna klasa Kolor {
    funkcja konstruktor() {}
    
    funkcja zastosuj(obiekt) {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa KolorCzerwony < Kolor {
    funkcja zastosuj(obiekt) {
        zwroc "Rysuje czerwony " + obiekt
    }
}

klasa KolorNiebieski < Kolor {
    funkcja zastosuj(obiekt) {
        zwroc "Rysuje niebieski " + obiekt
    }
}

klasa KolorZielony < Kolor {
    funkcja zastosuj(obiekt) {
        zwroc "Rysuje zielony " + obiekt
    }
}


pokazl "=== Test Bridge ==="
pokazl ""

niech czerwony = KolorCzerwony.nowy()
niech niebieski = KolorNiebieski.nowy()
niech zielony = KolorZielony.nowy()

niech kolo1 = Kolo.nowy(czerwony, 5)
niech kolo2 = Kolo.nowy(niebieski, 10)

niech kwadrat1 = Kwadrat.nowy(zielony, 7)
niech kwadrat2 = Kwadrat.nowy(czerwony, 3)

kolo1.rysuj()
kolo2.rysuj()
kwadrat1.rysuj()
kwadrat2.rysuj()