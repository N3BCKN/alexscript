# frozen_string_literal: true

# lib/alexscript/native/plik.rb
#
# Native binding for Ruby's File and IO classes, exposed as AlexScript's Plik class.
#
# Design: Plik has both static convenience methods (read/write entire files)
# and instance methods (open a handle, read/write incrementally, close).
#
# Covers:
#   Static — convenience:
#     czytaj, zapisz, dopisz, czytaj_linie, zapisz_linie
#   Static — queries:
#     istnieje, czy_plik, czy_katalog, czy_pusty, rozmiar, rozszerzenie
#     nazwa, katalog, pelna_sciezka, polacz
#   Static — manipulation:
#     usun, kopiuj, przesun, zmien_nazwe, utworz_katalog, usun_katalog
#     lista_katalogu
#   Static — permissions/metadata:
#     czas_dostepu, czas_modyfikacji, czas_utworzenia
#     czy_odczytywalny, czy_zapisywalny, czy_wykonywalny
#   Instance — streaming:
#     nowy(sciezka, tryb), czytaj, czytaj_linie, czytaj_bajty
#     zapisz, zapisz_linie, przesun_kursor, pozycja_kursora
#     zamknij, czy_zamkniety
#
# Performance: all methods are direct Ruby lambda calls.
# File handles live as __native__ on the instance — GC-safe.

require 'fileutils'

