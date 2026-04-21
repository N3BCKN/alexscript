asynchroniczna funkcja szybki() {
    czekaj uspij(10)
    pokazl "szybki fulfilled"
    zwroc "gotowe"
}

asynchroniczna funkcja main() {
    pokazl "przed limit_czasu"
    niech p = szybki()
    pokazl "po szybki()"
    niech wynik = czekaj Obietnica.limit_czasu(p, 100)
    pokazl "po czekaj limit_czasu"
    zwroc wynik
}
pokazl uruchom(main)