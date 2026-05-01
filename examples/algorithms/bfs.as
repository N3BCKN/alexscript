funkcja bfs(graf, start) {
    niech kolejka = [start]
    niech odwiedzone = [start]
    niech porzadek = []

    dopoki kolejka.dlg > 0 {
        # Pobierz pierwszy element z kolejki (FIFO)
        niech aktualny = kolejka[0]
        kolejka.usun(0)
        porzadek << aktualny

        niech sasiedzi = graf[aktualny]
        dla sasiad w sasiedzi {
            jesli ! odwiedzone.zawiera(sasiad) {
                odwiedzone << sasiad
                kolejka << sasiad
            }
        }
    }

    zwroc porzadek
}

# Przykładowy graf:
#       A
#      / \
#     B   C
#    /|   |\
#   D E   F G
niech graf14 = {
    "A": ["B", "C"],
    "B": ["A", "D", "E"],
    "C": ["A", "F", "G"],
    "D": ["B"],
    "E": ["B"],
    "F": ["C"],
    "G": ["C"]
}

pokazl "BFS od wierzchołka 'A': " + bfs(graf14, "A")