[SEGMENT .text]
GLOBAL GetVidSegment,ClearScreen,WriteString,PrintChar,NewLine,WriteBigChar
GLOBAL IncYPos,WriteLn,WipeScreen

; ------------------------------------------------------------------------------
; GetVidSegment - 1999-06-08
; DOEL     : Zet ES naar de videobuffer door naar ~([0:410h] and 30h) te kijken
;            of de uitkomst 0 is (dan mono,0B000h,anders kleur,0B800h).
; GEBRUIKT : EAX,Flags
; SCHRIJFT : ES
; ------------------------------------------------------------------------------
GetVidSegment:

  push EAX        ; Bewaar register op stack
  pushf           ; Bewaar zero-flag op stack

  INT 0x11        ; Laat BIOS het doen, resultaat in EAX (14 bytes code)
  not AL          ; Draai de 8 bits om
  test AL,0x30    ; Kijk of bit 4 en/of 5 één zijn
  mov AX,0xB800   ; Kleur
  JNE SetBuffer   ; Als bit 4 en/of 5 ongelijk aan één zijn -> kleurenbuffer
    mov AX,0xB000 ; Mono
  SetBuffer:
  mov ES,AX       ; ES bevat het goede segment

  popf            ; Haal zero-flag van stack
  pop EAX         ; Haal register van stack

  RET

; ------------------------------------------------------------------------------
; ClearScreen - 1999-06-08
; DOEL     : Wist het scherm van CX tekens met attribuut AX via een REP stosw
;            Roep eerst GetVidSegment aan voor ES (bevat videosegment)
; GEBRUIKT : DI,CX,Flags
; ------------------------------------------------------------------------------
ClearScreen:

  push CX      ; Bewaar register op stack
  push DI
  pushf        ; Bewaar Flags op stack

  xor DI,DI    ; Linksboven op scherm beginnen
  cld          ; Vooruit in geheugen
  REP stosw    ; Wis het scherm

  popf         ; Herstel Flags
  pop DI       ; Herstel registers
  pop CX

  RET

; ------------------------------------------------------------------------------
; WriteString - 1999-05-27.
; DOEL     : Schrijft een string direct naar het videogeheugen (ES:DI).
;            De string die afgebeeld moet worden staat in DS:SI.
;            De locatie wordt gegeven door (XPos,YPos) en is 0-gebaseerd.
;            De lengte van de string staat in CX en de kleurcode in Attr.
;            Roep eerst GetVidSegment aan voor de waarde van ES.
; LEEST    : [SI],YPos,Attr
; GEBRUIKT : AX,CX,DI,SI,Flags,XPos
; ------------------------------------------------------------------------------
WriteString:

  push AX        ; Bewaar registers op stack
  push CX
  push DI
  push SI
  pushf

  JCXZ NoPrint   ; Geen nulstring afbeelden

  xor AH,AH
  mov AL,[YPos]
  imul DI,AX,160 ; DI=YPos*160, de cursorpositie (YPos = byte, mag niet)
  mov AL,[XPos]  ; AL wordt XPos...
  shl AX,1       ; AX*=2
  add DI,AX      ; DI wordt met XPos*2 verhoogd via AX

  mov AH,[Attr]  ; De kleurcode staat in Attr
  PrintIt:
    lodsb        ; AL bevat nu het SIe teken uit de string, SI++
    stosw        ; In geheugen en DI naar volgende schermcoördinaat
  LOOP PrintIt   ; CX-1, zolang CX > 0 naar PrintIt

  NoPrint:
  popf           ; Haal registers van stack
  pop SI
  pop DI
  pop CX
  pop AX

  RET

; ------------------------------------------------------------------------------
; PrintChar - 1998-04-01
; DOEL      : Beeld het teken wat in Teken staat af op XPos,YPos met kleur Attr.
;             Roep eerst GetVidSegment aan voor de waarde van ES.
; LEEST     : XPos,YPos,Attr,adres Teken
; GEBRUIKT  : CX,SI
; ROEPT AAN : WriteString
; ------------------------------------------------------------------------------
PrintChar:

  push CX          ; Bewaar registers op stack
  push SI

  mov CX,1         ; 1 teken lang
  lea SI,[Teken]   ; Offsetadres
  CALL WriteString ; Beeld het teken af

  pop SI           ; Herstel registers
  pop CX

  RET

