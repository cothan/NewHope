#include "cpucycles.h"


#include "cpucycles.h"

#include "papi.h"

#include <stdio.h>
#include <stdlib.h>

inline long long cpucycles(void)
{
  return PAPI_get_virt_cyc();
}

// long long cpucycles(void)
// {
//   unsigned long long result;
//   asm volatile(".byte 15;.byte 49;shlq $32,%%rdx;orq %%rdx,%%rax"
//     : "=a" (result) ::  "%rdx");
//   return result;
// }
