/****************************************************************************
 * Copyright Advanced Micro Devices, Inc.
 * SPDX-License-Identifier: MIT
 ***************************************************************************/
#ifndef SOFTMAX_TOP_HPP
#define SOFTMAX_TOP_HPP

#include "softmax.hpp"

constexpr size_t  N    = /*@*/ 128 /*@*/;  // total processed vector length
constexpr size_t  SIMD =  /*@*/ 4 /*@*/;   // parallelism; must divide N (128 % 4 == 0)
using  TI = /*@*/ float /*@*/;             // input  data type (FP32)
using  TO = /*@*/ float /*@*/;             // output data type (FP32)

void softmax_top(
	hls::stream<hls::vector<TI, SIMD>> &src,
	hls::stream<hls::vector<TO, SIMD>> &dst
);

#endif
