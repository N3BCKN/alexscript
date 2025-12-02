funkcja moze_zawiesc() {
                rzuc "Operacja nie powiodła sie"
                zwroc 42
              }
              
              proba {
                niech x = 10 + moze_zawiesc()
                pokazl x
              } zlap (e) {
                pokazl "Nie udało się przypisać: " + e["wiadomosc"]
              }



proba {
  niech x = 10
  niech y = 0
  
  jesli y == 0 {
    rzuc "Dzielenie przez zero!"
  }
  
  pokazl x / y
} zlap (e) {
  niech test = {"test": 123, "dupa": "pupa", "wiadomosc": 12345}
  pokazl test['wiadomosc']
  pokazl "Złapano wyjątek: " + e
} wkoncu {
  pokazl "Ten kod zawsze się wykona"
}


# Definiowanie wyjątku dziedziczącego po innym
wyjatek BladMatematyczny : BladWykonania

# Rzucanie zdefiniowanego wyjątku
funkcja podziel(a, b) {
  jesli b == 0 {
    rzuc { typ: "BladMatematyczny", wiadomosc: "Próba dzielenia przez zero" }
  }
  zwroc a / b
}

# Używanie z typami wyjątków
proba {
  pokazl podziel(10, 0)
} zlap (e : BladMatematyczny) {
  pokazl "Błąd matematyczny: " + e['wiadomosc']
} zlap (e) {
  pokazl "Inny wyjątek: " + e['wiadomosc']
}
