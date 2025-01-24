# Generator grafiki w konsoli

# Podstawowe kształty i wzory
funkcja rysuj_prostokat(szerokosc, wysokosc, znak) {
    dla niech idx = 0; wysokosc; 1 {
        dla niech j = 0; szerokosc; 1 {
            pokaz znak
        }
        pokazl ""
    }
}

funkcja rysuj_pusty_prostokat(szerokosc, wysokosc, znak) {
    dla niech idx = 0; wysokosc; 1 {
        dla niech j = 0; szerokosc; 1 {
            jesli idx == 0 lub idx == wysokosc - 1 lub j == 0 lub j == szerokosc - 1 {
                pokaz znak
            } albo {
                pokaz " "
            }
        }
        pokazl ""
    }
}

funkcja rysuj_trojkat(wysokosc, znak) {
    dla niech idx = 0; wysokosc; 1 {
        dla niech j = 0; wysokosc - idx - 1; 1 {
            pokaz " "
        }
        dla niech j = 0; 2 * idx + 1; 1 {
            pokaz znak
        }
        pokazl ""
    }
}

funkcja rysuj_diament(rozmiar, znak) {
    # Górna połowa
    dla niech idx = 0; rozmiar; 1 {
        dla niech j = 0; rozmiar - idx - 1; 1 {
            pokaz " "
        }
        dla niech j = 0; 2 * idx + 1; 1 {
            pokaz znak
        }
        pokazl ""
    }
    
    # Dolna połowa
    dla niech idx = rozmiar - 2; 0; -1 {
        dla niech j = 0; rozmiar - idx - 1; 1 {
            pokaz " "
        }
        dla niech j = 0; 2 * idx + 1; 1 {
            pokaz znak
        }
        pokazl ""
    }
}

funkcja rysuj_spirale(rozmiar) {
    niech spiral = []
    dla niech idx = 0; rozmiar; 1 {
        spiral.dodaj([])
        dla niech j = 0; rozmiar; 1 {
            spiral[idx].dodaj(" ")
        }
    }
    
    niech znaki = ["┌", "─", "┐", "│", "└", "┘"]
    niech x = 0
    niech y = 0
    niech dx = 1
    niech dy = 0
    niech kroki = rozmiar
    niech zmiana = 0
    
    dopoki kroki > 0 {
        dla niech krok = 0; kroki; 1 {
            jesli dx == 1 {
                spiral[y][x] = "─"
            } albojesli dx == -1 {
                spiral[y][x] = "─"
            } albojesli dy == 1 {
                pokazl spiral.dlg
                pokazl spiral[y]
                pokazl spiral[y].dlg
                pokazl x
                spiral[y][x] = "│"
            } albojesli dy == -1 {
                spiral[y][x] = "│"
            }
            x = x + dx
            y = y + dy
        }
        
        # Narożniki
        jesli dx == 1 i dy == 0 {
            spiral[y-1][x-1] = "┐"
        } albojesli dx == 0 i dy == 1 {
            spiral[y-1][x] = "┘"
        } albojesli dx == -1 i dy == 0 {
            spiral[y][x+1] = "└"
        } albojesli dx == 0 i dy == -1 {
            spiral[y+1][x-1] = "┌"
        }
        
        # Zmiana kierunku
        niech temp = dx
        dx = -dy
        dy = temp
        
        zmiana = zmiana + 1
        jesli zmiana == 2 {
            kroki = kroki - 1
            zmiana = 0
        }
    }
    
    # Wyświetlenie spirali
    dla niech idx = 0; rozmiar; 1 {
        dla niech j = 0; rozmiar; 1 {
            pokaz spiral[idx][j]
        }
        pokazl ""
    }
}

funkcja rysuj_szachownice(rozmiar) {
    dla niech idx = 0; rozmiar; 1 {
        dla niech j = 0; rozmiar; 1 {
            jesli (idx + j) % 2 == 0 {
                pokaz "□"
            } albo {
                pokaz "■"
            }
        }
        pokazl ""
    }
}

funkcja rysuj_fale(szerokosc, wysokosc) {
    niech faza = 0
    dla niech idx = 0; wysokosc; 1 {
        dla niech j = 0; szerokosc; 1 {
            niech pozycja = (j + faza) % 4
            jesli pozycja == 0 {
                pokaz "~"
            } albojesli pozycja == 1 {
                pokaz "-"
            } albojesli pozycja == 2 {
                pokaz "~"
            } albo {
                pokaz "-"
            }
        }
        faza = (faza + 1) % 4
        pokazl ""
    }
}