; ------------------------------------------------------------------------------
; NewLine - 1999-05-27
; DOEL     : Scrollt het scherm 1 naar boven, t/m regel YPos,de YPos-e regel
;            krijgt de kleur zwart/van het 1e teken YPos-1e regel (in AL).
;            Roep eerst GetVidSegment aan voor ES. Het scherm moet 80x25
;            tekens bevatten (meestal zo).
; LEEST    : YPos,ES
; GEBRUIKT : AX,CX,SI,DI,DS,Flags
; ------------------------------------------------------------------------------
NewLine:

  push AX          ; Bewaar de gebruikte registers
  push CX
  push SI
  push DI
  push DS
  pushf            ; Bewaar de Flags

  push AX
  xor AH,AH
  mov AL,[YPos]
  imul CX,AX,80    ; Teller (=YPos*80)
  pop AX
  mov SI,160       ; Wijst naar de 2e regel
  xor DI,DI        ; Wijst naar de 1e regel
  push ES          ; Zet ES op de stack
  pop  DS          ; En kopieer hem naar DS
  cld              ; Voorwaarts in het videogeheugen
  REP movsw        ; Scroll t/m de YPos-e regel

  mov CX,80        ; De onderste regel bevat 80 tekens
  mov AH,[DI-1]    ; Bevat de kleur van teken op 80:YPos
                   ; AL = 'Û' -> in kleur; AL = ' ' -> in zwart
  REP stosw        ; Wis de onderste regel

  popf             ; Herstel de Flags
  pop DS           ; Herstel de gebruikte registers
  pop DI
  pop SI
  pop CX
  pop AX

  RET

; ------------------------------------------------------------------------------
; WriteBigChar - 1998-10-12.
; DOEL      : Schrijft een teken die beschreven staat in [SI] vergroot op
;             het scherm.
; LEEST     : SI
; GEBRUIKT  : CX,DX,SI,YPos,Flags
; ROEPT AAN : WriteString
; ------------------------------------------------------------------------------
WriteBigChar:

  push CX    ; Bewaar de gebruikte registers
  push DX
  push SI
  pushf      ; Bewaar de zero-flag

  mov CX,8   ; Een regel is 8 tekens breed
  mov DX,8   ; Alle tekens zijn 8 regels lang
  WriteChar:
    CALL WriteString
    inc BYTE [YPos] ; Eén regel naar beneden
    add SI,8 ; 8 verder in [SI]
    dec DX   ; Weer een regel gedaan,dec DL = 2 bytes, dec DX = 1 byte !
  JNZ WriteChar

  sub BYTE [YPos],8 ; Herstel de originele Y-positie
  popf       ; Herstel de zero-flag
  pop SI     ; Herstel de gebruikte registers
  pop DX
  pop CX

  RET

; ------------------------------------------------------------------------------
; IncYPos - 1998-07-12
; DOEL      : Verhoogt YPos als die kleiner is dan 24 en scrollt evt omhoog.
; GEBRUIKT  : YPos,Flags,AX
; ROEPT AAN : NewLine
; ------------------------------------------------------------------------------
IncYPos:

  push AX        ; Bewaar het register
  pushf          ; Bewaar de Flags

  cmp BYTE [YPos],24 ; Moeten we scrollen?
  JB NoScroll    ; Nee
    mov AL,' '   ; Wis de onderste regel met een spatie
    CALL NewLine ; Scroll een regel omhoog
  NoScroll:
  JE NoIncLF     ; Staan we op de onderste regel?
    inc BYTE [YPos] ; Nee,een regel naar beneden
  NoIncLF:

  popf           ; Herstel de Flags
  pop AX         ; Herstel het register

  RET

; ------------------------------------------------------------------------------
; WriteLn - 1998-01-21
; DOEL      : Beeld een boodschap en een CRLF af. Dit is handiger dan 2 aparte
;             procedures aanroepen.
; LEEST     : CX,SI
; ROEPT AAN : WriteString,IncYPos
; ------------------------------------------------------------------------------
WriteLn:

  mov BYTE [XPos],0 ; Aan het begin van de regel
  CALL WriteString ; Beeld de boodschap af
  CALL IncYPos     ; Schuif eventueel een regel omhoog

  RET

; ------------------------------------------------------------------------------
; WipeScreen - 1999-06-08
; DOEL      : Wist het scherm (2000 tekens) met attribuut 0720h
; GEBRUIKT  : AX,CX
; ROEPT AAN : ClearScreen
; ------------------------------------------------------------------------------
WipeScreen:

  push AX      ; Bewaar de registers
  push CX

  mov AX,0x0720 ; Grijs-op-zwart,spatie
  mov CX,80*25  ; breedte*lengte
  CALL ClearScreen

  pop CX       ; Herstel de registers
  pop AX

  RET

[SEGMENT .bss]
EXTERN XPos,YPos,Attr,Teken
