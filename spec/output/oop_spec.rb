require 'aruba/rspec'

RSpec.describe 'Object-Oriented Programming', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Basic class definition' do
    it 'defines an empty class' do
      code = '
        klasa Pusty {}
        pokazl "Klasa zdefiniowana"
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Klasa zdefiniowana')
    end

    it 'creates an instance of a class' do
      code = '
        klasa Przyklad {}
        niech obj = Przyklad.nowy()
        pokazl "Utworzono instancję"
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Utworzono instancję')
    end

    it 'defines class with instance variables' do
      code = '
        klasa Osoba {
          funkcja konstruktor(imie) {
            niech @imie = imie
          }
          
          funkcja przedstaw_sie() {
            zwroc "Nazywam się " + @imie
          }
        }
        
        niech osoba = Osoba.nowy("Jan")
        pokazl osoba.przedstaw_sie()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Nazywam się Jan')
    end
  end

  describe 'Constructors' do
    it 'initializes object with constructor without parameters' do
      code = '
        klasa Przyklad {
          funkcja konstruktor() {
            niech @wartosc = 42
          }
          
          funkcja pobierz() {
            zwroc @wartosc
          }
        }
        
        niech obj = Przyklad.nowy()
        pokazl obj.pobierz()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('42')
    end

    it 'initializes object with constructor with parameters' do
      code = '
        klasa Punkt {
          funkcja konstruktor(x, y) {
            niech @x = x
            niech @y = y
          }
          
          funkcja koordynaty() {
            zwroc "(" + @x + "," + @y + ")"
          }
        }
        
        niech punkt = Punkt.nowy(10, 20)
        pokazl punkt.koordynaty()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('(10,20)')
    end

    it 'uses default parameter values in constructor' do
      code = '
        klasa Konfiguracja {
          funkcja konstruktor(nazwa = "domyslna", wartosc = 100) {
            niech @nazwa = nazwa
            niech @wartosc = wartosc
          }
          
          funkcja opis() {
            zwroc @nazwa + ": " + @wartosc
          }
        }
        
        niech konfig1 = Konfiguracja.nowy()
        niech konfig2 = Konfiguracja.nowy("testowa")
        niech konfig3 = Konfiguracja.nowy("niestandardowa", 500)
        
        pokazl konfig1.opis()
        pokazl konfig2.opis()
        pokazl konfig3.opis()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("domyslna: 100\ntestowa: 100\nniestandardowa: 500")
    end
  end

  describe 'Instance methods' do
    it 'calls instance methods without parameters' do
      code = '
        klasa Kalkulator {
          funkcja konstruktor() {
            niech @wynik = 0
          }
          
          funkcja reset() {
            niech @wynik = 0
          }
          
          funkcja pobierz_wynik() {
            zwroc @wynik
          }
          
          funkcja dodaj_jeden() {
            niech @wynik = @wynik + 1
          }
        }
        
        niech kalk = Kalkulator.nowy()
        kalk.dodaj_jeden()
        kalk.dodaj_jeden()
        pokazl kalk.pobierz_wynik()
        kalk.reset()
        pokazl kalk.pobierz_wynik()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2\n0")
    end

    it 'calls instance methods with parameters' do
      code = '
        klasa Kalkulator {
          funkcja konstruktor() {
            niech @wynik = 0
          }
          
          funkcja dodaj(liczba) {
            niech @wynik = @wynik + liczba
          }
          
          funkcja pomnoz(liczba) {
            niech @wynik = @wynik * liczba
          }
          
          funkcja pobierz_wynik() {
            zwroc @wynik
          }
        }
        
        niech kalk = Kalkulator.nowy()
        kalk.dodaj(5)
        kalk.pomnoz(2)
        pokazl kalk.pobierz_wynik()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("10")
    end

    it 'returns values from methods' do
      code = '
        klasa Matematyka {
          funkcja konstruktor() {}
          
          funkcja kwadrat(x) {
            zwroc x * x
          }
          
          funkcja silnia(n) {
            jesli n <= 1 {
              zwroc 1
            }
            zwroc n * silnia(n-1)
          }
        }
        
        niech mat = Matematyka.nowy()
        pokazl mat.kwadrat(4)
        pokazl mat.silnia(5)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("16\n120")
    end

    it 'modifies instance variables via methods' do
      code = '
        klasa Osoba {
          funkcja konstruktor(imie, wiek) {
            niech @imie = imie
            niech @wiek = wiek
          }
          
          funkcja urodziny() {
            niech @wiek = @wiek + 1
          }
          
          funkcja zmien_imie(nowe_imie) {
            niech @imie = nowe_imie
          }
          
          funkcja opis() {
            zwroc @imie + " ma " + @wiek + " lat"
          }
        }
        
        niech osoba = Osoba.nowy("Jan", 30)
        pokazl osoba.opis()
        osoba.urodziny()
        osoba.zmien_imie("Adam")
        pokazl osoba.opis()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("Jan ma 30 lat\nAdam ma 31 lat")
    end

    it 'accesses instance variables directly' do
      code = '
        klasa Punkt {
          funkcja konstruktor(x, y) {
            niech @x = x
            niech @y = y
          }
          
          funkcja odleglosc() {
            zwroc (@x * @x + @y * @y) ** 0.5
          }
        }
        
        niech p = Punkt.nowy(3, 4)
        pokazl p.odleglosc()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("5.0")
    end
  end

  describe 'Private methods' do
    it 'defines and uses private methods within class' do
      code = '
        klasa Kalkulator {
          funkcja konstruktor() {}
          
          funkcja kwadrat_publiczny(x) {
            zwroc pomnoz(x, x)
          }
          
          funkcja szescian_publiczny(x) {
            zwroc pomnoz(x, pomnoz(x, x))
          }
          
          prywatne
          
          funkcja pomnoz(a, b) {
            zwroc a * b
          }
        }
        
        niech kalk = Kalkulator.nowy()
        pokazl kalk.kwadrat_publiczny(5)
        pokazl kalk.szescian_publiczny(3)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("25\n27")
    end

    it 'cannot call private methods from outside the class' do
      code = '
        klasa Kalkulator {
          funkcja konstruktor() {}
          
          prywatne
          
          funkcja pomnoz(a, b) {
            zwroc a * b
          }
        }
        
        niech kalk = Kalkulator.nowy()
        pokazl kalk.pomnoz(5, 4)
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Próba wywołania prywatnej metody pomnoz/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'implements private helper methods' do
      code = '
        klasa Walidator {
          funkcja konstruktor() {}
          
          funkcja sprawdz_haslo(haslo) {
            jesli jest_puste(haslo) {
              zwroc "Hasło nie może być puste"
            }
            jesli haslo.dlg() < 8 {
              zwroc "Hasło jest za krótkie"
            }
            zwroc "Hasło jest poprawne"
          }
          
          prywatne
          
          funkcja jest_puste(tekst) {
            zwroc tekst == ""
          }
          
          funkcja dlugosc(tekst) {
            niech licznik = 0
            dla element w tekst {
              licznik = licznik + 1
            }
            zwroc licznik
          }
        }
        
        niech val = Walidator.nowy()
        pokazl val.sprawdz_haslo("")
        pokazl val.sprawdz_haslo("abc")
        pokazl val.sprawdz_haslo("bezpieczne_haslo")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("Hasło nie może być puste\nHasło jest za krótkie\nHasło jest poprawne")
    end
  end

  describe 'Static methods and variables' do
    it 'defines and accesses static variables' do
      code = '
        klasa Matematyka {
          statyczna niech PI = 3.14159
          statyczna niech E = 2.71828
        }
        
        pokazl Matematyka.PI
        pokazl Matematyka.E
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("3.14159\n2.71828")
    end

    it 'defines and calls static methods' do
      code = '
        klasa Matematyka {
          statyczna funkcja kwadrat(x) {
            zwroc x * x
          }
          
          statyczna funkcja szescian(x) {
            zwroc x * x * x
          }
        }
        
        pokazl Matematyka.kwadrat(4)
        pokazl Matematyka.szescian(3)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("16\n27")
    end

    it 'uses static methods with more complex logic' do
      code = '
        klasa Matematyka {
          statyczna niech PI = 3.14159
          
          statyczna funkcja pole_kola(promien) {
            zwroc Matematyka.PI * Matematyka.kwadrat(promien)
          }
          
          statyczna funkcja objetosc_sfery(promien) {
            zwroc 4 / 3 * Matematyka.PI * Matematyka.szescian(promien)
          }
          
          statyczna funkcja kwadrat(x) {
            zwroc x * x
          }
          
          statyczna funkcja szescian(x) {
            zwroc x * x * x
          }
        }
        
        pokazl Matematyka.pole_kola(2)
        pokazl Matematyka.objetosc_sfery(3)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to include("12.56")
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to include("113.097")
    end

    it 'restricts keyword "statyczna" to class body only' do
      code = '
        statyczna niech ZMIENNA = 10
        pokazl ZMIENNA
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Słowo kluczowe 'statyczna' może być używane tylko w ciele klasy/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'combines static and instance methods' do
      code = '
        klasa Konwerter {
          statyczna niech STOPY_NA_METRY = 0.3048
          statyczna niech CALE_NA_CM = 2.54
          
          statyczna funkcja stopy_na_metry(stopy) {
            zwroc stopy * Konwerter.STOPY_NA_METRY
          }
          
          funkcja konstruktor(wartosc) {
            niech @wartosc = wartosc
          }
          
          funkcja przelicz_na_metry() {
            zwroc Konwerter.stopy_na_metry(@wartosc)
          }
        }
        
        pokazl Konwerter.stopy_na_metry(10)
        
        niech konw = Konwerter.nowy(5)
        pokazl konw.przelicz_na_metry()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("3.048\n1.524")
    end
  end

  describe 'Inheritance' do
    it 'implements simple inheritance' do
      code = '
        klasa Zwierze {          
          funkcja odglos() {
            zwroc "..."
          }
          
          funkcja przedstaw() {
            zwroc "Jestem " + @nazwa + " i robię " + odglos()
          }
        }
        
        klasa Pies < Zwierze {
          funkcja konstruktor(nazwa){
             niech @nazwa = nazwa
          }

          funkcja odglos() {
            zwroc "Hau hau!"
          }
        }
        
        klasa Kot < Zwierze {
          funkcja konstruktor(nazwa){
             niech @nazwa = nazwa
          }
            
          funkcja odglos() {
            zwroc "Miau!"
          }
        }
        
        niech pies = Pies.nowy("Burek")
        niech kot = Kot.nowy("Mruczek")
        
        pokazl pies.przedstaw()
        pokazl kot.przedstaw()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("Jestem Burek i robię Hau hau!\nJestem Mruczek i robię Miau!")
    end

    it 'calls parent constructor with super' do
      code = '
        klasa Pojazd {
          funkcja konstruktor(nazwa, predkosc) {
            niech @nazwa = nazwa
            niech @predkosc = predkosc
          }
          
          funkcja info() {
            zwroc @nazwa + " (prędkość: " + @predkosc + " km/h)"
          }
        }
        
        klasa Samochod < Pojazd {
          funkcja konstruktor(nazwa, predkosc, marka) {
            super(nazwa, predkosc)
            niech @marka = marka
          }
          
          funkcja info() {
            zwroc @marka + " " + super.info()
          }
        }
        
        niech auto = Samochod.nowy("Sportowy", 200, "Ferrari")
        pokazl auto.info()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("Ferrari Sportowy (prędkość: 200 km/h)")
    end

    it 'calls other parent methods with super' do
			code = 'klasa Rodzic{
					funkcja czy_dziala(){
						pokazl "dziala"
					}
				}

				klasa Dziecko < Rodzic{
					funkcja czy_dziala(){
						super()
					}
				}

				niech x = Dziecko.nowy()
				x.czy_dziala()'
				run_command_and_stop "ruby #{main_file_path} '#{code}'"
				expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("dziala")
    end 

    it 'overrides methods with parent methods accessibility via super' do
      code = '
        klasa Figura {
          funkcja konstruktor() {}
          
          funkcja pole() {
            zwroc 0
          }
          
          funkcja opis() {
            zwroc "Pole: " + pole()
          }
        }
        
        klasa Prostokat < Figura {
          funkcja konstruktor(a, b) {
            niech @a = a
            niech @b = b
          }
          
          funkcja pole() {
            zwroc @a * @b
          }
          
          funkcja opis() {
            zwroc "Prostokąt " + super.opis()
          }
        }
        
        klasa Kwadrat < Prostokat {
          funkcja konstruktor(a) {
            super(a, a)
          }
          
          funkcja opis() {
            zwroc "Kwadrat " + super.opis()
          }
        }
        
        niech prostokat = Prostokat.nowy(4, 5)
        niech kwadrat = Kwadrat.nowy(3)
        
        pokazl prostokat.opis()
        pokazl kwadrat.opis()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("Prostokąt Pole: 20\nKwadrat Prostokąt Pole: 9")
    end

    it 'inherits static methods and variables' do
      code = '
        klasa Matematyka {
          statyczna niech PI = 3.14159
          
          statyczna funkcja kwadrat(x) {
            zwroc x * x
          }
        }
        
        klasa Geometria < Matematyka {
          statyczna funkcja pole_kola(r) {
            zwroc Matematyka.PI * Matematyka.kwadrat(r)
          }
        }
        
        pokazl Matematyka.PI
        pokazl Matematyka.kwadrat(4)
        pokazl Geometria.PI
        pokazl Geometria.kwadrat(5)
        pokazl Geometria.pole_kola(3)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to include("3.14159")
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to include("16")
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to include("25")
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to include("28.27")
    end

    it 'inherits private methods that remain private' do
      code = '
        klasa Bazowa {
          funkcja metoda_publiczna() {
            zwroc metoda_prywatna() * 2
          }
          
          prywatne
          
          funkcja metoda_prywatna() {
            zwroc 42
          }
        }
        
        klasa Pochodna < Bazowa {
          funkcja inna_metoda() {
            zwroc metoda_prywatna() + 10
          }
        }
        
        niech obj = Pochodna.nowy()
        pokazl obj.metoda_publiczna()
        pokazl obj.inna_metoda()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("84\n52")
    end
  end

  describe 'Error cases' do
    it 'raises error for undefined method' do
      code = '
        klasa Test {
          funkcja konstruktor() {}
        }
        
        niech obj = Test.nowy()
        pokazl obj.nieistniejaca_metoda()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Nieznana metoda nieistniejaca_metoda/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'raises error for undefined class' do
      code = '
        niech obj = NieistniejacaKlasa.nowy()
        pokazl obj
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Nieznana klasa NieistniejacaKlasa/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'raises error when accessing instance variable outside class' do
      code = '
        klasa Osoba {
          funkcja konstruktor(imie) {
            niech @imie = imie
          }
        }
        
        niech osoba = Osoba.nowy("Jan")
        pokazl @imie
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Nie można użyć zmiennej instancji poza kontekstem instancji/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'prevents calling super outside class context' do
      code = '
        funkcja test() {
          super.metoda()
        }
        
        test()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Nie można użyć 'super' poza kontekstem instancji/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'prevents calling super.method in a class without parent' do
      code = '
        klasa BezRodzica {
          funkcja metoda() {
            super.metoda()
          }
        }
        
        niech obj = BezRodzica.nowy()
        obj.metoda()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Nie znaleziono metody metoda w klasie nadrzędnej/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'prevents abstract classes from being instanciated' do
        code = '
        abstrakcyjna klasa Figura {
            funkcja konstruktor() {
                # Konstruktor w klasie abstrakcyjnej
            }
            
            funkcja opis() {
                zwroc "Figura geometryczna"
            }
        }
        niech figura = Figura.nowy()  # Błąd: Nie można utworzyć instancji klasy abstrakcyjnej Figura
        '
        run_command "ruby #{main_file_path} '#{code}'"
        expect(last_command_started).to have_output(/Nie można utworzyć instancji klasy abstrakcyjnej Figura/)
        expect(last_command_started).to have_exit_status(1)
    end 
  end

  describe 'Instance methods arithmetic operations' do
    it 'allows reassigning an instance variable using itself in the expression' do
      code = <<~AS
        klasa Licznik {
          funkcja konstruktor() {
            niech @n = 0
          }

          funkcja dodaj(x) {
            @n = @n + x
            pokazl @n
          }
        }

        niech c = Licznik.nowy()
        c.dodaj(5)
        c.dodaj(3)
      AS

      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("5\n8")
    end

    it 'allows overwriting an instance variable with a plain value' do
      code = <<~AS
        klasa Box {
          funkcja konstruktor() {
            niech @v = "a"
          }

          funkcja ustaw(nowy) {
            @v = nowy
            pokazl @v
          }
        }

        niech b = Box.nowy()
        b.ustaw("b")
      AS

      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("b")
    end
  end 
end