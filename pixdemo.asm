; ==============================================================================
; PixDemo - 1999-06-23 -- 1999-06-25
; Programma dat een symmetrisch patroon genereert, met piepjes.
; ==============================================================================

DOSSEG       ; Segmenten zoals DOS
.MODEL SMALL ; Alle referenties zijn NEAR

.386
.STACK       ; 1 Kb

; *******************************DATA SEGMENT***********************************

.DATA? ; Data zonder initiële waarde
EXTRN RandVal:WORD,RandRes:WORD,Params:BYTE,Freq:WORD
XP DW 1 DUP (?)
YP DW 1 DUP (?)
.DATA  ; Data met initiële waarde
EXTRN RandSeed:DWORD,Status:BYTE,Halted:BYTE
PUBLIC FileName,Guide
FileName DB  'PixDemo.EXE',0
Guide    DB  'Esc : stoppen, Tab : piepje aan/uit, - : langzamer, + : sneller'
LGuide   EQU $-Guide
Speed DB 50 ; 50 ms tussen 2 plaatsingen

; **************************CODE SEGMENT****************************************
.CODE
EXTRN PutVGA:PROC,RestoreMode:PROC,PutPixel:PROC,ActKey:PROC
EXTRN GetParameters:PROC,StrToDec:PROC,Sound:PROC,NoSound:PROC,RandWord:PROC
EXTRN Randomize:PROC,ShowCopy:PROC,GetVidSegment:PROC,InitDelay:PROC,Delay:PROC

; ------------------------------------------------------------------------------
; SetPoints - 1999-06-26
; DOEL      : Zet 4 puntjes van het patroon op het scherm.
; LEEST     : XP (originele x-positie, 0..319)
; SCHRIJFT  : CX (x-positie), DX (y-positie)
; ROEPT AAN : PutPixel
; ------------------------------------------------------------------------------
SetPoints PROC
  CALL PutPixel ; in driehoek 2,1
  neg CX
  add CX,639    ; X4=639-X1, Y4=Y1
  CALL PutPixel ; in driehoek 3,4
  mov CX,XP     ; restore
  neg DX
  add DX,479    ; X5=X1, Y5=479-Y1
  CALL PutPixel ; in driehoek 6,5
  neg CX
  add CX,639    ; X8=639-X1, Y8=479-Y1
  CALL PutPixel ; in driehoek 7,8
  RET
SetPoints ENDP

; ------------------------------------------------------------------------------
; GetRandSeed - 1999-06-25
; DOEL      : Initialiseert de RNG met de systeemklok of met paramstr(1)
; SCHRIJFT  : CX,EDX,SI,Params,RandSeed
; ROEPT AAN : GetParameters,StrToDec
; ------------------------------------------------------------------------------
GetRandSeed MACRO
LOCAL DoRandomize,EndSeed
  CALL GetParameters
  JCXZ DoRandomize ; Geen parameters
  lea SI,Params    ; EDX = val(DS:SI) met lengte CX
  CALL StrToDec
  mov RandSeed,EDX
  JMP SHORT EndSeed
DoRandomize:
  CALL Randomize   ; RandSeed via timer
EndSeed:
ENDM

; ------------------------------------------------------------------------------
; InitProg - 1999-06-25
; DOEL      : Odds 'n ends
; LEEST     : LGuide
; SCHRIJFT  : CX
; ROEPT AAN : GetVidSegment,ShowCopy,PutVGA
; ------------------------------------------------------------------------------
InitProg MACRO
  CALL InitDelay
  CALL GetVidSegment
  mov CL,LGuide
  CALL ShowCopy
  CALL PutVGA
  mov CX,2500 ; wacht op scherm
  CALL Delay
ENDM

; ------------------------------------------------------------------------------
; GetValues - 1999-06-26
; DOEL      : Bepaalt XP (0..319), YP (0..3/4*XP) en de kleur v/d pixel
; LEEST     : RandRes
; SCHRIJFT  : AX,CX,DX,XP,YP,RandVal
; ------------------------------------------------------------------------------
GetValues MACRO
LOCAL NoIncCX
  mov RandVal,320 ; 0..319
  CALL RandWord
  mov AX,RandRes  ; x-coordinaat
  mov XP,AX
  xor DX,DX       ; voor idiv
  mov CX,4        ;   "    "
  idiv CX         ; AX=DX:AX/3, DX=DX:AX%3
  cmp DX,2        ; Fractie >= 1/2 ?
  JB NoIncAX      ; Nee
  inc AX          ; Naar boven afronden
NoIncAX:
  imul AX,3       ; AX*=3
  mov RandVal,AX  ; 0..(3/4)*XP
  CALL RandWord
  mov DX,RandRes  ; y-coordinaat
  mov YP,DX
  mov CX,XP       ; herladen
  mov RandVal,16  ; 0..15
  CALL RandWord
  mov AX,RandRes  ; kleur
ENDM

