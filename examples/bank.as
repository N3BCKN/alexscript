# System zarządzania kontami bankowymi w AlexScript
# Praktyczny przykład wykorzystania programowania obiektowego

# Klasa bazowa reprezentująca konto bankowe
abstrakcyjna klasa KontoBankowe {
    funkcja konstruktor(numer, wlasciciel, saldo = 0) {
        niech @numer = numer
        niech @wlasciciel = wlasciciel
        niech @saldo = saldo
        niech @historia = []
        zarejestruj_operacje("Utworzenie konta", 0)
    }
    
    funkcja pobierz_saldo() {
        zwroc @saldo
    }
    
    funkcja pobierz_dane() {
        zwroc {
            "numer": @numer,
            "wlasciciel": @wlasciciel,
            "saldo": @saldo,
            "typ": pobierz_typ_konta()
        }
    }
    
    funkcja wplata(kwota) {
        jesli kwota <= 0 {
            rzuc "Kwota wpłaty musi być dodatnia"
        }
        
        niech @saldo = @saldo + kwota
        zarejestruj_operacje("Wpłata", kwota)
        zwroc prawda
    }
    
    funkcja wyplata(kwota) {
        jesli kwota <= 0 {
            rzuc "Kwota wypłaty musi być dodatnia"
        }
        
        jesli !sprawdz_mozliwosc_wyplaty(kwota) {
            rzuc "Brak wystarczających środków na koncie"
        }
        
        niech @saldo = @saldo - kwota
        zarejestruj_operacje("Wypłata", -kwota)
        zwroc prawda
    }
    
    funkcja pobierz_historie() {
        zwroc @historia
    }
    
    funkcja pobierz_typ_konta() {
        rzuc "Metoda abstrakcyjna 'pobierz_typ_konta' musi być zaimplementowana w klasach pochodnych"
    }
    
    prywatne
    
    funkcja zarejestruj_operacje(typ, kwota) {
        niech data = pobierz_aktualna_date()
        niech operacja = {
            "data": data,
            "typ": typ,
            "kwota": kwota,
            "saldo_po": @saldo
        }
        @historia.dodaj(operacja)
    }
    
    funkcja pobierz_aktualna_date() {
        # W praktyce powinno to korzystać z biblioteki daty
        # Dla uproszczenia zwracamy string
        zwroc "2025-05-13"
    }
    
    funkcja sprawdz_mozliwosc_wyplaty(kwota) {
        zwroc @saldo >= kwota
    }
}

# Klasa reprezentująca konto oszczędnościowe
klasa KontoOszczednosciowe < KontoBankowe {
    funkcja konstruktor(numer, wlasciciel, stopa_procentowa, saldo = 0) {
        super(numer, wlasciciel, saldo)
        niech @stopa_procentowa = stopa_procentowa
    }
    
    funkcja pobierz_typ_konta() {
        zwroc "oszczędnościowe"
    }
    
    funkcja nalicz_odsetki() {
        niech odsetki = @saldo * (@stopa_procentowa / 100)
        niech @saldo = @saldo + odsetki
        zarejestruj_operacje("Naliczenie odsetek", odsetki)
        zwroc odsetki
    }
}

# Klasa reprezentująca konto kredytowe
klasa KontoKredytowe < KontoBankowe {
    funkcja konstruktor(numer, wlasciciel, limit_kredytowy, oprocentowanie, saldo = 0) {
        super(numer, wlasciciel, saldo)
        niech @limit_kredytowy = limit_kredytowy
        niech @oprocentowanie = oprocentowanie
    }
    
    funkcja pobierz_typ_konta() {
        zwroc "kredytowe"
    }
    
    funkcja nalicz_odsetki_od_debetu() {
        jesli @saldo < 0 {
            niech odsetki = -@saldo * (@oprocentowanie / 100)
            niech @saldo = @saldo - odsetki
            zarejestruj_operacje("Naliczenie odsetek od debetu", -odsetki)
            zwroc odsetki
        }
        zwroc 0
    }
    
    prywatne
    
    funkcja sprawdz_mozliwosc_wyplaty(kwota) {
        zwroc (@saldo - kwota) >= -@limit_kredytowy
    }
}

