################################################################################
#                  Fonctions d'affichage et d'entrée clavier                   #
################################################################################

# Ces fonctions s'occupent de l'affichage et des entrées clavier.
# Il n'est pas n cessaire de les modifier.!!!

.data

# Tampon d'affichage du jeu 256*256 de manière linéaire.

frameBuffer: .word 0 : 1024  # Frame buffer

# Code couleur pour l'affichage
# Codage des couleurs 0xwwxxyyzz où
#   ww = 00
#   00 <= xx <= ff est la couleur rouge en hexadécimal
#   00 <= yy <= ff est la couleur verte en hexadécimal
#   00 <= zz <= ff est la couleur bleue en hexadécimal

colors: .word 0x00000000, 0x00ff0000, 0xff00ff00, 0x00396239, 0x00ff00ff, , 0x00ffffff
.eqv black 0
.eqv red   4
.eqv green 8
.eqv greenV2  12
.eqv rose  16
.eqv white 20


# Dernière position connue de la queue du serpent.

lastSnakePiece: .word 0, 0

.text
j main

############################# printColorAtPosition #############################
# Paramètres: $a0 La valeur de la couleur
#             $a1 La position en X
#             $a2 La position en Y
# Retour: Aucun
# Effet de bord: Modifie l'affichage du jeu
################################################################################

printColorAtPosition:
lw $t0 tailleGrille
mul $t0 $a1 $t0
add $t0 $t0 $a2
sll $t0 $t0 2
sw $a0 frameBuffer($t0)
jr $ra

################################ resetAffichage ################################
# Paramètres: Aucun
# Retour: Aucun
# Effet de bord: Réinitialise tout l'affichage avec la couleur noir
################################################################################

resetAffichage:
lw $t1 tailleGrille
mul $t1 $t1 $t1
sll $t1 $t1 2
la $t0 frameBuffer
addu $t1 $t0 $t1
lw $t3 colors + black

RALoop2: bge $t0 $t1 endRALoop2
  sw $t3 0($t0)
  add $t0 $t0 4
  j RALoop2
endRALoop2:
jr $ra

################################## printSnake ##################################
# Paramètres: Aucun
# Retour: Aucun
# Effet de bord: Change la couleur de l'affichage aux emplacement ou se
#                trouve le serpent et sauvegarde la dernière position connue de
#                la queue du serpent.
################################################################################

printSnake:
subu $sp $sp 12
sw $ra 0($sp)
sw $s0 4($sp)
sw $s1 8($sp)

lw $s0 tailleSnake
sll $s0 $s0 2
li $s1 0

lw $a0 colors + greenV2
lw $a1 snakePosX($s1)
lw $a2 snakePosY($s1)
jal printColorAtPosition
li $s1 4

PSLoop:
bge $s1 $s0 endPSLoop
  lw $a0 colors + green
  lw $a1 snakePosX($s1)
  lw $a2 snakePosY($s1)
  jal printColorAtPosition
  addu $s1 $s1 4
  j PSLoop
endPSLoop:

subu $s0 $s0 4
lw $t0 snakePosX($s0)
lw $t1 snakePosY($s0)
sw $t0 lastSnakePiece
sw $t1 lastSnakePiece + 4

lw $ra 0($sp)
lw $s0 4($sp)
lw $s1 8($sp)
addu $sp $sp 12
jr $ra

################################ printObstacles ################################
# Paramètres: Aucun
# Retour: Aucun
# Effet de bord: Change la couleur de l'affichage aux emplacement des obstacles.
################################################################################

printObstacles:
subu $sp $sp 12
sw $ra 0($sp)
sw $s0 4($sp)
sw $s1 8($sp)

lw $s0 numObstacles
sll $s0 $s0 2
li $s1 0

POLoop:
bge $s1 $s0 endPOLoop
  lw $a0 colors + red
  lw $a1 obstaclesPosX($s1)
  lw $a2 obstaclesPosY($s1)
  jal printColorAtPosition
  addu $s1 $s1 4
  j POLoop
endPOLoop:

lw $ra 0($sp)
lw $s0 4($sp)
lw $s1 8($sp)
addu $sp $sp 12
jr $ra

