2022-02-18

* Travail sur **?DO**. 

2022-02-17 

* 23:07 commit 

* Travail sur **?DO** .

* Modifié >NFA pour mettre le bit thumb du cfa à zéro. 

* Corrigé  **2R&gt;**, **2&gt;R** et ajouté **2R@**. 
---

*  La liste complète des mots du CORE forth 2012 standard est maintenant implémentée. commit 20:23

*  Move ne correspondait pas au standard forth 2012. Il devait transféré un nombre extact d'octets. Je l'ai renommé **WMOVE** car il transfert 
   un nombre entier de mots de 32 bits.  **MOVE** est maintenant un alias pour **CMOVE** puisque sur ce système il font la même chose.

*  Modifié  **:** et **CREATE** pour que l'entête de dictionnaire soit alignée. Au cas ou HERE ne serait pas aligné au moment de la création 
d'un nouveau mot. Cette possibilité existe si **ALLOT** est utilisé avec un argument qui n'est pas modulo 4 . Par exemple lorsque **C,** est utilisé.

*  Ajout de **C,**. 

*  Corrigé  bogue dans **ABORT**. 

*  Modifié  **;** pour que le pointeur HERE soit alignée après la définition.

*  Supprimé le **OVERT** dans la définition de **:**. Le mot de doit-être visible dans FIND seulement après que la définition soit complétée.

----------------

*  Débogué **DOES>** commit 11:41

* Modifié **CREATE** et **VARIABLE** 

* bogue dans ABORT et DOES>. 22:23 commit.

* 22:21 **DEFER**, **DEFER!**, **DEFER!**, **:NONAME** et **IS** testés.  

* 20:34 commit.

* Modification à **CREATE** pour que le data field soit après la définition du mot mais non alloué. 

* Modifié **&gt;BODY** pour tenir compte de la modification de **CREATE**. 

* Renommé  **&gt;NAME** en **&gt;NFA** et renommé **NAME&gt;** en **&gt;CFA**.

* Corrigé bogue dans **PRESET**. Ce mot est maintenant codé en assembleur.

----

* Ajout des mots __0&gt;__, __0&tl;&gt;__ et __&lt;&gt;__. 

* Ajout des mots  __:NONAME__ et __IS__. 

2022-02-16

* Ajouté et testé le mot **RECURSE**. Ceci complète le vocabulaire CORE du standard forth 2012.

