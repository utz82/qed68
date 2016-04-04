;qed68 v0.1 - 4 channel PCM player
;by utz 04'2016

	include "OS.h" 	;include file for _nostub programs, containing especially the ROM_CALLs
	xdef _nostub 	;no kernel required
	xdef _ti92plus 	;This program runs on a TI-92+.
	
	;samples must be aligned to 4 bytes inc. stop byte
	;all volume levels multiplied by 4
	
	;a0 - 	sequence pointer > preserved in (seqpntr)
	;a1 - 	pattern pointer
	;a2-a5	sample pointers
	;a6	jump table base pointer
	;d0-d3	basevals ch1-4
	;d4-d7	counters ch1-4
	
init
	move.w	#$700,d0		;disable interrupts
	trap	#1				
	move.w	d0,-(a7)		;preserve int mask
	
	movem.l d0-d7/a0-a6,-(a7) 	;save all regs

	bset	#6,($60000C)		;enable direct sound

	move.w	#$0,($600018)		;prepare keyhandler (check all keys)
	
	move.l	#$60000E,a2
	
	bclr	#2,($600001)		;disable memory protection
	
	move.l	($000074),-(a7)		;preserve AutoInt 5 vector
	move.l	($000078),-(a7)		;preserve AutoInt 6 vector
	
	lea	int6(PC),a1		;set AutoInt 6 vector
	move.l	a1,($000078)
	
	lea	int5(PC),a1		;set AutoInt 5 vector
	move.l	a1,($000074)
	
	moveq	#$0,d0
	lea	musicdata(PC),a0	;initialize pointers
	move.w	(a0)+,d0		;read and set global speed
	move.b	d0,($600017)
	
	movea.l	(a0)+,a1		;init sequence pointer
	move.l	a0,(seqpntr)		;preserve it
	
	moveq	#$0,d0			;reset basevals
	moveq	#$0,d1
	moveq	#$0,d2
	moveq	#$0,d3
	moveq	#$0,d4			;reset add counters
	moveq	#$0,d5
	moveq	#$0,d6
	moveq	#$0,d7

	move.w	(a1)+,d0		;skip ctrl word
	move.w	(a1)+,d3		;set initial basevals
	movea.l	(a1)+,a5
	move.w	(a1)+,d2
	movea.l	(a1)+,a4
	move.w	(a1)+,d1
	movea.l	(a1)+,a3
	move.w	(a1)+,d0
	movea.l	(a1)+,a2
	
	lea	jumptab(PC),a6		;initialize jump table pointer
	
	move.w	d0,-(a7)
	move.w	#$400,d0		;enable auto-int 5-7
	trap	#1
	move.w	(a7)+,d0
	move.l	d0,a0
		
;****************************************************************************
;****************************************************************************
core0					;volume 0 - 20t
	move.b	#$3,($60000E)		;20__
	move.b	#$0,($60000E)		;20__20

	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d6			;8	reset hi-word of counter
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d7			;8	reset hi-word of counter
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8
	beq	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1
	nop				;4	
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
	
					;442 +10 452 ~22,05kHz
					
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core1					;volume 1 - 20+16t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	
	move.b	#$0,($60000E)		;20__36
	
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d6			;8	reset hi-word of counter
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d7			;8	reset hi-word of counter
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8
	beq	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
	
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core2					;volume 2 - 20+32t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d4			;8	reset hi-word of counter
	
	move.b	#$0,($60000E)		;20__52
	
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d6			;8	reset hi-word of counter
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d7			;8	reset hi-word of counter
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8
	beq	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
	
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core3					;volume 3 - 20+48t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4
	
	move.b	#$0,($60000E)		;20__68
	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.w	#$0,d6			;8	reset hi-word of counter
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8
	beq	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
	
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core4					;volume 4 - 20+64t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	
	move.b	#$0,($60000E)		;20__84
	
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8
	beq	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
	
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core5					;volume 5 - 20+80t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	
	move.b	#$0,($60000E)		;20__100
	
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8
	beq	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14

\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core6					;volume 6 - 20+96t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter
	
	move.b	#$0,($60000E)		;20__116
	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8
	beq	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core7					;volume 7 - 20+112t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4
	
	move.b	#$0,($60000E)		;20__132
	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8
	beq	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core8					;volume 8 - 20+128t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter
	
	move.b	#$0,($60000E)		;20__148
	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8
	beq	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core9					;volume 9 - 20+144t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	
	move.b	#$0,($60000E)		;20__164
	
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core10					;volume 10 - 20+160t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8
	beq.s	\resetsmp1		;8/10
		
	move.b	#$0,($60000E)		;20__180
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4	timing
	nop				;4
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.b	#$0,($60000E)
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core11					;volume 11 - 20+176t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	move.b	#$0,($60000E)		;20__196
	nop
	nop
	nop
	nop
	nop				;+28

	
	nop				;4
