modul Porownywalne {
    funkcja rowne(inne) {
        zwroc @wartosc == inne
    }
    
    funkcja wieksze(inne) {
        zwroc @wartosc > inne
    }
}

klasa Liczba {
    dolacz Porownywalne
    
    funkcja konstruktor(wartosc) {
        niech @wartosc = wartosc
    }
}

niech x = Liczba.nowy(5)
pokazl x.rowne(5)
pokazl x.wieksze(3)
pokazl x.wieksze(10)


