#include "functions.S"
#include "push_pop.S"
#include "reductions.S"
#include "repeat.S"
#include "butterfly.S"
#include "ntt_macros.S"


.text

function ntt_asm
// void ntt(uint16_t * a, const uint16_t* omega);

  // inputs:
  // x0: (uint16_t *) a: points to beginning of array to transform,
  //      1024 elements, content will contain the transformed array
  // x1: (uint16_t *) omega: points to beginning of array of omega factors,
  //      512 elements, content will not be changed

  // occupation of regular registers:
  // x0: pointer to coefficients array, changed after reading
  // x1: pointer to omega array
  // x2: unused
  // x3: loop counter
  // x4: temporary register
  // x5-x29: unused
  // x30: link register -> contains return address

  // occupation of vector registers:
  // v0  - v11 : omegas - need to be in v0-v15
  // v12       : unused
  // v13 - v14: constants for addition and bitmasking
  // v15      : constants for multiplications by element - need to be in v0-v15
  // v16 - v31: coefficients

  // Important: for element wise multiplications the values need to be stored
  //            in vector registers in the range v0-v15.

  // safe register contents
  // x19 - x29 and v8 - v15 (bottom 64-bit -> d8-d15) if used
  // here: only v8 - v11, and v13 - v15 (include v12 to get even number)
  push d8, d9, d10, d11, d12, d13, d14, d15


  // # load constansts

  // vector v15 is used to store constants for multiplication with
  // 16bit and 32bit elements
  // v15.s[0] = q = 12289 = 1 + 2**8 * (2**4+2**5)
  mov w4, 12289
  mov v15.s[0], w4
  // v15.s[1] = q' = -q**(-1) mod R = 12287, with R = 2**18
  mov w4, 12287
  mov v15.s[1], w4
  // v15.s[2] = A = 43687
  mov w4, 43687
  mov v15.s[2], w4

  // load 3*q into each 16bit element of vector v14 for addition
  // 3*q = 36867 = 3 + 2**8 * (2**4+2**7)
  movi v14.8h, 3
  orr v14.8h, 16+128, LSL 8

  // load R-1 = 2**18-1 into each 32bit element of vector v13 as bitmask
  movi v13.4s, 3, MSL 16


  // # firt ntt block loop

  // initialize loop counter
  mov x3, 0
  // loop: for(x3=0, x3<16, x3++)
