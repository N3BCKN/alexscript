abstrakcyjna klasa StanAutomatu {
    funkcja konstruktor() {}
    
    funkcja wloz_monete(automat) {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja zwroc_monete(automat) {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja wybierz_produkt(automat) {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja wydaj(automat) {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa StanBezMonety < StanAutomatu {
    funkcja wloz_monete(automat) {
        pokazl "  [STAN] Moneta włożona"
        automat.ustaw_stan(automat.pobierz_stan_z_moneta())
    }
    
    funkcja zwroc_monete(automat) {
        pokazl "  [STAN] Nie włożono monety"
    }
    
    funkcja wybierz_produkt(automat) {
        pokazl "  [STAN] Najpierw włóż monetę"
    }
    
    funkcja wydaj(automat) {
        pokazl "  [STAN] Najpierw zapłać"
    }
}

klasa StanZMoneta < StanAutomatu {
    funkcja wloz_monete(automat) {
        pokazl "  [STAN] Moneta już jest włożona"
    }
    
    funkcja zwroc_monete(automat) {
        pokazl "  [STAN] Moneta zwrócona"
        automat.ustaw_stan(automat.pobierz_stan_bez_monety())
    }
    
    funkcja wybierz_produkt(automat) {
        pokazl "  [STAN] Produkt wybrany"
        automat.ustaw_stan(automat.pobierz_stan_sprzedaz())
    }
    
    funkcja wydaj(automat) {
        pokazl "  [STAN] Najpierw wybierz produkt"
    }
}

klasa StanSprzedaz < StanAutomatu {
    funkcja wloz_monete(automat) {
        pokazl "  [STAN] Proszę czekać, wydajemy produkt"
    }
    
    funkcja zwroc_monete(automat) {
        pokazl "  [STAN] Za późno na zwrot"
    }
    
    funkcja wybierz_produkt(automat) {
        pokazl "  [STAN] Już wybrano produkt"
    }
    
    funkcja wydaj(automat) {
        pokazl "  [STAN] 🎁 Wydano produkt!"
        
        niech nowa_ilosc = automat.pobierz_ilosc() - 1
        automat.ustaw_ilosc(nowa_ilosc)
        
        jesli nowa_ilosc > 0 {
            automat.ustaw_stan(automat.pobierz_stan_bez_monety())
        } albo {
            pokazl "  [STAN] ⚠️  Automat pusty!"
            automat.ustaw_stan(automat.pobierz_stan_pusty())
        }
    }
}

klasa StanPusty < StanAutomatu {
    funkcja wloz_monete(automat) {
        pokazl "  [STAN] Automat pusty, moneta zwrócona"
    }
    
    funkcja zwroc_monete(automat) {
        pokazl "  [STAN] Nie włożono monety"
    }
    
    funkcja wybierz_produkt(automat) {
        pokazl "  [STAN] Automat pusty"
    }
    
    funkcja wydaj(automat) {
        pokazl "  [STAN] Automat pusty"
    }
}

klasa AutomatSprzedajacy {
    funkcja konstruktor(ilosc) {
        niech @stan_bez_monety = StanBezMonety.nowy()
        niech @stan_z_moneta = StanZMoneta.nowy()
        niech @stan_sprzedaz = StanSprzedaz.nowy()
        niech @stan_pusty = StanPusty.nowy()
        
        niech @ilosc_produktow = ilosc
        
        jesli ilosc > 0 {
            niech @aktualny_stan = @stan_bez_monety
        } albo {
            niech @aktualny_stan = @stan_pusty
        }
    }
    
    funkcja wloz_monete() {
        @aktualny_stan.wloz_monete(@)
    }
    
    funkcja zwroc_monete() {
        @aktualny_stan.zwroc_monete(@)
    }
    
    funkcja wybierz_produkt() {
        @aktualny_stan.wybierz_produkt(@)
    }
    
    funkcja obrot_korby() {
        pokazl "  [AUTOMAT] Obracam korbę..."
        @aktualny_stan.wydaj(@)
    }
    
    funkcja ustaw_stan(stan) {
        niech @aktualny_stan = stan
    }
    
    funkcja pobierz_stan_bez_monety() {
        zwroc @stan_bez_monety
    }
    
    funkcja pobierz_stan_z_moneta() {
        zwroc @stan_z_moneta
    }
    
    funkcja pobierz_stan_sprzedaz() {
        zwroc @stan_sprzedaz
    }
    
    funkcja pobierz_stan_pusty() {
        zwroc @stan_pusty
    }
    
    funkcja pobierz_ilosc() {
        zwroc @ilosc_produktow
    }
    
    funkcja ustaw_ilosc(ilosc) {
        niech @ilosc_produktow = ilosc
    }
    
    funkcja uzupelnij(ilosc) {
        niech @ilosc_produktow = @ilosc_produktow + ilosc
        pokazl "  [AUTOMAT] Uzupełniono " + ilosc + " produktów (razem: " + @ilosc_produktow + ")"
        
        jesli @ilosc_produktow > 0 {
            niech @aktualny_stan = @stan_bez_monety
        }
    }
}


pokazl "=== Test State ==="
pokazl ""

niech automat = AutomatSprzedajacy.nowy(3)

pokazl "Stan: 3 produkty"
pokazl ""

pokazl "1. Próba kupna (pełny cykl):"
automat.wloz_monete()
automat.wybierz_produkt()
automat.obrot_korby()
pokazl ""

pokazl "2. Włożenie monety i zwrot:"
automat.wloz_monete()
automat.zwroc_monete()
pokazl ""

pokazl "3. Próba bez monety:"
automat.wybierz_produkt()
automat.obrot_korby()
pokazl ""

pokazl "4. Drugi zakup:"
automat.wloz_monete()
automat.wybierz_produkt()
automat.obrot_korby()
pokazl ""

pokazl "5. Trzeci zakup (ostatni produkt):"
automat.wloz_monete()
automat.wybierz_produkt()
automat.obrot_korby()
pokazl ""

pokazl "6. Próba kupna z pustego automatu:"
automat.wloz_monete()
pokazl ""

pokazl "7. Uzupełnienie automatu:"
automat.uzupelnij(2)
pokazl ""

pokazl "8. Zakup po uzupełnieniu:"
automat.wloz_monete()
automat.wybierz_produkt()
automat.obrot_korby()