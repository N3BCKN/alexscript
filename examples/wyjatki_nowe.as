proba {
  rzuc BladTypu.nowy("Test")
} zlap (e : BladTypu) {
  pokazl e['wiadomosc']  # Should print: Test
  pokazl e['klasa']       # Should print: BladTypu
}