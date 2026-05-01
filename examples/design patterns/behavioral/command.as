abstrakcyjna klasa Polecenie {
    funkcja konstruktor() {}
    
    funkcja wykonaj() {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja cofnij() {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa Swiatlo {
    funkcja konstruktor(lokalizacja) {
        niech @lokalizacja = lokalizacja
        niech @wlaczone = falsz
    }
    
    funkcja wlacz() {
        niech @wlaczone = prawda
        pokazl "  [" + @lokalizacja + "] Światło WŁĄCZONE"
    }
    
    funkcja wylacz() {
        niech @wlaczone = falsz
        pokazl "  [" + @lokalizacja + "] Światło WYŁĄCZONE"
    }
}

klasa PolecenieWlaczSwiatlo < Polecenie {
    funkcja konstruktor(swiatlo) {
        super()
        niech @swiatlo = swiatlo
    }
    
    funkcja wykonaj() {
        @swiatlo.wlacz()
    }
    
    funkcja cofnij() {
        @swiatlo.wylacz()
    }
}

klasa PolecenieWylaczSwiatlo < Polecenie {
    funkcja konstruktor(swiatlo) {
        super()
        niech @swiatlo = swiatlo
    }
    
    funkcja wykonaj() {
        @swiatlo.wylacz()
    }
    
    funkcja cofnij() {
        @swiatlo.wlacz()
    }
}

klasa Stereo {
    funkcja konstruktor() {
        niech @wlaczone = falsz
        niech @glosnosc = 0
    }
    
    funkcja wlacz() {
        niech @wlaczone = prawda
        pokazl "  [STEREO] Włączone"
    }
    
    funkcja ustaw_glosnosc(poziom) {
        niech @glosnosc = poziom
        pokazl "  [STEREO] Głośność: " + poziom
    }
    
    funkcja wylacz() {
        niech @wlaczone = falsz
        niech @glosnosc = 0
        pokazl "  [STEREO] Wyłączone"
    }
}

klasa PolecenieMuzyka < Polecenie {
    funkcja konstruktor(stereo) {
        super()
        niech @stereo = stereo
        niech @poprzednia_glosnosc = 0
    }
    
    funkcja wykonaj() {
        @stereo.wlacz()
        @stereo.ustaw_glosnosc(50)
    }
    
    funkcja cofnij() {
        @stereo.wylacz()
    }
}

klasa PilotZdalny {
    funkcja konstruktor() {
        niech @historia = []
    }
    
    funkcja wykonaj_polecenie(polecenie) {
        polecenie.wykonaj()
        @historia.dodaj(polecenie)
    }
    
    funkcja cofnij_ostatnie() {
        jesli @historia.dlg > 0 {
            niech ostatnie = @historia[@historia.dlg - 1]
            ostatnie.cofnij()
            @historia.usun(@historia.dlg - 1)
        } albo {
            pokazl "  Brak poleceń do cofnięcia"
        }
    }
}


pokazl "=== Test Command ==="
pokazl ""

niech swiatlo_salon = Swiatlo.nowy("Salon")
niech swiatlo_sypialnia = Swiatlo.nowy("Sypialnia")
niech stereo = Stereo.nowy()

niech cmd_salon_on = PolecenieWlaczSwiatlo.nowy(swiatlo_salon)
niech cmd_salon_off = PolecenieWylaczSwiatlo.nowy(swiatlo_salon)
niech cmd_sypialnia_on = PolecenieWlaczSwiatlo.nowy(swiatlo_sypialnia)
niech cmd_muzyka = PolecenieMuzyka.nowy(stereo)

niech pilot = PilotZdalny.nowy()

pokazl "Włączam światło w salonie:"
pilot.wykonaj_polecenie(cmd_salon_on)
pokazl ""

pokazl "Włączam światło w sypialni:"
pilot.wykonaj_polecenie(cmd_sypialnia_on)
pokazl ""

pokazl "Włączam muzykę:"
pilot.wykonaj_polecenie(cmd_muzyka)
pokazl ""

pokazl "Cofam ostatnią operację (muzyka):"
pilot.cofnij_ostatnie()
pokazl ""

pokazl "Cofam ostatnią operację (światło sypialnia):"
pilot.cofnij_ostatnie()
pokazl ""

pokazl "Wyłączam światło w salonie:"
pilot.wykonaj_polecenie(cmd_salon_off)