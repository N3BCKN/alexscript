funkcja scal(lewa, prawa) {
    niech wynik = []
    niech k = 0
    niech j = 0

    dopoki k < lewa.dlg i j < prawa.dlg {
        jesli lewa[k] <= prawa[j] {
            wynik << lewa[k]
            k = k + 1
        } albo {
            wynik << prawa[j]
            j = j + 1
        }
    }

    # Dopisz pozostałości z lewej połowy
    dopoki k < lewa.dlg {
        wynik << lewa[k]
        k = k + 1
    }
    # Dopisz pozostałości z prawej połowy
    dopoki j < prawa.dlg {
        wynik << prawa[j]
        j = j + 1
    }

    zwroc wynik
}

funkcja merge_sort(tablica) {
    jesli tablica.dlg <= 1 to zwroc tablica

    niech srodek = tablica.dlg / 2
    niech lewa = []
    niech prawa = []

    dla niech k = 0; srodek; 1 {
        lewa << tablica[k]
    }
    dla niech k = srodek; tablica.dlg; 1 {
        prawa << tablica[k]
    }

    zwroc scal(merge_sort(lewa), merge_sort(prawa))
}

niech dane11 = [38, 27, 43, 3, 9, 82, 10]
pokazl "Merge Sort: " + merge_sort(dane11)