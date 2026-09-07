/****************************************************************************
 * Copyright Advanced Micro Devices, Inc.
 * SPDX-License-Identifier: MIT
 ***************************************************************************/
#ifndef SOFTMAX_TOP_HPP
#define SOFTMAX_TOP_HPP

#include "softmax.hpp"

constexpr size_t  N    = /*@*/ 64 /*@*/;
constexpr size_t  SIMD =  /*@*/ 1 /*@*/;
using  TI = /*@*/ float /*@*/;
using  TO = /*@*/ float /*@*/;

void softmax_top(
	hls::stream<hls::vector<TI, SIMD>> &src,
	hls::stream<hls::vector<TO, SIMD>> &dst
);

#endif
