# MARK: ——— README ———

.eqv    DEBUG_MODE      1       # Controls whether logging debug data is enabled



.include "./system.asm"



# MARK: CONSTANTS

.eqv    i_TOKEN_VAR             0       # A-Z
.eqv    i_TOKEN_PAREN_OPEN      1       # (
.eqv    i_TOKEN_PAREN_CLOSE     2       # )
.eqv    i_TOKEN_NOT             3       # !, ~
.eqv    i_TOKEN_AND             4       # &, ^
.eqv    i_TOKEN_OR              5       # |, v
.eqv    i_TOKEN_ERROR           6

.eqv    i_NODE_UNARY            0       # operator (operand)
.eqv    i_NODE_BINARY           0       # (operand) operator (operand)



.data

# MARK: DATA CONSTANTS

str_TKN0:       .asciiz     "VAR"
str_TKN1:       .asciiz     "("
str_TKN2:       .asciiz     ")"
str_TKN3:       .asciiz     "NOT"
str_TKN4:       .asciiz     "AND"
str_TKN5:       .asciiz     "OR"
str_TKN6:       .asciiz     "!ERR"
str_TOKENS:     .word       str_TKN0, str_TKN1, str_TKN2, str_TKN3, str_TKN4, str_TKN5, str_TKN6

# MARK: DATA VARIABLES

str_input_expr:     .space      20

# Token:
#     char value (1 byte)
#     byte type (1 byte)
arr_tokens:             .space      40
arr_tokens_size:        .byte       0
arr_tokens_valid:       .byte       1



.text

# MARK: MAIN

main:
    PRINT_CSTR("Enter logical expression (max 20 chars)\n")
    PRINT_CSTR(" --> ")
    READ_STR(str_input_expr, 100)
    
    jal     fn_tokenize
    li      $t0,    DEBUG_MODE
    beq     $t0,    0,      skip_dump_tokens_main
    jal     fn_dump_tokens
skip_dump_tokens_main:
    jal     fn_tokens_check
    
    PRINT_CSTR("\n")
    EXIT()



# MARK: LEXER

fn_tokenize:
    la      $t0,    str_input_expr          # str_input_expr:$t0 = &str_input_expr
    la      $t1,    arr_tokens              # arr_tokens:$t1 = &arr_tokens
    la      $t6,    arr_tokens_valid        # arr_tokens_valid:$t6 = &arr_tokens_valid
    li      $t5,    0                       # count:$t5 = 0 // for count of tokens

loop_tokenize:
    lb      $t2,    0($t0)                  # current:$t2 = $t0->value // get current character
    beqz    $t2,    done_tokenize           # if current:$t2 == '\0', done
    sb      $t2,    0($t1)                  # arr_tokens:$t1:->type = $t2 // save current character

    # if current:$t2 == ' ':$t3, skip
    li      $t3,    ' '                     # $t3 = ' '
    beq     $t2,    $t3,    skip_char

    # if current:$t2 == lf:$t3, skip
    li      $t3,    10                      # $t3 = 10 // line feed
    beq     $t2,    $t3,    skip_char

    # if current:$t2 == (:$t3, save
    li      $t4,    i_TOKEN_PAREN_OPEN      # type:$t4 = i_TOKEN_PAREN_OPEN
    li      $t3,    '('                     # $t3 = '('
    beq     $t2,    $t3,    save_token

    # if current:$t2 == ):$t3, save
    li      $t4,    i_TOKEN_PAREN_CLOSE     # type:$t4 = i_TOKEN_PAREN_CLOSE
    li      $t3,    ')'                     # $t3 = ')'
    beq     $t2,    $t3,    save_token

    # if current:$t2 == (!, ~):$t3, save
    li      $t4,    i_TOKEN_NOT             # type:$t4 = i_TOKEN_NOT
    li      $t3,    '!'                     # $t3 = '!'
    beq     $t2,    $t3,    save_token
    li      $t3,    '~'                     # $t3 = '~'
    beq     $t2,    $t3,    save_token

    # if current:$t2 == (&, ^):$t3, save
    li      $t4,    i_TOKEN_AND             # type:$t4 = i_TOKEN_AND
    li      $t3,    '&'                     # $t3 = '&'
    beq     $t2,    $t3,    save_token
    li      $t3,    '^'                     # $t3 = '^'
    beq     $t2,    $t3,    save_token

    # if current:$t2 == (|, v):$t3, save
    li      $t4,    i_TOKEN_OR              # type:$t4 = i_TOKEN_OR
    li      $t3,    '|'                     # $t3 = '|'
    beq     $t2,    $t3,    save_token
    li      $t3,    'v'                     # $t3 = 'v'
    beq     $t2,    $t3,    save_token

    # if not A:$t3 <= current:$t2 <= Z:$t3, error
    li      $t4,    i_TOKEN_VAR             # type:$t4 = i_TOKEN_VAR
    li      $t3,    'A'                     # $t3 = 'A' (65 in ASCII)
    blt     $t2,    $t3,    error_token
    li      $t3,    'Z'                     # $t3 = 'Z' (90 in ASCII)
    bgt     $t2,    $t3,    error_token
    j       save_token

