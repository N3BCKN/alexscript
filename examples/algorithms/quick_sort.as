funkcja quick_sort(tablica) {
    jesli tablica.dlg <= 1 {
        zwroc tablica
    }

    niech pivot = tablica[0]
    niech mniejsze = []
    niech wieksze = []

    dla niech k = 1; tablica.dlg; 1 {
        jesli tablica[k] < pivot {
            mniejsze << tablica[k]
        } albo {
            wieksze << tablica[k]
        }
    }

    niech wynik = quick_sort(mniejsze)
    wynik << pivot
    niech prawa = quick_sort(wieksze)
    dla element w prawa {
        wynik << element
    }
    zwroc wynik
}

niech dane2 = [10, 7, 8, 9, 1, 5]
pokazl "Quick Sort:  " + quick_sort(dane2)