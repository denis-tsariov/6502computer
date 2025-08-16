ACIA_DATA = $5000
ACIA_STATUS = $5001

reset:
    ldx #0
send_msg:
    lda message, x
    beq done
    jsr send_char
    inx
    jmp send_msg
done:
    jmp done

message: .asciiz "Hello"

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