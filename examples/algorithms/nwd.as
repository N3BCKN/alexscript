funkcja nwd(a, b) {
    dopoki b != 0 {
        niech tmp = b
        b = a % b
        a = tmp
    }
    zwroc a
}

funkcja nww(a, b) {
    zwroc (a * b) / nwd(a, b)
}

pokazl "   NWD(48, 18) = " + nwd(48, 18)
pokazl "   NWW(12, 18) = " + nww(12, 18)