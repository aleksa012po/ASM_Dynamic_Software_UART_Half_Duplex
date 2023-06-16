;
; Arduino AsemblerUARTdinamican.asm
;
; Created: 17/08/2022 08:22:21
; Author : Aleksandar Bogdanovic
;

//Arduino Asembler, UART napraviti da ceo kod bude dinamican, u smislu, da se boudrate zadaje 
//a da tajming bude na osnovu toga, izracunati za dati kontroler

//U ovom primeru cemo koristiti baud rate 9600, 8 data bitova, 1 stop bit i Timer/Counter1 Compare Match A
// za detekciju poslate vrednosti, u HTerm-u ce vec biti zadatake vrednosti i poslate

.include "m328pdef.inc"

//Definicija pinova
.equ Rx = 0 //PD0
.equ Tx = 1 //PD1

.equ value = 57724 //0.5 sek - ne treba visse

//Stop bitovi
.equ sb = 1	//Broj stop bitova = 1

//Globalni registri
.def bc = r16					//bit counter
.def temp = r17					//privremena memorija registar
.def TxByte = r18				//podaci koji ce biti poslati
.def RxByte = r19				//podaci koji ce biti primljeni
.def compare = r20				//compare za baud rate
.def br = r23					//baud rate settings
.def br_value = r24				//baud rate value - koristi ce kada timer izmeri pravu vrednost za bit counter
.def counter = r30				//counter
.def tm = r31					//timer memory

.cseg							//Start CODE segment 
.org 0x0000
		rjmp reset
.org 0x0016						//Timer/Counter1 Compare Match A
		rjmp isr

postavichar:
		ldi bc, 9+sb			//1+8+stopbit = 10 bita 
		com	TxByte				//One’s Complement, invertuje sve
		sec						//Set Carry Flag, start bit
		
postavichar0:
		brcc postavichar1		//ako je carry setovan – Branch if Carry Cleared
		cbi	PORTD, Tx			//salje '0' - Clear Bit in I/O Register
		rjmp postavichar2

postavichar1:
		sbi	PORTD, Tx			//salje '1' - Set Bit in I/O Register
		nop

postavichar2:
		rcall delayUART			//jedan bit delay
		rcall delayUART			

		lsr	TxByte				//Logical Shift Right, prima sledeci bit
		dec bc			
		brne postavichar0		//posalji sledeci
		ret

primichar:
		ldi	bc, 9			//b data bitova + 1 stop bit
//////////////////////////////////////// Timer LOOP /////////////////////////////////////////////////
primichar1:
		sbic PIND, Rx			//sacekaj start bit (Skip if Bit in I/O Register is Cleared)
		rjmp primichar1
		rcall start_timer		

count_delay:
		sbis PIND, Rx			//Skip if Bit in I/O Register is Set
		rjmp count_delay
		rcall stop_timer
		mov br_value, counter
///////////////////////////////////// Baud rate value ///////////////////////////////////////////////
//4800 baud rate counter value 210
//9600 baud rate counter value 106
//14400 baud rate counter value 71
//19200 baud rate counter value 54
//28800 baud rate counter value 36
//38400 baud rate counter value 28
//56000 baud rate counter value 20
//57600 baud rate counter value 19
//115200 baud rate counter value 11
//128000 baud rate counter value 10
//256000 baud rate counter value 6


		 rcall baud_setup
		 rcall delayUART		//0.5 bit delay
		

primichar2:
		rcall delayUART
		rcall delayUART			//1 bit delay (cekamo 1.5 bit puta = primichar1+primichar2)

		clc						//kliruje carry
		sbic PIND, Rx			//ako je Rx pin = 5V, Skip if Bit in I/O Register is Cleared
		sec						//setuje carry

		dec bc
		breq primichar3

		ror	RxByte				//Rotate Right through Carry, siftuje bit u RxByte
		rjmp primichar2	

primichar3:
		ret

start_timer:
		clr tm					//tm = r20
		sts TCNT1H, tm	
		ldi tm, 0
		sts TCNT1L, tm
		ldi tm, 0b00000010		//TIMSK1 – Timer/Counter1 Interrupt Mask Register
		sts TIMSK1, tm			//Timer/Counter1, Output Compare A Match Interrupt Enable
		ldi tm, 1
		sts OCR1AL, tm
		ldi tm, 0b00000001
		sts TIFR1, tm			//TOV1: Timer/Counter1, Overflow Flag, kada je 255 flag se aktivira

		ldi tm, 0b00000000
		sts TCCR1A, tm
		ldi tm, 0b00001010		
		sts TCCR1B, tm			//CTC, Timer/Counter1 Compare Match A, preskalar na 1024
		ret

