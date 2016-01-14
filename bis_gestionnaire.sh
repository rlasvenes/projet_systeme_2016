#! /bin/bash

genMenu()
{
	# pense bete: nb_char=$(head -n 1 fic.menu | wc -c)
	echo "+----------------+" > fic.menu
	printf "|%3s | %-9s |\n" "1)" "Voir" "2)" "editer" "3)" "compiler" "4)" "Lancer" "5)" "debug" "6)" "Shell" >> fic.menu
	echo "+----------------+" >> fic.menu
	
}
genMenu
