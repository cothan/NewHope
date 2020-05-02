#include "functions.S"
#include "push_pop.S"
#include "reductions.S"
#include "repeat.S"

.text

function poly_add_asm
//void poly_add(poly *r, const poly *a, const poly *b);

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
  // v0       : constants for addition/substraction
  // v1  - v15: unused
  // v16 - v23: input a and output r
  // v24 - v31: input b

  // Important: for element wise multiplications the values need to be stored
  //            in vector registers in the range v0-v15.


  // safe register contents
  // x19 - x29 and v8 - v15 (bottom 64-bit -> d8-d15) if used
  // here: none


  // load q into each 16bit element of vector v0
  // q = 12289 = 1 + 2**8 * (2**4+2**5)
  movi v0.8h, 1
  orr v0.8h, 32+16, LSL 8


  // # loop over coefficients

  // initialize loop counter
  mov x3, 0
  // loop: for(x3=0, x3<16, x3++)
  loop_poly_add:

    // # load current input coefficients

    // load input a in v16-23
    //x1 = x1_orig + 8*2*4*2 * x3
    ld1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x1], 8*2*4
    ld1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x1], 8*2*4
    //x1 = x1_orig + 8*2*4*2 * (x3+1)
    // total of 64 coefficients of a loaded

    // load input b in v24-v31
    //x2 = x2_orig + 8*2*4*2 * x3
    ld1 {v24.8h, v25.8h, v26.8h, v27.8h}, [x2], 8*2*4
    ld1 {v28.8h, v29.8h, v30.8h, v31.8h}, [x2], 8*2*4
    //x2 = x2_orig + 8*2*4*2 * (x3+1)
    // total of 64 coefficients of b loaded

    // inputs 14bit -> outputs 15bit

    // add a + b
    // r in vectors v16-v23
    // a in vectors v16-v23
    // b in vectors v24-v31
    // r = a + b
    rptop 8, add, \
          v, 16, .8h, 1, \
          v, 16, .8h, 1, \
          v, 24, .8h, 1


    // # reduction considering pipelining:
    // r in vectors v16-v23
    // t in vectors v24-31
    // vq16 in vector v0

    rptFullRed2q  8, \
                  v, 16, 1, \
                  v, 24, 1, \
                  v, 0
    rptFullRed2q  8, \
                  v, 16, 1, \
                  v, 24, 1, \
                  v, 0


    // # store coefficients to r
    //x0 = x0_orig + 8*2*4*2 * x3
    st1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x0], 8*2*4
    st1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x0], 8*2*4
    //x0 = x0_orig + 8*2*4*2 * (x3+1)

    // increment loop counter
    add x3, x3, 1

  // repeat loop until x3 is 16
  tbz x3, 4, loop_poly_add
  // end loop over coefficients

  // return
  ret

endfunc poly_add_asm
