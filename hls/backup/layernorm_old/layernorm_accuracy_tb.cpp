/****************************************************************************
 * Copyright Advanced Micro Devices, Inc.
 * SPDX-License-Identifier: MIT
 *
 * @brief   Accuracy testbench for the HLS LayerNorm, measuring the RMSRE of
 *          the finite-precision fp32 datapath against a full-precision (double)
 *          reference -- the exact same metric used by the SystemVerilog
 *          accuracy testbench (layernorm_accuracy_tb.sv), so the HLS and the
 *          RTL implementations can be compared on an equal footing.
 *
 * @details
 *   This drives the *real* HLS kernel: it instantiates layernorm<N,TI,TO,SIMD>
 *   from layernorm.hpp and streams data through it under Vitis HLS C
 *   simulation. No behavioral re-implementation of the datapath is used; the
 *   numbers reported here are those of the synthesizable code itself.
 *
 *   Only the single configuration requested for the thesis comparison is
 *   exercised: N = 64, SIMD = 2, TI = TO = float (fp32 in and out).
 *
 *   Equivalence to the SystemVerilog accuracy testbench
 *   ---------------------------------------------------
 *   The following are reproduced bit-for-bit / value-for-value so that the
 *   RMSRE reported here is measured "the same way" as in the RTL flow:
 *
 *     * Input distribution -- rand_fp() below builds each fp32 sample with the
 *       identical bit layout as the SV rand_fp(): the low 23 bits of a random
 *       32-bit word form the mantissa, the biased exponent is uniform in
 *       [87, 142] (values ~[2^-40, 2^15)), and the sign bit is uniform. Inputs
 *       therefore stay strictly normalized, exactly as in the SV testbench.
 *
 *     * Reference -- exact_layernorm() computes the mean, the variance of the
 *       mean-shifted values, and 1/sqrt(variance + EPSILON) in double precision
 *       and casts each output element to float, mirroring the SV reference
 *       precisely (same EPSILON, same shift-then-scale algorithm). The measured
 *       error is thus the fp32 finite-precision error of the HLS datapath alone.
 *
 *     * Metric -- RMSRE over the output elements whose exact magnitude clears
 *       REL_ERR_FLOOR = 1e-3 (elements passing through zero are excluded, since
 *       the relative error is undefined there); also the maximum relative error
 *       and the input that produced it. Identical floors, identical formulas,
 *       identical report format and identical TARGET_ELEMENTS sample size.
 *
 *   The one difference that cannot be removed is the pseudo-random *sequence*
 *   itself: SystemVerilog's $urandom and C++'s PRNG are different generators,
 *   so the two testbenches do not replay the identical stream of samples. They
 *   draw from the identical *distribution* with the identical *sample count*
 *   (TARGET_ELEMENTS elements), which is what makes the resulting RMSRE figures
 *   statistically comparable -- not the individual draws.
 *
 *   Driving an HLS DATAFLOW kernel under C simulation
 *   -------------------------------------------------
 *   layernorm() is a DATAFLOW region with ap_ctrl_none and stream I/O. As in
 *   the existing layernorm_tb.cpp, and as required by Vitis HLS for such a
 *   region, the top function is invoked repeatedly in a loop: each call lets
 *   the leaf processes consume the data currently available, so several calls
 *   are needed to push a vector through the three pipeline stages and to flush
 *   the internal FIFOs. The loop terminates once the kernel has been idle
 *   (produced no output) for a bounded number of consecutive calls.
 ****************************************************************************/
// The HLS stream/vector headers must precede layernorm.hpp: the kernel's
// signatures are written in terms of hls::stream / hls::vector.
#include <hls_stream.h>
#include <hls_vector.h>
#include <hls_math.h>

#include "layernorm.hpp"

#include <cmath>
#include <cstdint>
#include <cstddef>
#include <cstring>
#include <deque>
#include <random>
#include <vector>
#include <cstdio>

//---------------------------------------------------------------------------
// Configuration under test -- the thesis comparison point.
static constexpr std::size_t  N     = 64;   // vector length
static constexpr std::size_t  SIMD  = 2;    // lane parallelism
using  TI = float;                          // fp32 input
using  TO = float;                          // fp32 output

static constexpr float  EPSILON = 1.0e-5f;  // variance stabilizer (matches DUT/ref)

// Hold the number of exercised output elements constant, exactly as the SV
// testbench does. TARGET_ELEMENTS must be divisible by N; 32768 is a multiple
// of every power-of-two N used in the sweep.
static constexpr std::size_t  TARGET_ELEMENTS = 32768;
static constexpr std::size_t  NUM_SAMPLES     = TARGET_ELEMENTS / N;   // = 512 vectors

// Reference relative error is only defined where the exact output is not (near)
// zero; such elements are excluded from the statistics.
static constexpr double  REL_ERR_FLOOR = 1.0e-3;

// Reported RMSRE when no output element cleared the floor (metric undefined).
static constexpr double  RMSRE_UNDEFINED = -1.0;

//---------------------------------------------------------------------------
// Generate a random fp32 sample with the identical bit layout as the SV
// rand_fp(): 23-bit mantissa from a random word, biased exponent uniform in
// [87, 142], uniform sign. Keeps inputs strictly normalized.
static float rand_fp(std::mt19937 &rng) {
	std::uniform_int_distribution<std::uint32_t>  mant_d(0u, (1u << 23) - 1u);  // 23-bit mantissa
	std::uniform_int_distribution<std::uint32_t>  exp_d(87u, 142u);             // biased exponent
	std::uniform_int_distribution<std::uint32_t>  sign_d(0u, 1u);               // sign bit

	std::uint32_t  bits = mant_d(rng);              // mantissa in [22:0]
	bits |= exp_d(rng)  << 23;                      // exponent in [30:23]
	bits |= sign_d(rng) << 31;                      // sign in [31]

	float  f;
	std::memcpy(&f, &bits, sizeof(f));
	return  f;
}

