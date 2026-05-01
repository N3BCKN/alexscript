funkcja bubble_sort(tablica) {
    niech n = tablica.dlg
    dla niech k = 0; n - 1; 1 {
        dla niech j = 0; n - k - 1; 1 {
            jesli tablica[j] > tablica[j + 1] {
                niech tmp = tablica[j]
                tablica[j] = tablica[j + 1]
                tablica[j + 1] = tmp
            }
        }
    }
    zwroc tablica
}

niech dane1 = [64, 34, 25, 12, 22, 11, 90]
pokazl "Bubble Sort: " + bubble_sort(dane1)