loop_ntt_block_1:

  // # load current coefficients

  // load each 16 coefficients de-interleaved into two consecutive vectors
  //x0 = x0 + 64*2 * x3
  ld2 {v16.8h,v17.8h}, [x0], 32
  ld2 {v18.8h,v19.8h}, [x0], 32
  ld2 {v20.8h,v21.8h}, [x0], 32
  ld2 {v22.8h,v23.8h}, [x0], 32
  //x0 = x0 + 64*2 * (x3+1)
  // total of 64 coefficients loaded

  // # first layer - inputs are 14 bits

  // load corresponding 8 omega factors
  //x1 = x1 + 32*2 * x3
  ld1 {v0.8h, v1.8h, v2.8h, v3.8h}, [x1]
  // total of 32 omegas loaded

  // data is already ready to be processed

  rptNtt_odd_layer 4,\
                    v,  16,  2,  \
                    v,  17,  2,  \
                    v,  17,  2,  \
                    v,  24,  1,  \
                    v,  28,  1,  \
                    <v0.4h,v1.4h,v2.4h,v3.4h>, \
                    <v0.8h,v1.8h,v2.8h,v3.8h>

  // # second layer - inputs 15bits

  // load the corresponding omegas
  //x1 = x1 + 32*2 * x3
  sub x1, x1, x3, LSL 5  // x1 -= x3<<5 = x3 * 2**5 = x3 * 16*2
  //x1 = x1 + 16*2 * x3
  ld1 {v0.8h, v1.8h}, [x1]
  // widen omegas to 32bits
  uxtl  v4.4s,  v0.4h
  uxtl2 v6.4s,  v0.8h
  uxtl  v8.4s,  v1.4h
  uxtl2 v10.4s, v1.8h
  // douplicate omega elements
  zip2 v5.4s,  v4.4s,  v4.4s
  zip1 v4.4s,  v4.4s,  v4.4s
  zip2 v7.4s,  v6.4s,  v6.4s
  zip1 v6.4s,  v6.4s,  v6.4s
  zip2 v9.4s,  v8.4s,  v8.4s
  zip1 v8.4s,  v8.4s,  v8.4s
  zip2 v11.4s, v10.4s, v10.4s
  zip1 v10.4s, v10.4s, v10.4s


  // prepare coefficients -> transpose element wise
  rptop 4, transposeElements, \
                v, 16, .8h, 2, \
                v, 24, .8h, 1, \
                v, 17, .8h, 2

  rptNtt_even_layer 4,\
                    v,      16,      2,  \
                    v,      17,      2,  \
                    v,      24,      1,  \
                    v,      28,      1,  \
                    v,      17,      2,  \
                    v,      24,      1,  \
                    <v4.4s,v6.4s,v8.4s,v10.4s>,   \
                    <v5.4s,v7.4s,v9.4s,v11.4s>


  // # third layer - inputs are 14bit again

  // load the corresponding omegas
  //x1 = x1 + 16*2 * x3
  sub x1, x1, x3, LSL 4  // x1 -= x3<<4 = x3 * 2**4 = x3 * 8*2
  //x1 = x1 + 8*2 * x3
  ld1 {v0.8h}, [x1]


  // prepare coefficients -> transpose two-element wise
  rptop 4, transposeElements, \
                v, 16, .4s, 2, \
                v, 24, .4s, 2, \
                v, 17, .4s, 2

  rptNtt_odd_layer  4,\
                    v,  16,  2,  \
                    v,  17,  2,  \
                    v,  24,  2,  \
                    v,  25,  2,  \
                    v,  24,  2,  \
                    <v0.h[0],v0.h[2],v0.h[4],v0.h[6]>,  \
                    <v0.h[1],v0.h[3],v0.h[5],v0.h[7]>


  // # forth layer - inputs are 15 bit

  // load the corresponding omegas
  //x1 = x1 + 8*2 * x3
  sub x1, x1, x3, LSL 3  // x1 -= x3<<3 = x3 * 2**3 = x3 * 4*2
  //x1 = x1 + 4*2 * x3
  ld1 {v0.8h}, [x1]
  // widen omegas to 32bits
  uxtl  v0.4s, v0.4h


  // prepare coefficients -> transpose four-element wise
  rptop 4, transposeElements, \
                v, 16, .2d, 2, \
                v, 24, .2d, 1, \
                v, 17, .2d, 2

  rptNtt_even_layer 4,\
                    v,      16,      2,      \
                    v,      17,      2,  \
                    v,      24,      1,   \
                    v,      28,      1,     \
                    v,      17,      2,     \
                    v,      24,      1,     \
                    <v0.4s[0],v0.4s[1],v0.4s[2],v0.4s[3]>,   \
                    <v0.4s[0],v0.4s[1],v0.4s[2],v0.4s[3]>


  // store coefficients
  //x0 = x0 + 64*2 * (x3+1)
  sub x0, x0, 64*2
  st1 {v16.8h,v17.8h}, [x0], 32
  st1 {v18.8h,v19.8h}, [x0], 32
  st1 {v20.8h,v21.8h}, [x0], 32
  st1 {v22.8h,v23.8h}, [x0], 32
  //x0 = x0 + 64*2 * (x3+1)

  // increment loop counter and omega pointer
  //x1 = x1 + 4*2 * x3_old
  sub x1, x1, x3, LSL 3  // x1 -= x3<<3 = x3 * 2**3 = x3 * 4*2
  add x3, x3, 1
  add x1, x1, x3, LSL 6  // x1 += x3<<6 = x3 * 2**6 = x3 * 32*2
  //x1 = x1 + 32*2 * x3_new
  // repeat loop until x3 is 16
  tbz x3, 4, loop_ntt_block_1
  // end firt ntt block loop


  // reset x0 & x1
  //x0 = x0 + 64*2 * x3, with x3=16
  sub x0, x0, 64*2*16
  //x0 = x0

  //x1 = x1 + 32*2 * x3, with x3=16
  sub x1, x1, 32*2*16
  //x1 = x1

  // load corresponding omega factors for layer 5 onwards
  //x1 = x1
  ld1 {v0.8h, v1.8h, v2.8h, v3.8h}, [x1], 64
  //x1 = x1 + 32*2
  // total of 32 omegas loaded


  // prepare omegas for odd layers
  // widen omegas to 32bits
  uxtl  v4.4s,  v0.4h
  uxtl2 v6.4s,  v0.8h
  uxtl  v8.4s,  v1.4h
  uxtl2 v10.4s, v1.8h
  // douplicate omega elements
  zip2 v5.4s,  v4.4s,  v4.4s
  zip1 v4.4s,  v4.4s,  v4.4s
  zip2 v7.4s,  v6.4s,  v6.4s
  zip1 v6.4s,  v6.4s,  v6.4s
  zip2 v9.4s,  v8.4s,  v8.4s
  zip1 v8.4s,  v8.4s,  v8.4s
  zip2 v11.4s, v10.4s, v10.4s
  zip1 v10.4s, v10.4s, v10.4s


  // # second ntt block loop
  // store distance in register
  mov x4, 16*2
  // initialize loop counter
  mov x3, 0
  // loop: for(x3=0, x3<16, x3++)
