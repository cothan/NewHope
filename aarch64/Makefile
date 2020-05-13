CC = cc
CFLAGS = -Wall -Wextra -g -O3 -fomit-frame-pointer -I asm/macro/ -fno-stack-protector -mstrict-align  -lpapi
NISTFLAGS = -O3 -fomit-frame-pointer -fPIC -no-pie -fno-stack-protector -mstrict-align 

HEADERS = params.h poly.h randombytes.h ntt.h reduce.h verify.h cpapke.h Makefile
SOURCES = poly.c reduce.c fips202.c verify.c cpapke.c ntt.c precomp.c asm/bitrev_vector.S \
  asm/mul_coefficients.S  asm/ntt.S  asm/poly_add.S asm/poly_pointwise.S  asm/poly_sub.S asm/KeccakP-1600-armv8a-neon.s
CCAKEM  = ccakem.c
CPAKEM  = cpakem.c

#LDFLAGS += $(shell pkg-config papi --libs)
#CFLAGS += $(shell pkg-config papi --cflags)
#CXXFLAGS += $(shell pkg-config papi --cflags)

# asm/%.o: asm/%.S Makefile
# 	$(CC) $(CFLAGS) -c -o $@ $< -I asm/macro/

all:	PQCgenKAT_cpakem512 \
			PQCgenKAT_cpakem1024 \
			PQCgenKAT_ccakem512 \
			PQCgenKAT_ccakem1024 \
			test_cpakem512 \
			test_cpakem1024 \
			test_ccakem512 \
			test_ccakem1024 \
			speed_cpakem512 \
			speed_cpakem1024 \
			speed_ccakem512 \
			speed_ccakem1024 \

PQCgenKAT_cpakem512: $(SOURCES) $(HEADERS) PQCgenKAT_kem.c rng.c rng.h
	ln -sf cpakem.h api.h
	$(CC) $(NISTFLAGS) -o $@ -DNEWHOPE_N=512 $(SOURCES) cpakem.c -I. rng.c PQCgenKAT_kem.c -lcrypto

PQCgenKAT_cpakem1024: $(SOURCES) $(HEADERS) PQCgenKAT_kem.c rng.c rng.h
	ln -sf cpakem.h api.h
	$(CC) $(NISTFLAGS) -o $@ -DNEWHOPE_N=1024 $(SOURCES) cpakem.c -I. rng.c PQCgenKAT_kem.c -lcrypto


PQCgenKAT_ccakem512: $(SOURCES) $(HEADERS) PQCgenKAT_kem.c rng.c rng.h
	ln -sf ccakem.h api.h
	$(CC) $(NISTFLAGS) -o $@ -DNEWHOPE_N=512 $(SOURCES) ccakem.c -I. rng.c PQCgenKAT_kem.c -lcrypto

PQCgenKAT_ccakem1024: $(SOURCES) $(HEADERS) PQCgenKAT_kem.c rng.c rng.h
	ln -sf ccakem.h api.h
	$(CC) $(NISTFLAGS) -o $@ -DNEWHOPE_N=1024 $(SOURCES) ccakem.c -I. rng.c PQCgenKAT_kem.c -lcrypto


test_cpakem512: $(HEADERS) $(SOURCES) $(CPAKEM) test_newhope.c randombytes.c
	ln -sf cpakem.h api.h
	$(CC) $(CFLAGS) $(SOURCES) -DNEWHOPE_N=512 $(CPAKEM) randombytes.c test_newhope.c -o $@

test_cpakem1024: $(HEADERS) $(SOURCES) $(CPAKEM) test_newhope.c randombytes.c
	ln -sf cpakem.h api.h
	$(CC) $(CFLAGS) $(SOURCES) -DNEWHOPE_N=1024 $(CPAKEM) randombytes.c test_newhope.c -o $@


test_ccakem512: $(HEADERS) $(SOURCES) $(CCAKEM) test_newhope.c randombytes.c
	ln -sf ccakem.h api.h
	$(CC) $(CFLAGS) $(SOURCES) -DNEWHOPE_N=512 $(CCAKEM) randombytes.c test_newhope.c -o $@

test_ccakem1024: $(HEADERS) $(SOURCES) $(CCAKEM) test_newhope.c randombytes.c
	ln -sf ccakem.h api.h
	$(CC) $(CFLAGS) $(SOURCES) -DNEWHOPE_N=1024 $(CCAKEM) randombytes.c test_newhope.c -o $@


speed_cpakem512: $(HEADERS) $(SOURCES) $(CPAKEM) speed.c randombytes.c cpucycles.h cpucycles.c
	ln -sf cpakem.h api.h
	$(CC) $(CFLAGS) $(SOURCES) -DNEWHOPE_N=512 $(CPAKEM) randombytes.c cpucycles.c speed.c $(LDFLAGS) -o $@

speed_cpakem1024: $(HEADERS) $(SOURCES) $(CPAKEM) speed.c randombytes.c cpucycles.h cpucycles.c
	ln -sf cpakem.h api.h
	$(CC) $(CFLAGS) $(SOURCES) -DNEWHOPE_N=1024 $(CPAKEM) randombytes.c cpucycles.c speed.c $(LDFLAGS) -o $@


speed_ccakem512: $(HEADERS) $(SOURCES) $(CCAKEM) speed.c randombytes.c cpucycles.h cpucycles.c
	ln -sf ccakem.h api.h
	$(CC) $(CFLAGS) $(SOURCES) -DNEWHOPE_N=512 $(CCAKEM) randombytes.c cpucycles.c speed.c $(LDFLAGS) -o $@

speed_ccakem1024: $(HEADERS) $(SOURCES) $(CCAKEM) speed.c randombytes.c cpucycles.h cpucycles.c
	ln -sf ccakem.h api.h
	$(CC) $(CFLAGS) $(SOURCES) -DNEWHOPE_N=1024 $(CCAKEM) randombytes.c cpucycles.c speed.c $(LDFLAGS) -o $@



.PHONY: clean

clean:
	-rm PQCgenKAT_cpakem512
	-rm PQCgenKAT_cpakem1024
	-rm PQCgenKAT_ccakem512
	-rm PQCgenKAT_ccakem1024
	-rm test_cpakem512
	-rm test_cpakem1024
	-rm test_ccakem512
	-rm test_ccakem1024
	-rm speed_cpakem512
	-rm speed_cpakem1024
	-rm speed_ccakem512
	-rm speed_ccakem1024
	-rm api.h
	-rm PQCkemKAT_*.req
	-rm PQCkemKAT_*.rsp