//---------------------------------------------------------------------------
// Exact LayerNorm of the algorithm implemented by the DUT, evaluated in full
// (double) precision over one complete vector of N input elements and cast to
// fp32 per output element -- the reference against which the HLS output error
// is measured. Mirrors the SV exact_layernorm() exactly: plain mean, variance
// of the shifted values, EPSILON-stabilized inverse square root.
static void exact_layernorm(std::vector<float> const &x, std::vector<float> &y) {
	double  sum = 0.0;
	for(float const  v : x)  sum += double(v);
	double const  mean = sum / double(N);

	double  var_sum = 0.0;
	for(float const  v : x) {
		double const  d = double(v) - mean;
		var_sum += d * d;
	}
	double const  variance = var_sum / double(N);
	double const  inv_std  = 1.0 / std::sqrt(variance + double(EPSILON));

	y.clear();
	y.reserve(x.size());
	for(float const  v : x)  y.push_back(float((double(v) - mean) * inv_std));
}

//---------------------------------------------------------------------------
int main() {
	hls::stream<hls::vector<TI, SIMD>>  src;
	hls::stream<hls::vector<TO, SIMD>>  dst;

	// Deterministic seed so the run is reproducible (the SV testbench seeds its
	// per-configuration feeder from N; we do the analogous thing here).
	std::mt19937  rng(static_cast<std::uint32_t>(N));

	// Feed exactly NUM_SAMPLES vectors of N elements, packed SIMD lanes per beat,
	// and remember each input vector so its output can be checked in order.
	std::deque<std::vector<float>>  pending;   // FIFO of length-N input vectors
	{
		std::vector<float>  vec;
		vec.reserve(N);
		for(std::size_t  s = 0; s < NUM_SAMPLES; s++) {
			for(std::size_t  i = 0; i < N; i += SIMD) {
				hls::vector<TI, SIMD>  beat;
				for(std::size_t  j = 0; j < SIMD; j++) {
					float const  v = rand_fp(rng);
					beat[j] = v;
					vec.push_back(v);
				}
				src.write(beat);
			}
			pending.push_back(vec);
			vec.clear();
		}
	}

	// Error statistics (accumulated in double, exactly like the SV testbench).
	std::size_t  err_count       = 0;   // number of output elements entering the RMSRE
	double       rel_err_squared = 0.0;
	double       rel_err_max     = 0.0;
	float        worst_input     = 0.0f;

	// Output-vector assembly and comparison state.
	std::vector<float>  outv;           // output vector under construction
	outv.reserve(N);
	std::vector<float>  yref;           // reference for the current vector
	std::size_t         vectors_done = 0;

	// Drive the DATAFLOW kernel until it has been idle for a bounded run of
	// consecutive calls (all FIFOs flushed, all vectors emitted). The idle
	// bound is generous relative to the pipeline depth so no output is missed.
	static constexpr unsigned  IDLE_LIMIT = 512;
	unsigned  idle = 0;
	while(idle < IDLE_LIMIT) {
		layernorm<N, TI, TO, SIMD>(src, dst, EPSILON);

		if(dst.empty()) {
			idle++;
			continue;
		}
		idle = 0;

		// Consume every beat currently available and assemble N-element vectors.
		while(!dst.empty()) {
			hls::vector<TO, SIMD> const  beat = dst.read();
			for(std::size_t  j = 0; j < SIMD; j++)  outv.push_back(beat[j]);

			if(outv.size() == N) {
				if(pending.empty()) {
					std::fprintf(stderr, "Spurious output vector.\n");
					return  1;
				}
				std::vector<float> const  xin = pending.front();
				pending.pop_front();
				exact_layernorm(xin, yref);

				for(std::size_t  i = 0; i < yref.size(); i++) {
					double const  exp     = double(yref[i]);
					double const  diff    = double(outv[i]) - exp;
					double const  abs_exp = std::fabs(exp);
					double const  abs_dif = std::fabs(diff);
					if(abs_exp >= REL_ERR_FLOOR) {
						double const  rel_err = abs_dif / abs_exp;
						rel_err_squared += rel_err * rel_err;
						err_count += 1;
						if(rel_err > rel_err_max) {
							rel_err_max = rel_err;
							worst_input = xin[i];
						}
					}
				}
				outv.clear();
				vectors_done++;
			}
		}
	}

	// All fed vectors must have come back out.
	if(!pending.empty()) {
		std::fprintf(stderr, "Test (N = %zu, SIMD = %zu): Missing %zu output vectors.\n",
			N, SIMD, pending.size());
		return  1;
	}
	if(!outv.empty()) {
		std::fprintf(stderr, "Test (N = %zu, SIMD = %zu): Trailing %zu-element partial output.\n",
			N, SIMD, outv.size());
		return  1;
	}

	double const  rmsre = (err_count != 0) ? std::sqrt(rel_err_squared / double(err_count))
	                                        : RMSRE_UNDEFINED;

	// Same report format as the SV accuracy testbench.
	std::printf("Test (N = %zu, SIMD = %zu): RMSRE = %.10f, MAX_REL_ERROR = %.10f, WORST_INPUT = %.25f (elements = %zu)\n",
		N, SIMD, rmsre, rel_err_max, double(worst_input), err_count);

	return  0;
}
