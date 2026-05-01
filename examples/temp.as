# modul Dupa {
#     klasa NowyBlad < WyjatekPodstawowy {}
# }


# pokazl Dupa::NowyBlad.metody()


modul Test {
  klasa B < WyjatekPodstawowy {
    funkcja konstruktor(k) { super(k) }
  }
}
niech b = Test::B.nowy("hej")
pokazl b              # #<B:0x...>
pokazl "obiekt: " + "#{b}"   # obiekt: <B instancja>

# Powinno też dla zwykłej klasy:
klasa Foo {}
niech f = Foo.nowy()
pokazl f              # #<Foo:0x...>

# I user override:
klasa Bar {
  funkcja napis() { zwroc "custom Bar repr" }
}
niech bar = Bar.nowy()
pokazl bar            # #<Bar:0x...> — UWAGA: user napis() NIE zostanie wywołany
                      # bo formatter nie ma dispatcha. To znana limit.
                      # bar.napis() zwróci "custom Bar repr" — to działa.