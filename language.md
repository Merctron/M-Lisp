## Language Specification

Meta lisp supports the following operators and keywords:

```
# Arithmetic operators for integers: +, -, *, /
M-Lisp>(+ 1 1)
2

# 'def' to define a variable.
M-Lisp>(def a 4)
M-Lisp>a
4

# 'set' to modify a variable.
M-Lisp>(set a 5)
M-Lisp>a
5

# 'quote' to return an expression. Note that quote does not merely print values
# and returns the expression as a list (is a list is quoted).
M-Lisp>(quote a)
a
M-Lisp>(quote (a b c))
(a b c)

# 'lambda' to create a function.
M-Lisp>(def addtwo (lambda (a) (+ a 2)))
M-Lisp>(addtwo 3)                       
5

# 'atom' to determine whether an expression is atomic, i.e, whether it
# evaluates to value (returns 1) or a list (returns 0).
M-Lisp>(atom a)          
1                       
M-Lisp>(atom (quote (a)))
0

# 'car' to return the first value from the result of a list expression.
M-Lisp>(car (quote (+ b c)))
+

# 'cdr' to return the all values but the first from the result of a list
# expression.
M-Lisp>(car (quote (+ b c)))
(b c)

# 'if' for conditional expressions.
M-Lisp>(if (atom 1) 3 4)
3

# 'eq' to check the equality of two expressions.
M-Lisp>(eq 3 (+ 1 2))
1

# 'null' to check if an expression returns an empty list.
M-Lisp>(null (quote (1)))
0

# 'begin' to evaluate a series of expressions and return the result of the last
# expression.
M-Lisp>(begin (def a 1) (+ a 1))
2

# 'cons' to append expressions.
M-Lisp>(cons 1 (quote (2 3)))
(1 2 3)

# 'cond' to evaluate a series of conditonals and return the first value
# associated with a true conditional.
M-Lisp>(cond ((atom 1) 1) ((atom 2) 2))
1
```