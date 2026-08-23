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

/* DEAD (kept for reference): standard-normal sampler N(0,1), guarded so the
   magnitude is a normalized fp32 (rejects |x| < FLT_MIN, i.e. subnormals and
   zero). Its distribution does not match the fp32 range the SV rsqrt accuracy
   testbenches and the hardware actually exercise. Superseded by
   sample_standard() below; retained but no longer called. */
float sample_from_distribution() {
	float normal_rand;
	do
	{
		normal_rand = rand_normal(0, 1);
	} while (fabs(normal_rand) < FLT_MIN);

	return normal_rand;
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
	fp = fopen("optimal_magic_coarse_sweep_results.csv", "w");
	print_and_store("num_newton_steps, optimal_magic_constant, optimal_RMSRE\n");

	bool FULL_SWEEP = false;

	// Parameters for full sweep
	const uint32_t first = 0x00800000u;	// Minimal standard (not 0 or denormalized) float (FLT_MIN)
	const uint32_t last  = 0x7F7FFFFFu;	// Maximal standard (not infinity) float (FLT_MAX)
	uint64_t count = (uint64_t)(last - first) + 1;   /* 2,139,095,040 */

	// Parameters for sampling only
	const int NUM_SAMPLES = 10000;
	float samples[NUM_SAMPLES];
	for(int i = 0; i < NUM_SAMPLES; i++) {
		samples[i] = sample_standard();
	}

	for(int num_newton_steps = 1; num_newton_steps < 3; num_newton_steps++) {
		
		uint32_t optimal_magic_constant = 0;
		double optimal_rmsre = 100;

		for(uint32_t magic_constant = 0x5F000000; magic_constant < 0x5F800000; magic_constant += 0x00001000) {
			double total_rel_error_squared = 0.0;
			for (uint32_t bits = first; bits <= (FULL_SWEEP ? last : (first + NUM_SAMPLES - 1)); bits++) {
				float inp_value = FULL_SWEEP ? bits_to_float(bits) : samples[bits - first];
				float approx    = fast_invsqrt(magic_constant, inp_value, num_newton_steps);
				double exact    = 1.0 / sqrt((double)inp_value);
				double rel_err  = fabs((double)approx - exact) / exact;

				total_rel_error_squared += rel_err*rel_err;
			}
			double rmsre = sqrt(total_rel_error_squared / (double)(FULL_SWEEP ? count : NUM_SAMPLES));
			if(rmsre < optimal_rmsre) {
				optimal_magic_constant = magic_constant;
				optimal_rmsre = rmsre;
			}
			fprintf(fp, "%d, %" PRIu32 ", %.6f\n", num_newton_steps, magic_constant, rmsre);
		}

		char buf[128];
		snprintf(buf, sizeof(buf), "%d, %" PRIu32 ", %.6f\n", num_newton_steps, optimal_magic_constant, optimal_rmsre);
		print_and_store(buf);
	}

	return 0;
}