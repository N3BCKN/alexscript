require 'aruba/rspec'

RSpec.describe 'Exceptions', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Tłumaczenie wyjątków Ruby' do
    it 'tłumaczy błąd dzielenia przez zero' do
      code = 'niech x = 10
              niech y = 0
              pokazl x / y'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Dzielenie przez zero/)
      expect(last_command_started).to have_output(/w linii 3/)
    end

    it 'tłumaczy błąd nieprawidłowego indeksu tablicy' do
      code = 'niech arr = [1, 2, 3]
              pokazl arr[5]'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Indeks poza zakresem/)
    end

    it 'tłumaczy błąd niezdefiniowanej zmiennej' do
      code = 'pokazl nieistniejaca_zmienna'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niezadeklarowany identyfikator/)
    end

    it 'tłumaczy błąd nieprawidłowej operacji na typie' do
      code = 'niech tekst = "abc"
              pokazl tekst - 5'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niewspierany operator - pomiedzy abc a 5 w linii 2/)
    end

    it 'tłumaczy błąd nieprawidłowego warunku w if' do
      code = 'jesli "to nie jest boolean" {
                pokazl "nie powinno się wykonać"
              }'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Warunek musi byc boolem lub "nic"/)
    end
  end

  describe 'Definiowanie własnych wyjątków' do
    it 'definiuje własny wyjątek' do
      code = 'klasa MojWyjatek < WyjatekPodstawowy {}
              rzuc MojWyjatek.nowy("Test własnego wyjątku")
              pokazl "To nie powinno się wykonać"'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Test własnego wyjątku/)
    end

    it 'definiuje wyjątek dziedziczący po innym' do
      code = 'klasa MojWyjatek < WyjatekPodstawowy {}
              klasa MojWyjatek1 < MojWyjatek {}
              rzuc MojWyjatek1.nowy("Test dziedziczenia wyjątków")'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Test dziedziczenia wyjątków/)
    end
  end

  describe 'Rzucanie wyjątków' do
    it 'rzuca prosty wyjątek z wiadomością' do
      code = 'rzuc "Prosty komunikat o błędzie"
              pokazl "To nie powinno się wykonać"'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Prosty komunikat o błędzie/)
    end

    it 'rzuca wyjątek określonego typu' do
      code = 'klasa BladAplikacji < WyjatekPodstawowy {}
              rzuc BladAplikacji.nowy("Błąd aplikacji")'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Błąd aplikacji/)
    end

    it 'rzuca wyjątek z funkcji' do
      code = 'funkcja niebezpieczna() {
                rzuc "Niebezpieczna operacja"
              }
              niebezpieczna()'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niebezpieczna operacja/)
    end
  end

  describe 'Bloki try-catch-finally' do
    it 'łapie prosty wyjątek' do	
      code = 'proba {
                rzuc "Test łapania wyjątku"
              } zlap (e) {
                pokazl "Złapano: " + e["wiadomosc"]
              }'
			run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Złapano: Test łapania wyjątku/)
    end

    it 'łapie wyjątek określonego typu' do
      code = 'klasa BladA < WyjatekPodstawowy {}
              klasa BladB < WyjatekPodstawowy {}
              proba {
                rzuc BladB.nowy("Wyjątek typu B")
              } zlap (e : BladA) {
                pokazl "Złapano A: " + e["wiadomosc"]
              } zlap (e : BladB) {
                pokazl "Złapano B: " + e["wiadomosc"]
              }'
			run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Złapano B: Wyjątek typu B/)
    end

    it 'blok finally wykonuje się zawsze po try' do
      code = 'niech wykonane = falsz
              proba {
                pokazl "W bloku try"
              } wkoncu {
                pokazl "W bloku finally"
              }
              pokazl "Po bloku try-finally"'
			run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/W bloku try/)
			expect(last_command_started).to have_output(/W bloku finally/)
			expect(last_command_started).to have_output(/Po bloku try-finally/)
    end

    it 'blok finally wykonuje się zawsze po catch' do
      code = 'proba {
                rzuc "Test finally"
              } zlap (e) {
                pokazl "Złapano: " + e["wiadomosc"]
              } wkoncu {
                pokazl "W bloku finally"
              }'
			run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Złapano: Test finally/)
			expect(last_command_started).to have_output(/W bloku finally/)
    end

    it 'obsługuje zagnieżdżone bloki try-catch' do
      code = 'proba {
                pokazl "Zewnętrzny try"
                proba {
                  rzuc "Wewnętrzny wyjątek"
                } zlap (e) {
                  pokazl "Wewnętrzny catch: " + e["wiadomosc"] 
                  rzuc "Zewnętrzny wyjątek"
                }
              } zlap (e) {
                pokazl "Zewnętrzny catch: " + e["wiadomosc"] 
              }'

			run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Zewnętrzny try/)
			expect(last_command_started).to have_output(/Wewnętrzny catch: Wewnętrzny wyjątek/)
			expect(last_command_started).to have_output(/Zewnętrzny catch: Zewnętrzny wyjątek/)
    end
  end

  describe 'Złożone scenariusze wyjątków' do
    it 'łapie błędy dzielenia przez zero w funkcji' do
      code = 'funkcja podziel(a, b) {
                jesli b == 0 {
                  rzuc "Dzielenie przez zero!"
                }
                zwroc a / b
              }
              
              proba {
                pokazl podziel(10, 0)
              } zlap (e) {
                pokazl "Złapano błąd: " + e["wiadomosc"] 
              }'
			run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Złapano błąd: Dzielenie przez zero!/)
    end

    it 'obsługuje wyjątki w wyrażeniach' do
      code = 'funkcja moze_zawiesc() {
                rzuc "Operacja nie powiodła sie"
                zwroc 42
              }
              
              proba {
                niech x = 10 + moze_zawiesc()
                pokazl x
              } zlap (e) {
                pokazl "Nie udało się przypisać: " + e["wiadomosc"]
              }'
			run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Nie udało się przypisać: Operacja nie powiodła sie/)
    end

    it 'przekazuje informacje o linii błędu' do
      code = 'niech array = [1, 2, 3]
              # Linia poniżej spowoduje błąd
              pokazl array[10]'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/BladZakresu: Indeks poza zakresem/)
    end

    it 'tworzy hierarchię wyjątków i łapie odpowiednie typy' do
      code = 'klasa BladAplikacji < WyjatekPodstawowy {}
              klasa BladDanych < BladAplikacji {}
              klasa BladBazyDanych < BladDanych {}
              
              funkcja operacja_na_bazie() {
                rzuc BladBazyDanych.nowy("Błąd łączenia z bazą")
              }
              
              proba {
                operacja_na_bazie()
              } zlap (e : BladBazyDanych) {
                pokazl "Złapano błąd bazy: " + e["wiadomosc"]
              } zlap (e : BladAplikacji) {
                pokazl "Złapano błąd aplikacji: " + e["wiadomosc"] 
              } zlap (e) {
                pokazl "Złapano inny błąd: " + e["wiadomosc"]
              }'
			run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Złapano błąd bazy: Błąd łączenia z bazą/)
    end

    it 'obsługuje wiele powiązanych bloków catch' do
      code = 'klasa BladA < WyjatekPodstawowy {}
              klasa BladB < WyjatekPodstawowy {}
              klasa BladC < WyjatekPodstawowy {}
              
              funkcja test_wyjatku(typ) {
                jesli typ == "A" { rzuc BladA.nowy("Wyjątek A") }
                jesli typ == "B" { rzuc BladB.nowy("Wyjątek B") }
                jesli typ == "C" { rzuc BladC.nowy("Wyjątek C") }
                zwroc "OK"
              }
              
              funkcja uruchom_test(typ) {
                proba {
                  pokazl test_wyjatku(typ)
                } zlap (e : BladA) {
                  pokazl "A: " + e["wiadomosc"]
                } zlap (e : BladB) {
                  pokazl "B: " + e["wiadomosc"]
                } zlap (e) {
                  pokazl "Inny: " + e["wiadomosc"] 
                }
              }
              
              uruchom_test("A")
              uruchom_test("B")
              uruchom_test("C")'
			run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/A: Wyjątek A/)
			expect(last_command_started).to have_output(/B: Wyjątek B/)
			expect(last_command_started).to have_output(/Inny: Wyjątek C/)
    end

    it 'prawidłowo tłumaczy wiadomości o błędach rekurencji' do
      code = 'funkcja nieskonczona_rekurencja() {
                nieskonczona_rekurencja()
              }
              nieskonczona_rekurencja()'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/zbyt glebokie zagniezdzenie stosu/)
    end
  end
end
