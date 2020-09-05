( forth to just create the sprites. This file can be compiled, loaded into an emulator then )
( have SETUP-SPRITES run. At this point, this code be "forgotten" with FORGET SPRITE-BASE  ) 
( this rolls back the dictionary to before the definition of SPRITE-BASE. The sprites themselves )
( live in sprite memory and will be preserved. This snapshot can then be saved and used as the base )
( for the game itself )

0 VARIABLE LASTHERE 
0 VARIABLE FIRSTHERE 

HERE DUP LASTHERE ! FIRSTHERE !

0 VARIABLE SPRITE-BASE 

: MK-SPRITES16 SPN ! TEST DROP  1 LEN +!  1 HGT +! 16 0 DO DUP I +  SPN !  ISPRITE CLSM  LOOP DROP ;
: MK-SPRITES4 SPN ! TEST DROP  1 LEN +!   4 0 DO DUP I +  SPN ! ISPRITE CLSM  LOOP DROP ;

: CP-SPRITES16-H 0 SROW ! 0 SCOL ! SPRITE-BASE  ! 
					16 0 DO 
						I 3 AND SPRITE-BASE @ + SP1 !
						DUP I + DUP SPN ! SP2 ! 
						GWBLM I 3 AND 1 + 0 DO  
							SCR1M SCR1M 
						LOOP 
					LOOP DROP ;
					
: CP-SPRITES4-H 0 SROW ! 0 SCOL ! SPRITE-BASE  ! 
					4 0 DO 
						I 3 AND SPRITE-BASE @ + SP1 !
						DUP I + DUP SPN ! SP2 ! 
						GWBLM I 3 AND 1 + 0 DO  
							SCR1M SCR1M 
						LOOP 
					LOOP DROP ;
					
: CP-SPRITES16-H-DUP 0 SROW ! 0 SCOL ! SPRITE-BASE  ! 
					16 0 DO 
						SPRITE-BASE @ SP1 !
						DUP I + DUP SPN ! SP2 ! 
						GWBLM I 3 AND 1 + 0 DO  
							SCR1M SCR1M 
						LOOP 
					LOOP DROP ;
					
: CP-SPRITES16-V SPRITE-BASE  !  16 4 DO I  4 / ( 2 / 2 )  MINUS NPX ! SPRITE-BASE @ I + SPN ! WCRM WCRM  LOOP ; 

: MK-SPRITE SPN ! HGT ! LEN ! ISPRITE CLSM  ;

( : MK-TILEBUFFER 254 SPN ! 32 LEN ! 17 HGT ! ISPRITE CLSM 7 INK 0 PAPER 1 BRIGHT SETAM ; )
( : MK-TEMPTILE 252 SPN ! 1 LEN ! 1 HGT ! ISPRITE CLSM ; )
( : MK-DIRTY 253 SPN ! 6 LEN ! 5 HGT ! ISPRITE CLSM ; )
( : MK-TILEMAP 251 SPN ! 32 LEN ! 2 HGT ! ISPRITE CLSM  ; )

: MIRROR-SPRITES 6 1 DO I SPN !  MIRM LOOP ; 

: SETUP-SPRITES
	 1 1 252   MK-SPRITE 
	 32 17 254 MK-SPRITE 7 INK 0 PAPER 1 BRIGHT SETAM  
	 6 5 253   MK-SPRITE  
	 128  1    MK-SPRITES4 128   1 CP-SPRITES4-H  
	 144 ( 128 16 + )  5 MK-SPRITES16  144 ( 128 16 + )   5 CP-SPRITES16-H-DUP  144 ( 128 16 + )  CP-SPRITES16-V 
	MIRROR-SPRITES 
	160  ( 128 32 + ) ( 48 ) 1  MK-SPRITES4 160 ( 128 32 + ) ( 48 )  1 CP-SPRITES4-H ( 2 48 CP-SPRITES4-V  ) 
	 176 ( 128 32 16 + + ) ( 64 ) 5  MK-SPRITES16 176 ( 128 32 16 + + )  ( 64 ) 5 CP-SPRITES16-H-DUP ( 64 )  176 ( 128 32 16 + + )  CP-SPRITES16-V  
	( MK-TILEMAP ) 32 4 251 MK-SPRITE 
	; 
	
." sprite creation "  HERE LASTHERE @  - U. CR HERE LASTHERE ! 