#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <inttypes.h>
#include <time.h>

#define SCHRAUDOLPH_A 12102203.0f

static const int EXCLUDE_POS = 0;

/* 0 = plain Schraudolph; 1 = halved variant exp(f/2) * exp(f/2). */
static const int USE_HALVED = 1;

FILE *fp;

void print_and_store(char *s) {
	printf("%s", s);
	fprintf(fp, "%s", s);
	fflush(stdout);
	fflush(fp);
}

float bits_to_float(uint32_t bits) {
	float f;
	memcpy(&f, &bits, sizeof(f));
	return f;
}

float schraudolph_exp_standard(int32_t magic_constant, float f) {
	union {
		int32_t i;
		float   f;
	} u;
	u.i = (int32_t)(SCHRAUDOLPH_A * f) + magic_constant;
	return u.f;
}

float schraudolph_exp(int32_t magic_constant, float f) {
	if (USE_HALVED) {
		return schraudolph_exp_standard(magic_constant, f / 2.0) * schraudolph_exp_standard(magic_constant, f / 2.0);
	}
	return schraudolph_exp_standard(magic_constant, f);
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
	EXCLUDE_POS=0: any normal fp32 in [-87.0, 88.0]
	EXCLUDE_POS=1: any normal fp32 in [-87.0,  0.0)
   Uniform over fp32 bit patterns (mantissa and exponent-field each drawn
   uniformly), matching the SV accuracy testbenches, rather than uniform over
   the reals -- the latter concentrates almost all mass in the few largest
   exponent bins and shifts the RMSRE-optimal magic toward large |x|.
   Exclude denormalized numbers: the exponent field is drawn from {1,...,133}
   so field 0 (subnormals/zero) never occurs. The top bin (field 133,
   magnitudes in [64,128)) is capped to keep the admitted value-set in
   [-87,88]: positive up to 88.0 (mantissa 0x300000), negative up to 87.0
   (mantissa 0x2E0000); larger mantissas in that bin are redrawn. */
float rand_fp(void) {
	const uint32_t MAN_LIM_POS = 0x300000u;   /* 88.0 in exp field 133 */
	const uint32_t MAN_LIM_NEG = 0x2E0000u;   /* 87.0 in exp field 133 */
	for (;;) {
		uint32_t r         = rand_u32();
		uint32_t man_field = r & 0x7FFFFFu;
		uint32_t sign      = EXCLUDE_POS ? 1u : ((r >> 23) & 1u);
		uint32_t exp_field = 1u + (rand_u32() % 133u);
		if (exp_field == 133u) {
			uint32_t lim = sign ? MAN_LIM_NEG : MAN_LIM_POS;
			if (man_field > lim) continue;
		}
		return bits_to_float((sign << 31) | (exp_field << 23) | man_field);
	}
}

int main(int argc, char **argv) {
	unsigned seed = (argc > 1) ? (unsigned)strtoul(argv[1], NULL, 10)
	                           : (unsigned)time(NULL);
	/* xorshift32 cannot be seeded with 0 — it would lock to zero forever. */
	xs_state = seed ? seed : 0x9E3779B9u;

	fp = fopen("optimal_magic_coarse_sweep_schraudolph_results.csv", "w");
	char seed_buf[64];
	snprintf(seed_buf, sizeof(seed_buf), "# seed = %u\n", seed);
	print_and_store(seed_buf);
	print_and_store("magic_constant, RMSRE\n");

	/* Sweep range. Under bit-pattern-uniform sampling the optimum sits near
	   c = 1065280000 for both the plain and the halved variant (cf.
	   determine_optimal_magic_schraudolph.c). Sweep a symmetric window around
	   it so the curve shape is visible. */
	const int32_t magic_first = 1064530000;
	const int32_t magic_last  = 1066030000;
	const int32_t magic_step  = 1000;

	/* Parameters for sampling only */
	const int NUM_SAMPLES = 10000;
	float samples[NUM_SAMPLES];
	for (int i = 0; i < NUM_SAMPLES; i++) {
		samples[i] = rand_fp();
	}

	int32_t optimal_magic_constant = 0;
	double  optimal_rmsre          = INFINITY;

	for (int32_t magic_constant = magic_first;
	     magic_constant <= magic_last;
	     magic_constant += magic_step) {

		double   sum_sq = 0.0;
		uint64_t count  = 0;

		for (int i = 0; i < NUM_SAMPLES; i++) {
			float  x   = samples[i];
			float  sa  = schraudolph_exp(magic_constant, x);
			double ref = exp((double)x);
			if (!isfinite(ref) || ref == 0.0) continue;

			double rel_err = fabs((double)sa - ref) / ref;
			sum_sq += rel_err * rel_err;
			count  += 1;
		}

		double rmsre = (count > 0) ? sqrt(sum_sq / (double)count) : INFINITY;
		if (rmsre < optimal_rmsre) {
			optimal_magic_constant = magic_constant;
			optimal_rmsre          = rmsre;
		}
		fprintf(fp, "%" PRId32 ", %.10e\n", magic_constant, rmsre);
	}

	char buf[160];
	snprintf(buf, sizeof(buf),
	         "optimal magic constant: %" PRId32 "  (RMSRE = %.10e)\n",
	         optimal_magic_constant, optimal_rmsre);
	print_and_store(buf);

	fclose(fp);
	return 0;
}
