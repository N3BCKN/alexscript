abstrakcyjna klasa StrategiaPlacenia {
    funkcja konstruktor() {}
    
    funkcja zaplac(kwota) {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa PlatnoscKarta < StrategiaPlacenia {
    funkcja konstruktor(numer, cvv) {
        super()
        niech @numer = numer
        niech @cvv = cvv
    }
    
    funkcja zaplac(kwota) {
        pokazl "  [KARTA] Przetwarzanie płatności kartą"
        pokazl "  [KARTA] Numer: ****" + @numer.wydziel(@numer.dlg - 4, 4)
        pokazl "  [KARTA] Kwota: " + kwota + " PLN"
        pokazl "  [KARTA] ✓ Płatność zaakceptowana"
    }
}

klasa PlatnoscBlik < StrategiaPlacenia {
    funkcja konstruktor(kod) {
        super()
        niech @kod = kod
    }
    
    funkcja zaplac(kwota) {
        pokazl "  [BLIK] Wysłano powiadomienie na telefon"
        pokazl "  [BLIK] Kod: " + @kod
        pokazl "  [BLIK] Kwota: " + kwota + " PLN"
        pokazl "  [BLIK] ✓ Płatność potwierdzona"
    }
}

klasa PlatnoscPrzelew < StrategiaPlacenia {
    funkcja konstruktor(email) {
        super()
        niech @email = email
    }
    
    funkcja zaplac(kwota) {
        pokazl "  [PRZELEW] Przekierowanie do bramki płatności"
        pokazl "  [PRZELEW] Email: " + @email
        pokazl "  [PRZELEW] Kwota: " + kwota + " PLN"
        pokazl "  [PRZELEW] ✓ Link wysłany na email"
    }
}

klasa PlatnoscGotowka < StrategiaPlacenia {
    funkcja zaplac(kwota) {
        pokazl "  [GOTÓWKA] Kwota do zapłaty: " + kwota + " PLN"
        pokazl "  [GOTÓWKA] Płatność przy odbiorze"
        pokazl "  [GOTÓWKA] ✓ Zamówienie przyjęte"
    }
}

klasa KoszykZakupowy {
    funkcja konstruktor() {
        niech @produkty = []
        niech @strategia_placenia = nic
    }
    
    funkcja dodaj_produkt(nazwa, cena) {
        @produkty.dodaj({"nazwa": nazwa, "cena": cena})
        pokazl "  [KOSZYK] Dodano: " + nazwa + " (" + cena + " PLN)"
    }
    
    funkcja ustaw_strategie(strategia) {
        niech @strategia_placenia = strategia
        pokazl "  [KOSZYK] Wybrano metodę płatności"
    }
    
    funkcja oblicz_suma() {
        niech suma = 0
        dla produkt w @produkty {
            niech suma = suma + produkt["cena"]
        }
        zwroc suma
    }
    
    funkcja realizuj_zakup() {
        jesli @produkty.dlg == 0 {
            pokazl "  [KOSZYK] Koszyk jest pusty"
            zwroc
        }
        
        jesli @strategia_placenia == nic {
            pokazl "  [KOSZYK] Wybierz metodę płatności"
            zwroc
        }
        
        pokazl "[KOSZYK] Realizacja zakupu:"
        pokazl "[KOSZYK] Produktów: " + @produkty.dlg
        
        niech suma = oblicz_suma()
        pokazl "[KOSZYK] Suma: " + suma + " PLN"
        pokazl ""
        
        @strategia_placenia.zaplac(suma)
        pokazl ""
        pokazl "[KOSZYK] ✓ Zamówienie zrealizowane"
    }
    
    funkcja wyczysc() {
        niech @produkty = []
        pokazl "  [KOSZYK] Wyczyszczono koszyk"
    }
}

pokazl "=== Test Strategy ==="
pokazl ""

niech koszyk = KoszykZakupowy.nowy()

pokazl "=== Scenariusz 1: Płatność kartą ==="
koszyk.dodaj_produkt("Laptop", 3500)
koszyk.dodaj_produkt("Mysz", 150)
pokazl ""

niech karta = PlatnoscKarta.nowy("1234567890123456", "123")
koszyk.ustaw_strategie(karta)
pokazl ""

koszyk.realizuj_zakup()
pokazl ""
pokazl "================================"
pokazl ""

koszyk.wyczysc()

pokazl "=== Scenariusz 2: Płatność BLIK ==="
koszyk.dodaj_produkt("Książka", 45)
koszyk.dodaj_produkt("Ebook", 25)
pokazl ""

niech blik = PlatnoscBlik.nowy("123456")
koszyk.ustaw_strategie(blik)
pokazl ""

koszyk.realizuj_zakup()
pokazl ""
pokazl "================================"
pokazl ""

koszyk.wyczysc()

pokazl "=== Scenariusz 3: Płatność przelewem ==="
koszyk.dodaj_produkt("Monitor", 1200)
pokazl ""

niech przelew = PlatnoscPrzelew.nowy("user@example.com")
koszyk.ustaw_strategie(przelew)
pokazl ""

koszyk.realizuj_zakup()
pokazl ""
pokazl "================================"
pokazl ""

koszyk.wyczysc()

pokazl "=== Scenariusz 4: Płatność gotówką ==="
koszyk.dodaj_produkt("Klawiatura", 350)
pokazl ""

niech gotowka = PlatnoscGotowka.nowy()
koszyk.ustaw_strategie(gotowka)
pokazl ""

koszyk.realizuj_zakup()