# modul Dupa {
#     klasa NowyBlad < WyjatekPodstawowy {}
# }


# pokazl Dupa::NowyBlad.metody()
modul Test {
  klasa Bazowa { funkcja konstruktor(k) { niech @k = k } }
  klasa Srodek < Bazowa { funkcja konstruktor(k) { super(k) } }
  klasa Pochodna < Srodek { funkcja konstruktor(k) { super(k) } }
}

niech p = Test::Pochodna.nowy("hej")
pokazl p