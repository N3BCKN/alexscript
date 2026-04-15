# ============================================================================
# test_securerandom.as — Testy biblioteki SecureRandom
# ============================================================================
import("securerandom")

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
# 1. HEX
# ============================================================================

niech h1 = SecureRandom.hex()
test("hex domyślny — 32 znaki (16 bajtów)", h1.dlg() == 32)

niech h2 = SecureRandom.hex(10)
test("hex(10) — 20 znaków", h2.dlg() == 20)

niech h3 = SecureRandom.hex(1)
test("hex(1) — 2 znaki", h3.dlg() == 2)

# Unikalność
niech h4 = SecureRandom.hex()
test("hex — unikalne", h1 != h4)

# ============================================================================
# 2. BASE64
# ============================================================================

niech b1 = SecureRandom.base64()
test("base64 domyślny — niepusty", b1.dlg() > 0)

niech b2 = SecureRandom.base64(10)
test("base64(10) — niepusty", b2.dlg() > 0)

# ============================================================================
# 3. URL-SAFE BASE64
# ============================================================================

niech u1 = SecureRandom.urlsafe_base64()
test("urlsafe_base64 — niepusty", u1.dlg() > 0)
test("urlsafe_base64 — brak +", u1.zawiera("+") == falsz)
test("urlsafe_base64 — brak /", u1.zawiera("/") == falsz)

# ============================================================================
# 4. UUID
# ============================================================================

niech uuid1 = SecureRandom.uuid()
test("uuid — 36 znaków", uuid1.dlg() == 36)
test("uuid — zawiera myślniki", uuid1.zawiera("-"))

niech uuid2 = SecureRandom.uuid()
test("uuid — unikalne", uuid1 != uuid2)

# Format: 8-4-4-4-12
niech czesci = uuid1.dlg()
test("uuid — format poprawny", czesci == 36)

# ============================================================================
# 5. ALFANUMERYCZNY
# ============================================================================

niech an1 = SecureRandom.alfanumeryczny()
test("alfanumeryczny domyślny — 16 znaków", an1.dlg() == 16)

niech an2 = SecureRandom.alfanumeryczny(32)
test("alfanumeryczny(32) — 32 znaki", an2.dlg() == 32)

niech an3 = SecureRandom.alfanumeryczny(1)
test("alfanumeryczny(1) — 1 znak", an3.dlg() == 1)

# Unikalność
niech an4 = SecureRandom.alfanumeryczny()
test("alfanumeryczny — unikalne", an1 != an4)

# ============================================================================
# 6. LOSOWA LICZBA
# ============================================================================

# Float [0, 1)
niech f1 = SecureRandom.losowa_liczba()
test("losowa_liczba() — >= 0", f1 >= 0)
test("losowa_liczba() — < 1", f1 < 1)

# Int [0, n)
niech n1 = SecureRandom.losowa_liczba(100)
test("losowa_liczba(100) — >= 0", n1 >= 0)
test("losowa_liczba(100) — < 100", n1 < 100)

niech n2 = SecureRandom.losowa_liczba(10)
test("losowa_liczba(10) — >= 0", n2 >= 0)
test("losowa_liczba(10) — < 10", n2 < 10)

# ============================================================================
# 7. LOSOWE BAJTY
# ============================================================================

niech bajty = SecureRandom.losowe_bajty(16)
test("losowe_bajty(16) — 16 elementów", bajty.dlg() == 16)

niech bajty2 = SecureRandom.losowe_bajty(1)
test("losowe_bajty(1) — 1 element", bajty2.dlg() == 1)
test("losowe_bajty — wartość 0-255", bajty[0] >= 0)
test("losowe_bajty — wartość <= 255", bajty[0] <= 255)

# ============================================================================
# 8. LOSOWA Z ZAKRESU
# ============================================================================

niech z1 = SecureRandom.losowa_z_zakresu(10, 20)
test("losowa_z_zakresu(10,20) — >= 10", z1 >= 10)
test("losowa_z_zakresu(10,20) — <= 20", z1 <= 20)

niech z2 = SecureRandom.losowa_z_zakresu(1, 1)
test("losowa_z_zakresu(1,1) — == 1", z2 == 1)

niech z3 = SecureRandom.losowa_z_zakresu(0, 1000)
test("losowa_z_zakresu(0,1000) — >= 0", z3 >= 0)
test("losowa_z_zakresu(0,1000) — <= 1000", z3 <= 1000)

# ============================================================================
# 9. TOKEN
# ============================================================================

niech t1 = SecureRandom.token()
test("token domyślny — 32 znaki", t1.dlg() == 32)

niech t2 = SecureRandom.token(64)
test("token(64) — 64 znaki", t2.dlg() == 64)

niech t3 = SecureRandom.token()
test("token — unikalne", t1 != t3)

# ============================================================================
# 10. WYBIERZ
# ============================================================================

niech w1 = SecureRandom.wybierz("abc", 10)
test("wybierz — 10 znaków", w1.dlg() == 10)

niech w2 = SecureRandom.wybierz("0123456789", 6)
test("wybierz cyfry — 6 znaków", w2.dlg() == 6)

niech w3 = SecureRandom.wybierz("x", 5)
test("wybierz 1 znak — xxxxx", w3 == "xxxxx")

# ============================================================================
# PODSUMOWANIE
# ============================================================================

pokazl ""
pokazl "======================================="
pokazl "WYNIKI TESTÓW BIBLIOTEKI SECURERANDOM"
pokazl "======================================="
pokazl "Przeszło: " + testy_ok
pokazl "Nie przeszło: " + testy_fail
pokazl "Razem: " + (testy_ok + testy_fail)
pokazl "======================================="

jesli testy_fail == 0 {
    pokazl "WSZYSTKIE TESTY PRZESZŁY!"
} albo {
    pokazl "UWAGA: " + testy_fail + " testów nie przeszło!"
}
