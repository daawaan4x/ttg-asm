                        .eqv    i_TOKEN_VAR         0                           # P, Q, R
                        .eqv    i_TOKEN_PAREN_OPEN  1                           # (
                        .eqv    i_TOKEN_PAREN_CLOSE 2                           # )
                        .eqv    i_TOKEN_NOT         3                           # !
                        .eqv    i_TOKEN_AND         4                           # &
                        .eqv    i_TOKEN_OR          5                           # |
                        .eqv    i_TOKEN_ERROR       6

                        .eqv    i_NODE_UNARY        0                           # operator (operand)
                        .eqv    i_NODE_BINARY       0                           # (operand) operator (operand)

                        .eqv    sys_PRINT_INT       1
                        .eqv    sys_PRINT_STR       4
                        .eqv    sys_READ_STR        8
                        .eqv    sys_EXIT            10
                        .eqv    sys_PRINT_CHAR      11



.data

str_TOKEN_VAR:          .asciiz "VAR"
str_TOKEN_PAREN_OPEN:   .asciiz "PARENL"
str_TOKEN_PAREN_CLOSE:  .asciiz "PARENR"
str_TOKEN_NOT:          .asciiz "NOT"
str_TOKEN_AND:          .asciiz "AND"
str_TOKEN_OR:           .asciiz "OR"
str_TOKEN_ERROR:        .asciiz "ERROR"

str_PROMPT_EXPR:        .asciiz "Enter logical expression: "
str_SPACE:              .asciiz " "
str_COLON:              .asciiz ":"
str_QUOTE:              .asciiz "\""
str_PAREN_OPEN:         .asciiz "("
str_PAREN_CLOSE:        .asciiz ")"
str_TAB:                .asciiz "\t"
str_NEWLINE:            .asciiz "\n"

str_input_expr:         .space  20

    # Token:
    #     char value (1 byte)
    #     byte type (1 byte)
arr_tokens:             .space  40
arr_tokens_size:        .byte



.text

    # MARK: MAIN

main:
    jal     fn_read_expr
    jal     fn_tokenize
    jal     fn_dump_tokens

    li      $v0,                    sys_EXIT
    syscall



    # MARK: HELPER FUNCTIONS

fn_print_space:
    li      $v0,                    sys_PRINT_STR
    la      $a0,                    str_SPACE
    syscall
    jr      $ra

fn_print_colon:
    li      $v0,                    sys_PRINT_STR
    la      $a0,                    str_COLON
    syscall
    jr      $ra

fn_print_quote:
    li      $v0,                    sys_PRINT_STR
    la      $a0,                    str_QUOTE
    syscall
    jr      $ra

fn_print_paren_open:
    li      $v0,                    sys_PRINT_STR
    la      $a0,                    str_PAREN_OPEN
    syscall
    jr      $ra

fn_print_paren_close:
    li      $v0,                    sys_PRINT_STR
    la      $a0,                    str_PAREN_CLOSE
    syscall
    jr      $ra

fn_print_tab:
    li      $v0,                    sys_PRINT_STR
    la      $a0,                    str_TAB
    syscall
    jr      $ra

fn_print_newline:
    li      $v0,                    sys_PRINT_STR
    la      $a0,                    str_NEWLINE
    syscall
    jr      $ra



    # MARK: INPUT HANDLER

fn_read_expr:
    li      $v0,                    sys_PRINT_STR
    la      $a0,                    str_PROMPT_EXPR
    syscall
    li      $v0,                    sys_READ_STR
    la      $a0,                    str_input_expr
    li      $a1,                    100
    syscall
    jr      $ra



    # MARK: LEXER

fn_tokenize:
    la      $t0,                    str_input_expr                              # *$t0 = &str_input_expr
    la      $t1,                    arr_tokens                                  # *$t1 = &arr_tokens
    li      $t5,                    0                                           # $t5 = 0 // for count of tokens

loop_tokenize:
    lb      $t2,                    0($t0)                                      # $t2 = $t0->value // get current character
    beqz    $t2,                    done_tokenize                               # if $t2 == '\0', done
    sb      $t2,                    0($t1)                                      # $t1->type = $t2 // save current character

    li      $t3,                    ' '                                         # $t3 = ' '
    beq     $t2,                    $t3,                    skip_token

    li      $t3,                    10                                          # $t3 = 10 // line feed
    beq     $t2,                    $t3,                    skip_token

    li      $t4,                    i_TOKEN_PAREN_OPEN                          # $t4 = i_TOKEN_PAREN_OPEN
    li      $t3,                    '('                                         # $t3 = '('
    beq     $t2,                    $t3,                    save_token

    li      $t4,                    i_TOKEN_PAREN_CLOSE                         # $t4 = i_TOKEN_PAREN_CLOSE
    li      $t3,                    ')'                                         # $t3 = ')'
    beq     $t2,                    $t3,                    save_token

    li      $t4,                    i_TOKEN_NOT                                 # $t4 = i_TOKEN_NOT
    li      $t3,                    '!'                                         # $t3 = '!'
    beq     $t2,                    $t3,                    save_token

    li      $t4,                    i_TOKEN_AND                                 # $t4 = i_TOKEN_AND
    li      $t3,                    '&'                                         # $t3 = '&'
    beq     $t2,                    $t3,                    save_token

    li      $t4,                    i_TOKEN_OR                                  # $t4 = i_TOKEN_OR
    li      $t3,                    '|'                                         # $t3 = '|'
    beq     $t2,                    $t3,                    save_token

    li      $t4,                    i_TOKEN_VAR                                 # $t4 = i_TOKEN_VAR
    li      $t3,                    'P'                                         # $t3 = 'P'
    beq     $t2,                    $t3,                    save_token
    li      $t3,                    'Q'                                         # $t3 = 'Q'
    beq     $t2,                    $t3,                    save_token
    li      $t3,                    'R'                                         # $t3 = 'R'
    beq     $t2,                    $t3,                    save_token

    li      $t4,                    i_TOKEN_ERROR                               # $t4 = i_TOKEN_ERROR

