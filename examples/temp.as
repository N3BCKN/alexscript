# test_2_null_strict.as
# Bug 2: nic + cokolwiek (poza == i !=) powinno wybuchać, nie po cichu zwracać nic.

pokazl "=== 1. == i != z nic — bez zmian ==="
pokazl nic == nic           # oczekiwane: prawda
pokazl nic == 5             # oczekiwane: falsz
pokazl nic != "x"           # oczekiwane: prawda
pokazl 5 != nic             # oczekiwane: prawda

pokazl ""
pokazl "=== 2. string + nic - powinno wybuchać ==="
proba {
  niech wynik = "Witaj, " + nic
  pokazl "Nie powinno tu dotrzeć: " + wynik
} zlap (e) {
  pokazl "Poprawnie wybuchło: " + e["wiadomosc"]
}

pokazl ""
pokazl "=== 3. nic + string - powinno wybuchać ==="
proba {
  niech wynik = nic + " świecie"
} zlap (e) {
  pokazl "Poprawnie wybuchło: " + e["wiadomosc"]
}

pokazl ""
pokazl "=== 4. liczba + nic - powinno wybuchać ==="
proba {
  niech wynik = 5 + nic
} zlap (e) {
  pokazl "Poprawnie wybuchło: " + e["wiadomosc"]
}

pokazl ""
pokazl "=== 5. nic > 5, nic < 10 - powinno wybuchać ==="
proba {
  niech wynik = nic > 5
} zlap (e) {
  pokazl "Poprawnie wybuchło: " + e["wiadomosc"]
}

pokazl ""
pokazl "=== 6. interpolacja jako idiomatyczna alternatywa ==="
niech imie = nic
pokazl "Imie to: #{imie}"   # oczekiwane: "Imie to: nic"

pokazl ""
pokazl "=== 7. Diagnostyka — bug 1 + bug 2 razem ==="
# Po naprawie bug 1, @imie powinno być ustawione i nic nie wybucha.
klasa Zwierze {
  funkcja konstruktor(imie) { niech @imie = imie }
  funkcja przedstaw() { pokazl "Jestem " + @imie }
}
klasa Pies < Zwierze {}
niech reksio = Pies.nowy("Reksio")
reksio.przedstaw()          # oczekiwane: "Jestem Reksio" (bug 1 fix)

# Gdyby ktoś z premedytacją wywołał na klasie bez własnego konstruktora
# i bez parent constructor — pole pozostaje nieustawione, i wtedy
# dotknięcie go w + ze stringiem wybucha (bug 2 fix).
klasa BezPol {}
niech b = BezPol.nowy()
proba {
  niech x = "tekst: " + b.cokolwiek_co_nie_istnieje
} zlap (e) {
  pokazl "Method dispatch error: " + e["wiadomosc"]
}
