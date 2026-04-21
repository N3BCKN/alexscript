        asynchroniczna funkcja main() {
            uruchom_rownolegle(fn() {
                rzuc BladWykonania.nowy("ignored error")
            })
            czekaj uspij(200)
            zwroc "done"
        }
        pokazl uruchom(main)