        klasa PizzaBuilder {
            funkcja konstruktor() {
                niech @rozmiar = "srednia"
                niech @ser = falsz
                niech @pieczarki = falsz
            }
            
            funkcja z_serem() {
                niech @ser = prawda
                zwroc sam
            }
            
            funkcja z_pieczarkami() {
                niech @pieczarki = prawda
                zwroc sam
            }
            
            funkcja duza() {
                niech @rozmiar = "duza"
                zwroc sam
            }
            
            funkcja zbuduj() {
                niech liczba = 0
                jesli @ser {
                    liczba = liczba + 1     # ← POPRAWKA: bez 'niech'
                }
                jesli @pieczarki {
                    liczba = liczba + 1     # ← POPRAWKA: bez 'niech'
                }
                zwroc @rozmiar + ":" + liczba
            }
        }
        
        niech pizza = PizzaBuilder.nowy().duza().z_serem().z_pieczarkami().zbuduj()
        pokazl pizza