################################## printCandy ##################################
# Paramètres: Aucun
# Retour: Aucun
# Effet de bord: Change la couleur de l'affichage à l'emplacement du bonbon.
################################################################################

printCandy:
subu $sp $sp 4
sw $ra ($sp)

lw $a0 colors + rose
lw $a1 candy
lw $a2 candy + 4
jal printColorAtPosition

lw $ra ($sp)
addu $sp $sp 4
jr $ra

eraseLastSnakePiece:
subu $sp $sp 4
sw $ra ($sp)

lw $a0 colors + black
lw $a1 lastSnakePiece
lw $a2 lastSnakePiece + 4
jal printColorAtPosition

lw $ra ($sp)
addu $sp $sp 4
jr $ra

################################## printGame ###################################
# Paramètres: Aucun
# Retour: Aucun
# Effet de bord: Effectue l'affichage de la totalité des éléments du jeu.
################################################################################

printGame:
subu $sp $sp 4
sw $ra 0($sp)

jal eraseLastSnakePiece
jal printSnake
jal printObstacles
jal printCandy

lw $ra 0($sp)
addu $sp $sp 4
jr $ra

############################## getRandomExcluding ##############################
# Paramètres: $a0 Un entier x | 0 <= x < tailleGrille
# Retour: $v0 Un entier y | 0 <= y < tailleGrille, y != x
################################################################################

getRandomExcluding:
move $t0 $a0
lw $a1 tailleGrille
li $v0 42
syscall
beq $t0 $a0 getRandomExcluding
move $v0 $a0
jr $ra

########################### newRandomObjectPosition ############################
# Description: Renvoie une position aléatoire sur un emplacement non utilisé
#              qui ne se trouve pas devant le serpent.
# Paramètres: Aucun
# Retour: $v0 Position X du nouvel objet
#         $v1 Position Y du nouvel objet
################################################################################

newRandomObjectPosition:
subu $sp $sp 4
sw $ra ($sp)

lw $t0 snakeDir
or $t0 0x2
bgtz $t0 horizontalMoving
li $v0 42
lw $a1 tailleGrille
syscall
move $t8 $a0
lw $a0 snakePosY
jal getRandomExcluding
move $t9 $v0
j endROPdir

horizontalMoving:
lw $a0 snakePosX
jal getRandomExcluding
move $t8 $v0
lw $a1 tailleGrille
li $v0 42
syscall
move $t9 $a0
endROPdir:

lw $t0 tailleSnake
sll $t0 $t0 2
la $t0 snakePosX($t0)
la $t1 snakePosX
la $t2 snakePosY
li $t4 0

ROPtestPos:
bge $t1 $t0 endROPtestPos
lw $t3 ($t1)
bne $t3 $t8 ROPtestPos2
lw $t3 ($t2)
beq $t3 $t9 replayROP
ROPtestPos2:
addu $t1 $t1 4
addu $t2 $t2 4
j ROPtestPos
endROPtestPos:

bnez $t4 endROP

lw $t0 numObstacles
sll $t0 $t0 2
la $t0 obstaclesPosX($t0)
la $t1 obstaclesPosX
la $t2 obstaclesPosY
li $t4 1
j ROPtestPos

endROP:
move $v0 $t8
move $v1 $t9
lw $ra ($sp)
addu $sp $sp 4
jr $ra

replayROP:
lw $ra ($sp)
addu $sp $sp 4
j newRandomObjectPosition

################################# getInputVal ##################################
# Paramètres: Aucun
# Retour: $v0 La valeur 122 z 0 (haut), 100 d 1 (droite), 115 s 2 (bas), q 3 (gauche), 4 erreur
################################################################################

getInputVal:
lw $t0 0xffff0004
li $t1 122
beq $t0 $t1 GIhaut
li $t1 115
beq $t0 $t1 GIbas
li $t1 113
beq $t0 $t1 GIgauche
li $t1 100
beq $t0 $t1 GIdroite
li $v0 4
j GIend

GIhaut:
li $v0 0
j GIend

GIdroite:
li $v0 1
j GIend

GIbas:
li $v0 2
j GIend

GIgauche:
li $v0 3

GIend:
jr $ra

