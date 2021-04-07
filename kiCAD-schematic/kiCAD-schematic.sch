EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L black-pill:BLACKPILL BRD1
U 1 1 5FFB52D6
P 6000 3500
F 0 "BRD1" H 5825 2127 50  0000 C CNN
F 1 "BLACKPILL" H 5825 2036 50  0000 C CNN
F 2 "" H 6000 3500 50  0001 C CNN
F 3 "" H 6000 3500 50  0001 C CNN
	1    6000 3500
	1    0    0    -1  
$EndComp
$Comp
L Transistor_BJT:2N3904 Q1
U 1 1 5FFB6AAB
P 8550 1200
F 0 "Q1" H 8740 1246 50  0000 L CNN
F 1 "2N3904" H 8740 1155 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 8750 1125 50  0001 L CIN
F 3 "https://www.fairchildsemi.com/datasheets/2N/2N3904.pdf" H 8550 1200 50  0001 L CNN
	1    8550 1200
	-1   0    0    -1  
$EndComp
$Comp
L Transistor_BJT:2N3906 Q2
U 1 1 5FFB706D
P 9000 2850
F 0 "Q2" H 9190 2896 50  0000 L CNN
F 1 "2N3906" H 9190 2805 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 9200 2775 50  0001 L CIN
F 3 "https://www.fairchildsemi.com/datasheets/2N/2N3906.pdf" H 9000 2850 50  0001 L CNN
	1    9000 2850
	1    0    0    1   
$EndComp
$Comp
L Transistor_BJT:2N3904 Q3
U 1 1 5FFB73F5
P 9700 4600
F 0 "Q3" H 9890 4646 50  0000 L CNN
F 1 "2N3904" H 9890 4555 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 9900 4525 50  0001 L CIN
F 3 "https://www.fairchildsemi.com/datasheets/2N/2N3904.pdf" H 9700 4600 50  0001 L CNN
	1    9700 4600
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR09
U 1 1 5FFBB8C6
P 8450 1400
F 0 "#PWR09" H 8450 1150 50  0001 C CNN
F 1 "GND" H 8455 1227 50  0000 C CNN
F 2 "" H 8450 1400 50  0001 C CNN
F 3 "" H 8450 1400 50  0001 C CNN
	1    8450 1400
	-1   0    0    -1  
$EndComp
$Comp
L Device:R R7
U 1 1 5FFBBD46
P 8450 850
F 0 "R7" H 8380 896 50  0000 R CNN
F 1 "4k7" H 8380 805 50  0000 R CNN
F 2 "" V 8380 850 50  0001 C CNN
F 3 "~" H 8450 850 50  0001 C CNN
	1    8450 850 
	-1   0    0    -1  
$EndComp
$Comp
L Device:R R12
U 1 1 5FFBC3D5
P 8900 1200
F 0 "R12" V 8693 1200 50  0000 C CNN
F 1 "10k" V 8784 1200 50  0000 C CNN
F 2 "" V 8830 1200 50  0001 C CNN
F 3 "~" H 8900 1200 50  0001 C CNN
	1    8900 1200
	0    -1   1    0   
$EndComp
$Comp
L pspice:DIODE D4
U 1 1 5FFBCAE0
P 9400 1400
F 0 "D4" V 9446 1272 50  0000 R CNN
F 1 "1N4148" V 9355 1272 50  0000 R CNN
F 2 "" H 9400 1400 50  0001 C CNN
F 3 "~" H 9400 1400 50  0001 C CNN
	1    9400 1400
	0    -1   -1   0   
$EndComp
$Comp
L Device:CP C2
U 1 1 5FFBD29B
P 9400 1750
F 0 "C2" H 9282 1704 50  0000 R CNN
F 1 "10µF/16v" H 9282 1795 50  0000 R CNN
F 2 "" H 9438 1600 50  0001 C CNN
F 3 "~" H 9400 1750 50  0001 C CNN
	1    9400 1750
	-1   0    0    1   
$EndComp
$Comp
L power:GND #PWR011
U 1 1 5FFBD895
P 9400 1900
F 0 "#PWR011" H 9400 1650 50  0001 C CNN
F 1 "GND" H 9405 1727 50  0000 C CNN
F 2 "" H 9400 1900 50  0001 C CNN
F 3 "" H 9400 1900 50  0001 C CNN
	1    9400 1900
	1    0    0    -1  
