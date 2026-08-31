/**************************
 * Copyright Advanced Micro Devices, Inc.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * @brief	Combinational IEEE 754 float32 to signed integer converter
 *		with saturation and truncation toward zero.
 * @author	Thomas B. Preußer <thomas.preusser@amd.com>
 *************************/

module fp32_to_int #(
	int unsigned  K	// Output width (signed)
)(
	input	logic [31:0]       fval,
	output	logic signed [K-1:0]  ival
);

	initial begin
		if(K < 2) begin
			$error("K must be at least 2.");
			$finish;
		end
	end

	//=== Field Extraction =================================================
	uwire             sign = fval[31];
	uwire [7:0]       exp  = fval[30:23];
	uwire [22:0]      man  = fval[22:0];

	//=== Magnitude Computation ============================================
	// Effective mantissa with implicit leading 1 (24 bits: 1.23-bit fraction)
	uwire [23:0]  full_man = {1'b1, man};

	// Wide mantissa for safe left-shifting when K > 24
	localparam int unsigned  MANW = (K > 24)? K : 24;
	uwire [MANW-1:0]  wide_man = full_man;

	//=== Conversion =======================================================
	// Value = (-1)^sign × 1.mantissa × 2^(exp-127)
	// Integer magnitude via right-shifting full_man by (150 - exp) or
	// left-shifting wide_man by (exp - 150).
	// Saturate when exp > K + 125 (magnitude ≥ 2^(K-1)).
	always_comb begin
		if(exp < 127) begin
			// |fval| < 1 => truncates to zero
			ival = 0;
		end
		else if(exp > K + 125) begin
			ival = sign? {1'b1, {(K-1){1'b0}}} : {1'b0, {(K-1){1'b1}}};
		end
		else begin
			automatic logic [K-1:0]  mag;
			if(exp <= 150)
				mag = wide_man >> (150 - exp);
			else
				mag = wide_man << (exp - 150);
			ival = sign? -mag : mag;
		end
	end

endmodule : fp32_to_int