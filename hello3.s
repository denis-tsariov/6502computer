; addresses to access registers
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E  = %01000000
RW = %00100000
RS = %00010000

    .org $8000 ; program starts at address 8000

message: .asciiz "Hello, world!"

reset:
    ldx #$ff 
    txs         ; set stack pointer

    lda #%11111111 ; set all pins on port B to output (no one cares about b7)
    sta DDRB
    lda #%00000000 ; set all pins on port A to input
    sta DDRA

    jsr lcd_init 
    lda #%00101000 ; set 4-bit mode; 2 line; 5x8 font
    jsr lcd_instruction
    lda #%00001110
    jsr lcd_instruction
    lda #%00000110
    jsr lcd_instruction
    lda #%00000001
    jsr lcd_instruction

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

lcd_init:
    lda #%00000010 ; set 4-bit mode
    sta PORTB
    ora #E
    sta PORTB
    and #%00001111
    sta PORTB
    rts

lcd_instruction:
    jsr lcd_wait
    pha
    lsr
    lsr
    lsr
    lsr ; send high 4 bits first
    sta PORTB
    ora #E ; set E bit to send instruction
    sta PORTB
    eor #E ; clear E bit
    sta PORTB
    pla
    and #%00001111 ; send low 4 bits
    sta PORTB
    ora #E
    sta PORTB
    eor #E
    sta PORTB
    rts

lcd_wait:
    pha
    lda #%11110000 ; lcd data is input
    sta DDRB
lcd_busy:
    lda #RW
    sta PORTB
    lda #(RW | E)
    sta PORTB
    lda PORTB ; read high nibble
    pha ; and put on stack since it has the busy flag
    lda #RW
    sta PORTB
    lda #(RW | E)
    sta PORTB
    lda PORTB ; read low nibble
    pla  ; het high nibble off stack
    and #%00001000
    bne lcd_busy

    lda #RW
    sta PORTB
    lda #%11111111
    sta DDRB
    pla
    rts

print_char:
    jsr lcd_wait
    pha
    lsr
    lsr
    lsr
    lsr         ; send high 4 bits
    ora #RS
    sta PORTB
    ora #E
    sta PORTB
    eor #E
    sta PORTB
    pla
    and #%00001111 ; send 4 low bits
    ora #RS
    sta PORTB
    ora #E 
    sta PORTB
    eor #E
    sta PORTB
    rts

    .org $fffc
    .word reset
    .word $0000
