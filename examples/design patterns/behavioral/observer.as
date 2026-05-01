abstrakcyjna klasa Obserwator {
    funkcja konstruktor() {}
    
    funkcja aktualizuj(temat, dane) {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa Temat {
    funkcja konstruktor() {
        niech @obserwatorzy = []
    }
    
    funkcja dodaj_obserwatora(obserwator) {
        @obserwatorzy.dodaj(obserwator)
        pokazl "  [TEMAT] Dodano obserwatora"
    }
    
    funkcja usun_obserwatora(obserwator) {
        niech indeks = 0
        dla obs w @obserwatorzy {
            jesli obs.identyczny(obserwator) {
                @obserwatorzy.usun(indeks)
                pokazl "  [TEMAT] Usunięto obserwatora"
                zwroc prawda
            }
            niech indeks = indeks + 1
        }
        zwroc falsz
    }
    
    funkcja powiadom_wszystkich(dane) {
        pokazl "  [TEMAT] Powiadamiam " + @obserwatorzy.dlg + " obserwatorów"
        dla obserwator w @obserwatorzy {
            obserwator.aktualizuj(@, dane)
        }
    }
}

klasa StacjaMeteo < Temat {
    funkcja konstruktor() {
        super()
        niech @temperatura = 0
        niech @cisnienie = 0
        niech @wilgotnosc = 0
    }
    
    funkcja ustaw_pomiary(temp, cisn, wilg) {
        pokazl "[STACJA] Nowe pomiary: " + temp + "°C, " + cisn + " hPa, " + wilg + "%"
        niech @temperatura = temp
        niech @cisnienie = cisn
        niech @wilgotnosc = wilg
        
        niech dane = {
            "temperatura": temp,
            "cisnienie": cisn,
            "wilgotnosc": wilg
        }
        
        powiadom_wszystkich(dane)
    }
    
    funkcja pobierz_temperature() {
        zwroc @temperatura
    }
    
    funkcja pobierz_cisnienie() {
        zwroc @cisnienie
    }
    
    funkcja pobierz_wilgotnosc() {
        zwroc @wilgotnosc
    }
}

klasa WyswietlaczBiezacy < Obserwator {
    funkcja konstruktor() {
        super()
    }
    
    funkcja aktualizuj(temat, dane) {
        pokazl "  [WYŚWIETLACZ BIEŻĄCY]"
        pokazl "    Temperatura: " + dane["temperatura"] + "°C"
        pokazl "    Ciśnienie: " + dane["cisnienie"] + " hPa"
        pokazl "    Wilgotność: " + dane["wilgotnosc"] + "%"
    }
}

klasa WyswietlaczStatystyki < Obserwator {
    funkcja konstruktor() {
        super()
        niech @temperatury = []
        niech @suma = 0
    }
    
    funkcja aktualizuj(temat, dane) {
        niech temp = dane["temperatura"]
        @temperatury.dodaj(temp)
        niech @suma = @suma + temp
        
        niech srednia = @suma / @temperatury.dlg
        
        pokazl "  [WYŚWIETLACZ STATYSTYKI]"
        pokazl "    Pomiarów: " + @temperatury.dlg
        pokazl "    Średnia temperatura: " + srednia + "°C"
    }
}

klasa SystemAlarmowy < Obserwator {
    funkcja konstruktor(prog_temp) {
        super()
        niech @prog_temperatury = prog_temp
    }
    
    funkcja aktualizuj(temat, dane) {
        niech temp = dane["temperatura"]
        
        jesli temp > @prog_temperatury {
            pokazl "  [ALARM] ⚠️  UWAGA! Temperatura " + temp + "°C przekroczyła próg " + @prog_temperatury + "°C!"
        } albojesli temp < 0 {
            pokazl "  [ALARM] ❄️  UWAGA! Temperatura poniżej zera: " + temp + "°C!"
        }
    }
}


pokazl "=== Test Observer ==="
pokazl ""

niech stacja = StacjaMeteo.nowy()

niech wyswietlacz1 = WyswietlaczBiezacy.nowy()
niech wyswietlacz2 = WyswietlaczStatystyki.nowy()
niech alarm = SystemAlarmowy.nowy(30)

pokazl "Rejestracja obserwatorów:"
stacja.dodaj_obserwatora(wyswietlacz1)
stacja.dodaj_obserwatora(wyswietlacz2)
stacja.dodaj_obserwatora(alarm)
pokazl ""

pokazl "=== Pomiar 1 ==="
stacja.ustaw_pomiary(25, 1013, 65)
pokazl ""

pokazl "=== Pomiar 2 ==="
stacja.ustaw_pomiary(28, 1015, 60)
pokazl ""

pokazl "=== Pomiar 3 (alarm temperatura) ==="
stacja.ustaw_pomiary(35, 1012, 55)
pokazl ""

pokazl "=== Pomiar 4 (alarm mróz) ==="
stacja.ustaw_pomiary(-5, 1020, 80)
pokazl ""

pokazl "Usuwam wyświetlacz bieżący:"
stacja.usun_obserwatora(wyswietlacz1)
pokazl ""

pokazl "=== Pomiar 5 (bez wyświetlacza bieżącego) ==="
stacja.ustaw_pomiary(22, 1018, 70)