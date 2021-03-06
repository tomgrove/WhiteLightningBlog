( A fairly bad version of the arcade game frogger )

: BYTE-ARRAY
	CREATE 
		 ALLOT 
	DOES>
		SWAP 2 * + ;
		

( surprsingly, WL does not provide shift instructions which is a problem        )
( given that calculating sprite frames involves divisions; although its         )
( slightly cheating, we will add a special /2 word to quickly do divisions by 2 )

HEX

: /2X  CREATE ;CODE E1 C, 					( push hl )
					AF C,		        ( xor a )
					CB C, 1C C, 		( rr h )
					CB C, 1D C,             ( rr l )
					E5 C,                   ( pop hl )
					C3 C, 45 C, 61 C,       ( jp Next )
			  SMUDGE
			  
/2X  /2 SMUDGE

DECIMAL 

( express division by 8 as three divisions by 2 )

: /8 /2 /2 /2 ;

0 VARIABLE FROG-X
0 VARIABLE FROG-Y
0 VARIABLE HOP-DY 
0 VARIABLE DEAD
0 VARIABLE FROG-COUNT
0 VARIABLE LIVES
0 VARIABLE TIME-LOW
0 VARIABLE TIME-X

( decrease the time )

: DEC-TIME
	-1 TIME-LOW +!
	TIME-X @ COL ! 1 HGT ! 1 LEN ! 22 ROW ! SCL1V 
	TIME-LOW @ 0= IF 
		 8 TIME-LOW !
		-1 TIME-X +!
	ENDIF ;

( check for expiry )

: TIME-EXPIRED
	TIME-X @ 8 = 
	TIME-LOW @ 8 = 
	AND
;

( array to store frog homes ) 

4 BYTE-ARRAY HOMES SMUDGE

( setup frog sprites )

: CLR-SPRITE SPN ! >R TEST DROP DPTR @ HGT @  LEN @ * DUP 8 * + R> FILL ;
: MK-SPRITES SPN ! TEST DROP  1 LEN +! 4 0 DO DUP I +  SPN !  ISPRITE 0 SPN @ CLR-SPRITE LOOP DROP ;
: MK-MASK-SPRITES SPN ! TEST DROP  1 LEN +! 4 0 DO DUP I +  SPN !  ISPRITE 255 SPN @ CLR-SPRITE LOOP DROP ;
: CP-SPRITES 0 SROW ! 0 SCOL ! SP1 ! 4 0 DO DUP I + DUP SPN ! SP2 ! GWBLM I 1 + 0 DO  SCR1M SCR1M LOOP LOOP DROP ;
: CP-MASK-SPRITES 0 SROW ! 0 SCOL ! SP1 ! 4 0 DO DUP I + DUP SPN !  SP2 ! GWBLM I 1 + 0 DO  WRR1M WRR1M LOOP LOOP DROP ;

( select frog sprite image to draw )

: FROG-FRAME SWAP 7 AND /2 + ;
: CHECK-HOP FROG-Y @ /8 1 AND 1 = ;

: FROG-IMAGE CHECK-HOP IF 24 ELSE 20 ENDIF ;
: FROG-MASK CHECK-HOP IF 36 ELSE 32 ENDIF ;

( draw the masked frog into the off screen buffer )

: DRAW-FROG /8 SROW ! 
			DUP DUP 
			/8 SCOL ! 
			FROG-MASK  FROG-FRAME SP1 !  
			255 SP2 ! GWNDM  
			FROG-IMAGE FROG-FRAME SP1 ! GWORM  ;

( display the buffer )

: DISPLAY-BUFFER 255 SPN ! 4 COL ! 2 ROW ! PUTBLS ;

( make the sprites used for the background )

: MK-BACKBUFFER 255 SPN ! 24 LEN ! 20 HGT ! ISPRITE CLSM ;
: MK-LANE SPN ! 24 LEN ! 2 HGT ! ISPRITE CLSM ;
: MK-COLLISION 100 SPN ! 3 LEN ! 2 HGT ! ISPRITE CLSM ;

( setup graphics outside of the off screen buffer )

: DRAW-BANK 11 SP1 ! 24 0  24 0 DO I SCOL ! 0 SROW ! GWBLM 18 LOOP ; 
: DRAW-HOME DUP >R 11 SPN ! 6 * 4 + COL ! 0 ROW ! PUTBLS 1 COL +! PUTBLS  1 COL +! R> DUP HOMES @ IF 13 SPN ! PUTBLS ENDIF >R 11 SPN ! 2 COL +! PUTBLS 1 COL +! PUTBLS R> ;
: DRAW-HOMES 4 0 DO I DRAW-HOME LOOP ;
: DRAW-TIME 4 COL ! 22 ROW ! 24 LEN ! 1 HGT ! 7 INK 0 PAPER 1 BRIGHT CLSV 
            9 COL ! 2 LEN ! 2 INK CLSV 
			11 COL ! 4 LEN ! 6 INK CLSV 
			14 COL ! 14 LEN ! 4 INK CLSV 
			22 ROW ! 4 COL ! 17 SPN ! PUTBLS  22 ROW ! 28 9 DO I COL ! 16 SPN ! PUTBLS LOOP ;

