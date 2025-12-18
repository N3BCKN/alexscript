# modul Porownywalne {
#     funkcja rowne(inne) {
#         zwroc @wartosc == inne
#     }
    
#     funkcja wieksze(inne) {
#         zwroc @wartosc > inne
#     }
# }

# klasa Liczba {
#     dolacz Porownywalne
    
#     funkcja konstruktor(wartosc) {
#         niech @wartosc = wartosc
#     }
# }

# niech x = Liczba.nowy(5)
# pokazl x.rowne(5)
# pokazl x.wieksze(3)
# pokazl x.wieksze(10)


# modul A {
#     funkcja metoda_a() { pokazl "A" }
# }

# modul B {
#     funkcja metoda_b() { pokazl "B" }
# }

# klasa Test {
#     dolacz A
#     dolacz B
    
#     funkcja konstruktor() {}
# }

# niech t = Test.nowy()
# t.metoda_a()
# t.metoda_b()

# modul Matematyka {
#     niech PI = 3.14159
#     niech E = 2.71828
    
#     funkcja pole_kola(r) {
#         zwroc PI * r * r
#     }
# }

# klasa Kalkulator {
#     dolacz Matematyka
    
#     funkcja konstruktor() {}
    
#     funkcja oblicz() {
#         pokazl PI      # stała z modułu
#         pokazl E       # stała z modułu
#         zwroc pole_kola(5)  # funkcja z modułu
#     }
# }

# niech k = Kalkulator.nowy()
# pokazl k.oblicz()

#         modul Matematyka {
#           niech PI = 3.14159
          
#           funkcja kwadrat(x) {
#             zwroc x * x
#           }
          
#           klasa Kalkulator {
#             funkcja konstruktor() {
#               niech @wynik = 0
#             }
            
#             funkcja pole_kola(r) {
#               zwroc PI * kwadrat(r)
#             }
#           }
#         }
        
#         niech k = Matematyka::Kalkulator.nowy()
#         pokazl k.pole_kola(5)
#         pokazl Matematyka::PI
#         pokazl Matematyka::kwadrat(4)


        modul External {
          modul Helpers {
            funkcja helper_method() {
              zwroc "helped"
            }
          }
          
          klasa Worker {
            dolacz Helpers
            
            funkcja konstruktor() {}
            
            funkcja work() {
              zwroc helper_method()
            }
          }
        }
        
        niech x = External::Worker.nowy()
        pokazl x.work()