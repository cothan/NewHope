#include "functions.S"
#include "push_pop.S"
#include "reductions.S"
#include "repeat.S"

.text

function poly_getnoise_asm
// void poly_getnoise(poly *r, unsigned char *seed, unsigned char nonce);

  // inputs:
  // x0: (uint16_t *) r: points to beginning of output array, 1024 elements
  // x1: (uint16_t *) seed: points to beginning of seed
  // x2: (uint16_t *) nonce: nonce used for RNG

  // occupation of regular registers:
  // x0: pointer to output array r
  // x1: pointer to input array seed, later to buffer with random data
  // x2: pointer to input nonce, later temporary register
  // x3: loop counter and temporary register before loop
  // x4: temporary register
  // x5-x29: unused
  // x30: link register -> contains return address

  // occupation of vector registers:
  // v0       : constants for addition
  // v1  - v15: unused
  // v16 - v23: random values and output
  // v24 - v31: random values

  // Important: for element wise multiplications the values need to be stored
  //            in vector registers in the range v0-v15.

  // safe register contents
  // x19 - x29 and v8 - v15 (bottom 64-bit -> d8-d15) if used
  // here: none


  // # calling chacha20

  // save address of output r and link register to stack
  push x0,  x30

  // prepare nonce
  ldr x3, =nonce
  strb w2, [x3]

  // prepare input variables for crypto_stream_chacha20
  //crypto_stream_chacha20((unsigned char *)buf,4*PARAM_N,n,seed);
  mov x2, x3      // nonce
  mov x3, x1      // seed
  ldr x0, =buffer // buffer
  mov x1, 4*1024  // len

  // call crypto_stream_chacha20
  ldr x4, =crypto_stream_chacha20
  blr x4

  // load address of buffer to x1 (assuming chacha20 could have altered x0)
  ldr x1, =buffer

  // restore address of output r and link register from stack
  pop x0, x30

  // prepare value of q = 12289 in w2 and each 16-bit element of v0
  mov w2, 12289
  dup v0.8h, w2

  // # loop over coefficients

  // initialize loop counter
  mov x3, 0
  // loop: for(x3=0, x3<16, x3++)
  loop_poly_getnoise:

    // load random values form buffer
    // using ld4 to be 1-to-1 compatible to the reference implementation
    //x1 = x1_orig + 16*4*4 * x3
    ld4 {v16.16b, v17.16b, v18.16b, v19.16b}, [x1], 16*4
    ld4 {v20.16b, v21.16b, v22.16b, v23.16b}, [x1], 16*4
    ld4 {v24.16b, v25.16b, v26.16b, v27.16b}, [x1], 16*4
    ld4 {v28.16b, v29.16b, v30.16b, v31.16b}, [x1], 16*4
    //x1 = x1_orig + 16*4*4 * (x3+1)

    // sum up each 8 bits
    rptuop  16, cnt, \
            v, 16, .16b, 1, \
            v, 16, .16b, 1

    rptop 8, add, \
          v, 16, .16b, 1, \
          v, 16, .16b, 2, \
          v, 17, .16b, 2

    rptop 4, sub, \
          v, 16, .16b, 2, \
          v, 16, .16b, 2, \
          v, 17, .16b, 2

    rptop 4, saddw2, \
          v, 17, .8h,   2, \
          v, 0,  .8h,   0, \
          v, 16, .16b,  2

    rptop 4, saddw, \
          v, 16, .8h,   2, \
          v, 0,  .8h,   0, \
          v, 16, .8b,   2


    // # store coefficients to r

    //x0 = x0_orig + 8*2*4*2 * x3
    st1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x0], 8*2*4
    st1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x0], 8*2*4
    //x0 = x0_orig + 8*2*4*2 * (x3+1)

    // increment loop counter
    add x3, x3, 1

  // repeat loop until x3 is 16
  tbz x3, 4, loop_poly_getnoise
  // end loop over coefficients

  // return
  ret

  endfunc poly_getnoise_asm

  // reserve space for variables
  .bss
  // create buffer for random bytes
buffer:  .space 4*1024

  // create nonce
nonce:  .space 8
