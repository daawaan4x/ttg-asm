# MARK: ��� README ���

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

.eqv    i_NODE_GROUP            0       # (expr)
.eqv    i_NODE_VAR              1       # variable
.eqv    i_NODE_UNARY            2       # operator (expr)
.eqv    i_NODE_BINARY           3       # (expr) operator (expr)

.eqv    i_MAX_INPUT             50
.eqv    i_NODE_SIZE             16
.eqv    i_TOKEN_SIZE            8

.eqv    offset_TOKEN_TYPE       0
.eqv    offset_TOKEN_CHAR       4

.eqv    offset_NODE_TYPE        0
.eqv    offset_NODE_VALUE       4
.eqv    offset_NODE_LEFT        8
.eqv    offset_NODE_RIGHT       12

.data

# MARK: DATA CONSTANTS

str_TKN0:       .asciiz     "VAR"
str_TKN1:       .asciiz     "("
str_TKN2:       .asciiz     ")"
str_TKN3:       .asciiz     "NOT"
str_TKN4:       .asciiz     "AND"
str_TKN5:       .asciiz     "OR"
str_TKN6:       .asciiz     "!ERR"
.align 4
str_TOKENS:     .word       str_TKN0, str_TKN1, str_TKN2, str_TKN3, str_TKN4, str_TKN5, str_TKN6

str_NDE0:       .asciiz     "GROUP"
str_NDE1:       .asciiz     "VAR"
str_NDE2:       .asciiz     "UNARY"
str_NDE3:       .asciiz     "BINARY"
.align 4
str_NODES:      .word       str_NDE0, str_NDE1, str_NDE2, str_NDE3,

# MARK: DATA VARIABLES
#
# Comment: 
#   - Many of the variables only need less than 4 bytes but are still set
#     to use atleast 4 bytes for debugging 
.align 4
str_input_expr:     .space      i_MAX_INPUT

# Token:
#     word type (4 bytes)
#     word value (4 bytes)
.align 4
arr_tokens:             .space      200      # 50 chars * 4 bytes
arr_tokens_size:        .word       0
arr_tokens_valid:       .word       1

current_token_index:    .word       0       # For iterating arr_tokens

# Node:
#     word type (4 bytes)
#     word value (4 bytes)
#     word *left (4 bytes)
#     word *right (4 bytes)
.align 4
tree_nodes:             .space      800     # 50 char * 16 bytes
tree_nodes_root:        .word       0
tree_nodes_size:        .word       0



.text

# MARK: MAIN

main:
    PRINT_CSTR("Enter logical expression (max 20 chars)\n")
    PRINT_CSTR(" --> ")
    READ_STR(str_input_expr, 100)
    PRINT_CSTR("\n")

    jal     fn_tokenize
    li      $t0,    DEBUG_MODE
    beqz    $t0,    skip_dump_tokens_main
    jal     fn_dump_tokens
skip_dump_tokens_main:
    jal     fn_tokens_check

    jal     fn_parse_ast
    li      $t0,    DEBUG_MODE
    beqz    $t0,    skip_dump_ast_main
    jal     fn_dump_ast
skip_dump_ast_main:
    jal     fn_ast_check
    
    PRINT_CSTR("\n")
    EXIT()



# MARK: LEXER

# Function: fn_tokenize
# Description: Converts the input string into an array of tokens.
# Arguments: None
# Returns: None
fn_tokenize:
    la      $t0,    str_input_expr          # str_input_expr:$t0 = &str_input_expr
    la      $t1,    arr_tokens              # arr_tokens:$t1 = &arr_tokens
    la      $t6,    arr_tokens_valid        # arr_tokens_valid:$t6 = &arr_tokens_valid
    li      $t5,    0                       # count:$t5 = 0 // for count of tokens

