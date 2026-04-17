require 'aruba/rspec'

RSpec.describe 'Reflection Methods', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  # ========================================
  # TESTY DLA METOD KLAS
  # ========================================

  describe 'Class reflection methods' do
    describe 'Basic information methods' do
      it 'returns class name with nazwa()' do
        code = '
          klasa MojaKlasa {}
          pokazl MojaKlasa.nazwa()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('MojaKlasa')
      end

      it 'returns "klasa" for typ()' do
        code = '
          klasa Test {}
          pokazl Test.typ()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('klasa')
      end

      it 'returns parent class name with rodzic()' do
        code = '
          klasa Zwierze {}
          klasa Pies < Zwierze {}
          pokazl Pies.rodzic()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Zwierze')
      end

      it 'returns "nic" for rodzic() when no parent' do
        code = '
          klasa Bazowa {}
          pokazl Bazowa.rodzic()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
      end

      it 'returns prawda for abstrakcyjna() on abstract class' do
        code = '
          abstrakcyjna klasa Figura {}
          pokazl Figura.czy_abstrakcyjna()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns falsz for czy_abstrakcyjna() on regular class' do
        code = '
          klasa Kolo {}
          pokazl Kolo.czy_abstrakcyjna()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
      end

      it 'returns unique id for each class' do
        code = '
          klasa A {}
          klasa B {}
          niech id_a = A.id()
          niech id_b = B.id()
          pokazl id_a == id_b
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
      end

      it 'returns consistent id for same class' do
        code = '
          klasa Test {}
          niech id1 = Test.id()
          niech id2 = Test.id()
          pokazl id1 == id2
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end
    end

    describe 'Hierarchy methods' do
      it 'returns ancestors in correct order' do
        code = '
          klasa A {}
          klasa B < A {}
          klasa C < B {}
          pokazl C.przodkowie()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip).to include('B')
        expect(last_command_started.output.strip).to include('A')
      end

      it 'returns empty array for przodkowie() when no ancestors' do
        code = '
          klasa Bazowa {}
          pokazl Bazowa.przodkowie().dlg
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip).to eq('0')
      end

      it 'returns descendants with potomkowie()' do
        code = '
          klasa Zwierze {}
          klasa Pies < Zwierze {}
          klasa Labrador < Pies {}
          niech potomkowie = Zwierze.potomkowie()
          pokazl potomkowie.zawiera("Pies")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns prawda for czy_dziedziczy_po with direct parent' do
        code = '
          klasa A {}
          klasa B < A {}
          pokazl B.czy_dziedziczy_po("A")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns prawda for czy_dziedziczy_po with indirect ancestor' do
        code = '
          klasa A {}
          klasa B < A {}
          klasa C < B {}
          pokazl C.czy_dziedziczy_po("A")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns falsz for czy_dziedziczy_po with unrelated class' do
        code = '
          klasa A {}
          klasa B {}
          pokazl B.czy_dziedziczy_po("A")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
      end
    end

    describe 'Instance methods introspection' do
      it 'returns own public methods with metody(prawda)' do
        code = '
          klasa Test {
            funkcja metoda1() {}
            funkcja metoda2() {}
          }
          pokazl Test.metody(prawda).dlg
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.to_i).to be >= 2
      end

      it 'returns all methods including inherited with metody()' do
        code = '
          klasa Bazowa {
            funkcja metoda_bazowa() {}
          }
          klasa Pochodna < Bazowa {
            funkcja metoda_pochodna() {}
          }
          niech metody = Pochodna.metody()
          pokazl metody.zawiera("metoda_bazowa") i metody.zawiera("metoda_pochodna")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns private methods with metody_prywatne()' do
        code = '
          klasa Test {
            funkcja publiczna() {}
            
            prywatne
            funkcja prywatna() {}
          }
          pokazl Test.metody_prywatne().zawiera("prywatna")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'does not include private methods in metody()' do
        code = '
          klasa Test {
            funkcja publiczna() {}
            
            prywatne
            funkcja prywatna() {}
          }
          pokazl Test.metody().zawiera("prywatna")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
      end

      it 'returns prawda for ma_metode() when method exists' do
        code = '
          klasa Test {
            funkcja moja_metoda() {}
          }
          pokazl Test.ma_metode("moja_metoda")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns falsz for ma_metode() when method does not exist' do
        code = '
          klasa Test {}
          pokazl Test.ma_metode("nieistniejaca")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
      end

      it 'finds inherited methods with ma_metode()' do
        code = '
          klasa Bazowa {
            funkcja metoda_bazowa() {}
          }
          klasa Pochodna < Bazowa {}
          pokazl Pochodna.ma_metode("metoda_bazowa")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end
    end

    describe 'Static methods introspection' do
      it 'returns static methods with metody_statyczne()' do
        code = '
          klasa Test {
            statyczna funkcja metoda_statyczna() {}
          }
          pokazl Test.metody_statyczne().zawiera("metoda_statyczna")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'includes inherited static methods' do
        code = '
          klasa Bazowa {
            statyczna funkcja statyczna_bazowa() {}
          }
          klasa Pochodna < Bazowa {
            statyczna funkcja statyczna_pochodna() {}
          }
          niech metody = Pochodna.metody_statyczne()
          pokazl metody.zawiera("statyczna_bazowa")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns prawda for ma_metode_statyczna() when exists' do
        code = '
          klasa Test {
            statyczna funkcja test() {}
          }
          pokazl Test.ma_metode_statyczna("test")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns static variables with zmienne_statyczne()' do
        code = '
          klasa Test {
            statyczna niech STALA = 10
          }
          pokazl Test.zmienne_statyczne().zawiera("STALA")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'includes inherited static variables' do
        code = '
          klasa Bazowa {
            statyczna niech BAZOWA_STALA = 5
          }
          klasa Pochodna < Bazowa {
            statyczna niech POCHODNA_STALA = 10
          }
          pokazl Pochodna.zmienne_statyczne().zawiera("BAZOWA_STALA")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns prawda for ma_zmienna_statyczna() when exists' do
        code = '
          klasa Test {
            statyczna niech VAR = 5
          }
          pokazl Test.ma_zmienna_statyczna("VAR")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end
    end

    describe 'Method details' do
      it 'returns method info with info_metody()' do
        code = '
          klasa Test {
            funkcja metoda(a, b) {}
          }
          niech info = Test.info_metody("metoda")
          pokazl info["nazwa"]
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('metoda')
      end

      it 'returns parameter count in info_metody()' do
        code = '
          klasa Test {
            funkcja metoda(a, b, c) {}
          }
          niech info = Test.info_metody("metoda")
          pokazl info["parametry"]
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.to_i).to eq(3)
      end

      it 'indicates private status in info_metody()' do
        code = '
          klasa Test {
            prywatne
            funkcja prywatna_metoda() {}
          }
          niech info = Test.info_metody("prywatna_metoda")
          pokazl info["prywatna"]
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns empty object for non-existent method' do
        code = '
          klasa Test {}
          niech info = Test.info_metody("nieistniejaca")
          pokazl info == {}
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end
    end

    describe 'String representation' do
      it 'returns simple class name for napis()' do
        code = '
          klasa Test {}
          pokazl Test.napis()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Test')
      end

      it 'includes parent in napis() for derived class' do
        code = '
          klasa Bazowa {}
          klasa Pochodna < Bazowa {}
          pokazl Pochodna.napis()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip).to include('<')
        expect(last_command_started.output.strip).to include('Bazowa')
      end

      it 'indicates abstract class in napis()' do
        code = '
          abstrakcyjna klasa Abstrakcyjna {}
          pokazl Abstrakcyjna.napis()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip).to include('abstrakcyjna')
      end
    end
  end

  # ========================================
  # TESTY DLA METOD INSTANCJI
  # ========================================

  describe 'Instance reflection methods' do
    describe 'Basic information' do
      it 'returns "instancja" for typ()' do
        code = '
          klasa Test {}
          niech obj = Test.nowy()
          pokazl obj.typ()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('instancja')
      end

      it 'returns class name with klasa()' do
        code = '
          klasa MojaKlasa {}
          niech obj = MojaKlasa.nowy()
          pokazl obj.klasa()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('MojaKlasa')
      end

      it 'returns unique id for each instance' do
        code = '
          klasa Test {}
          niech obj1 = Test.nowy()
          niech obj2 = Test.nowy()
          pokazl obj1.id() == obj2.id()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
      end

      it 'returns consistent id for same instance' do
        code = '
          klasa Test {}
          niech obj = Test.nowy()
          niech id1 = obj.id()
          niech id2 = obj.id()
          pokazl id1 == id2
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end
    end

    describe 'Type checking' do
      it 'returns prawda for czy_instancja with own class' do
        code = '
          klasa Test {}
          niech obj = Test.nowy()
          pokazl obj.czy_instancja("Test")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns prawda for czy_instancja with parent class' do
        code = '
          klasa Zwierze {}
          klasa Pies < Zwierze {}
          niech pies = Pies.nowy()
          pokazl pies.czy_instancja("Zwierze")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns falsz for czy_instancja with unrelated class' do
        code = '
          klasa A {}
          klasa B {}
          niech obj = A.nowy()
          pokazl obj.czy_instancja("B")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
      end
    end

    describe 'Hierarchy methods' do
      it 'returns ancestors with przodkowie()' do
        code = '
          klasa A {}
          klasa B < A {}
          klasa C < B {}
          niech obj = C.nowy()
          pokazl obj.przodkowie()
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip).to include('B')
        expect(last_command_started.output.strip).to include('A')
      end

      it 'returns full hierarchy with hierarchia()' do
        code = '
          klasa A {}
          klasa B < A {}
          niech obj = B.nowy()
          niech hier = obj.hierarchia()
          pokazl hier[0] == "B" i hier[1] == "A"
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns prawda for czy_dziedziczy_po with ancestor' do
        code = '
          klasa A {}
          klasa B < A {}
          niech obj = B.nowy()
          pokazl obj.czy_dziedziczy_po("A")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end
    end

    describe 'Methods introspection' do
      it 'returns available methods with metody()' do
        code = '
          klasa Test {
            funkcja moja_metoda() {}
          }
          niech obj = Test.nowy()
          pokazl obj.metody().zawiera("moja_metoda")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'includes inherited methods in metody()' do
        code = '
          klasa Bazowa {
            funkcja metoda_bazowa() {}
          }
          klasa Pochodna < Bazowa {
            funkcja metoda_pochodna() {}
          }
          niech obj = Pochodna.nowy()
          niech metody = obj.metody()
          pokazl metody.zawiera("metoda_bazowa") i metody.zawiera("metoda_pochodna")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns prawda for czy_odpowiada when method exists' do
        code = '
          klasa Test {
            funkcja test_metoda() {}
          }
          niech obj = Test.nowy()
          pokazl obj.czy_odpowiada("test_metoda")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns falsz for czy_odpowiada when method does not exist' do
        code = '
          klasa Test {}
          niech obj = Test.nowy()
          pokazl obj.czy_odpowiada("nieistniejaca")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
      end
    end

    describe 'Instance variables introspection' do
      it 'returns instance variables with zmienne_instancji()' do
        code = '
          klasa Osoba {
            funkcja konstruktor(imie, wiek) {
              niech @imie = imie
              niech @wiek = wiek
            }
          }
          niech osoba = Osoba.nowy("Jan", 25)
          niech zmienne = osoba.zmienne_instancji()
          pokazl zmienne.zawiera("imie") i zmienne.zawiera("wiek")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns prawda for ma_zmienna_instancji when exists' do
        code = '
          klasa Test {
            funkcja konstruktor() {
              niech @zmienna = 10
            }
          }
          niech obj = Test.nowy()
          pokazl obj.ma_zmienna_instancji("zmienna")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns falsz for ma_zmienna_instancji when does not exist' do
        code = '
          klasa Test {}
          niech obj = Test.nowy()
          pokazl obj.ma_zmienna_instancji("nieistniejaca")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
      end

      it 'returns variable value with wartosc_zmiennej_instancji()' do
        code = '
          klasa Test {
            funkcja konstruktor() {
              niech @x = 42
            }
          }
          niech obj = Test.nowy()
          pokazl obj.wartosc_zmiennej_instancji("x")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip).to eq('42')
      end

      it 'returns nic for non-existent variable value' do
        code = '
          klasa Test {}
          niech obj = Test.nowy()
          pokazl obj.wartosc_zmiennej_instancji("nieistniejaca")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
      end
    end

    describe 'Object operations' do
      it 'creates shallow copy with kopia()' do
        code = '
          klasa Test {
            funkcja konstruktor(x) {
              niech @x = x
            }
          }
          niech obj1 = Test.nowy(10)
          niech obj2 = obj1.kopia()
          pokazl obj2.wartosc_zmiennej_instancji("x")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip).to eq('10')
      end

      it 'returns prawda for identyczny with same reference' do
        code = '
          klasa Test {}
          niech obj1 = Test.nowy()
          niech obj2 = obj1
          pokazl obj1.identyczny(obj2)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'returns falsz for identyczny with different instances' do
        code = '
          klasa Test {}
          niech obj1 = Test.nowy()
          niech obj2 = Test.nowy()
          pokazl obj1.identyczny(obj2)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
      end

      it 'returns falsz for identyczny with copy' do
        code = '
          klasa Test {}
          niech obj1 = Test.nowy()
          niech obj2 = obj1.kopia()
          pokazl obj1.identyczny(obj2)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
      end
    end

    describe 'String representation' do
      it 'returns object representation with napis()' do
        code = '
          klasa Test {}
          niech obj = Test.nowy()
          niech repr = obj.napis()
          pokazl repr.zawiera("Test")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end

      it 'includes hex id in napis()' do
        code = '
          klasa Test {}
          niech obj = Test.nowy()
          pokazl obj.napis().zawiera("0x")
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
      end
    end

    describe 'Debug information' do
      it 'returns debug info object' do
        code = '
          klasa Test {
            funkcja konstruktor() {
              niech @x = 1
              niech @y = 2
            }
          }
          niech obj = Test.nowy()
          niech info = obj.debug_info()
          pokazl info["zmienne_count"]
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.to_i).to eq(2)
      end

      it 'includes class name in debug_info()' do
        code = '
          klasa MojaKlasa {}
          niech obj = MojaKlasa.nowy()
          niech info = obj.debug_info()
          pokazl info["klasa"]
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('MojaKlasa')
      end
    end
  end

  # ========================================
  # TESTY INTEGRACYJNE
  # ========================================

  describe 'Integration tests' do
    it 'works correctly with multi-level inheritance' do
      code = '
        klasa A {
          funkcja metoda_a() {}
        }
        klasa B < A {
          funkcja metoda_b() {}
        }
        klasa C < B {
          funkcja metoda_c() {}
        }
        
        niech obj = C.nowy()
        pokazl obj.hierarchia().dlg
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.to_i).to eq(3)
    end

    it 'reflection methods work with abstract classes' do
      code = '
        abstrakcyjna klasa Ksztalt {
          funkcja pole() {}
        }
        klasa Prostokat < Ksztalt {
          funkcja pole() { zwroc 10 }
        }
        
        pokazl Ksztalt.czy_abstrakcyjna()
        pokazl Prostokat.czy_dziedziczy_po("Ksztalt")
        pokazl Prostokat.ma_metode("pole")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      output = last_command_started.output.strip
      expect(output).to include('prawda')
    end

    it 'instance variables are tracked correctly through inheritance' do
      code = '
        klasa Zwierze {
          funkcja konstruktor(nazwa) {
            niech @nazwa = nazwa
          }
        }
        klasa Pies < Zwierze {
          funkcja konstruktor(nazwa, rasa) {
            super(nazwa)
            niech @rasa = rasa
          }
        }
        
        niech pies = Pies.nowy("Burek", "Owczarek")
        pokazl pies.zmienne_instancji().dlg
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.to_i).to eq(2)
    end

    it 'static methods and variables are inherited correctly' do
      code = '
        klasa Bazowa {
          statyczna niech STALA_BAZOWA = 10
          statyczna funkcja metoda_bazowa() { zwroc 1 }
        }
        klasa Pochodna < Bazowa {
          statyczna niech STALA_POCHODNA = 20
          statyczna funkcja metoda_pochodna() { zwroc 2 }
        }
        
        pokazl Pochodna.zmienne_statyczne().dlg
        pokazl Pochodna.metody_statyczne().dlg
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      output = last_command_started.output.strip.split("\n")
      expect(output[0].to_i).to eq(2) # 2 static variables
      expect(output[1].to_i).to eq(2) # 2 static methods
    end

    it 'private methods are visible in reflection but marked as private' do
      code = '
        klasa Test {
          funkcja publiczna() {}
          
          prywatne
          funkcja prywatna() {}
        }
        
        pokazl Test.metody().zawiera("prywatna")
        pokazl Test.metody_prywatne().zawiera("prywatna")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      output = last_command_started.output.strip.split("\n")
      expect(output[0].gsub(/[\\"]/, '')).to eq('falsz')
      expect(output[1].gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'reflection works with empty classes' do
      code = '
        klasa Pusta {}
        
        pokazl Pusta.metody().dlg
        pokazl Pusta.metody_statyczne().dlg
        pokazl Pusta.zmienne_statyczne().dlg
        pokazl Pusta.przodkowie().dlg
        
        niech obj = Pusta.nowy()
        pokazl obj.zmienne_instancji().dlg
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      output = last_command_started.output.strip.split("\n")
      output.each do |line|
        expect(line.to_i).to eq(0)
      end
    end

    it 'complex real-world scenario with full reflection usage' do
      code = '
        klasa Pojazd {
          funkcja konstruktor(nazwa) {
            niech @nazwa = nazwa
          }
          
          funkcja jedz() {}
        }
        
        klasa Samochod < Pojazd {
          funkcja konstruktor(nazwa, marka) {
            super(nazwa)
            niech @marka = marka
          }
          
          funkcja jedz() {}
          funkcja parkuj() {}
          
          statyczna niech KOLA = 4
          statyczna funkcja opis() { zwroc "Samochod" }
        }
        
        niech auto = Samochod.nowy("Civic", "Honda")
        
        pokazl auto.klasa()
        pokazl auto.czy_instancja("Pojazd")
        pokazl auto.zmienne_instancji().dlg
        pokazl auto.metody().zawiera("jedz")
        pokazl Samochod.zmienne_statyczne().zawiera("KOLA")
        pokazl Samochod.metody_statyczne().zawiera("opis")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      output = last_command_started.output.strip.split("\n")
      expect(output[0].gsub(/[\\"]/, '')).to eq('Samochod')
      expect(output[1].gsub(/[\\"]/, '')).to eq('prawda')
      expect(output[2].to_i).to eq(2) # @nazwa, @marka
      expect(output[3].gsub(/[\\"]/, '')).to eq('prawda')
      expect(output[4].gsub(/[\\"]/, '')).to eq('prawda')
      expect(output[5].gsub(/[\\"]/, '')).to eq('prawda')
    end
  end
end 