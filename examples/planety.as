# Definiujemy stałe 
niech PI = 3.14159

# Funkcja do konwersji stopni na radiany
funkcja na_radiany(stopnie) {
    zwroc (stopnie * PI) / 180
}

# Funkcja do obliczania silni
funkcja silnia(n) {
    jesli n <= 1 to zwroc 1
    zwroc n * silnia(n - 1)
}

# Funkcja do potęgowania
funkcja potega(x, n) {
    jesli n == 0 to zwroc 1
    
    niech wynik = 1
    niech indeks = 0
    dopoki indeks < n {
        wynik = wynik * x
        indeks = indeks + 1
    }
    zwroc wynik
}

# Implementacja sin(x) używając szeregu Taylora
# sin(x) = x - x^3/3! + x^5/5! - x^7/7! + ...
funkcja sin(x) {
    niech wynik = 0
    niech znak = 1
    niech indeks = 0
    
    # Używamy pierwszych 7 wyrazów szeregu dla przybliżenia
    dopoki indeks < 7 {
        niech wykladnik = 2 * indeks + 1
        niech skladnik = potega(x, wykladnik) / silnia(wykladnik)
        wynik = wynik + znak * skladnik
        znak = znak * -1
        indeks = indeks + 1
    }
    
    zwroc wynik
}

# Implementacja cos(x) używając szeregu Taylora
# cos(x) = 1 - x^2/2! + x^4/4! - x^6/6! + ...
funkcja cos(x) {
    niech wynik = 0
    niech znak = 1
    niech indeks = 0
    
    # Używamy pierwszych 7 wyrazów szeregu dla przybliżenia
    dopoki indeks < 7 {
        niech wykladnik = 2 * indeks
        niech skladnik = potega(x, wykladnik) / silnia(wykladnik)
        wynik = wynik + znak * skladnik
        znak = znak * -1
        indeks = indeks + 1
    }
    
    zwroc wynik
}


# Funkcja do obliczania pozycji planety w stopniach po zadanym czasie
funkcja oblicz_pozycje(dni, okres_orbitalny) {
    niech pozycja = (dni / okres_orbitalny) * 360
    zwroc pozycja % 360
}

# Funkcja obliczająca współrzędne x,y planety na podstawie kąta i odległości od słońca
funkcja oblicz_wspolrzedne(kat_stopnie, odleglosc) {
    niech kat = na_radiany(kat_stopnie)
    # x = odległość * cos(kąt)
    # y = odległość * sin(kąt)
    niech x = odleglosc * cos(kat)
    niech y = odleglosc * sin(kat)
    zwroc [x, y]
}

# Inicjalizacja danych o planetach
# [nazwa, odległość od słońca (mln km), okres orbitalny (dni)]
niech planety = [
    ["Merkury", 57.9, 88],
    ["Wenus", 108.2, 224.7],
    ["Ziemia", 149.6, 365.2],
    ["Mars", 227.9, 687],
    ["Jowisz", 778.5, 4331],
    ["Saturn", 1434.0, 10747],
    ["Uran", 2871.0, 30589],
    ["Neptun", 4495.0, 59800]
]

# Funkcja wyświetlająca pozycje wszystkich planet po zadanej liczbie dni
funkcja pokaz_uklad(dni) {
    niech indeks = 0
    pokazl "Słońce znajduje się w punkcie (0,0)"
    pokazl "Współrzędne podane w milionach kilometrów od Słońca"
    pokazl "------------------------------------------------"
    pokazl planety
    dopoki indeks < planety.dlg {
        niech planeta = planety[indeks]
        niech nazwa = planeta[0]
        niech odleglosc = planeta[1]
        niech okres = planeta[2]
        
        niech kat = oblicz_pozycje(dni, okres)
        niech wspolrzedne = oblicz_wspolrzedne(kat, odleglosc)
        
        pokazl nazwa + ":"
        pokazl "  Kąt: " + kat + " stopni"
        pokazl "  Pozycja (x,y): (" + wspolrzedne[0] + ", " + wspolrzedne[1] + ")"  
        
        indeks = indeks + 1
    }
}

# pokazl "Pozycje planet po 100 dniach:"
# pokaz_uklad(100)

pokazl "Pozycje planet po roku (365 dni):"
pokaz_uklad(365)