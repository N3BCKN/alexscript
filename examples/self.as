# # Test 1: Podstawowe użycie w metodzie
# klasa Test1 {
#     funkcja konstruktor() {
#         niech @nazwa = "Test"
#     }
    
#     funkcja pobierz_siebie() {
#         zwroc sam
#     }
# }

# pokazl "=== Test 1: Podstawowe użycie ==="
# niech t1 = Test1.nowy()
# niech wynik = t1.pobierz_siebie()
# pokazl "Czy sam zwraca instancję? " + wynik.identyczny(t1)
# pokazl ""

# Test 2: Method chaining
# klasa Builder {
#     funkcja konstruktor() {
#         niech @x = 0
#         niech @y = 0
#     }
    
#     funkcja ustaw_x(wartosc) {
#         niech @x = wartosc
#         zwroc sam
#     }
    
#     funkcja ustaw_y(wartosc) {
#         niech @y = wartosc
#         zwroc sam
#     }
    
#     funkcja wyswietl() {
#         pokazl "X: " + @x + ", Y: " + @y
#     }
# }

# pokazl "=== Test 2: Method Chaining ==="
# niech builder = Builder.nowy().ustaw_x(10).ustaw_y(20)
# builder.wyswietl()
# pokazl ""

# # Test 3: W konstruktorze
# klasa Test3 {
#     funkcja konstruktor() {
#         pokazl "W konstruktorze, typ: " + sam.klasa()
#     }
# }

# pokazl "=== Test 3: W konstruktorze ==="
# niech t3 = Test3.nowy()
# pokazl ""

# # Test 4: Przekazywanie do funkcji (Visitor Pattern)
# klasa Element {
#     funkcja konstruktor(id) {
#         niech @id = id
#     }
    
#     funkcja akceptuj(visitor) {
#         zwroc visitor.odwiedz(sam)
#     }
    
#     funkcja pobierz_id() {
#         zwroc @id
#     }
# }

# klasa Visitor {
#     funkcja odwiedz(element) {
#         zwroc "Odwiedzono element: " + element.pobierz_id()
#     }
# }

# pokazl "=== Test 4: Visitor Pattern ==="
# niech elem = Element.nowy("E1")
# niech vis = Visitor.nowy()
# pokazl elem.akceptuj(vis)
# pokazl ""

# # Test 5: Funkcja zagnieżdżona (dziedziczenie kontekstu)
# klasa Test5 {
#     funkcja konstruktor() {
#         niech @wartosc = 42
#     }
    
#     funkcja test_closure() {
#         funkcja wewnetrzna() {
#             zwroc sam.pobierz_wartosc()
#         }
#         zwroc wewnetrzna()
#     }
    
#     funkcja pobierz_wartosc() {
#         zwroc @wartosc
#     }
# }

# pokazl "=== Test 5: Funkcja zagnieżdżona ==="
# niech t5 = Test5.nowy()
# pokazl "Wartość z closure: " + t5.test_closure()
# pokazl ""

# Test 6: Błędy - użycie poza klasą
pokazl "=== Test 6: Testy błędów ==="

pokazl "Test 6a: Sam w globalnej funkcji"
proba {
    funkcja global_test() {
        zwroc sam
    }
    global_test()
    pokazl "BŁĄD: Nie złapano wyjątku!"
} zlap (e) {
    pokazl "✓ Poprawnie złapano: " + e["wiadomosc"]
}

pokazl ""
pokazl "Test 6b: Przypisanie do sam (niech sam = ...)"
# Ten test nie zadziała w runtime, bo parser złapie błąd wcześniej
# Odkomentuj poniższe 3 linie i spróbuj uruchomić - dostaniesz błąd parsowania:
klasa TestError {
    funkcja foo() { niech sam = 5 }
}

pokazl "Test przypisania do 'sam' daje błąd parsowania (nie runtime)"
pokazl ""

# pokazl "=== Wszystkie testy zakończone ==="