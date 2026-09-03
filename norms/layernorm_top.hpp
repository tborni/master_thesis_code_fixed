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


constexpr unsigned  N    = 128;
constexpr unsigned  SIMD =  16;
using  TI = float;
using  TO = float;

void layernorm_top(
	hls::stream<hls::vector<TI, SIMD>> &src,
	hls::stream<hls::vector<TO, SIMD>> &dst
);

#endif