$EndComp
Wire Wire Line
	9050 1200 9400 1200
Text GLabel 8200 1000 0    50   Input ~ 0
RX
Wire Wire Line
	8200 1000 8450 1000
Connection ~ 8450 1000
Text GLabel 6650 4150 2    50   Input ~ 0
RX
Wire Wire Line
	6650 4150 6450 4150
Text GLabel 6650 4250 2    50   Input ~ 0
TX
Wire Wire Line
	6450 4250 6650 4250
$Comp
L Device:R R8
U 1 1 5FFCA3D0
P 8650 2850
F 0 "R8" V 8857 2850 50  0000 C CNN
F 1 "1k" V 8766 2850 50  0000 C CNN
F 2 "" V 8580 2850 50  0001 C CNN
F 3 "~" H 8650 2850 50  0001 C CNN
	1    8650 2850
	0    -1   -1   0   
$EndComp
Text GLabel 8500 2850 0    50   Input ~ 0
TX
$Comp
L Device:R R13
U 1 1 5FFCAAFB
P 9100 2350
F 0 "R13" H 9030 2304 50  0000 R CNN
F 1 "3k3" H 9030 2395 50  0000 R CNN
F 2 "" V 9030 2350 50  0001 C CNN
F 3 "~" H 9100 2350 50  0001 C CNN
	1    9100 2350
	-1   0    0    1   
$EndComp
Text GLabel 9100 3050 3    50   Input ~ 0
5v+
Connection ~ 9400 1600
Wire Wire Line
	9100 2650 9100 2550
Text GLabel 9650 2550 2    50   Input ~ 0
rs-232-tx
Connection ~ 9100 2550
Wire Wire Line
	9100 2550 9100 2500
Text GLabel 9650 1200 2    50   Input ~ 0
rs-232-rx
Wire Wire Line
	9650 1200 9400 1200
Connection ~ 9400 1200
Wire Wire Line
	9100 1600 9100 2200
Wire Wire Line
	9100 1600 9400 1600
Wire Wire Line
	9100 2550 9650 2550
Text GLabel 8300 650  0    50   Input ~ 0
5v+
Wire Wire Line
	8300 650  8450 650 
Wire Wire Line
	8450 650  8450 700 
$Comp
L Device:R R18
U 1 1 5FFE0B3E
P 9800 5100
F 0 "R18" H 9870 5146 50  0000 L CNN
F 1 "82" H 9870 5055 50  0000 L CNN
F 2 "" V 9730 5100 50  0001 C CNN
F 3 "~" H 9800 5100 50  0001 C CNN
	1    9800 5100
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR012
U 1 1 5FFE2066
P 9800 5250
F 0 "#PWR012" H 9800 5000 50  0001 C CNN
F 1 "GND" H 9805 5077 50  0000 C CNN
F 2 "" H 9800 5250 50  0001 C CNN
F 3 "" H 9800 5250 50  0001 C CNN
	1    9800 5250
	1    0    0    -1  
$EndComp
$Comp
L Device:R R15
U 1 1 5FFE28FB
P 9250 4050
F 0 "R15" H 9320 4096 50  0000 L CNN
F 1 "510" H 9320 4005 50  0000 L CNN
F 2 "" V 9180 4050 50  0001 C CNN
F 3 "~" H 9250 4050 50  0001 C CNN
	1    9250 4050
	1    0    0    -1  
$EndComp
$Comp
L Device:R R3
U 1 1 5FFE2BA0
P 8400 4600
F 0 "R3" V 8607 4600 50  0000 C CNN
F 1 "2K" V 8516 4600 50  0000 C CNN
F 2 "" V 8330 4600 50  0001 C CNN
F 3 "~" H 8400 4600 50  0001 C CNN
	1    8400 4600
	0    -1   -1   0   
$EndComp
Wire Wire Line
	9800 4200 9800 4400
Wire Wire Line
	9500 4600 9250 4600
Wire Wire Line
	8700 4600 8550 4600
Wire Wire Line
	9800 4800 9800 4850
Text GLabel 10100 4850 2    50   Input ~ 0
video-out
Wire Wire Line
	10100 4850 9800 4850
Connection ~ 9800 4850
Wire Wire Line
	9800 4850 9800 4950
