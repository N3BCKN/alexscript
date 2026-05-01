funkcja binary_search(tablica, szukana) {
    niech lewy = 0
    niech prawy = tablica.dlg - 1

    dopoki lewy <= prawy {
        niech srodek = (lewy + prawy) / 2
        srodek = srodek.typ() == 'calkowita' ?  srodek : srodek.zaokragl()
        jesli tablica[srodek] == szukana {
            zwroc srodek
        } albojesli tablica[srodek] < szukana {
            lewy = srodek + 1
        } albo {
            prawy = srodek - 1
        }
    }
    zwroc -1
}

niech dane3 = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19]
pokazl "Binary Search (szukam 13): indeks " + binary_search(dane3, 13)