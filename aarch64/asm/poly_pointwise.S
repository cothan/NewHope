#include "functions.S"
#include "push_pop.S"
#include "reductions.S"
#include "repeat.S"

.text

function poly_mul_pointwise_asm
// void poly_pointwise(poly *r, const poly *a, const poly *b);

  // inputs:
  // x0: (uint16_t *) r: points to beginning of output array, 1024 elements
  // x1: (uint16_t *) a: points to beginning of input array a, 1024 elements,
  //                     content will not be changed
  // x2: (uint16_t *) b: points to beginning of input array b, 1024 elements,
  //                     content will not be changed

  // occupation of regular registers:
  // x0: pointer to output array r
  // x1: pointer to input array a
  // x2: pointer to input array b
  // x3: loop counter and temporary register before loop
  // x4-x29: unused
  // x30: link register -> contains return address

  // occupation of vector registers:
  // v0       : constants for multiplications by element - need to be in v0-v15
  // v1  - v15: unused
  // v16 - v19: input a
  // v20 - v23: input b
  // v24 - v27: output r
  // v28 - v31: intermediate values

  // Important: for element wise multiplications the values need to be stored
  //            in vector registers in the range v0-v15.


  // safe register contents
  // x19 - x29 and v8 - v15 (bottom 64-bit -> d8-d15) if used
  // here: none


  // vector v0 is used to store constants for multiplication with
  // 16bit and 32bit elements
  // v0.s[0] = v0.h[0] = q = 12,289 = 1 + 2**8 * (2**4+2**5)
  mov w3, 12289
  mov v0.s[0], w3
  // v0.s[1] = v0.h[2] = A = 2,863,078,533
  ldr w3, =2863078533
  mov v0.s[1], w3


  // # loop over coefficients

  // initialize loop counter
  mov x3, 0
  // loop: for(x3=0, x3<32, x3++)
  loop_poly_pointwise:

    // # load current input coefficients

    // load input a in v16-19
    //x1 = x1_orig + 8*2*4 * x3
    ld1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x1], 8*2*4
    //x1 = x1_orig + 8*2*4 * (x3+1)
    // total of 32 coefficients of a loaded

    // load input b in v20-v23
    //x2 = x2_orig + 8*2*4 * x3
    ld1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x2], 8*2*4
    //x2 = x2_orig + 8*2*4 * (x3+1)
    // total of 32 coefficients of b loaded

    // inputs 2 * 16bit -> outputs 32bit
    // -> widen to 32bit in multiplication

    // multiply the lower 4 elements each vector to v24-v27
    // r1 = a * b [lower elements]
    rptop 4, umull, \
          v, 24,  .4s, 1, \
          v, 16, .4h, 1, \
          v, 20, .4h, 1

    // multiply the upper 4 elements each vector to v28-v31
    // r2 = a * b [upper elements]
    rptop 4, umull2, \
          v, 28, .4s, 1, \
          v, 16, .8h, 1, \
          v, 20, .8h, 1


    // # reduction
    rptBarrett32 4, \
                v, 24, 1, \
                v, 28, 1, \
                v, 16, 1, \
                v, 20, 1, \
                v, 0, .s[0], \
                v, 0, .s[1]



    // # store coefficients to r
    //x0 = x0_orig + 8*2*4*2 * x3
    st1 {v24.8h, v25.8h, v26.8h, v27.8h}, [x0], 8*2*4
    //x0 = x0_orig + 8*2*4*2 * (x3+1)

    // increment loop counter
    add x3, x3, 1

  // repeat loop until x3 is 32
  tbz x3, 5, loop_poly_pointwise
  // end loop over coefficients

  // return
  ret

endfunc poly_mul_pointwise_asm
