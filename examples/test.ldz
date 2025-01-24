funkcja silnia(n) {
  niech mul = 1
  dla niech index = 1; n {
    mul = mul * index
  }
  jesli mul > 0{
    zwroc mul
  }
}



niech x = 1
dopoki x < 8 {
  niech y = silnia(x)
  pokazl "silnia z " + x + " to " + y
  x = x + 1
}



niech c = "kupa"
dla niech x = 1; 20; 2{
  pokazl x
  c = 'dupa'
  globalna niech test = 'to powinna byc zmienna globalna'
  niech nietest = 'a to nie powinno dzialac poza tym scope'
}

niech x = "test"

pokazl x
pokazl c
pokazl test 



niech x = -2131 

jesli x > 10 {
  pokazl "x jest większe niż 10"
} albojesli x > 5 {
  pokazl "x jest większe niż 5"
} albojesli x > 0 {
  pokazl "x jest większe niż 0"
} albo {
  pokazl "x jest mniejsze lub równe 0"
  globalna niech g = 'dupa'
  niech c = 'kupa'
}



funkcja silnia(n){
  jesli n == 1 {
    zwroc n
  }
  zwroc n * silnia(n-1)
}

pokazl silnia(5)





niech PI = 3.14
pokazl PI 


dla niech indeks = 1; 10; 1 {
  jesli indeks == 5 to zakoncz
  pokaz indeks
}
# wyświetli: 1, 2, 3, 4
pokazl ""

# Przykład z nastepny
dla niech indeks = 1; 5; 1 {
  jesli indeks == 3 to nastepny
  pokaz indeks
}
# wyświetli: 1, 2, 4, 5
pokazl ""

# W pętli while
niech x = 0
dopoki x < 10 {
  x = x + 1
  jesli x == 5 to nastepny
  pokaz x
  jesli x == 8 to zakoncz
}



niech x = nic
# W warunkach (traktowane jako false)
jesli x == nic {
  pokazl "x jest puste"
}

# Sprawdzanie czy wartość to nic
funkcja bezpieczne_dzielenie(a, b) {
  jesli b == 0 to zwroc nic
  zwroc a / b
}

# przykład użycia
niech wynik = bezpieczne_dzielenie(10, 0)
jesli wynik == nic {
  pokazl "nie można dzielić przez zero"
} albo {
  pokaz wynik
}


niech test = 5
test += 1