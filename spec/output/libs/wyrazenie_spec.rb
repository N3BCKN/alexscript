require 'aruba/rspec'

RSpec.describe 'Wyrazenie (wyrazenia regularne)', type: :aruba do
  let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', File.dirname(__FILE__)) }

  #  Konstrukcja 

  describe 'konstrukcja' do
    it 'tworzy wyrazenie bez flag' do
      code = 'niech k = Wyrazenie.nowy("hello")
              pokazl k.wzor()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('hello')
    end

    it 'tworzy wyrazenie z flagami' do
      code = 'niech k = Wyrazenie.nowy("abc", "im")
              pokazl k.flagi()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('im')
    end

    it 'serializuje wyrazenie przez do_tekstu' do
      code = 'niech k = Wyrazenie.nowy("[0-9]+", "i")
              pokazl k.do_tekstu()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('/[0-9]+/i')
    end

    it 'rzuca blad dla nieznanej flagi' do
      code = 'niech k = Wyrazenie.nowy("abc", "z")
              pokazl k.wzor()'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to match(/BladArgumentu/)
    end

    it 'rzuca blad dla nieprawidlowego wzoru' do
      code = 'niech k = Wyrazenie.nowy("[abc")
              pokazl k.wzor()'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to match(/BladArgumentu/)
    end
  end

  #  Dopasowanie 

  describe 'dopasuj' do
    it 'zwraca obiekt Dopasowanie przy trafieniu' do
      code = 'niech k = Wyrazenie.nowy("[0-9]+")
              niech d = k.dopasuj("mam 42 lat")
              pokazl d.tekst()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('42')
    end

    it 'zwraca nic przy braku trafienia' do
      code = 'niech k = Wyrazenie.nowy("[0-9]+")
              niech d = k.dopasuj("brak cyfr")
              pokazl d'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end

    it 'obsluguje flage ignorecase' do
      code = 'niech k = Wyrazenie.nowy("hello", "i")
              pokazl k.pasuje("HELLO world")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'zwraca indeksy poczatku i konca dopasowania' do
      code = 'niech k = Wyrazenie.nowy("[0-9]+")
              niech d = k.dopasuj("abc 42 xyz")
              pokazl d.indeks()
              pokazl d.indeks_konca()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("4\n6")
    end

    it 'zwraca tekst przed i po dopasowaniu' do
      code = 'niech k = Wyrazenie.nowy("[0-9]+")
              niech d = k.dopasuj("abc 42 xyz")
              pokazl d.przed()
              pokazl d.po()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("abc \n xyz")
    end
  end

  #  Grupy 

  describe 'grupy' do
    it 'udostepnia grupy po indeksie' do
      code = 'niech k = Wyrazenie.nowy("([a-z]+)=([0-9]+)")
              niech d = k.dopasuj("wiek=30")
              pokazl d.grupa(0)
              pokazl d.grupa(1)
              pokazl d.grupa(2)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("wiek=30\nwiek\n30")
    end

    it 'zwraca wszystkie grupy jako tablice' do
      code = 'niech k = Wyrazenie.nowy("([a-z]+)=([0-9]+)")
              niech d = k.dopasuj("wiek=30")
              niech g = d.grupy()
              pokazl g.dlg
              pokazl g[0]
              pokazl g[1]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2\nwiek\n30")
    end

    it 'obsluguje grupy nazwane' do
      code = 'niech k = Wyrazenie.nowy("(?<klucz>[a-z]+)=(?<wartosc>[0-9]+)")
              niech d = k.dopasuj("rok=2026")
              pokazl d.nazwana("klucz")
              pokazl d.nazwana("wartosc")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("rok\n2026")
    end

    it 'zwraca nic dla nieistniejacej grupy nazwanej' do
      code = 'niech k = Wyrazenie.nowy("(?<a>[0-9]+)")
              niech d = k.dopasuj("42")
              pokazl d.nazwana("b")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end
  end

  #  Wszystkie dopasowania 

  describe 'dopasuj_wszystkie' do
    it 'zwraca tablice wszystkich dopasowan' do
      code = 'niech k = Wyrazenie.nowy("[0-9]+")
              niech ds = k.dopasuj_wszystkie("ma 12 lat i 3 koty, razem 15")
              pokazl ds.dlg
              pokazl ds[0].tekst()
              pokazl ds[1].tekst()
              pokazl ds[2].tekst()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("3\n12\n3\n15")
    end

    it 'zwraca pusta tablice przy braku dopasowan' do
      code = 'niech k = Wyrazenie.nowy("[0-9]+")
              niech ds = k.dopasuj_wszystkie("brak cyfr")
              pokazl ds.dlg'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('0')
    end
  end

  #  Zamiany 

  describe 'zamien i zamien_wszystkie' do
    it 'zamienia pierwsze wystapienie' do
      code = 'niech k = Wyrazenie.nowy("[0-9]+")
              pokazl k.zamien("a1 b2 c3", "X")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('aX b2 c3')
    end

    it 'zamienia wszystkie wystapienia' do
      code = 'niech k = Wyrazenie.nowy("[0-9]+")
              pokazl k.zamien_wszystkie("a1 b22 c333", "X")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('aX bX cX')
    end
  end

  # Podzial i skan 

  describe 'podziel i skanuj' do
    it 'dzieli tekst na czesci' do
      code = 'niech k = Wyrazenie.nowy("[,;]")
              niech czesci = k.podziel("a,b;c,d")
              pokazl czesci.dlg
              pokazl czesci[0]
              pokazl czesci[3]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("4\na\nd")
    end

    it 'respektuje limit w podziel' do
      code = 'niech k = Wyrazenie.nowy(",")
              niech czesci = k.podziel("a,b,c,d", 2)
              pokazl czesci.dlg
              pokazl czesci[1]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2\nb,c,d")
    end

    it 'skanuje i zwraca liste dopasowan' do
      code = 'niech k = Wyrazenie.nowy("[0-9]+")
              niech liczby = k.skanuj("aa 12 bb 345 cc 6")
              pokazl liczby.dlg
              pokazl liczby[0]
              pokazl liczby[2]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("3\n12\n6")
    end
  end

  #  Predykat i escapuj 

  describe 'pasuje i escapuj' do
    it 'pasuje zwraca prawda gdy dopasowanie istnieje' do
      code = 'niech k = Wyrazenie.nowy("^[a-z]+$")
              pokazl k.pasuje("abc")
              pokazl k.pasuje("Abc")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nfalsz")
    end

    it 'Wyrazenie.escapuj pozwala na literalne dopasowanie metaznakow' do
      # Funkcjonalny test round-trip: po escape pattern matchuje doslownie,
      # a nie dopasowuje sie do tekstu bez metaznakok.
      code = 'niech bezp = Wyrazenie.escapuj("1+2*3")
              niech k = Wyrazenie.nowy(bezp)
              pokazl k.pasuje("1+2*3")
              pokazl k.pasuje("1a2b3")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nfalsz")
    end
  end

  describe 'zamien z callbackiem' do
    it 'wywoluje callback na kazdym dopasowaniu' do
      code = 'niech re = Wyrazenie.nowy("[0-9]+")
          pokazl re.zamien_wszystkie("a1 b22 c333", fn(m) { m.tekst() + "!" })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('a1! b22! c333!')
    end

    it 'callback ma dostep do grup' do
      code = 'niech re = Wyrazenie.nowy("([a-z]+)=([0-9]+)")
          pokazl re.zamien_wszystkie("a=1, b=22", fn(m) { m.grupa(2) + ":" + m.grupa(1) })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('1:a, 22:b')
    end

    it 'zamien bez callbacku wykonuje tylko jedna zamiane' do
      code = 'niech re = Wyrazenie.nowy("[0-9]+")
          pokazl re.zamien("a1 b2", fn(m) { "X" })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('aX b2')
    end

    it 'callback moze zwrocic liczbe — konwertowana do stringa' do
      code = 'niech re = Wyrazenie.nowy("[a-z]+")
          pokazl re.zamien_wszystkie("foo bar", fn(m) { m.tekst().dlg })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('3 3')
    end

    it 'callback moze uzywac closure' do
      code = 'niech licznik = 0
        niech re = Wyrazenie.nowy("[0-9]+")
        niech wynik = re.zamien_wszystkie("a1 b2 c3", fn(m) {
          licznik = licznik + 1
          zwroc "[" + licznik.napis() + "]"
        })
        pokazl wynik
        pokazl licznik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("a[1] b[2] c[3]\n3")
    end
  end

  describe 'metody polimorficzne na stringach' do
    it 'str.pasuje(Wyrazenie) zwraca bool' do
      code = 'niech re = Wyrazenie.nowy("^[0-9]+$")
          pokazl "123".pasuje(re)
          pokazl "abc".pasuje(re)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nfalsz")
    end

    it 'str.dopasuj(Wyrazenie) zwraca Dopasowanie przy trafieniu' do
      code = 'niech re = Wyrazenie.nowy("[0-9]+")
          niech dop = "mam 42 lata".dopasuj(re)
          pokazl dop.tekst()
          pokazl dop.indeks()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("42\n4")
    end

    it 'str.dopasuj zwraca nic przy braku trafienia' do
      code = 'niech re = Wyrazenie.nowy("[0-9]+")
            niech dop = "bez cyfr".dopasuj(re)
            pokazl dop'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end

    it 'str.rozdziel akceptuje Wyrazenie jako separator' do
      code = 'niech re = Wyrazenie.nowy("[,;]\\s*")
              niech czesci = "a, b;c,d".rozdziel(re)
              pokazl czesci.dlg
              pokazl czesci[0]
              pokazl czesci[3]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("4\na\nd")
    end

    it 'str.rozdziel(string) nadal dziala po staremu' do
      code = 'niech czesci = "a-b-c".rozdziel("-")
              pokazl czesci.dlg
              pokazl czesci[1]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("3\nb")
    end

    it 'str.pasuje rzuca BladArgumentu dla stringa zamiast Wyrazenia' do
      code = 'pokazl "abc".pasuje("nie-regex")'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to match(/BladArgumentu/)
    end

    it 'str.dopasuj obsluguje grupy' do
      code = 'niech re = Wyrazenie.nowy("(?<klucz>[a-z]+)=(?<war>[0-9]+)")
              niech dop = "rok=2026".dopasuj(re)
              pokazl dop.nazwana("klucz")
              pokazl dop.nazwana("war")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("rok\n2026")
    end
  end
end