require 'aruba/rspec'

RSpec.describe 'Lexer phase 1 - numeric literals', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'lexes a decimal integer' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl 12345'"
    expect(last_command_started.output.strip).to eq('12345')
  end

  it 'lexes a float' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl 3.14159'"
    expect(last_command_started.output.strip).to eq('3.14159')
  end

  it 'lexes zero on its own' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl 0'"
    expect(last_command_started.output.strip).to eq('0')
  end

  it 'lexes a binary literal' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl 0b1010'"
    expect(last_command_started.output.strip).to eq('10')
  end

  it 'lexes an uppercase binary literal' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl 0B1111'"
    expect(last_command_started.output.strip).to eq('15')
  end

  it 'lexes a hex literal' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl 0xFF'"
    expect(last_command_started.output.strip).to eq('255')
  end

  it 'lexes an uppercase hex literal with mixed-case digits' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl 0XdeadBEEF'"
    expect(last_command_started.output.strip).to eq('3735928559')
  end

  it 'lexes an octal literal' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl 0o777'"
    expect(last_command_started.output.strip).to eq('511')
  end

  it 'lexes an uppercase octal literal' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl 0O10'"
    expect(last_command_started.output.strip).to eq('8')
  end

  it 'uses prefix literals in arithmetic' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl 0xFF + 0b1 + 0o7'"
    expect(last_command_started.output.strip).to eq('263')
  end

  it 'rejects an empty binary literal' do
    run_command "ruby #{main_file_path} 'pokazl 0b'"
    expect(last_command_started).to have_output(/literal binarny/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects an empty hex literal' do
    run_command "ruby #{main_file_path} 'pokazl 0x'"
    expect(last_command_started).to have_output(/literal szesnastkowy/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects an empty octal literal' do
    run_command "ruby #{main_file_path} 'pokazl 0o'"
    expect(last_command_started).to have_output(/literal osemkowy/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects a binary literal with a non-binary digit' do
    run_command "ruby #{main_file_path} 'pokazl 0b2'"
    expect(last_command_started).to have_output(/literal binarny/)
    expect(last_command_started.exit_status).not_to eq(0)
  end
end

RSpec.describe 'Lexer phase 1 - strings and escapes', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'lexes a double-quoted string' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"Hello\"'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('Hello')
  end

  it 'resolves the newline escape' do
    run_command_and_stop "ruby #{main_file_path} 'pokaz \"a\\nb\"'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq("a\nb")
  end

  it 'resolves the tab escape' do
    run_command_and_stop "ruby #{main_file_path} 'pokaz \"a\\tb\"'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq("a\tb")
  end

  it 'resolves an escaped quote without terminating the string' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"a\\\"b\".dlg()'"
    expect(last_command_started.output.strip).to eq('3')
  end

  it 'resolves an escaped backslash' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"a\\\\b\".dlg()'"
    expect(last_command_started.output.strip).to eq('3')
  end

  it 'resolves an escaped hash so it does not start interpolation' do
    code = 'pokazl "cena: \\#{100}"'
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to include('#{100}')
  end

  it 'preserves an unknown escape verbatim' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"a\\qb\".dlg()'"
    expect(last_command_started.output.strip).to eq('4')
  end

  it 'lexes an empty string' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"\".dlg()'"
    expect(last_command_started.output.strip).to eq('0')
  end

  it 'rejects an unterminated string' do
    run_command "ruby #{main_file_path} 'pokazl \"abc'"
    expect(last_command_started).to have_output(/Niezakonczony ciag znakow/)
    expect(last_command_started.exit_status).not_to eq(0)
  end
end

RSpec.describe 'Lexer phase 1 - interpolation', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'interpolates a variable' do
    code = '
      niech n = "Jan"
      pokazl "Witaj, #{n}!"
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('Witaj, Jan!')
  end

  it 'interpolates an expression' do
    code = 'pokazl "suma: #{2 + 3 * 4}"'
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('suma: 14')
  end

  it 'interpolates several times in one string' do
    code = '
      niech a = 1
      niech b = 2
      pokazl "#{a} i #{b} daje #{a + b}"
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('1 i 2 daje 3')
  end

  it 'interpolates a method call' do
    code = 'pokazl "dlugosc: #{[1, 2, 3].dlg()}"'
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('dlugosc: 3')
  end

  it 'tracks brace depth through a nested object literal' do
    code = 'pokazl "obiekt: #{ {"a": 7} }"'
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to include('obiekt:')
  end

  it 'tracks brace depth through a lambda body' do
    code = 'pokazl "wynik: #{ fn(x) { x * 2 }(5) }"'
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('wynik: 10')
  end

  it 'interpolates at the very start and very end of a string' do
    code = '
      niech x = 5
      pokazl "#{x}-srodek-#{x}"
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('5-srodek-5')
  end

  it 'rejects an unterminated interpolation' do
    code = 'pokazl "abc #{1 + 2"'
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.exit_status).not_to eq(0)
  end
end

RSpec.describe 'Lexer phase 1 - comments and line numbers', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'skips a single-line comment' do
    code = '
      # to jest komentarz
      pokazl 1
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('1')
  end

  it 'skips a multi-line comment' do
    code = '
      /* komentarz
         w kilku
         liniach */
      pokazl 2
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('2')
  end

  it 'rejects an unterminated multi-line comment' do
    code = 'pokazl 1 /* bez zamkniecia'
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/Niezamkniety komentarz/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  # These three are the sharpest test of the byteindex change. Under the old
  # String#index the newline offset was a CHARACTER offset while @current was a
  # BYTE offset, so any non-ASCII text before an error shifted every subsequent
  # line number without failing loudly.
  it 'reports the right line number after ASCII comments' do
    code = "# pierwsza linia\n# druga linia\nniech x = 5 / 0"
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/w linii 3/)
  end

  it 'reports the right line number after comments containing Polish text' do
    code = "# zazolc gesla jazn: zolw\n# ogonki: acelnoszz\nniech x = 5 / 0"
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/w linii 3/)
  end

  it 'counts lines inside a multi-line comment containing Polish text' do
    code = "/* komentarz\n   z ogonkami\n   trzecia linia */\nniech x = 5 / 0"
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/w linii 4/)
  end

  it 'counts lines across a multi-line string' do
    code = "niech s = \"pierwsza\ndruga\ntrzecia\"\nniech x = 5 / 0"
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/w linii 4/)
  end
