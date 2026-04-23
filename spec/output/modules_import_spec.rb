require 'aruba/rspec'

RSpec.describe 'Module imports across files', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  def output_without_load_noise(raw)
    raw.lines.reject { |l| l.include?("has been read successfully") }.join.strip
  end

  describe 'direct import of a file defining a module' do
    it 'exposes nested module classes to the importer' do
      write_file('mod.as', <<~AS)
        modul Zubr {
          modul Parser {
            klasa Limity {
              funkcja konstruktor() {
                pokazl "Witaj!"
              }
            }
          }
        }
      AS

      write_file('main.as', <<~AS)
        import('./mod.as')
        niech x = Zubr::Parser::Limity.nowy()
      AS

      run_command_and_stop "ruby #{main_file_path} main.as"
      expect(output_without_load_noise(last_command_started.output.strip.gsub(/[\\"]/, ''))).to eq('Witaj!')
    end
  end

  describe 'transitive import (A -> B -> C) of a module' do
    it 'propagates a module defined two levels deep' do
      write_file('c.as', <<~AS)
        modul Zubr {
          modul Parser {
            niech XYZ = 123

            klasa Limity {
              funkcja konstruktor() {
                pokazl "Witaj!"
              }
            }
          }
        }
      AS

      write_file('b.as', "import('./c.as')\n")

      write_file('a.as', <<~AS)
        import('./b.as')
        niech x = Zubr::Parser::Limity.nowy()
      AS

      run_command_and_stop "ruby #{main_file_path} a.as"
      expect(output_without_load_noise(last_command_started.output.strip.gsub(/[\\"]/, ''))).to eq('Witaj!')
    end

    it 'exposes module constants through the chain' do
      write_file('c.as', <<~AS)
        modul Zubr {
          modul Parser {
            niech XYZ = 123
          }
        }
      AS

      write_file('b.as', "import('./c.as')\n")

      write_file('a.as', <<~AS)
        import('./b.as')
        pokazl Zubr::Parser::XYZ
      AS

      run_command_and_stop "ruby #{main_file_path} a.as"
      expect(output_without_load_noise(last_command_started.output.strip.gsub(/[\\"]/, ''))).to eq('123')
    end
  end

  describe 'module reopening across sibling imports' do
    it 'merges classes from two files that both open the same module' do
      write_file('a.as', <<~AS)
        modul Zubr {
          klasa A {
            funkcja konstruktor() { pokazl "A" }
          }
        }
      AS

      write_file('b.as', <<~AS)
        modul Zubr {
          klasa B {
            funkcja konstruktor() { pokazl "B" }
          }
        }
      AS

      write_file('main.as', <<~AS)
        import('./a.as')
        import('./b.as')
        niech x = Zubr::A.nowy()
        niech y = Zubr::B.nowy()
      AS

      run_command_and_stop "ruby #{main_file_path} main.as"
      expect(output_without_load_noise(last_command_started.output.strip.gsub(/[\\"]/, ''))).to eq("A\nB")
    end
  end

  describe '\'::\' and \'.\' equivalence for imported module members' do
    it 'allows calling a static method via both separators' do
      write_file('mod.as', <<~AS)
        modul Zubr {
          klasa Narzedzia {
            statyczna funkcja powitaj() {
              pokazl "czesc"
            }
          }
        }
      AS

      write_file('main.as', <<~AS)
        import('./mod.as')
        Zubr::Narzedzia.powitaj()
        Zubr::Narzedzia::powitaj()
      AS

      run_command_and_stop "ruby #{main_file_path} main.as"
      expect(output_without_load_noise(last_command_started.output.strip.gsub(/[\\"]/, ''))).to eq("czesc\nczesc")
    end
  end

  describe 'optional .as extension in imports' do
    it 'resolves import(name) to name.as when extension is omitted' do
      write_file('mod.as', <<~AS)
        modul Zubr {
          klasa Limity {
            funkcja konstruktor() { pokazl "Witaj!" }
          }
        }
      AS

      write_file('main.as', <<~AS)
        import('./mod')
        niech x = Zubr::Limity.nowy()
      AS

      run_command_and_stop "ruby #{main_file_path} main.as"
      expect(output_without_load_noise(last_command_started.output.strip.gsub(/[\\"]/, ''))).to eq('Witaj!')
    end

    it 'accepts explicit .as extension as well' do
      write_file('mod.as', <<~AS)
        modul Zubr {
          klasa Limity {
            funkcja konstruktor() { pokazl "Witaj!" }
          }
        }
      AS

      write_file('main.as', <<~AS)
        import('./mod.as')
        niech x = Zubr::Limity.nowy()
      AS

      run_command_and_stop "ruby #{main_file_path} main.as"
      expect(output_without_load_noise(last_command_started.output.strip.gsub(/[\\"]/, ''))).to eq('Witaj!')
    end

    it 'reports the .as filename when the file does not exist' do
      write_file('main.as', "import('./nonexistent')\n")

      run_command "ruby #{main_file_path} main.as"
      stop_all_commands

      expect(last_command_started.output).to include('nonexistent.as')
    end
  end

  describe 'import call stack on errors' do
    it 'preserves original error class and line when a runtime error occurs in an imported file' do
      write_file('c.as', "pokazl nieznana_zmienna\n")
      write_file('b.as', "import('./c.as')\n")
      write_file('a.as', "import('./b.as')\n")

      run_command "ruby #{main_file_path} a.as"
      stop_all_commands

      output = last_command_started.output
      # original class survives the import chain (no longer wrapped in BladImportu)
      expect(output).to include('BladNazwy')
      # import chain is printed with both links
      expect(output).to include("import './c.as'")
      expect(output).to include("import './b.as'")
      # locations point at the importing files
      expect(output).to include('(b.as:')
      expect(output).to include('(a.as:')
    end

    it 'prints BladImportu with stack when the imported file is missing' do
      write_file('main.as', "import('./does_not_exist.as')\n")

      run_command "ruby #{main_file_path} main.as"
      stop_all_commands

      output = last_command_started.output
      expect(output).to include('BladImportu')
      expect(output).to include("import './does_not_exist.as'")
    end

    it 'normalizes displayed import paths to include .as' do
      write_file('c.as', "pokazl nieznana_zmienna\n")
      write_file('b.as', "import('./c')\n")     # written without .as
      write_file('a.as', "import('./b.as')\n") # written with .as

      run_command "ruby #{main_file_path} a.as"
      stop_all_commands

      output = last_command_started.output
      expect(output).to include("import './c.as'")
      expect(output).to include("import './b.as'")
    end
  end
end