loop_tokenize:
    lb      $t2,    0($t0)                  # current:$t2 = $t0[i] // get current character
    beqz    $t2,    done_tokenize           # if current:$t2 == '\0', done
    sw      $t2,    offset_TOKEN_CHAR($t1)                  # &arr_tokens:$t1:->char = current:$t2 // save current character

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
    sw      $t7,    0($t6)                  # &arr_tokens_valid:$t6 = $t7

save_token:
    sw      $t4,    offset_TOKEN_TYPE($t1)                  # &arr_tokens:$t1->type = $t4 // save current type
    addi    $t5,    $t5,    1               # count:$t5 += 1 // increment count of tokens
    addi    $t1,    $t1,    i_TOKEN_SIZE    # $t1 += 2 // increment to next element

skip_char:
    addi    $t0,    $t0,    1               # str_input_expr:$t0 += 1 // increment to next char
    j       loop_tokenize

done_tokenize:
    la      $t0,    arr_tokens_size         # arr_tokens_size:$t0 = &arr_tokens_size
    sw      $t5,    0($t0)                  # &arr_tokens_size:$t0 = $t5
    jr      $ra



# Function: fn_tokens_check
# Description: If array token is invalid, it displays the tokens and exits.
# Arguments: None
# Returns: None
fn_tokens_check:
    # if arr_tokens_valid:$t0 == 1, return
    lw      $t0,    arr_tokens_valid        # is_valid:$t0 = arr_tokens_valid
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

# Function: fn_dump_tokens
# Description: Displays the tokens for debugging.
# Arguments: None
# Returns: None
fn_dump_tokens:
    la      $t0,    arr_tokens                  # arr_tokens:$t0 = &arr_tokens
    li      $t1,    0                           # count:$t2 = 0 // for token counting
    lw      $t2,    arr_tokens_size             # arr_tokens_size:$t1 = &arr_tokens_size

loop_dump_tokens:
    beq     $t1,    $t2,    done_dump_tokens    # if $t1 == $t2, done
    lw      $t3,    offset_TOKEN_CHAR($t0)                      # char:$t3 = $t0->char
    lw      $t4,    offset_TOKEN_TYPE($t0)                      # type:$t4 = $t0->type

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

    addi    $t0,    $t0,    i_TOKEN_SIZE        # $t0 += 2 // increment to next element
    addi    $t1,    $t1,    1                   # $t1 += 1 // increment token counter
    j       loop_dump_tokens

done_dump_tokens:
    PRINT_CSTR("\n")
    jr      $ra



# MARK: PARSER

# Function: fn_parse_ast
# Description: Parses the tokens into an AST
# Arguments: None
# Returns: None
fn_parse_ast:
    addi    $sp,    $sp,    -4
    sw      $ra,    0($sp)

    # if root_node:$v0 == null, exit
    jal     fn_parse_expr               # root_node:$v0 = fn_parse_expr()
    beqz    $v0,    exit_parse_ast
    sw      $v0,    tree_nodes_root     # &tree_nodes_root = root_node:$v0
    
exit_parse_ast:
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    4
    jr      $ra



# Function: fn_ast_check:
# Description: If AST is invalid, it displays the AST and exits.
# Arguments: None
# Returns: None
fn_ast_check:
    # if arr_tokens_valid:$t0 == 1, return
    lw      $t0,    tree_nodes_root        # tree_nodes_root:$t0 = &tree_nodes_root
    beqz    $t0,    invalid_ast_check
    jr      $ra

invalid_ast_check:
    li      $t0,    DEBUG_MODE
    beq     $t0,    1,      skip_dump_ast_check
    jal fn_dump_ast 
skip_dump_ast_check:

    PRINT_CSTR("\nERROR: The Parser encountered invalid grammar.")
    EXIT()



# MARK: EXPR PARSER UTILITIES