funkcja rysuj_serce() {
    pokazl "  ♥♥   ♥♥"
    pokazl " ♥♥♥♥ ♥♥♥♥"
    pokazl "♥♥♥♥♥♥♥♥♥♥"
    pokazl " ♥♥♥♥♥♥♥♥"
    pokazl "  ♥♥♥♥♥♥"
    pokazl "   ♥♥♥♥"
    pokazl "    ♥♥"
}

funkcja rysuj_drzewo(wysokosc) {
    # Korona drzewa
    dla niech idx = 0; wysokosc; 1 {
        dla niech j = 0; wysokosc - idx - 1; 1 {
            pokaz " "
        }
        dla niech j = 0; 2 * idx + 1; 1 {
            pokaz "^"
        }
        pokazl ""
    }
    
    # Pień drzewa
    dla niech idx = 0; wysokosc/3; 1 {
        dla niech j = 0; wysokosc - 1; 1 {
            pokaz " "
        }
        pokazl "||"
    }
}

funkcja rysuj_labirynt(szerokosc, wysokosc) {
    niech labirynt = []
    dla niech idx = 0; wysokosc; 1 {
        labirynt.dodaj([])
        dla niech j = 0; szerokosc; 1 {
            labirynt[idx].dodaj("█")
        }
    }
    
  # Prosty algorytm generowania labiryntu
  funkcja stworz_sciezke(x, y) {
      labirynt[y][x] = " "
      niech kierunki = [[0,2], [2,0], [0,-2], [-2,0]]
      kierunki = tasuj(kierunki)
      
      dla niech idx = 0; kierunki.dlg; 1 {
          niech dx = kierunki[idx][0]
          niech dy = kierunki[idx][1]
          niech nowy_x = x + dx
          niech nowy_y = y + dy
          
          jesli nowy_x > 0 i nowy_x < szerokosc - 1 i nowy_y > 0 i nowy_y < wysokosc - 1 i
            labirynt[nowy_y][nowy_x] == "█" {
              labirynt[y + dy/2][x + dx/2] = " "
              stworz_sciezke(nowy_x, nowy_y)
          }
      }
  }
    
    stworz_sciezke(1, 1)
    
    # Wyjście z labiryntu
    labirynt[wysokosc-2][szerokosc-1] = " "
    
    # Wyświetlenie labiryntu
    dla niech idx = 0; wysokosc; 1 {
        dla niech j = 0; szerokosc; 1 {
            pokaz labirynt[idx][j]
        }
        pokazl ""
    }
}

funkcja tasuj(arr) {
    dla niech idx = arr.dlg - 1; 0; -1 {
        niech j = losuj(0, idx)
        niech temp = arr[idx]
        arr[idx] = arr[j]
        arr[j] = temp
    }
    zwroc arr
}

funkcja losuj(min, max) {
    zwroc min + (random() * (max - min + 1))
}

# Przykłady użycia
# funkcja przyklad_uzycia() {
#     pokazl "=== Prostokąt ==="
#     rysuj_prostokat(10, 5, "*")
#     pokazl ""
    
#     pokazl "=== Pusty prostokąt ==="
#     rysuj_pusty_prostokat(10, 5, "#")
#     pokazl ""
    
#     pokazl "=== Trójkąt ==="
#     rysuj_trojkat(5, "*")
#     pokazl ""
    
#     pokazl "=== Diament ==="
#     rysuj_diament(4, "*")
#     pokazl ""
    
#     pokazl "=== Spirala ==="
#     rysuj_spirale(10)
#     pokazl ""
    
#     pokazl "=== Szachownica ==="
#     rysuj_szachownice(8)
#     pokazl ""
    
#     pokazl "=== Fale ==="
#     rysuj_fale(20, 5)
#     pokazl ""
    
#     pokazl "=== Serce ==="
#     rysuj_serce()
#     pokazl ""
    
#     pokazl "=== Drzewo ==="
#     rysuj_drzewo(6)
#     pokazl ""
    
#     pokazl "=== Labirynt ==="
#     rysuj_labirynt(15, 15)
# }

# przyklad_uzycia()

    pokazl "=== Prostokąt ==="
    rysuj_prostokat(10, 5, "*")
    pokazl ""

    pokazl "=== Trójkąt ==="
    rysuj_labirynt(15, 15)
    pokazl ""