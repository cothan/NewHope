// this file uses the alternate macro mode
.altmacro

.ifndef _REDUCTIONS_H_S_
.set    _REDUCTIONS_H_S_ , 0

.macro fullRed2q va, vt, vq16
  // full reduction routine for values smaller 2*q, needs 2 instructions
  // complete reduction routine
  // inputs:
  //  * va.8h, all values < 2*q = 24578
  //  * vt.8h: temporary register
  //  * vq16: vector of 16bit elements with value q=12289 each
  // output:
  //  * va.8h, all values < q=12289

  sub  \vt\().8h, \va\().8h, \vq16\().8h  // t = a - q, underflow for a < q
  // the underflow causes the result to be t = 2**16 + a -q
  umin \va\().8h, \va\().8h, \vt\().8h    // a = min(a,t), unsigned
  // this takes a for a<q and t for a>=q

.endm


.macro rptFullRed2q num, \
                    a_v, a_s, a_inc=1, \
                    t_v, t_s, t_inc=1, \
                    q_v, vq16
  // optimized for pipeline

  // t = a - q, underflow for a < q
  // the underflow causes the result to be t = 2**16 + a -q
  rptop \num, sub, \
        \t_v, \t_s,  .8h, \t_inc, \
        \a_v, \a_s,  .8h, \a_inc, \
        \q_v, \vq16, .8h, 0

  // a = min(a,t), unsigned
  // this takes a for a<q and t for a>=q
  rptop \num, umin, \
        \a_v, \a_s,  .8h, \a_inc, \
        \a_v, \a_s,  .8h, \a_inc, \
        \t_v, \t_s,  .8h, \t_inc
.endm


.macro fastBarrett16 va, vt, eq16
  // 16bit fast barrett reduction, needs 4 instructions
  // incomplete reduction routine to 14bits
  // inputs:
  //  * va.8h, all values < 2**16
  //  * vt: temporary register
  //  * eq16: 16bit vector element with value q=12289, vector in range v0-v15
  // output:
  //  * va.8h, all values <= 16379 < 2**14

  // shift once at the beginning, and once at the end.
  // needed to avoid overflows and at the same time ensure accuracy
  ushr \vt\().8h, \va\().8h, 8  // t = a / 2**8
  usra \vt\().8h, \va\().8h, 6  // t += a / 2**6 =^= t = t * 5
  // alternative to usra:
  // mul \vt\().8h, \vt\().8h, \eA16  // t = t * A, with A = 5
  ushr \vt\().8h, \vt\().8h, 8  // t = t / 2**8
  mls \va\().8h, \vt\().8h, \eq16  // a -= t * q
.endm

.macro rptFastBarrett16 num, \
                    a_v, a_s, a_inc=1, \
                    t_v, t_s, t_inc=1, \
                    eq16_v=v,   eq16_n=15,  eq32_t=.h[0]
  // optimized for pipeline

  rptop num, ushr, \
        t_v,     t_s,     .8h,    t_inc, \
        a_v,     a_s,     .8h,    a_inc, \
        ,         8,       ,       0

  rptop num, usra, \
        t_v,     t_s,     .8h,    t_inc, \
        a_v,     a_s,     .8h,    a_inc, \
        ,         6,       ,       0

  rptop num, ushr, \
        t_v,     t_s,     .8h,    t_inc, \
        t_v,     t_s,     .8h,    t_inc, \
        ,         8,       ,       0

  rptop num, mls, \
        a_v,     a_s,     .8h,    a_inc, \
        t_v,     t_s,     .8h,    t_inc, \
        eq16_v,  eq16_n,   eq32_t,    0
.endm


