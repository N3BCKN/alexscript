modul Matematyka {
    niech PI = 3.14159
    
    funkcja dodaj(a, b) {
        zwroc a + b
    }
    
    klasa Kalkulator {
        funkcja konstruktor() {
            niech @wynik = 0
        }
        
        funkcja oblicz(x, y) {
            zwroc x + y
        }
    }
}

pokazl Matematyka::PI
pokazl Matematyka::dodaj(10, 20)

niech kalk = Matematyka::Kalkulator.nowy()
pokazl kalk.oblicz(5, 3)

modul A {
    niech X = 1
    
    modul B {
        niech Y = 2
        
        klasa Test {
            funkcja konstruktor() {
                pokazl "Test z A::B"
            }
        }
    }
}

pokazl A::X
pokazl A::B::Y
niech t = A::B::Test.nowy()