# Function: fn_tokens_check
# Description: Loads the current token
# Arguments: None
# Returns: $v0 = Token Type, $v1 = Token Value
fn_get_token:
    lw      $t0,    current_token_index     # current_token_index:$t0 = current_token_index
    lw      $t1,    arr_tokens_size         # arr_tokens_size:$t1 = arr_tokens_size
    
    # if current_token_index:$t0 == arr_tokens_size:$t1, EOF
    bge     $t0,    $t1,    get_token_eof
    
    la      $t2,    arr_tokens              # arr_tokens:$t2 = &arr_tokens
    mul     $t3,    $t0,    i_TOKEN_SIZE    # $t3 = current_token_index:$t0 * 2
    add     $t2,    $t2,    $t3             # arr_tokens:$t2 += $t3
    
    lw      $v0,    offset_TOKEN_TYPE($t2)      # $v0 = arr_tokens:$t2->type
    lw      $v1,    offset_TOKEN_CHAR($t2)      # $v1 = arr_tokens:$t2->value
    jr      $ra

get_token_eof:
    li      $v0,    -1      # $v0 = EOF token type
    li      $v1,    0       # $v1 = EOF token value
    jr      $ra



# Function: fn_advance_token
# Description: Moves to the next token
# Arguments: None
# Returns: None
fn_advance_token:
    lw      $t0,    current_token_index     # current_token_index:$t0 = current_token_index 
    addi    $t0,    $t0,    1               # current_token_index:$t0 += 1
    sw      $t0,    current_token_index     # &current_token_index:$t0 = $t0
    jr      $ra



# Function: fn_alloc_node 
# Description: Allocate a new Node
# Arguments: $a0 = Node Type, $a1 = Node Value
# Returns: $v0 = Node pointer
fn_alloc_node:
    lw      $t0,    tree_nodes_size         # tree_nodes_size:$t0 = tree_nodes_size 
    la      $t2,    tree_nodes              # tree_nodes:$t2 = &tree_nodes  
    mul     $t3,    $t0,    i_NODE_SIZE     # offset:$t3 = tree_nodes_size * i_NODE_SIZE
    add     $t2,    $t2,    $t3             # tree_nodes:$t2 += offset:$t3
    
    sw      $a0,        offset_NODE_TYPE($t2)      # tree_nodes:$t2->type = type:$a0
    sw      $a1,        offset_NODE_VALUE($t2)      # tree_nodes:$t2->value = value:$a1
    sw      $zero,      offset_NODE_LEFT($t2)      # tree_nodes:$t2->*left = null
    sw      $zero,      offset_NODE_RIGHT($t2)      # tree_nodes:$t2->*right = null

    li      $t4,    DEBUG_MODE
    beqz    $t4,    skip_debug_alloc_node
    PRINT_CSTR("Created Node @ ")
    PRINT_INT(move, $t2)
    PRINT_CSTR(", type=")
    PRINT_INT(move, $a0)
    PRINT_CSTR(", value=")
    PRINT_INT(move, $a1)
    PRINT_CSTR("\n")
skip_debug_alloc_node:

    addi    $t0,    $t0,    1             # tree_nodes_size:$t0 += 1
    sw      $t0,    tree_nodes_size    # &tree_nodes_size:$t0 = tree_nodes_size:$t0
    
    move    $v0, $t2    # $v0 = &tree_nodes:$t2
    jr      $ra



# Function: fn_set_left_child
# Description: Sets the left child of a node
# Arguments: $a0 = Parent Node, $a1 = Left Child Pointer
fn_set_left_child:
    sw      $a1, offset_NODE_LEFT($a0)     # tree_nodes:$a0->*left = &left:$a1
    jr      $ra



# Function: fn_set_right_child
# Description: Sets the right child of a node
# Arguments: $a0 = Parent Node, $a1 = Right Child Pointer
fn_set_right_child:
    sw      $a1, offset_NODE_RIGHT($a0)     # tree_nodes:$a0->*right = &right:$a1
    jr      $ra



# MARK: EXPR PARSER

