klasa Serwis {
  funkcja konstruktor() {
    niech @db = BazaDanych.nowy()
  }
  
  funkcja pobierz_dane() {
    zwroc @db.zapytanie("SELECT * FROM users")
  }
}

klasa BazaDanych {
  funkcja zapytanie(sql) {
    rzuc BladWykonania.nowy("Błąd połączenia")
  }
}

proba {
  niech s = Serwis.nowy()
  s.pobierz_dane()
} zlap (e) {
  dla frame w e['stos'] {
    pokazl frame
  }
}