################################ sleepMillisec #################################
# Paramètres: $a0 Le temps en milli-secondes qu'il faut passer dans cette
#             fonction (approximatif)
# Retour: Aucun
################################################################################

sleepMillisec:
move $t0 $a0
li $v0 30
syscall
addu $t0 $t0 $a0

SMloop:
bgt $a0 $t0 endSMloop
li $v0 30
syscall
j SMloop

endSMloop:
jr $ra

##################################### main #####################################
# Description: Boucle principal du jeu
# Paramètres: Aucun
# Retour: Aucun
################################################################################

main:

# Initialisation du jeu

#jal resetAffichage
jal newRandomObjectPosition
sw $v0 candy
sw $v1 candy + 4

# Boucle de jeu

mainloop:

jal getInputVal
move $a0 $v0
jal majDirection
jal updateGameStatus
jal conditionFinJeu
bnez $v0 gameOver
jal printGame
li $a0 500
jal sleepMillisec
j mainloop

gameOver:
jal affichageFinJeu
li $v0 10
syscall

################################################################################
#                                Partie Projet                                 #
################################################################################

# À vous de jouer !

.data

tailleGrille:  .word 16        # Nombre de case du jeu dans une dimension.

# La tête du serpent se trouve à (snakePosX[0], snakePosY[0]) et la queue à
# (snakePosX[tailleSnake - 1], snakePosY[tailleSnake - 1])
tailleSnake:   .word 1         # Taille actuelle du serpent.
snakePosX:     .word 0 : 1024  # Coordonnées X du serpent ordonné de la tête à la queue.
snakePosY:     .word 0 : 1024  # Coordonnées Y du serpent ordonné de la t.

# Les directions sont représentés sous forme d'entier allant de 0 à 3:
snakeDir:      .word 1         # Direction du serpent: 0 (haut), 1 (droite)
                               #                       2 (bas), 3 (gauche)
numObstacles:  .word 0         # Nombre actuel d'obstacle présent dans le jeu.
obstaclesPosX: .word 0 : 1024  # Coordonnées X des obstacles
obstaclesPosY: .word 0 : 1024  # Coordonnées Y des obstacles
candy:         .word 0, 0      # Position du bonbon (X,Y)
scoreJeu:      .word 0         # Score obtenu par le joueur

.text

################################# majDirection #################################
# Param tres: $a0 La nouvelle position demande par l'utilisateur. La valeur
#                  tant le retour de la fonction getInputVal.
# Retour: Aucun
# Effet de bord: La direction du serpent à été mise à jour.
# Post-condition: La valeur du serpent reste intacte si une commande ill gale
#                 est demand e, i.e. le serpent ne peut pas faire un demi-tour 
#                 (se retourner en un seul tour. Par exemple passer de la 
#                 direction droite   gauche directement est impossible (un 
#                 serpent n'est pas une chouette)
################################################################################

majDirection:

lw $t1 snakeDir # Charge dans le registre t1 le contenu de la variable snakeDir(l'ancienne direction)

li $t0 0 # Charge dans le registre t0 la valeur de la direction haut
beq $a0 $t0 TestIllegale

li $t0 1 # Charge dans le registre t0 la valeur de la direction droite
beq $a0 $t0 TestIllegale

li $t0 2 # Charge dans le registre t0 la valeur de la direction bas
beq $a0 $t0 TestIllegale

li $t0 3 # Charge dans le registre t0 la valeur de la direction gauche
beq $a0 $t0 TestIllegale

j end

# On utilise cette m thode puisqu'elle est plus efficace car si on aurait fait pour chaque cas de la variable snakeDirection cela aurait ete repetitif
TestIllegale:
li $t2 2
rem $t3 $t0 $t2 # On calcul le reste de la division de la nouvelle direction par 2 pour voir si c'est pair(ordonn e) ou impair(abscisse)
rem $t4 $t1 $t2 # On calcul le reste de la division de l'ancienne direction par 2 pour voir si c'est pair ou impair
beq $t3 $t4 end # SI les reste sont  gaux on retourne au main puisque si le reste des 2 divisions soit impair/pair pour ancienne nouvelle 
#                 pour l'axe ordonn e/abscisse c'est illegale donc on ne met pas   jour la direction du snake 
#                 SINON on met   jour la direction du snake et on retourne au main avec la direction   jour
sw $a0 snakeDir
end:
jr $ra

