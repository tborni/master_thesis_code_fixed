#include <stdio.h>
#include <stdint.h>
#include <math.h>

#define SCHRAUDOLPH_A 12102203.0f
#define SCHRAUDOLPH_D 1064866805.0f

float schraudolph_exp(float f) {
	union {
		int32_t i;
		float   f;
	} u;
	u.i = (int32_t)(SCHRAUDOLPH_A * f + SCHRAUDOLPH_D);
	return u.f;
}

int main(void) {
	float x = 89.0f;

	float  sa = schraudolph_exp(x);
	float ref = (float)exp((double)x);

	double rel_err = (isfinite(ref) && ref != 0.0)
	               ? (double)fabs(sa - ref) / ref
	               : NAN;

	uint32_t xb = (union { float f; uint32_t u; }){.f = x}.u;
	printf("x                  : %.9g (0x%08x)\n", x, (unsigned)xb);
	printf("schraudolph_exp(x) : %.9g\n", sa);
	printf("reference_exp(x)   : %.17g\n", ref);
	printf("relative error     : %.10e\n", rel_err);
	return 0;
}
