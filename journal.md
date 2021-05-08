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