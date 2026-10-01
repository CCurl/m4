( The default app )

: ll z" ls -l" system ;
: lg z" lazygit" system ;

: .nwb ( n width base-- )
    base @ >r  base !  >r <# r> 1- for # next #s #> ztype  r> base ! ;
: .hex     ( n-- )  #2 $10 .nwb ;

: aemit ( ch-- )  dup #31 $7F btwi if0 drop '.' then emit ;
: t0    ( addr-- )  >x $10 for c@x+ aemit next <x ;
: dump  ( addr n-- )  0 >xyz y@ for
     z@+ if0 x@ cr .hex ." : " then c@x+ .hex space
     z@ $10 = if 0 z! space space x@ $10 - t0 then
   next <xyz ;

( some benchmarks )
: lap ( --n ) timer ;
: .lap ( n-- ) lap swap - space . ." ticks" cr ;

: mil 1000 dup * * ;
: fib ( n--fib ) 1- dup 2 < if drop 1 exit then dup fib swap 1- fib + ;
: t0 ( n a-- ) ztype '(' emit dup (.) ')' emit lap swap ;
: bm-while ( n-- ) z" while " t0 begin 1- -while drop .lap ;
: bm-loop  ( n-- ) z" loop "  t0 for next .lap ;
: bm-fib   ( n-- ) z" fib "   t0 fib space (.) .lap ;
: bm-fibs  ( n-- ) 1 >x for x@+ bm-fib next <x ;
: bb ( -- ) 1000 mil bm-loop ;
: bm-all ( -- ) 250 mil bm-while bb 35 bm-fib ;

( simple fixed point )
: f. ( n-- )    100 /mod (.) '.' emit abs 2 10 .nwb ;
: f* ( a b--c ) * 100 / ;
: f/ ( a b--c ) swap 100 * swap / ;
: f+ ( a b--c ) + ;
: f- ( a b--c ) - ;

( Random numbers )
val seed@   (val) t2
: seed! ( n-- ) t2 ! ;

: random ( --n )
    seed@
    dup 8192 * xor
    dup 131072 / xor
    dup 32 * xor
    dup seed! ;

: rand-max ( max--n ) random abs swap mod ;
timer seed!

( ANSI color codes )
: csi  27 emit '[' emit ;
: ->cr ( c r-- ) csi (.) ';' emit (.) 'H' emit ;
: cls  csi ." 2J" 1 dup ->cr ;
: fg   csi ." 38;5;" (.) 'm' emit ;
: black    0 fg ;      : red     203 fg ;
: green   40 fg ;      : yellow  226 fg ;
: blue    63 fg ;      : purple  201 fg ;
: cyan   117 fg ;      : grey    246 fg ;
: white  255 fg ;

( *** Banner *** )
: .version version <# # # #. # # #. #s 'v' hold #> ztype ;
: .banner
    yellow ." m4 " green .version white ."  - Chris Curl" cr
    yellow ."   Memory: " white mem-sz . ." bytes." cr
    yellow ."     Code: " white vars mem - cell / . ." cells, used: " here . cr
    yellow ."     Vars: " white last vars - . ." bytes, used: " vhere vars - . cr
    yellow ."     Dict: " white dict-end last - .  ." bytes used" cr
    ." hello." cr ;
.banner
