# frozen_string_literal: true

require 'aruba/rspec'

RSpec.describe 'AlexScript sam (self-reference)', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'podstawowe użycie sam' do
    it 'sam zwraca instancję klasy' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja pobierz_sam() {
                zwroc sam
            }
        }
        
        niech t = Test.nowy()
        niech wynik = t.pobierz_sam()
        pokazl wynik.identyczny(t)
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'sam.klasa() zwraca nazwę klasy' do
      code = <<~ALEXSCRIPT
        klasa MojaKlasa {
            funkcja jaka_klasa() {
                zwroc sam.klasa()
            }
        }
        
        niech obj = MojaKlasa.nowy()
        pokazl obj.jaka_klasa()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('MojaKlasa')
    end

    it 'sam działa w konstruktorze' do
      code = <<~ALEXSCRIPT
        klasa TestKonstruktor {
            funkcja konstruktor() {
                niech @sam_w_konstruktorze = sam
            }
            
            funkcja sprawdz() {
                zwroc @sam_w_konstruktorze.identyczny(sam)
            }
        }
        
        niech t = TestKonstruktor.nowy()
        pokazl t.sprawdz()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'sam pozwala na dostęp do zmiennych instancji' do
      code = <<~ALEXSCRIPT
        klasa Osoba {
            funkcja konstruktor(imie) {
                niech @imie = imie
            }
            
            funkcja pobierz_przez_sam() {
                zwroc sam.wartosc_zmiennej_instancji("imie")
            }
        }
        
        niech osoba = Osoba.nowy("Jan")
        pokazl osoba.pobierz_przez_sam()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Jan')
    end
  end

  describe 'method chaining z sam' do
    it 'zwracanie sam umożliwia method chaining' do
      code = <<~ALEXSCRIPT
        klasa Builder {
            funkcja konstruktor() {
                niech @x = 0
                niech @y = 0
            }
            
            funkcja ustaw_x(val) {
                niech @x = val
                zwroc sam
            }
            
            funkcja ustaw_y(val) {
                niech @y = val
                zwroc sam
            }
            
            funkcja suma() {
                zwroc @x + @y
            }
        }
        
        niech wynik = Builder.nowy().ustaw_x(10).ustaw_y(20).suma()
        pokazl wynik
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('30')
    end

    it 'sam.metoda().inna_metoda() działa poprawnie' do
      code = <<~ALEXSCRIPT
        klasa Lancuch {
            funkcja konstruktor(wartosc) {
                niech @wartosc = wartosc
            }
            
            funkcja podwoj() {
                niech @wartosc = @wartosc * 2
                zwroc sam
            }
            
            funkcja dodaj(x) {
                niech @wartosc = @wartosc + x
                zwroc sam
            }
            
            funkcja pobierz() {
                zwroc @wartosc
            }
            
            funkcja test_sam_chaining() {
                zwroc sam.podwoj().dodaj(5).pobierz()
            }
        }
        
        niech l = Lancuch.nowy(10)
        pokazl l.test_sam_chaining()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('25')
    end

    it 'długi łańcuch z sam' do
      code = <<~ALEXSCRIPT
        klasa Licznik {
            funkcja konstruktor() {
                niech @val = 0
            }
            
            funkcja inc() {
                niech @val = @val + 1
                zwroc sam
            }
            
            funkcja val() {
                zwroc @val
            }
        }
        
        niech wynik = Licznik.nowy().inc().inc().inc().inc().inc().val()
        pokazl wynik
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('5')
    end
  end

  describe 'sam z dziedziczeniem' do
    it 'sam w klasie potomnej zwraca właściwą klasę' do
      code = <<~ALEXSCRIPT
        klasa Zwierze {
            funkcja jaki_typ() {
                zwroc sam.klasa()
            }
        }
        
        klasa Pies < Zwierze {
            funkcja konstruktor() {
                niech @gatunek = "pies"
            }
        }
        
        niech pies = Pies.nowy()
        pokazl pies.jaki_typ()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Pies')
    end

    it 'sam w metodzie nadpisanej' do
      code = <<~ALEXSCRIPT
        klasa A {
            funkcja test() {
                zwroc "A:" + sam.klasa()
            }
        }
        
        klasa B < A {
            funkcja test() {
                zwroc "B:" + sam.klasa()
            }
        }
        
        niech b = B.nowy()
        pokazl b.test()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('B:B')
    end

    it 'sam z super()' do
      code = <<~ALEXSCRIPT
        klasa Rodzic {
            funkcja konstruktor() {
                niech @typ = sam.klasa()
            }
            
            funkcja pobierz_typ() {
                zwroc @typ
            }
        }
        
        klasa Dziecko < Rodzic {
            funkcja konstruktor() {
                super()
            }
        }
        
        niech d = Dziecko.nowy()
        pokazl d.pobierz_typ()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Dziecko')
    end
  end

  describe 'sam przekazywany jako argument' do
    it 'przekazywanie sam do innej metody' do
      code = <<~ALEXSCRIPT
        klasa Visitor {
            funkcja odwiedz(element) {
                zwroc "Odwiedzono: " + element.klasa()
            }
        }
        
        klasa Element {
            funkcja akceptuj(visitor) {
                zwroc visitor.odwiedz(sam)
            }
        }
        
        niech elem = Element.nowy()
        niech vis = Visitor.nowy()
        pokazl elem.akceptuj(vis)
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Odwiedzono: Element')
    end
  end

  describe 'sam z modułami' do
    it 'sam w metodzie modułu dołączonej do klasy' do
      code = <<~ALEXSCRIPT
        modul Identyfikowalny {
            funkcja kim_jestem() {
                zwroc "Jestem instancją: " + sam.klasa()
            }
        }
        
        klasa Osoba {
            dolacz Identyfikowalny
            
            funkcja konstruktor() {
                niech @typ = "osoba"
            }
        }
        
        niech o = Osoba.nowy()
        pokazl o.kim_jestem()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Jestem instancją: Osoba')
    end

    it 'sam w modułach zagnieżdżonych' do
      code = <<~ALEXSCRIPT
        modul A {
            funkcja metoda_a() {
                zwroc sam.klasa() + ":A"
            }
        }
        
        modul B {
            funkcja metoda_b() {
                zwroc sam.klasa() + ":B"
            }
        }
        
        klasa Test {
            dolacz A
            dolacz B
        }
        
        niech t = Test.nowy()
        pokazl t.metoda_a()
        pokazl t.metoda_b()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("Test:A\nTest:B")
    end
  end

  describe 'sam z metodami wbudowanymi' do
    it 'sam.typ() zwraca "instancja"' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja jaki_typ() {
                zwroc sam.typ()
            }
        }
        
        niech t = Test.nowy()
        pokazl t.jaki_typ()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('instancja')
    end

    it 'sam.metody() zwraca listę metod' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja metoda1() {
                zwroc 1
            }
            
            funkcja metoda2() {
                zwroc 2
            }
            
            funkcja ile_metod() {
                zwroc sam.metody().dlg()
            }
        }
        
        niech t = Test.nowy()
        pokazl t.ile_metod() > 0
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'sam.czy_instancja() sprawdza przynależność' do
      code = <<~ALEXSCRIPT
        klasa Rodzic {}
        klasa Dziecko < Rodzic {
            funkcja test() {
                zwroc sam.czy_instancja("Rodzic")
            }
        }
        
        niech d = Dziecko.nowy()
        pokazl d.test()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'sam.zmienne_instancji() zwraca nazwy zmiennych' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja konstruktor() {
                niech @x = 1
                niech @y = 2
                niech @z = 3
            }
            
            funkcja ile_zmiennych() {
                zwroc sam.zmienne_instancji().dlg()
            }
        }
        
        niech t = Test.nowy()
        pokazl t.ile_zmiennych()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('3')
    end

    it 'sam.napis() zwraca reprezentację tekstową' do
      code = <<~ALEXSCRIPT
        klasa MojaKlasa {
            funkcja jako_napis() {
                zwroc sam.napis()
            }
        }
        
        niech mk = MojaKlasa.nowy()
        pokazl mk.jako_napis()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to include('#<MojaKlasa:0x')
    end
  end

  describe 'sam w różnych kontekstach' do
    it 'porównanie sam z @zmienna' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja konstruktor() {
                niech @sam_ref = sam
            }
            
            funkcja sprawdz() {
                zwroc @sam_ref.identyczny(sam)
            }
        }
        
        niech t = Test.nowy()
        pokazl t.sprawdz()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end
  end

  describe 'wzorce projektowe z sam' do
    it 'Builder pattern z sam' do
      code = <<~ALEXSCRIPT
        klasa PizzaBuilder {
            funkcja konstruktor() {
                niech @rozmiar = "srednia"
                niech @ser = falsz
                niech @pieczarki = falsz
            }
            
            funkcja z_serem() {
                niech @ser = prawda
                zwroc sam
            }
            
            funkcja z_pieczarkami() {
                niech @pieczarki = prawda
                zwroc sam
            }
            
            funkcja duza() {
                niech @rozmiar = "duza"
                zwroc sam
            }
            
            funkcja zbuduj() {
                niech liczba = 0
                jesli @ser {
                    liczba = liczba + 1     # ← POPRAWKA: bez 'niech'
                }
                jesli @pieczarki {
                    liczba = liczba + 1     # ← POPRAWKA: bez 'niech'
                }
                zwroc @rozmiar + ":" + liczba
            }
        }
        
        niech pizza = PizzaBuilder.nowy().duza().z_serem().z_pieczarkami().zbuduj()
        pokazl pizza
      ALEXSCRIPT
      
      run_command("ruby #{main_file_path} '#{code}'")
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('duza:2')
    end
  end

  describe 'edge cases i błędy' do
    it 'błąd przy użyciu sam w kontekście globalnym' do
      code = <<~ALEXSCRIPT
        proba {
            pokazl sam
        } zlap (e) {
            pokazl "Blad: " + e["wiadomosc"]
        }
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to include('Nie można użyć')
    end

    it 'błąd składni przy przypisaniu do sam z niech' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja metoda() {
                niech sam = 42
            }
        }
      ALEXSCRIPT
      
      run_command("alexscript '#{code}'")
      expect(last_command_started).to have_output(/BladSkladni: Nie można przypisać wartości do słowa kluczowego 'sam' w linii 3/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'błąd przy bezpośrednim przypisaniu sam = wartość' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja metoda() {
                sam = 42
            }
        }
      ALEXSCRIPT
      
      run_command("alexscript '#{code}'")
      expect(last_command_started).to have_output(/BladSkladni: Nie można przypisać wartości do słowa kluczowego 'sam' w linii 3/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'sam z pustą klasą' do
      code = <<~ALEXSCRIPT
        klasa PustaKlasa {
            funkcja konstruktor() {
                pokazl sam.klasa()
            }
        }
        
        PustaKlasa.nowy()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('PustaKlasa')
    end

    it 'wielokrotne zwracanie sam' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja raz() {
                zwroc sam
            }
            
            funkcja dwa() {
                zwroc sam.raz()
            }
            
            funkcja trzy() {
                zwroc sam.dwa()
            }
        }
        
        niech t = Test.nowy()
        pokazl t.trzy().identyczny(t)
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end
  end

  describe 'sam z operatorami' do
    it 'sam w operacji konkatenacji stringów' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja jako_tekst() {
                zwroc "Klasa: " + sam.klasa()
            }
        }
        
        niech t = Test.nowy()
        pokazl t.jako_tekst()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Klasa: Test')
    end

    it 'sam w porównaniach' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja czy_to_ja(inny) {
                zwroc sam.identyczny(inny)
            }
        }
        
        niech t1 = Test.nowy()
        niech t2 = Test.nowy()
        pokazl t1.czy_to_ja(t1)
        pokazl t1.czy_to_ja(t2)
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nfalsz")
    end
  end

  describe 'sam z rekurencją' do
    it 'rekurencyjne wywołanie z sam' do
      code = <<~ALEXSCRIPT
        klasa Silnia {
            funkcja licz(n) {
                jesli n <= 1 {
                    zwroc 1
                }
                zwroc n * sam.licz(n - 1)
            }
        }
        
        niech s = Silnia.nowy()
        pokazl s.licz(5)
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('120')
    end
  end

  describe 'sam z różnymi typami zwracanymi' do
    it 'sam.klasa() zwraca string' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja test() {
                zwroc sam.klasa().typ()
            }
        }
        
        niech t = Test.nowy()
        pokazl t.test()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('napis')
    end

    it 'sam.metody() zwraca tablicę' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja test() {
                zwroc sam.metody().typ()
            }
        }
        
        niech t = Test.nowy()
        pokazl t.test()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('tablica')
    end

    it 'sam.identyczny() zwraca boolean' do
      code = <<~ALEXSCRIPT
        klasa Test {
            funkcja test() {
                zwroc sam.identyczny(sam).typ()
            }
        }
        
        niech t = Test.nowy()
        pokazl t.test()
      ALEXSCRIPT
      
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('logiczna')
    end
  end
end