.macro barrett32 va1, va2, vt1, vt2, eA32, eq32
  // 32bit barrett reduction, needs 14 instructions
  // complete reduction routine
  // inputs:
  //  * va1.4s, all values < 2**32
  //  * va2.4s, all values < 2**32
  //  * vt1: temporary register
  //  * vt2: temporary register
  //  * eA32: 32bit vector element with value A=2,863,078,533
  //          vector in range v0-v15
  //  * eq32: 32bit vector element with value q=12289, vector in range v0-v15
  // output:
  //  * va1.8h, all values < q = 12289 < 2**14

  // t1/t2 = a1 * A -> widening to 64bit elements
  umull \vt1\().2d, \va1\().2s, \eA32  // t1 = a1 * A [lower elements]
  umull2 \vt2\().2d, \va1\().4s, \eA32  // t2 = a1 * A [upper elements]
  // t1 = t1/t2 / 2**32 -> reducing to 32bit elements
  shrn \vt1\().2s, \vt1\().2d, 32  // t1 = t1 / 2**32 [lower elements]
  shrn2 \vt1\().4s, \vt2\().2d, 32  // t1 = t2 / 2**32 [upper elements]
  ushr \vt1\().4s, \vt1\().4s, 13  // t1 = t1 / 2**13
  mls \va1\().4s, \vt1\().4s, \eq32  // a -= t1 * q

  // t1/t2 = a2 * A -> widening to 64bit elements
  umull \vt1\().2d, \va2\().2s, \eA32  // t1 = a2 * A [lower elements]
  umull2 \vt2\().2d, \va2\().4s, \eA32  // t2 = a2 * A [upper elements]
  // t1 = t1/t2 / 2**32 -> reducing to 32bit elements
  shrn \vt1\().2s, \vt1\().2d, 32  // t1 = t1 / 2**32 [lower elements]
  shrn2 \vt1\().4s, \vt2\().2d, 32  // t1 = t2 / 2**32 [upper elements]
  ushr \vt1\().4s, \vt1\().4s, 13  // t1 = t1 / 2**13
  mls \va2\().4s, \vt1\().4s, \eq32  // a -= t1 * q

  // merging: a1 = a1/a2 -> reducing to 16bit elements
  xtn \va1\().4h, \va1\().4s  // a1 = a1 [lower elements]
  xtn2 \va1\().8h, \va2\().4s  // a1 = a2 [upper elements]
.endm


