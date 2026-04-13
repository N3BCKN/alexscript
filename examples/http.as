# ============================================================================
# test_http.as — Testy biblioteki Http
# ============================================================================
import("http")
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
# 1. KODOWANIE I DEKODOWANIE URL (offline)
# ============================================================================

niech zakodowany = Http.koduj_url("witaj świecie!")
test("koduj_url — brak spacji", zakodowany.zawiera(" ") == falsz)

niech odkodowany = Http.dekoduj_url(zakodowany)
test("dekoduj_url — round-trip", odkodowany == "witaj świecie!")

niech tekst = "test/ścieżka?parametr=wartość"
niech rt = Http.dekoduj_url(Http.koduj_url(tekst))
test("round-trip encode/decode", rt == tekst)

# ============================================================================
# 2. PARSOWANIE URL (offline)
# ============================================================================

niech p = Http.parsuj_url("https://example.com:8080/api/v1?klucz=wartosc#sekcja")
test("schemat", p["schemat"] == "https")
test("host", p["host"] == "example.com")
test("port", p["port"] == 8080)
test("sciezka", p["sciezka"] == "/api/v1")
test("zapytanie", p["zapytanie"] == "klucz=wartosc")
test("fragment", p["fragment"] == "sekcja")

niech prosty = Http.parsuj_url("http://test.com/strona")
test("prosty — schemat", prosty["schemat"] == "http")
test("prosty — host", prosty["host"] == "test.com")

# ============================================================================
# 3. QUERY STRING (offline)
# ============================================================================

niech qs = Http.zbuduj_zapytanie({"a": "1", "b": "2"})
test("zbuduj — a=1", qs.zawiera("a=1"))
test("zbuduj — b=2", qs.zawiera("b=2"))
test("zbuduj — &", qs.zawiera("&"))

niech sp = Http.parsuj_zapytanie("x=10&y=20")
test("parsuj_zapytanie — x", sp["x"] == "10")
test("parsuj_zapytanie — y", sp["y"] == "20")

niech params = {"klucz": "wartosc", "foo": "bar"}
niech qs2 = Http.zbuduj_zapytanie(params)
niech odtw = Http.parsuj_zapytanie(qs2)
test("round-trip qs — klucz", odtw["klucz"] == "wartosc")
test("round-trip qs — foo", odtw["foo"] == "bar")

# ============================================================================
# 4. BUDOWANIE URL (offline)
# ============================================================================

niech url = Http.zbuduj_url("https", "example.com", 443, "/api", "q=1")
test("zbuduj_url — https", url.zawiera("https"))
test("zbuduj_url — host", url.zawiera("example.com"))
test("zbuduj_url — /api", url.zawiera("/api"))
test("zbuduj_url — q=1", url.zawiera("q=1"))

# ============================================================================
# 5. HTTP GET (sieć)
# ============================================================================

niech odp = Http.get("https://httpbin.org/get")
test("GET — status 200", odp["status"] == 200)
test("GET — ciało niepuste", odp["cialo"].dlg() > 0)
test("GET — czy_sukces", odp["czy_sukces"])
test("GET — nagłówki", odp["naglowki"]["content-type"].dlg() > 0)
test("GET — wiadomość", odp["wiadomosc"] == "OK")

# ============================================================================
# 6. GET JSON (sieć)
# ============================================================================

niech dj = Http.get_json("https://httpbin.org/get")
test("get_json — url", dj["url"] == "https://httpbin.org/get")
test("get_json — headers istnieją", dj["headers"] != nic)

# ============================================================================
# 7. GET JSON z nagłówkami (sieć)
# ============================================================================

niech dh = Http.get_json("https://httpbin.org/headers", {"X-Test": "abc123"})
test("custom header wysłany", dh["headers"]["X-Test"] == "abc123")

# ============================================================================
# 8. POST (sieć)
# ============================================================================

niech op = Http.post("https://httpbin.org/post", "dane testowe")
test("POST — status 200", op["status"] == 200)
test("POST — ciało", op["cialo"].zawiera("dane testowe"))

# ============================================================================
# 9. POST JSON (sieć)
# ============================================================================

niech wynik = Http.post_json("https://httpbin.org/post", {"klucz": "wartosc", "liczba": 42})
test("post_json — klucz", wynik["json"]["klucz"] == "wartosc")
test("post_json — liczba", wynik["json"]["liczba"] == 42)

# ============================================================================
# 10. PUT (sieć)
# ============================================================================

niech oput = Http.put("https://httpbin.org/put", "put data")
test("PUT — status 200", oput["status"] == 200)

# ============================================================================
# 11. DELETE (sieć)
# ============================================================================

niech odel = Http.delete("https://httpbin.org/delete")
test("DELETE — status 200", odel["status"] == 200)

# ============================================================================
# 12. HEAD (sieć)
# ============================================================================

niech ohead = Http.head("https://httpbin.org/get")
test("HEAD — status 200", ohead["status"] == 200)
test("HEAD — ciało puste", ohead["cialo"].dlg() == 0)

# ============================================================================
# 13. KODY STATUSU (sieć)
# ============================================================================

niech o404 = Http.get("https://httpbin.org/status/404")
test("404 — status", o404["status"] == 404)
test("404 — czy_blad_klienta", o404["czy_blad_klienta"])
test("404 — nie sukces", o404["czy_sukces"] == falsz)

niech o500 = Http.get("https://httpbin.org/status/500")
test("500 — status", o500["status"] == 500)
test("500 — czy_blad_serwera", o500["czy_blad_serwera"])

# ============================================================================
# 14. POST FORMULARZ (sieć)
# ============================================================================

niech of = Http.post_formularz("https://httpbin.org/post", {"user": "jan", "pass": "abc"})
test("formularz — status 200", of["status"] == 200)
niech fb = Json.parsuj(of["cialo"])
test("formularz — user", fb["form"]["user"] == "jan")
test("formularz — pass", fb["form"]["pass"] == "abc")

# ============================================================================
# 15. PRZEKIEROWANIA (sieć)
# ============================================================================

niech or2 = Http.get("https://httpbin.org/redirect/1")
test("redirect → 200", or2["status"] == 200)
test("redirect → sukces", or2["czy_sukces"])

# ============================================================================
# 16. HTTPS (sieć)
# ============================================================================

niech ossl = Http.get("https://httpbin.org/get")
test("HTTPS — 200", ossl["status"] == 200)

# ============================================================================
# PODSUMOWANIE
# ============================================================================

pokazl ""
pokazl "================================"
pokazl "WYNIKI TESTÓW BIBLIOTEKI HTTP"
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
