( a super basic IF engine in Forth )

( structure definitions, this time with string support )

: <STRUCT 
	<BUILDS 0 , HERE 2 -
DOES>
	@ ;
	
: | SWAP DUP @ <BUILDS ,  DUP ROT SWAP +! DOES>  @ + ;

: W| 2 | ;
: C| 1 | ;
: $| 3 | ;

: GET-DESC DUP C@ SWAP 1+ @ SWAP ;

: STRUCT> DROP ;

( array support )

: [] SWAP <BUILDS DUP , * 1 + ALLOT  DOES> DUP @ ROT * + 2 +  ; 

( string variables )

: $ <BUILDS 34 WORD HERE C@ 1 + ALLOT DOES> ;

( string literals )

: ($") R COUNT DUP 1+ R> + >R  ;
: $" 34 ( STATE @ IF ) COMPILE ($") WORD HERE C@ 1+ ALLOT ( ELSE WORD HERE COUNT ENDIF ) ; IMMEDIATE

( convert a character to upper case )

: TO-UPPER 95 AND ;

( track numbers of locations and objects )

0 VARIABLE LOCATION-COUNT 
0 VARIABLE OBJECT-COUNT 

( locaton flags: only two, whether a location has been visited and whether it is dark in the location )

1 CONSTANT VISITED
2 CONSTANT DARK

( all locations have an id, a brief description and some flags  )

<STRUCT LOCATION-STRUCT
	W| LOCATIONSTRUCT-ID 
	$| LOCATIONSTRUCT-DESC
	W| LOCATIONSTRUCT-FLAGS
STRUCT>

( up to 128 locations, although probably too many )

LOCATION-STRUCT 128 [] LOCATIONS

( sets the location description in the current the locatio )

: LOCATION-DESC:  34 WORD HERE DUP C@ 1 + ALLOT  
				LOCATION-COUNT @ 1 - LOCATIONS >R 
				DUP C@ R LOCATIONSTRUCT-DESC C! 
				1+ R LOCATIONSTRUCT-DESC 1 + ! R> DROP ;

( sets the flags for the current location )

: ->LOCATION-FLAGS LOCATION-COUNT @ 1 - LOCATIONS LOCATIONSTRUCT-FLAGS ! ;

( words to add or remove flags )

: +FLAG DUP @ ROT OR SWAP ! ;   			
: -FLAG DUP @ ROT MINUS 1 - AND SWAP ! ; 		
 
( set the location id for the current location - this is similar, and expressed in terms of, creating a constant )

: LOCATION-ID: LOCATION-COUNT @ DUP 1 LOCATION-COUNT +! CONSTANT  LOCATIONS LOCATIONSTRUCT-ID  LATEST PFA SWAP ! ;  

( some special location ids )

LOCATION-ID: DESTROYED
LOCATION-ID: CARRIED
LOCATION-ID: WORN

( an object just has a location and a brief description )

<STRUCT OBJECT-STRUCT
	W| OBJECT-LOCATION
	$| OBJECT-DESC 
STRUCT>

( up to 128 objects )

OBJECT-STRUCT 128 [] OBJECTS 

( set the description for the current object )

: OBJECT-DESC: 34 WORD HERE DUP C@ 1 + ALLOT  
				OBJECT-COUNT @ 1 - OBJECTS >R 
				DUP C@ R OBJECT-DESC C! 
				1+ R OBJECT-DESC 1 + ! R> DROP ;

( set the id for the current object )

: OBJECT-ID: OBJECT-COUNT @ 1 OBJECT-COUNT +! CONSTANT ;  

( set the location of the current object by looking for it in the dictionary. The location words are constants )
( and executing them returns their index in the location array )

: OBJECT-LOCATION: -FIND IF  
						DROP CFA EXECUTE 
					ELSE 
						DESTROYED 
					ENDIF 
					
					OBJECT-COUNT @ 1 - OBJECTS OBJECT-LOCATION ! ;
				


