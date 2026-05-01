abstrakcyjna klasa FabrykaPojazdow {
    funkcja konstruktor() {}
    
    funkcja stworz_pojazd() {
        rzuc "Metoda abstrakcyjna - zaimplementuj w klasie pochodnej"
    }
    
    funkcja dostarcz_pojazd() {
        niech pojazd = stworz_pojazd()
        pokazl "Dostarczam: " + pojazd.opisz()
        zwroc pojazd
    }
}

klasa FabrykaSamochodow < FabrykaPojazdow {
    funkcja stworz_pojazd() {
        zwroc Samochod.nowy()
    }
}

klasa FabrykaMotocykli < FabrykaPojazdow {
    funkcja stworz_pojazd() {
        zwroc Motocykl.nowy()
    }
}

klasa Samochod {
    funkcja konstruktor() {}
    
    funkcja opisz() {
        zwroc "Samochod (4 kola)"
    }
    
    funkcja jedz() {
        zwroc "Samochod jedzie po drodze"
    }
}

klasa Motocykl {
    funkcja konstruktor() {}
    
    funkcja opisz() {
        zwroc "Motocykl (2 kola)"
    }
    
    funkcja jedz() {
        zwroc "Motocykl jedzie szybko"
    }
}


# test 

pokazl "=== Test Factory Method ==="
pokazl ""

niech fabryka_aut = FabrykaSamochodow.nowy()
niech fabryka_motocykli = FabrykaMotocykli.nowy()

niech auto = fabryka_aut.dostarcz_pojazd()
pokazl auto.jedz()
pokazl ""

niech motor = fabryka_motocykli.dostarcz_pojazd()
pokazl motor.jedz()
pokazl ""
