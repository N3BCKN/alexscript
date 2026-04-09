# ============================================================================
# test_mat.as — Testy biblioteki Mat
# ============================================================================
import("mat")

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

# Helper: porównanie z tolerancją dla float
funkcja blisko(a, b, eps = 0.0001) {
    niech diff = a - b
    jesli diff < 0 {
        diff = diff * -1
    }
    zwroc diff < eps
}

# ============================================================================
# 1. STAŁE
# ============================================================================

test("Mat.PI ≈ 3.14159", blisko(Mat.PI, 3.14159, 0.001))
test("Mat.E ≈ 2.71828", blisko(Mat.E, 2.71828, 0.001))
test("Mat.NIESKONCZONOSC > 0", Mat.NIESKONCZONOSC > 999999999)
test("Mat.MINUS_NIESKONCZONOSC < 0", Mat.MINUS_NIESKONCZONOSC < -999999999)
test("Mat.NAN != Mat.NAN (NaN property)", Mat.czy_nan(Mat.NAN))

# ============================================================================
# 2. TRYGONOMETRIA
# ============================================================================

test("sin(0) == 0", blisko(Mat.sin(0), 0.0))
test("sin(PI/2) == 1", blisko(Mat.sin(Mat.PI / 2), 1.0))
test("cos(0) == 1", blisko(Mat.cos(0), 1.0))
test("cos(PI) == -1", blisko(Mat.cos(Mat.PI), -1.0))
test("tan(0) == 0", blisko(Mat.tan(0), 0.0))
test("tan(PI/4) ≈ 1", blisko(Mat.tan(Mat.PI / 4), 1.0))

# Inverse trig
test("asin(1) == PI/2", blisko(Mat.asin(1), Mat.PI / 2))
test("acos(1) == 0", blisko(Mat.acos(1), 0.0))
test("atan(1) == PI/4", blisko(Mat.atan(1), Mat.PI / 4))
test("atan2(1,1) == PI/4", blisko(Mat.atan2(1, 1), Mat.PI / 4))
test("atan2(0,-1) == PI", blisko(Mat.atan2(0, -1), Mat.PI))

# ============================================================================
# 3. HIPERBOLICZNE
# ============================================================================

test("sinh(0) == 0", blisko(Mat.sinh(0), 0.0))
test("cosh(0) == 1", blisko(Mat.cosh(0), 1.0))
test("tanh(0) == 0", blisko(Mat.tanh(0), 0.0))

test("asinh(0) == 0", blisko(Mat.asinh(0), 0.0))
test("acosh(1) == 0", blisko(Mat.acosh(1), 0.0))
test("atanh(0) == 0", blisko(Mat.atanh(0), 0.0))

# ============================================================================
# 4. WYKŁADNICZE I LOGARYTMICZNE
# ============================================================================

test("exp(0) == 1", blisko(Mat.exp(0), 1.0))
test("exp(1) == E", blisko(Mat.exp(1), Mat.E))
# test("expm1(0) == 0", blisko(Mat.expm1(0), 0.0))

test("log(1) == 0", blisko(Mat.log(1), 0.0))
test("log(E) == 1", blisko(Mat.log(Mat.E), 1.0))
test("log(8, 2) == 3", blisko(Mat.log(8, 2), 3.0))
test("log2(8) == 3", blisko(Mat.log2(8), 3.0))
test("log10(1000) == 3", blisko(Mat.log10(1000), 3.0))
# test("log1p(0) == 0", blisko(Mat.log1p(0), 0.0))

# ============================================================================
# 5. PIERWIASTKI I POTĘGI
# ============================================================================

test("sqrt(4) == 2", blisko(Mat.sqrt(4), 2.0))
test("sqrt(2) ≈ 1.4142", blisko(Mat.sqrt(2), 1.4142, 0.001))
test("cbrt(27) == 3", blisko(Mat.cbrt(27), 3.0))
test("cbrt(8) == 2", blisko(Mat.cbrt(8), 2.0))
test("hipotenuza(3, 4) == 5", blisko(Mat.hipotenuza(3, 4), 5.0))
test("potega(2, 10) == 1024", Mat.potega(2, 10) == 1024)
test("potega(3, 3) == 27", Mat.potega(3, 3) == 27)

# ============================================================================
# 6. FUNKCJE BŁĘDU I GAMMA
# ============================================================================

test("erf(0) == 0", blisko(Mat.erf(0), 0.0))
test("erfc(0) == 1", blisko(Mat.erfc(0), 1.0))
test("erf(x) + erfc(x) == 1", blisko(Mat.erf(0.5) + Mat.erfc(0.5), 1.0))

test("gamma(5) == 24 (4!)", blisko(Mat.gamma(5), 24.0))
test("gamma(1) == 1", blisko(Mat.gamma(1), 1.0))
test("lgamma(1) == 0", blisko(Mat.lgamma(1), 0.0))

# ============================================================================
# 7. ZAOKRĄGLANIE
# ============================================================================

