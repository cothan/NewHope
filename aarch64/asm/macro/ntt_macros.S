// this file uses the alternate macro mode
.altmacro

.ifndef _NTT_H_S_
.set    _NTT_H_S_ , 0

.macro transposeElements a, b_out, b_in
  // transposes the elements of two vectors
  trn2 \b_out, \a, \b_in
  trn1 \a, \a, \b_in
.endm

.macro loadDistantElementsInterleaved vdst1, vdst2, xsrc, xdistance
  // loads distant elements interleaved for the fifth layer of the ntt
  ld1 {\vdst1\().h}[0], [\xsrc], \xdistance
  ld1 {\vdst2\().h}[0], [\xsrc], \xdistance
  ld1 {\vdst1\().h}[1], [\xsrc], \xdistance
  ld1 {\vdst2\().h}[1], [\xsrc], \xdistance
  ld1 {\vdst1\().h}[2], [\xsrc], \xdistance
  ld1 {\vdst2\().h}[2], [\xsrc], \xdistance
  ld1 {\vdst1\().h}[3], [\xsrc], \xdistance
  ld1 {\vdst2\().h}[3], [\xsrc], \xdistance
  ld1 {\vdst1\().h}[4], [\xsrc], \xdistance
  ld1 {\vdst2\().h}[4], [\xsrc], \xdistance
  ld1 {\vdst1\().h}[5], [\xsrc], \xdistance
  ld1 {\vdst2\().h}[5], [\xsrc], \xdistance
  ld1 {\vdst1\().h}[6], [\xsrc], \xdistance
  ld1 {\vdst2\().h}[6], [\xsrc], \xdistance
  ld1 {\vdst1\().h}[7], [\xsrc], \xdistance
  ld1 {\vdst2\().h}[7], [\xsrc], \xdistance
.endm

.macro storeDistantElements vdst1, vdst2, xsrc, xdistance
  // stores distant elements to memory
  st1 {\vdst1\().h}[0], [\xsrc], \xdistance
  st1 {\vdst1\().h}[1], [\xsrc], \xdistance
  st1 {\vdst1\().h}[2], [\xsrc], \xdistance
  st1 {\vdst1\().h}[3], [\xsrc], \xdistance
  st1 {\vdst1\().h}[4], [\xsrc], \xdistance
  st1 {\vdst1\().h}[5], [\xsrc], \xdistance
  st1 {\vdst1\().h}[6], [\xsrc], \xdistance
  st1 {\vdst1\().h}[7], [\xsrc], \xdistance
  st1 {\vdst2\().h}[0], [\xsrc], \xdistance
  st1 {\vdst2\().h}[1], [\xsrc], \xdistance
  st1 {\vdst2\().h}[2], [\xsrc], \xdistance
  st1 {\vdst2\().h}[3], [\xsrc], \xdistance
  st1 {\vdst2\().h}[4], [\xsrc], \xdistance
  st1 {\vdst2\().h}[5], [\xsrc], \xdistance
  st1 {\vdst2\().h}[6], [\xsrc], \xdistance
  st1 {\vdst2\().h}[7], [\xsrc], \xdistance
.endm



.macro ntt_odd_layer va, vb_out, vb_in, omega16_1, omega16_2, vt1, vtb2, \
    eq32=v15.s[0], eqp32=v15.s[1], v3q16=v14, vr32=v13
  // NTT odd layer (1,3,5,7,9) operations for 14bit inputs.
  // Reduction after addition is skipped, as results are < 2**15
  // inputs:
  //  * va.8h: all values < 2**14, representing a[j]
  //  * vb_out: empty/nonempty output vector, see below
  //  * vb_in.8h: all values < 2**14, representing a[j+distance]
  //  * omega16_1: vector of 16bit elements or single 16bit element to be
  //               multiplied by first half of vb
  //  * omega16_2: vector of 16bit elements or single 16bit element to be
  //               multiplied by second half of vb
  //  * vt1: temporary register
  //  * vtb2: temporary register, see below
  // optional inputs:
  //  * eq32: 32bit vector element with value q=12289, vector in range v0-v15
  //  * eqp32: 32bit vector element with value q'= -q**(-1) mod 2**18 = 12287,
  //           vector in range v0-v15
  //  * v3q16.8h: vector of 16bit elements with value 3*q = 36867 each
  //  * vr32.4s: vector of 32bit elements with value 2**18-1 each
  //
  // two special cases concerning vb/vtb vector-registers:
  //  * vb_in and vb_out are the same register
  //    -> all temporary registers need to be distinct
  //  * vb_in and vb_out are two distinct regisers:
  //    -> vtb2 and vb_in can be the same register
  //
  // outputs:
  //  * va.8h: all values < 2**15
  //  * vb_out.8h: all values < 2**14

  // butterfly for 14bit inputs
  // butterfly14 va, vb_out, vb_in, v3q16
  butterfly14 \va, \vt1, \vb_in, \v3q16

  // multiply omega to vt1 -> widening to 32bit elements
  umull \vb_out\().4s, \vt1\().4h, \omega16_1  // b = t1 * omega1
  umull2 \vt1\().4s, \vt1\().8h, \omega16_2  // t1 = t1 * omega2

  // montgomery32 va1, va2, vt1, eq32, eqp32, vr32
  montgomery32 \vb_out, \vt1, \vtb2, \eq32, \eqp32, \vr32

  // skip reduction after addition in odd layer, as va is < 2**15

.endm



