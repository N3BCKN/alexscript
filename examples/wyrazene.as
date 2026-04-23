# niech email = Wyrazenie.nowy("^[a-z0-9.]+@[a-z]+\\.[a-z]+$", "i")
# pokazl email.pasuje("alex@example.com")       # prawda

# niech liczby = Wyrazenie.nowy("[0-9]+")
# niech d = liczby.dopasuj("wiek: 42 lat")
# pokazl d.tekst()       # 42
# pokazl d.indeks()      # 7

# niech kv = Wyrazenie.nowy("(?<k>[a-z]+)=(?<v>[0-9]+)")
# niech m = kv.dopasuj("rok=2026")
# pokazl m.nazwana("k")  # rok
# pokazl m.nazwana("v")  # 2026

# niech spacje = Wyrazenie.nowy("\\s+")
# pokazl spacje.zamien_wszystkie("a  b   c", "-")  # a-b-c
# pokazl spacje.podziel("a b  c")                   # [a, b, c]


        # niech licznik = 0
        # niech re = Wyrazenie.nowy("[0-9]+")
        # niech wynik = re.zamien_wszystkie("a1 b2 c3", fn(m) {
        #   licznik = licznik + 1
        #   zwroc "[" + licznik.napis() + "]"
        # })
        # pokazl wynik
        # pokazl licznik

niech re = Wyrazenie.nowy("[,;]\\s*")
niech czesci = "a, b;c,d".rozdziel(re)
pokazl czesci.dlg
debug()
pokazl czesci[0]
pokazl czesci[3]