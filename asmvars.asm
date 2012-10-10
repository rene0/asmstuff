[SEGMENT .data]
GLOBAL DaTiStr,Halted,Status
  DaTiStr DB '    -  -     :  :  '
  Halted  DB 0
  Status  DB 1

COMMON Jaar        2
COMMON Maand       1
COMMON Dag         1
COMMON Uur         1
COMMON Minuut      1
COMMON Seconde     1
COMMON WeekDag     1 ; na de tijd vanwege PutDaTiString
COMMON XPos        1
COMMON YPos        1
COMMON Attr        1 ; kleurcode
COMMON Teken       1 ; ASCII-code
COMMON BufLen      1
COMMON BufString 255
