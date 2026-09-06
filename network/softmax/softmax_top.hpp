/****************************************************************************
 * Copyright Advanced Micro Devices, Inc.
 * SPDX-License-Identifier: MIT
 ***************************************************************************/
#ifndef SOFTMAX_TOP_HPP
#define SOFTMAX_TOP_HPP

#include "softmax.hpp"

constexpr size_t  N    = /*@*/ 30 /*@*/;
constexpr size_t  SIMD =  /*@*/ 5 /*@*/;
using  TI = /*@*/ ap_uint<8> /*@*/;
using  TO = /*@*/ ap_float<16,8> /*@*/;

void softmax_top(
	hls::stream<hls::vector<TI, SIMD>> &src,
	hls::stream<hls::vector<TO, SIMD>> &dst
);

#endif
