        klasa Zwierze {
          funkcja konstruktor(nazwa) {
            niech @nazwa = nazwa
          }
          
          funkcja odglos() {
            zwroc "..."
          }
          
          funkcja przedstaw() {
            zwroc "Jestem " + @nazwa + " i robię " + odglos()
          }
        }
        
        klasa Pies < Zwierze {
          funkcja konstruktor(nazwa){
             niech @nazwa = nazwa
          }

          funkcja odglos() {
            zwroc "Hau hau!"
          }
        }
        
        klasa Kot < Zwierze {
          funkcja konstruktor(nazwa){
             niech @nazwa = nazwa
          }
            
          funkcja odglos() {
            zwroc "Miau!"
          }
        }
        
        niech pies = Pies.nowy("Burek")
        niech kot = Kot.nowy("Mruczek")
        
        pokazl pies.przedstaw()
        pokazl kot.przedstaw()