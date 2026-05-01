funkcja fib_rekurencja(n) {
    jesli n < 2 to zwroc n
    zwroc fib_rekurencja(n - 1) + fib_rekurencja(n - 2)
}

funkcja fib_iteracja(n) {
    jesli n < 2 to zwroc n
    niech a = 0
    niech b = 1
    dla niech k = 2; n + 1; 1 {
        niech tmp = a + b
        a = b
        b = tmp
    }
    zwroc b
}

pokazl "Fibonacci(10) rekurencyjnie: " + fib_rekurencja(10)
pokazl "Fibonacci(10) iteracyjnie:  " + fib_iteracja(10)