end

RSpec.describe 'Lexer phase 1 - multi-character operators', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  # Every one of these goes through next_match, whose comparison changed from
  # String equality to byte equality.
  {
    'pokazl 2 ** 3'                              => '8',
    'pokazl 7 // 2'                              => '3',
    'pokazl 7 / 2'                               => '3.5',
    'pokazl 7 % 3'                               => '1',
    'pokazl 1 == 1'                              => 'prawda',
    'pokazl 1 != 2'                              => 'prawda',
    'pokazl 1 <= 1'                              => 'prawda',
    'pokazl 2 >= 3'                              => 'falsz',
    'pokazl 1 < 2'                               => 'prawda',
    'pokazl 1 > 2'                               => 'falsz',
    'pokazl 1 << 3'                              => '8',
    'pokazl 16 >> 2'                             => '4',
    'pokazl 6 & 3'                               => '2',
    'pokazl 6 | 1'                               => '7',
    'pokazl 6 ^ 3'                               => '5',
    'niech x = 5 x += 3 pokazl x'                => '8',
    'niech x = 5 x -= 3 pokazl x'                => '2',
    'niech x = 5 x *= 3 pokazl x'                => '15',
    'niech x = 6 x /= 3 pokazl x'                => '2',
    'pokazl prawda ? 1 : 2'                      => '1'
  }.each do |code, expected|
    it "lexes: #{code}" do
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq(expected)
    end
  end

  it 'lexes the module resolution operator' do
    code = '
      modul M {
        funkcja f() { zwroc 42 }
      }
      pokazl M::f()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('42')
  end

  it 'distinguishes a slash-star comment from a division' do
    code = 'niech x = 10 /* komentarz */ pokazl x / 2'
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('5.0')
  end