$Comp
L Device:R R9
U 1 1 5FFE64FB
P 8700 4750
F 0 "R9" V 8907 4750 50  0000 C CNN
F 1 "1K" V 8816 4750 50  0000 C CNN
F 2 "" V 8630 4750 50  0001 C CNN
F 3 "~" H 8700 4750 50  0001 C CNN
	1    8700 4750
	1    0    0    -1  
$EndComp
$Comp
L Device:R R5
U 1 1 5FFE66C1
P 8400 5200
F 0 "R5" V 8607 5200 50  0000 C CNN
F 1 "2K" V 8516 5200 50  0000 C CNN
F 2 "" V 8330 5200 50  0001 C CNN
F 3 "~" H 8400 5200 50  0001 C CNN
	1    8400 5200
	0    -1   -1   0   
$EndComp
Wire Wire Line
	8550 4900 8700 4900
Wire Wire Line
	8550 5200 8700 5200
Wire Wire Line
	8550 5500 8700 5500
Text GLabel 8950 3900 0    50   Input ~ 0
VSYNK
Wire Wire Line
	8950 3900 9250 3900
$Comp
L Connector:Mini-DIN-6 J3
U 1 1 5FFF21E9
P 3400 6200
F 0 "J3" H 3400 6567 50  0000 C CNN
F 1 "keyboard (ps/2)" H 3400 6476 50  0000 C CNN
F 2 "" H 3400 6200 50  0001 C CNN
F 3 "http://service.powerdynamics.com/ec/Catalog17/Section%2011.pdf" H 3400 6200 50  0001 C CNN
	1    3400 6200
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR06
U 1 1 5FFF7C89
P 4050 6200
F 0 "#PWR06" H 4050 5950 50  0001 C CNN
F 1 "GND" H 4055 6027 50  0000 C CNN
F 2 "" H 4050 6200 50  0001 C CNN
F 3 "" H 4050 6200 50  0001 C CNN
	1    4050 6200
	1    0    0    -1  
$EndComp
Text GLabel 2850 6200 0    50   Input ~ 0
5V+
Wire Wire Line
	2850 6200 3100 6200
Wire Wire Line
	3700 6200 4050 6200
Text GLabel 3700 6300 2    50   Input ~ 0
data
Text GLabel 3700 6100 2    50   Input ~ 0
clock
$Comp
L Connector:USB_A J2
U 1 1 5FFFC531
P 1600 6200
F 0 "J2" H 1657 6667 50  0000 C CNN
F 1 "keyboard (usb-a)" H 1657 6576 50  0000 C CNN
F 2 "" H 1750 6150 50  0001 C CNN
F 3 " ~" H 1750 6150 50  0001 C CNN
	1    1600 6200
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR04
U 1 1 5FFFD3BC
P 1600 6600
F 0 "#PWR04" H 1600 6350 50  0001 C CNN
F 1 "GND" H 1605 6427 50  0000 C CNN
F 2 "" H 1600 6600 50  0001 C CNN
F 3 "" H 1600 6600 50  0001 C CNN
	1    1600 6600
	1    0    0    -1  
$EndComp
Text GLabel 1900 6000 2    50   Input ~ 0
5V+
Text GLabel 1900 6300 2    50   Input ~ 0
data
Text GLabel 1900 6200 2    50   Input ~ 0
clock
NoConn ~ 5250 3750
NoConn ~ 5250 3850
NoConn ~ 5250 3950
NoConn ~ 5250 4050
Text Notes 4350 4000 0    50   ~ 0
PA4,PA5,PA6,PA7\nUSED BY W25Q128\nON board SPI FLASH
Wire Notes Line
	4300 3700 4300 4100
Wire Notes Line
	4300 4100 5150 4100
Wire Notes Line
	5150 4100 5150 3700
Wire Notes Line
	5150 3700 4300 3700
$Comp
L Switch:SW_SPST SW1
U 1 1 6000E75A
P 2050 3300
F 0 "SW1" H 2050 3547 50  0000 C CNN
F 1 "~RESET" H 2050 3449 50  0000 C CNN
F 2 "" H 2050 3300 50  0001 C CNN
F 3 "~" H 2050 3300 50  0001 C CNN
	1    2050 3300
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR02
U 1 1 6000F1EA
P 1550 3300
F 0 "#PWR02" H 1550 3050 50  0001 C CNN
F 1 "GND" H 1555 3127 50  0000 C CNN
F 2 "" H 1550 3300 50  0001 C CNN
F 3 "" H 1550 3300 50  0001 C CNN
	1    1550 3300
	1    0    0    -1  
