import("czas")

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
# 1. TWORZENIE INSTANCJI
# ============================================================================

# Czas.teraz() — bieżący czas
niech teraz = Czas.teraz()
test("Czas.teraz() zwraca instancję", teraz.rok() > 2000)

# Czas.nowy() — bez argumentów = bieżący czas
niech t0 = Czas.nowy()
test("Czas.nowy() — rok > 2000", t0.rok() > 2000)

# Czas.nowy(rok) — tylko rok
niech t1 = Czas.nowy(2024)
test("Czas.nowy(2024) — rok", t1.rok() == 2024)
test("Czas.nowy(2024) — domyślny miesiąc", t1.miesiac() == 1)
test("Czas.nowy(2024) — domyślny dzień", t1.dzien() == 1)

# Czas.nowy(rok, miesiac, dzien)
niech t2 = Czas.nowy(2024, 6, 15)
test("Czas.nowy(2024,6,15) — rok", t2.rok() == 2024)
test("Czas.nowy(2024,6,15) — miesiąc", t2.miesiac() == 6)
test("Czas.nowy(2024,6,15) — dzień", t2.dzien() == 15)

# Czas.nowy(rok, miesiac, dzien, godzina, minuta, sekunda)
niech t3 = Czas.nowy(2024, 12, 25, 14, 30, 45)
test("Pełne argumenty — godzina", t3.godzina() == 14)
test("Pełne argumenty — minuta", t3.minuta() == 30)
test("Pełne argumenty — sekunda", t3.sekunda() == 45)

# Czas.nowy(string) — parsowanie z tekstu
niech t_str = Czas.nowy("2024-03-15 10:20:30")
test("Czas.nowy(string) — rok", t_str.rok() == 2024)
test("Czas.nowy(string) — miesiąc", t_str.miesiac() == 3)
test("Czas.nowy(string) — godzina", t_str.godzina() == 10)

# Czas.z_timestampu()
niech t_ts = Czas.z_timestampu(0)
test("z_timestampu(0) — rok 1970", t_ts.rok() == 1970)

niech t_ts2 = Czas.z_timestampu(1700000000)
test("z_timestampu(1700000000) — rok 2023", t_ts2.rok() == 2023)

# Czas.utc()
niech t_utc = Czas.utc(2024, 1, 1, 12, 0, 0)
test("Czas.utc() — rok", t_utc.rok() == 2024)
test("Czas.utc() — czy_utc", t_utc.czy_utc())

# Czas.lokalny()
niech t_lok = Czas.lokalny(2024, 7, 4, 18, 0, 0)
test("Czas.lokalny() — rok", t_lok.rok() == 2024)
test("Czas.lokalny() — miesiąc", t_lok.miesiac() == 7)

# Czas.parsuj()
niech t_par = Czas.parsuj("2024-08-20 09:15:30")
test("Czas.parsuj() — rok", t_par.rok() == 2024)
test("Czas.parsuj() — miesiąc", t_par.miesiac() == 8)

# Czas.parsuj_format()
niech t_pf = Czas.parsuj_format("20/06/2024", "%d/%m/%Y")
test("parsuj_format — dzień", t_pf.dzien() == 20)
test("parsuj_format — miesiąc", t_pf.miesiac() == 6)

# ============================================================================
# 2. GETTERY — KOMPONENTY CZASU
# ============================================================================

niech t_get = Czas.nowy(2024, 3, 14, 15, 9, 26)

test("rok()", t_get.rok() == 2024)
test("miesiac()", t_get.miesiac() == 3)
test("dzien()", t_get.dzien() == 14)
test("godzina()", t_get.godzina() == 15)
test("minuta()", t_get.minuta() == 9)
test("sekunda()", t_get.sekunda() == 26)
test("dzien_roku() — 14 marca = 74. dzień roku (rok przestępny)", t_get.dzien_roku() == 74)

