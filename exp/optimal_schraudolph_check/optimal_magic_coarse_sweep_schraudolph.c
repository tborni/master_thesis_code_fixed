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

	fp = fopen("optimal_magic_coarse_sweep_schraudolph_results.csv", "w");
	char seed_buf[64];
	snprintf(seed_buf, sizeof(seed_buf), "# seed = %u\n", seed);
	print_and_store(seed_buf);
	print_and_store("magic_constant, RMSRE\n");

	/* Sweep range. Under real-uniform sampling the optimum sits near
	   c = 1064866360 (per determine_optimal_magic_schraudolph.c). Sweep a
	   symmetric window around it so the curve shape is visible. */
	const int32_t magic_first = 1064100000;
	const int32_t magic_last  = 1065600000;
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