$EndComp
Wire Wire Line
	1550 3300 1850 3300
Text GLabel 2500 3300 2    50   Input ~ 0
~RST
Text GLabel 5000 3250 0    50   Input ~ 0
~RST
Wire Wire Line
	5000 3250 5250 3250
$Comp
L pspice:DIODE D3
U 1 1 60019841
P 2350 3100
F 0 "D3" V 2396 2972 50  0000 R CNN
F 1 "1N4148" V 2305 2972 50  0000 R CNN
F 2 "" H 2350 3100 50  0001 C CNN
F 3 "~" H 2350 3100 50  0001 C CNN
	1    2350 3100
	0    -1   -1   0   
$EndComp
Wire Wire Line
	2250 3300 2350 3300
Connection ~ 2350 3300
Wire Wire Line
	2350 3300 2500 3300
Text GLabel 2350 2900 1    50   Input ~ 0
3v3+
Text GLabel 5250 4250 0    50   Input ~ 0
VSYNK
Text GLabel 8250 4600 0    50   Input ~ 0
VB3
Text GLabel 8250 4900 0    50   Input ~ 0
VB2
Text GLabel 8250 5200 0    50   Input ~ 0
VB1
Text GLabel 8250 5500 0    50   Input ~ 0
VB0
Text GLabel 5150 3350 0    50   Input ~ 0
VB0
Wire Wire Line
	5150 3350 5250 3350
Text GLabel 4950 3450 0    50   Input ~ 0
VB1
Wire Wire Line
	4950 3450 5250 3450
Text GLabel 5150 3550 0    50   Input ~ 0
VB2
Wire Wire Line
	5150 3550 5250 3550
Text GLabel 4950 3650 0    50   Input ~ 0
VB3
Wire Wire Line
	4950 3650 5250 3650
$Comp
L Device:R R1
U 1 1 6002405D
P 7150 3800
F 0 "R1" H 7220 3846 50  0000 L CNN
F 1 "10K" H 7220 3755 50  0000 L CNN
F 2 "" V 7080 3800 50  0001 C CNN
F 3 "~" H 7150 3800 50  0001 C CNN
	1    7150 3800
	-1   0    0    -1  
$EndComp
$Comp
L Device:R R2
U 1 1 600245BA
P 7450 3900
F 0 "R2" H 7520 3946 50  0000 L CNN
F 1 "10K" H 7520 3855 50  0000 L CNN
F 2 "" V 7380 3900 50  0001 C CNN
F 3 "~" H 7450 3900 50  0001 C CNN
	1    7450 3900
	-1   0    0    -1  
$EndComp
Wire Wire Line
	7450 4050 6450 4050
Wire Wire Line
	7150 3950 6450 3950
Wire Wire Line
	7450 3750 7450 3650
Wire Wire Line
	7450 3650 7150 3650
Text GLabel 7300 3650 1    50   Input ~ 0
5V+
Text GLabel 7650 4050 2    50   Input ~ 0
clock
Wire Wire Line
	7650 4050 7450 4050
Connection ~ 7450 4050
Text GLabel 6850 3950 1    50   Input ~ 0
data
Text GLabel 6450 2850 2    50   Input ~ 0
3v3+
Text GLabel 5250 4550 0    50   Input ~ 0
3v3+
Text GLabel 5250 4750 0    50   Input ~ 0
5V+
Text GLabel 6450 3050 2    50   Input ~ 0
5V+
$Comp
L power:GND #PWR08
U 1 1 6002E243
P 6900 3000
F 0 "#PWR08" H 6900 2750 50  0001 C CNN
F 1 "GND" H 6905 2827 50  0000 C CNN
F 2 "" H 6900 3000 50  0001 C CNN
F 3 "" H 6900 3000 50  0001 C CNN
	1    6900 3000
	1    0    0    -1  
$EndComp
Wire Wire Line
	6900 3000 6900 2950
Wire Wire Line
	6900 2950 6450 2950
$Comp
L power:GND #PWR07
U 1 1 60030D2C
P 4650 4650
F 0 "#PWR07" H 4650 4400 50  0001 C CNN
F 1 "GND" H 4655 4477 50  0000 C CNN
F 2 "" H 4650 4650 50  0001 C CNN
F 3 "" H 4650 4650 50  0001 C CNN
	1    4650 4650
	1    0    0    -1  
