#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <inttypes.h>
#include <time.h>

/* fp32 multiplicative constant for the Schraudolph approximation. */
static const float SCHRAUDOLPH_A = 12102203.0f;

static const int EXCLUDE_POS = 0;

FILE *fp;

void print_and_store(char *s) {
	printf("%s", s);
	fprintf(fp, "%s", s);
	fflush(stdout);
	fflush(fp);
}

/* Matches schraudolph_exp_large_sweep.c bit-for-bit: fp32 mul, cast to int32,
   then integer add of the magic bias — the standard Schraudolph formulation. */
float schraudolph_exp(int32_t magic, float f) {
	union {
		int32_t i;
		float   f;
	} u;
	u.i = (int32_t)(SCHRAUDOLPH_A * f) + magic;
	return u.f;
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

	fp = fopen("determine_optimal_magic_schraudolph.csv", "w");
	char seed_buf[64];
	snprintf(seed_buf, sizeof(seed_buf), "# seed = %u\n", seed);
	print_and_store(seed_buf);
	print_and_store("optimal_magic_constant, optimal_RMSRE\n");

	/* Pre-generate a single fixed sample set so every magic constant is
	   evaluated on identical inputs (otherwise RMSRE noise dominates the
	   convexity-driven narrowing). Also pre-compute the fp64 reference
	   exp(x) once per sample — it does not depend on the magic constant. */
	const int NUM_SAMPLES_RAW = 20000000;
	float  *samples = malloc(NUM_SAMPLES_RAW * sizeof(float));
	double *refs    = malloc(NUM_SAMPLES_RAW * sizeof(double));
	int     num_valid = 0;
	for (int i = 0; i < NUM_SAMPLES_RAW; i++) {
		float x = rand_fp();
		double r = exp((double)x);
		if (!isfinite(r) || r == 0.0) continue;
		samples[num_valid] = x;
		refs[num_valid]    = r;
		num_valid++;
	}

	/* Search over int32 magic constants directly — every integer is a valid
	   candidate for the standard Schraudolph integer-add formulation. The
	   window is widened past the bit-pattern-uniform optimum (~1065292384)
	   because real-uniform sampling reweights toward large |x| and shifts
	   the minimum; the first pass must bracket the new optimum. */
	int32_t magic_min = 1063500000;
	int32_t magic_max = 1066500000;

	int32_t step = 65536;

	while (step > 0) {
		int32_t optimal_magic = 0;
		double  optimal_rmsre = INFINITY;

		/* Spend most samples only on the final, highest-resolution pass. */
		int num_samples = step > 4 ? num_valid / 100 : num_valid;

		for (int32_t m = magic_min; m <= magic_max; m += step) {
			double   sum_sq = 0.0;
			uint64_t count  = 0;

			for (int i = 0; i < num_samples; i++) {
				float  x   = samples[i];
				float  sa  = schraudolph_exp(m, x);
				double ref = refs[i];

				double rel_err = fabs((double)sa - ref) / ref;
				sum_sq += rel_err * rel_err;
				count  += 1;
			}

			double rmsre = (count > 0) ? sqrt(sum_sq / (double)count) : INFINITY;
			if (rmsre < optimal_rmsre) {
				optimal_magic = m;
				optimal_rmsre = rmsre;
			}
		}

		if (step == 1) {
			char buf[128];
			snprintf(buf, sizeof(buf), "%" PRId32 ", %.10e\n",
			         optimal_magic, optimal_rmsre);
			print_and_store(buf);
			step = 0;
		} else {
			/* Widen the next pass by ±2 * step around the current optimum,
			   then refine the step. */
			int32_t span = 2 * step;
			magic_min = optimal_magic - span;
			magic_max = optimal_magic + span;
			step     /= 4;
			if (step == 0) step = 1;
		}
	}

	free(samples);
	free(refs);
	return 0;
}
