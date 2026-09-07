/****************************************************************************
 * Copyright (C) 2024, Advanced Micro Devices, Inc.
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * @author	Thomas B. Preußer <thomas.preusser@amd.com>
 ****************************************************************************
 * Reduced extract for the softmax component: clog2 / tree_reduce / ModCounter
 * (identical to the layernorm extract) plus the is_floating_point_or_ap_float
 * trait required by softmax.hpp.
 *
 * The ap_float.h / ap_float<W,I> / numeric_limits<ap_float> content of the full
 * util.hpp was dropped: ap_float.h is absent in Vitis HLS 2023.1, and this
 * softmax component is synthesized with standard-float I/O (TI = TO = float,
 * see softmax_top.hpp). is_floating_point_or_ap_float is therefore provided in
 * its std::is_floating_point-only form, which is exactly what the TO = float
 * static_assert in softmax.hpp needs. Symbols below are verbatim from the
 * original where noted.
 ****************************************************************************/
#ifndef UTIL_HPP
#define UTIL_HPP

#include <algorithm>
#include <cstddef>
#include <limits>
#include <type_traits>

#include <ap_int.h>
#include <hls_stream.h>
#include <hls_vector.h>


//- Type Traits -------------------------------------------------------------

// True for standard floating-point types (float / double / long double).
//
// The full util.hpp additionally recognized VitisHLS ap_float<W,I> here. That
// path is intentionally omitted: ap_float.h is unavailable in Vitis HLS 2023.1
// and the softmax component is built with TO = float, so the standard-float
// branch is sufficient for the static_assert in softmax.hpp. To restore
// ap_float support, add the ap_float type/header and an OR-ed specialization.
template<typename T>
struct is_floating_point_or_ap_float : std::is_floating_point<T> {};


//- Compile-Time Functions --------------------------------------------------

// ceil(log2(x))
template<typename T>
constexpr unsigned clog2(T  x) {
  return  x<2? 0 : 1+clog2((x+1)/2);
}

//- Tree Reduce -------------------------------------------------------------
template<
	size_t    N,
	typename  TA,
	typename  TR = TA,	// must be assignable from TA
	typename  F			// (TR, TR) -> TR
>
TR tree_reduce(hls::vector<TA, N> const &v, F &&f = F()) {
#pragma HLS inline
	TR  tree[2*N-1];
#pragma HLS array_partition complete dim=1 variable=tree
	for(unsigned  i = N; i-- > 0;) {
#pragma HLS unroll
		tree[N-1 + i] = v[i];
	}
	for(unsigned  i = N-1; i-- > 0;) {
#pragma HLS unroll
		tree[i] = f(tree[2*i+1], tree[2*i+2]);
	}
	return  tree[0];
}

//- Modulus Counter ---------------------------------------------------------

/**
 * Modulus counter returning true upon each N-th call of tick.
 * @description
 *	The implementation internally counts from N-2, ..., 0, -1 wrapping back to
 *	N-2 so that the sign bit of the counter value can directly serve as the
 *	wrap-around indicator without requiring a multi-bit comparator.
 */
template<unsigned  N> class ModCounter {
	ap_int<1+clog2(N-1)>  cnt = N-2;
public:
	bool last() const {
#pragma HLS inline
		return  cnt < 0;
	}
	bool tick() {
#pragma HLS inline
		bool const  ret = last();
		cnt += ret? N-1 : -1;
		return  ret;
	}
};
template<> class ModCounter<1> {
public:
	bool last() const {
#pragma HLS inline
		return  true;
	}
	bool tick() const {
#pragma HLS inline
		return  true;
	}
};
template<> class ModCounter<0> {};

#endif