$EndComp
Wire Wire Line
	4650 4650 5250 4650
$Comp
L Device:Battery BT1
U 1 1 60034C79
P 1600 1950
F 0 "BT1" H 1708 1996 50  0000 L CNN
F 1 "6Volt" H 1708 1905 50  0000 L CNN
F 2 "" V 1600 2010 50  0001 C CNN
F 3 "~" V 1600 2010 50  0001 C CNN
	1    1600 1950
	1    0    0    -1  
$EndComp
$Comp
L Switch:SW_SPST SW2
U 1 1 6003540A
P 2300 1350
F 0 "SW2" H 2300 1585 50  0000 C CNN
F 1 "POWER" H 2300 1494 50  0000 C CNN
F 2 "" H 2300 1350 50  0001 C CNN
F 3 "~" H 2300 1350 50  0001 C CNN
	1    2300 1350
	1    0    0    -1  
$EndComp
$Comp
L Device:D D1
U 1 1 60035A9F
P 1300 1350
F 0 "D1" H 1300 1134 50  0000 C CNN
F 1 "1N4001" H 1300 1225 50  0000 C CNN
F 2 "" H 1300 1350 50  0001 C CNN
F 3 "~" H 1300 1350 50  0001 C CNN
	1    1300 1350
	-1   0    0    1   
$EndComp
$Comp
L power:GND #PWR03
U 1 1 6003823A
P 1600 2150
F 0 "#PWR03" H 1600 1900 50  0001 C CNN
F 1 "GND" H 1605 1977 50  0000 C CNN
F 2 "" H 1600 2150 50  0001 C CNN
F 3 "" H 1600 2150 50  0001 C CNN
	1    1600 2150
	1    0    0    -1  
$EndComp
Text GLabel 2850 1350 2    50   Input ~ 0
5V+
$Comp
L Device:CP C1
U 1 1 6003899C
P 2650 1500
F 0 "C1" H 2768 1546 50  0000 L CNN
F 1 "CP" H 2768 1455 50  0000 L CNN
F 2 "" H 2688 1350 50  0001 C CNN
F 3 "~" H 2650 1500 50  0001 C CNN
	1    2650 1500
	1    0    0    -1  
$EndComp
Wire Wire Line
	2500 1350 2650 1350
Wire Wire Line
	2650 1350 2850 1350
Connection ~ 2650 1350
$Comp
L power:GND #PWR05
U 1 1 6003AF48
P 2650 1650
F 0 "#PWR05" H 2650 1400 50  0001 C CNN
F 1 "GND" H 2655 1477 50  0000 C CNN
F 2 "" H 2650 1650 50  0001 C CNN
F 3 "" H 2650 1650 50  0001 C CNN
	1    2650 1650
	1    0    0    -1  
$EndComp
$Comp
L Connector:Conn_Coaxial_Power J1
U 1 1 600417D1
P 800 1450
F 0 "J1" H 888 1446 50  0000 L CNN
F 1 "ext. power" H 888 1355 50  0000 L CNN
F 2 "" H 800 1400 50  0001 C CNN
F 3 "~" H 800 1400 50  0001 C CNN
	1    800  1450
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR01
U 1 1 600428CB
P 800 1750
F 0 "#PWR01" H 800 1500 50  0001 C CNN
F 1 "GND" H 805 1577 50  0000 C CNN
F 2 "" H 800 1750 50  0001 C CNN
F 3 "" H 800 1750 50  0001 C CNN
	1    800  1750
	1    0    0    -1  
$EndComp
Wire Wire Line
	800  1650 800  1750
$Comp
L Device:D D2
U 1 1 6004E92C
P 1600 1600
F 0 "D2" V 1554 1679 50  0000 L CNN
F 1 "1N4001" V 1645 1679 50  0000 L CNN
F 2 "" H 1600 1600 50  0001 C CNN
F 3 "~" H 1600 1600 50  0001 C CNN
	1    1600 1600
	0    1    1    0   
$EndComp
Wire Wire Line
	1600 1350 1600 1450
Wire Wire Line
	1600 1350 2100 1350
Wire Wire Line
	800  1350 1150 1350
