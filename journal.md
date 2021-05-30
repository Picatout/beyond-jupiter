2021-05-29

* Travail sur [float.f](float.f) à partir de l'article paru dans FORTH dimensions vol. IV, #1
2021-05-27

* Travail sur [float.s](float.s)

2021-05-26

* Travail sur [float.s](float.s)

2021-05-25

* Création et checkout sur branche **test** pour travailler sur [float.s](float.s)

* Travail sur [float.s](float.s)

* Ajout de **U>** 

* Ajout de **BIN** set set **BASE** to 2.

* Renommé  **NUMBER?** **INT?** 

* Retravaillé  **INT?**  pour utiliser **PARSE_DIGITS** comme facteur commun entre **FLOAT?** et **INT?** 

2021-05-24

* Travail sur [float.s](float.s)

* Factorisation de **BCD+** et ajout de **BCD1+**. 

* Ajout de **BCD-NEG** et **BCD-** .

* Ajout de **BCD>BIN** et **BIN>BCD** 

2021-05-23

* Travail sur [float.s](float.s)

* Déboger BCD+

2021-05-22

* Travail sur [float.s](float.s) référence [docs/Jupiter-Ace-ROM.asm](docs/Jupiter-Ace-ROM.asm) et 
[docs/JA-Ace4000-Manual-First-US-Edition.pdf](JA-Ace4000-Manual-First-US-Edition.pdf) chapitre 15.

2021-05-20

* added [test-bars.f](test-bars.f)

2021-05-19

* Ajout de **VLIST** et **UPPER** 

* Maintenant mots insensible à la casse. 

2021-05-17 

* Ajout de mots au vocabulaire.

    * **DO**, **LOOP** et **+LOOP** 
    
2021-05-16

* déboguage spi-flash.s

* Création mots **WC** et **MARK** 

2021-05-15

*  Transféré interface clavier sur PC14:15 pour résoudre conflit avec video output.

* Travail sur spi-flash.s

2021-05-14

* bogues à corrigés:
    * spi-flash.s ne fonctione pas. 
    * conflis entre video_output et ps2 keyboard.
    
2021-05-13 

* Travail sur spi-flash.s 

2021-05-10

* Travail sur **tvout.s** 

2021-05-09

* Travail sur interface utilisateur. Ajout de la détection d'interface par défaut sur PA8. 
    * PA8 low  LOCAL CONSOLE 
    * PA8 high SERIAL CONSOLE 

2021-05-08 

*  Ajout de commandes dans **ser-term.s**
    * **SER-CLS**
    * **SER-AT**
    * **ANSI-PARAM**
    * **ESC[**

2021-05-06

* Débogage de la console. 


2021-05-05

* Continué le travail de remodelage du système pour l'adapté à la commutation de console.

2021-05-04

* Restructuré interface utilisateur. 
    * les modules **tvout.s** et **ps2_kbd.s** définissent l'interface locale utilisant un moniteur **NTSC** et un clavier **PS2**.
    * Le module **ser-term.s** définie l'interface utilisateur via un émulateur de terminal sur PC.
    * Le mot **CONSOLE** permet de commuter entre les 2 interfaces: **SERIAL CONSOLE** pour la console à partir du PC  et **LOCAL CONSOLE** pour NTSC+PS2.

2021-05-03

* Travail sur ps2_kdb.s, modification du code et débogage.

2021-04-28

* Modifié **nvic_enable_irq* dans *init.s*.

2021-04-27

* Ajout de **KBD-RST** et **KBD-LED** 

* Ajout de **usec** for µseconds delay in init.s 

2021-04-25

* Ajout de **ASYNC-KEY** retourne l'état des touches asynchrones 

* Travail sur **INKEY**.

* Travail sur ps2-kbd.s 

2021-04-24

* travail sur ps2-kbd.s, ajout de **KEYCODE**, **KEY-ERR?**, **KEY-RST-ERR**.

* Travail dans init.s, ajout de **nvic_set_priority**, **nvic_enable_irq** et **nvic_disable_irq**. 

2021-04-23

* Ajout de **PRINT**, **TV-CR**, **CURPOS**, **INPUT**
* Réécriture de **PLOT** 
* Ajout du mot **3DROP** 
* Travail sur **TV-PUTC** pour améliorer performance. 

2021-04-21

* Améliorer performance **TV-PUTC** et **CHARROW** 
* Ajouter **-ROT**. 

2021-04-14

* Travail sur tvout.s

2021-04-13

* Travail sur TV-PUTC (non complété).