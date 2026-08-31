#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <inttypes.h>
#include <float.h>

#define M_PI 3.14159265358979323846

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

float fast_invsqrt(uint32_t magic_constant, float number, int num_newton_steps) {
	uint32_t i;
	float x2, y;
	const float threehalfs = 1.5F;

	x2 = number * 0.5F;
	y  = number;
	memcpy(&i, &y, sizeof(i));  
	i  = magic_constant - ( i >> 1 );
	memcpy(&y, &i, sizeof(y));
	for(int i = 0; i < num_newton_steps; i++) {
		y = y * ( threehalfs - ( x2 * y * y ) );
	}

	return y;
}

float rand_normal(float mu, float sigma) {
	float u1 = (rand() + 1.0f) / (RAND_MAX + 2.0f);
	float u2 = (rand() + 1.0f) / (RAND_MAX + 2.0f);

	float z0 = sqrtf(-2.0f * logf(u1)) * cosf(2.0f * M_PI * u2);

	return z0 * sigma + mu;
}

/* Half-normal sampler: the positive part of N(0,1), i.e. |N(0,1)|. Guarded so
   the magnitude is a normalized fp32 (rejects |x| < FLT_MIN, i.e. subnormals
   and zero). Returning the magnitude keeps every sample a valid rsqrt input;
   the signed N(0,1) it derives from produces ~50% negatives, for which
   1/sqrt(x) is NaN and the sweep degenerates. Note this distribution still
   does not match the fp32 range the SV rsqrt accuracy testbenches and the
   hardware exercise (see sample_standard()). */
float sample_from_distribution() {
	float normal_rand;
	do
	{
		normal_rand = rand_normal(0, 1);
	} while (fabs(normal_rand) < FLT_MIN);

	return fabsf(normal_rand);
}

/* xorshift32: produces all 32 bits uniformly. glibc rand() only delivers
   31 bits and combining draws still leaves a biased top bit. */
static uint32_t xs_state = 0x9E3779B9u;

uint32_t rand_u32(void) {
	uint32_t x = xs_state;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	xs_state = x;
	return x;
}

/* Bit-pattern-uniform fp32 sampler mirroring the SystemVerilog rsqrt
   accuracy testbenches (rsqrt_ip_core / rsqrt_bipartite):
       bits = $urandom();
       bits[30:23] = $urandom_range(2, 254);   // normalized; exp*0.5 stays normal
       bits[31]    = 0;                          // positive only
   Mantissa is drawn uniformly, the exponent field uniformly over 2..254,
   and the sign is always positive — the distribution the other rsqrt RMSRE
   components use, rather than chi-squared(1). */
float sample_standard() {
	uint32_t bits      = rand_u32();
	uint32_t exp_field = 2u + (rand_u32() % 253u);   /* 2..254 inclusive */
	bits = (bits & 0x007FFFFFu) | (exp_field << 23); /* keep mantissa, set exp */
	bits &= 0x7FFFFFFFu;                              /* clear sign bit */
	return bits_to_float(bits);
}

int main(void) {
	fp = fopen("determine_optimal_magic.csv", "w");
	print_and_store("num_newton_steps, optimal_magic_constant, optimal_RMSRE\n");

	const int NUM_NEWTON_STEPS = 0;

	// Parameters for sampling only
	const int NUM_SAMPLES = 10000000;
	float *samples = malloc(NUM_SAMPLES * sizeof(float));
	for(int i = 0; i < NUM_SAMPLES; i++) {
		samples[i] = sample_from_distribution();
	}

	uint32_t magic_min_bound = 0x5F000000;
	uint32_t magic_max_bound = 0x5F800000;
	uint32_t step_size = 0x00010000;

	while(step_size > 0) {
		uint32_t optimal_magic_constant = 0;
		double optimal_rmsre = 100;

		for(uint32_t magic_constant = magic_min_bound; magic_constant <= magic_max_bound; magic_constant += step_size) {
			double total_rel_error_squared = 0.0;
			// Use more samples for small intervals
			int num_samples = step_size > 0x00000010 ? NUM_SAMPLES / 100 : NUM_SAMPLES;
			for (uint32_t i = 0; i < num_samples; i++) {
				float inp_value = samples[i];
				float approx    = fast_invsqrt(magic_constant, inp_value, NUM_NEWTON_STEPS);
				double exact    = 1.0 / sqrt((double)inp_value);
				double rel_err  = fabs((double)approx - exact) / exact;

				total_rel_error_squared += rel_err*rel_err;
			}
			double rmsre = sqrt(total_rel_error_squared / num_samples);
			if(rmsre < optimal_rmsre) {
				optimal_magic_constant = magic_constant;
				optimal_rmsre = rmsre;
			}
		}

		if(step_size == 1) {
			free(samples);
			char buf[128];
			snprintf(buf, sizeof(buf), "%d, %" PRIu32 ", %.6f\n", NUM_NEWTON_STEPS, optimal_magic_constant, optimal_rmsre);
			print_and_store(buf);
			step_size = 0;
		} else {
			magic_min_bound = optimal_magic_constant - 2 * step_size;
			magic_max_bound = optimal_magic_constant + 2 * step_size;
			step_size /= 4;
		}
	}

	return 0;
}