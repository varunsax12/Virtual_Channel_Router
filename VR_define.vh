
`ifndef VR_define
`define VR_define

// Arbiter identifiers
`define MATRIX_ARBITER        1
`define ROUND_ROBIN_ARBITER   2

// Allocator identifiers
`define SEPARABLE_ALLOCATOR   1
`define WAVEFRONT_ALLOCATOR   2

// Arbiter selection switch
`define ARBITER_TYPE          2

// Allocator select switch
`define ALLOCATOR_TYPE        1

// Switch to indicate whether to arbiter in select_vc or encoder
`define SELECT_VC_ARBITRATE   0

// Flit data width
`define FLIT_DATA_WIDTH       32

// Direction encoding
`define NORTH   3'b000
`define SOUTH   3'b001
`define EAST    3'b010
`define WEST    3'b011
`define EJECT   3'b100

`endif