# Function: fn_parse_expr
# Description: Parses an Expression
# Arguments: None
# Returns: $v0 = Node
fn_parse_expr:
    addi    $sp,    $sp,    -12
    sw      $ra,    0($sp)
    sw      $s0,    4($sp)
    sw      $s1,    8($sp)
    
    jal     fn_parse_expr_or
    
    lw      $s1,    8($sp)
    lw      $s0,    4($sp)
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    12
    jr      $ra



# Function: fn_parse_expr_or
# Description: Parses an OR Expression - expr_or = expr_and | expr_and OR expr_or
# Arguments: None
# Returns: $v0 = Node
fn_parse_expr_or:
    addi    $sp,    $sp,    -12
    sw      $ra,    0($sp)
    sw      $s0,    4($sp)
    sw      $s1,    8($sp)
    
    # Parse Left Child
    jal     fn_parse_expr_and       # left_expr:$v0 = fn_parse_expr_and()
    beqz    $v0, fail_parse_or
    move    $s0,    $v0             # left_operand:$s0 = left_expr:$v0
    
loop_parse_or:
    # if type:$v0 != i_TOKEN_OR, done
    jal     fn_get_token            # type:$v0, value:$v1 = fn_get_token()
    li      $t0,    i_TOKEN_OR      # type:$t0 = i_TOKEN_OR
    bne     $v0,    $t0,    done_parse_or

    # Parse Right Child
    jal     fn_advance_token        
    jal     fn_parse_expr_and       # right_expr:$v0 = fn_parse_expr_and()
    beqz    $v0,    fail_parse_or
    move    $s1,    $v0             # right_operand:$v0 = right_operand:$t0

    # Create Node
    li      $a0,    i_NODE_BINARY       # node_type:$a0 = i_NODE_BINARY
    li      $a1,    i_TOKEN_OR          # node_value:$a1 = i_TOKEN_OR
    jal     fn_alloc_node               # new_node:$v0 = fn_alloc_node()
    
    # Assign Children
    move    $a0,    $v0     # parent:$a0 = new_node:$v0
    move    $a1,    $s0     # left_child:$ = left_operand:$s0
    jal     fn_set_left_child
    move    $a1,    $s1     # right_child:$ = right_operand:$s0
    jal     fn_set_right_child
    
    li      $t4,    DEBUG_MODE
    beqz    $t4,    skip_debug_parse_expr_or
    PRINT_CSTR("OR @ ")
    PRINT_INT(move, $a0)
    PRINT_CSTR(", left=")
    PRINT_INT(move, $s0)
    PRINT_CSTR(", right=")
    PRINT_INT(move, $s1)
    PRINT_CSTR("\n\n")
skip_debug_parse_expr_or:

    move    $s0,    $v0     # left_operand:$s0 = new_node:$v0 
    j       loop_parse_or

done_parse_or:
    move    $v0,    $s0     # expr:$v0 = left_operand:$0
    j       exit_parse_or

fail_parse_or:
    li      $v0,    0       # expr:$v0 = null

exit_parse_or:
    lw      $s1,    8($sp)
    lw      $s0,    4($sp)
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    12
    jr      $ra



# Function: fn_parse_expr_and
# Description: Parses an AND Expression - expr_and = expr_not | expr_not AND expr_and
# Arguments: None
# Returns: $v0 = Node
fn_parse_expr_and:
    addi    $sp,    $sp,    -12
    sw      $ra,    0($sp)
    sw      $s0,    4($sp)
    sw      $s1,    8($sp)
    
    # Parse Left Child
    jal     fn_parse_expr_not       # left_expr:$v0 = fn_parse_expr_not()
    beqz    $v0,    fail_parse_and
    move    $s0,    $v0             # left_operand:$s0 = left_expr:$v0
    