module AlexScript
  module Native
    module PlikLibrary

      def self.register
        Utils::NativeClassRegistry.define_class('Plik',
          ruby_class: File,
          constructor: method(:construct),
          methods: build_instance_methods,
          static_methods: build_static_methods,
          static_vars: build_static_vars
        )
      end

      # ── Constructor ────────────────────────────────────────────
      # Plik.nowy(sciezka, tryb)
      #   tryb: "r" (czytanie), "w" (pisanie), "a" (dopisywanie),
      #         "r+" (czytanie+pisanie), "rb" (binarny odczyt), etc.

      def self.construct(sciezka, tryb = 'r')
        File.open(sciezka.to_s, tryb.to_s)
      end

      # ── Static Constants ───────────────────────────────────────

      def self.build_static_vars
        {
          'SEPARATOR' => File::SEPARATOR,
          'ALT_SEPARATOR' => File::ALT_SEPARATOR || '',
          'PATH_SEPARATOR' => File::PATH_SEPARATOR
        }
      end

      # ── Instance Methods ───────────────────────────────────────

      def self.build_instance_methods
        {
          # ─── Reading ───────────────────────────────────────
          'czytaj' => ->(f, *args) {
            args.empty? ? f.read : f.read(args[0].to_i)
          },

          'czytaj_linie' => ->(f) {
            f.readlines.map(&:chomp)
          },

          'czytaj_linie_raw' => ->(f) {
            f.readlines
          },

          'czytaj_bajty' => ->(f, n) {
            bytes = f.read(n.to_i)
            bytes ? bytes.bytes.to_a : []
          },

          'czytaj_znak' => ->(f) {
            f.getc || ''
          },

          # ─── Writing ───────────────────────────────────────
          'zapisz' => ->(f, dane) {
            f.write(dane.to_s)
          },

          'zapisz_linie' => ->(f, linie) {
            if linie.is_a?(Array)
              linie.each { |l| f.puts(l.to_s) }
              linie.size
            else
              f.puts(linie.to_s)
              1
            end
          },

          'wyczysc' => ->(f) {
            f.truncate(0)
            f.rewind
            true
          },

          'flush' => ->(f) {
            f.flush
            true
          },

          # ─── Cursor / Position ─────────────────────────────
          'przewin' => ->(f) {
            f.rewind
            true
          },

          'przesun_kursor' => ->(f, pozycja, *args) {
            # whence: 0=SEEK_SET, 1=SEEK_CUR, 2=SEEK_END
            whence = args.empty? ? IO::SEEK_SET : args[0].to_i
            f.seek(pozycja.to_i, whence)
            true
          },

          'pozycja' => ->(f) {
            f.pos
          },

          'rozmiar' => ->(f) {
            f.size
          },

          # ─── State ─────────────────────────────────────────
          'zamknij' => ->(f) {
            return true if f.closed?
            f.close
            true
          },

          'czy_zamkniety' => ->(f) {
            f.closed?
          },

          'czy_koniec' => ->(f) {
            f.eof?
          },

          # ─── Metadata ─────────────────────────────────────
          'sciezka' => ->(f) {
            f.path
          },

          'tryb' => ->(f) {
            # No direct Ruby method; approximate from stat
            f.stat.mode.to_s(8)
          },

          'czas_modyfikacji' => ->(f) {
            f.mtime
          },

          'czas_dostepu' => ->(f) {
            f.atime
          }
        }
      end

      # ── Static Methods ─────────────────────────────────────────

      def self.build_static_methods
        {
          # ─── Convenience read/write (open+close in one call) ─

          'czytaj' => ->(sciezka) {
            File.read(sciezka.to_s)
          },

          'czytaj_linie' => ->(sciezka) {
            File.readlines(sciezka.to_s).map(&:chomp)
          },

          'zapisz' => ->(sciezka, dane) {
            File.write(sciezka.to_s, dane.to_s)
          },

          'dopisz' => ->(sciezka, dane) {
            File.open(sciezka.to_s, 'a') { |f| f.write(dane.to_s) }
          },

          'zapisz_linie' => ->(sciezka, linie) {
            if linie.is_a?(Array)
              content = linie.map(&:to_s).join("\n") + "\n"
              File.write(sciezka.to_s, content)
              linie.size
            else
              File.write(sciezka.to_s, linie.to_s + "\n")
              1
            end
          },

          # ─── Path queries ──────────────────────────────────

          'istnieje' => ->(sciezka) {
            File.exist?(sciezka.to_s)
          },

          'czy_plik' => ->(sciezka) {
            File.file?(sciezka.to_s)
          },

          'czy_katalog' => ->(sciezka) {
            File.directory?(sciezka.to_s)
          },

          'czy_pusty' => ->(sciezka) {
            if File.directory?(sciezka.to_s)
              Dir.empty?(sciezka.to_s)
            elsif File.file?(sciezka.to_s)
              File.zero?(sciezka.to_s)
            else
              true
            end
          },

          'czy_odczytywalny' => ->(sciezka) {
            File.readable?(sciezka.to_s)
          },

          'czy_zapisywalny' => ->(sciezka) {
            File.writable?(sciezka.to_s)
          },

          'czy_wykonywalny' => ->(sciezka) {
            File.executable?(sciezka.to_s)
          },

          'czy_dowiazanie' => ->(sciezka) {
            File.symlink?(sciezka.to_s)
          },

          # ─── Path components ───────────────────────────────

          'nazwa' => ->(sciezka, *args) {
            # nazwa("plik.txt") → "plik.txt"
            # nazwa("plik.txt", ".txt") → "plik"  (strip extension)
            args.empty? ? File.basename(sciezka.to_s) : File.basename(sciezka.to_s, args[0].to_s)
          },

          'katalog' => ->(sciezka) {
            File.dirname(sciezka.to_s)
          },

          'rozszerzenie' => ->(sciezka) {
            File.extname(sciezka.to_s)
          },

          'pelna_sciezka' => ->(sciezka) {
            File.expand_path(sciezka.to_s)
          },

          'rzeczywista_sciezka' => ->(sciezka) {
            File.realpath(sciezka.to_s)
          },

          'polacz' => ->(*czesci) {
            File.join(*czesci.map(&:to_s))
          },

          'podziel' => ->(sciezka) {
            # Returns [directory, filename]
            File.split(sciezka.to_s)
          },

          # ─── File info ─────────────────────────────────────

          'rozmiar' => ->(sciezka) {
            File.size(sciezka.to_s)
          },

          'czas_dostepu' => ->(sciezka) {
            File.atime(sciezka.to_s)
          },

          'czas_modyfikacji' => ->(sciezka) {
            File.mtime(sciezka.to_s)
          },

          'czas_utworzenia' => ->(sciezka) {
            begin
              File.birthtime(sciezka.to_s)
            rescue NotImplementedError
              File.ctime(sciezka.to_s)
            end
          },

          'typ' => ->(sciezka) {
            File.ftype(sciezka.to_s)
          },

          # ─── Manipulation ──────────────────────────────────

          'usun' => ->(sciezka) {
            File.delete(sciezka.to_s)
            true
          },

          'zmien_nazwe' => ->(stara, nowa) {
            File.rename(stara.to_s, nowa.to_s)
            true
          },

          'kopiuj' => ->(zrodlo, cel) {
            FileUtils.cp(zrodlo.to_s, cel.to_s)
            true
          },

          'przesun' => ->(zrodlo, cel) {
            FileUtils.mv(zrodlo.to_s, cel.to_s)
            true
          },

          'utworz_katalog' => ->(sciezka) {
            FileUtils.mkdir_p(sciezka.to_s)
            true
          },

          'usun_katalog' => ->(sciezka) {
            FileUtils.rm_rf(sciezka.to_s)
            true
          },

          'lista' => ->(sciezka, *args) {
            # lista(".") → all files
            # lista(".", "*.rb") → glob pattern
            pattern = args.empty? ? '*' : args[0].to_s
            Dir.glob(File.join(sciezka.to_s, pattern))
          },

          'lista_rekurencyjna' => ->(sciezka, *args) {
            pattern = args.empty? ? '**/*' : "**/#{args[0]}"
            Dir.glob(File.join(sciezka.to_s, pattern))
          },

          # ─── Permissions ───────────────────────────────────

          'zmien_uprawnienia' => ->(sciezka, tryb) {
            File.chmod(tryb.to_i, sciezka.to_s)
            true
          },

          # ─── Temp file ─────────────────────────────────────

          'plik_tymczasowy' => ->(*args) {
            prefix = args.empty? ? 'alexscript' : args[0].to_s
            tmp = Tempfile.new(prefix)
            tmp.path
          },

          'katalog_tymczasowy' => ->() {
            Dir.tmpdir
          },

          # ─── Utility ───────────────────────────────────────

          'biezacy_katalog' => ->() {
            Dir.pwd
          },

          'zmien_katalog' => ->(sciezka) {
            Dir.chdir(sciezka.to_s)
            true
          }
        }
      end
    end
  end
end