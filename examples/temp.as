klasa Punkt {
        funkcja konstruktor(x, y) {
          niech @x = x
          niech @y = y

          pokazl @x.typ()
          pokazl x.typ()
        }
        # funkcja napis() {
        #   pokazl @x 
        #   pokazl @y
        #   zwroc "(#{@x.napis()}, #{@y.napis()})"
        # }
      }
      niech p = Punkt.nowy(3, 4)
