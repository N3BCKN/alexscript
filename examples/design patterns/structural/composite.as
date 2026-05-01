abstrakcyjna klasa KomponentPlikow {
    funkcja konstruktor(nazwa) {
        niech @nazwa = nazwa
    }
    
    funkcja wyswietl(wcienie = 0) {
        rzuc "Metoda abstrakcyjna"
    }
    
    funkcja rozmiar() {
        rzuc "Metoda abstrakcyjna"
    }
}

klasa Plik < KomponentPlikow {
    funkcja konstruktor(nazwa, rozmiar_kb) {
        super(nazwa)
        niech @rozmiar_kb = rozmiar_kb
    }
    
    funkcja wyswietl(wcienie = 0) {
        niech spacje = ""
        dla niech n = 0; wcienie; 1 {
            niech spacje = spacje + "  "
        }
        pokazl spacje + "📄 " + @nazwa + " (" + @rozmiar_kb + " KB)"
    }
    
    funkcja rozmiar() {
        zwroc @rozmiar_kb
    }
}

klasa Folder < KomponentPlikow {
    funkcja konstruktor(nazwa) {
        super(nazwa)
        niech @zawartosc = []
    }
    
    funkcja dodaj(komponent) {
        @zawartosc.dodaj(komponent)
    }
    
    funkcja usun(komponent) {
        niech indeks = 0
        dla element w @zawartosc {
            jesli element.identyczny(komponent) {
                @zawartosc.usun(indeks)
                zwroc prawda
            }
            niech indeks = indeks + 1
        }
        zwroc falsz
    }
    
    funkcja wyswietl(wcienie = 0) {
        niech spacje = ""
        dla niech n = 0; wcienie; 1 {
            niech spacje = spacje + "  "
        }
        pokazl spacje + "📁 " + @nazwa + "/"
                
        dla element w @zawartosc {
            element.wyswietl(wcienie + 1)
        }
    }
    
    funkcja rozmiar() {
        niech suma = 0
        dla element w @zawartosc {
            niech suma = suma + element.rozmiar()
        }
        zwroc suma
    }
}


pokazl "=== Test Composite ==="
pokazl ""

niech plik1 = Plik.nowy("readme.txt", 5)
niech plik2 = Plik.nowy("config.json", 2)
niech plik3 = Plik.nowy("main.as", 15)
niech plik4 = Plik.nowy("test.as", 8)
niech plik5 = Plik.nowy("logo.png", 250)

niech folder_src = Folder.nowy("src")
folder_src.dodaj(plik3)
folder_src.dodaj(plik4)

niech folder_assets = Folder.nowy("assets")
folder_assets.dodaj(plik5)

niech folder_root = Folder.nowy("projekt")
folder_root.dodaj(plik1)
folder_root.dodaj(plik2)
folder_root.dodaj(folder_src)
folder_root.dodaj(folder_assets)

pokazl "Struktura projektu:"
folder_root.wyswietl()
pokazl ""
pokazl "Całkowity rozmiar: " + folder_root.rozmiar() + " KB"