( reset the frog )

: NEW-LIFE 0 DEAD ! 146 FROG-Y ! 96 FROG-X ! 0 HOP-DY ! ;

: GET-HOME 
	DUP 1 = IF DROP  0 ELSE 
	DUP 4 = IF DROP  1 ELSE 
	DUP 7 = IF DROP  2 ELSE 
	   10 = IF 3 ELSE -1 
	ENDIF ENDIF ENDIF ENDIF 
 ;

( create the sprites used for the traffic, river and banks )

: DRAW-LOG 8 SP1 !  SCOL ! 0 SROW ! GWBLM  2 SCOL +! 9 SP1 ! 1 DO GWBLM 2 SCOL +! LOOP 10 SP1 ! GWBLM ;
: MK-LOGS MK-LANE SPN @ SP2 ! 0 DO DRAW-LOG LOOP ;
: MK-LOGLANES 4 12 3 0 2 254 MK-LOGS 
              1 8  1 1 2 253 MK-LOGS  ;

: DRAW-CAR SP1 ! SCOL ! 0 ROW ! GWBLM ;
: MK-CARS MK-LANE SPN @ SP2 ! 0 DO DRAW-CAR LOOP ;
: MK-CARLANES  10 3 0 3 2 252 MK-CARS 
			   18 4 6 5 2 251 MK-CARS  ;
			   
: MK-BANK 250 MK-LANE SPN @ SP2 ! DRAW-BANK ;

( check frog against back buffer )

( : DBG-DRAWCOLLIDE 100 SPN ! 0 COL ! 0 ROW ! PUTBLS ; )
: IS-COLLIDE FROG-X @ /8 SCOL ! 
		     FROG-Y @ /8 SROW ! 
			 100 SP1 ! 
			 255 SP2 ! PWBLM  
			 100 SP2 ! 
			 FROG-X @ 
			 20 FROG-FRAME SP1 ! 
			 0 SCOL ! 0 SROW ! 
			 GWNDM  ( DBG-DRAWCOLLIDE ) 
			 100 SPN ! SCANM ;

( draw all the background elements into the off screen buffer )

: DRAW-BG 		255 SP2 ! 0 SROW ! 0 SCOL !  
				254 SP1 ! GWBLM 2 SROW +! 
				253 SP1 ! GWBLM 2 SROW +!
				254 SP1 ! GWBLM 2 SROW +!
				253 SP1 ! GWBLM 2 SROW +!
				250 SP1 ! GWBLM 2 SROW +!
				252 SP1 ! GWBLM 2 SROW +! 
				251 SP1 ! GWBLM 2 SROW +!
				252 SP1 ! GWBLM 2 SROW +!
				251 SP1 ! GWBLM 2 SROW +! 
				250 SP1 ! GWBLM 2 SROW +!
				;
				
( update the off screen buffer )

: UPDATE-BG 254 SPN ! WRL1M WRL1M 253 SPN ! WRR1M WRR1M
			252 SPN ! WRL4M 251 SPN ! WRR1M ;

( checks for the frog being home )

: ON-HOME-BANK FROG-Y @ 0 < ;
: OCCUPY-HOME 1 FROG-X @ 8 + /8 /2 GET-HOME HOMES ! NEW-LIFE ;
: FREE-HOME FROG-X @ 8 + /8 /2 GET-HOME DUP -1 > IF HOMES ELSE DROP 0 ENDIF ; 

( move the frog by the appropriate amount if its on a log )

: MOVE-ON-LOG FROG-Y @ /8 /2 1 AND IF 2 FROG-X +! ELSE -2 FROG-X +! ENDIF ;

( check for home )

: CHECK-HOME  ON-HOME-BANK IF 
						FREE-HOME IF OCCUPY-HOME DRAW-HOMES
								  ELSE 1 DEAD ! 0 FROG-Y ! 
								  ENDIF
						ENDIF ;

( check for screen bounds )

: CHECK-BOUNDS FROG-X @ 0 < IF 
							1 DEAD  ! 0 FROG-X !  
						  ELSE 
							FROG-X  @ 174 > IF 
											174 FROG-X ! 1 DEAD  ! 
										  ENDIF 
						  ENDIF 
			   FROG-Y @ 146 > IF 
								146 FROG-Y ! 
							 ENDIF ;
						