.macro rptBarrett32 num, \
                    a1_v, a1_s, a1_inc=1, \
                    a2_v, a2_s, a2_inc=1, \
                    t1_v, t1_s, t1_inc=1, \
                    t2_v, t2_s, t2_inc=1, \
                    eq32_v=v,   eq32_n=15,  eq32_t=.s[0], \
                    eA32_v=v,   eA32_n=15,  eA32_t=.s[1]
  // optimized for pipeline

  // t1/t2 = a1 * A -> widening to 64bit elements
  // umull \vt1\().2d, \va1\().2s, \eA32  // t1 = a1 * A [lower elements]
  rptop num, umull, \
        t1_v,     t1_s,     .2d,    t1_inc, \
        a1_v,     a1_s,     .2s,    a1_inc, \
        eA32_v,   eA32_n,   eA32_t, 0
  // umull2 \vt2\().2d, \va1\().4s, \eA32  // t2 = a1 * A [upper elements]
  rptop num, umull2, \
        t2_v,     t2_s,     .2d,    t1_inc, \
        a1_v,     a1_s,     .4s,    a1_inc, \
        eA32_v,   eA32_n,   eA32_t, 0
  // t1 = t1/t2 / 2**32 -> reducing to 32bit elements
  // shrn \vt1\().2s, \vt1\().2d, 32  // t1 = t1 / 2**32 [lower elements]
  rptop num, shrn, \
        t1_v,     t1_s,     .2s,    t1_inc, \
        t1_v,     t1_s,     .2d,    t1_inc, \
        ,         32,       ,       0
  // shrn2 \vt1\().4s, \vt2\().2d, 32  // t1 = t2 / 2**32 [upper elements]
  rptop num, shrn2, \
        t1_v,     t1_s,     .4s,    t1_inc, \
        t2_v,     t2_s,     .2d,    t2_inc, \
        ,         32,       ,       0
  // ushr \vt1\().4s, \vt1\().4s, 13  // t1 = t1 / 2**13
  rptop num, ushr, \
        t1_v,     t1_s,     .4s,    t1_inc, \
        t1_v,     t1_s,     .4s,    t1_inc, \
        ,         13,       ,       0
  // mls \va1\().4s, \vt1\().4s, \eq32  // a1 -= t1 * q
  rptop num, mls, \
        a1_v,     a1_s,     .4s,    a1_inc, \
        t1_v,     t1_s,     .4s,    t1_inc, \
        eq32_v,   eq32_n,   eq32_t, 0

  // t1/t2 = a2 * A -> widening to 64bit elements
  // umull \vt1\().2d, \va2\().2s, \eA32  // t1 = a2 * A [lower elements]
  rptop num, umull, \
        t1_v,     t1_s,     .2d,    t1_inc, \
        a2_v,     a2_s,     .2s,    a2_inc, \
        eA32_v,   eA32_n,   eA32_t, 0
  // umull2 \vt2\().2d, \va2\().4s, \eA32  // t2 = a2 * A [upper elements]
  rptop num, umull2, \
        t2_v,     t2_s,     .2d,    t1_inc, \
        a2_v,     a2_s,     .4s,    a2_inc, \
        eA32_v,   eA32_n,   eA32_t, 0
  // t1 = t1/t2 / 2**32 -> reducing to 32bit elements
  // shrn \vt1\().2s, \vt1\().2d, 32  // t1 = t1 / 2**32 [lower elements]
  rptop num, shrn, \
        t1_v,     t1_s,     .2s,    t1_inc, \
        t1_v,     t1_s,     .2d,    t1_inc, \
        ,         32,       ,       0
  // shrn2 \vt1\().4s, \vt2\().2d, 32  // t1 = t2 / 2**32 [upper elements]
  rptop num, shrn2, \
        t1_v,     t1_s,     .4s,    t1_inc, \
        t2_v,     t2_s,     .2d,    t2_inc, \
        ,         32,       ,       0
  // ushr \vt1\().4s, \vt1\().4s, 13  // t1 = t1 / 2**13
  rptop num, ushr, \
        t1_v,     t1_s,     .4s,    t1_inc, \
        t1_v,     t1_s,     .4s,    t1_inc, \
        ,         13,       ,       0
  // mls \va2\().4s, \vt1\().4s, \eq32  // a2 -= t1 * q
  rptop num, mls, \
        a2_v,     a2_s,     .4s,    a2_inc, \
        t1_v,     t1_s,     .4s,    t1_inc, \
        eq32_v,   eq32_n,   eq32_t, 0

  // merging: a1 = a1/a2 -> reducing to 16bit elements
  // xtn \va1\().4h, \va1\().4s  // a1 = a1 [lower elements]
  rptuop num, xtn, \
        a1_v,     a1_s,     .4h,    a1_inc, \
        a1_v,     a1_s,     .4s,    a1_inc
  // xtn2 \va1\().8h, \va2\().4s  // a1 = a2 [upper elements]
  rptuop num, xtn2, \
        a1_v,     a1_s,     .8h,    a1_inc, \
        a2_v,     a2_s,     .4s,    a2_inc
.endm