stop_timer:
		ldi tm, 0b00000000		
		sts TCCR1A, tm			//TCCR1A = 0x00
		ldi tm, 0b00000000			
		sts TCCR1B, tm			//TCCR1B = 0x00
		cli
		ret	

//Baud rate podesavanja primer
// 1sek/9600 = 0.00010416666...
// 8MHz kristal
// online timer calculator
// Total timer ticks 833
// 833/7 = 119

//Baud rate settings value 1sek/baud rate, OTC, timer ticks/3 = value
//4800 baud rate settings value  238 (0.000208333333333 sec) 
//9600 baud rate settings value  119 (0.000104166666666 sec)
//14400 baud rate settings value  79 (0.000069444444444 sec)
//19200 baud rate settings value  59 (0.000052083333333 sec)
//28800 baud rate settings value  39 (0.000034722222222 sec)
//38400 baud rate settings value  29 (0.000026041666666 sec)
//56000 baud rate settings value  20 (0.000017857142857 sec)
//57600 baud rate settings value  19 (0.000017361111111 sec)
//115200 baud rate settings value 10 (0.000008680555555 sec)
//128000 baud rate settings value 9  (0,0000078125 sec)
//256000 baud rate settings value 4  (0,00000390625 sec)

//Baud rate settings
.equ br4800 = 238
.equ br9600 = 119
.equ br14400 = 79
.equ br19200 = 59				//19200 bps @ 8MHz kristal
.equ br28800 = 39
.equ br38400 = 29
.equ br56000 = 20
.equ br57600 = 19
.equ br115200 = 10
.equ br128000 = 9
.equ br256000 = 4
		
baud_setup:
		mov compare, counter
		cpi compare, 210
		breq baud4800
////////////////////////////////	
		cpi compare, 106
		breq baud9600
////////////////////////////////	
		cpi compare, 71
		breq baud14400
////////////////////////////////	
		cpi compare, 54
		breq baud19200
////////////////////////////////			
		cpi compare, 36
		breq baud28800
////////////////////////////////	
		cpi compare, 28
		breq baud38400
////////////////////////////////			
		cpi compare, 20
		breq baud56000
////////////////////////////////	
		cpi compare, 19
		breq baud57600	
////////////////////////////////	
		cpi compare, 11
		breq baud115200
////////////////////////////////	
		cpi compare, 11
		breq baud128000
////////////////////////////////	
		cpi compare, 6
		breq baud256000
////////////////////////////////	
		        
delayUART:						//3*b + 7 ciklusa (zajedno sa rcall i ret)
        mov temp, br			//br u temp=r17
delayUART1:
        dec temp				//dekrament r17 (temp value - 1)
		nop
		nop
		nop
		nop
        brne delayUART1			//Branch if Not Equal
        ret

//Test programa

reset:
		sbi	PORTD, Tx			//inicijalizuje port pinove
		sbi DDRD, Tx
		clr r21
		sts tcnt1h, r21			//Store Direct to Data Space
		sts tcnt1l, r21			//Store Direct to Data Space
		sei		

		;ldi	TxByte, 12
		;rcall postavichar
		rcall primichar
loop:
		rcall primichar
		mov TxByte, RxByte		//kopiraj registar
		rcall postavichar
		rjmp loop

isr:
		inc counter				//isr counter
		ldi tm, (1<<TOV1)
		sts TIFR1, tm			//tm = r20
		reti

baud4800:
		ldi br, br4800			//kopira 238
		ret
baud9600:
		ldi br, br9600			//kopira 119
		ret
baud14400:
		ldi br, br14400			//kopira 79...
		ret
baud19200:
		ldi br, br19200
		ret
baud28800:
		ldi br, br28800
		ret
baud38400:
		ldi br, br38400
		ret
baud56000:
		ldi br, br56000
		ret
baud57600:
		ldi br, br57600
		ret
baud115200:
		ldi br, br115200
		ret
baud128000:
		ldi br, br128000
		ret
baud256000:
		ldi br, br256000
		ret



		