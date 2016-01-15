#! /bin/bash

#### Script réalisé par :
#### Rémi Lasvenes et Alexandre Bouyssou ####

### État script : fonctionnel ###
### Finis le 13/01/2016 ### --------> voir fonction debugguerFichier : problème commande gdb

### Comprend quelques fonctionnalitées bonus minimal ###
### Fonction bonus non terminé --> repCourant() ###

############################## FONCTIONS (manipulations fichiers/dossier etc...) ##############################

genTemplate() # créée un fichier basique et ajoute du contenu dedans  
{
	clear
	touch temp.cpp
	
	# -e permet l'interprétation des backslashs mais pas que (voir man echo)
	echo -e "#include <iostream>" \
			"\n\nusing namespace std;" \
			"\n\nint main(int argc, char *argv[]) \n{" \
			"\n    cout << \"Hello World!\"  << endl; " \
			"\n    return 0;" \
			"\n}" > temp.cpp 
}

genMenu() # créée un menu sous avec interface graphique
{
	whiptail --title "gestionnaire" --nocancel --menu "fichier sélectionné : \"$FICHIER_EDIT$extension\"" 0 0 7 \
	"1)" "Voir" 		 \
	"2)" "Editer" \
	"3)" "Générer" \
	"4)" "Lancer" \
	"5)" "Débugguer" \
	"6)" "Imprimer" \
	"7)" "Shell" \
	"8)" "QUITTER" 3>&1 1>&2 2>&3 | cut -d')' -f1 > getChoix.txt # on récupère le choix de l'utilisateur

}

showMsgScreen() # affiche un message standard avec interface graphique
{
	whiptail --title "$1" --msgbox "$2" 0 0 0
}

showChoiceScreen() # afficher un message de type "choix" avec 2 choix possibles, avec interface graphique
{
	whiptail --title "$1" --yes-button "$2" --no-button "$3" --yesno "$4" 10 40
}

showInputScreen() # affiche un message de type "saisie" où on entre une chaîne de caractères, avec interface graphique
{
	whiptail --title "$1" --inputbox "$2" 10 50 3>&1 1>&2 2>&3; 
}

listerContenuCpp() # stock QUE les fichiers ".cc" et ".cpp" dans un autre fichiers
{
	ls . | egrep \(*.cpp$\|*.cc$\) | cut -d'.' -f1 > contenuRep.fichier  #stock les .cc et .cpp du rep courant dans un fichier 
	# basename -a $(cat contenuRep.fichier)
}

renommerFichier() # permet de renommer un fichier
{
	touch tmp1 tmp2
	
	echo $1 > tmp1 # on est obligé de créer 2 fichiers temporaires pour vérifier si leurs noms sont identiques
	echo $2 > tmp2 # sans ça, la commande ci dessous aurait affiché le contenu des fichiers passé en parametres
	
	FIC1=$(cat tmp1 | cut -d'.' -f1);
	FIC2=$(cat tmp2 | cut -d'.' -f1);
	
	if [ FIC1 != FIC2 ]
	then
		mv "$1" "$2";
		# if [ $? -eq 0 ] # si tout s'est bien passé
		# then
		# showMsgScreen "Renommer fichier" "SUCCÈS"
		# else # sinon, on affiche le code d'erreur
		#	echo "erreur numéro $?, arrêt du script"
		#	exit 1
		# fi
	fi
	rm -f tmp1 tmp2 # on supprimes les fichiers, qui à ce stade sont inutiles
	
}

repCourant() # créée un dossier pour y stocker les fichiers que le script va générer afin de ne pas "polluer" le bureau
{
	# ls -l . | grep "^d" | cut -d':' -f2 | cut -d' ' -f2 | sed '/^$/d' > fichier.dossier # met tous les dossiers du rep courant dans un fichier
	
	if [ "$REP_COURANT" = "$REP_PERS" ] # si on se trouve dans le répertoire perso ### BUG ###
	then
		if ! [ -d NEW_REP ] # et si le répertoire n'existe pas
		then
			mkdir script_gestionnaire # on le créé !
			if [ $? = 0 ]
			then
				showMsgScreen "Support dossier" "Création de \"$NEW_REP\" avec succés" # création avec succès
			fi
		else # [ -d NEW_REP ]  sinon, si le répertoire éxiste
			showInputScreen "Renommer dossier" "Entrer un nom de dossier : " > getInput.dossier
			while [[ -d "$(cat getInput.dossier)" ]] # tant que le dossier existe, demander de saisir un autre nom
			do
				showMsgScreen "Renommer dossier : " "Le dossier \"$(cat getInput.dossier)\" existe déjà. Refaire :"
				showInputScreen "Renommer dossier"  "Entrer un nom de dossier valide : " > getInput.dossier
			done
			mkdir "$(cat getInput.dossier)"
			if [ $? -eq 0 ]
			then
				showMsgScreen "Créer dossier" "Dossier \"$(cat getInput.dossier)\" créée avec succès ! "
			fi
		fi
	
		#showMsgScreen "HALT" "Vous vous situez dans ce répertoire : \"$(pwd)\" ! "
		#echo "Ok."
	fi
				
}