loop_ntt_block_2:

  // # load current coefficients

  //x0 = x0 + 2*x3
  // load each 16 coefficients de-interleaved into two consecutive vectors
  // with a distance of 16 elements each (distance stored in x4)
  //loadDistantElementsInterleaved vdst1, vdst2, xsrc, xdistance
  loadDistantElementsInterleaved v16, v17, x0, x4
  loadDistantElementsInterleaved v18, v19, x0, x4
  loadDistantElementsInterleaved v20, v21, x0, x4
  loadDistantElementsInterleaved v22, v23, x0, x4
  //x0 = x0 + 2*x4 + 16*2*16*4
  // total of 64 coefficients loaded


  // # fifth layer - inputs are 14 bits

  // data is already ready to be processed

  rptNtt_odd_layer  4,\
                    v,  16,  2,  \
                    v,  17,  2,  \
                    v,  17,  2,  \
                    v,  25,  2,  \
                    v,  24,  2,  \
                    <v0.4h,v1.4h,v2.4h,v3.4h>,\
                    <v0.8h,v1.8h,v2.8h,v3.8h>


  // # sixth layer - inputs 15bits

  // prepare coefficients -> transpose element wise
  rptop 4, transposeElements, \
                v, 16, .8h, 2, \
                v, 24, .8h, 1, \
                v, 17, .8h, 2

  rptNtt_even_layer 4,\
                          v,      16,      2,      \
                          v,      17,      2,  \
                          v,      24,      1,   \
                          v,      28,      1,     \
                          v,      17,      2,     \
                          v,      24,      1,     \
                          <v4.4s,v6.4s,v8.4s,v10.4s>,   \
                          <v5.4s,v7.4s,v9.4s,v11.4s>


  // # seventh layer - inputs 14bits

  // prepare coefficients -> transpose two-element wise
  rptop 4, transposeElements, \
                v, 16, .4s, 2, \
                v, 24, .4s, 2, \
                v, 17, .4s, 2

  rptNtt_odd_layer  4,\
                    v,  16,  2,  \
                    v,  17,  2,  \
                    v,  24,  2,  \
                    v,  25,  2,  \
                    v,  24,  2,  \
                    <v0.h[0],v0.h[2],v0.h[4],v0.h[6]>,  \
                    <v0.h[1],v0.h[3],v0.h[5],v0.h[7]>


  // # eighth layer - inputs 15bits

  // prepare coefficients -> transpose four-element wise
  rptop 4, transposeElements, \
                v, 16, .2d, 2, \
                v, 24, .2d, 1, \
                v, 17, .2d, 2

  rptNtt_even_layer 4,\
                    v,      16,      2, \
                    v,      17,      2, \
                    v,      24,      1, \
                    v,      28,      1, \
                    v,      17,      2, \
                    v,      24,      1, \
                    <v4.4s[0],v4.4s[2],v5.4s[0],v5.4s[2]>, \
                    <v4.4s[0],v4.4s[2],v5.4s[0],v5.4s[2]>


  // # nineth layer - inputs 14bits

  // swap v17&v18 and v21&v22
  mov v24.16b, v17.16b
  mov v25.16b, v21.16b
  mov v17.16b, v18.16b
  mov v21.16b, v22.16b
  mov v18.16b, v24.16b
  mov v22.16b, v25.16b

  rptNtt_odd_layer  4,\
                    v,  16,  2,  \
                    v,  17,  2,  \
                    v,  17,  2,  \
                    v,  25,  2,  \
                    v,  24,  2,  \
                    <v0.h[0],v0.h[0],v0.h[1],v0.h[1]>,\
                    <v0.h[0],v0.h[0],v0.h[1],v0.h[1]>

  // swap v17&v18 and v21&v22
  mov v24.16b, v17.16b
  mov v25.16b, v21.16b
  mov v17.16b, v18.16b
  mov v21.16b, v22.16b
  mov v18.16b, v24.16b
  mov v22.16b, v25.16b


  // # tenth layer - inputs 15bits
  rptNtt_even_layer 4,\
                          v,      16,      1,  \
                          v,      20,      1,  \
                          v,      20,      1,  \
                          v,      28,      1,  \
                          v,      24,      1,  \
                          v,      24,      1,  \
                          <v4.4s[0],v4.4s[0],v4.4s[0],v4.4s[0]>,   \
                          <v4.4s[0],v4.4s[0],v4.4s[0],v4.4s[0]>

  // # store coefficients

  //x0 = x0 + 2*x3 + 16*2*16*4
  sub x0, x0, (16*2*16*4)
  //x0 = x0 + 2*x3
  storeDistantElements v16, v17, x0, x4
  storeDistantElements v18, v19, x0, x4
  storeDistantElements v20, v21, x0, x4
  storeDistantElements v22, v23, x0, x4
  //x0 = x0 + 2*x3 + 16*2*16*4


  // increment loop counter and coefficients pointer
  add x3, x3, 1
  //x0 = x0 + 2*x3_old + 16*2*16*4
  sub x0, x0, (16*2*16*4 - 2*1)  // x0 = x0 - (16*2*16*4) + (2*1)
  //x0 = x0 + 2*x3_new
  // repeat loop until x3 is 16
  tbz x3, 4, loop_ntt_block_2
  // end second ntt block loop

  // restore register contents
  pop d8, d9, d10, d11, d12, d13, d14, d15

  // return
  ret

endfunc ntt_asm
