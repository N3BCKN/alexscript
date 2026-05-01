globalna niech licznik_ruchow = 0

funkcja hanoi(n, zrodlo, cel, pomoc) {
    jesli n == 1 {
        licznik_ruchow = licznik_ruchow + 1
        pokazl "   Przenieś krążek 1 z " + zrodlo + " na " + cel
        zwroc nic
    }
    hanoi(n - 1, zrodlo, pomoc, cel)
    licznik_ruchow = licznik_ruchow + 1
    pokazl "   Przenieś krążek " + n + " z " + zrodlo + " na " + cel
    hanoi(n - 1, pomoc, cel, zrodlo)
}

pokazl "9. Wieża Hanoi dla 3 krążków:"
licznik_ruchow = 0
hanoi(3, "A", "C", "B")
pokazl "   Łącznie ruchów: " + licznik_ruchow