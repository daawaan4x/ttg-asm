# MARK: CONSTANTS

.eqv    sys_PRINT_INT           1
.eqv    sys_PRINT_STR           4
.eqv    sys_READ_STR            8
.eqv    sys_EXIT                10
.eqv    sys_PRINT_CHAR          11

# MARK: MACRO

.macro  PRINT_INT(%op, %int)
    addi    $sp,    $sp,    -8
    sw      $v0,    0($sp)
    sw      $a0,    4($sp)

    li      $v0,    sys_PRINT_INT
    %op      $a0,    %int
    syscall

    lw      $a0,    4($sp)
    lw      $v0,    0($sp)
    addi    $sp,    $sp,    8
.end_macro

.macro  PRINT_CSTR(%str)
    .data
        literal:    .asciiz     %str
    .text
        addi    $sp,    $sp,    -8
        sw      $v0,    0($sp)
        sw      $a0,    4($sp)

        li      $v0,    sys_PRINT_STR
        la      $a0,    literal
        syscall

        lw      $a0,    4($sp)
        lw      $v0,    0($sp)
        addi    $sp,    $sp,    8
.end_macro

.macro  PRINT_STR(%op, %str)
    addi    $sp,    $sp,    -8
    sw      $v0,    0($sp)
    sw      $a0,    4($sp)

    li      $v0,    sys_PRINT_STR
    %op      $a0,    %str
    syscall

    lw      $a0,    4($sp)
    lw      $v0,    0($sp)
    addi    $sp,    $sp,    8
.end_macro

.macro  READ_STR(%var, %size)
    addi    $sp,    $sp,    -12
    sw      $v0,    0($sp)
    sw      $a0,    4($sp)
    sw      $a1,    8($sp)

    li      $v0,    sys_READ_STR
    la      $a0,    %var
    li      $a1,    %size
    syscall

    lw      $a1,    8($sp)
    lw      $a0,    4($sp)
    lw      $v0,    0($sp)
    addi    $sp,    $sp,    12
.end_macro

.macro  EXIT()
    li      $v0,    sys_EXIT
    syscall
.end_macro

.macro  PRINT_CHAR(%op, %ch)
    addi    $sp,    $sp,    -8
    sw      $v0,    0($sp)
    sw      $a0,    4($sp)

    li      $v0,    sys_PRINT_CHAR
    %op      $a0,    %ch
    syscall

    lw      $a0,    4($sp)
    lw      $v0,    0($sp)
    addi    $sp,    $sp,    8
.end_macro

.macro  PUSH_STACK_RA()
    addi    $sp,    $sp,    -4
    sw      $ra,    0($sp)
.end_macro

.macro  POP_STACK_RA()
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    4
.end_macro