# En haut 0, ... en bas 2, ... à gauche 3, ... à droite 1
############################### updateGameStatus ###############################
# Paramètres: Aucun
# Retour: Aucun
# Effet de bord: L'état du jeu est mis à jour d'un pas de temps. Il faut donc :
#                  - Faire bouger le serpent
#                  - Tester si le serpent   manger le bonbon
#                  - Si oui d placer le bonbon et ajouter un nouvel obstacle
################################################################################

updateGameStatus:

# jal hiddenCheatFunctionDoingEverythingTheProjectDemandsWithoutHavingToWorkOnIt
#FAIRE AVANC  LE SERPENT
# D placement en fonction de la direction
lw $t0 snakeDir   # Chargement de la direction actuelle du serpent dans $t0

# Si la direction est vers la droite (1)
beq $t0 1 PosXDroite

# Si la direction est vers le bas (2)
beq $t0 2 PosYBas

# Si la direction est vers la gauche (3)
beq $t0 3 PosXGauche

# Si la direction est vers le haut (0)
beq $t0 0 PosYHaut

# Saut   la fin de la fonction si la direction n'est pas valide
j end

# Si la direction est vers la droite
PosXDroite:
lw $t0 snakePosY  # Chargement de la position Y actuelle du serpent dans $t0
addi $t1 $t0 1    # Incr mentation de la position Y (d placement vers la droite)
j AjoutY          # Saut   la partie de mise   jour des positions

# Si la direction est vers la gauche
PosXGauche:
lw $t0 snakePosY  # Chargement de la position Y actuelle du serpent dans $t0
subi $t1 $t0 1    # D cr mentation de la position Y (d placement vers la gauche)
j AjoutY          # Saut   la partie de mise   jour des positions

# Si la direction est vers le bas
PosYBas:
lw $t0 snakePosX  # Chargement de la position X actuelle du serpent dans $t0
addi $t1 $t0 1    # Incr mentation de la position X (d placement vers le bas)
j AjoutX          # Saut   la partie de mise   jour des positions

# Si la direction est vers le haut
PosYHaut:
lw $t0 snakePosX  # Chargement de la position X actuelle du serpent dans $t0
subi $t1 $t0 1    # D cr mentation de la position X (d placement vers le haut)
j AjoutX          # Saut   la partie de mise   jour des positions

AjoutX: #Stocke la nouvelle position X du serpent apr s le d placement

sw $t1 snakePosX  # Stocke la nouvelle position X $t1 dans la variable snakePosX


lw $t1 snakePosY  # Charge la position Y actuelle du serpent dans $t1
lw $t2 tailleSnake  # Charge la taille du serpent dans $t2
li $t3 1  # Initialisation de l'indice   1
li $t4 4  # Taille en octets d'un entier

# Boucle pour mettre   jour les positions sur l'axe X
PourX:
slt $t5 $t3 $t2  # V rifie si l'indice de boucle est inf rieur   la taille du serpent
beqz $t5 Nourriture  # Si l'indice atteint la taille du serpent, saute   la partie Nourriture

# Calcul de l'indice pour acc der a la position ac du corps du serpent
mul $t5 $t3 $t4
lw $t6 snakePosX($t5)  # Charge la valeur snakePosX[i] du serpent dans $t6 
lw $t7 snakePosY($t5)  # Charge la valeur snakePosY[i] du serpent dans $t7
sw $t6 0($sp)          # Stocke la valeur dans la pile pour utilisation ult rieure snakePosX[i]
sw $t7 4($sp)          # Stocke la valeur dans la pile pour utilisation ult rieure snakePosY[i]

# Mise   jour des positions
sw $t0 snakePosX + 0($t5)  # Stocke la nouvelle position X calcul e snakePosX[i] = ancienne position de snakePosX[i-1]
sw $t1 snakePosY + 0($t5)  # Stocke la position Y calcul e = snakePosY[i] = ancienne position de snakePosY[i-1]

addi $t3 $t3 1  # Incr mente l'indice de boucle
lw $t0 ($sp)    # R cup re l'ancienne position X snakePosX[i] du serpent depuis la pile
lw $t1 4($sp)   # R cup re l'ancienne position Y snakePosY[i] du serpent depuis la pile
j PourX         # Saute au d but de la boucle


