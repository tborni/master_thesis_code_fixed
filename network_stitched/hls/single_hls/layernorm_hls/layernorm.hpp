/****************************************************************************
 * Copyright Advanced Micro Devices, Inc.
 * SPDX-License-Identifier: MIT
 *
 * @author	Shane T. Fleming <shane.fleming@amd.com>
 * @author	Thomas B. Preußer <thomas.preusser@amd.com>
 ****************************************************************************/
#ifndef LAYERNORM_HPP
#define LAYERNORM_HPP

#include "util.hpp"
#include <hls_math.h>


// First pipeline stage
//
// Trigger: Data available on src input stream
//
// Desc: Performs a mean calculation across N elements.
template<
	size_t   N,    // total processed vector length
	typename T,    // [inferred] type of input data
	typename TM,   // [inferred] type of mean
	size_t   SIMD  // [inferred] parallelism
>
void mean_stage(
	hls::stream<hls::vector<T, SIMD>> &in_s,
	hls::stream<hls::vector<T, SIMD>> &out_s,
	hls::stream<TM> &mean_s
) {
#pragma HLS pipeline II=1 style=flp
	static_assert(N%SIMD == 0, "SIMD parallelism must divide vector length.");
	constexpr size_t  NN = N / SIMD;

	static ModCounter<NN>  count;
	static TM  sum = TM(0);
#pragma HLS reset variable=count
#pragma HLS reset variable=sum

	if (!in_s.empty()) {
		hls::vector<T,  SIMD> const  x = in_s.read();
		sum += tree_reduce(x, [](TM const &a, TM const &b) -> TM { return  a+b; });

		out_s.write(x);
		if(count.tick()) {
			mean_s.write(sum / N);
			sum = TM(0);
		}
	}

} // mean_stage()


// Second pipeline stage
//
// Trigger: On data being available on the mean value stream
//
// Desc: Normalizes input to a mean of 0 and computes the variance across N elements.
template<
	size_t   N,    // total processed vector length
	typename T,    // [inferred] type of input data
	typename TM,   // [inferred] type of mean
	typename TO,   // [inferred] type of normalized output data
	size_t   SIMD  // [inferred] parallelism
>
void var_stage(
	hls::stream<hls::vector<T, SIMD>> &in_s,
	hls::stream<TM> &mean_s,

	hls::stream<hls::vector<TO, SIMD>> &out_s,
	hls::stream<TO> &var_s
) {
#pragma HLS pipeline II=1 style=flp
	static_assert(N%SIMD == 0, "SIMD parallelism must divide vector length.");
	constexpr size_t  NN = N / SIMD;

	static TM  mean;
	static bool  valid = false;
	static ModCounter<NN>  count;
	static TO  sumq = TO(0);
#pragma HLS reset variable=mean off
#pragma HLS reset variable=valid
#pragma HLS reset variable=count
#pragma HLS reset variable=sumq

	if(!valid && !mean_s.empty()) {
		mean_s.read_nb(mean);
		valid = true;
	}

	if(valid && !in_s.empty()) {
		hls::vector<T,  SIMD> const  x = in_s.read();
		hls::vector<TO, SIMD>  y;
		hls::vector<TO, SIMD>  yy;
		for(unsigned i=0; i<SIMD; i++) {
#pragma HLS UNROLL
			TO const  xm = TO(x[i]) - mean;
			y [i] = xm;
			yy[i] = xm * xm;
		}
		sumq += tree_reduce(yy, [](TO const &a, TO const &b) -> TO { return  a+b; });

		out_s.write(y);
		if(count.tick()) {
			var_s.write(sumq / N);
			sumq = TO(0);
			valid = false;
		}
	}

} // var_stage()

// Third pipeline stage
//
// Trigger: On data being available on the varmean value stream
//
// Desc: Performs a variance normalization of across N mean-centered data elements.
template<
	size_t   N,
	typename TO,
	size_t   SIMD
>
void inv_sqrt_stage(
	hls::stream<hls::vector<TO, SIMD>> &in_s,
	hls::stream<TO> &var_s,
	hls::stream<hls::vector<TO, SIMD>> &out_s,
	TO const  eps
) {
#pragma HLS function_instantiate variable=eps
#pragma HLS pipeline II=1 style=flp
	static_assert(N%SIMD == 0, "SIMD parallelism must divide vector length.");
	constexpr size_t  NN = N / SIMD;

	static TO  var;
	static bool  valid = false;
	static ModCounter<NN>  count;
#pragma HLS reset variable=var off
#pragma HLS reset variable=valid
#pragma HLS reset variable=count

	if(!valid && !var_s.empty()) {
		var = 1.0f / hls::sqrt(var_s.read() + eps);
		valid = true;
	}

	if(valid && !in_s.empty()) {
		hls::vector<TO, SIMD> const  x = in_s.read();
		hls::vector<TO, SIMD>  y;
		for(unsigned i=0; i<SIMD; i++) {
#pragma HLS UNROLL
			y[i] = var * x[i];
		}

		out_s.write(y);
		if(count.tick())  valid = false;
	}

} // inv_sqrt_stage()

template<
	size_t    N,
	typename  TI, // Input type
	typename  TO, // Output type
	size_t    SIMD
>
void layernorm(
	hls::stream<hls::vector<TI, SIMD>> &src,
	hls::stream<hls::vector<TO, SIMD>> &dst,
	TO const  eps = 1e-5f
) {
#pragma HLS DATAFLOW disable_start_propagation

	static hls::stream<hls::vector<TI, SIMD>> stage1_s;
#pragma HLS stream variable=stage1_s depth=N/SIMD
	static hls::stream<TO> mean_s;
#pragma HLS stream variable=mean_s depth=2
	static hls::stream<hls::vector<TO, SIMD>> stage2_s;
#pragma HLS stream variable=stage2_s depth=N/SIMD
	static hls::stream<TO> var_s;
#pragma HLS stream variable=var_s depth=2

	mean_stage<N>(src, stage1_s, mean_s);
	var_stage<N>(stage1_s, mean_s, stage2_s, var_s);
	inv_sqrt_stage<N>(stage2_s, var_s, dst, eps);
}

#endif
