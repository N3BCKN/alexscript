klasa Samochod {
    funkcja konstruktor() {
        niech @marka = "Nieznana"
        niech @silnik = "Brak"
        niech @kolor = "Szary"
        niech @liczba_miejsc = 5
    }
    
    funkcja ustaw_marke(marka) {
        niech @marka = marka
    }
    
    funkcja ustaw_silnik(silnik) {
        niech @silnik = silnik
    }
    
    funkcja ustaw_kolor(kolor) {
        niech @kolor = kolor
    }
    
    funkcja ustaw_miejsca(miejsca) {
        niech @liczba_miejsc = miejsca
    }
    
    funkcja specyfikacja() {
        zwroc @marka + " " + @kolor + ", silnik: " + @silnik + ", miejsc: " + @liczba_miejsc
    }
}

klasa BudowniczySamochodu {
    funkcja konstruktor() {
        niech @samochod = Samochod.nowy()
    }
    
    funkcja ustaw_marke(marka) {
        @samochod.ustaw_marke(marka)
        zwroc @
    }
    
    funkcja ustaw_silnik(silnik) {
        @samochod.ustaw_silnik(silnik)
        zwroc @
    }
    
    funkcja ustaw_kolor(kolor) {
        @samochod.ustaw_kolor(kolor)
        zwroc @
    }
    
    funkcja ustaw_miejsca(miejsca) {
        @samochod.ustaw_miejsca(miejsca)
        zwroc @
    }
    
    funkcja zbuduj() {
        zwroc @samochod
    }
    
    funkcja reset() {
        niech @samochod = Samochod.nowy()
        zwroc @
    }
}

klasa DyrektorBudowy {
    funkcja konstruktor(budowniczy) {
        niech @budowniczy = budowniczy
    }
    
    funkcja zbuduj_auto_sportowe() {
        zwroc @budowniczy
            .reset()
            .ustaw_marke("Ferrari")
            .ustaw_silnik("V8 Turbo")
            .ustaw_kolor("Czerwony")
            .ustaw_miejsca(2)
            .zbuduj()
    }
    
    funkcja zbuduj_auto_rodzinne() {
        zwroc @budowniczy
            .reset()
            .ustaw_marke("Volkswagen")
            .ustaw_silnik("2.0 TDI")
            .ustaw_kolor("Niebieski")
            .ustaw_miejsca(7)
            .zbuduj()
    }
}


pokazl "=== Test Builder ==="
pokazl ""

niech budowniczy = BudowniczySamochodu.nowy()
niech dyrektor = DyrektorBudowy.nowy(budowniczy)

pokazl "Auto sportowe:"
niech sportowy = dyrektor.zbuduj_auto_sportowe()
pokazl sportowy.specyfikacja()
pokazl ""

pokazl "Auto rodzinne:"
niech rodzinny = dyrektor.zbuduj_auto_rodzinne()
pokazl rodzinny.specyfikacja()
pokazl ""

pokazl "Auto custom (bez dyrektora):"
niech custom = budowniczy
    .reset()
    .ustaw_marke("Tesla")
    .ustaw_silnik("Elektryczny 500kW")
    .ustaw_kolor("Biały")
    .ustaw_miejsca(5)
    .zbuduj()
pokazl custom.specyfikacja()
