[SEGMENT .text]
GLOBAL GetDaTi,NewSec,InitDelay,Delay

; ------------------------------------------------------------------------------
; GetDaTi - 1998-04-01.
; DOEL     : Vraagt de datum en weekdag via INTerrupt 21h functie 2Ah
;            en de tijd via INTerrupt 21h functie 2Ch en zet deze in
;            de daarvoor bestemde variabelen.
; GEBRUIKT : AX,CX,DX,Flags
; SCHRIJFT : Jaar,Maand,Dag,WeekDag,Uur,Minuut,Seconde,CSec
; ------------------------------------------------------------------------------
GetDaTi:

  push AX          ; Bewaar de gebruikte registers
  push CX
  push DX
  pushf            ; Bewaar Flags

  mov AH,0x2A      ; Vraag datum en weekdag
  INT 0x21         ; Roep DOS aan
  mov [Jaar],CX  ; Bewaar de datum,jaar
  mov [Maand],DH ; Maand
  mov [Dag],DL   ; Dag
  mov BYTE [WeekDag],7 ; Zondag !
  or AL,AL         ; Is het wel zondag?
  JZ Sunday
    mov [WeekDag],AL ; Nee !
  Sunday:

  mov AH,0x2C      ; Vraag tijd
  INT 0x21         ; Roep DOS aan
  mov [Uur],CH     ; Bewaar de tijd,uur
  mov [Minuut],CL  ; Minuut
  mov [Seconde],DH ; Seconde
  mov [CSec],DL    ; CSec

  popf             ; Herstel de Flags
  pop DX           ; Herstel de registers
  pop CX
  pop AX

  RET

; ------------------------------------------------------------------------------
; NewSec - 1998-10-17.
; DOEL     : Wacht op de volgende seconde.
; GEBRUIKT : AX,BX,DX,Flags
; ------------------------------------------------------------------------------
NewSec:

  push AX             ; Bewaar de registers
  push BX
  push DX
  pushf               ; En de Flags

  mov AH,0x2C          ; Vraag tijd
  INT 0x21             ; Roep DOS aan
  mov BH,DH           ; Bewaar de seconde
  WaitSec:
    INT 0x21           ; Roep DOS aan
    cmp BH,DH         ; Wacht op de volgende seconde...
  JE WaitSec          ; ...door terug te gaan naar de loop

  popf                ; Herstel de Flags
  pop DX              ; En de registers
  pop BX
  pop AX

  RET

InitDelay:
; Turbo Pascal code...
  RET

Delay:
; Turbo Pascal code...
  RET

[SEGMENT .data]
GLOBAL WkDTabl
WkDTabl DB 'Ma' ; 1e dag
  DB 'Di'
  DB 'Wo'
  DB 'Do'
  DB 'Vr'
  DB 'Za' ; 6e dag
  DB 'Zo' ; 7e dag (DOS -> 0e dag)

COMMON CSec      1
COMMON LoopsInMs 2
[SEGMENT .bss]
EXTERN Jaar,Maand,Dag,Uur,Minuut,Seconde,WeekDag