test("podloga(3.7) == 3", Mat.podloga(3.7) == 3)
test("podloga(-3.2) == -4", Mat.podloga(-3.2) == -4)
test("sufit(3.2) == 4", Mat.sufit(3.2) == 4)
test("sufit(-3.7) == -3", Mat.sufit(-3.7) == -3)
test("zaokraglij(3.5) == 4", Mat.zaokraglij(3.5) == 4)
test("zaokraglij(3.14159, 2) ≈ 3.14", blisko(Mat.zaokraglij(3.14159, 2), 3.14))
test("obetnij(3.9) == 3", Mat.obetnij(3.9) == 3)
test("obetnij(-3.9) == -3", Mat.obetnij(-3.9) == -3)

# ============================================================================
# 8. WARTOŚĆ BEZWZGLĘDNA I ZNAK
# ============================================================================

test("abs(5) == 5", Mat.abs(5) == 5)
test("abs(-5) == 5", Mat.abs(-5) == 5)
test("abs(-3.14) ≈ 3.14", blisko(Mat.abs(-3.14), 3.14))

test("znak(42) == 1", Mat.znak(42) == 1)
test("znak(-7) == -1", Mat.znak(-7) == -1)
test("znak(0) == 0", Mat.znak(0) == 0)

# ============================================================================
# 9. MIN / MAX / OGRANICZ
# ============================================================================

test("min(3, 7) == 3", Mat.min(3, 7) == 3)
test("min(-1, 1) == -1", Mat.min(-1, 1) == -1)
test("max(3, 7) == 7", Mat.max(3, 7) == 7)
test("max(-1, 1) == 1", Mat.max(-1, 1) == 1)

test("ogranicz(5, 0, 10) == 5", Mat.ogranicz(5, 0, 10) == 5)
test("ogranicz(-5, 0, 10) == 0", Mat.ogranicz(-5, 0, 10) == 0)
test("ogranicz(15, 0, 10) == 10", Mat.ogranicz(15, 0, 10) == 10)

# ============================================================================
# 10. SILNIA
# ============================================================================

test("silnia(0) == 1", Mat.silnia(0) == 1)
test("silnia(1) == 1", Mat.silnia(1) == 1)
test("silnia(5) == 120", Mat.silnia(5) == 120)
test("silnia(10) == 3628800", Mat.silnia(10) == 3628800)

# ============================================================================
# 11. KONWERSJA STOPNIE/RADIANY
# ============================================================================

test("na_radiany(180) == PI", blisko(Mat.na_radiany(180), Mat.PI))
test("na_radiany(90) == PI/2", blisko(Mat.na_radiany(90), Mat.PI / 2))
test("na_stopnie(PI) == 180", blisko(Mat.na_stopnie(Mat.PI), 180.0))
test("na_stopnie(PI/2) == 90", blisko(Mat.na_stopnie(Mat.PI / 2), 90.0))

# round-trip: stopnie → radiany → stopnie
test("na_stopnie(na_radiany(45)) == 45", blisko(Mat.na_stopnie(Mat.na_radiany(45)), 45.0))

# ============================================================================
# 12. LOSOWOŚĆ
# ============================================================================

niech los = Mat.losowa()
test("losowa() >= 0", los >= 0)
test("losowa() < 1", los < 1)

niech los_z = Mat.losowa_zakres(10, 20)
test("losowa_zakres(10, 20) >= 10", los_z >= 10)
test("losowa_zakres(10, 20) <= 20", los_z <= 20)

# ============================================================================
# 13. PREDYKATY
# ============================================================================

test("czy_nan(NAN) == prawda", Mat.czy_nan(Mat.NAN))
test("czy_nan(1.0) == falsz", Mat.czy_nan(1.0) == falsz)
test("czy_nieskonczonosc(NIESKONCZONOSC)", Mat.czy_nieskonczonosc(Mat.NIESKONCZONOSC))
test("czy_nieskonczonosc(1.0) == falsz", Mat.czy_nieskonczonosc(1.0) == falsz)

test("czy_parzysta(4)", Mat.czy_parzysta(4))
test("czy_parzysta(7) == falsz", Mat.czy_parzysta(7) == falsz)
test("czy_nieparzysta(7)", Mat.czy_nieparzysta(7))
test("czy_nieparzysta(4) == falsz", Mat.czy_nieparzysta(4) == falsz)

# ============================================================================
# 14. NWD / NWW / RESZTA
# ============================================================================

test("nwd(12, 8) == 4", Mat.nwd(12, 8) == 4)
test("nwd(17, 5) == 1", Mat.nwd(17, 5) == 1)
test("nww(4, 6) == 12", Mat.nww(4, 6) == 12)
test("nww(3, 7) == 21", Mat.nww(3, 7) == 21)
test("reszta(10, 3) == 1", Mat.reszta(10, 3) == 1)
test("dzielenie_calkowite(10, 3) == 3", Mat.dzielenie_calkowite(10, 3) == 3)

# ============================================================================
# 15. FREXP / LDEXP
# ============================================================================

niech fr = Mat.frexp(1024.0)
test("frexp(1024) — tablica 2-elementowa", fr.dlg() == 2)
test("ldexp odwraca frexp", blisko(Mat.ldexp(fr[0], fr[1]), 1024.0))

# ============================================================================
# PODSUMOWANIE
# ============================================================================

pokazl ""
pokazl "================================"
pokazl "WYNIKI TESTÓW BIBLIOTEKI MAT"
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