; ------------------------------------------------------------------------------
; MirrorCoords - 1999-06-26
; DOEL      : Spiegelt XP en YP en past de bereiken aan
; LEEST     : XP,YP
; GEBRUIKT  : AX
; SCHRIJFT  : CX,DX,XP,YP
; ------------------------------------------------------------------------------
MirrorCoords MACRO
LOCAL NoRndAX,NoAdjAX
  push AX    ; voor idiv
  mov AX,YP  ;   "    "
  xor DX,DX  ;   "    "
  shl AX,2   ; AX*=2
  mov CX,3   ; voor idiv
  idiv CX    ; AX=DX:AX/3, DX=DX:AX%3
  cmp DX,2   ; Fractie >= 2/3 ?
  JB NoRndAX ; Nee
  inc AX     ; Naar boven afronden
NoRndAX:
  mov CX,AX
  mov AX,XP
  mov XP,CX  ; XP=(4/3)*YP

  xor DX,DX  ; voor idiv
  mov CX,4   ;   "    "
  idiv CX    ; AX=DX:AX/3, DX=DX:AX%3
  cmp DX,2   ; Fractie >= 1/2 ?
  JB NoAdjAX ; Nee
  inc AX     ; Naar boven afronden
NoAdjAX:
  imul AX,3
  mov DX,AX
  mov YP,DX  ; YP=(3/4)*XP
  mov CX,XP  ; herladen
  pop AX     ; voor idiv
ENDM

; ------------------------------------------------------------------------------
; CalcFreq - 1999-06-25
; DOEL      : Berekent de frequentie van het piepje kleur*512+(x/16*y/16*2)
; LEEST     : XP,YP
; SCHRIJFT  : AX,CX,DX,Freq
; ------------------------------------------------------------------------------
CalcFreq MACRO
  shl AX,9    ; AX*=512
  mov CX,XP
  shr CX,4    ; CX/=16
  mov DX,YP
  shr DX,4    ; DX/=16
  imul DX,CX
  mov Freq,DX ; imul Freq,DX -> imul SI,DX !
  shl Freq,1  ; Freq*=2
  add Freq,AX
ENDM

; ------------------------------------------------------------------------------
; EmitBeep - 1999-06-25
; DOEL      : Zendt het piepje van Speed/2 ms uit als het aanstaat (anders stil)
; LEEST     : Speed,Status
; SCHRIJFT  : CX
; ------------------------------------------------------------------------------
EmitBeep MACRO
LOCAL SkipBeep
  xor CH,CH
  mov CL,Speed ; Speed ms rust
  cmp Status,1 ; piepje aan?
  JNE SkipBeep ; nee
  shr CX,1     ; Speed/2 ms rust
  CALL Sound
  CALL Delay
  CALL NoSound
SkipBeep:
  CALL Delay
ENDM

; ------------------------------------------------------------------------------
; AdjustSpeed - 1999-06-25
; DOEL      : Stelt de snelheid bij
; LEEST     : AL (toets)
; SCHRIJFT  : Speed
; ------------------------------------------------------------------------------
AdjustSpeed MACRO
LOCAL TestInc
  cmp AL,'-'    ; Langzamer?
  JNE TestInc   ; Nee
  cmp Speed,255 ; Minimaal?
  JE TestInc    ; ja
  inc Speed     ; 1 ms langzamer
TestInc:
  cmp AL,'+'    ; Sneller?
  JNE SkipSpeed ; Nee
  cmp Speed,0   ; Maximaal?
  JE SkipSpeed  ; Ja
  dec Speed     ; 1 ms sneller
ENDM

; ------------------------------------------------------------------------------
; Main - 1999-06-25
; DOEL      : Dit is het hoofdprogramma.
; LEEST     : DGroup
; SCHRIJFT  : AX,DS,Status
; ROEPT AAN : SetPoints,ActKey,RestoreMode
; MACROS    : GetRandSeed,InitProg,GetValues,MirrorCoords,CalcFreq,EmitBeep
;             AdjustSpeed
; ------------------------------------------------------------------------------
Main PROC
  mov AX,DGroup    ; Zet eigen datasegment in DS op
  mov DS,AX        ; Dit moet via een GP-register
  mov Status,0     ; Piepje uit
  GetRandSeed
  InitProg
  PixLus:
    GetValues      ; XP,YP,kleur
    CALL SetPoints ; Teken de 4 puntjes van 1,4,5,8
    MirrorCoords   ; in Y=X
    CALL SetPoints ; Teken de 4 puntjes van 2,3,6,7
    cmp Status,1   ; Piepje aan?
    JNE SkipCalc   ; Nee, dan geen frequentie berekenen
    CalcFreq
  SkipCalc:
    EmitBeep
    CALL ActKey
    or AH,AH       ; Toets ingedrukt?
    JZ SkipSpeed   ; Nee
    AdjustSpeed    ; Eventueel bijstellen
  SkipSpeed:
    cmp Halted,0   ; Doorgaan?
  JE PixLus        ; Ja

  CALL RestoreMode
  mov AX,4C00h     ; Terminate process DOS Service,no error
  INT 21h          ; Roep DOS aan
Main ENDP

END Main
