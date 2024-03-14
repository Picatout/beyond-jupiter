# Beyond-Jupiter 

À fin des années 70 et durant les années 80 les ordinateurs personnels basés sur des processeurs 8 bits comme le 6502 et le Z80 incorporaient tous dans une mémoire ROM un interpréteur BASIC. Cependant il y a eu une exception le [Juputer ACE](https://en.wikipedia.org/wiki/Jupiter_Ace) mit en marché en 1982. Ce dernier incorporait un interpréteur Forth. Malheureusement ce ne fut pas un succès commercial.  

Le **Jupiter-ACE** a été mis au point par des ingénieurs qui avaient travaillé sur les **ZX80** et **SX81** de Sinclair. Ils ont formé leur propre compagnie [Jupiter Canlab limited](https://en.wikipedia.org/wiki/Jupiter_Cantab). Cet ordinateur utilisait aussi un processeur **Z80**.

Depuis 1982 la technologie a grandement progressée ainsi que l'exploration spatiale. Plusieurs sondes se sont rendues au delà de Jupiter et certaines ont même quittées le système solaire. 

**Beyond-Jupiter** est un ordinateur basé sur un processeur 32 bits Cortex-M4 avec unitée en virgule flottante de 32 bits incorporé. Comme le [Juputer ACE](https://en.wikipedia.org/wiki/Jupiter_Ace) il incorpore un interpréteur Forth en mémoire FLASH. Pour l'essentiel cet interpréteur respecte le standard [Forth 2012](https://forth-standard.org/).


# Conception matérielle

Le coeur de cet ordinateur est une carte black-pill comprenant un processeur **STM32F411CEU6** et une mémoire FLASH de **16 MO** utilisée pour le système de fichier.

## BLACK-PILL 

![black-pill](docs/STM32F411CEU6_WeAct_Black_Pill_V3.0-2.jpeg)

* MCU  STM32F411CEU6
    * mémoire FLASH 512Ko
    * mémoire RAM 128ko 
    * Fclk maximal  100Mhz 

![dessous](docs/STM32F411CEU6_WeAct_Black_Pill_V3.0-3.jpg) 

La carte que j'ai en main a les composants C15 (100nF) et U3 (25Q128JVSQ, mémoire flash SPI de 16Mo) installés.

## Pinout

![board pinout](docs/STM32F4x1_PinoutDiagram_RichardBalint.png)


## Affichage Vidéo 

* Sortie NTSC composite 
* graphiques  
    * graphique 320x200 pixels 
    * 16 niveaux de gris 
* texte 
    * 25 lignes 
    * 53 charactères par ligne

* Clavier PS/2

* Audio 1 tonalité de fréquence et durée variables.

