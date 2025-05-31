# ttg-asm
A Truth Table Generator for Propositional Logic Formulas made with MIPS Assembly.

This project is a *lite*-version of the original — written in *Python* — see https://github.com/daawaan4x/ttg

## Features

- **Supported Logical Operators**: In order of precedence 
	- **NOT:**, `!`, `~`
	- **AND:**, `&`, `^`
	- **OR:**, `|`, `v`
- **Complex Formulas**: Input nested formulas using parenthesis `(...)` 
- **26 Variables**: Add any variable using any capital alphabet `A-Z` letter.

## Table of Contents

1. [Algorithm](#algorithm)
   - [Lexer](#lexer)
   - [Parser](#parser)
   - [Evaluator](#evaluator)
   - [Error Handling](#error-handling)
3. [User Manual](#algorithm)
   - [Running From Source](#running-from-source)
   - [Compiling From Source](#compiling-from-source)

## Algorithm

This Truth-Table Generator implements an interpreter divided into three components to handle different phases, namely:

1. **Lexer** for *tokenization* (converting `string` input to `Token[]`) 
2. **Parser** for *Expression Tree* construction (constructing `Expr` tree from `Token[]`)
3. **Evaluator** for the *Expression Tree* (evaluating `Expr` tree into a `bool[]`)

### Lexer

The **Lexer** iteratively checks each character of the input string that can be classified as a token and then converts them into a list.

```
function tokenize(input_formula):
  tokens = empty list

  for each char in input_formula:
    if char is '(': add "PARENL" token
    elif char is ')': add "PARENR" token
    elif char is NOT: add "NOT" token
    elif char is AND: add "AND" token
    elif char is OR: add "OR" token
    elif char is variable: add "VAR" token
    else: add "ERROR" token

  return tokens
```

### Parser

The **Parser** is an implementation of a [*Recursive-Descent Parser*](https://en.wikipedia.org/wiki/Recursive_descent_parser) which validates the arrangement of the tokens with the expected grammar and simultaneously constructs an [*Expression Tree*](https://en.wikipedia.org/wiki/Binary_expression_tree) — wherein each *Node* represents its corresponding *token* and its related *Nodes*. It uses the following grammar described in a psuedo-format similar to [*Backus-Naur Form* (**BNF**)](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form) and it utilizes the [*Precedence-Climbing Method*](https://en.wikipedia.org/wiki/Operator-precedence_parser) to implement operator precedence.

```
expr_group = ( expr )
expr_primary = expr_group | variable
expr_not = expr_primary | NOT expr_not
expr_and = expr_not | expr_not AND expr_and
expr_or = expr_and | expr_and OR expr_or
expr = expr_or
```

```
function parse(tokens):
  return expr()

  function expr():
    return expr_or()

  function expr_or():
    left_expr = expr_and()
    while next token is OR:
      right_expr = expr_and()
      left_expr = new binary_expr(left_expr, "or", right_expr)
    return left_expr

  function expr_and():
    left_expr = expr_not()
    while next token is AND:
      right_expr = expr_not()
      left_expr = new binary_expr(left_expr, "and", right_expr)
    return left_expr

  function expr_not():
    if next token is NOT:
      return new unary_expr("not", expr_not())
    return expr_primary()

  function expr_primary():
    if next token is "(":
      expression = expr()
      expect ")"
      return new group_expr(expression)
    if next token is variable:
      return new variable_expr(token)
    throw error("Expected variable or expression")
```

### Evaluator

The **Evaluator** is simply a set of functions matched to each of the types of *Nodes* in the *Expression Tree*, namely `Variable` nodes, `Unary` nodes, and `Binary` nodes. Due to the nature of Tree Data Structures, evaluating the *Expression Tree* is as simple as recursively running each function in the *Expression Tree* for each *Node*.

A single evaluation will only return the results of each sub-expression in the Expression Tree based on the current set of truth-values used for each of the variables. In order to generate a truth-table, the Evaluator will generate the [*cartesian product*](https://en.wikipedia.org/wiki/Cartesian_product) of each of all the variables' possible states (**1** | **0**) then repeatedly evaluate the *Expression Tree* for each row of values. 

In simpler terms, the Evaluator will repeatedly evaluate the *Expression Tree* for each of all the possible combinations of **1** and **0** values for all the variables, in order to construct each row of the truth table.

```
function generate_truth_combinations(variables):
  combinations = empty list
  total_combinations = 2 ^ (count of variables)
  for each number from 0 to total_combinations - 1:
    create an empty dictionary called truth_values
    for each variable and index:
      value = get (index)'th bit digit of number
      set value for variable in truth_values dictionary
    add truth_values to combinations list
  return combinations

function evaluate(expression_tree, truth_values):
  if expression_tree is a group expression:
    return evaluate(expression_tree.child, truth_values)

  if expression_tree is a variable:
    return truth_values[variable]
  
  if expression_tree is a unary expression:
    right_value = evaluate(right_expr, truth_values)
    if operator is "not":
      return NOT right_value
  
  if expression_tree is a binary expression:
    left_value = evaluate(left_expr, truth_values)
    right_value = evaluate(right_expr, truth_values)
    if operator is "and": return left_value AND right_value
    if operator is "or": return left_value OR right_value

function generate_truth_table(expression_tree, variables):
  combinations = generate_truth_combinations(variables)
  for each combination:
    evaluate the expression_tree with current truth values
  return truth table
```

### Error Handling

**Invalid Token.** The **Lexer** is a resilient tokenizer and will capture any group of unrecognizable characters as a `Token` of `"ERROR"` type until the end of the input instead of terminating early. This allows the **Lexer** to display all the invalid tokens present in the input.

**Invalid Grammar.** The **Parser** while constructing the *Expression Tree* will immediately raise errors upon detecting any incorrect grammar and will inform the user on the expected supposed token in place of the current suspected token. Due to its complexity, the implementation is not resilient and will terminate upon encountering the first invalid grammar.