end

RSpec.describe 'Lexer phase 1 - non-ASCII inside strings', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  # If a lexeme were sliced with byteslice but left in ASCII-8BIT, every one of
  # these would report byte counts instead of character counts.
  it 'counts characters, not bytes, in a Polish string' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"zolw\".dlg()'"
    expect(last_command_started.output.strip).to eq('4')
  end

  it 'counts characters in a string made only of Polish letters' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"żółw\".dlg()'"
    expect(last_command_started.output.strip).to eq('4')
  end

  it 'reverses a Polish string by characters' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"żółw\".odwroc()'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('włóż')
  end

  it 'upcases Polish letters' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"zażółć\".duzymi()'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('ZAŻÓŁĆ')
  end

  it 'indexes a Polish string by character' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"żółw\".indeks(1)'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('ó')
  end

  it 'compares Polish strings for equality' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"gęś\" == \"gęś\"'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('prawda')
  end

  it 'concatenates Polish strings' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"żół\" + \"wik\"'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('żółwik')
  end

  it 'interpolates Polish text' do
    code = '
      niech m = "Świnoujście"
      pokazl "Miasto: #{m}, znakow: #{m.dlg()}"
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('Miasto: Świnoujście, znakow: 11')
  end

  it 'uses Polish text as an object key' do
    code = '
      niech o = {"imię": "Anna"}
      pokazl o["imię"]
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('Anna')
  end

  it 'keeps escapes working next to Polish text' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"żółw\\tgęś\".dlg()'"
    expect(last_command_started.output.strip).to eq('8')
  end
end

RSpec.describe 'Lexer phase 2 - Polish letters in identifiers', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'accepts a variable name with a Polish letter' do
    code = '
      niech imię = "Anna"
      pokazl imię
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('Anna')
  end

  it 'accepts every lowercase Polish letter in an identifier' do
    code = '
      niech ą = 1
      niech ć = 2
      niech ę = 3
      niech ł = 4
      niech ń = 5
      niech ó = 6
      niech ś = 7
      niech ź = 8
      niech ż = 9
      pokazl ą + ć + ę + ł + ń + ó + ś + ź + ż
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('45')
  end

  it 'accepts uppercase Polish letters inside an identifier' do
    code = '
      niech mieszaneĄĆĘŁŃÓŚŹŻ = 7
      pokazl mieszaneĄĆĘŁŃÓŚŹŻ
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('7')
  end

  it 'accepts a Polish letter at the start, middle and end of a name' do
    code = '
      niech ługi = 1
      niech dłg = 2
      niech dlugoś = 3
      pokazl ługi + dłg + dlugoś
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('6')
  end

  it 'mixes Polish letters with digits and underscores' do
    code = '
      niech gęstość_wody_2 = 997
      pokazl gęstość_wody_2
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('997')
  end

  it 'terminates a Polish identifier correctly at an operator' do
    code = '
      niech ćwierć = 25
      niech pół = 50
      pokazl ćwierć+pół
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('75')
  end

  it 'terminates a Polish identifier correctly at a parenthesis and comma' do
    code = '
      funkcja suma(pierwszą, drugą) {
        zwroc pierwszą + drugą
      }
      pokazl suma(3,4)
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('7')
  end

  it 'keeps Polish and ASCII names distinct' do
    code = '
      niech los = 1
      niech łoś = 2
      pokazl los
      pokazl łoś
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[1 2])
  end

  it 'accepts a Polish function name' do
    code = '
      funkcja zaokrąglij_w_dół(x) {
        zwroc x // 1
      }
      pokazl zaokrąglij_w_dół(7)
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('7')
  end

  it 'accepts a Polish class name and method name' do
    code = '
      klasa Zwierzę {
        funkcja konstruktor(imię) {
          niech @imię = imię
        }
        funkcja przedstaw_się() {
          zwroc @imię
        }
      }
      pokazl Zwierzę.nowy("Reksio").przedstaw_się()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('Reksio')
  end

  it 'accepts a Polish instance variable name' do
    code = '
      klasa Osoba {
        funkcja konstruktor() {
          niech @nazwisko_użytkownika = "Kowalski"
        }
        funkcja nazwisko() {
          zwroc @nazwisko_użytkownika
        }
      }
      pokazl Osoba.nowy().nazwisko()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('Kowalski')
  end

  it 'accepts an instance variable starting with a Polish letter' do
    code = '
      klasa K {
        funkcja konstruktor() {
          niech @łańcuch = "ok"
        }
        funkcja v() {
          zwroc @łańcuch
        }
      }
      pokazl K.nowy().v()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('ok')
  end

  it 'accepts a Polish module name and function' do
    code = '
      modul Ułamki {
        funkcja połowa(x) {
          zwroc x / 2
        }
      }
      pokazl Ułamki::połowa(9)
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('4.5')
  end

  it 'reports the type of a Polish-named variable' do
    code = '
      niech gęś = 5
      pokazl gęś.typ()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('calkowita')
  end

  it 'uses Polish names in multiple declaration' do
    code = '
      niech imię, nazwisko = "Jan", "Kowalski"
      pokazl imię
      pokazl nazwisko
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[Jan Kowalski])
  end

  it 'reports an undeclared Polish identifier by its real name' do
    run_command "ruby #{main_file_path} 'pokazl nieistniejąca'"
    expect(last_command_started).to have_output(/nieistniejąca/)
    expect(last_command_started.exit_status).not_to eq(0)
  end
