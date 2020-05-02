// this file uses the alternate macro mode
.altmacro

.ifndef _RPTMACROS_H_S_
.set    _RPTMACROS_H_S_ , 0

// these macros allow operations to be repeated a speciefied number of times
// with different registers


.macro  rptop num, op, \
              d_v, d_s, d_t, d_inc=1, \
              n_v, n_s, n_t, n_inc=1, \
              m_v, m_s, m_t, m_inc=1
  // this repeats the operation 'op' for 'num' times
  // ?_v is the register type, e.g. v
  // ?_s is the starting register number, e.g. 0
  // ?_inc is the increment for each instruction, e.g. 1
  // it assembles the operation as shown in the line below
  \op \d_v\d_s\d_t, \n_v\n_s\n_t, \m_v\m_s\m_t
  .if     \num-1
    rptop %\num-1, \op, \
          \d_v, %\d_s+\d_inc, \d_t, \d_inc, \
          \n_v, %\n_s+\n_inc, \n_t, \n_inc, \
          \m_v, %\m_s+\m_inc, \m_t, \m_inc
  .endif
.endm



.macro  rptuop num, op, \
              d_v, d_s, d_t, d_inc=1, \
              n_v, n_s, n_t, n_inc=1
  // this repeats the unary operation 'op' for 'num' times
  // ?_v is the register type, e.g. v
  // ?_s is the starting register number, e.g. 0
  // ?_inc is the increment for each instruction, e.g. 1
  // it assembles the operation as shown in the line below
  \op \d_v\d_s\d_t, \n_v\n_s\n_t
  .if     \num-1
    rptuop %\num-1, \op, \
          \d_v, %\d_s+\d_inc, \d_t, \d_inc, \
          \n_v, %\n_s+\n_inc, \n_t, \n_inc
  .endif
.endm

.macro  rpt2ops num, \
                op1, \
                  d1_v, d1_s, d1_t, d1_inc=1, \
                  n1_v, n1_s, n1_t, n1_inc=1, \
                  m1_v, m1_s, m1_t, m1_inc=1, \
                op2, \
                  d2_v, d2_s, d2_t, d2_inc=1, \
                  n2_v, n2_s, n2_t, n2_inc=1, \
                  m2_v, m2_s, m2_t, m2_inc=1
  // this repeats the two operations 'op1' and 'op2' for 'num' times
  // ?_v is the register type, e.g. v
  // ?_s is the starting register number, e.g. 0
  // ?_inc is the increment for each instruction, e.g. 1
  // it assembles the operations as shown in the line below
  \op1 \d1_v\d1_s\d1_t, \n1_v\n1_s\n1_t, \m1_v\m1_s\m1_t
  \op2 \d2_v\d2_s\d2_t, \n2_v\n2_s\n2_t, \m2_v\m2_s\m2_t
  .if     \num-1
    rpt2ops %\num-1, \
          \op1, \
            \d1_v, %\d1_s+\d1_inc, \d1_t, \d1_inc, \
            \n1_v, %\n1_s+\n1_inc, \n1_t, \n1_inc, \
            \m1_v, %\m1_s+\m1_inc, \m1_t, \m1_inc, \
          \op2, \
            \d2_v, %\d2_s+\d2_inc, \d2_t, \d2_inc, \
            \n2_v, %\n2_s+\n2_inc, \n2_t, \n2_inc, \
            \m2_v, %\m2_s+\m2_inc, \m2_t, \m2_inc
  .endif
.endm

.macro  rptop_m_list  num, op, \
                    d_v, d_s, d_t, d_inc=1, \
                    n_v, n_s, n_t, n_inc=1, \
                    m, m_list:vararg
  // this repeats the operation 'op' for 'num' times
  // ?_v is the register type, e.g. v
  // ?_s is the starting register number, e.g. 0
  // ?_inc is the increment for each instruction, e.g. 1
  // as a third operand, a list is taken, consisting with 'num' entries
  // it assembles the operations as shown in the line below
  \op \d_v\d_s\d_t, \n_v\n_s\n_t, m
  .if     \num-1
    rptop_m_list %\num-1, \op, \
          \d_v, %\d_s+\d_inc, \d_t, \d_inc, \
          \n_v, %\n_s+\n_inc, \n_t, \n_inc, \
          m_list
  .endif
.endm

.macro  rptop4list  op, list_i, list:vararg
  // this repeats the operation 'op' for all entries in the list
  // it assembles the operations as shown in the line below
  op list_i
  .ifnb  list
    rptop4list op, list
  .endif
.endm


.endif  // _RPTMACROS_H_S_
