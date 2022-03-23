
`ifndef VR_define
`define VR_define

// Arbiter identifiers
`define MATRIX_ARBITER        1
`define ROUND_ROBIN_ARBITER   2

// Allocator identifiers
`define SEPARABLE_ALLOCATOR   1
`define WAVEFRONT_ALLOCATOR   2

// Arbiter selection switch
`define ARBITER_TYPE          1

// Allocator select switch
`define ALLOCATOR_TYPE        1

// Switch to indicate whether to arbiter in select_vc or encoder
`define SELECT_VC_ARBITRATE   0

// Direction encoding
`define NORTH   2'b00
`define SOUTH   2'b01
`define EAST    2'b10
`define WEST    2'b11

`endif
