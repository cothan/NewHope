// this file uses the alternate macro mode
.altmacro

.ifndef _FUNCTIONS_H_S_
.set    _FUNCTIONS_H_S_ , 0

.macro              function  name:req
  .global             name
  .type               name, %function
  .func               name, name
  name&:
.endm


.macro              endfunc  name:req
  .pool
  .size               name, . - name
  .endfunc
.endm


.endif  // _FUNCTIONS_H_S_
