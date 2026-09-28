( some examples )

( a circular stack )
32 cells var stk
val sp@   (val) t0
: sp! ( n-- ) 127 and t0 ! ;
: s@  ( --n ) stk sp@ + @ ;
: s!  ( n-- ) stk sp@ + ! ;
: >s  ( n-- ) sp@ cell + sp! s! ;
: s>  ( --n ) s@ sp@ cell - sp! ;

val x@   (val) t0   : x! ( n-- ) t0 ! ;
val y@   (val) t0   : y! ( n-- ) t0 ! ;
val z@   (val) t0   : z! ( n-- ) t0 ! ;

: >x ( n-- ) x@ >s x! ;  : >y ( n-- ) y@ >s y! ;  : >z ( n-- ) z@ >s z! ;
: <x ( -- )  s> x! ;     : <y ( -- )  s> y! ;     : <z ( -- )  s> z! ;
: x> ( --n ) x@ <x ;     : y> ( --n ) y@ <y ;     : z> ( --n ) z@ <z ;

: >xy ( x y-- ) >y >x ;  : >xyz ( x y z-- ) >z >y >x ;
: <xy ( -- )    <x <y ;  : <xyz ( -- )      <x <y <z ;
