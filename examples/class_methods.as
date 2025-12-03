# test.ldz
klasa Test {
    funkcja metoda() {
        zwroc "działa"
    }
}

pokazl Test.nazwa()      # "Test"
pokazl Test.metody()     # ["metoda"]

niech obj = Test.nowy()
# pokazl obj.klasa()       # "Test"
pokazl obj.typ()         # "instancja"