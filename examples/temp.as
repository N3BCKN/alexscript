          klasa Osoba {
            funkcja konstruktor(imie, wiek) {
              niech @imie = imie
              niech @wiek = wiek
            }
          }
          niech osoba = Osoba.nowy("Jan", 25)
          niech zmienne = osoba.zmienne_instancji()
          pokazl zmienne.zawiera("imie") i zmienne.zawiera("wiek")