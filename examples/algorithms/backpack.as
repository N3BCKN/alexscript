funkcja plecak_01(wagi, wartosci, pojemnosc) {
    niech n = wagi.dlg

    # Inicjalizacja tablicy DP: dp[i][w] = max wartość dla pierwszych i przedmiotów i pojemności w
    niech dp = []
    dla niech k = 0; n + 1; 1 {
        niech wiersz = []
        dla niech x = 0; pojemnosc + 1; 1 {
            wiersz << 0
        }
        dp << wiersz
    }

    # Wypełnianie tablicy DP od dołu do góry
    dla niech k = 1; n + 1; 1 {
        dla niech x = 0; pojemnosc + 1; 1 {
            jesli wagi[k - 1] <= x {
                # Wybór: bierzemy przedmiot lub nie
                niech bez_przedmiotu = dp[k - 1][x]
                niech z_przedmiotem = dp[k - 1][x - wagi[k - 1]] + wartosci[k - 1]
                jesli z_przedmiotem > bez_przedmiotu {
                    dp[k][x] = z_przedmiotem
                } albo {
                    dp[k][x] = bez_przedmiotu
                }
            } albo {
                # Przedmiot się nie mieści - bierzemy bez niego
                dp[k][x] = dp[k - 1][x]
            }
        }
    }

    zwroc dp[n][pojemnosc]
}

niech wagi13 = [2, 3, 4, 5]
niech wartosci13 = [3, 4, 5, 6]
niech pojemnosc13 = 8
pokazl "Plecak 0/1 (pojemność " + pojemnosc13 + "): max wartość = " + plecak_01(wagi13, wartosci13, pojemnosc13)