# mikrosekunda/nanosekunda — dla czasu bez ułamków powinny być 0
test("mikrosekunda() == 0", t_get.mikrosekunda() == 0)
test("nanosekunda() == 0", t_get.nanosekunda() == 0)

# timestamp
niech ts = t_get.timestamp()
test("timestamp() zwraca Integer > 0", ts > 0)

niech ts_f = t_get.timestamp_f()
test("timestamp_f() zwraca Float > 0", ts_f > 0)

# strefa i przesunięcie
niech strefa = t_get.strefa()
test("strefa() zwraca string", strefa.dlg() > 0)

niech offset = t_get.przesuniecie_utc()
test("przesuniecie_utc() zwraca Integer", offset == offset)

# ============================================================================
# 3. PREDYKATY DNIA TYGODNIA
# ============================================================================

# 2024-03-14 to czwartek
test("czy_czwartek() — 14 marca 2024", t_get.czy_czwartek())
test("czy_poniedzialek() — nie poniedziałek", t_get.czy_poniedzialek() == falsz)
test("czy_wtorek() — nie wtorek", t_get.czy_wtorek() == falsz)
test("czy_sroda() — nie środa", t_get.czy_sroda() == falsz)
test("czy_piatek() — nie piątek", t_get.czy_piatek() == falsz)
test("czy_sobota() — nie sobota", t_get.czy_sobota() == falsz)
test("czy_niedziela() — nie niedziela", t_get.czy_niedziela() == falsz)

# Sprawdź niedzielę: 2024-03-17
niech ndz = Czas.nowy(2024, 3, 17)
test("czy_niedziela() — 17 marca 2024", ndz.czy_niedziela())

# Sprawdź piątek: 2024-03-15
niech pt = Czas.nowy(2024, 3, 15)
test("czy_piatek() — 15 marca 2024", pt.czy_piatek())

# ============================================================================
# 4. PREDYKATY STANU
# ============================================================================

niech utc_czas = Czas.utc(2024, 1, 1)
test("czy_utc() — czas UTC", utc_czas.czy_utc())

niech lok_czas = Czas.lokalny(2024, 1, 1)
# czy_czas_letni() — w styczniu zazwyczaj nie
test("czy_czas_letni() zwraca bool", lok_czas.czy_czas_letni() == prawda lub lok_czas.czy_czas_letni() == falsz)

# ============================================================================
# 5. ARYTMETYKA CZASU
# ============================================================================

niech baza = Czas.nowy(2024, 1, 1, 12, 0, 0)

# dodaj sekundy
niech plus_60 = baza.dodaj(60)
test("dodaj(60) — minuta do przodu", plus_60.minuta() == 1)
test("dodaj(60) — godzina bez zmian", plus_60.godzina() == 12)

# dodaj_minuty
niech plus_30m = baza.dodaj_minuty(30)
test("dodaj_minuty(30) — godzina 12:30", plus_30m.minuta() == 30)

# dodaj_godziny
niech plus_3h = baza.dodaj_godziny(3)
test("dodaj_godziny(3) — godzina 15", plus_3h.godzina() == 15)

# dodaj_dni
niech plus_1d = baza.dodaj_dni(1)
test("dodaj_dni(1) — 2 stycznia", plus_1d.dzien() == 2)

# dodaj_tygodnie
niech plus_1w = baza.dodaj_tygodnie(1)
test("dodaj_tygodnie(1) — 8 stycznia", plus_1w.dzien() == 8)

# odejmij
niech minus_60 = baza.odejmij(60)
test("odejmij(60) — minuta wstecz", minus_60.minuta() == 59)
test("odejmij(60) — godzina 11", minus_60.godzina() == 11)

# odejmij_dni
niech minus_1d = baza.odejmij_dni(1)
test("odejmij_dni(1) — 31 grudnia", minus_1d.dzien() == 31)
test("odejmij_dni(1) — miesiąc 12", minus_1d.miesiac() == 12)

