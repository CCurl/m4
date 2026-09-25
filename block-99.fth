( some examples )

( a circular stack )
128 var astk
val asp@   (val) t0
: asp! ( n-- ) 127 and t0 ! ;
: asp++ ( -- ) asp@ 4 + asp! ;
: asp-- ( -- ) asp@ 4 - asp! ;
: astk@ ( --n ) astk asp@ + @ ;
: astk! ( n-- ) astk asp@ + ! ;
: >astk ( n-- ) asp++ astk! ;
: astk> ( --n ) astk@ asp-- ;

( a & b variables similar to ColorForth )
val a@   (val) t0   : a! ( n-- ) t0 ! ;
val b@   (val) t0   : b! ( n-- ) t0 ! ;

: <a ( -- )  astk> a! ;      : <b ( -- )  astk> b! ;
: a> ( --n ) a@ <a ;         : b> ( --n ) b@ <b ;
: >a ( n-- ) a@ >astk a! ;   : >b ( n-- ) b@ >astk b! ;

: >ab ( a b-- ) >b >a ;
: +ab ( -- ) 0 dup >ab ;
: -ab ( -- ) <a <b ;