Wire Wire Line
	1450 1350 1600 1350
Connection ~ 1600 1350
Text Notes 500  1550 0    50   ~ 0
5VDC\n
Text Notes 2200 6900 0    79   ~ 0
keyboard connector\nalternative\n
Wire Notes Line
	1000 5500 1000 7050
Wire Notes Line
	1000 7050 4250 7050
Wire Notes Line
	4250 7050 4250 5500
Wire Notes Line
	4250 5500 1000 5500
Text GLabel 9800 4200 1    50   Input ~ 0
3.3V
Wire Wire Line
	9250 4200 9250 4600
$Comp
L Device:R R6
U 1 1 5FFE69F1
P 8400 5500
F 0 "R6" V 8607 5500 50  0000 C CNN
F 1 "2K" V 8516 5500 50  0000 C CNN
F 2 "" V 8330 5500 50  0001 C CNN
F 3 "~" H 8400 5500 50  0001 C CNN
	1    8400 5500
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R10
U 1 1 606BBA80
P 8700 5050
F 0 "R10" V 8907 5050 50  0000 C CNN
F 1 "1K" V 8816 5050 50  0000 C CNN
F 2 "" V 8630 5050 50  0001 C CNN
F 3 "~" H 8700 5050 50  0001 C CNN
	1    8700 5050
	1    0    0    -1  
$EndComp
Connection ~ 8700 4900
$Comp
L Device:R R11
U 1 1 606BBEF7
P 8700 5350
F 0 "R11" V 8907 5350 50  0000 C CNN
F 1 "1K" V 8816 5350 50  0000 C CNN
F 2 "" V 8630 5350 50  0001 C CNN
F 3 "~" H 8700 5350 50  0001 C CNN
	1    8700 5350
	1    0    0    -1  
$EndComp
Connection ~ 8700 5200
$Comp
L Device:R R4
U 1 1 606BC274
P 8400 4900
F 0 "R4" V 8607 4900 50  0000 C CNN
F 1 "2K" V 8516 4900 50  0000 C CNN
F 2 "" V 8330 4900 50  0001 C CNN
F 3 "~" H 8400 4900 50  0001 C CNN
	1    8400 4900
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R16
U 1 1 606BC7C8
P 9250 5100
F 0 "R16" V 9457 5100 50  0000 C CNN
F 1 "2K" V 9366 5100 50  0000 C CNN
F 2 "" V 9180 5100 50  0001 C CNN
F 3 "~" H 9250 5100 50  0001 C CNN
	1    9250 5100
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR010
U 1 1 606BCE93
P 9250 5250
F 0 "#PWR010" H 9250 5000 50  0001 C CNN
F 1 "GND" H 9255 5077 50  0000 C CNN
F 2 "" H 9250 5250 50  0001 C CNN
F 3 "" H 9250 5250 50  0001 C CNN
	1    9250 5250
	1    0    0    -1  
$EndComp
$Comp
L Device:R R14
U 1 1 606BD278
P 9100 4600
F 0 "R14" V 9307 4600 50  0000 C CNN
F 1 "1K" V 9216 4600 50  0000 C CNN
F 2 "" V 9030 4600 50  0001 C CNN
F 3 "~" H 9100 4600 50  0001 C CNN
	1    9100 4600
	0    1    1    0   
$EndComp
Connection ~ 9250 4600
Wire Wire Line
	9250 4600 9250 4950
Wire Wire Line
	8700 4600 8950 4600
Connection ~ 8700 4600
$Comp
L Device:R R?
U 1 1 606BFDFE
P 8700 5650
F 0 "R?" V 8907 5650 50  0000 C CNN
F 1 "2K" V 8816 5650 50  0000 C CNN
F 2 "" V 8630 5650 50  0001 C CNN
F 3 "~" H 8700 5650 50  0001 C CNN
	1    8700 5650
	1    0    0    -1  
$EndComp
Connection ~ 8700 5500
$Comp
L power:GND #PWR?
U 1 1 606C01F2
P 8700 5800
F 0 "#PWR?" H 8700 5550 50  0001 C CNN
F 1 "GND" H 8705 5627 50  0000 C CNN
F 2 "" H 8700 5800 50  0001 C CNN
F 3 "" H 8700 5800 50  0001 C CNN
	1    8700 5800
	1    0    0    -1  
$EndComp
$EndSCHEMATC