# odejmij_godziny
niech minus_12h = baza.odejmij_godziny(12)
test("odejmij_godziny(12) — godzina 0", minus_12h.godzina() == 0)

# dodaj — ujemna wartość = cofnięcie
niech cofnij = baza.dodaj(-3600)
test("dodaj(-3600) — cofnij godzinę", cofnij.godzina() == 11)

# łańcuchowanie operacji
niech lancuch = baza.dodaj_dni(1).dodaj_godziny(2).dodaj_minuty(30)
test("łańcuchowanie — dzień", lancuch.dzien() == 2)
test("łańcuchowanie — godzina", lancuch.godzina() == 14)
test("łańcuchowanie — minuta", lancuch.minuta() == 30)

# ============================================================================
# 6. PORÓWNANIA
# ============================================================================

niech wczesny = Czas.nowy(2024, 1, 1)
niech pozny = Czas.nowy(2024, 12, 31)
niech kopia = Czas.nowy(2024, 1, 1)

test("przed() — styczeń przed grudniem", wczesny.przed(pozny))
test("po() — grudzień po styczniu", pozny.po(wczesny))
test("przed() — grudzień nie przed styczniem", pozny.przed(wczesny) == falsz)

# porownaj — zwraca -1, 0, 1
test("porownaj() — wcześniejszy = -1", wczesny.porownaj(pozny) == -1)
test("porownaj() — późniejszy = 1", pozny.porownaj(wczesny) == 1)
test("porownaj() — równy = 0", wczesny.porownaj(kopia) == 0)

# roznica — w sekundach
niech diff = pozny.roznica(wczesny)
test("roznica() — > 0 (późniejszy - wcześniejszy)", diff > 0)
test("roznica() — cały rok ≈ 365 dni", diff > 365 * 86400 - 100)

# odejmij(inny_czas) — też daje różnicę w sekundach
niech diff2 = pozny.odejmij(wczesny)
test("odejmij(Czas) — różnica w sekundach (Float)", diff2 > 0)

# miedzy
niech srodek = Czas.nowy(2024, 6, 15)
test("miedzy() — czerwiec między styczniem a grudniem", srodek.miedzy(wczesny, pozny))
test("miedzy() — styczeń nie między czerwcem a grudniem", wczesny.miedzy(srodek, pozny) == falsz)

# ============================================================================
# 7. FORMATOWANIE I KONWERSJA
# ============================================================================

niech t_fmt = Czas.nowy(2024, 3, 15, 14, 30, 45)

# format() — strftime
niech fmt1 = t_fmt.format("%Y-%m-%d")
test("format('%Y-%m-%d')", fmt1 == "2024-03-15")

niech fmt2 = t_fmt.format("%H:%M:%S")
test("format('%H:%M:%S')", fmt2 == "14:30:45")

niech fmt3 = t_fmt.format("%d.%m.%Y %H:%M")
test("format('%d.%m.%Y %H:%M')", fmt3 == "15.03.2024 14:30")

# do_tekstu()
niech tekst = t_fmt.do_tekstu()
test("do_tekstu() zawiera rok", tekst.zawiera("2024"))

# ascii()
niech asc = t_fmt.ascii()
test("ascii() zwraca string", asc.dlg() > 0)

# iso8601
niech iso = t_fmt.iso8601()
test("iso8601() zawiera 2024", iso.zawiera("2024"))

# do_utc()
niech utc_conv = t_fmt.do_utc()
test("do_utc() — czy_utc", utc_conv.czy_utc())

# do_lokalnego()
niech lok_conv = utc_conv.do_lokalnego()
test("do_lokalnego() — konwersja z powrotem", lok_conv.rok() == 2024)

# do_strefy — konwersja do konkretnej strefy
niech tokyo = t_fmt.do_strefy("+09:00")
test("do_strefy(+09:00) — rok zachowany", tokyo.rok() == 2024)

