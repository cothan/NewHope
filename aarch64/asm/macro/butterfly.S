// this file uses the alternate macro mode
.altmacro

.ifndef _BUTTERFLY_H_S_
.set    _BUTTERFLY_H_S_ , 0

.macro butterfly14 va, vb_out, vb_in, v3q16
  // butterfly operation for 14bit inputs only!, needs 3 instructions
  // excluding multiplication with omegas and reduction
  // output is 15bit/16bit
  // inputs:
  //  * va.8h: all values < 2**14, representing a[j]
  //  * vb_out: empty vector
  //  * vb_in.8h: all values < 2**14, representing a[j+distance]
  //  * v3q16.8h: vector of 16bit elements with value 3*q = 36867 each
  // outpus:
  // * va.8h: all values < 2**15
  // * vb_out.8h: all values < 2**16

  // first half of butterfly
  add \vb_out\().8h, \va\().8h, \v3q16\().8h  // t = a[j] + 3*q < 2**16
  sub \vb_out\().8h, \vb_out\().8h, \vb_in\().8h  // t = t - a[j+distance]
  // second half of butterfly
  add \va\().8h, \va\().8h, \vb_in\().8h  // a[j]_new = a[j] + a[j+distance]
.endm

.macro rptButterfly14 num, \
                      a_v,      a_s,      a_inc=1,      \
                      b_out_v,  b_out_s,  b_out_inc=1,  \
                      b_in_v,   b_in_s,   b_in_inc=1,   \
                      v3q16_v=v,v3q16_n=14
  // optimized for pipeline

  // first half of butterfly
  // t = a[j] + 3*q < 2**16
  rptop \num, add, \
        \b_out_v, \b_out_s, .8h, \b_out_inc,  \
        \a_v,     \a_s,     .8h, \a_inc,      \
        \v3q16_v, \v3q16_n, .8h, 0

  // t = t - a[j+distance]
  rptop \num, sub, \
        \b_out_v, \b_out_s, .8h, \b_out_inc,  \
        \b_out_v, \b_out_s, .8h, \b_out_inc,  \
        \b_in_v,  \b_in_s,  .8h, \b_in_inc

  // second half of butterfly
  // a[j]_new = a[j] + a[j+distance]
  rptop \num, add, \
        \a_v,     \a_s,     .8h, \a_inc,      \
        \a_v,     \a_s,     .8h, \a_inc,      \
        \b_in_v,  \b_in_s,  .8h, \b_in_inc

.endm

.macro butterfly15 va, vb_out1, vb_out2, vb_in, v3q16
  // butterfly operation for 15bit inputs, needs 5 instructions
  // excluding multiplication with omegas and reduction
  // output is 16bit/17bit
  // inputs:
  //  * va.8h: all values < 2**15, representing a[j]
  //  * vb_out1: empty output vector
  //  * vb_out2: empty output vector
  //  * vb_in.8h: all values < 2**15, representing a[j+distance]
  //  * v3q16.8h: vector of 16bit elements with value 3*q = 36867 each
  // outpus:
  // * va.8h: all values < 2**16
  // * vb_out1.4s: all values < 2**17
  // * vb_out2.4s: all values < 2**17

  // first half of butterfly
  uaddl  \vb_out1\().4s, \va\().4h, \v3q16\().4h  // t1 = a[j] + 3*q < 2**17
  uaddl2 \vb_out2\().4s, \va\().8h, \v3q16\().8h  // t2 = a[j] + 3*q < 2**17
  usubw \vb_out1\().4s, \vb_out1\().4s, \vb_in\().4h  // t1 = t1 - a[j+distance]
  usubw2 \vb_out2\().4s, \vb_out2\().4s, \vb_in\().8h  // t2 = t2 - a[j+distance]
  // second half of butterfly
  add \va\().8h, \va\().8h, \vb_in\().8h  // a[j]_new = a[j] + a[j+distance]
.endm

.macro rptButterfly15 num, \
                      a_v,      a_s,      a_inc=1,      \
                      b_out1_v,  b_out1_s,  b_out1_inc=1,  \
                      b_out2_v,  b_out2_s,  b_out2_inc=1,  \
                      b_in_v,   b_in_s,   b_in_inc=1,   \
                      v3q16_v=v,v3q16_n=14
  // optimized for pipeline

  // first half of butterfly
  // t1 = a[j] + 3*q < 2**17
  rptop \num, uaddl, \
        \b_out1_v, \b_out1_s, .4s, \b_out1_inc,  \
        \a_v,     \a_s,     .4h, \a_inc,      \
        \v3q16_v, \v3q16_n, .4h, 0
  // t2 = a[j] + 3*q < 2**17
  rptop \num, uaddl2, \
        \b_out2_v, \b_out2_s, .4s, \b_out2_inc,  \
        \a_v,     \a_s,     .8h, \a_inc,      \
        \v3q16_v, \v3q16_n, .8h, 0

  // t = t - a[j+distance]
  rptop \num, usubw, \
        \b_out1_v, \b_out1_s, .4s, \b_out1_inc,  \
        \b_out1_v, \b_out1_s, .4s, \b_out1_inc,  \
        \b_in_v,  \b_in_s,  .4h, \b_in_inc

  rptop \num, usubw2, \
        \b_out2_v, \b_out2_s, .4s, \b_out2_inc,  \
        \b_out2_v, \b_out2_s, .4s, \b_out2_inc,  \
        \b_in_v,  \b_in_s,  .8h, \b_in_inc
  // second half of butterfly
  // a[j]_new = a[j] + a[j+distance]
  rptop \num, add, \
        \a_v,     \a_s,     .8h, \a_inc,      \
        \a_v,     \a_s,     .8h, \a_inc,      \
        \b_in_v,  \b_in_s,  .8h, \b_in_inc

.endm

.endif // _BUTTERFLY_H_S_
