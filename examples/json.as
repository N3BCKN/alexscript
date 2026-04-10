# ============================================================================
# test_json.as — Testy biblioteki Json
# ============================================================================
import("json")

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
# 1. PARSOWANIE
# ============================================================================

# Parsowanie obiektu
# niech obj = Json.parsuj("{\"imie\": \"Jan\", \"wiek\": 30}")
# test("parsuj obiekt — imie", obj["imie"] == "Jan")
# test("parsuj obiekt — wiek", obj["wiek"] == 30)

# Parsowanie tablicy
niech tab = Json.parsuj("[1, 2, 3, 4, 5]")
test("parsuj tablica — długość", tab.dlg() == 5)
test("parsuj tablica — element", tab[0] == 1)
test("parsuj tablica — ostatni", tab[4] == 5)

# Parsowanie zagnieżdżone
# niech zagn = Json.parsuj("{\"osoba\": {\"imie\": \"Jan\"}, \"oceny\": [5, 4, 3]}")
# test("parsuj zagnieżdżony obiekt", zagn["osoba"]["imie"] == "Jan")
# test("parsuj zagnieżdżona tablica", zagn["oceny"][0] == 5)

# Parsowanie typów
# niech typy = Json.parsuj("{\"int\": 42, \"float\": 3.14, \"bool\": true, \"null_val\": null, \"str\": \"abc\"}")
# test("parsuj int", typy["int"] == 42)
# test("parsuj float", typy["float"] == 3.14)
# test("parsuj bool true", typy["bool"] == prawda)
# test("parsuj null", typy["null_val"] == nic)
# test("parsuj string", typy["str"] == "abc")

# Parsowanie bool false
niech bf = Json.parsuj("{\"v\": false}")
test("parsuj bool false", bf["v"] == falsz)

# Parsowanie pustych struktur
niech pusty_obj = Json.parsuj("{}")
niech pusta_tab = Json.parsuj("[]")
test("parsuj pusty obiekt", pusty_obj.dlg() == 0)
test("parsuj pusta tablica", pusta_tab.dlg() == 0)

# ============================================================================
# 2. GENEROWANIE
# ============================================================================

# Generowanie obiektu
niech json_str = Json.generuj({"imie": "Anna", "wiek": 25})
test("generuj obiekt — zawiera imie", json_str.zawiera("Anna"))
test("generuj obiekt — zawiera wiek", json_str.zawiera("25"))

# Generowanie tablicy
niech json_tab = Json.generuj([1, 2, 3])
test("generuj tablica", json_tab.zawiera("[1,2,3]"))

# Round-trip: parsuj → generuj → parsuj
niech oryg = {"klucz": "wartość", "liczba": 42}
niech json = Json.generuj(oryg)
niech odtworzony = Json.parsuj(json)
test("round-trip klucz", odtworzony["klucz"] == "wartość")
test("round-trip liczba", odtworzony["liczba"] == 42)

# ============================================================================
# 3. ŁADNE GENEROWANIE
# ============================================================================

niech ladny = Json.generuj_ladnie({"a": 1, "b": 2})
test("generuj_ladnie — zawiera wcięcia", ladny.zawiera("\n"))
test("generuj_ladnie — zawiera klucz", ladny.zawiera("\"a\""))

# ============================================================================
# 4. WALIDACJA
# ============================================================================

test("czy_poprawny — poprawny JSON", Json.czy_poprawny("{\"a\": 1}"))
test("czy_poprawny — niepoprawny JSON", Json.czy_poprawny("to nie json") == falsz)
test("czy_poprawny — pusta tablica", Json.czy_poprawny("[]"))
test("czy_poprawny — pusty obiekt", Json.czy_poprawny("{}"))

# ============================================================================
# 5. ŁĄCZENIE OBIEKTÓW
# ============================================================================

niech obj1 = {"a": 1, "b": 2}
niech obj2 = {"b": 3, "c": 4}
niech polaczony = Json.polacz(obj1, obj2)
test("polacz — a z pierwszego", polaczony["a"] == 1)
test("polacz — b nadpisany", polaczony["b"] == 3)
test("polacz — c z drugiego", polaczony["c"] == 4)

# ============================================================================
# 6. KLUCZE I WARTOŚCI
# ============================================================================

niech dane = {"x": 10, "y": 20, "z": 30}
niech klucze = Json.klucze(dane)
test("klucze — ilość", klucze.dlg() == 3)
test("klucze — zawiera x", klucze.zawiera("x"))

# ============================================================================
# 7. OPERACJE NA PLIKACH
# ============================================================================

niech sciezka = "/tmp/as_test_json.json"
niech do_zapisu = {"test": "dane", "liczba": 123}
Json.generuj_plik(sciezka, do_zapisu)

niech wczytany = Json.parsuj_plik(sciezka)
test("plik — zapis i odczyt", wczytany["test"] == "dane")
test("plik — liczba", wczytany["liczba"] == 123)

# Ładny zapis
niech sciezka2 = "/tmp/as_test_json_pretty.json"
Json.generuj_plik(sciezka2, do_zapisu, prawda)
niech wczytany2 = Json.parsuj_plik(sciezka2)
test("plik ładny — odczyt", wczytany2["test"] == "dane")

# ============================================================================
# SPRZĄTANIE
# ============================================================================
import("plik")
jesli Plik.istnieje(sciezka) { Plik.usun(sciezka) }
jesli Plik.istnieje(sciezka2) { Plik.usun(sciezka2) }

# ============================================================================
# PODSUMOWANIE
# ============================================================================

pokazl ""
pokazl "================================"
pokazl "WYNIKI TESTÓW BIBLIOTEKI JSON"
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
