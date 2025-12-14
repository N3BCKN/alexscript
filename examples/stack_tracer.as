        funkcja outer() {
          inner()
        }
        
        funkcja inner() {
          rzuc BladTypu.nowy("Type error")
        }
        
        proba {
          outer()
        } zlap (e : BladWykonania) {
          pokazl e
          pokazl "nie złapany"
        } zlap (e : BladTypu) {
          pokazl e["stos"].dlg
        }