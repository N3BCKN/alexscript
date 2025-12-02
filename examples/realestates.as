# Model symulacji rynku nieruchomości

# Struktury danych reprezentujące rynek
niech POCZATKOWA_LICZBA_MIESZKAN = 1000
niech POCZATKOWA_POPULACJA = 10000
niech POCZATKOWA_STOPA_PROCENTOWA = 3.5
niech POCZATKOWA_INFLACJA = 2.0

# Klasa reprezentująca mieszkanie
funkcja Mieszkanie() {
    niech self = {
        "powierzchnia": losuj(30, 120),
        "lokalizacja": losujLokalizacje(),
        "standard": losuj(1, 5),
        "cena": 0,
        "dostepne": prawda
    }
    
    funkcja obliczCene() {
        niech cena_bazowa = self["powierzchnia"] * 5000
        niech mnoznik_lokalizacji = {
            "centrum": 1.5,
            "przedmiescia": 1.0,
            "obrzeza": 0.7
        }
        
        niech cena = cena_bazowa * 
            mnoznik_lokalizacji[self["lokalizacja"]] * 
            (0.8 + (self["standard"] * 0.2))
            
        self["cena"] = cena
    }
    
    zwroc self
}

# Klasa reprezentująca rynek
funkcja Rynek() {
    niech self = {
        "mieszkania": [],
        "kupujacy": [],
        "stopa_procentowa": POCZATKOWA_STOPA_PROCENTOWA,
        "inflacja": POCZATKOWA_INFLACJA,
        "miesiac": 1,
        "rok": 2024,
        "historia_cen": [],
        "historia_transakcji": []
    }
    
    funkcja inicjalizuj() {
        dla niech i = 0; POCZATKOWA_LICZBA_MIESZKAN; 1 {
            niech mieszkanie = Mieszkanie()
            mieszkanie.obliczCene()
            self["mieszkania"].dodaj(mieszkanie)
        }
        
        dla niech i = 0; POCZATKOWA_POPULACJA; 1 {
            self["kupujacy"].dodaj(stworzKupujacego())
        }
    }
    
    funkcja stworzKupujacego() {
        zwroc {
            "budzet": losuj(200000, 1000000),
            "preferowana_powierzchnia": losuj(30, 120),
            "preferowana_lokalizacja": losujLokalizacje(),
            "sila_nabywcza": losuj(0.5, 1.5),
            "pilnosc_zakupu": losuj(0, 1)
        }
    }
    
    funkcja symulujMiesiac() {
        aktualizujParametryMakro()
        przeliczCenyMieszkan()
        wykonajTransakcje()
        aktualizujPopyt()
        aktualizujPodaz()
        
        self["miesiac"] = self["miesiac"] + 1
        jesli self["miesiac"] > 12 {
            self["miesiac"] = 1
            self["rok"] = self["rok"] + 1
        }
        
        zapiszStatystyki()
    }
    
    funkcja aktualizujParametryMakro() {
        # Symulacja zmian stóp procentowych
        niech zmiana = (losuj(-20, 20) / 100)
        self["stopa_procentowa"] = max(0.1, self["stopa_procentowa"] + zmiana)
        
        # Symulacja zmian inflacji
        niech zmiana_inflacji = (losuj(-10, 10) / 100)
        self["inflacja"] = max(0, self["inflacja"] + zmiana_inflacji)
        
        # Wpływ sezonu na rynek
        niech sezonowosc = obliczWspolczynnikSezonowy(self["miesiac"])
        
        # Symulacja wydarzeń losowych
        jesli losuj(1, 100) <= 5 {
            symulujWydarzenieSpecjalne()
        }
    }
    
    funkcja obliczWspolczynnikSezonowy(miesiac) {
        # Większy ruch na rynku wiosną i jesienią
        niech wspolczynniki = [
            0.9,  # Styczeń
            0.9,  # Luty
            1.1,  # Marzec
            1.2,  # Kwiecień
            1.2,  # Maj
            1.1,  # Czerwiec
            0.9,  # Lipiec
            0.8,  # Sierpień
            1.2,  # Wrzesień
            1.1,  # Październik
            0.9,  # Listopad
            0.8   # Grudzień
        ]
        zwroc wspolczynniki[miesiac - 1]
    }
    
    funkcja symulujWydarzenieSpecjalne() {
        niech wydarzenia = [
            {
                "nazwa": "kryzys_finansowy",
                "wplyw_ceny": -0.15,
                "wplyw_popyt": -0.3,
                "czas_trwania": 12
            },
            {
                "nazwa": "boom_gospodarczy",
                "wplyw_ceny": 0.2,
                "wplyw_popyt": 0.4,
                "czas_trwania": 6
            },
            {
                "nazwa": "zmiana_przepisow",
                "wplyw_ceny": 0.1,
                "wplyw_popyt": -0.1,
                "czas_trwania": 24
            },
            {
                "nazwa": "migracja",
                "wplyw_ceny": 0.05,
                "wplyw_popyt": 0.2,
                "czas_trwania": 18
            }
        ]
        
        niech wydarzenie = wydarzenia[losuj(0, wydarzenia.dlg - 1)]
        zastosujWydarzenie(wydarzenie)
    }
    
    funkcja przeliczCenyMieszkan() {
        dla niech mieszkanie w self["mieszkania"] {
            jesli mieszkanie["dostepne"] {
                niech wspolczynnik_inflacji = 1 + (self["inflacja"] / 100)
                niech wspolczynnik_stopy = 1 - ((self["stopa_procentowa"] - POCZATKOWA_STOPA_PROCENTOWA) / 100)
                niech sezonowosc = obliczWspolczynnikSezonowy(self["miesiac"])
                
                mieszkanie["cena"] = mieszkanie["cena"] * 
                    wspolczynnik_inflacji * 
                    wspolczynnik_stopy *
                    sezonowosc
            }
        }
    }
    
    funkcja wykonajTransakcje() {
        dla niech kupujacy w self["kupujacy"] {
            jesli kupujacy["pilnosc_zakupu"] > 0.7 {
                niech mieszkanie = znajdzOdpowiednieMieszkanie(kupujacy)
                jesli mieszkanie != nic {
                    zrealizujTransakcje(kupujacy, mieszkanie)
                }
            }
        }
    }
    
    funkcja znajdzOdpowiednieMieszkanie(kupujacy) {
        niech odpowiednie = []
        
        dla niech mieszkanie w self["mieszkania"] {
            jesli mieszkanie["dostepne"] i
               mieszkanie["cena"] <= kupujacy["budzet"] i
               abs(mieszkanie["powierzchnia"] - kupujacy["preferowana_powierzchnia"]) <= 20 {
                odpowiednie.dodaj(mieszkanie)
            }
        }
        
        jesli odpowiednie.dlg > 0 {
            zwroc odpowiednie[losuj(0, odpowiednie.dlg - 1)]
        }
        
        zwroc nic
    }
    
    funkcja zrealizujTransakcje(kupujacy, mieszkanie) {
        mieszkanie["dostepne"] = falsz
        
        self["historia_transakcji"].dodaj({
            "data": [self["rok"], self["miesiac"]],
            "cena": mieszkanie["cena"],
            "powierzchnia": mieszkanie["powierzchnia"],
            "lokalizacja": mieszkanie["lokalizacja"]
        })
        
        # Usunięcie kupującego z rynku
        niech index = self["kupujacy"].indeks(kupujacy)
        self["kupujacy"].usun(index)
    }
    
    funkcja aktualizujPopyt() {
        # Dodawanie nowych kupujących
        niech nowi_kupujacy = losuj(10, 50)
        dla niech i = 0; nowi_kupujacy; 1 {
            self["kupujacy"].dodaj(stworzKupujacego())
        }
        
        # Aktualizacja pilności zakupu
        dla niech kupujacy w self["kupujacy"] {
            kupujacy["pilnosc_zakupu"] = min(1, kupujacy["pilnosc_zakupu"] + 0.1)
        }
    }
    
    funkcja aktualizujPodaz() {
        # Dodawanie nowych mieszkań
        niech nowe_mieszkania = losuj(5, 20)
        dla niech i = 0; nowe_mieszkania; 1 {
            niech mieszkanie = Mieszkanie()
            mieszkanie.obliczCene()
            self["mieszkania"].dodaj(mieszkanie)
        }
    }
    
    funkcja zapiszStatystyki() {
        niech dostepne_mieszkania = []
        dla niech mieszkanie w self["mieszkania"] {
            jesli mieszkanie["dostepne"] {
                dostepne_mieszkania.dodaj(mieszkanie)
            }
        }
        
        niech srednia_cena = 0
        jesli dostepne_mieszkania.dlg > 0 {
            dla niech mieszkanie w dostepne_mieszkania {
                srednia_cena = srednia_cena + mieszkanie["cena"]
            }
            srednia_cena = srednia_cena / dostepne_mieszkania.dlg
        }
        
        self["historia_cen"].dodaj({
            "data": [self["rok"], self["miesiac"]],
            "srednia_cena": srednia_cena,
            "liczba_dostepnych": dostepne_mieszkania.dlg,
            "liczba_kupujacych": self["kupujacy"].dlg,
            "stopa_procentowa": self["stopa_procentowa"],
            "inflacja": self["inflacja"]
        })
    }
    
    funkcja raportMiesieczny() {
        niech ostatnie_statystyki = self["historia_cen"][self["historia_cen"].dlg - 1]
        
        pokazl "=== Raport za " + self["miesiac"] + "/" + self["rok"] + " ==="
        pokazl "Średnia cena: " + ostatnie_statystyki["srednia_cena"]
        pokazl "Dostępnych mieszkań: " + ostatnie_statystyki["liczba_dostepnych"]
        pokazl "Liczba kupujących: " + ostatnie_statystyki["liczba_kupujacych"]
        pokazl "Stopa procentowa: " + ostatnie_statystyki["stopa_procentowa"] + "%"
        pokazl "Inflacja: " + ostatnie_statystyki["inflacja"] + "%"
        pokazl "Liczba transakcji w tym miesiącu: " + 
            policzTransakcjeWMiesiacu(self["rok"], self["miesiac"])
    }
    
    funkcja policzTransakcjeWMiesiacu(rok, miesiac) {
        niech liczba = 0
        dla niech transakcja w self["historia_transakcji"] {
            jesli transakcja["data"][0] == rok i transakcja["data"][1] == miesiac {
                liczba = liczba + 1
            }
        }
        zwroc liczba
    }
    
    inicjalizuj()
    zwroc self
}

# Funkcje pomocnicze
funkcja losuj(min, max) {
    zwroc min + (random() * (max - min))
}

funkcja losujLokalizacje() {
    niech lokalizacje = ["centrum", "przedmiescia", "obrzeza"]
    zwroc lokalizacje[losuj(0, 2)]
}

# Uruchomienie symulacji
funkcja uruchomSymulacje(liczba_miesiecy) {
    niech rynek = Rynek()
    
    dla niech i = 0; liczba_miesiecy; 1 {
        rynek.symulujMiesiac()
        rynek.raportMiesieczny()
    }
    
    pokazl "\n=== Podsumowanie symulacji ==="
    pokazl "Zasymulowano " + liczba_miesiecy + " miesięcy"
    pokazl "Końcowa liczba transakcji: " + rynek["historia_transakcji"].dlg
    pokazl "Zmiana średniej ceny: " + 
        ((rynek["historia_cen"][rynek["historia_cen"].dlg - 1]["srednia_cena"] / 
          rynek["historia_cen"][0]["srednia_cena"] - 1) * 100) + "%"
}

# Start symulacji na 24 miesiące
uruchomSymulacje(24)