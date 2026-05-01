import("csv")
import("plik")

niech testy_ok = 0
niech testy_fail = 0

funkcja test(nazwa, warunek) {
    jesli warunek {
        testy_ok = testy_ok + 1
    } albo {
        pokazl "[FAIL] " + nazwa
        testy_fail = testy_fail + 1
    }
}

# ============================================================================
# 1. PARSOWANIE TEKSTU
# ============================================================================

niech dane = "imie,wiek,miasto\nJan,30,Warszawa\nAna,25,Kraków"

# Parsuj — tablica tablic
niech wiersze = Csv.parsuj(dane)
test("parsuj — 3 wiersze (z nagłówkiem)", wiersze.dlg() == 3)
test("parsuj — pierwszy wiersz = nagłówki", wiersze[0][0] == "imie")
test("parsuj — dane wiersz 1", wiersze[1][0] == "Jan")
test("parsuj — dane wiersz 2 kolumna 2", wiersze[2][1] == "25")

# Parsuj pojedynczą linię
niech linia = Csv.parsuj_linie("a,b,c,d")
test("parsuj_linie — 4 elementy", linia.dlg() == 4)
test("parsuj_linie — pierwszy", linia[0] == "a")
test("parsuj_linie — ostatni", linia[3] == "d")

# ============================================================================
# 2. PARSOWANIE Z NAGŁÓWKAMI
# ============================================================================

niech obiekty = Csv.parsuj_z_naglowkami(dane)
test("z_naglowkami — 2 obiekty (bez nagłówka)", obiekty.dlg() == 2)
test("z_naglowkami — imie pierwszego", obiekty[0]["imie"] == "Jan")
test("z_naglowkami — wiek pierwszego", obiekty[0]["wiek"] == "30")
test("z_naglowkami — miasto drugiego", obiekty[1]["miasto"] == "Kraków")

# Nagłówki
niech nag = Csv.naglowki(dane)
test("naglowki — 3 kolumny", nag.dlg() == 3)
test("naglowki — pierwsza", nag[0] == "imie")
test("naglowki — trzecia", nag[2] == "miasto")

# ============================================================================
# 3. NIESTANDARDOWY SEPARATOR
# ============================================================================

niech dane_sr = "imie;wiek;miasto\nJan;30;Warszawa"
niech wiersze_sr = Csv.parsuj(dane_sr, ";")
test("separator ; — poprawne parsowanie", wiersze_sr[0][0] == "imie")
test("separator ; — dane", wiersze_sr[1][1] == "30")

niech obiekty_sr = Csv.parsuj_z_naglowkami(dane_sr, ";")
test("separator ; z nagłówkami", obiekty_sr[0]["imie"] == "Jan")

# ============================================================================
# 4. GENEROWANIE
# ============================================================================

niech gen = Csv.generuj([["x", "y"], ["1", "2"], ["3", "4"]])
test("generuj — zawiera x,y", gen.zawiera("x,y"))
test("generuj — zawiera 1,2", gen.zawiera("1,2"))
test("generuj — zawiera 3,4", gen.zawiera("3,4"))

niech gen_linia = Csv.generuj_linie(["a", "b", "c"])
test("generuj_linie — a,b,c", gen_linia.zawiera("a,b,c"))

# Generowanie z nagłówkami
niech gen_z_nag = Csv.generuj_z_naglowkami(["kol1", "kol2"], [["v1", "v2"], ["v3", "v4"]])
test("generuj_z_naglowkami — nagłówki", gen_z_nag.zawiera("kol1,kol2"))
test("generuj_z_naglowkami — dane", gen_z_nag.zawiera("v1,v2"))

# Generowanie z separatorem
niech gen_sr = Csv.generuj([["a", "b"], ["1", "2"]], ";")
test("generuj separator ; ", gen_sr.zawiera("a;b"))

# ============================================================================
# 5. OPERACJE NA PLIKACH
# ============================================================================

niech sciezka = "/tmp/as_test_csv.csv"

# Zapis
Csv.generuj_plik(sciezka, [["imie", "wiek"], ["Jan", "30"], ["Ana", "25"]])
test("generuj_plik — plik istnieje", Plik.istnieje(sciezka))

# Odczyt
niech z_pliku = Csv.parsuj_plik(sciezka)
test("parsuj_plik — 3 wiersze", z_pliku.dlg() == 3)
test("parsuj_plik — dane", z_pliku[1][0] == "Jan")

# Odczyt z nagłówkami
niech z_pliku_nag = Csv.parsuj_plik_z_naglowkami(sciezka)
test("parsuj_plik_z_naglowkami — 2 obiekty", z_pliku_nag.dlg() == 2)
test("parsuj_plik_z_naglowkami — imie", z_pliku_nag[0]["imie"] == "Jan")

# Nagłówki z pliku
niech nag_pliku = Csv.naglowki_pliku(sciezka)
test("naglowki_pliku — 2 kolumny", nag_pliku.dlg() == 2)
test("naglowki_pliku — pierwsza", nag_pliku[0] == "imie")

# Zapis z nagłówkami
niech sciezka2 = "/tmp/as_test_csv2.csv"
Csv.generuj_plik_z_naglowkami(sciezka2, ["produkt", "cena"], [["Chleb", "5"], ["Mleko", "4"]])
niech z_pliku2 = Csv.parsuj_plik_z_naglowkami(sciezka2)
test("plik z nagłówkami — odczyt", z_pliku2[0]["produkt"] == "Chleb")
test("plik z nagłówkami — cena", z_pliku2[1]["cena"] == "4")

# ============================================================================
# 6. UTILITY
# ============================================================================

test("liczba_wierszy", Csv.liczba_wierszy(dane) == 3)
test("liczba_kolumn", Csv.liczba_kolumn(dane) == 3)

# Wyciągnij kolumnę
niech kolumna_wiek = Csv.kolumna(dane, "wiek")
test("kolumna — 2 wartości", kolumna_wiek.dlg() == 2)
test("kolumna — pierwsza", kolumna_wiek[0] == "30")
test("kolumna — druga", kolumna_wiek[1] == "25")

# ============================================================================
# 7. PUSTE DANE
# ============================================================================

niech pusty = Csv.parsuj("")
test("parsuj pusty — 0 wierszy", pusty.dlg() == 0)

# ============================================================================
# SPRZĄTANIE
# ============================================================================

jesli Plik.istnieje(sciezka) { Plik.usun(sciezka) }
jesli Plik.istnieje(sciezka2) { Plik.usun(sciezka2) }

# ============================================================================
# PODSUMOWANIE
# ============================================================================

pokazl ""
pokazl "================================"
pokazl "WYNIKI TESTÓW BIBLIOTEKI CSV"
pokazl "================================"
pokazl "Przeszło: " + testy_ok
pokazl "Nie przeszło: " + testy_fail
pokazl "Razem: " + (testy_ok + testy_fail)
pokazl "================================"

jesli testy_fail == 0 {
    pokazl "WSZYSTKIE TESTY PRZESZŁY!"
} albo {
    pokazl "UWAGA: " + testy_fail + " testów nie przeszło!"
}