AjoutY: #Stocke la nouvelle position Y du serpent apr s le d placement

sw $t1 snakePosY  # Stocke la nouvelle position Y $t1 dans la variable snakePosY

lw $t1 snakePosX  # Charge la position X actuelle du serpent dans $t1
lw $t2 tailleSnake  # Charge la taille du serpent dans $t2
li $t3 1  # Initialisation de la variable de boucle   1
li $t4 4  # Taille en octets d'un entier

#  Boucle pour mettre   jour les positions sur l'axe Y
PourY:
slt $t5 $t3 $t2  # V rifie si l'indice de boucle est inf rieur   la taille du serpent
beqz $t5 Nourriture  # Si l'indice atteint la taille du serpent, saute   la partie Nourriture

# Calcul de l'indice pour acc der aux positions du corps du serpent
mul $t5 $t3 $t4
lw $t6 snakePosY($t5)  # Charge la valeur snakePosY[i] du serpent dans $t6
lw $t7 snakePosX($t5)  # Charge la valeur snakePosX[i] du serpent dans $t7

sw $t6 0($sp)  # Stocke la valeur dans la pile pour utilisation ult rieure
sw $t7 4($sp)  # Stocke la valeur dans la pile pour utilisation ult rieure

# Mise   jour des positions
sw $t0 snakePosY + 0($t5)  # Stocke la nouvelle position Y calcul e snakePosY[i] = ancienne position de snakePosY[i-1]
sw $t1 snakePosX + 0($t5)  # Stocke la nouvelle position X calcul e snakePosX[i] = ancienne position de snakePosX[i-1]

addi $t3 $t3 1  # Incr mente l'indice de boucle
lw $t0 ($sp)  # R cup re l'ancienne position Y snakePosY[i] du serpent depuis la pile
lw $t1 4($sp) # R cup re l'ancienne position X snakePosX[i] du serpent depuis la pile
j PourY  # Saute au d but de la boucle


#Manger la nourriture
Nourriture:
lw $t0 candy  # Charge la position X de la nourriture dans $t0
lw $t2 candy + 4  # Charge la position Y de la nourriture dans $t2
lw $t3 snakePosX  # Charge la position X de la t te du serpent dans $t0
lw $t4 snakePosY # Charge la position Y de la t te du serpent dans $t0
beq $t0 $t3 testY # Si la position X de la nourriture est  gale   celle de la t te du serpent, saute   testY
j end  # Sinon, va   la fin

testY:

beq $t2 $t4 AjoutNourriture # Si la position Y de la nourriture est  gale   celle de la t te du serpent, saute   AjoutNourriture
j end # Sinon, va   la fin

AjoutNourriture:
sw $ra ($sp) # Sauvegarde l'adresse de retour dans la pile
jal newRandomObjectPosition # Appelle la fonction pour g n rer une nouvelle position pour la nourriture
sw $v0 candy # Stocke la nouvelle position X de la nourriture dans candy
sw $v1 candy + 4 # Stocke la nouvelle position Y de la nourriture dans candy + 4 octets
lw $ra ($sp) # Restaure l'adresse de retour depuis la pile

AjoutTaille:
lw $t0 tailleSnake # Charge la taille actuelle du serpent dans $t0
addi $t0 $t0 1 # Incr mente la taille du serpent
sw $t0 tailleSnake # Stocke la nouvelle taille dans tailleSnake

AjoutObstacle:
lw $t2 numObstacles # Charge le nombre actuel d'obstacles dans $t2
addi $t2 $t2 1 # Incr mente le nombre d'obstacles
sw $t2 numObstacles # Stocke le nouveau nombre d'obstacles
sw $t2 scoreJeu # Met   jour le score du jeu
li $t3 4 # Charge la taille d'un entier dans $t3
subi $t1 $t2 1 # Calcule l'indice du dernier obstacle ajout 
mul $t5 $t1 $t3  # Multiplie l'indice par la taille d'un entier

sw $ra ($sp)
jal newRandomObjectPosition