\nx1
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	nop
	move.b	#$0,($60000E)		;20__198
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core12					;volume 12 - 20+192t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	move.b	#$0,($60000E)		;20__212
	nop				;+28

	
	nop				;4
\nx1
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	nop
	move.l	1(a2),a2		;16
	move.b	#$0,($60000E)		;20__214
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core13					;volume 13 - 20+208t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	

	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	move.b	#$0,($60000E)		;20__228
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx2	
	nop				;4
	nop				;4	timing
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.b	#$0,($60000E)
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core14					;volume 14 - 20+224t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop
	move.b	#$0,($60000E)		;20__244
	nop
	nop
	nop
	nop
	nop				;+28
	nop				;4
\nx2	
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	nop
	move.b	#$0,($60000E)		;20__242
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core15					;volume 15 - 20+240t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop	
	nop
	nop
	nop
	nop
	move.b	#$0,($60000E)		;20__260
	nop				;+28
	nop				;4
\nx2	
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	nop
	move.l	1(a3),a3
	move.b	#$0,($60000E)		;20__258
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core16					;volume 16 - 20+256t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop	
	nop
	nop
	nop
	nop
	nop				;+28
\nx2
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	move.b	#$0,($60000E)		;20__276	
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3	
	nop				;4	timing
	nop				;4
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.b	#$0,($60000E)
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core17					;volume 17 - 20+272t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop	
	nop
	nop
	nop
	nop
	nop				;+28
\nx2
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	move.b	#$0,($60000E)		;20__292
	nop
	nop
	nop
	nop
	nop				;+28
	nop				;4
\nx3
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	nop
	move.b	#$0,($60000E)		;20__290
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core18					;volume 18 - 20+288t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop	
	nop
	nop
	nop
	nop
	nop				;+28
\nx2
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	move.b	#$0,($60000E)		;20__308
	nop				;+28
	nop				;4
\nx3
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	nop
	move.l	1(a4),a4
	move.b	#$0,($60000E)		;20__306
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core19					;volume 19 - 20+304t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop	
	nop
	nop
	nop
	nop
	nop				;+28
\nx2
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3
	nop				;4
	cmp.b	(a5),d0			;8
	beq	\resetsmp4		;8/10
	move.b	#$0,($60000E)		;20__324
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx4
	nop				;4	timing
	nop				;4	
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.b	#$0,($60000E)
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core20					;volume 20 - 20+320t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop	
	nop
	nop
	nop
	nop
	nop				;+28
\nx2
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3
	nop				;4
	cmp.b	(a5),d0			;8	
	beq	\resetsmp4		;8/10
	nop
	nop
	move.b	#$0,($60000E)		;20__340
	nop
	nop
	nop
	nop
	nop				;+28	
	moveq	#0,d0			;4
\nx4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	moveq	#0,d0
	move.b	#$0,($60000E)		;20__338
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core21					;volume 21 - 20+336t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop	
	nop
	nop
	nop
	nop
	nop				;+28
\nx2
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3
	nop				;4
	cmp.b	(a5),d0			;8	
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	move.b	#$0,($60000E)		;20__356
	nop				;+28	
	moveq	#0,d0			;4
\nx4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	moveq	#0,d0
	move.l	1(a5),a5
	move.b	#$0,($60000E)		;20__354
	bra	\nx4	

;****************************************************************************
core22					;volume 21 - 20+352t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop	
	nop
	nop
	nop
	nop
	nop				;+28
\nx2
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3
	nop				;4
	cmp.b	(a5),d0			;8	
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop	
	nop				;+28	
\nx4
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	move.b	#$0,($60000E)		;20__372
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core23					;volume 23 - 20+8+368t
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop	
	nop
	nop
	nop
	nop
	nop				;+28
\nx2
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3
	nop				;4
	cmp.b	(a5),d0			;8	
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop	
	nop				;+28	
\nx4
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	move.b	#$0,($60000E)		;20__396
	add.b	(a5),d0			;12
	
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
core24					;volume 24 - full loop
	move.b	#$3,($60000E)		;20__
	
	move.l	a0,d0			;4	restore d0

	add.l	d0,d4			;8	add baseval to counter ch1
	swap	d4			;4
	add.w	d4,a2			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d4			;8	reset hi-word of counter
	swap	d4			;4
	
	add.l	d1,d5			;8	add baseval to counter ch2
	swap	d5			;4	
	add.w	d5,a3			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d5			;8	reset hi-word of counter
	swap	d5			;4
	
	add.l	d2,d6			;8	add baseval to counter ch3
	swap	d6			;4
	add.w	d6,a4			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d6			;8	reset hi-word of counter	
	swap	d6			;4
	
	add.l	d3,d7			;8	add baseval to counter ch4
	swap	d7			;4	
	add.w	d7,a5			;8	increment sample byte if bit 16 of counter was set
	move.b	#$0,d7			;8	reset hi-word of counter	
	swap	d7			;4
	
	nop				;4	timing
	nop				;4
	
	move.l	d0,a0			;4
	move.b	#$ff,d0			;8
	cmp.b	(a2),d0			;8	
	beq.s	\resetsmp1		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28