( some words for parsing )

0 VARIABLE BUF-PTR
0 VARIABLE WORD-PTR
0 VARIABLE WORD-LEN

( two string variables to store the input buffer and the look-up word being assembled )

$ BUF "                                                    "
$ WORD-BUF "                                               "

( lots of code to do parsing and dispatch )

: WORD-PTR-0! 0 WORD-LEN !  WORD-BUF COUNT DROP WORD-PTR ! ;
: WORD-PTR+! WORD-PTR @ C! 1 WORD-PTR +! ;

( mask of the length from the word string returned by NFA )

: WORD-NAME NFA COUNT 127 AND ;

( drop the word buffer onto the stack as "count string" )

: WORD-BUF-COUNT WORD-PTR @ WORD-LEN @ -  WORD-LEN @ ;

( print the word buffer for debugging purposes )

: .WORD-BUF  WORD-BUF-COUNT  TYPE ;

( append the word on the stack to the word buffer )

: ++ DUP WORD-LEN +! OVER + SWAP DO I C@ WORD-PTR+! LOOP ;

: MOVE-WORD-BUF
		  HERE 
		  WORD-LEN @ C,   
		  WORD-LEN @ 0 DO WORD-BUF COUNT DROP I + C@  C,  LOOP DP !  ;

( copy the string on the stack to the next free address in Forth. The FIND words will only work on strings here )

: CMOVE-HERE
	HERE							
	ROT								
	ROT 							
	DUP C,						   
	OVER +							
	SWAP 							
	DO I C@ 127 AND C, LOOP 0 C, 0 C, DP ! ; 
	
( get the address of the word to look-up, copy it to here and attempt to find and execute it )

: DISPATCH-ACTION	
		  WORD-BUF-COUNT
		  CMOVE-HERE		
		  HERE LATEST  (FIND) IF 
			DROP CFA EXECUTE 
			1
		  ELSE
			0
		  ENDIF ;

: PARSE-SPACES BEGIN BUF-PTR @ C@ 32 = WHILE 1 BUF-PTR +! REPEAT ;
: PARSE-CHARS BEGIN BUF-PTR @ C@ DUP 32 = SWAP 0 = OR 0= WHILE BUF-PTR @ C@ TO-UPPER WORD-PTR+! 1 WORD-LEN +!  1 BUF-PTR +! REPEAT ;
: PARSE-VERB-NOUN  WORD-PTR-0! PARSE-SPACES $" -" ++ PARSE-CHARS $" -" ++  PARSE-SPACES PARSE-CHARS  ;
: READ-INPUT  BUF COUNT EXPECT CR   BUF COUNT DROP BUF-PTR ! ;

( read input, parse the phrase, dispatch action - if no action was dispatched respond with no understanding )

: PARSE	  READ-INPUT
		  PARSE-VERB-NOUN
		  DISPATCH-ACTION 0= IF 
			." I don't understand" CR 
		  ENDIF ;

