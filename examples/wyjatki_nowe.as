              klasa BladAplikacji < WyjatekPodstawowy {}
              klasa BladDanych < BladAplikacji {}
              klasa BladBazyDanych < BladDanych {}
              
              funkcja operacja_na_bazie() {
                rzuc BladBazyDanych.nowy("Błąd łączenia z bazą")
              }
              
              proba {
                operacja_na_bazie()
              } zlap (e : BladBazyDanych) {
                pokazl "Złapano błąd bazy: " + e["wiadomosc"]
              } zlap (e : BladAplikacji) {
                pokazl "Złapano błąd aplikacji: " + e["wiadomosc"] 
              } zlap (e) {
                pokazl "Złapano inny błąd: " + e["wiadomosc"]
              }