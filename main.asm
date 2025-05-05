.include "./system.asm"

# MARK: CONSTANTS

.eqv    i_TOKEN_VAR             0       # P, Q, R
.eqv    i_TOKEN_PAREN_OPEN      1       # (
.eqv    i_TOKEN_PAREN_CLOSE     2       # )
.eqv    i_TOKEN_NOT             3       # !
.eqv    i_TOKEN_AND             4       # &
.eqv    i_TOKEN_OR              5       # |
.eqv    i_TOKEN_ERROR           6

.eqv    i_NODE_UNARY            0       # operator (operand)
.eqv    i_NODE_BINARY           0       # (operand) operator (operand)



.data

# MARK: DATA CONSTANTS

str_TKN0:       .asciiz     "VAR"
str_TKN1:       .asciiz     "PARENL"
str_TKN2:       .asciiz     "PARENR"
str_TKN3:       .asciiz     "NOT"
str_TKN4:       .asciiz     "AND"
str_TKN5:       .asciiz     "OR"
str_TKN6:       .asciiz     "ERROR"
str_TOKENS:     .word       str_TKN0, str_TKN1, str_TKN2, str_TKN3, str_TKN4, str_TKN5, str_TKN6

# MARK: DATA VARIABLES

str_input_expr:             .space      20

# Token:
#     char value (1 byte)
#     byte type (1 byte)
arr_tokens:                 .space      40
arr_tokens_size:            .byte



.text

# MARK: MAIN

main:
    PRINT_CSTR("Enter logical expression: ")
    READ_STR(str_input_expr, 100)
    jal     fn_tokenize
    jal     fn_dump_tokens
    EXIT()



# MARK: LEXER

fn_tokenize:
    la      $t0,    str_input_expr          # *$t0 = &str_input_expr
    la      $t1,    arr_tokens              # *$t1 = &arr_tokens
    li      $t5,    0                       # $t5 = 0 // for count of tokens

loop_tokenize:
    lb      $t2,    0($t0)                  # $t2 = $t0->value // get current character
    beqz    $t2,    done_tokenize           # if $t2 == '\0', done
    sb      $t2,    0($t1)                  # $t1->type = $t2 // save current character

    li      $t3,    ' '                     # $t3 = ' '
    beq     $t2,    $t3,    skip_char

    li      $t3,    10                      # $t3 = 10 // line feed
    beq     $t2,    $t3,    skip_char

    li      $t4,    i_TOKEN_PAREN_OPEN      # $t4 = i_TOKEN_PAREN_OPEN
    li      $t3,    '('                     # $t3 = '('
    beq     $t2,    $t3,    save_token

    li      $t4,    i_TOKEN_PAREN_CLOSE     # $t4 = i_TOKEN_PAREN_CLOSE
    li      $t3,    ')'                     # $t3 = ')'
    beq     $t2,    $t3,    save_token

    li      $t4,    i_TOKEN_NOT             # $t4 = i_TOKEN_NOT
    li      $t3,    '!'                     # $t3 = '!'
    beq     $t2,    $t3,    save_token

    li      $t4,    i_TOKEN_AND             # $t4 = i_TOKEN_AND
    li      $t3,    '&'                     # $t3 = '&'
    beq     $t2,    $t3,    save_token

    li      $t4,    i_TOKEN_OR              # $t4 = i_TOKEN_OR
    li      $t3,    '|'                     # $t3 = '|'
    beq     $t2,    $t3,    save_token

    li      $t4,    i_TOKEN_VAR             # $t4 = i_TOKEN_VAR
    li      $t3,    'P'                     # $t3 = 'P'
    beq     $t2,    $t3,    save_token
    li      $t3,    'Q'                     # $t3 = 'Q'
    beq     $t2,    $t3,    save_token
    li      $t3,    'R'                     # $t3 = 'R'
    beq     $t2,    $t3,    save_token

    li      $t4,    i_TOKEN_ERROR           # $t4 = i_TOKEN_ERROR

save_token:
    sb      $t4,    1($t1)                  # $t1->type = $t4 // save current type
    addi    $t5,    $t5,    1               # $t5 += 1 // increment count of tokens
    addi    $t1,    $t1,    2               # $t1 += 2 // increment to next element

skip_char:
    addi    $t0,    $t0,    1               # $t0 += 1 // increment to next char
    j       loop_tokenize

done_tokenize:
    la      $t0,    arr_tokens_size         # *$t0 = &arr_tokens_size
    sb      $t5,    0($t0)                  # *$t0 = $t5
    jr      $ra



# MARK: LEXER (DEBUG)

fn_dump_tokens:
    PUSH_STACK_RA()
    la      $t0,    arr_tokens                  # *$t0 = &arr_tokens
    li      $t1,    0                           # $t2 = 0 // for token counting
    lb      $t2,    arr_tokens_size             # *$t1 = &arr_tokens_size

loop_dump_tokens:
    beq     $t1,    $t2,    done_dump_tokens    # if $t1 == $t2, done
    lb      $t3,    0($t0)                      # $t3 = $t0->char
    lb      $t4,    1($t0)                      # $t4 = $t0->type

    mul     $t5,    $t4,    4                   # $t5 = $t4 * 4 // str_TOKENS byte-offset
    la      $t6,    str_TOKENS                  # *$t6 = &str_TOKENS
    add     $t6,    $t6,    $t5                 # $t6 += $t5 // apply byte-offset
    lw      $t6,    0($t6)                      # $t6 = *$t6 // load element

    # format: <TYPE>:\t"<CHAR>" (<CHAR_CODE>)\n"
    PRINT_STR(move, $t6)                # <TYPE>
    PRINT_CSTR(":\t\"")
    PRINT_CHAR(move, $t3)               # <CHAR>
    PRINT_CSTR("\" (")
    PRINT_INT(move, $t3)                # <CHAR_CODE>
    PRINT_CSTR(")\n")

    addi    $t0,    $t0,    2     # $t0 += 2 // increment to next element
    addi    $t1,    $t1,    1     # $t1 += 1 // increment token counter
    j       loop_dump_tokens

done_dump_tokens:
    POP_STACK_RA()
    jr      $ra