( the player's current location )

0 VARIABLE PLAYER-LOCATION 

( append the player's location to the string on the stack ) 

: ++PLAYER-LOCATION PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-ID @ WORD-NAME ++ ;

( perform a location action )

: LOCATION-ACTION  WORD-PTR-0! ++ ++PLAYER-LOCATION DISPATCH-ACTION ;

( termination condition )

0 VARIABLE QUIT-FLAG 

( the standard cannot move there response )

: CANT-GO ." You can't go that way." CR ;

( tests for various object conditions )		

: CARRIED?  OBJECT-LOCATION @ CARRIED = ;
: WORN? OBJECT-LOCATION @  WORN = ;
: PRESENT? >R 
		   R CARRIED?
		   R WORN? OR
		   R OBJECT-LOCATION @ PLAYER-LOCATION @  = OR 
R> DROP ;

( quit )

: -BYE- ." see you later!" CR 1 QUIT-FLAG ! ;

( print the objects that a player is carrying and return the number printed )

: INVENTORY 
	0 >R
	OBJECT-COUNT @  0 DO 
						I OBJECTS OBJECT-LOCATION @ CARRIED = IF
								I OBJECTS OBJECT-DESC GET-DESC TYPE CR
								ELSE
									I OBJECTS OBJECT-LOCATION @ WORN = IF
											I OBJECTS OBJECT-DESC GET-DESC TYPE ."  (worn)" CR
											R> R> R> 1 + >R >R >R 
											ENDIF
								ENDIF
					LOOP R> ;	
																			
( actions to show inventory )
																			
: -I- 	
		." You are carrying: " CR 
		INVENTORY 0= IF  ." nothing" CR ENDIF ;
							
: -INVENTORY- -I- ;
			
( generic examine )

: EXAMINE-* 
	OBJECTS >R 
	R PRESENT? IF
		R OBJECT-DESC GET-DESC TYPE CR  
	ELSE
		." I don't see that here"
	ENDIF 
R> DROP ;

( generic take )

: TAKE-* OBJECTS >R
	R CARRIED? R WORN? OR IF
		." You already have it" CR
		ELSE R PRESENT? IF 
			CARRIED R OBJECT-LOCATION !
			." Taken" CR
	ELSE
		." You can't" CR
	ENDIF 
	ENDIF 
R> DROP ;

( generic drop )

: DROP-* OBJECTS >R 
	R CARRIED? R WORN? OR IF
		PLAYER-LOCATION @ R OBJECT-LOCATION !
		." Dropped"  CR
	ELSE
		." You're not carrying it" CR 
	ENDIF 
R> DROP ;

( test to see if anything is in a location ) 

: ANYTHING? 0 >R OBJECT-COUNT @ 0 DO 
					I OBJECTS OBJECT-LOCATION @ PLAYER-LOCATION @ = IF 
					R> R> R> 1 >R >R >R 
					ENDIF
				LOOP R> ; 

( list other visible objects )

: ALSO-SEE  ANYTHING? IF ." You can also see:" CR 
			OBJECT-COUNT @ 0 DO 
				I OBJECTS OBJECT-LOCATION @ PLAYER-LOCATION @ = IF 
						I OBJECTS OBJECT-DESC GET-DESC TYPE CR 
					ENDIF 
				LOOP 
			ENDIF ;

( briefly describe a location )

: BRIEF	    PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-FLAGS @ DARK AND IF
					." It is dark here"
			 ELSE
					PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-DESC  GET-DESC TYPE CR 
			ENDIF ;
		
( look action - if there is a specific look action associated with this loction, run it. Otherwise use the brief )
( description. Show any objects )
		
 : -LOOK- $" -LOOK-" LOCATION-ACTION 0= IF  BRIEF  ENDIF  ALSO-SEE ;	

( show the full location description )

: FULL 	PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-FLAGS @ DARK AND IF
					." It is dark here"
			ELSE
					-LOOK-
					 VISITED PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-FLAGS +FLAG 
			ENDIF ;
	
( print the name of the current location, showing the full description if this is the first visit )
( otherwise the brief description )

: CHANGE-LOCATION 
			PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-FLAGS @ VISITED AND IF 
								BRIEF
							ELSE
								FULL  
							ENDIF ;
							
( handle movement actions - if a movement action is possible, describe the new location )

: -N-  $" -N-" LOCATION-ACTION 0= IF CANT-GO ELSE CHANGE-LOCATION  ENDIF ;
: -S-  $" -S-" LOCATION-ACTION 0= IF CANT-GO ELSE CHANGE-LOCATION  ENDIF ;
: -E-  $" -E-" LOCATION-ACTION 0= IF CANT-GO ELSE CHANGE-LOCATION  ENDIF ;
: -W-  $" -W-" LOCATION-ACTION 0= IF CANT-GO ELSE CHANGE-LOCATION  ENDIF ;