loop_parse_and:
    # if type:$v0 != i_TOKEN_AND, done
    jal     fn_get_token            # type:$v0, value:$v1 = fn_get_token()
    li      $t0,    i_TOKEN_AND     # type:$t0 = i_TOKEN_AND
    bne     $v0,    $t0,    done_parse_and

    # Parse Right Child
    jal     fn_advance_token        
    jal     fn_parse_expr_not       # right_expr:$v0 = fn_parse_expr_not()
    beqz    $v0,    fail_parse_and
    move    $s1,    $v0             # right_operand:$t0 = right_operand:$v0

    # Create Node
    li      $a0,    i_NODE_BINARY       # node_type:$a0 = i_NODE_BINARY
    li      $a1,    i_TOKEN_AND         # node_value:$a1 = i_TOKEN_AND
    jal     fn_alloc_node               # new_node:$v0 = fn_alloc_node()
    
    # Assign Children
    move    $a0,    $v0     # parent:$a0 = new_node:$v0
    move    $a1,    $s0     # left_child:$ = left_operand:$s0
    jal     fn_set_left_child
    move    $a1,    $s1     # right_child:$ = right_operand:$s0
    jal     fn_set_right_child
    
    li      $t4,    DEBUG_MODE
    beqz    $t4,    skip_debug_parse_expr_and
    PRINT_CSTR("AND @ ")
    PRINT_INT(move, $a0)
    PRINT_CSTR(", left=")
    PRINT_INT(move, $s0)
    PRINT_CSTR(", right=")
    PRINT_INT(move, $s1)
    PRINT_CSTR("\n\n")
skip_debug_parse_expr_and:

    move    $s0,    $v0     # left_operand:$s0 = new_node:$v0 
    j       loop_parse_and

done_parse_and:
    move    $v0,    $s0     # expr:$v0 = left_operand:$0
    j       exit_parse_and

fail_parse_and:
    li      $v0,    0       # # expr:$v0 = null

exit_parse_and:
    lw      $s1,    8($sp)     
    lw      $s0,    4($sp)     
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    12
    jr      $ra




# Function: fn_parse_expr_not
# Description: Parses a NOT Expression - expr_not = expr_primary | expr_not
# Arguments: None
# Returns: $v0 = Node
fn_parse_expr_not:
    addi    $sp,    $sp,    -12
    sw      $ra,    0($sp)
    sw      $s0,    4($sp)
    sw      $s1,    8($sp)

    # if type:$v0 != i_TOKEN_NOT, done
    jal     fn_get_token            # type:$v0, value:$v1 = fn_get_token()
    li      $t0,    i_TOKEN_NOT     # type:$t0 = i_TOKEN_NOT
    bne     $v0,    $t0,    expr_primary_parse_not

    # Parse Child
    jal     fn_advance_token        
    jal     fn_parse_expr_not       # expr:$v0 = fn_parse_expr_not()
    beqz    $v0,    fail_parse_not
    move    $t0,    $v0             # operand:$t0 = expr:$v0

    # Create Node
    li      $a0,    i_NODE_UNARY    # node_type:$a0 = i_NODE_UNARY
    li      $a1,    i_TOKEN_NOT     # node_value:$a1 = i_TOKEN_NOT
    jal     fn_alloc_node           # new_node:$v0 = fn_alloc_node()
    
    # Assign Child
    move    $a0,    $v0     # parent:$a0 = new_node:$v0
    move    $a1,    $t0     # child:$a1 = operand:$t0
    jal     fn_set_left_child
    
    li      $t4,    DEBUG_MODE
    beqz    $t4,    skip_debug_parse_expr_not
    PRINT_CSTR("NOT @ ")
    PRINT_INT(move, $a0)
    PRINT_CSTR(" of ")
    PRINT_INT(move, $t0)
    PRINT_CSTR("\n\n")
skip_debug_parse_expr_not:
    j       exit_parse_not

expr_primary_parse_not:
    jal     fn_parse_expr_primary       # $v0 = fn_parse_expr_primary()
    j       exit_parse_not

fail_parse_not:
    li      $v0,    0       # expr:$v0 = null

