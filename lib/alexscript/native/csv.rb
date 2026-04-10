# frozen_string_literal: true

# lib/alexscript/native/csv_lib.rb
#
# Native binding for Ruby's CSV library, exposed as AlexScript's Csv class.
# Purely static — Csv cannot be instantiated.
#
# Design: CSV data in AlexScript is represented as arrays of arrays (rows of fields).
# Headers mode returns array of objects (hashes) instead.
#
# Covers:
#   Parsing:    parsuj, parsuj_linie, parsuj_plik
#   Generating: generuj, generuj_linie, generuj_plik
#   With headers: parsuj_z_naglowkami, parsuj_plik_z_naglowkami

require 'csv'

module AlexScript
  module Native
    module CsvLibrary

      def self.register
        Utils::NativeClassRegistry.define_class('Csv',
          constructor: ->(*) {
            raise "Csv jest klasą statyczną i nie może być instancjonowana"
          },
          methods: {},
          static_methods: build_static_methods,
          static_vars: {
            'SEPARATOR' => ','
          }
        )
      end

      def self.build_static_methods
        {
          # ─── Parsing ───────────────────────────────────────

          # Csv.parsuj("a,b,c\n1,2,3")  → [["a","b","c"],["1","2","3"]]
          'parsuj' => ->(tekst, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            CSV.parse(tekst.to_s, col_sep: separator)
          },

          # Csv.parsuj_linie("a,b,c")  → ["a", "b", "c"]
          'parsuj_linie' => ->(tekst, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            CSV.parse_line(tekst.to_s, col_sep: separator) || []
          },

          # Csv.parsuj_plik("dane.csv")  → array of arrays
          # Csv.parsuj_plik("dane.csv", ";")  → custom separator
          'parsuj_plik' => ->(sciezka, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            CSV.read(sciezka.to_s, col_sep: separator)
          },

          # ─── Parsing with headers ──────────────────────────

          # Csv.parsuj_z_naglowkami("imie,wiek\nJan,30\nAna,25")
          # → [{"imie": "Jan", "wiek": "30"}, {"imie": "Ana", "wiek": "25"}]
          'parsuj_z_naglowkami' => ->(tekst, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            table = CSV.parse(tekst.to_s, headers: true, col_sep: separator)
            table.map { |row| row.to_h }
          },

          # Csv.parsuj_plik_z_naglowkami("dane.csv")
          # → array of hashes
          'parsuj_plik_z_naglowkami' => ->(sciezka, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            table = CSV.read(sciezka.to_s, headers: true, col_sep: separator)
            table.map { |row| row.to_h }
          },

          # ─── Header extraction ─────────────────────────────

          # Csv.naglowki("imie,wiek\nJan,30")  → ["imie", "wiek"]
          'naglowki' => ->(tekst, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            table = CSV.parse(tekst.to_s, headers: true, col_sep: separator)
            table.headers
          },

          # Csv.naglowki_pliku("dane.csv")  → ["col1", "col2", ...]
          'naglowki_pliku' => ->(sciezka, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            table = CSV.read(sciezka.to_s, headers: true, col_sep: separator)
            table.headers
          },

          # ─── Generating ────────────────────────────────────

          # Csv.generuj([["a","b"],["1","2"]])  → "a,b\n1,2\n"
          # Csv.generuj([["a","b"],["1","2"]], ";")  → "a;b\n1;2\n"
          'generuj' => ->(wiersze, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            ruby_rows = convert_rows_to_ruby(wiersze)
            CSV.generate(col_sep: separator) do |csv|
              ruby_rows.each { |row| csv << row }
            end
          },

          # Csv.generuj_linie(["a", "b", "c"])  → "a,b,c\n"
          'generuj_linie' => ->(tablica, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            ruby_arr = convert_single_row(tablica)
            CSV.generate_line(ruby_arr, col_sep: separator)
          },

          # Csv.generuj_plik("out.csv", [["a","b"],["1","2"]])
          'generuj_plik' => ->(sciezka, wiersze, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            ruby_rows = convert_rows_to_ruby(wiersze)
            CSV.open(sciezka.to_s, 'wb', col_sep: separator) do |csv|
              ruby_rows.each { |row| csv << row }
            end
            ruby_rows.size
          },

          # ─── With headers generating ───────────────────────

          # Csv.generuj_z_naglowkami(["imie","wiek"], [["Jan","30"],["Ana","25"]])
          'generuj_z_naglowkami' => ->(naglowki, wiersze, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            ruby_headers = convert_single_row(naglowki)
            ruby_rows = convert_rows_to_ruby(wiersze)
            CSV.generate(col_sep: separator) do |csv|
              csv << ruby_headers
              ruby_rows.each { |row| csv << row }
            end
          },

          # Csv.generuj_plik_z_naglowkami("out.csv", ["imie","wiek"], [["Jan","30"]])
          'generuj_plik_z_naglowkami' => ->(sciezka, naglowki, wiersze, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            ruby_headers = convert_single_row(naglowki)
            ruby_rows = convert_rows_to_ruby(wiersze)
            CSV.open(sciezka.to_s, 'wb', col_sep: separator) do |csv|
              csv << ruby_headers
              ruby_rows.each { |row| csv << row }
            end
            ruby_rows.size + 1
          },

          # ─── Utility ───────────────────────────────────────

          # Csv.liczba_wierszy("a,b\n1,2\n3,4")  → 3 (including header)
          'liczba_wierszy' => ->(tekst, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            CSV.parse(tekst.to_s, col_sep: separator).size
          },

          # Csv.liczba_kolumn("a,b,c\n1,2,3")  → 3
          'liczba_kolumn' => ->(tekst, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            rows = CSV.parse(tekst.to_s, col_sep: separator)
            rows.empty? ? 0 : rows.first.size
          },

          # Csv.kolumna("imie,wiek\nJan,30\nAna,25", "wiek")  → ["30", "25"]
          'kolumna' => ->(tekst, nazwa, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            table = CSV.parse(tekst.to_s, headers: true, col_sep: separator)
            table.map { |row| row[nazwa.to_s] }
          },

          # Csv.kolumna_pliku("dane.csv", "wiek")  → ["30", "25"]
          'kolumna_pliku' => ->(sciezka, nazwa, *args) {
            separator = args.empty? ? ',' : args[0].to_s
            table = CSV.read(sciezka.to_s, headers: true, col_sep: separator)
            table.map { |row| row[nazwa.to_s] }
          }
        }
      end

      private

      # Convert AS array-of-arrays to Ruby array-of-arrays
      def self.convert_rows_to_ruby(wiersze)
        if wiersze.is_a?(Array) && wiersze.first.is_a?(Hash) && wiersze.first.key?(:type)
          # AS typed array: [{type: :type_array, value: [...]}, ...]
          wiersze.map { |elem| convert_single_row(elem[:value] || elem) }
        elsif wiersze.is_a?(Array) && wiersze.first.is_a?(Array)
          wiersze.map { |row| row.map(&:to_s) }
        else
          wiersze.map { |row| convert_single_row(row) }
        end
      end

      # Convert a single AS row to Ruby array of strings
      def self.convert_single_row(row)
        if row.is_a?(Array) && row.first.is_a?(Hash) && row.first.key?(:type)
          row.map { |elem| elem[:value].to_s }
        elsif row.is_a?(Array)
          row.map(&:to_s)
        else
          [row.to_s]
        end
      end
    end
  end
end