# Klasa zarządzająca bankiem
klasa Bank {
    funkcja konstruktor(nazwa) {
        niech @nazwa = nazwa
        niech @konta = {}
        niech @nastepny_id = 1
    }
    
    funkcja utworz_konto_oszczednosciowe(wlasciciel, stopa_procentowa, saldo_poczatkowe = 0) {
        niech numer = generuj_numer_konta()
        niech konto = KontoOszczednosciowe.nowy(numer, wlasciciel, stopa_procentowa, saldo_poczatkowe)
        dodaj_konto(konto)
        zwroc numer
    }
    
    funkcja utworz_konto_kredytowe(wlasciciel, limit_kredytowy, oprocentowanie, saldo_poczatkowe = 0) {
        niech numer = generuj_numer_konta()
        niech konto = KontoKredytowe.nowy(numer, wlasciciel, limit_kredytowy, oprocentowanie, saldo_poczatkowe)
        dodaj_konto(konto)
        zwroc numer
    }
    
    funkcja pobierz_konto(numer) {
        jesli !@konta.ma_klucz(numer) {
            rzuc "Konto o podanym numerze nie istnieje"
        }
        zwroc @konta[numer]
    }
    
    funkcja lista_kont() {
        niech lista = []
        
        dla klucz w @konta.klucze() {
            niech konto = @konta[klucz]
            lista.dodaj(konto.pobierz_dane())
        }
        
        zwroc lista
    }
    
    funkcja wykonaj_przelew(z_konta, na_konto, kwota) {
        proba {
            niech konto_zrodlowe = pobierz_konto(z_konta)
            niech konto_docelowe = pobierz_konto(na_konto)
            
            konto_zrodlowe.wyplata(kwota)
            konto_docelowe.wplata(kwota)
            
            zwroc prawda
        } zlap (e) {
            pokazl "Błąd podczas przelewu: " + e['wiadomosc']
            zwroc falsz
        }
    }
    
    funkcja nalicz_odsetki_wszystkim() {
        dla klucz w @konta.klucze() {
            niech konto = @konta[klucz]

            pokazl konto
            
            jesli konto.pobierz_typ_konta() == "oszczędnościowe" {
                konto.nalicz_odsetki()
            } albojesli konto.pobierz_typ_konta() == "kredytowe" {
                konto.nalicz_odsetki_od_debetu()
            }
        }
    }
    
    prywatne
    
    funkcja generuj_numer_konta() {
        niech numer = "ACC" + @nastepny_id
        niech @nastepny_id = @nastepny_id + 1
        zwroc numer
    }
    
    funkcja dodaj_konto(konto) {
        @konta[konto.pobierz_dane()["numer"]] = konto
    }
}

# Przykład użycia systemu bankowego
funkcja uruchom_demo() {
    niech bankApp = Bank.nowy("AlexBank")
    
    pokazl "Witaj w systemie bankowym AlexBank!"
    pokazl "----------------------------------------"
    
    # Utworzenie kont
    niech konto1 = bankApp.utworz_konto_oszczednosciowe("Jan Kowalski", 2.5, 1000)
    niech konto2 = bankApp.utworz_konto_kredytowe("Anna Nowak", 5000, 10.0)
    
    pokazl "Utworzono konta:"
    pokazl bankApp.lista_kont()
    pokazl "----------------------------------------"
    
    # Operacje na kontach
    pokazl "Wpłata na konto kredytowe:"
    bankApp.pobierz_konto(konto2).wplata(500)
    pokazl bankApp.pobierz_konto(konto2).pobierz_dane()
    
    pokazl "Wypłata z konta oszczędnościowego:"
    bankApp.pobierz_konto(konto1).wyplata(200)
    pokazl bankApp.pobierz_konto(konto1).pobierz_dane()
    
    pokazl "Przelew między kontami:"
    bankApp.wykonaj_przelew(konto1, konto2, 300)
    pokazl "Konto 1 po przelewie:"
    pokazl bankApp.pobierz_konto(konto1).pobierz_dane()
    pokazl "Konto 2 po przelewie:"
    pokazl bankApp.pobierz_konto(konto2).pobierz_dane()
    pokazl "----------------------------------------"
    
    # Naliczanie odsetek
    pokazl "Naliczanie odsetek:"
    bankApp.nalicz_odsetki_wszystkim()
    pokazl "Konto 1 po naliczeniu odsetek:"
    pokazl bankApp.pobierz_konto(konto1).pobierz_dane()
    
    # Historia operacji
    pokazl "Historia operacji konta 1:"
    pokazl bankApp.pobierz_konto(konto1).pobierz_historie()
}

# Uruchomienie demonstracji
uruchom_demo()