exit_parse_not:
    lw      $s1,    8($sp)     
    lw      $s0,    4($sp)     
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    12
    jr      $ra


# Function: fn_parse_expr_primary
# Description: Parses a Primary Expression - expr_primary = expr_group | variable
# Arguments: None
# Returns: $v0 = Node
fn_parse_expr_primary:
    addi    $sp,    $sp,    -12
    sw      $ra,    0($sp)
    sw      $s0,    4($sp)
    sw      $s1,    8($sp)

    jal     fn_get_token    # type:$v0, value:$v1 = fn_get_token()      

    # if type:$v0 == i_TOKEN_PAREN_OPEN, parse_primary_group
    li      $t0,    i_TOKEN_PAREN_OPEN      # type:$t0 = i_TOKEN_PAREN_OPEN
    beq     $v0,    $t0,    group_parse_primary
    
    # if type:$v0 == i_TOKEN_VAR, parse_primary_var
    li      $t0,    i_TOKEN_VAR             # type:$t0 = i_TOKEN_VAR
    beq     $v0,    $t0,    var_parse_primary
    
    li      $v0,    0   # expr:$v0 = null
    j       exit_parse_primary

group_parse_primary:
    jal     fn_parse_expr_group
    j       exit_parse_primary

var_parse_primary:
    # Create Node
    li      $a0,    i_NODE_VAR      # node_type:$a0 = i_NODE_VAR
    move    $a1,    $v1             # node_value:$a1 = value:$v1
    jal     fn_alloc_node           # $v0 = fn_alloc_node()
    move    $t5,    $v0
    jal     fn_advance_token

    li      $t4,    DEBUG_MODE
    beqz    $t4,    skip_debug_var_parse_primary
    PRINT_CSTR("VAR @ ")
    PRINT_INT(move, $t5)
    PRINT_CSTR("\n\n")
skip_debug_var_parse_primary:

exit_parse_primary:
    lw      $s1,    8($sp)     
    lw      $s0,    4($sp)     
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    12
    jr      $ra

# Function: fn_parse_expr_primary
# Description: Parses a Group Expression - expr_group = ( expr )
# Arguments: None
# Returns: $v0 = Node
fn_parse_expr_group:
    addi    $sp,    $sp,    -12
    sw      $ra,    0($sp)
    sw      $s0,    4($sp)
    sw      $s1,    8($sp)
    
    jal     fn_get_token    # type:$v0, value:$v1 = fn_get_token()
    li      $t0,    i_TOKEN_PAREN_OPEN      # type:$t0 = i_TOKEN_PAREN_OPEN
    bne     $v0,    $t0,    fail_parse_group
    
    jal     fn_advance_token
    
    # Parse Inner Expression
    jal     fn_parse_expr       # expr:$v0 = fn_parse_expr()
    beqz    $v0,    fail_parse_group
    move    $s0,    $v0         # expr:$s0 = expr:$v0 
    
    jal     fn_get_token    # type:$v0, value:$v1 = fn_get_token()
    li      $t1,    i_TOKEN_PAREN_CLOSE     # type:$t1 = i_TOKEN_PAREN_OPEN
    bne     $v0,    $t1,    fail_parse_group
    
    jal     fn_advance_token
    
    # Create Node
    li      $a0,    i_NODE_GROUP    # node_type:$a0 = i_NODE_GROUP
    li      $a1,    0               # node_value:$a1 = null
    jal     fn_alloc_node       # new_node:$v0 = fn_alloc_node()
    
    move    $a0,    $v0     # parent:$a0 = new_node:$v0
    move    $a1,    $s0     # left_child:$a1 = expr:$s0
    jal     fn_set_left_child

    li      $t4,    DEBUG_MODE
    beqz    $t4,    skip_debug_parse_expr_group
    PRINT_CSTR("GROUP @ ")
    PRINT_INT(move, $a0)
    PRINT_CSTR(" of ")
    PRINT_INT(move, $s0)
    PRINT_CSTR("\n\n")
