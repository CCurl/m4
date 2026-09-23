( these are created later as -last- and -here- )
( they are used later for rebooting )
(h) @   (l) @

: last (l) @ ;
: here (h) @ ;
: cells  ( n--n' ) cell * ;
: cell+  ( n--n' ) cell + ;
: immediate ( -- ) $80 last cell+ 1 + c! ;
: ->code ( off--addr ) cells mem + ;
: code@  ( off--dw )  ->code @ ;
: code!  ( dw off-- ) ->code ! ;
: , ( dw-- ) here dup 1 + (h) ! code! ;

: bye      ( -- ) 999 state ! ;
: (exit)   ( --n )  0 ;
: (lit)    ( --n )  1 ;
: (jmp)    ( --n )  2 ;
: (jmpz)   ( --n )  3 ;
: (jmpnz)  ( --n )  4 ;
: (njmpz)  ( --n )  5 ;
: (njmpnz) ( --n )  6 ;

: if   (jmpz)   , here 0 , ; immediate
: -if  (njmpz)  , here 0 , ; immediate
: if0  (jmpnz)  , here 0 , ; immediate
: -if0 (njmpnz) , here 0 , ; immediate
: then here swap code!     ; immediate

: begin here ; immediate
: again (jmp)     , , ; immediate
: while (jmpnz)   , , ; immediate
: -while (njmpnz) , , ; immediate
: until (jmpz)    , , ; immediate

( val and (val) define a very efficient variable mechanism )
( Usage:  val a@   (val) @@a   : a! @@a ! ; )
: const ( n-- ) add-word (lit) , , (exit) , ;
:  val  ( -- ) 0 const ;
: (val) ( -- ) here 2 - ->code const ;

( the original here and last - used by 'rb' )
const -last-   const -here-

mem mem-sz + const dict-end
32 ->code const (vh)
64 1024 * ->code const vars
vars (vh) !
: vhere ( --a ) (vh) @ ;
: allot ( n-- ) (vh) +! ;
: var   ( n-- ) vhere const allot ;

( A stack for 3 locals - x,y,z )
30 cells var loc-stk       ( loc-stk: the locals stack start )
vhere 3 cells - const lse  ( lse: the locals stack end )
val x0     (val) @@x       ( x0: address of x, @@x: address of x0 )
val y0     (val) @@y       ( y0: address of y, @@y: address of y0 )
val z0     (val) @@z       ( z0: address of z, @@z: address of z0 )
: xyz! ( a-- ) dup @@x ! cell+ dup @@y ! cell+ @@z ! ;
loc-stk xyz!               ( Initialize )

: x@ ( --n ) x0 @ ;      : x! ( n-- ) x0 ! ;
: y@ ( --n ) y0 @ ;      : y! ( n-- ) y0 ! ;
: z@ ( --n ) z0 @ ;      : z! ( n-- ) z0 ! ;

: +L  ( -- )  z0 lse < if x0 3 cells + xyz! then ;
: -L  ( -- )  x0 loc-stk > if x0 3 cells - xyz! then ;
: +L1 ( x -- )    +L x! ;
: +L2 ( x y-- )   +L y! x! ;
: +L3 ( x y z-- ) +L z! y! x! ;

: x++ ( -- )  1 x0 +! ;    : x@+  ( --n ) x@ x++ ;
: x-- ( -- ) -1 x0 +! ;    : x@-  ( --n ) x@ x-- ;
: c@x ( --b ) x@ c@ ;      : c@x+ ( --b ) x@+ c@ ;  : c@x- ( --b ) x@- c@ ;
: c!x ( b-- ) x@ c! ;      : c!x+ ( b-- ) x@+ c! ;  : c!x- ( b-- ) x@- c! ;

: y++ ( -- )  1 y0 +! ;    : y@+  ( --n ) y@ y++ ;
: y-- ( -- ) -1 y0 +! ;    : y@-  ( --n ) y@ y-- ;
: c@y ( --b ) y@ c@ ;      : c@y+ ( --b ) y@+ c@ ;  : c@y- ( --b ) y@- c@ ;
: c!y ( b-- ) y@ c! ;      : c!y+ ( b-- ) y@+ c! ;  : c!y- ( b-- ) y@- c! ;

: z++ ( -- )  1 z0 +! ;    : z@+  ( --n ) z@ z++ ;

( Strings )
: compiling? ( --n ) state @ 1 = ;
: (") ( --a ) +L vhere dup z! x! 1 >in +!
    begin
        >in @ c@ y! 1 >in +!
        y@ 0 = y@ '"' = or
        if  0 c!x+  z@
            compiling? if (lit) , , x@ (vh) ! then
            -L exit
        then
        y@ c!x+
    again ;

find ztype @ const (ztype)
: z" ( "string"--addr ) (") ; immediate
: ." ( "string"-- ) (") compiling? if (ztype) , exit then ztype ; immediate

( Files )
: fopen-r   ( nm--fh ) z" rb" fopen ;
: fopen-w   ( nm--fh ) z" wb" fopen ;
: ->file    ( fh-- )   output-fp ! ;
: ->stdout  ( -- )     0 ->file ;
: ->stdout! ( -- )     output-fp @ fclose ->stdout ;

( reboot )
: rbb vars y@ + ;
: rb ( -- )
    z" m4-boot.fth" fopen-r -if0 drop ." m4-boot.fth not found" exit then
    z!  50000 y!  rbb x!  y@ for 0 c!x+ next
    rbb y@ z@ fread drop z@ fclose
    -here- (h) !  -last- (l) !
    rbb >in ! ;
: vi z" vi m4-boot.fth" system ;

( More core words )
: 1+ ( n--n' ) 1 + ;
: 1- ( n--n' ) 1 - ;
: [ ( -- ) 0 state ! ; immediate  ( 0 = INTERPRET )
: ] ( -- ) 1 state ! ;            ( 1 = COMPILE )
: rdrop ( -- ) r> drop ;
: tuck  ( a b--b a b )   swap over ;
: nip   ( a b--b )       swap drop ;
: ?dup ( n--n n|0 )  -if dup then ;
: 2dup  ( a b--a b a b ) over over ;
: 2drop ( a b-- )        drop drop ;
: -rot ( a b c--c a b )  swap >r swap r> ;
: 0= ( n--f ) 0 =    ;
: 0< ( n--f ) 0 <    ;
: <= ( a b--f ) > 0= ;
: >= ( a b--f ) < 0= ;
: type ( a n-- ) for dup c@ emit 1+ next drop ;
: btwi ( n l h--f ) >r over <= swap r> <= and ;
: negate ( n--n' ) 0 swap - ;
: abs ( n--n' ) dup 0< if negate then ;
: cr  ( -- )     13 emit 10 emit ;
: tab ( -- )      9 emit ;
: space  ( -- )  32 emit ;
: spaces ( n-- ) for space next ;
: /   ( a b--q ) /mod nip  ;
: mod ( a b--r ) /mod drop ;
: */  ( n m q--n' ) >r * r> / ;
: min ( a b-a|b ) over over > if swap then drop ;
: max ( a b-a|b ) over over < if swap then drop ;
: unloop  ( -- ) (lsp) @ 3 - 0 max (lsp) ! ;
: execute ( xt-- ) ?dup if >r then ;
: decimal  ( -- )  #10 base ! ;
: hex      ( -- )  $10 base ! ;
: binary   ( -- )  %10 base ! ;

   1 var (neg)
  65 var buf
cell var (buf)
: ?neg ( n--n' ) dup 0< dup (neg) c! if negate then ;
: hold ( c-- )   -1 (buf) +! (buf) @ c! ;
: #.   ( -- )    '.' hold ;
: #n   ( n-- )   '0' + dup '9' > if 7 + then hold ;
: #    ( n--m )  base @ /mod swap #n ;
: #s   ( n--0 )  # -if #s exit then ;
: <#   ( n--n' ) ?neg buf 65 + (buf) ! 0 hold ;
: #>   ( n--a )  drop (neg) @ if '-' hold then (buf) @ ;
: (.)  ( n-- )   <# #s #> ztype ;
: .    ( n-- )   (.) space ;

: 0sp 0 (sp) ! ;
: depth ( --n ) (sp) @ 1- ;
: .s '(' emit space depth ?dup if
        stk swap for cell+ dup @ . next drop
    then ')' emit ;

: .word ( de-- ) cell+ 3 + ztype ;
: words ( -- ) +L last x! 0 y! 1 z! begin
        x@ dict-end < if0 '(' emit z@ . ." words)" -L exit then
        x@ .word tab z++
        x@ cell+ 2 + c@ 7 > if y++ then
        y@+ 12 > if cr 0 y! then
        x@ dup cell+ c@ + x!
    again ;

: words-n ( n-- ) +L last x! 0 y! for
        x@ .word tab
        y@+ 12 > if cr 0 y! then
		x@ dup cell+ c@ + x!
    next -L ;

cell var t4   cell var t5
: [[ here t4 !  vhere t5 !  1 state ! ;
: ]] (exit) , 0 state ! t4 @ dup >r (h) ! t5 @ (vh) ! ; immediate
: ms ( ms-- ) timer + begin timer over > until drop ;

( Strings / Memory )
: pad    ( --a ) vhere $100 + ;
: fill   ( a num ch-- ) -rot for 2dup c! 1+ next 2drop ;
: cmove  ( f t n-- )  +L3  z@ if  z@ for c@x+ c!y+ next then -L ;
: cmove> ( f t n-- )  +L3  y@ z@ + 1- y!  x@ z@ + 1- x!  z@ for c@x- c!y- next -L ;
: s-len  ( str--len ) +L1 0 begin c@x+ if0 -L exit then 1+ again ;
: s-end  ( str--end ) dup s-len + ;   ( end: address of the null )
: s-cpy  ( dst src--dst ) 2dup s-len 1+ cmove ;
: s-cat  ( dst src--dst ) over s-end  over s-len 1+  cmove ;
: s-scat ( src dst--dst ) swap s-cat ;
: s-catc ( dst ch--dst )  over s-end  +L1  c!x+  0 c!x+  -L ;
: s-catn ( dst num--dst ) <# #s #> s-cat ;
: s-eqn  ( s1 s2 n--f ) +L3 z@ for c@x+ c@y+ = if0 -L 0 unloop exit then next -L 1 ;
: s-eq   ( s1 s2--f ) dup s-len 1+ s-eqn ;

( Disk: 64 blocks, 16K bytes each )
: kb ( n--m ) 1024 * ;
: mb ( n--m ) kb kb ;
mem mem-sz 2 mb - + const disk
32 var fn
val blk@   (val) (blk)
: #blks     ( --n )   100 ; ( 0 -> 99 )
: blk-sz    ( --n )   10 kb ;
: blk!      ( n-- )   0 max #blks 1- min (blk) ! ;
: blk-fn    ( --a )   fn z" block-" s-cpy blk@ <# # #s #> s-cat z" .fth" s-cat ;
: blk-addr  ( --a )   blk@ blk-sz * disk + ;
: blk-clr   ( -- )    blk-addr blk-sz 0 fill ;
: t0        ( fh-- )  >r  blk-clr  blk-addr blk-sz r@ fread drop  r> fclose ;
: blk-read  ( -- )    blk-fn fopen-r ?dup if0 blk-fn ztype ."  not found." drop exit then t0 ;
: t1        ( fh-- )  >r  blk-addr blk-sz r@ fwrite drop  r> fclose ;
: blk-write ( -- )    blk-fn fopen-w ?dup if0 ." -err-" drop exit then t1 ;
: t2        ( -- )    0 blk-addr blk-sz + 1- c! ;
: load      ( n-- )   blk! blk-read t2 blk-addr outer ;
: load-next ( n-- )   blk! blk-read t2 blk-addr >in ! ;

: fn-blk ( n--a ) blk@ >r blk! blk-fn r> blk! ;
: ed     ( n-- )  pad z" vi " s-cpy swap fn-blk s-cat system ;
( *** App code - starts in block-01 *** )
1 load
