#include "functions.S"
#include "push_pop.S"
#include "reductions.S"
#include "repeat.S"

.text

function mul_coefficients_asm
// void mul_coefficients(uint16_t* poly, const uint16_t* factors);

  // inputs:
  // x0: (uint16_t *) poly: points to beginning of in-out array, 1024 elements
  // x1: (uint16_t *) factors: points to beginning of factors array,
  //                  1024 elements, content will not be changed

  // occupation of regular registers:
  // x0: pointer to array poly
  // x1: pointer to input array factors
  // x3: loop counter
  // x4: temporary register
  // x5-x29: unused
  // x30: link register -> contains return address

  // occupation of vector registers:
  // v0  - v7 : output poly
  // v8  - v12: unused
  // v13      : constants for addition/substraction
  // v14      : unused
  // v15      : constants for multiplications by element - need to be in v0-v15
  // v16 - v23: input poly
  // v24 - v31: input factors

  // Important: for element wise multiplications the values need to be stored
  //            in vector registers in the range v0-v15.


  // safe register contents
  // x19 - x29 and v8 - v15 (bottom 64-bit -> d8-d15) if used
  // here: only v13, v15 used
  push d13, d15


  // vector v15 is used to store constants for multiplication with
  // 16bit and 32bit elements
  // v15.s[0] = q = 12289 = 1 + 2**8 * (2**4+2**5)
  mov w4, 12289
  mov v15.s[0], w4
  // v0.s[1] = q' = -q**(-1) mod R = 12287, with R = 2**18
  mov w4, 12287
  mov v15.s[1], w4

  // load R-1 = 2**18-1 into each 32bit element of vector v13 as bitmask
  movi v13.4s, 3, MSL 16



  // # loop over coefficients

  // initialize loop counter
  mov x3, 0
  // loop: for(x3=0, x3<16, x3++)
  loop_mul_coefficients:

    // # load current input coefficients

    // load input a in v16-23
    //x0 = x0_orig + 8*2*4*2 * x3
    ld1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x0], 8*2*4
    ld1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x0], 8*2*4
    //x0 = x0_orig + 8*2*4*2 * (x3+1)
    // total of 64 coefficients of a loaded

    // load input b in v24-v31
    //x1 = x1_orig + 8*2*4*2 * x3
    ld1 {v24.8h, v25.8h, v26.8h, v27.8h}, [x1], 8*2*4
    ld1 {v28.8h, v29.8h, v30.8h, v31.8h}, [x1], 8*2*4
    //x1 = x1_orig + 8*2*4*2 * (x3+1)
    // total of 64 coefficients of b loaded

    // inputs 2 * 14bit -> outputs 28bit
    // -> widen to 32bit in multiplication


    // multiply the lower 4 elements each vector to v0-v7
    // r1 = a * b [lower elements]
    rptop 8, umull, \
          v, 0,  .4s, 1, \
          v, 16, .4h, 1, \
          v, 24, .4h, 1

    // multiply the upper 4 elements each vector to v16-v23
    // r2 = a * b [upper elements]
    rptop 8, umull2, \
          v, 16, .4s, 1, \
          v, 16, .8h, 1, \
          v, 24, .8h, 1


    // # reduction
    rptMontgomery32 8, \
                    v,  0,  1,  \
                    v,  16, 1,  \
                    v,  24, 1,  \



    // # store coefficients to poly

    //x0 = x0_orig + 8*2*4*2 * (x3+1)
    sub x0, x0, (8*2*4*2)
    //x0 = x0_orig + 8*2*4*2 * x3
    st1 {v0.8h, v1.8h, v2.8h, v3.8h}, [x0], 8*2*4
    st1 {v4.8h, v5.8h, v6.8h, v7.8h}, [x0], 8*2*4
    //x0 = x0_orig + 8*2*4*2 * (x3+1)

    // increment loop counter
    add x3, x3, 1

  // repeat loop until x3 is 16
  tbz x3, 4, loop_mul_coefficients
  // end loop over coefficients

  // restore register contents
  pop d13, d15

  // return
  ret

endfunc mul_coefficients_asm