skip_debug_parse_expr_group:
    
    j       exit_parse_group

fail_parse_group:
    li      $v0,    0

exit_parse_group:
    lw      $s1,    8($sp)     
    lw      $s0,    4($sp)     
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    12
    jr      $ra


# MARK: PARSER (DEBUG)

# Function: fn_dump_ast
# Description: Displays the Expression Tree for debugging
# Arguments: $a0 = Root Node Pointer
# Returns: None
fn_dump_ast:
    addi    $sp, $sp, -8
    sw      $ra, 0($sp)
    sw      $a0, 4($sp)
    
    lw      $a0,    tree_nodes_root
    beqz    $a0,    exit_dump_ast
    
    li      $a1,    0
    jal     fn_dump_expr
    
exit_dump_ast:
    lw      $a0, 4($sp)
    lw      $ra, 0($sp)
    addi    $sp, $sp, 8
    jr      $ra

# Function: fn_dump_expr
# Description: Recursively display an Expression Node
# Arguments: $a0 = Node Pointer, $a1 = Indent Level
# Returns: None
fn_dump_expr:
    addi    $sp,    $sp,    -16
    sw      $ra,    0($sp)
    sw      $a0,    4($sp)
    sw      $a1,    8($sp)
    sw      $s0,    12($sp)

    lw      $t0,    offset_NODE_TYPE($a0)       # type:$t0 = node:$a0->type
    mul     $t2,    $t0,   4                    # str_nodes_offset:$t2 = type:$t0
    la      $t3,    str_NODES                   # str_nodes:$t3 = &str_nodes
    add     $t3,    $t3,    $t2                 # str_nodes:$t3 += str_nodes_offset:$t2
    lw      $t4,    0($t3)                      # type_str:$t4 = *$t3

    li      $t5,    0                           # counter:$t5 = 0
loop_indent:
    # if counter:$t5 >= indent:$a1, break
    bge     $t5,    $a1,    end_loop_indent
    PRINT_CSTR("  ")
    addi    $t5,    $t5,    1                   # counter:$t5 += 1
    j       loop_indent
end_loop_indent:
    PRINT_CSTR("- ")
    PRINT_STR(move, $t4)
    addi    $a1,    $a1,    1                   # indent:$a1 += 1

    # if type == i_NODE_GROUP
    li      $t1,    i_NODE_GROUP
    beq     $t0,    $t1,    call_group

    # if type == i_NODE_VAR
    li      $t1,    i_NODE_VAR
    beq     $t0,    $t1,    call_var

    # if type == i_NODE_UNARY
    li      $t1,    i_NODE_UNARY
    beq     $t0,    $t1,    call_unary

    # if type == i_NODE_BINARY
    li      $t1,    i_NODE_BINARY
    beq     $t0,    $t1,    call_binary

    j       exit_dump_expr

call_group:
    jal     fn_dump_expr_group
    j       exit_dump_expr

call_var:
    jal     fn_dump_expr_var
    j       exit_dump_expr

call_unary:
    jal     fn_dump_expr_unary
    j       exit_dump_expr

call_binary:
    jal     fn_dump_expr_binary

exit_dump_expr:
    lw      $s0,    12($sp)
    lw      $a1,    8($sp)
    lw      $a0,    4($sp)
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    16
    jr      $ra

# Function: fn_dump_expr_group
# Description: Recursively display a GROUP Node
# Arguments: $a0 = Node Pointer, $a1 = Indent Level
# Returns: None
fn_dump_expr_group:
    addi    $sp,    $sp,    -16
    sw      $ra,    0($sp)
    sw      $a0,    4($sp)
    sw      $a1,    8($sp)
    sw      $s0,    12($sp)

    PRINT_CSTR(":")
    
    lw      $a0,    offset_NODE_LEFT($a0)       # left:$t0 = node:$a0->left
    PRINT_CSTR("\n")
    jal     fn_dump_expr
    
