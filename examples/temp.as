import('json')
# Test 4 — native static method z efektem ubocznym w argumencie
niech licznik = 0
funkcja zrob_dane() {
  globalna niech licznik = licznik + 1
  zwroc { "id": licznik }
}

niech json = Json.generuj(zrob_dane())
pokazl licznik   # powinno: 1, NIE 2
pokazl json      # powinno: '{"id":1}', NIE '{"id":2}'