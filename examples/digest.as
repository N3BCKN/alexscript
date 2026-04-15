# ============================================================================
# test_digest.as — Testy biblioteki Digest
# ============================================================================
import("digest")
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
# 1. MD5
# ============================================================================

niech md5 = Digest.md5("hello")
test("md5 — hex length 32", md5.dlg() == 32)
test("md5 — deterministic", Digest.md5("hello") == md5)
test("md5 — known value", md5 == "5d41402abc4b2a76b9719d911017c592")

niech md5_b64 = Digest.md5_base64("hello")
test("md5_base64 — niepusty", md5_b64.dlg() > 0)

niech md5_bajty = Digest.md5_bajty("hello")
test("md5_bajty — 16 bajtów", md5_bajty.dlg() == 16)

# Różne wejścia dają różne hashe
test("md5 — różne wejścia", Digest.md5("hello") != Digest.md5("world"))

# Pusty string
niech md5_pusty = Digest.md5("")
test("md5 pusty string", md5_pusty == "d41d8cd98f00b204e9800998ecf8427e")

# ============================================================================
# 2. SHA1
# ============================================================================

niech sha1 = Digest.sha1("hello")
test("sha1 — hex length 40", sha1.dlg() == 40)
test("sha1 — known value", sha1 == "aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d")

niech sha1_b64 = Digest.sha1_base64("hello")
test("sha1_base64 — niepusty", sha1_b64.dlg() > 0)

niech sha1_bajty = Digest.sha1_bajty("hello")
test("sha1_bajty — 20 bajtów", sha1_bajty.dlg() == 20)

# ============================================================================
# 3. SHA256
# ============================================================================

niech sha256 = Digest.sha256("hello")
test("sha256 — hex length 64", sha256.dlg() == 64)
test("sha256 — known value", sha256 == "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
test("sha256 — deterministic", Digest.sha256("hello") == sha256)

niech sha256_b64 = Digest.sha256_base64("hello")
test("sha256_base64 — niepusty", sha256_b64.dlg() > 0)

niech sha256_bajty = Digest.sha256_bajty("hello")
test("sha256_bajty — 32 bajty", sha256_bajty.dlg() == 32)

# ============================================================================
# 4. SHA384
# ============================================================================

niech sha384 = Digest.sha384("hello")
test("sha384 — hex length 96", sha384.dlg() == 96)
test("sha384 — deterministic", Digest.sha384("hello") == sha384)

niech sha384_bajty = Digest.sha384_bajty("hello")
test("sha384_bajty — 48 bajtów", sha384_bajty.dlg() == 48)

# ============================================================================
# 5. SHA512
# ============================================================================

niech sha512 = Digest.sha512("hello")
test("sha512 — hex length 128", sha512.dlg() == 128)
test("sha512 — deterministic", Digest.sha512("hello") == sha512)

niech sha512_bajty = Digest.sha512_bajty("hello")
test("sha512_bajty — 64 bajty", sha512_bajty.dlg() == 64)

# ============================================================================
# 6. HMAC
# ============================================================================

niech hmac = Digest.hmac_sha256("klucz", "wiadomosc")
test("hmac_sha256 — hex length 64", hmac.dlg() == 64)
test("hmac_sha256 — deterministic", Digest.hmac_sha256("klucz", "wiadomosc") == hmac)
test("hmac_sha256 — inny klucz = inny wynik", Digest.hmac_sha256("inny", "wiadomosc") != hmac)

niech hmac512 = Digest.hmac_sha512("klucz", "wiadomosc")
test("hmac_sha512 — hex length 128", hmac512.dlg() == 128)

niech hmac_md5 = Digest.hmac_md5("klucz", "wiadomosc")
test("hmac_md5 — hex length 32", hmac_md5.dlg() == 32)

niech hmac_sha1 = Digest.hmac_sha1("klucz", "wiadomosc")
test("hmac_sha1 — hex length 40", hmac_sha1.dlg() == 40)

# ============================================================================
# 7. PORÓWNANIE (constant-time)
# ============================================================================

niech h1 = Digest.sha256("test")
niech h2 = Digest.sha256("test")
niech h3 = Digest.sha256("inny")
test("porownaj — identyczne", Digest.porownaj(h1, h2))
test("porownaj — różne", Digest.porownaj(h1, h3) == falsz)

# ============================================================================
# 8. HEX ↔ BAJTY konwersja
# ============================================================================

niech bajty = Digest.hex_na_bajty("48656c6c6f")
test("hex_na_bajty — 5 bajtów", bajty.dlg() == 5)
test("hex_na_bajty — H=72", bajty[0] == 72)

niech hex = Digest.bajty_na_hex([72, 101, 108, 108, 111])
test("bajty_na_hex — Hello", hex == "48656c6c6f")

# ============================================================================
# 9. HASH PLIKU
# ============================================================================

niech sciezka = "/tmp/as_test_digest.txt"
Plik.zapisz(sciezka, "hello")
niech hash_pliku = Digest.sha256_plik(sciezka)
test("sha256_plik — identyczny z sha256 tekstu", hash_pliku == sha256)

niech md5_pliku = Digest.md5_plik(sciezka)
test("md5_plik — identyczny", md5_pliku == md5)

Plik.usun(sciezka)

# ============================================================================
# PODSUMOWANIE
# ============================================================================

pokazl ""
pokazl "================================"
pokazl "WYNIKI TESTÓW BIBLIOTEKI DIGEST"
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
