klasa Zwierze {}
klasa Pies < Zwierze {
    funkcja szczekaj() {}
}



pokazl Pies.przodkowie()      # ["Zwierze"]
pokazl Pies.przodkowie().typ()     # klasa

pokazl Pies.info_metody('szczekaj')

pokazl Pies.czy_abstrakcyjna()

# Hierarchia
pokazl Pies.rodzic()          # "Zwierze"
pokazl Pies.przodkowie()      # ["Zwierze"]
pokazl Pies.czy_dziedziczy_po("Zwierze")  # prawda

# Metody
pokazl Pies.metody()          # ["szczekaj"]
pokazl Pies.ma_metode("szczekaj")  # prawda


niech pies = Pies.nowy()

# Typ
pokazl pies.nazwa_klasy()           # "Pies"
pokazl pies.czy_instancja("Zwierze")  # prawda

# Metody i zmienne
pokazl pies.metody()          # wszystkie dostępne metody
pokazl pies.zmienne_instancji()  # lista zmiennych @