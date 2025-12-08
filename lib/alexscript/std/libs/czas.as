# lib/std/libs/czas.as
require_ruby("time")

klasa Czas {
  niech @czas = nic
    
    # Konstruktor
    funkcja konstruktor(rok = nic, miesiac = nic, dzien = nic, godzina = 0, minuta = 0, sekunda = 0) {
      jesli rok == nic {
        # Aktualny czas
        niech @czas = ruby("Time", "now")
      } albo {
        # Tworzenie z podanymi parametrami
        niech @czas = ruby("Time", "new", rok, miesiac, dzien, godzina, minuta, sekunda)
      }
    }
    
    # Pobieranie aktualnej daty i czasu
    statyczny funkcja teraz() {
			niech czas = Czas.nowy()
			zwroc czas.do_tekstu()
    }
    
    # Tworzenie z timestampu Unix
    statyczny funkcja z_timestampu(timestamp) {
      niech czas = Czas.nowy()
      czas.ustaw_czas(ruby("Time", "at", timestamp))
      zwroc czas
    }
    
    # Parsowanie daty z formatu ISO
    statyczny funkcja parsuj(data_string) {
      niech czas = Czas.nowy()
      czas.ustaw_czas(ruby("Time", "parse", data_string))
      zwroc czas
    }
    
    # Ustaw wewnętrzny czas (metoda pomocnicza)
    funkcja ustaw_czas(czas_ruby) {
      niech @czas = czas_ruby
      zwroc prawda
    }
    
    # Gettery - używają ruby_obj zamiast ruby
    funkcja rok() {
      zwroc ruby_obj(@czas, "year")
    }
    
    funkcja miesiac() {
      zwroc ruby_obj(@czas, "month")
    }
    
    funkcja dzien() {
      zwroc ruby_obj(@czas, "day")
    }
    
    funkcja godzina() {
      zwroc ruby_obj(@czas, "hour")
    }
    
    funkcja minuta() {
      zwroc ruby_obj(@czas, "min")
    }
    
    funkcja sekunda() {
      zwroc ruby_obj(@czas, "sec")
    }
    
    funkcja milisekunda() {
      zwroc ruby_obj(@czas, "subsec") * 1000
    }
    
    funkcja dzien_tygodnia() {
      zwroc ruby_obj(@czas, "wday")
    }
    
    funkcja dzien_roku() {
      zwroc ruby_obj(@czas, "yday")
    }
    
    funkcja strefa_czasowa() {
      zwroc ruby_obj(@czas, "zone")
    }
    
    funkcja czas_letni() {
      zwroc ruby_obj(@czas, "dst?")
    }
    
    funkcja timestamp() {
      zwroc ruby_obj(@czas, "to_i")
    }
    
    # Nazwy dni i miesięcy
    funkcja nazwa_dnia_tygodnia() {
      niech indeks = dzien_tygodnia()
			niech dni = ["niedziela", "poniedziałek", "wtorek", "środa", "czwartek", "piątek", "sobota"]
      zwroc dni[indeks]
    }
    
    funkcja nazwa_miesiaca() {
      niech indeks = miesiac() - 1  # Indeksowanie od 0
			miesiace = ["styczeń", "luty", "marzec", "kwiecień", "maj", "czerwiec", "lipiec", "sierpień", "wrzesień", "październik", "listopad", "grudzień"]
      zwroc miesiace[indeks]
    }
    
    funkcja nazwa_miesiaca_dopelniacz() {
      niech indeks = miesiac() - 1  # Indeksowanie od 0
			niech miesiace = ["stycznia", "lutego", "marca", "kwietnia", "maja", "czerwca", "lipca", "sierpnia", "września", "października", "listopada", "grudnia"]
      zwroc miesiace[indeks]
    }
    
    # Formatowanie
    funkcja format(format_string = "%d.%m.%Y %H:%M:%S") {
      zwroc ruby_obj(@czas, "strftime", format_string)
    }
    
    funkcja do_tekstu() {
      niech dzien_tyg = nazwa_dnia_tygodnia()
      niech dzien_mies = dzien()
      niech mies_nazwa = nazwa_miesiaca_dopelniacz()
      niech rok_val = rok()
      niech godz = godzina()
      niech min = minuta()
      niech sek = sekunda()
        
      zwroc dzien_tyg + ", " + dzien_mies + " " + mies_nazwa + " " + rok_val + ", " + godz + ":" + min + ":" + sek
    }
    
    # Operacje - używają ruby_obj
    funkcja dodaj_sekundy(n) {
      niech nowy_czas = ruby_obj(@czas, "+", n)
      zwroc Czas.z_timestampu(ruby_obj(nowy_czas, "to_i"))
    }
    
    funkcja dodaj_minuty(n) {
      zwroc dodaj_sekundy(n * 60)
    }
    
    funkcja dodaj_godziny(n) {
      zwroc dodaj_minuty(n * 60)
    }
    
    funkcja dodaj_dni(n) {
      zwroc dodaj_godziny(n * 24)
    }
    
    funkcja dodaj_tygodnie(n) {
      zwroc dodaj_dni(n * 7)
    }
    
    # Porównania
    funkcja roznica(inny_czas) {
      niech inny_timestamp = inny_czas.timestamp()
      niech moj_timestamp = timestamp()
        
      zwroc moj_timestamp - inny_timestamp
    }
    
    funkcja po(inny_czas) {
      zwroc roznica(inny_czas) > 0
    }
    
    funkcja przed(inny_czas) {
      zwroc roznica(inny_czas) < 0
    }
    
    funkcja rowny(inny_czas) {
      zwroc roznica(inny_czas) == 0
    }
    
    # Przydatne funkcje
    statyczny funkcja uspij(sekundy) {
      ruby("Kernel", "sleep", sekundy)
      zwroc prawda
    }
    
    statyczny funkcja dzisiaj() {
      niech teraz = Czas.teraz()
      zwroc Czas.nowy(teraz.rok(), teraz.miesiac(), teraz.dzien(), 0, 0, 0)
    }
    
    statyczny funkcja wczoraj() {
      zwroc Czas.dzisiaj().dodaj_dni(-1)
    }
    
    statyczny funkcja jutro() {
      zwroc Czas.dzisiaj().dodaj_dni(1)
    }
}