sw $v0 obstaclesPosX + 0($t5)
sw $v1 obstaclesPosY + 0($t5)
lw $ra ($sp)
j end

############################### conditionFinJeu ################################
# Paramètres: Aucun
# Retour: $v0 La valeur 0 si le jeu doit continuer ou toute autre valeur sinon.
################################################################################

conditionFinJeu:

li $v0 0

# R cup ration des coordonn es de la t te du serpent ainsi que la taille de la grille
lw $t0 snakePosX
lw $t1 snakePosY
lw $t2 tailleGrille
bltz $t1 ModifieRetour
bltz  $t0 ModifieRetour
bge $t0 $t2 ModifieRetour
bge $t1 $t2 ModifieRetour

# V rification de la collision avec le serpent lui-m me
# R cup ration de la taille du snake et initialisation de l'indice pour la boucle

lw $t2 tailleSnake
li $t3 1 # L'indice de la boucle commence par 1 car l'indice 0 correspond a la t te du serpent
li $t4 4 # Taille d'un int (en octets)

Pour:
# V rification : Si l'indice i ($t3) = la taille du serpent ($t2) alors sort de la boucle et v rifie la collision avec un obstacle. Sinon la boucle continue.
bge $t3 $t2 Obstacles
# Calcul de l'indice de la position actuelle du corps du serpent
# La multiplication par 4 est n cessaire car chaque  l ment du tableau occupe 4 octets puisque un int c'est 4 octets
mul $t5 $t3 $t4 #Le r sultat de la multiplication dans $t5
lw $t6 snakePosX($t5) # Chargement de la valeur de snakePosX[i]
lw $t7 snakePosY($t5) # Chargement de la valeur de snakePosY[i]
# Test de la collision sur l'axe X si c'est  gale on va test  si la partie du corps actuel et sur le meme axe des ordonn es
beq $t6 $t0 testQY
# Sinon incr mentation de l'indice et saut   l'it ration suivante de la boucle
addi $t3 $t3 1
j Pour
testQY:
# Test de la collision sur l'axe Y si c'est  gale on va saut  a la fonction ModifieRetour qui va indiquer la fin du jeu
beq $t7 $t1 ModifieRetour
# Sinon incr mentation de l'indice et saut   l'it ration suivante de la boucle
addi $t3 $t3 1
j Pour

Obstacles:

# V rification de la collision avec un obstacle
# R cup ration du nombre d'obstacles et initialisation de l'indice pour la boucle

lw $t2 numObstacles
li $t3 0
li $t4 4 # Taille d'un int (en octets)
PourObstacle:
beq $t3 $t2 end
mul $t5 $t3 $t4 #Le r sultat de la multiplication dans $t5
lw $t6 obstaclesPosX($t5) # l adresse = adresse obstaclesPosX + octet $t5
lw $t7 obstaclesPosY($t5) # l adresse = adresse obstaclesPosY + octet $t5

# Test de la collision sur l'axe X de la t te et obstacle[i] si c'est  gale on va test  si l'obstacle actuel et sur le m me axe des ordonn es
beq $t6 $t0 testOY
# Sinon incr mentation de l'indice et saut   l'it ration suivante de la boucle
addi $t3 $t3 1
j PourObstacle
testOY:
# Test de la collision sur l'axe Y si c'est  gale donc collision avec l'obstacle on va saut  a la fonction ModifieRetour qui va indiquer la fin du jeu
beq $t7 $t1 ModifieRetour
# Sinon incr mentation de l'indice et saut   l'it ration suivante de la boucle
addi $t3 $t3 1
j PourObstacle


ModifieRetour:
# La valeur de retour est modifi e   1 pour indiquer la fin du jeu
li $v0 1
# Retour   l'instruction appelante
jr $ra

############################### affichageFinJeu ################################
# Paramètres: Aucun
# Retour: Aucun
# Effet de bord: Affiche le score du joueur dans le terminal suivi d'un petit
#                mot gentil (Exemple : «Quelle pitoyable prestation!»).
# Bonus: Afficher le score en surimpression du jeu.
################################################################################

affichageFinJeu:
.data

