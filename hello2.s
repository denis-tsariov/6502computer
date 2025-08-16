; addresses to access registers 
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E  = %10000000
RW = %01000000
RS = %00100000

value = $0200 ; 2 bytes
mod10 = $0202 ; 2 bytes

  .org $8000

reset:
  ldx #$ff
  txs

  lda #%11111111 ; Set all pins on port B to output
  sta DDRB

  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA

  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruciton
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruciton
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruciton
  lda #%00000001 ; clear display
  jsr lcd_instruciton

 ldx #0
print:
  lda message,x
  beq print_done
  jsr print_char
  inx
  jmp print
print_done:

loop:
  jmp loop

message: .asciiz "Hello, world!"
number: .word 1729

lcd_wait:
  pha
  lda #%00000000 ; port b is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB 
  and #%10000000 
  bne lcdbusy

  lda #RW
  sta PORTA
  lda #%11111111 ; port b in output
  sta DDRB
  pla
  rts

lcd_instruciton:
  jsr lcd_wait
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  rts

print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts

  .org $fffc
  .word reset
  .word $0000 