error_token:
    # Mark array token as invalid
    li      $t4,    i_TOKEN_ERROR           # type:$t4 = i_TOKEN_ERROR
    li      $t7,    0                       # $t7 = 1
    sb      $t7,    0($t6)                  # arr_tokens_valid:$t6 = $t7

save_token:
    sb      $t4,    1($t1)                  # arr_tokens:$t1->type = $t4 // save current type
    addi    $t5,    $t5,    1               # count:$t5 += 1 // increment count of tokens
    addi    $t1,    $t1,    2               # $t1 += 2 // increment to next element

skip_char:
    addi    $t0,    $t0,    1               # str_input_expr:$t0 += 1 // increment to next char
    j       loop_tokenize

done_tokenize:
    la      $t0,    arr_tokens_size         # arr_tokens_size:$t0 = &arr_tokens_size
    sb      $t5,    0($t0)                  # arr_tokens_size:$t0 = $t5
    jr      $ra



fn_tokens_check:
    # if arr_tokens_valid:$t0 == 1, return
    lb      $t0,    arr_tokens_valid        # is_valid:$t0 = arr_tokens_valid
    li      $t1,    1
    beqz    $t0,    invalid_tokens_check
    jr      $ra

invalid_tokens_check:
    li      $t0,    DEBUG_MODE
    beq     $t0,    1,      skip_dump_tokens_check
    jal fn_dump_tokens 
skip_dump_tokens_check:

    PRINT_CSTR("\nERROR: Invalid tokens were found.")
    EXIT()



# MARK: LEXER (DEBUG)

fn_dump_tokens:
    la      $t0,    arr_tokens                  # arr_tokens:$t0 = &arr_tokens
    li      $t1,    0                           # count:$t2 = 0 // for token counting
    lb      $t2,    arr_tokens_size             # arr_tokens_size:$t1 = &arr_tokens_size
    PRINT_CSTR("\n")

loop_dump_tokens:
    beq     $t1,    $t2,    done_dump_tokens    # if $t1 == $t2, done
    lb      $t3,    0($t0)                      # char:$t3 = $t0->char
    lb      $t4,    1($t0)                      # type:$t4 = $t0->type

    mul     $t5,    $t4,    4                   # $t5 = type:$t4 * 4 // str_TOKENS byte-offset
    la      $t6,    str_TOKENS                  # *$t6 = &str_TOKENS
    add     $t6,    $t6,    $t5                 # $t6 += $t5 // apply byte-offset
    lw      $t6,    0($t6)                      # type_str:$t6 = *$t6 // load element

    # format: <TYPE>:\t"<CHAR>" (<CHAR_CODE>)\n"
    PRINT_STR(move, $t6)        # <TYPE>
    PRINT_CSTR(":\t\"")
    PRINT_CHAR(move, $t3)       # <CHAR>
    PRINT_CSTR("\" (")
    PRINT_INT(move, $t3)        # <CHAR_CODE>
    PRINT_CSTR(")\n")

    addi    $t0,    $t0,    2       # $t0 += 2 // increment to next element
    addi    $t1,    $t1,    1       # $t1 += 1 // increment token counter
    j       loop_dump_tokens

done_dump_tokens:
    jr      $ra



# MARK: PARSER



# MARK: PARSER (DEBUG)