save_token:
    sb      $t4,                    1($t1)                                      # $t1->type = $t4 // save current type
    addi    $t5,                    $t5,                    1                   # $t5 += 1 // increment count of tokens
    addi    $t1,                    $t1,                    2                   # $t1 += 2 // increment to next element

skip_token:
    addi    $t0,                    $t0,                    1                   # $t0 += 1 // increment to next char
    j       loop_tokenize

done_tokenize:
    la      $t0,                    arr_tokens_size                             # *$t0 = &arr_tokens_size
    sb      $t5,                    0($t0)                                      # *$t0 = $t5
    jr      $ra



    # MARK: LEXER (DEBUG)

fn_dump_tokens:
    # Push $ra in stack
    addi    $sp,                    $sp,                    -4
    sw      $ra,                    0($sp)

    la      $t0,                    arr_tokens                                  # *$t0 = &arr_tokens
    li      $t1,                    0                                           # $t2 = 0 // for token counting
    lb      $t2,                    arr_tokens_size                             # *$t1 = &arr_tokens_size

loop_dump_tokens:
    beq     $t1,                    $t2,                    done_dump_tokens    # if $t1 == $t2, done
    lb      $t3,                    0($t0)                                      # $t3 = $t0->char
    lb      $t4,                    1($t0)                                      # $t4 = $t0->type

    li      $t5,                    i_TOKEN_VAR                                 # $t5 = i_TOKEN_VAR
    la      $t6,                    str_TOKEN_VAR                               # *$t6 = &str_TOKEN_VAR
    beq     $t4,                    $t5,                    print_token

    li      $t5,                    i_TOKEN_PAREN_OPEN                          # $t5 = i_TOKEN_PAREN_OPEN
    la      $t6,                    str_TOKEN_PAREN_OPEN                        # *$t6 = &str_TOKEN_PAREN_OPEN
    beq     $t4,                    $t5,                    print_token

    li      $t5,                    i_TOKEN_PAREN_CLOSE                         # $t5 = i_TOKEN_PAREN_CLOSE
    la      $t6,                    str_TOKEN_PAREN_CLOSE                       # *$t6 = &str_TOKEN_PAREN_CLOSE
    beq     $t4,                    $t5,                    print_token

    li      $t5,                    i_TOKEN_NOT                                 # $t5 = i_TOKEN_NOT
    la      $t6,                    str_TOKEN_NOT                               # *$t6 = &str_TOKEN_NOT
    beq     $t4,                    $t5,                    print_token

    li      $t5,                    i_TOKEN_AND                                 # $t5 = i_TOKEN_AND
    la      $t6,                    str_TOKEN_AND                               # *$t6 = &str_TOKEN_AND
    beq     $t4,                    $t5,                    print_token

    li      $t5,                    i_TOKEN_OR                                  # $t5 = i_TOKEN_OR
    la      $t6,                    str_TOKEN_OR                                # *$t6 = &str_TOKEN_OR
    beq     $t4,                    $t5,                    print_token

    la      $t6,                    str_TOKEN_ERROR


print_token:
    # format: <TYPE>:\t"<CHAR>" (<CHAR_CODE>)\n"
    li      $v0,                    sys_PRINT_STR
    move    $a0,                    $t6
    syscall

    jal     fn_print_colon
    jal     fn_print_tab

    jal     fn_print_quote
    li      $v0,                    sys_PRINT_CHAR
    move    $a0,                    $t3
    syscall
    jal     fn_print_quote

    jal     fn_print_space

    jal     fn_print_paren_open
    li      $v0,                    sys_PRINT_INT
    move    $a0,                    $t3
    syscall
    jal     fn_print_paren_close

    jal     fn_print_newline

    addi    $t0,                    $t0,                    2                   # $t0 += 2 // increment to next element
    addi    $t1,                    $t1,                    1                   # $t1 += 1 // increment token counter
    j       loop_dump_tokens

done_dump_tokens:
    # Pop $ra in stack
    lw      $ra,                    0($sp)
    addi    $sp,                    $sp,                    4

    jr      $ra
