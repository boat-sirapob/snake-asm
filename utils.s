
.global modulo

.data
.balign 4

.text
modulo:
    @ R0 = R0 % R1; (for R0 < R1*2)
    
    CMP R0, R1              @ if R0 < R1
    BLT return              @ ... return
        SUB R0, R0, R1      @ else, R0 = R0 - R1
    return:
        BX LR               @ return
