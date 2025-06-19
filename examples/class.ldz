klasa Heh {
  statyczny niech PI = 3.14
  statyczny funkcja test(){
    pokazl "z funkcji test"
  } 
}

klasa Hih < Heh{

}

pokazl Heh.PI 
pokazl Heh.test()
pokazl Hih.PI
pokazl Hih.test()



klasa Rodzic{
  funkcja czy_dziala(){
    pokazl 'dziala'
  }
}

klasa Dziecko < Rodzic{
  funkcja czy_dziala(){
    super()
  }
}

niech x = Dziecko.nowy()
x.czy_dziala()



klasa Test{
  funkcja testowa_publiczna(){
    testowa_prywatna()
  }

  prywatne 
  funkcja testowa_prywatna(){
    pokazl 'cialo funkcji prywatnej'
  }
}

klasa Test1 < Test{
  
}

niech test = Test1.nowy()

test.testowa_publiczna()


# Test działania słowa kluczowego super

klasa ZwierzeBazowe {
    funkcja konstruktor(nazwa) {
        niech @nazwa = nazwa
    }
    
    funkcja przedstaw_sie() {
        zwroc "Jestem zwierzęciem o nazwie " + @nazwa
    }
    
    funkcja odglos() {
        zwroc "..."
    }
    
    funkcja pelny_opis() {
        zwroc przedstaw_sie() + " i wydaję dźwięk: " + odglos()
    }
}

klasa Pies < ZwierzeBazowe {
    funkcja konstruktor(nazwa, rasa) {
        super(nazwa)  # Wywołanie konstruktora klasy bazowej
        niech @rasa = rasa
    }
    
    funkcja przedstaw_sie() {
        zwroc super() + " i jestem psem rasy " + @rasa
    }
    
    funkcja odglos() {
        zwroc "Hau hau!"
    }
    
    funkcja machaj_ogonem() {
        zwroc @nazwa + " macha ogonem!"
    }
}

klasa Kot < ZwierzeBazowe {
    funkcja konstruktor(nazwa, kolor) {
        super(nazwa)  # Wywołanie konstruktora klasy bazowej
        niech @kolor = kolor
    }
    
    funkcja przedstaw_sie() {
        zwroc super() + " i jestem kotem o kolorze " + @kolor
    }
    
    funkcja odglos() {
        zwroc "Miau miau!"
    }
    
    funkcja drap_mebel() {
        zwroc @nazwa + " drapie mebel!"
    }
}

# Stworzenie instancji klas
niech pies = Pies.nowy("Burek", "Owczarek niemiecki")
niech kot = Kot.nowy("Mruczek", "szary")

# Test wywołań super

# Test czy pelny_opis używa polimorficznych metod odglos
pokazl pies.pelny_opis()  # Powinno użyć pies.odglos() zamiast ZwierzeBazowe.odglos()
pokazl kot.pelny_opis()   # Powinno użyć kot.odglos() zamiast ZwierzeBazowe.odglos()