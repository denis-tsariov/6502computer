PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
T1CL = $6004
T1CH = $6005
ACR = $600B
IER = $600E

E  = %01000000
RW = %00100000
RS = %00010000

ACIA_DATA = $5000
ACIA_STATUS = $5001
ACIA_CMD = $5002
ACIA_CTRL = $5003

    .org $8000

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

    lda #$00
    sta ACIA_STATUS ; soft reset (value not important)

    lda #$1f ; N-8-1, 19200 baud
    sta ACIA_CTRL

    lda #$0b ; no parity, no echo, no interrupts
    sta ACIA_CMD

    ldx #0
send_msg:
    lda message, x
    beq done
    jsr send_char
    inx
    jmp send_msg
done:

rx_wait:
    lda ACIA_STATUS
    and #$08 ; check rx buffer status flag
    beq rx_wait ; loop if rx buffer empty

    lda ACIA_DATA
    jsr print_char
    jsr send_char ; echo
    jmp rx_wait

message: .asciiz "Hello, world!"

send_char:
    sta ACIA_DATA
    pha
tx_wait:
    lda ACIA_STATUS
    and #$10 ; check tx buffer status flag
    beq tx_wait ; loop tx buffer not empty
    ; the 3 instructions above would be the ones used if the Transmitter Data Register Empty was set as per spec
    jsr tx_delay
    pla
    rts

tx_delay:
    phx
    ldx #100
tx_delay_1:
    dex ; 2             200
    bne tx_delay_1 ; 3  300
    plx
    rts

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
    pha
    and #%00001111 ; send 4 low bits
    ora #RS
    sta PORTB
    ora #E 
    sta PORTB
    eor #E
    sta PORTB
    pla
    rts



    .org $fffc
    .word reset
    .word $0000