* Modifié le mot **.(** pour en faire un mot immédiat.

* Ajout de **UD.** pour imprime entier double non signés. 

* Ajouté **ENVIRONTMENT?**

* Corrigé bogue dans **ABORQ** .

2022-02-15

* Ajour de  **SOURCE**, **EVALUATE**, **SOURCE-ID** 

* Ajout de la variable **STATE**  mise à -1 lorsqu'en mode compilation. À 0 autrement.

2022-02-14

* Ajout des constantes système **MIN-INT**, **MAX-INT** et **MAX-UINT**. 

* Ajout de la divsion double signée par simple signée symétrique **SM/REM**. 

* Testé  **FM/MOD** et **SM/REM**. 

* Ajouter **UNLOOP** pour conformance au standard forth 2012.

* Corrigé bogue mot **EXIT**. 

2022-02-13

* Ajout des mots **ALIGN** , **CHAR+**, **CHARS**, **FIND**  

* Renommé **M/MOD** en **FM/MOD** pour conformité avec forth std 2012. 

* Renommé **NOT** en **INVERT** pour conformité avec forth std 2012. 

* Ajout de **LEAVE**,  **POSTPONE**, **[']** .

* Modifié **RSHIFT** pour LSR au lieu de ASR pour se conformer au standard.

* Corrigé bogue dand **FLOAT?** acceptait la forme **.alpha..** comme float de valeur 0.0. 

* Modifié **ABORT** Selon le standard ce mot n'affiche pas de message. Imprime __" ?"__.

* Modifié **DOSTR**, **DOTQP** . Supprimé **DOTST**. 


2022-02-12

*  Recodé  **INT?** et **FLOAT?** pour utiliser **&gt;NUMBER** au lieu de **PARSE_DIGITS**. Éliminer **PARSE_DIGITS**. 

*  Ajout de **>NUMBER** pour se conformer au standard forth std 2012.

* Ajout de **&gt;BODY** 

* Ajout de **2SWAP** et **2OVER**.

* Renommé  **D@** **2@**.

* Codé **PICK** en machine et ajouter **PUT**. 

20022-02-11

* Renommé  **ATBFAR** **BFAR**.

* Renommé  **ATCFSR** **CFSR**.

* Renommé  **TONE** **BEEP**. 

* Supprimé mots **VLIST** et **WC**. 

* Ajouté constantes **LN2** et **LN10** pour les logarithmes naturel de 2 et 10, fichier [fpu.s](fpu.s)

* Ajouter au dictionnaire les mots **SCALEUP**  et **SCALEDONW** dans le fichier [ftoa.s](ftoa.s)

* Modifié **SCALEUP** pour accepter une limite en paramètre.

* Modifié **SCALEDOWN** 

* Modifié **LN** dans [ln.f](ln.f)

* Ajouté **LOG** dans [ln.f](ln.f)

20022-02-10

* Création du fichier [ln.f](ln.f) pour calcul du logarithme naturel.

* Modifié  **F>A** pour tenir compte des NaN et infinis. 

* Autre problème dans **F>A**  0.0  7 f. résulte en une boucle infinie.

* Corrigé bogue dans **F>A** du fichier [ftoa.s](ftoa.s). 

20022-02-09

*  Création du fichier [trigo.f](trigo.f)

*  découvert bogue dans f.  le nombre $3f7fffff imprime 0.:0000 au lieu de 0.999999
        
         $3F7FFFFE 7 f. 0.:00000 
         $3f7fffff 7 f. 0.:00000 ok


*  Corrigé bogue dans **DOPLOOP**. 

*  Ajout de **timer4_handler**  et du code d'initialisaton du TIMER4-CH1 dans [init.s](init.s)

*  Ajout du mot **TONE (  d f -- )** dans [forth.s](forth.s).

*  Ajout initialisation sortie audio dans [init.s](init.s)

2022-02-08

* Ajout du mot **JOYSTK** pour lire le port Atari Joystick 
    * **A0** LEFT 
    * **A1** RIGHT 
    * **A2** UP 
    * **A3** DOWN
    * **A12** FIRE 

2022-02-07

* Modifié schématique pour ajouter sortie audio sur **PB6** utilisation de **T4-CH1** en mode PWM. 


*  Ajouter variable système **BCHAR** qui permet de désactiver l'affichage du caractère indicateur de la base lors des  impressions de nombres.

* Corriger bogue dans commande **DUMP** 

* Modifié **fpus_exception pour indiquer l'adress IP où s'est produite l'exception. 

* Retravaillé les conversion entier vers ASCII. 

2022-02-06

* retraillé **PARSE_DIGITS** pour contrôler les débordements.

* Création de **D>A** pour convertir entier double en chaîne. 

* Retraillé l'impression des entiers. 

* Modifié **fpu_exception** pour restaurer à base numérique avant de quitter. 

* Modifié le mot **:** pour que permettre les définitions récursives.

2022-02-05

* Travail sur [ftoa.s](ftoa.s)  complété.

* Modifié code **CONSOLE** l'appel à **READY** se fait maintenant dans **COLD** 

* Travail dans [init.s](init.s)  sur **fpu_excecption**. 

2022-02-04

* Retravaillé [strtof.s](strtof.s), factorisation et optimisation. 

* Travail sur [ftoa.s](ftoa.s)

2022-02-03

* Travail sur [ftoa.f](ftoa.f)

* Création du mot **ARRAY nom ( n -- )** dans [forth.s](forth.s).

2022-02-02

* Travail sur [ftoa.f](ftoa.f)


2022-02-01

* **e.** et **f.** dans  [ftoa.f](ftoa.f) testés et débogués.

* Travail sur [ftoa.f](ftoa.f)

2022-01-31


* Travail sur [ftoa.f](ftoa.f)

2022-01-30

* Bogue à corrigé dans [strtof.s](strtof.s), **float?** laisse des résidus sur la pile: **0.5e-4 .s $200049BC $0 $3851B717**

* Début du travail sur [ftoa.s](ftoa.s)

* Ajout de **ARRAY@ -- ( a i -- w ) ** to fetch array element dans [forth.s](forth.s).


2022-01-29

* Travail sur [strtof.s](strtof.s).

* Retraivaillé le mot **INT?** dans [forth.s](forth.s) 

* Testé  **float?** dans [strtof.s](strtof.s)

2022-01-28

* Travail sur [strtof.s](strtof.s).

* Corrigé bogue sur **2&gt;R**. 

2022-01-27

* Travail sur [strtof.s](strtof.s).

* Ajout de **2&gt;R** et **2R&gt;** 

2022-01-26

* Continuer travail sur fpu.s qui va au final contenir les fonctions arithmétiques sur type float32. 

* Création de [strtof.s](strtof.s)  

2022-01-25

* Ajouts de mots pour les fonctions arithmétique sur type float32 dans [fpu.s](fpu.s)  

* Trouvé bogue causé par FPU. La pile des retours n'était pas assez grande. Augmentée à 256 octets. Lorsque le FPU est utilisé tous les regustres du FPU sont sauvegardés sur la pile lors d'un exception. 

2022-01-22 

* essaie de débogger bus fault quand aux accès du FPU. 

* Modification du vecteur BOOT vers HI_BOTH pour afficher le message sur les 2 consoles.

*  Ajout du message **READY** sur la console active.

2021-06-08

* Ajout de **CLZ** et **CTLZ** dans [forth.s](forth.s).

* Ajout de **SEARCH-FILE**, **ERASE-FILE**, **SAVE** et **LOAD**, **DIR**.


* Travail sur les fichiers en flash externe. [spi-flash.s](spi-flash.s)

2021-06-07 

* Ajouté **FABS**, **FMIN**, **FMAX**, **F&gt;** et **F&lt;**

* Corrigé bogue dans **F-ALIGN**.

* Corrigé bogue dans **F>S**. 

* Modifié TRACE pour afficher R> en plus de S>. Ajouter TRACE. pour éviter que TRACE écrase le tampon PAD. 

* Corrigé bogue dans **FLOAT?** .

2021-06-06

A faire: déboguer E. et F. 

2021-06-05

* Débuté transcription de [float.f](float.f) dans [float.s](float.s)

* Travail sur [float.f](float.f)

* Ajout de **[CHAR]** dans [forth.s](forth.s)

2021-06-04

* Ajout des mots **FABS**, **FNEGATE**, **FMIN**, **FMAX** , **F&gt;** et **F&lt;**. 

* Travail sur [float.f](float.f)

2021-06-03

* Ajouté __D*__  pour multiplié double par simple.

* renommé  **UD/** en **D/** 

* Travail sur [float.f](float.f)

2021-06-02

* Ajouté **D.** , **D2/** , **S>D**, **&lt;&gt;**.

* Modifié sortie numérique pour gérer entiers doubles. 

* Travail sur **D/MOD**  et [float.f](float.f)

2021-06-01 

* travail sur **UD/** 

2021-05-30

* Ajout de **UD/**  et __D2*__  

* Travail sur [float.f](float.f) à partir de l'article paru dans FORTH dimensions vol. IV, #1

2021-05-30

* Ajout de **UD>**  et **DABS**  

* Travail sur [float.f](float.f) à partir de l'article paru dans FORTH dimensions vol. IV, #1

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