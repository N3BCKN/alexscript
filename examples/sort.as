funkcja bubblesort(L) {
	niech zamieniono = prawda
	dopoki zamieniono {
					zamieniono = falsz
					dla niech j = 0; L.dlg - 1; 1 {
									jesli L[j] > L[j + 1] {
													niech temp = L[j]
													L[j] = L[j + 1]
													L[j + 1] = temp
													zamieniono = prawda
									}
					}
	}
	zwroc L
}

# Główny program
niech nieposortowana = [5, 2, 4, 6, 1, 3]
niech posortowana = bubblesort(nieposortowana)
pokazl posortowana