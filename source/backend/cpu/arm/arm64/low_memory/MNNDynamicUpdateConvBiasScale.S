//
//  MNNDynamicUpdateConvBiasScale.S
//  MNN
//
//  Created by MNN on 2019/01/22.
//  Copyright © 2018, Alibaba Group Holding Limited
//

#ifdef __aarch64__

#include "MNNAsmGlobal.h"

.text
.align 5

.macro Round z0, z1, z2, z3
    fcvtzs \z0\().4s, \z0\().4s
    fcvtzs \z1\().4s, \z1\().4s
    fcvtzs \z2\().4s, \z2\().4s
    fcvtzs \z3\().4s, \z3\().4s
.endm

.macro MUL_CONSTANT s0, s1, s2, s3, z0
    fmul \s0\().4s, \s0\().4s, \z0\().4s
    fmul \s1\().4s, \s1\().4s, \z0\().4s
    fmul \s2\().4s, \s2\().4s, \z0\().4s
    fmul \s3\().4s, \s3\().4s, \z0\().4s
.endm

.macro DIV4 s0, s1, s2, s3, z0, z1, z2, z3
    fdiv \s0\().4s, \s0\().4s, \z0\().4s 
    fdiv \s1\().4s, \s1\().4s, \z1\().4s 
    fdiv \s2\().4s, \s2\().4s, \z2\().4s 
    fdiv \s3\().4s, \s3\().4s, \z3\().4s 
.endm

.macro ADD4 s0, s1, s2, s3, z0, z1, z2, z3
    fadd \s0\().4s, \s0\().4s, \z0\().4s
    fadd \s1\().4s, \s1\().4s, \z1\().4s
    fadd \s2\().4s, \s2\().4s, \z2\().4s
    fadd \s3\().4s, \s3\().4s, \z3\().4s
.endm

/*
Note: Only used in dynamic quant,so do not need compare min max!
 */
asm_function MNNDynamicUpdateConvBiasScale
//MNNDynamicUpdateConvBiasScale(float* newbias, float* oldbias, float* weightKernelSum, float* inputZero, size_t ocQuad);
//x0:newbias, x1:oldbias, x2:weightKernelSum, x3:inputZero, x4:ocQuad

stp d14, d15, [sp, #-64]!
stp d12, d13, [sp, #16]
stp d10, d11, [sp, #32]
stp d8,  d9,  [sp, #48]

ld1r {v30.4s}, [x3] // input dequant zero:fp32 zero
// Bias:
BIAS_L16:
cmp x4, #16
blt BIAS_L8

ld1 {v0.4s, v1.4s, v2.4s, v3.4s}, [x1], #64 // oldbias
ld1 {v4.4s, v5.4s, v6.4s, v7.4s}, [x1], #64
ld1 {v8.4s, v9.4s, v10.4s, v11.4s}, [x1], #64
ld1 {v12.4s, v13.4s, v14.4s, v15.4s}, [x1], #64
ld1 {v16.4s, v17.4s, v18.4s, v19.4s}, [x2], #64 // weightKernelSum
ld1 {v20.4s, v21.4s, v22.4s, v23.4s}, [x2], #64
ld1 {v24.4s, v25.4s, v26.4s, v27.4s}, [x2], #64

sub x4, x4, #16

MUL_CONSTANT v16, v17, v18, v19, v30 // w_sum * x_zero
MUL_CONSTANT v20, v21, v22, v23, v30 // w_sum * x_zero
MUL_CONSTANT v24, v25, v26, v27, v30 // w_sum * x_zero

ADD4 v0, v1, v2, v3, v16, v17, v18, v19
ADD4 v4, v5, v6, v7, v20, v21, v22, v23
ld1 {v16.4s, v17.4s, v18.4s, v19.4s}, [x2], #64
ADD4 v8, v9, v10, v11, v24, v25, v26, v27
MUL_CONSTANT v16, v17, v18, v19, v30 // w_sum * x_zero
ADD4 v12, v13, v14, v15, v16, v17, v18, v19

st1 {v0.4s, v1.4s, v2.4s, v3.4s}, [x0], #64 // bias float
st1 {v4.4s, v5.4s, v6.4s, v7.4s}, [x0], #64
st1 {v8.4s, v9.4s, v10.4s, v11.4s}, [x0], #64
st1 {v12.4s, v13.4s, v14.4s, v15.4s}, [x0], #64
b BIAS_L16

BIAS_L8:
cmp x4, #8
blt BIAS_L4

ld1 {v0.4s, v1.4s, v2.4s, v3.4s}, [x1], #64 // oldbias
ld1 {v4.4s, v5.4s, v6.4s, v7.4s}, [x1], #64
ld1 {v16.4s, v17.4s, v18.4s, v19.4s}, [x2], #64 // weightKernelSum
ld1 {v20.4s, v21.4s, v22.4s, v23.4s}, [x2], #64
sub x4, x4, #8

MUL_CONSTANT v16, v17, v18, v19, v30 // w_sum * x_zero
MUL_CONSTANT v20, v21, v22, v23, v30 // w_sum * x_zero
ADD4 v0, v1, v2, v3, v16, v17, v18, v19
ADD4 v4, v5, v6, v7, v20, v21, v22, v23
st1 {v0.4s, v1.4s, v2.4s, v3.4s}, [x0], #64 // bias float
st1 {v4.4s, v5.4s, v6.4s, v7.4s}, [x0], #64
b BIAS_L8

BIAS_L4:
cmp x4, #4
blt BIAS_L1

ld1 {v0.4s, v1.4s, v2.4s, v3.4s}, [x1], #64 // oldbias
ld1 {v8.4s, v9.4s, v10.4s, v11.4s}, [x2], #64 // weightKernelSum
sub x4, x4, #4

MUL_CONSTANT v8, v9, v10, v11, v30 // w_sum * x_zero
ADD4 v0, v1, v2, v3, v8, v9, v10, v11
st1 {v0.4s, v1.4s, v2.4s, v3.4s}, [x0], #64
b BIAS_L4

BIAS_L1:
cmp x4, #1
blt End
ld1 {v0.4s}, [x1], #16 // oldbias
ld1 {v4.4s}, [x2], #16 // weightKernelSum
sub x4, x4, #1
fmul v4.4s, v4.4s, v30.4s // w_sum * x_zero
fadd v0.4s, v0.4s, v4.4s // oldbias + w_sum * x_zero
st1 {v0.4s}, [x0], #16
b BIAS_L1

End:
ldp d8,  d9,  [sp, #48]
ldp d10, d11, [sp, #32]
ldp d12, d13, [sp, #16]
ldp d14, d15, [sp], #64
ret
#endif