( check if on a "safe" bank )
						
: CHECK-ON-BANK FROG-Y @ /8 /2 
	DUP 4 = IF 1 ELSE 
	    9 = IF 1 ELSE 0 
	ENDIF ENDIF  ;

( do the off screen buffer checks )

: HITS FROG-Y @ /8 7 > IF 
						IS-COLLIDE IF  1 DEAD ! ENDIF 
					ELSE 
						IS-COLLIDE IF MOVE-ON-LOG ELSE 1 DEAD ! ENDIF 
					ENDIF ;
					
( do all the checks )
					
: CHECK-ALL CHECK-HOME CHECK-ON-BANK  CHECK-HOP OR  0= IF HITS ENDIF  CHECK-BOUNDS ;
			
( get key press and move the frog )
			
: MOVE-FROG 6 2 KB IF 
					-4 FROG-X +!  
				   ENDIF 
			6 1 KB IF 
					 4 FROG-X +! 
				   ENDIF 
				   
			HOP-DY @ 0= IF 
				2 1 KB IF 
						8 HOP-DY !
					    8 FROG-Y +!   
					   ENDIF  
				3 1  KB IF
						-8 HOP-DY !
						-8 FROG-Y +! 
					   ENDIF 
			ELSE 
					HOP-DY @ FROG-Y +!
					0 HOP-DY !
			ENDIF ;
				   
( tick the game )
				   
: TICK-GAME 
	MOVE-FROG 
	UPDATE-BG 
	DRAW-BG 
	CHECK-ALL 
	FROG-X @ FROG-Y @  DRAW-FROG  
	DEC-TIME ;

( setup screen attributes )

: SETUP-ATTR 2 HGT ! 1 + LEN ! ROW ! COL ! SETAV ;

: SETUP-RIVERATTRS 1 BRIGHT 2 INK 1 PAPER 4 COL ! 24 LEN ! 8 HGT ! 2  ROW ! CLSV ;
: SETUP-ROADATTRS  1 BRIGHT 3 INK 0 PAPER 4 COL ! 24 LEN ! 8 HGT ! 12 ROW ! CLSV ;

: SETUP-BANKATTRS 24 LEN ! 4 COL ! 2 HGT ! 
	4 INK 1 PAPER 1 BRIGHT
	0 ROW ! SETAV
	4 INK 0 PAPER 1 BRIGHT
	10 ROW ! SETAV
	20 ROW ! SETAV ; 

: SETUP-SCR 0 BORDER 7 INK 0 PAPER CLS 
    SETUP-RIVERATTRS
	SETUP-ROADATTRS
	SETUP-BANKATTRS
	DRAW-HOMES	
	DRAW-TIME ;

( main loop )

: NEW-LEVEL 0 FROG-COUNT ! 4 0 DO 
									0 I HOMES ! 
							   LOOP SETUP-SCR  28 TIME-X  ! 8 TIME-LOW ! ;

: NEW-GAME 3 LIVES !  ;
	
: END-GAME-LOOP DEAD @ FROG-COUNT @ 4 = OR TIME-EXPIRED  OR ;

: GAME-LOOP   BEGIN  
				TICK-GAME 
				DISPLAY-BUFFER
			  END-GAME-LOOP UNTIL DEAD @ IF -1 LIVES +! ENDIF  ;
			 
: END-LEVEL-LOOP LIVES @ 0 = FROG-COUNT @ 4 = OR TIME-EXPIRED  OR ;
			 
: LEVEL-LOOP  NEW-LEVEL 
					BEGIN 
						NEW-LIFE GAME-LOOP 
					END-LEVEL-LOOP UNTIL ;

: OUTER-LOOP  EI BEGIN 
					NEW-GAME BEGIN 
								LEVEL-LOOP 
							 LIVES @ 0 = TIME-EXPIRED OR UNTIL 
				   AGAIN ;
( title screen )

: TITLE 0 BORDER 4 INK 0 PAPER CLS 
	9 COL ! 12 ROW ! 18 SPN ! PUTBLS ;

( setup all the sprites )

: SETUP-SPRITES  
	4 SPN ! MIRM 
	MK-BANK 
	MK-LOGLANES 
	MK-CARLANES 
	MK-BACKBUFFER 
	MK-COLLISION 
	20 1   MK-SPRITES 20 1 CP-SPRITES 
	24 2   MK-SPRITES 24 2 CP-SPRITES
	32 14  MK-MASK-SPRITES 32 14 CP-MASK-SPRITES 
	36 15  MK-MASK-SPRITES 36 15 CP-MASK-SPRITES ; 

: MAIN ATTOFF TITLE SETUP-SPRITES OUTER-LOOP ; 

( build a standalone version )

ZAP 
