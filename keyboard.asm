; Copyright (c) 1997-2000 René Ladan. All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
; SUCH DAMAGE.

[SEGMENT .text]
GLOBAL GetKey,GetNumber,ActKey
EXTERN PrintChar,MoveCursor

; ------------------------------------------------------------------------------
; GetKey - 1999-06-10.
; DOEL      : Haalt via INTerrupt 16h,functie 11h een toets binnen.
;             In AH staat de scancode, in AL de ASCII-code.
;             Er wordt dus *niet* op een toets gewacht. Als er op een toets werd
;             gedrukt,wordt de buffer gewist via INTerrupt 21h,fuctie 0C06h.
; GEBRUIKT  : DX,Flags
; SCHRIJFT  : AX
; ------------------------------------------------------------------------------
GetKey:

  pushf        ; Bewaar de registers

  mov AH,0x11  ; Kijk of er op een toets wordt gedrukt
  INT 0x16     ; Roep BIOS aan
  JZ NoKey     ; Nee, dan terug

  push AX      ; Bewaar de toets
  push DX
  mov AX,0x0C06; Leeg de toetsenbordbuffer, rechtstreekse console-invoer
  mov DX,255   ; rechtstreekse consoleinvoer
  INT 0x21     ; Roep DOS aan
  pop DX
  pop AX       ; Bevat weer de toets
  JMP SHORT Einde

  NoKey:
  xor AX,AX    ; Geen scan/ASCII-code
  Einde:
  popf         ; Herstel de registers
  RET

; ------------------------------------------------------------------------------
; GetNumber - 1999-06-11
; DOEL      : Leest een geheel positief getal vanaf het toetsenbord in EDX.
;             <Backspace> corrigeert een fout, <Return> = einde.
; GEBRUIKT  : EAX,ECX,Flags
; SCHRIJFT  : EDX,Teken,XPos
; ROEPT AAN : PrintChar,MoveCursor
; ------------------------------------------------------------------------------
GetNumber:

  push EAX          ; Bewaar de registers
  push ECX
  pushf

  xor ECX,ECX      ; Geen tekens getypt
  xor EDX,EDX      ; Resultaat = 0
  GetNumChar:
    xor AH,AH      ; 0 = Keyboard read, AL = ASCII, AH = scan
    INT 0x16       ; Roep BIOS aan

    cmp AL,'0'     ; Alleen 0..9 verwerken
    JB CheckBS
    cmp AL,'9'
    JA CheckBS

    inc ECX        ; Geldig teken getypt
    mov [Teken],AL ; Plaats AL in Teken
    CALL PrintChar ; Beeld AL af
    inc BYTE [XPos] ; Cursor 1 verder dan teken
    CALL MoveCursor
    imul EDX,10    ; EDX*=10
    sub BYTE [Teken],'0' ; Zet ASCII-code in numerieke waarde (0..9) om
    add DL,[Teken] ; Tel Teken erbij op
  JMP SHORT GetNumChar

  CheckBS:
    cmp AL,8       ; BS ?
    JNE CheckCR    ; Nee,nog een teken ophalen
    sub ECX,1      ; Teken minder getypt, CF als ECX<0, dec zet CF niet
    JS CheckCR     ; Teveel gewist ! (aantal tekens negatief)

    dec BYTE [XPos] ; Cursor 1 terug
    mov BYTE [Teken],' ' ; Spatie
    CALL PrintChar ; Wis het foutieve teken
    CALL MoveCursor
    push ECX       ; Bewaar aantal getypte tekens
    mov EAX,EDX    ; Kopieer het getal
    xor EDX,EDX    ; Voor de DIV-instructie
    mov ECX,10     ; Deelfactor
    div ECX        ; EAX=EDX:EAX/ECX
    mov EDX,EAX    ; EDX/=10
    pop ECX
  JMP SHORT GetNumChar

  CheckCR:
    cmp ECX,0      ; Niet-negatief?
    JNS DoCR       ; > -1, geen teken
    xor ECX,ECX    ; reset
  DoCR:
    cmp AL,13      ; CR ?
    JNE GetNumChar ; Nee, nog een teken ophalen

  popf             ; Herstel de registers
  pop ECX
  pop EAX
  RET

; ------------------------------------------------------------------------------
; ActKey - 1999-06-23.
; DOEL      : Haalt via GetKey een toets binnen. Is dit de Tab, verander dan de
;             status. Is dit de Esc, maak Halted dan 1.
; GEBRUIKT  : Flags
; SCHRIJFT  : Status,Halted,AX (toetscode voor detectie/overige toetsen)
; ROEPT AAN : GetKey
; ------------------------------------------------------------------------------
ActKey:

  pushf        ; Bewaar Flags

  CALL GetKey
  or AX,AX     ; Geen toets ?
  JZ DoneKey

  cmp AL,27    ; Escape ?
  JNE TestStat ; Nee,verder kijken
  mov BYTE [Halted],1 ; Ja
  JMP SHORT DoneKey

  TestStat:
  cmp AL,9     ; Tab ?
  JNE DoneKey  ; Geen Tab/Escape
  xor BYTE [Status],1 ; Verwissel de status

  DoneKey:
  popf         ; Herstel de Flags

  RET

[SEGMENT .data]
EXTERN Halted,Status

[SEGMENT .bss]
EXTERN XPos,YPos,Teken
