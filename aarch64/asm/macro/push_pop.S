// this file uses the alternate macro mode
.altmacro

.ifndef _PUSH_POP_H_S_
.set    _PUSH_POP_H_S_ , 0

// aarch64 does not offer push/pop functionality
// Therefore we have some small makros for it, assuming a decreasing stack
// sp must be 16-bytes aligned -> only save in pairs

// # registers which need to be saved by callee:
// x19 - x29: preserved across calls

// # important registers which should be saved before function call
// x30: link register

// # vector registers which need to be saved by callee:
// v8 - v15: bottom 64-bit preserved across calls


.macro pushp xa, xb
  // push xa and xb onto the stack, sp changed before store
  // both registers are 64-bit
  // also works with bottom 64-bit of vector registers (da, db)
  stp xa, xb, [sp, -16]!
.endm

.macro  push xa, xb, list:vararg
  // push a list of registers onto the stack in reversed order, to match pop
  //
  // check the second parameter -> error for odd number of registers
  .ifb xb
    .error "push macro requires an even number of registers."
  .endif
  // recursion
  .ifnb  list
    push list
  .endif
  // push the first two registers onto the stack
  pushp xa, xb
.endm


.macro popp xa, xb
  // pop xa and xb from the stack, sp changed after load
  // both registers are 64-bit
  // also works with bottom 64-bit of vector registers (da, db)
  ldp xa, xb, [sp], 16
.endm

.macro  pop xa, xb, list:vararg
  // pop a list of registers from the stack
  //
  // check the second parameter -> error for odd number of registers
  .ifb xb
    .error "pop macro requires an even number of registers."
  .endif
  // pop the first two registers from the stack
  popp xa, xb
  //recursion
  .ifnb  list
    pop list
  .endif
.endm

.endif // _PUSH_POP_H_S_