listerFichiersAllType() # liste TOUS les fichiers (toutes extension confondues)
{
	# voir aussi: echo "Il y a $(wc -l fichiers.dat | cut -d' ' -f1) fichier(s) dans /$(basename $(pwd))"
	find . -maxdepth 1 -type f | cut -d'/' -f2 > fichiers.dat
	echo "$(wc -l fichiers.dat | cut -d' ' -f1)" >> fichiers.dat # par convention, la dernière ligne contient le nombre de fichiers
}

compterFichiersDiff() # principe: on fais un ls avant/après l'éxec du script --> compare les fichiers anciens/nouveaux --> déplacer les fichiers
{
	# RAPPEL : syntaxe de diff : > "fichier contenu dans $2 mais pas $1"
	# ------------------------ : < "fichier contenu dans $1 mais pas $2
	 diff "$1" "2" | grep "^>" | cut -d' ' -f2
}

###############################################################################################################


############################## FONCTIONS (fonctionnalités du script) ##########################################

voirFichier() # affiche le contenu du fichier passé en paramètre avec le pageur less
{
	less $1
}

editerFichier() # ouvre le fichier avec nano
{
	nano -i "$1" # -i = auto indentation
}

genererFichier() # compile le fichier .cc/.cpp en -o
{
	# FONCTION INCOMPLETE ---> Il faut pas tout faire d'un coup, revoir pour amélioration
	# apres la commande g++ --> penser à rediriger la sortie d'erreur dans un fichier genereFichier.cerr par exemple
	# (pour proposer en consequence du contenu de ce fichier, si oui ou non on affiche "Voulez-vous voir les erreurs")
	
	if [ -f "$1$extension" ] # si le fichier (avec extension) existe, alors on génère le fichier objet
	then
		showMsgScreen "TEST" "Vous manipulez ce fichier : \"$1$extension\" "
		g++ -Wall -c "$1$extension" -o "$1.o" 2> getOutput.cerr #### on créée le fichier objet ici, ET, on redirige les erreurs dans un fichier
 		if [ $? = 0 ]
		then
			showMsgScreen "Succès !" "Le fichier \"$1.o\" a bien été généré. "
		else
			showMsgScreen "ERREUR : $?" "Des erreurs sont survenues lors de la création du fichier \"$1.o\" "
			if (showChoiceScreen "ERREUR : $?" "Oui" "Non" "Voulez-vous voir les erreurs ?")
			then
				showMsgScreen "ERREUR : $?" "$(cat getOutput.cerr)"
			fi
		fi
		
	else # sinon il y a une erreur, et donc on quitte le script
		echo "Erreur: pas de fichier $1.cc"
		exit 1	
	fi
}

lancerFichier()
{
	# pour connaitre les droits, voir : getfacl a.out | grep "::" | cut -d':' -f3
	# ATTENTION, dans le cas juste au-dessus, "a.out" est l'éxécutable, et il se trouve que sur ma machine, après compilation, il a les droits de type 775
	
	# Une fois le fichier compilé (si tout marche bien), affecter l'éxéctable à la variable $FICHIER_EDIT
	if [ -f "$1.o" ] # si le fichier objet a bien été créée
	then
		clear
		g++ "$1.o" -o "$1" ; "./$1" ### on lance alors le programme (renommé en son nom de base sans extension, au lieu de "a.out")
		echo "Tapez \"q\" pour revenir au menu. "; read reponse
		while [ $reponse != "q" ]
		do
			echo "Tapez \"q\" pour revenir au menu."; read reponse
		done
	else 
		showMsgScreen "Lançer : $? " "Aucun fichier objet associé à \"$1$extension\" "
	fi
}

debugguerFichier()
{
	# Faudras vérifier avant de lancer gdb, que $FICHIER_EDIT correspond bien à l'éxécutable en question
	
	# Si oui, on fait ce que doit faire la fonction, sinon, on affich
	# problème avec la commande gdb. Pas aussi simple qu'il n'y paraît... (voir : créer un fichier avec les breakpoints souhaités !?)
	
	if [ -x "$1" ] # test les droits d'éxécution sur le fichier
	then
		showMsgScreen "Debug : \"$1\" " "Ce fichier est bien un fichier de type éxécutable"
		showMsgScreen "Debug : \"gdb\" " "Lancement imminent de \"gdb\".\nTaper \"quit\" pour sortir. "
		clear
		gdb "$1" 2>> /dev/null
	else # si il n'a pas les droits --> chmod !
		showMsgScreen "Debug : \"$1\" " "Ce fichier n'est pas de type éxécutable. Des droits d'éxécution et de lecture vont lui être attribués."
		chmod 555 "$1"
		showMsgScreen "Debug : \"gdb\" " "Lancement imminent de \"gdb\".\nTaper \"quit\" pour sortir. "
		clear
		gdb "$1"
	fi
}

imprimerFichier()
{
	# d'abord convertir en pdf puis imprimer
	# vérifier que le fichier ne soit pas vide
	
	if [ -s "$1" ] 
	then
		a2ps "$1" -o "$1.ps" 2>> /dev/null
		ps2pdf "$1.ps"
		
		rm -f "$1.ps"
	else
		showMsgScreen "Imprimer : ERREUR" "Le fichier \"$1$extension\" est vide, impression annulé. "
	fi
}

