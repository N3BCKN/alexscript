funkcja sito_eratostenesa(n) {
    # tablica[i] == prawda oznacza ze i jest pierwsze
    niech sito = []
    dla niech k = 0; n + 1; 1 {
        sito << prawda
    }
    sito[0] = falsz
    sito[1] = falsz

    niech k = 2
    dopoki k * k <= n {
        jesli sito[k] {
            niech j = k * k
            dopoki j <= n {
                sito[j] = falsz
                j = j + k
            }
        }
        k = k + 1
    }

    niech pierwsze = []
    dla niech k = 2; n + 1; 1 {
        jesli sito[k] {
            pierwsze << k
        }
    }
    zwroc pierwsze
}

pokazl "Liczby pierwsze do 30: " + sito_eratostenesa(30)