.macro montgomery32 va1, va2, vt1, eq32, eqp32, vr32
  // 32bit montgomery reduction, needs 9 instructions
  // incomplete reduction routine, needs input to be in montgomery domain
  // output will be a * (r**(-1)) mod q, reduced to 14bits
  // with r = 2**18 and q = 12289
  // inputs:
  //  * va1.4s, all values <= 1,073,491,968 ~ 2**29.9
  //  * va2.4s, all values <= 1,073,491,968 ~ 2**29.9
  //  * vt1: temporary register
  //  * eq32: 32bit vector element with value q=12289, vector in range v0-v15
  //  * eqp32: 32bit vector element with value q'= -q**(-1) mod 2**18 = 12287,
  //           vector in range v0-v15
  //  * vr32: vector of 32bit elements with value 2**18-1 each, used as bitmask
  // output:
  //  * va1.8h, all values < 2**14

  // first block for a1
  mul \vt1\().4s, \va1\().4s, \eqp32  // t1 = a1 * q', overflow discarded
  // note: byte elements needed for and operation
  and \vt1\().16b, \vt1\().16b, \vr32\().16b  // t1 = t1 & (2**18-1)
  mla \va1\().4s, \vt1\().4s, \eq32 // a1 += t1 * q

  // second block for a2
  mul \vt1\().4s, \va2\().4s, \eqp32  // t1 = a2 * q', overflow discarded
  // note: byte elements needed for and operation
  and \vt1\().16b, \vt1\().16b, \vr32\().16b  // t1 = t1 & (2**18-1)
  mla \va2\().4s, \vt1\().4s, \eq32 // a2 += t1 * q

  // merging & division by r -> reducing to 16bit elements
  shrn \va1\().4h, \va1\().4s, 16  // a1 = a1/2**16
  shrn2 \va1\().8h, \va2\().4s, 16  // a1 = a2/2**16
  ushr \va1\().8h, \va1\().8h, 2 // a1 = a1/2**2
.endm


.macro rptMontgomery32 num, \
                    a1_v, a1_s, a1_inc=1, \
                    a2_v, a2_s, a2_inc=1, \
                    t_v, t_s, t_inc=1, \
                    eq32_v=v,   eq32_n=15,  eq32_t=.s[0], \
                    eqp32_v=v,  eqp32_n=15, eqp32_t=.s[1], \
                    vr32_v=v,   vr32_n=13
  // optimized for pipeline

  // first block for a1
  // t1 = a1 * q', overflow discarded
  rptop \num, mul, \
        \t_v,     \t_s,  .4s, \t_inc,  \
        \a1_v,    \a1_s, .4s, \a1_inc, \
        \eqp32_v, \eqp32_n, \eqp32_t, 0
  // note: byte elements needed for and operation
  // t1 = t1 & (2**18-1)
  rptop \num, and, \
        \t_v,  \t_s,  .16b, \t_inc, \
        \t_v,  \t_s,  .16b, \t_inc, \
        \vr32_v, \vr32_n,  .16b, 0
  // a1 += t1 * q
  rptop \num, mla, \
        \a1_v, \a1_s, .4s, \a1_inc, \
        \t_v,  \t_s,  .4s, \t_inc,  \
        \eq32_v, \eq32_n, \eq32_t, 0

  // second block for a2
  // t1 = a2 * q', overflow discarded
  rptop \num, mul, \
        \t_v,  \t_s,  .4s, \t_inc,  \
        \a2_v, \a2_s, .4s, \a2_inc, \
        \eqp32_v, \eqp32_n, \eqp32_t, 0
  // note: byte elements needed for and operation
  // t1 = t1 & (2**18-1)
  rptop \num, and, \
        \t_v,  \t_s,  .16b, \t_inc, \
        \t_v,  \t_s,  .16b, \t_inc, \
        \vr32_v, \vr32_n,  .16b, 0
  // a2 += t1 * q
  rptop \num, mla, \
        \a2_v, \a2_s, .4s, \a2_inc, \
        \t_v,  \t_s,  .4s, \t_inc,  \
        \eq32_v, \eq32_n, \eq32_t, 0

  // merging & division by r -> reducing to 16bit elements
  // a1 = a1/2**16
  rptop \num, shrn, \
        \a1_v, \a1_s, .4h, \a1_inc, \
        \a1_v, \a1_s, .4s, \a1_inc, \
             , 16,       , 0
  // a1 = a2/2**16
  rptop \num, shrn2, \
        \a1_v, \a1_s, .8h, \a1_inc, \
        \a2_v, \a2_s, .4s, \a2_inc, \
             , 16,       , 0
  // a1 = a1/2**2
  rptop \num, ushr, \
        \a1_v, \a1_s, .8h, \a1_inc, \
        \a1_v, \a1_s, .8h, \a1_inc, \
             , 2,        , 0
.endm

.endif  // _REDUCTIONS_H_S_