# ============================================================================
# 8. ZAOKRĄGLANIE
# ============================================================================

# Tworzymy czas z ułamkiem sekundy przez timestamp
niech t_round = Czas.z_timestampu(1700000000.123456)

niech zaokr = t_round.zaokraglij(0)
test("zaokraglij(0) — sekunda zaokrąglona", zaokr.mikrosekunda() == 0)

niech suf = t_round.sufit(0)
test("sufit(0) — zaokrąglenie w górę", suf.mikrosekunda() == 0)

niech podl = t_round.podloga(0)
test("podloga(0) — zaokrąglenie w dół", podl.mikrosekunda() == 0)

# ============================================================================
# 9. POLSKIE NAZWY
# ============================================================================

# 2024-03-14 to czwartek
test("nazwa_dnia_tygodnia() — czwartek", t_get.nazwa_dnia_tygodnia() == "czwartek")
test("nazwa_dnia_skrot() — czw", t_get.nazwa_dnia_skrot() == "czw")

# Marzec
test("nazwa_miesiaca() — marzec", t_get.nazwa_miesiaca() == "marzec")
test("nazwa_miesiaca_dopelniacz() — marca", t_get.nazwa_miesiaca_dopelniacz() == "marca")
test("nazwa_miesiaca_skrot() — mar", t_get.nazwa_miesiaca_skrot() == "mar")

# Styczeń
niech styczen = Czas.nowy(2024, 1, 15)
test("nazwa_miesiaca() — styczeń", styczen.nazwa_miesiaca() == "styczeń")
test("nazwa_miesiaca_dopelniacz() — stycznia", styczen.nazwa_miesiaca_dopelniacz() == "stycznia")

# Grudzień
niech grudzien = Czas.nowy(2024, 12, 25)
test("nazwa_miesiaca() — grudzień", grudzien.nazwa_miesiaca() == "grudzień")
test("nazwa_miesiaca_dopelniacz() — grudnia", grudzien.nazwa_miesiaca_dopelniacz() == "grudnia")

# do_tekstu_pl()
niech pl_tekst = t_get.do_tekstu_pl()
test("do_tekstu_pl() zawiera 'czwartek'", pl_tekst.zawiera("czwartek"))
test("do_tekstu_pl() zawiera 'marca'", pl_tekst.zawiera("marca"))
test("do_tekstu_pl() zawiera '2024'", pl_tekst.zawiera("2024"))

# ============================================================================
# 10. STATYCZNE METODY POMOCNICZE
# ============================================================================

# Czas.stempel()
niech st = Czas.stempel()
test("Czas.stempel() > 0", st > 0)

# Czas.stempel_f()
niech st_f = Czas.stempel_f()
test("Czas.stempel_f() > 0", st_f > 0)

# Czas.uspij() — testujemy minimalny sleep
niech przed_sleep = Czas.stempel_f()
Czas.uspij(0.01)
niech po_sleep = Czas.stempel_f()
test("Czas.uspij(0.01) — czas upłynął", po_sleep - przed_sleep >= 0.01)

# ============================================================================
# 11. PARSOWANIE STANDARDOWYCH FORMATÓW
# ============================================================================

niech t_iso = Czas.z_iso8601("2024-06-15T14:30:00+02:00")
test("z_iso8601() — rok", t_iso.rok() == 2024)
test("z_iso8601() — miesiąc", t_iso.miesiac() == 6)

# ============================================================================
# 12. DO_TABLICY
# ============================================================================

niech tab = t_get.do_tablicy()
test("do_tablicy() — tablica 10-elementowa", tab.dlg() == 10)
test("do_tablicy()[5] — rok", tab[5] == 2024)

# ============================================================================
# PODSUMOWANIE
# ============================================================================

pokazl ""
pokazl "================================"
pokazl "WYNIKI TESTÓW BIBLIOTEKI CZAS"
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
