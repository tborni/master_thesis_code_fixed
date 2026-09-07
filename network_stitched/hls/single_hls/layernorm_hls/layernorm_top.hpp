/****************************************************************************
 * Copyright Advanced Micro Devices, Inc.
 * SPDX-License-Identifier: MIT
 *
 * @author	Shane T. Fleming <shane.fleming@amd.com>
 * @author	Thomas B. Preußer <thomas.preusser@amd.com>
 ****************************************************************************/
#ifndef LAYERNORM_TOP_HPP
#define LAYERNORM_TOP_HPP

#include <hls_stream.h>
#include <hls_vector.h>


constexpr unsigned  N    = 384;   // total processed vector length
constexpr unsigned  SIMD =   4;   // parallelism; must divide N (384 % 4 == 0)
using  TI = float;                // input  data type (FP32)
using  TO = float;                // output data type (FP32)

void layernorm_top(
	hls::stream<hls::vector<TI, SIMD>> &src,
	hls::stream<hls::vector<TO, SIMD>> &dst
);

#endif