phraseMéchante: .asciiz "Quelle pitoyable prestation ! "
phraseEncouragement: .asciiz "Dommage il fallait un peu plus de point pour  tre class  dans les fort ! "
phraseFélicitation: .asciiz "Wow vous  tes le meilleur des joueur que j'ai jamais connus ! "
.text
lw $t0 scoreJeu
beqz $t0 mechant
blt $t0 10 encouragement
j félicitation

mechant:
la $a0 phraseMéchante #adresse de la cha ne   afficher
j afficher

encouragement:
la $a0 phraseEncouragement #adresse de la cha ne   afficher
j afficher

félicitation:
la $a0 phraseFélicitation

afficher:
li $v0 4 #appel syst me 4: afficher une cha ne de caract re
syscall
move $a0 $t0
li $v0 1 #appel syst me 1: afficher un entier int
syscall
# Fin.
sw $ra ($sp)


jal resetAffichage

lw $a0 colors + rose
li $a1 7
li $a2 1
jal printColorAtPosition
li $a1 7
li $a2 2
jal printColorAtPosition
li $a1 8
li $a2 0
jal printColorAtPosition
li $a1 9
li $a2 0
jal printColorAtPosition
li $a1 10
li $a2 0
jal printColorAtPosition
li $a1 11
li $a2 0
jal printColorAtPosition
li $a1 9
li $a2 1
jal printColorAtPosition
li $a1 9
li $a2 2
jal printColorAtPosition
li $a1 8
li $a2 3
jal printColorAtPosition
li $a1 9
li $a2 3
jal printColorAtPosition
li $a1 10
li $a2 3
jal printColorAtPosition
li $a1 11
li $a2 3
jal printColorAtPosition


lw $a0 colors + red

li $a1 7
li $a2 4
jal printColorAtPosition
li $a1 8
li $a2 4
jal printColorAtPosition
li $a1 9
li $a2 4
jal printColorAtPosition
li $a1 9
li $a2 5
jal printColorAtPosition
li $a1 10
li $a2 5
jal printColorAtPosition
li $a1 11
li $a2 5
jal printColorAtPosition
li $a1 9
li $a2 6
jal printColorAtPosition
li $a1 7
li $a2 6
jal printColorAtPosition
li $a1 8
li $a2 6
jal printColorAtPosition
li $a1 9
li $a2 6
jal printColorAtPosition

lw $a0 colors + white

li $a1 7
li $a2 8
jal printColorAtPosition
li $a1 7
li $a2 9
jal printColorAtPosition
li $a1 8
li $a2 7
jal printColorAtPosition
li $a1 9
li $a2 7
jal printColorAtPosition
li $a1 10
li $a2 7
jal printColorAtPosition
li $a1 11
li $a2 7
jal printColorAtPosition
li $a1 9
li $a2 8
jal printColorAtPosition
li $a1 9
li $a2 9
jal printColorAtPosition
li $a1 8
li $a2 10
jal printColorAtPosition
li $a1 9
li $a2 10
jal printColorAtPosition
li $a1 10
li $a2 10
jal printColorAtPosition
li $a1 11
li $a2 10
jal printColorAtPosition

lw $a0 colors + green

li $a1 7
li $a2 11
jal printColorAtPosition
li $a1 8
li $a2 11
jal printColorAtPosition
li $a1 9
li $a2 11
jal printColorAtPosition
li $a1 10
li $a2 11
jal printColorAtPosition
li $a1 11
li $a2 11
jal printColorAtPosition

li $a1 7
li $a2 12
jal printColorAtPosition
li $a1 7
li $a2 13
jal printColorAtPosition
li $a1 11
li $a2 12
jal printColorAtPosition
li $a1 11
li $a2 13
jal printColorAtPosition
li $a1 8
li $a2 14
jal printColorAtPosition
li $a1 9
li $a2 14
jal printColorAtPosition
li $a1 10
li $a2 14
jal printColorAtPosition


lw $a0 colors + greenV2

li $a1 7
li $a2 15
jal printColorAtPosition
li $a1 8
li $a2 15
jal printColorAtPosition
li $a1 9
li $a2 15
jal printColorAtPosition
li $a1 10
li $a2 15
jal printColorAtPosition
li $a1 11
li $a2 15
jal printColorAtPosition
addi $t5 $t5 1


Fin:
lw $ra ($sp)
jr $ra