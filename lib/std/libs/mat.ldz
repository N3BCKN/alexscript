klasa Mat {
    # Stałe matematyczne
    statyczny niech PI = ruby("Math", "PI")
    statyczny niech E = ruby("Math", "E")
    statyczny niech NIESKONCZONOSC = ruby("Float::INFINITY", "to_f")
    
    # Funkcje trygonometryczne
    statyczny funkcja sin(x) {
        zwroc ruby("Math", "sin", x)
    }
    
    statyczny funkcja cos(x) {
        zwroc ruby("Math", "cos", x)
    }
    
    statyczny funkcja tan(x) {
        zwroc ruby("Math", "tan", x)
    }
    
    # Funkcje odwrotne trygonometryczne
    statyczny funkcja asin(x) {
        zwroc ruby("Math", "asin", x)
    }
    
    statyczny funkcja acos(x) {
        zwroc ruby("Math", "acos", x)
    }
    
    statyczny funkcja atan(x) {
        zwroc ruby("Math", "atan", x)
    }
    
    statyczny funkcja atan2(y, x) {
        zwroc ruby("Math", "atan2", y, x)
    }
    
    # Funkcje wykładnicze i logarytmiczne
    statyczny funkcja exp(x) {
        zwroc ruby("Math", "exp", x)
    }
    
    statyczny funkcja log(x, base = nic) {
        jesli base == nic {
            zwroc ruby("Math", "log", x)
        } albo {
            zwroc ruby("Math", "log", x, base)
        }
    }
    
    statyczny funkcja log10(x) {
        zwroc ruby("Math", "log10", x)
    }
    
    statyczny funkcja log2(x) {
        zwroc ruby("Math", "log2", x)
    }
    
    # Funkcje hiperboliczne
    statyczny funkcja sinh(x) {
        zwroc ruby("Math", "sinh", x)
    }
    
    statyczny funkcja cosh(x) {
        zwroc ruby("Math", "cosh", x)
    }
    
    statyczny funkcja tanh(x) {
        zwroc ruby("Math", "tanh", x)
    }
    
    # Funkcje odwrotne hiperboliczne
    statyczny funkcja asinh(x) {
        zwroc ruby("Math", "asinh", x)
    }
    
    statyczny funkcja acosh(x) {
        zwroc ruby("Math", "acosh", x)
    }
    
    statyczny funkcja atanh(x) {
        zwroc ruby("Math", "atanh", x)
    }
    
    # Funkcje pierwiastkowe
    statyczny funkcja sqrt(x) {
        zwroc ruby("Math", "sqrt", x)
    }
    
    statyczny funkcja cbrt(x) {
        zwroc ruby("Math", "cbrt", x)
    }
    
    # Funkcje zaokrąglające
    statyczny funkcja floor(x) {
        zwroc ruby("Float", "floor", x)
    }
    
    statyczny funkcja ceil(x) {
        zwroc ruby("Float", "ceil", x)
    }
    
    statyczny funkcja round(x, places = 0) {
        zwroc ruby("Float", "round", x, places)
    }
    
    # Funkcje specjalne
    statyczny funkcja gamma(x) {
        zwroc ruby("Math", "gamma", x)
    }
    
    statyczny funkcja lgamma(x) {
        niech wynik = ruby("Math", "lgamma", x)
        zwroc wynik[0]  # Zwracamy tylko wartość, pomijamy znak
    }
    
    statyczny funkcja erf(x) {
        zwroc ruby("Math", "erf", x)
    }
    
    statyczny funkcja erfc(x) {
        zwroc ruby("Math", "erfc", x)
    }
    
    # Funkcje użytkowe
    statyczny funkcja abs(x) {
        zwroc ruby("Numeric", "abs", x)
    }
    
    statyczny funkcja potega(x, y) {
        zwroc ruby("Numeric", "**", x, y)
    }
    
    statyczny funkcja hipotenuza(x, y) {
        zwroc ruby("Math", "hypot", x, y)
    }
    
    statyczny funkcja min(x, y) {
        zwroc ruby("Array", "min", [x, y])
    }
    
    statyczny funkcja max(x, y) {
        zwroc ruby("Array", "max", [x, y])
    }

    statyczny funkcja silnia(n){
        jesli n == 0{
            zwroc 1
        } albo{
            zwroc n * Mat.silnia(n-1)
        }
    }
    
    statyczny funkcja losowa() {
        zwroc ruby("Kernel", "rand")
    }
    
    statyczny funkcja losowa_zakres(min, max) {
        niech zakres = ruby("Range", "new", min, max)
        zwroc ruby("Kernel", "rand", zakres)
    }
}