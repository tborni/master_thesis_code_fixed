#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

static const float   SCHRAUDOLPH_A = 12102203.0f;
static const int32_t SCHRAUDOLPH_D = 1064866360;

static const int EXCLUDE_POS = 0;

float schraudolph_exp(float f) {
	union {
		int32_t i;
		float   f;
	} u;
	u.i = (int32_t)(SCHRAUDOLPH_A * f) + SCHRAUDOLPH_D;
	return u.f;
}

float schraudolph_exp_half(float f) {
	return schraudolph_exp(f / 2.0) * schraudolph_exp(f / 2.0);
}

/* xorshift32: produces all 32 bits uniformly. glibc rand() only delivers
   31 bits and combining two draws still leaves a biased top bit, which
   skewed the previous sampler away from the full-sweep distribution. */
static uint32_t xs_state = 0;

uint32_t rand_u32(void) {
	uint32_t x = xs_state;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	xs_state = x;
	return x;
}

/* Random fp sample generator
	EXCLUDE_POS=0: any normal fp32 (or +-0) in [-87.0, 88.0]
	EXCLUDE_POS=1: any normal fp32 (or +-0) in [-87.0,  0.0]
   Sampling is uniform over reals not fp32 bit patterns (each representable value is not equally likely)
   Exclude denormalized numbers */
float rand_fp(void) {
	const double lo = -87.0;
	const double hi = EXCLUDE_POS ? 0.0 : 88.0;
	for (;;) {
		double   u         = (double)rand_u32() / 4294967296.0;
		float    s         = (float)(lo + (hi - lo) * u);
		uint32_t bits      = (union { float f; uint32_t u; }){.f = s}.u;
		uint32_t exp_field = (bits >> 23) & 0xFFu;
		uint32_t man_field =  bits        & 0x7FFFFFu;
		if (exp_field != 0 || man_field == 0) return s;
	}
}

int main(int argc, char **argv) {
	unsigned seed = (argc > 1) ? (unsigned)strtoul(argv[1], NULL, 10)
	                           : (unsigned)time(NULL);
	/* xorshift32 cannot be seeded with 0 — it would lock to zero forever. */
	xs_state = seed ? seed : 0x9E3779B9u;

	double   sum_sq      = 0.0;
	uint64_t count       = 0;
	double   max_rel_err = 0.0;
	float    worst_x     = 0.0f;
	float    worst_sa    = 0.0f;
	double   worst_ref   = 0.0;

	const int NUM_SAMPLES = 1000000;
	for (int i = 0; i < NUM_SAMPLES; i++) {
		float  x   = rand_fp();
		float  sa  = schraudolph_exp(x);
		double ref = exp((double)x);
		if (!isfinite(ref) || ref == 0.0) continue;

		double rel_err = fabs((double)sa - ref) / ref;
		sum_sq += rel_err * rel_err;
		count  += 1;
		if (rel_err > max_rel_err) {
			max_rel_err = rel_err;
			worst_x     = x;
			worst_sa    = sa;
			worst_ref   = ref;
		}
	}

	double rmsre = (count > 0) ? sqrt(sum_sq / (double)count) : 0.0;

	printf("seed                               : %u\n", seed);
	printf("samples (finite, nonzero reference): %llu\n",
	       (unsigned long long)count);
	printf("RMSRE                              : %.10e\n", rmsre);
	printf("max relative error                 : %.10e\n", max_rel_err);
	printf("  at x                             : %.9g (0x%08x)\n",
	       worst_x, (unsigned)((union { float f; uint32_t u; }){.f = worst_x}.u));
	printf("  schraudolph_exp(x)               : %.9g\n", worst_sa);
	printf("  reference_exp(x)                 : %.17g\n", worst_ref);

	return 0;
}