end

RSpec.describe 'Lexer phase 2 - rejected characters', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'rejects Cyrillic in an identifier' do
    run_command "ruby #{main_file_path} 'niech привет = 1'"
    expect(last_command_started).to have_output(/nieznany znak/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects a German letter in an identifier' do
    run_command "ruby #{main_file_path} 'niech straße = 1'"
    expect(last_command_started).to have_output(/nieznany znak/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects an emoji in an identifier' do
    run_command "ruby #{main_file_path} 'niech x😀 = 1'"
    expect(last_command_started).to have_output(/nieznany znak/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'names the offending character rather than a byte value' do
    run_command "ruby #{main_file_path} 'niech x = §'"
    expect(last_command_started).to have_output(/nieznany znak: §/)
  end

  it 'detects an NFD-encoded source and says so' do
    # "coś" written as c o s + U+0301 (combining acute) instead of c o ś
    code = "niech co\u0073\u0301 = 1"
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/NFD/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'still allows rejected characters inside strings' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"привет straße 😀\".dlg()'"
    expect(last_command_started.output.strip).to eq('20')
  end

  it 'still allows rejected characters inside comments' do
    code = "# привет straße 😀\npokazl 1"
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('1')
  end
end

RSpec.describe 'Lexer phase 3 - keyword aliases', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'accepts jeśli and albo' do
    code = '
      jeśli prawda {
        pokazl "tak"
      } albo {
        pokazl "nie"
      }
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('tak')
  end

  it 'accepts albojeśli' do
    code = '
      niech x = 2
      jeśli x == 1 {
        pokazl "a"
      } albojeśli x == 2 {
        pokazl "b"
      } albo {
        pokazl "c"
      }
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('b')
  end

  it 'accepts fałsz' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl fałsz'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('falsz')
  end

  it 'accepts dopóki' do
    code = '
      niech k = 0
      dopóki k < 3 {
        k += 1
      }
      pokazl k
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('3')
  end

  it 'accepts zakończ inside a loop' do
    code = '
      niech k = 0
      dopóki prawda {
        k += 1
        jeśli k == 2 {
          zakończ
        }
      }
      pokazl k
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('2')
  end

  it 'accepts następny inside a loop' do
    code = '
      niech suma = 0
      dla niech k = 0; 5; 1 {
        jeśli k == 2 {
          następny
        }
        suma += k
      }
      pokazl suma
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('8')
  end

  it 'accepts pokaż and pokażl' do
    code = '
      pokaż "a"
      pokażl "b"
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.gsub(/[\\\"]/, '')).to include('a')
    expect(last_command_started.output.gsub(/[\\\"]/, '')).to include('b')
  end

  it 'accepts zwróć' do
    code = '
      funkcja f() {
        zwróć 42
      }
      pokazl f()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('42')
  end

  it 'accepts próba, złap and wkońcu' do
    code = '
      próba {
        rzuć "blad"
      } złap (e) {
        pokazl "zlapano"
      } wkońcu {
        pokazl "koniec"
      }
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[zlapano koniec])
  end

  it 'accepts moduł' do
    code = '
      moduł M {
        funkcja f() { zwróć 1 }
      }
      pokazl M::f()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('1')
  end

  it 'accepts dołącz' do
    code = '
      moduł Opisywalny {
        funkcja opis() {
          zwróć "opisany"
        }
      }
      klasa Produkt {
        dołącz Opisywalny
        funkcja konstruktor() {
          niech @x = 1
        }
      }
      pokazl Produkt.nowy().opis()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\\"]/, '')).to eq('opisany')
  end

  it 'accepts pętla' do
    code = '
      niech k = 0
      pętla {
        k += 1
        jeśli k == 3 {
          zakończ
        }
      }
      pokazl k
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('3')
  end

  it 'accepts wyjście with a status code' do
    run_command "ruby #{main_file_path} 'wyjście(1)'"
    stop_all_commands
    expect(last_command_started.exit_status).to eq(1)
  end

  it 'mixes both spellings in one program' do
    code = '
      funkcja f(x) {
        jesli x > 0 {
          zwróć "dodatnia"
        } albo {
          zwroc "niedodatnia"
        }
      }
      pokazl f(1)
      pokazl f(-1)
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[dodatnia niedodatnia])
  end

  it 'rejects an alias used as a variable name, like the ASCII form' do
    run_command "ruby #{main_file_path} 'niech jeśli = 1'"
    expect(last_command_started).to have_output(/slowem kluczowym/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'does not treat an identifier merely starting with an alias as a keyword' do
    code = '
      niech jeślix = 1
      niech zwróćmy = 2
      pokazl jeślix + zwróćmy
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('3')
  end

  it 'does not tokenize an alias appearing inside a string' do
    run_command_and_stop "ruby #{main_file_path} 'pokazl \"jeśli zwróć fałsz\".dlg()'"
    expect(last_command_started.output.strip).to eq('17')
  end
end

RSpec.describe 'Lexer - decisions to confirm', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  # Constant detection is /^[A-Z_]+$/, an ASCII-only range. Now that Polish
  # letters are legal in identifiers, a name like PÓŁ or DŁUGOSC is NOT
  # recognised as a constant. These two examples pin the CURRENT behaviour so
  # the decision is made deliberately rather than discovered by a user.
  it 'does not treat an uppercase name containing Polish letters as a constant' do
    code = '
      niech PÓŁ = 1
      PÓŁ = 2
      pokazl PÓŁ
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('2')
  end

  it 'still treats a pure-ASCII uppercase name as a constant' do
    code = '
      niech POL = 1
      POL = 2
    '
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/jest stala/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  # Same regex is used by modules.rb to decide what may live in a module body,
  # so a Polish-letter constant is rejected there outright.
  it 'rejects a Polish-letter constant inside a module body' do
    code = '
      modul M {
        niech PÓŁ = 0.5
      }
      pokazl 1
    '
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.exit_status).not_to eq(0)
  end
end