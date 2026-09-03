/****************************************************************************
 * Copyright Advanced Micro Devices, Inc.
 * SPDX-License-Identifier: MIT
 ***************************************************************************/
#include "softmax_top.hpp"
#include <random>
#include <algorithm>
#include <numeric>

constexpr unsigned  ROUNDS = 23;

template<typename TI>
std::vector<float> softmax_ref(std::vector<TI> const &input) {

	auto max_iter = std::max_element(input.begin(), input.end());
	float max = float(*max_iter);
        float sum = std::accumulate(input.begin(), input.end(), 0.0f, [max](float acc, TI x) {
		            return acc + std::exp(float(x) - max);
	});

	std::vector<float> output(input.size());
	std::transform(input.begin(), input.end(), output.begin(),
			[max,sum](TI x) { return exp(float(x) - max)/sum;
	});

	return output;
}

template<typename TO, unsigned SIMD, unsigned N>
bool is_sm_valid(std::vector<std::vector<float>> const &ref, hls::vector<TO, SIMD> const &res, float atol=1e-5) {
	static unsigned loc = 0;

	unsigned round = loc/N;
	unsigned idx = loc%N;
	bool mismatch = false;

	for(unsigned i=0; i<SIMD; i++) {
		if ( std::abs(float(res[i]) - ref[round][idx + i]) > atol ) {
			std::cerr << "Error in round: " << round << " index  " << idx << "\n";
			std::cerr <<  res[i] << " != " << ref[round][idx + i]<< "\n";
			mismatch = true;
		}
	}

	loc += SIMD;
	return !mismatch;
}

int main() {
	hls::stream<hls::vector<TI,    SIMD>>  src;
	hls::stream<hls::vector<TO,    SIMD>>  dst;
	std::vector<std::vector<float>>        ref_rounds; // stores the reference value for each ROUND

	{ // Generate Input
		std::default_random_engine  rnd;
		for(unsigned  r = 0; r < ROUNDS; r++) {
			std::vector<TI> ref_in;
			for(unsigned  i = 0; i < N; i += SIMD) {
				hls::vector<TI, SIMD>  x;
				for(unsigned  j = 0; j < SIMD; j++) {
					x[j] = rnd();
					ref_in.push_back(x[j]);
				}
				src.write(x);
			}
			ref_rounds.push_back(softmax_ref(ref_in));
		}
	}

	unsigned  timeout = 0;
	bool      mismatch = false;
	unsigned  count = 0;
	while(timeout < 2*N/SIMD+20) {
		softmax_top(src, dst);
		if(dst.empty())  timeout++;
		else {
			auto const  y = dst.read();
			std::cout << y << std::endl;
			mismatch = !is_sm_valid<TO,SIMD,N>(ref_rounds, y, 1e-2) ? true : mismatch;
			timeout = 0;
			count += SIMD;
		}
	}

	bool incorrect_amount = (ROUNDS*N != count);
	auto const outcome = (mismatch || incorrect_amount) ? "FAIL" : "PASS";
	std::cout << "Test result: " << outcome << std::endl;
	return (mismatch || incorrect_amount);
}
