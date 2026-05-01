abstrakcyjna klasa FabrykaMebli {
    funkcja konstruktor() {}
    
    funkcja stworz_krzeslo() {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja stworz_stol() {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa FabrykaNowoczesnych < FabrykaMebli {
    funkcja stworz_krzeslo() {
        zwroc KrzesloNowoczesne.nowy()
    }
    
    funkcja stworz_stol() {
        zwroc StolNowoczesny.nowy()
    }
}

klasa FabrykaWiktorianska < FabrykaMebli {
    funkcja stworz_krzeslo() {
        zwroc KrzesloWiktorianski.nowy()
    }
    
    funkcja stworz_stol() {
        zwroc StolWiktorianski.nowy()
    }
}

klasa KrzesloNowoczesne {
    funkcja konstruktor() {}
    
    funkcja opisz() {
        zwroc "Nowoczesne krzeslo z aluminium"
    }
}

klasa StolNowoczesny {
    funkcja konstruktor() {}
    
    funkcja opisz() {
        zwroc "Nowoczesny stol szklany"
    }
}

klasa KrzesloWiktorianski {
    funkcja konstruktor() {}
    
    funkcja opisz() {
        zwroc "Wiktoriańskie krzeslo drewniane"
    }
}

klasa StolWiktorianski {
    funkcja konstruktor() {}
    
    funkcja opisz() {
        zwroc "Wiktoriański stol z rzeźbieniami"
    }
}

funkcja umebluj_pokoj(fabryka) {
    niech krzeslo = fabryka.stworz_krzeslo()
    niech stol = fabryka.stworz_stol()
    
    pokazl "Meble w pokoju:"
    pokazl "  - " + krzeslo.opisz()
    pokazl "  - " + stol.opisz()
}




pokazl "=== Test Abstract Factory ==="
pokazl ""

pokazl "Styl nowoczesny:"
niech fabryka1 = FabrykaNowoczesnych.nowy()
umebluj_pokoj(fabryka1)
pokazl ""

pokazl "Styl wiktoriański:"
niech fabryka2 = FabrykaWiktorianska.nowy()
umebluj_pokoj(fabryka2)