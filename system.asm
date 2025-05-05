# MARK: CONSTANTS

.eqv    sys_PRINT_INT           1
.eqv    sys_PRINT_STR           4
.eqv    sys_READ_STR            8
.eqv    sys_EXIT                10
.eqv    sys_PRINT_CHAR          11

# MARK: MACRO

.macro  PRINT_INT(%op, %int)
    li      $v0,    sys_PRINT_INT
    %op      $a0,    %int
    syscall
.end_macro

.macro  PRINT_CSTR(%str)
    .data
        literal:    .asciiz     %str
    .text
        li      $v0,    sys_PRINT_STR
        la      $a0,    literal
        syscall
.end_macro

.macro  PRINT_STR(%op, %str)
    li      $v0,    sys_PRINT_STR
    %op      $a0,    %str
    syscall
.end_macro

.macro  READ_STR(%var, %size)
    li      $v0,    sys_READ_STR
    la      $a0,    %var
    li      $a1,    %size
    syscall
.end_macro

.macro  EXIT()
    li      $v0,    sys_EXIT
    syscall
.end_macro

.macro  PRINT_CHAR(%op, %ch)
    li      $v0,    sys_PRINT_CHAR
    %op      $a0,    %ch
    syscall
.end_macro

.macro  PUSH_STACK_RA()
    addi    $sp,    $sp,    -4
    sw      $ra,    0($sp)
.end_macro

.macro  POP_STACK_RA()
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    4
.end_macro