abstrakcyjna klasa Mediator {
    funkcja konstruktor() {}
    
    funkcja powiadom(nadawca, wydarzenie) {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa MediatorWiezyKontroli < Mediator {
    funkcja konstruktor() {
        super()
        niech @samoloty = []
    }
    
    funkcja zarejestruj_samolot(samolot) {
        @samoloty.dodaj(samolot)
        samolot.ustaw_mediatora(@)
    }
    
    funkcja powiadom(nadawca, wydarzenie) {
        pokazl "  [WIEŻA] Otrzymano: " + wydarzenie + " od " + nadawca.pobierz_id()
        
        jesli wydarzenie == "prosba_o_ladowanie" {
            pokazl "  [WIEŻA] Sprawdzam pas startowy..."
            pokazl "  [WIEŻA] → Zezwalam na lądowanie: " + nadawca.pobierz_id()
            nadawca.otrzymaj_wiadomosc("ladowanie_zatwierdzone")
        } albojesli wydarzenie == "gotowy_do_startu" {
            pokazl "  [WIEŻA] → Zezwalam na start: " + nadawca.pobierz_id()
            nadawca.otrzymaj_wiadomosc("start_zatwierdzony")
            
            dla samolot w @samoloty {
                jesli !samolot.identyczny(nadawca) {
                    samolot.otrzymaj_wiadomosc("uwaga_start_innego_samolotu")
                }
            }
        }
    }
}

klasa Samolot {
    funkcja konstruktor(id) {
        niech @id = id
        niech @mediator = nic
    }
    
    funkcja ustaw_mediatora(mediator) {
        niech @mediator = mediator
    }
    
    funkcja pobierz_id() {
        zwroc @id
    }
    
    funkcja prosba_ladowanie() {
        pokazl @id + ": Proszę o pozwolenie na lądowanie"
        jesli @mediator != nic {
            @mediator.powiadom(@, "prosba_o_ladowanie")
        }
    }
    
    funkcja prosba_start() {
        pokazl @id + ": Gotowy do startu"
        jesli @mediator != nic {
            @mediator.powiadom(@, "gotowy_do_startu")
        }
    }
    
    funkcja otrzymaj_wiadomosc(wiadomosc) {
        pokazl @id + ": Otrzymano - " + wiadomosc
    }
}


pokazl "=== Test Mediator ==="
pokazl ""

niech wieza = MediatorWiezyKontroli.nowy()

niech samolot1 = Samolot.nowy("LOT123")
niech samolot2 = Samolot.nowy("RYN456")
niech samolot3 = Samolot.nowy("WIZ789")

wieza.zarejestruj_samolot(samolot1)
wieza.zarejestruj_samolot(samolot2)
wieza.zarejestruj_samolot(samolot3)
pokazl ""

pokazl "Scenariusz 1: Lądowanie"
samolot1.prosba_ladowanie()
pokazl ""

pokazl "Scenariusz 2: Start (powiadamia inne samoloty)"
samolot2.prosba_start()
pokazl ""

pokazl "Scenariusz 3: Kolejne lądowanie"
samolot3.prosba_ladowanie()