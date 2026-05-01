abstrakcyjna klasa Napoj {
    funkcja konstruktor() {}
    
    funkcja opis() {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja koszt() {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa Kawa < Napoj {
    funkcja opis() {
        zwroc "Kawa"
    }
    
    funkcja koszt() {
        zwroc 5
    }
}

klasa Herbata < Napoj {
    funkcja opis() {
        zwroc "Herbata"
    }
    
    funkcja koszt() {
        zwroc 4
    }
}

modul DodatekMleko {
    funkcja opis() {
        zwroc @bazowy_opis + " + mleko"
    }
    
    funkcja koszt() {
        zwroc @bazowy_koszt + 2
    }
}

modul DodatekCukier {
    funkcja opis() {
        zwroc @bazowy_opis + " + cukier"
    }
    
    funkcja koszt() {
        zwroc @bazowy_koszt + 1
    }
}

modul DodatekBita {
    funkcja opis() {
        zwroc @bazowy_opis + " + bita śmietana"
    }
    
    funkcja koszt() {
        zwroc @bazowy_koszt + 3
    }
}

klasa KawaZMlekiem < Kawa {
    dolacz DodatekMleko
    
    funkcja konstruktor() {
        super()
        niech @bazowy_opis = super.opis()
        niech @bazowy_koszt = super.koszt()
    }
}

klasa KawaDeluxe < Kawa {
    dolacz DodatekMleko
    dolacz DodatekCukier
    dolacz DodatekBita
    
    funkcja konstruktor() {
        super()
        niech bazowy = super.opis()
        niech @bazowy_opis = bazowy + " + mleko + cukier"
        niech @bazowy_koszt = super.koszt() + 2 + 1
    }
}


pokazl "=== Test Decorator ==="
pokazl ""

niech kawa_prosta = Kawa.nowy()
pokazl kawa_prosta.opis() + " - " + kawa_prosta.koszt() + " zł"

niech herbata = Herbata.nowy()
pokazl herbata.opis() + " - " + herbata.koszt() + " zł"

niech kawa_mleko = KawaZMlekiem.nowy()
pokazl kawa_mleko.opis() + " - " + kawa_mleko.koszt() + " zł"

niech kawa_deluxe = KawaDeluxe.nowy()
pokazl kawa_deluxe.opis() + " - " + kawa_deluxe.koszt() + " zł"