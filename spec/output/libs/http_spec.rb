require 'aruba/rspec'

RSpec.describe 'Http native library', type: :aruba do
  let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', File.dirname(__FILE__)) }
  let(:test_download) { '/tmp/as_http_rspec_download.txt' }

  after(:each) { FileUtils.rm_f(test_download) }

  # ── 1. URL encoding/decoding (offline) ─────────────────────

  describe 'URL encoding' do
    it 'encodes and decodes URL components' do
      code = '
        import("http")
        niech z = Http.koduj_url("witaj świecie")
        pokazl z.zawiera(" ") == falsz
        niech o = Http.dekoduj_url(z)
        pokazl o
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nwitaj świecie")
    end

    it 'round-trips encode/decode' do
      code = '
        import("http")
        niech tekst = "test/ścieżka?p=v"
        niech rt = Http.dekoduj_url(Http.koduj_url(tekst))
        pokazl rt == tekst
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end
  end

  # ── 2. URL parsing (offline) ───────────────────────────────

  describe 'URL parsing' do
    it 'parses full URL into components' do
      code = '
        import("http")
        niech p = Http.parsuj_url("https://example.com:8080/api/v1?k=v#sec")
        pokazl p["schemat"]
        pokazl p["host"]
        pokazl p["port"]
        pokazl p["sciezka"]
        pokazl p["zapytanie"]
        pokazl p["fragment"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq(
        "https\nexample.com\n8080\n/api/v1\nk=v\nsec"
      )
    end

    it 'parses simple URL' do
      code = '
        import("http")
        niech p = Http.parsuj_url("http://test.com/strona")
        pokazl p["schemat"]
        pokazl p["host"]
        pokazl p["sciezka"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("http\ntest.com\n/strona")
    end
  end

  # ── 3. Query string (offline) ──────────────────────────────

  describe 'query string' do
    it 'builds query string from object' do
      code = '
        import("http")
        niech qs = Http.zbuduj_zapytanie({"a": "1", "b": "2"})
        pokazl qs.zawiera("a=1")
        pokazl qs.zawiera("b=2")
        pokazl qs.zawiera("&")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda")
    end

    it 'parses query string to object' do
      code = '
        import("http")
        niech p = Http.parsuj_zapytanie("x=10&y=20")
        pokazl p["x"]
        pokazl p["y"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("10\n20")
    end

    it 'round-trips query build/parse' do
      code = '
        import("http")
        niech qs = Http.zbuduj_zapytanie({"klucz": "wartosc", "foo": "bar"})
        niech o = Http.parsuj_zapytanie(qs)
        pokazl o["klucz"]
        pokazl o["foo"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("wartosc\nbar")
    end
  end

  # ── 4. URL building (offline) ──────────────────────────────

  describe 'URL building' do
    it 'builds URL from components' do
      code = '
        import("http")
        niech u = Http.zbuduj_url("https", "example.com", 443, "/api", "q=1")
        pokazl u.zawiera("https")
        pokazl u.zawiera("example.com")
        pokazl u.zawiera("/api")
        pokazl u.zawiera("q=1")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda\nprawda")
    end
  end

  # ── 5. HTTP GET (real network) ─────────────────────────────

  describe 'HTTP GET', network: true do
    it 'performs GET request and returns response object' do
      code = '
        import("http")
        niech odp = Http.get("https://httpbin.org/get")
        pokazl odp["status"]
        pokazl odp["czy_sukces"]
        pokazl odp["cialo"].dlg() > 0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip).to eq("200\nprawda\nprawda")
    end

    it 'returns response headers' do
      code = '
        import("http")
        niech odp = Http.get("https://httpbin.org/get")
        pokazl odp["naglowki"]["content-type"].dlg() > 0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'returns response message' do
      code = '
        import("http")
        niech odp = Http.get("https://httpbin.org/get")
        pokazl odp["wiadomosc"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("OK")
    end
  end

  # ── 6. HTTP GET JSON (real network) ────────────────────────

  describe 'HTTP GET JSON', network: true do
    it 'parses JSON response directly' do
      code = '
        import("http")
        niech d = Http.get_json("https://httpbin.org/get")
        pokazl d["url"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("https://httpbin.org/get")
    end

    it 'sends custom headers with get_json' do
      code = '
        import("http")
        niech d = Http.get_json("https://httpbin.org/headers", {"X-Test": "abc123"})
        pokazl d["headers"]["X-Test"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("abc123")
    end
  end

  # ── 7. HTTP POST (real network) ────────────────────────────

  describe 'HTTP POST', network: true do
    it 'sends POST with body' do
      code = '
        import("http")
        niech odp = Http.post("https://httpbin.org/post", "dane testowe")
        pokazl odp["status"]
        pokazl odp["cialo"].zawiera("dane testowe")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip).to eq("200\nprawda")
    end
  end

  # ── 8. HTTP POST JSON (real network) ───────────────────────

  describe 'HTTP POST JSON', network: true do
    it 'sends and receives JSON' do
      code = '
        import("http")
        niech k = Http.post_json("https://httpbin.org/post", {"klucz": "wartosc", "n": 42})
        pokazl k["json"]["klucz"]
        pokazl k["json"]["n"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("wartosc\n42")
    end
  end

  # ── 9. HTTP PUT (real network) ─────────────────────────────

  describe 'HTTP PUT', network: true do
    it 'sends PUT request' do
      code = '
        import("http")
        niech odp = Http.put("https://httpbin.org/put", "put data")
        pokazl odp["status"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip).to eq("200")
    end
  end

  # ── 10. HTTP DELETE (real network) ──────────────────────────

  describe 'HTTP DELETE', network: true do
    it 'sends DELETE request' do
      code = '
        import("http")
        niech odp = Http.delete("https://httpbin.org/delete")
        pokazl odp["status"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip).to eq("200")
    end
  end

  # ── 11. HTTP HEAD (real network) ───────────────────────────

  describe 'HTTP HEAD', network: true do
    it 'sends HEAD request with empty body' do
      code = '
        import("http")
        niech odp = Http.head("https://httpbin.org/get")
        pokazl odp["status"]
        pokazl odp["cialo"].dlg() == 0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip).to eq("200\nprawda")
    end
  end

  # ── 12. Status codes (real network) ────────────────────────

  describe 'HTTP status codes', network: true do
    it 'detects 404 client error' do
      code = '
        import("http")
        niech odp = Http.get("https://httpbin.org/status/404")
        pokazl odp["status"]
        pokazl odp["czy_blad_klienta"]
        pokazl odp["czy_sukces"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip).to eq("404\nprawda\nfalsz")
    end

    it 'detects 500 server error' do
      code = '
        import("http")
        niech odp = Http.get("https://httpbin.org/status/500")
        pokazl odp["status"]
        pokazl odp["czy_blad_serwera"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip).to eq("500\nprawda")
    end
  end

  # ── 13. POST formularz (real network) ──────────────────────

  describe 'HTTP POST form', network: true do
    it 'sends form-encoded data' do
      code = '
        import("http")
        import("json")
        niech odp = Http.post_formularz("https://httpbin.org/post", {"user": "jan", "pass": "abc"})
        pokazl odp["status"]
        niech body = Json.parsuj(odp["cialo"])
        pokazl body["form"]["user"]
        pokazl body["form"]["pass"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("200\njan\nabc")
    end
  end

  # ── 14. Redirects (real network) ───────────────────────────

  describe 'HTTP redirects', network: true do
    it 'follows redirects automatically' do
      code = '
        import("http")
        niech odp = Http.get("https://httpbin.org/redirect/1")
        pokazl odp["status"]
        pokazl odp["czy_sukces"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip).to eq("200\nprawda")
    end
  end

  # ── 15. HTTPS (real network) ───────────────────────────────

  describe 'HTTPS', network: true do
    it 'handles HTTPS automatically' do
      code = '
        import("http")
        niech odp = Http.get("https://httpbin.org/get")
        pokazl odp["status"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'", exit_timeout: 30
      expect(last_command_started.output.strip).to eq("200")
    end
  end

  # ── 16. Cannot instantiate ─────────────────────────────────

  describe 'instantiation guard' do
    it 'raises error on Http.nowy()' do
      code = '
        import("http")
        niech h = Http.nowy()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Http jest klasą statyczną/)
      expect(last_command_started).to have_exit_status(1)
    end
  end
end