\nx1	
	nop				;4
	cmp.b	(a3),d0			;8
	beq	\resetsmp2		;8/10
	nop
	nop	
	nop
	nop
	nop
	nop
	nop				;+28
\nx2
	nop				;4
	cmp.b	(a4),d0			;8
	beq	\resetsmp3		;8/10
	nop
	nop
	nop
	nop
	nop
	nop
	nop				;+28
\nx3
	nop				;4
	cmp.b	(a5),d0			;8	
	beq	\resetsmp4		;8/10
	nop
	nop
	nop
	nop
	nop
	nop	
	nop				;+28	
\nx4
	moveq	#0,d0			;4
	move.b	(a2),d0			;8
	add.b	(a3),d0			;12
	add.b	(a4),d0			;12
	add.b	(a5),d0			;12
	
	nop
	nop
	nop
	nop
	nop
	jmp	0(a6,d0.w)		;14
				
\resetsmp1
	move.l	1(a2),a2		;16
	bra	\nx1			;10 (+2=+28)
\resetsmp2
	move.l	1(a3),a3
	bra	\nx2
\resetsmp3
	move.l	1(a4),a4
	bra	\nx3
\resetsmp4
	move.l	1(a5),a5
	bra	\nx4	

;****************************************************************************
jumptab
	bra	core0			;10
	bra	core1
	bra	core2
	bra	core3
	bra	core4
	bra	core5
	bra	core6
	bra	core7
	bra	core8
	bra	core9
	bra	core10
	bra	core11
	bra	core12
	bra	core13
	bra	core14
	bra	core15
	bra	core16
	bra	core17
	bra	core18
	bra	core19
	bra	core20
	bra	core21
	bra	core22
	bra	core23
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24
	bra	core24


seqpntr
	dc.l	musicdata+6	
;****************************************************************************	
exit
	bclr	#0,($60000E)		;pull lines high
	bclr	#1,($60000E)
	bclr	#6,($60000C)		;disable direct sound
	
	move.l	(a7)+,($000078)		;restore auto-int 6 vector
	move.l	(a7)+,($000074)		;restore auto-int 5 vector
	bset	#2,($600001)
	
	move.b	#$cc,($600017)		;restore timer speed
	
	movem.l (a7)+,d0-d7/a0-a6 	;restore all regs
	
	move.w	(a7)+,d0		;restore interrupts
	trap	#1
	
	;jsr	tios::OSLinkReset
	ROM_CALL OSLinkReset
	rts

;****************************************************************************	
int5
	;andi.l	#$ffff,d0
	;move.l	d0,a0			;preserve d0
	move.w	(a7)+,d0
	move.l	(a7)+,a6
	lea	core0(PC),a6		;modify return point
	move.l	a6,-(a7)
	move.w	d0,-(a7)
	
rdptn	
	move.w	(a1)+,d0		;read ctrl word
	cmpi.w	#$ffff,d0		;check for ptn end
	beq.s	rdseq
	
	ror.b	#1,d0
	bcs	\rdch3
	moveq	#$0,d7
	moveq	#$0,d3
	move.w	(a1)+,d3
	movea.l	(a1)+,a5
	
\rdch3
	ror.b	#1,d0
	bcs	\rdch2
	moveq	#$0,d6
	moveq	#$0,d2
	move.w	(a1)+,d2
	movea.l	(a1)+,a4
	
\rdch2
	ror.b	#1,d0
	bcs	\rdch1
	moveq	#$0,d5
	moveq	#$0,d1
	move.w	(a1)+,d1
	movea.l	(a1)+,a3
	
\rdch1
	ror.b	#1,d0
	bcs	\rdnone
	moveq	#$0,d4
	moveq	#$0,d0
	move.w	(a1)+,d0
	movea.l	(a1)+,a2
	move.l 	d0,a0
\rdnone
	moveq	#$0,d4
	moveq	#$0,d5
	moveq	#$0,d6
	moveq	#$0,d7
	lea	jumptab(PC),a6
	rte

rdseq
	movea.l	(seqpntr),a0
	movea.l	(a0)+,a1
	move.l	a0,(seqpntr)
	tst	(a0)
	bne.s	rdptn	
	
	lea	sloop(PC),a0		;load loop point
	move.l	a0,(seqpntr)
	bra.s	rdptn

;****************************************************************************	
int6
	move.w	(a7)+,d0
	move.l	(a7)+,a0
	lea	exit(PC),a0		;modify return point
	move.l	a0,-(a7)
	move.w	d0,-(a7)
	move.w	d0,($60001a)		;acknowledge auto-int 6
	rte	
	
	even
musicdata
	INCLUDE "music.asm"