exit_dump_expr_group:
    lw      $s0,    12($sp)
    lw      $a1,    8($sp)
    lw      $a0,    4($sp)
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    16
    jr      $ra

# Function: fn_dump_expr_var
# Description: Recursively display a VAR Node
# Arguments: $a0 = Node Pointer, $a1 = Indent Level
# Returns: None
fn_dump_expr_var:
    addi    $sp,    $sp,    -16
    sw      $ra,    0($sp)
    sw      $a0,    4($sp)
    sw      $a1,    8($sp)
    sw      $s0,    12($sp)

    lw      $t0,    offset_NODE_VALUE($a0)      # type:$t0 = node:$a0->value
    PRINT_CSTR(" - ")
    PRINT_CHAR(move, $t0)

exit_dump_expr_var:
    lw      $s0,    12($sp)
    lw      $a1,    8($sp)
    lw      $a0,    4($sp)
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    16
    jr      $ra

# Function: fn_dump_expr_unary
# Description: Recursively display a UNARY Node
# Arguments: $a0 = Node Pointer, $a1 = Indent Level
# Returns: None
fn_dump_expr_unary:
    addi    $sp,    $sp,    -16
    sw      $ra,    0($sp)
    sw      $a0,    4($sp)
    sw      $a1,    8($sp)
    sw      $s0,    12($sp)

    lw      $t0,    offset_NODE_VALUE($a0)      # type:$t0 = node:$a0->type
    mul     $t2,    $t0,   4                    # str_tokens_offset:$t2 = type:$t0
    la      $t3,    str_TOKENS                  # str_tokens:$t3 = &str_tokens
    add     $t3,    $t3,    $t2                 # str_tokens:$t3 += str_tokens_offset:$t2
    lw      $t4,    0($t3)                      # type_str:$t4 = *$t3

    PRINT_CSTR(" (")
    PRINT_STR(move, $t4)
    PRINT_CSTR("):")

    lw      $a0,    offset_NODE_LEFT($s0)       # left:$t0 = node:$a0->left
    PRINT_CSTR("\n")
    jal     fn_dump_expr

exit_dump_expr_unary:
    lw      $s0,    12($sp)
    lw      $a1,    8($sp)
    lw      $a0,    4($sp)
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    16
    jr      $ra

# Function: fn_dump_expr_binary
# Description: Recursively display a BINARY Node
# Arguments: $a0 = Node Pointer, $a1 = Indent Level
# Returns: None
fn_dump_expr_binary:
    addi    $sp,    $sp,    -16
    sw      $ra,    0($sp)
    sw      $a0,    4($sp)
    sw      $a1,    8($sp)
    sw      $s0,    12($sp)

    move    $s0,    $a0                         # parent:$s0 = node:$a0

    lw      $t0,    offset_NODE_VALUE($a0)      # type:$t0 = node:$a0->type
    mul     $t2,    $t0,   4                    # str_tokens_offset:$t2 = type:$t0
    la      $t3,    str_TOKENS                  # str_tokens:$t3 = &str_tokens
    add     $t3,    $t3,    $t2                 # str_tokens:$t3 += str_tokens_offset:$t2
    lw      $t4,    0($t3)                      # type_str:$t4 = *$t3

    PRINT_CSTR(" (")
    PRINT_STR(move, $t4)
    PRINT_CSTR("):")

    lw      $a0,    offset_NODE_LEFT($s0)       # left:$t0 = node:$a0->left
    PRINT_CSTR("\n")
    jal     fn_dump_expr

    lw      $a0,    offset_NODE_RIGHT($s0)       # right:$t0 = node:$a0->right
    PRINT_CSTR("\n")
    jal     fn_dump_expr

exit_dump_expr_binary:
    lw      $s0,    12($sp)
    lw      $a1,    8($sp)
    lw      $a0,    4($sp)
    lw      $ra,    0($sp)
    addi    $sp,    $sp,    16
    jr      $ra