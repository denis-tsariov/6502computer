PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
T1CL = $6004
T1CH = $6005
ACR = $600B
IFR = $600D
IER = $600E

ticks = $00 ; 4 bytes (32 bits!!)
toggle_time = $04
lcd_time = $05
value = $08

    .org $8000

reset:
    lda #%11111111 ; Set all pins on port B to output
    sta DDRB
    lda #%11111111 ; set all pins on port A to output
    sta DDRA
    
    ; Wait for LCD to power up (15ms+)
    jsr long_delay
    jsr long_delay
    jsr long_delay
    
    ; LCD initialization sequence
    lda #%00110000 ; Function set: 8-bit interface
    jsr lcd_instruction_no_busy
    jsr long_delay
    
    lda #%00110000 ; Function set: 8-bit interface (repeat)
    jsr lcd_instruction_no_busy
    jsr short_delay
    
    lda #%00110000 ; Function set: 8-bit interface (repeat)
    jsr lcd_instruction_no_busy
    jsr short_delay
    
    lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
    jsr lcd_instruction
    lda #%00001000 ; Display off
    jsr lcd_instruction
    lda #%00000001 ; Clear display
    jsr lcd_instruction
    lda #%00000110 ; Increment and shift cursor; don't shift display
    jsr lcd_instruction
    lda #%00001110 ; Display on; cursor on; blink off
    jsr lcd_instruction
    
    lda #0
    sta PORTA
    sta ACR
    sta toggle_time
    sta lcd_time
    jsr init_timer

loop:
    jsr update_led
    jsr update_lcd
    jmp loop

update_led:
    sec
    lda ticks
    sbc toggle_time
    cmp #25 ; have 250 ms elapsed?
    bcc exit_update_led
    lda #$01
    eor PORTA
    sta PORTA
    lda ticks
    sta toggle_time
exit_update_led:
    rts

update_lcd:
    sec
    lda ticks
    sbc lcd_time
    cmp #100
    bcc skip_lcd
    sei
    lda ticks
    sta value
    lda ticks + 1
    sta value + 1
    cli
    lda #%00000001 ; clear display
    jsr lcd_instruction
    jsr print_num
    lda ticks
    sta lcd_time
skip_lcd:
    rts

init_timer:
    lda #0
    sta ticks
    sta ticks + 1
    sta ticks + 2
    sta ticks + 3
    lda #%01000000
    sta ACR
    lda #$0e 
    sta T1CL
    lda #$27
    sta T1CH
    lda #%11000000
    sta IER
    cli
    rts

irq: 
    bit T1CL
    inc ticks
    bne end_irq
    inc ticks + 1
    bne end_irq
    inc ticks + 2
    bne end_irq
    inc ticks + 3
end_irq:
    rti

; LCD instruction with busy flag checking
lcd_instruction:
    pha
    jsr lcd_wait
    pla
    jsr lcd_instruction_no_busy
    rts

; LCD instruction without busy flag checking (for initialization)
lcd_instruction_no_busy:
    sta PORTB
    lda #0         ; Clear RS/RW/E bits
    sta PORTA
    lda #%00100000 ; Set E bit to send instruction
    sta PORTA
    lda #0         ; Clear RS/RW/E bits
    sta PORTA
    rts

; Wait for LCD to be ready by checking busy flag
lcd_wait:
    pha
    lda #%00000000 ; Port B as input
    sta DDRB
lcd_wait_loop:
    lda #%00010000 ; Set RW bit to read
    sta PORTA
    lda #%00110000 ; Set E bit to enable
    sta PORTA
    lda PORTB      ; Read busy flag
    pha
    lda #%00010000 ; Clear E bit, keep RW set
    sta PORTA
    lda #0         ; Clear RS/RW/E bits
    sta PORTA
    pla
    and #%10000000 ; Check busy flag (bit 7)
    bne lcd_wait_loop
    lda #%11111111 ; Port B back to output
    sta DDRB
    pla
    rts

print_char:
    pha
    jsr lcd_wait
    pla
    sta PORTB
    lda #%00000001  ; Set RS; Clear RW/E bits
    sta PORTA
    lda #%00100001  ; Set E bit to send instruction
    sta PORTA
    lda #%00000001  ; Clear E bit
    sta PORTA
    rts

; Delay routines
long_delay:
    pha
    txa
    pha
    tya
    pha
    ldx #$ff
long_delay_outer:
    ldy #$ff
long_delay_inner:
    dey
    bne long_delay_inner
    dex
    bne long_delay_outer
    pla
    tay
    pla
    tax
    pla
    rts

short_delay:
    pha
    txa
    pha
    ldx #$ff
short_delay_loop:
    dex
    bne short_delay_loop
    pla
    tax
    pla
    rts

print_num:
    lda value + 1
    jsr print_hex
    lda value
    jsr print_hex
    rts

print_hex:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr print_hex_digit
    pla
    and #$0f
    jsr print_hex_digit
    rts

print_hex_digit:
    cmp #$0a
    bcs print_hex_letter
    adc #'0'
    jsr print_char
    rts
print_hex_letter:
    adc #'A' - $0a - 1
    jsr print_char
    rts

    .org $fffc
    .word reset
    .word irq