shell()
{
	showMsgScreen "Shell" "Un prompt va s'ouvrir, taper \"exit\" pour quitter"
	clear
	bash
	# export PS1="User "# lançe un autre shell (voir aussi: xterm)
}
###############################################################################################################


################################################ DÉBUT SCRIPT  ################################################

CONTINUER_SCRIPT=true; ### Pour gestion boucle (sortir/entrer)

extension="" # on affecteras cette variable plus tard
extcpp=".cpp"
extcc=".cc"

showMsgScreen "Bienvenue" "Script réalisé par Rémi Lasvenes et Alexandre Bouyssou";

if [[ $1 = "--help" || $1 = "-h" || $1 = "--aide" ]] 
then
	showMsgScreen "AIDE $1" "$ $0 [fichier] \nfichier est un argument facultatif.\nIl correspond à un fichier sans extension. \nSi aucun argument, \"temp.cpp\" seras généré."
	exit 0
fi

if [ $# -eq 0 ]
then
	genTemplate
	extension="$extcpp"
	FICHIER_EDIT="temp" # le template seras un fichier .cpp donc on initialise la variable en conséquence
	if (showMsgScreen "Renommer" "Un template vient d'être créée, donnez lui un nom.")
	then
		showInputScreen "Renommer template" "Renommer" "nope" "Donner un nom à votre fichier : " > getInput.choix
		while [ -f $(cat getInput.choix).cpp -o $(wc -c getInput.choix| cut -d' ' -f1) = 0 ]
		do
			if [ $(wc -c getInput.choix | cut -d' ' -f1) = 0 ]
			then
				showInputScreen " Renommer template" "Nom invalide : châine de caractères nulle.\nRefaire : " > getInput.choix
			else
				showInputScreen "Renommer template" "Le fichier \"$(cat getInput.choix)\" existe déjà." > getInput.choix
			fi
			
		done
		renommerFichier "$FICHIER_EDIT$extcpp" "$(cat getInput.choix)".cpp
		showMsgScreen "Fichier renommé" "Fichier renommé en \"$(cat getInput.choix).cpp\" avec succès !"
		extension="$extcpp" # ".$(cat getInput.choix | cut -d'.' -f2)"
		
		FICHIER_EDIT="$(cat getInput.choix | cut -d'.' -f1)"
		
	fi
elif [ $# -eq 1 ]
then
	if [ -f "$1$extcpp" ] 
	then
		showMsgScreen "temp" "$1 est un fichier $extcpp"
		extension="$extcpp"
		FICHIER_EDIT="$1"
	elif [ -f "$1$extcc" ]
	then
		showMsgScreen "$1" "$1 est un fichier $extcc"
		extension="$extcc"
		FICHIER_EDIT="$1"
	else
		showMsgScreen "ERREUR ! " "Il ne s'agit pas d'un fichier .cc ou .cpp.\nLe script va s'arrêter.\n\"$1\" est peut être inexistant. "
		
		exit 1
	fi
	# showMsgScreen "Argument $1" "Vous avez lançé ce script avec comme argument \"$FICHIER_EDIT\" "
else
	# si il y a + d'un argument, on arrête le script, ERREUR FATALE
	showMsgScreen "ERREUR ARGUMENT !" "Trop d'arguments ! \nLe script va s'arrêter."
	exit 1
fi

while $CONTINUER_SCRIPT # tant que l'on ne choisit pas "quitter" alors on continue d'afficher le menu
do
	genMenu FICHIER_EDIT ;
	case $(cat getChoix.txt) in # selon le choix de l'utilisateur, agir en conséquences
	1)
		voirFichier "$FICHIER_EDIT$extension"
		;;
	2)
		editerFichier "$FICHIER_EDIT$extension"
		;;
	3)  
		genererFichier "$FICHIER_EDIT"
		;;
	4)
		lancerFichier "$FICHIER_EDIT"
		;;
	5)
		debugguerFichier "$FICHIER_EDIT"
		;;
	6)
		imprimerFichier "$FICHIER_EDIT$extension"
		;;
	7)
		shell
		;;
	8)
		showMsgScreen "QUITTER" "Au revoir..."
		rm -f getChoix.txt getOutput.cerr # quand l'utilisateur quitte le script, on supprime les fichiers encombrants / inutiles
		CONTINUER_SCRIPT=false
		clear
		;;
	*)
		echo "FATAL ERROR" # si jamais le choix de l'utilisateur n'était pas parmis les autres, alors on arrête le script
		exit 1
		;;
	esac
done

################################################## FIN SCRIPT #################################################


################################################ NOTES PERSOS ################################################# 

# Voir commande madplay/aplay/play et amixer

	# syntaxe commande amixer : amixer -q -c 0 sset "Master" mute/unmute  ---> pour tester le son muet ou pas
	
	
	# syntaxe commande madplay : madplay fichier.mp3 2>> /dev/null pour bavardage