.macro rptNtt_odd_layer num,\
                        a_v,      a_s,      a_inc=1,      \
                        b_out_v,  b_out_s,  b_out_inc=1,  \
                        b_in_v,   b_in_s,   b_in_inc=1,   \
                        t1_v,     t1_s,     t1_inc=1,     \
                        t2_v,     t2_s,     t2_inc=1,     \
                        omega16_1_list,                   \
                        omega16_2_list

  // butterfly for 14bit inputs
  rptButterfly14  \num, \
                  \a_v,       \a_s,     \a_inc,   \
                  \t1_v,      \t1_s,    \t1_inc   \
                  \b_in_v,    \b_in_s,  \b_in_inc \

  // multiply omega to t1 -> widening to 32bit elements
  // b = t1 * omega1
  rptop_m_list  \num, umull, \
              b_out_v,  b_out_s,  .4s,  b_out_inc,  \
              t1_v,     t1_s,     .4h,  t1_inc,     \
              omega16_1_list
  // t1 = t1 * omega2
  rptop_m_list  \num, umull2, \
              t1_v,     t1_s,     .4s,  t1_inc,     \
              t1_v,     t1_s,     .8h,  t1_inc,     \
              omega16_2_list

  // montgomery reduction back to 14-bit
  rptMontgomery32 \num, \
                  b_out_v,  b_out_s, b_out_inc,  \
                  t1_v,     t1_s,    t1_inc,     \
                  t2_v,     t2_s,    t2_inc,     \

.endm



.macro ntt_even_layer va, vb_out, vb_in, omega32_1, omega32_2, vt1, vtb2, vtb3, \
    eq16=v15.h[0], eq32=v15.s[0], eqp32=v15.s[1], v3q16=v14, vr32=v13
  // NTT even layer (2,4,6,8,10) operations for 15bit inputs.
  // Including reduction after addition.
  // inputs:
  //  * va.8h: all values < 2**15, representing a[j]
  //  * vb_out: empty/nonempty output vector, see below
  //  * vb_in.8h: all values < 2**15, representing a[j+distance]
  //  * omega32_1: vector of 32bit elements or single 32bit element to be
  //               multiplied by first half of vb
  //  * omega32_2: vector of 32bit elements or single 32bit element to be
  //               multiplied by second half of vb
  //  * vt1: temporary register
  //  * vtb2: temporary register, see below
  //  * vtb3: temporary register, see below
  // optional inputs:
  //  * eq16: 16bit vector element with value q=12289, vector in range v0-v15
  //  * eq32: 32bit vector element with value q=12289, vector in range v0-v15
  //  * eqp32: 32bit vector element with value q'= -q**(-1) mod 2**18 = 12287,
  //           vector in range v0-v15
  //  * v3q16.8h: vector of 16bit elements with value 3*q = 36867 each
  //  * vr32.4s: vector of 32bit elements with value 2**18-1 each
  //
  // two special cases concerning vb/vtb vector-registers:
  //  * vb_in and vb_out are the same register:
  //    -> vtb2 and vtb3 can be the same register
  //  * vb_in and vb_out are two distinct regisers:
  //    -> vtb2 and vb_out can be the same register and
  //    -> vtb3 and vb_in can be the same register
  //
  // outputs:
  //  * va.8h: all values < 2**14
  //  * vb_out.8h: all values < 2**14


  // butterfly for 15bit inputs
  // butterfly15 va, vb_out1, vb_out2, vb_in, v3q16
  butterfly15 \va, \vtb2, \vt1, \vb_in, \v3q16

  // multiply omega to t on 32bit elements
  mul \vb_out\().4s, \vtb2\().4s, \omega32_1  // t1 = t1 * omega1
  mul \vt1\().4s, \vt1\().4s, \omega32_2  // t2 = t2 * omega1

  // montgomery32 va1, va2, vt1, eq32, eqp32, vr32
  montgomery32 \vb_out, \vt1, \vtb3, \eq32, \eqp32, \vr32

  // fastBarrett16 va, vt, eq16
  fastBarrett16 \va, \vt1, \eq16

.endm


.macro rptNtt_even_layer num,\
                        a_v,      a_s,      a_inc=1,      \
                        b_out_v,  b_out_s,  b_out_inc=1,  \
                        b_in_v,   b_in_s,   b_in_inc=1,   \
                        t1_v,     t1_s,     t1_inc=1,     \
                        t2_v,     t2_s,     t2_inc=1,     \
                        t3_v,     t3_s,     t3_inc=1,     \
                        omega32_1_list,                   \
                        omega32_2_list

  // butterfly for 14bit inputs
  rptButterfly15  \num, \
                  \a_v,       \a_s,     \a_inc,   \
                  \t2_v,      \t2_s,    \t2_inc   \
                  \t1_v,      \t1_s,    \t1_inc   \
                  \b_in_v,    \b_in_s,  \b_in_inc \

  // multiply omega to t1 -> widening to 32bit elements
  // b = t1 * omega1
  rptop_m_list  \num, mul, \
              b_out_v,  b_out_s,  .4s,  b_out_inc,  \
              t2_v,     t2_s,     .4s,  t2_inc,     \
              omega32_1_list
  // t1 = t1 * omega2
  rptop_m_list  \num, mul, \
              t1_v,     t1_s,     .4s,  t1_inc,     \
              t1_v,     t1_s,     .4s,  t1_inc,     \
              omega32_2_list

  // montgomery reduction back to 14-bit
  rptMontgomery32 \num, \
                  b_out_v,  b_out_s, b_out_inc,  \
                  t1_v,     t1_s,    t1_inc,     \
                  t3_v,     t3_s,    t3_inc

  rptFastBarrett16 num, \
                      \a_v,       \a_s,     \a_inc, \
                      t1_v,     t1_s,    t1_inc,
.endm

.endif  // _NTT_H_S_
