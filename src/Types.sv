`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 18:02:24
// Design Name: 
// Module Name: 
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`ifndef TYPES_SV
`define TYPES_SV

`define STRINGIFY(x)                        `"x`"

// Q18.14 fixed point
`define FIXED_WIDTH  			            32
`define FIXED_INT_WIDTH 		            17
`define FIXED_FRAC_WIDTH 		            14
`define FIXED_FRAC_HALF_WIDTH 	            7
`define FIXED					            [`FIXED_WIDTH-1:0]
`define FIXED_UNIT				            (`FIXED_WIDTH'b1 << `FIXED_FRAC_WIDTH)
`define FIXED_HALF_UNIT			            (`FIXED_WIDTH'b1 << (`FIXED_FRAC_WIDTH -1))
`define FIXED_MAX 	                        {1'b0, {`FIXED_INT_WIDTH{1'b1}}, {`FIXED_FRAC_WIDTH{1'b0}}}
`define FIXED_INF 	                        {1'b0, {`FIXED_INT_WIDTH{1'b1}}, {`FIXED_FRAC_WIDTH{1'b1}}}                                
`define FIXED_ZERO 	                        {1'b0, {`FIXED_INT_WIDTH{1'b0}}, {`FIXED_FRAC_WIDTH{1'b0}}}
`define FIXED_ONE 	                        `FIXED_UNIT
`define FIXED_HALF	                        `FIXED_HALF_UNIT
`define FIXED_INF_WIDTH 		            `FIXED_WIDTH-2

// Q2.14 fixed point (for nomalized value)
`define FIXED_NORM_WIDTH  		            16
`define FIXED_NORM_FRAC_WIDTH 		        14
`define FIXED_NORM_FRAC_HALF_WIDTH 	        7
`define FIXED_NORM				            [`FIXED_NORM_WIDTH-1:0]

//`define GPU_CLK_100                         1
//`define GPU_CLK_50                          1

`ifdef GPU_CLK_100
    `define FIXED_DIV_STEP                  4
    `define RGB8_DIV_STEP                   4
`elsif GPU_CLK_50
    `define FIXED_DIV_STEP                  8
    `define RGB8_DIV_STEP                   8
`else
    `define FIXED_DIV_STEP                  16
    `define RGB8_DIV_STEP                   16
`endif

`define SCREEN_COORD_WIDTH  		        10
`define SCREEN_COORD			            [`SCREEN_COORD_WIDTH-1:0]

`define PRIMITIVE_INDEX_WIDTH		        16
`define PRIMITIVE_INDEX				        [`PRIMITIVE_INDEX_WIDTH-1:0]
`define NULL_PRIMITIVE_INDEX                {`PRIMITIVE_INDEX_WIDTH{1'b1}}

// DDR2 with 27bits address == 256MB
`define FRAMEBUFFER_ADDR_0                  27'h000_0000 //FB0 (320x240x32b) 0x00000 ~ 0x26000
`define FRAMEBUFFER_ADDR_1                  27'h002_6000 //FB1 (320x240x32b) 0x26000 ~ 0x4C000
`define ROM_ADDR                            27'h004_C000 //64MB, 0x4C000 ~ 0x204C000
`define RAM_ADDR                            27'h204_C000 //190MB 

`define BVH_PRIMITIVE_ADDR                  27'h205_0000  // 2MB
`define BVH_NODE_ADDR                       27'h20D_0000  // 512KB
`define BVH_LEAF_ADDR                       27'h22D_0000  // 512KB

`define PI                                  16'd25736
`define ONE_DEGREE                          16'd143

`define FRAMEBUFFER_WIDTH                   10'd320
`define FRAMEBUFFER_HEIGHT                  10'd240
`define FRAMEBUFFER_PIXEL_COUNT             ({{22{1'b0}}, `FRAMEBUFFER_WIDTH} * {{22{1'b0}}, `FRAMEBUFFER_HEIGHT})

// Memory controller -----------------------------------------------------
parameter DQ_WIDTH                          = 16;
parameter ECC_TEST                          = "OFF";
parameter ADDR_WIDTH                        = 27;
parameter nCK_PER_CLK                       = 4;

parameter DATA_WIDTH                        = 16;
parameter PAYLOAD_WIDTH                     = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;
parameter APP_DATA_WIDTH                    = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
parameter APP_MASK_WIDTH                    = APP_DATA_WIDTH / 8;

`define MC_CACHE_DATA_WIDTH                 32
`define MC_CACHE_BLOCK_SIZE_WIDTH           4
`define MC_CACHE_BLOCK_SIZE                 2**`MC_CACHE_BLOCK_SIZE_WIDTH
`define MC_PACKAGE_SIZE                     16
`define MC_CACHE_SET_SIZE_WIDTH             3
`define MC_CACHE_SET_SIZE                   2**`MC_CACHE_SET_SIZE_WIDTH

`define MC_CACHE_WRITE_FIFO_SIZE_WIDTH      3
`define MC_CACHE_WRITE_FIFO_SIZE            2**`MC_CACHE_WRITE_FIFO_SIZE_WIDTH

`define DDR_CMD_WRITE                       3'b0
`define DDR_CMD_READ                        3'b1

`define FRAMEBUFFER_READ_ID                 8'd0

// Configuration >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// BVH ---------------------------------------------------------------------
`define BVH_PRIMITIVE_PATH                  `STRINGIFY(E:/MyWork/HomebrewGPU/data/chr_sword.vox.bvh.primitives.txt)
`define BVH_NODES_PATH                      `STRINGIFY(E:/MyWork/HomebrewGPU/data/chr_sword.vox.bvh.nodes.txt)
`define BVH_LEAVES_PATH                     `STRINGIFY(E:/MyWork/HomebrewGPU/data/chr_sword.vox.bvh.leaves.txt)

// AABB raw data -----------------------------------------------------------
// [151:56]         = Position.x
// [119:88]         = Position.y
// [87:56]          = Position.z        
// [55:24]          = Size        
// [23:16]          = Color.r
// [15:8]           = Color.g
// [7:0]            = Color.b
`define BVH_AABB_RAW_DATA_WIDTH             152
// Sphere raw data -----------------------------------------------------------
// [151:56]         = Center.x
// [119:88]         = Center.y
// [87:56]          = Center.z        
// [55:24]          = Radius        
// [23:16]          = Color.r
// [15:8]           = Color.g
// [7:0]            = Color.b
`define BVH_SPHERE_RAW_DATA_WIDTH           152
// BVH node raw data -----------------------------------------------------------
// [223:192]        = Boundary Box Max.x
// [191:160]        = Boundary Box Max.y
// [159:128]        = Boundary Box Max.z
// [127:96]         = Boundary Box Min.x
// [95:64]          = Boundary Box Min.y
// [63:32]          = Boundary Box Min.z
// [31:16]          = Left Node         
// [15:0]           = Right Node                 
`define BVH_NODE_RAW_DATA_WIDTH             224
// BVH leaf raw data -----------------------------------------------------------
// [231:200]        = Boundary Box Max.x
// [199:168]        = Boundary Box Max.y
// [167:136]        = Boundary Box Max.z
// [135:104]        = Boundary Box Min.x
// [103:72]         = Boundary Box Min.y
// [71:40]          = Boundary Box Min.z            
// [39:8]           = Start Primitive Index
// [7:0]            = Number of Primitives
`define BVH_LEAF_RAW_DATA_WIDTH             232

`define BVH_NODE_RAW_DATA_SIZE              20
`define BVH_LEAF_RAW_DATA_SIZE              20

`define BVH_LEAF_AABB_TEST                  1
`define BVH_NODE_INDEX_WIDTH                16
`define BVH_PRIMITIVE_INDEX_WIDTH           32
`define BVH_PRIMITIVE_AMOUNT_WIDTH          8

`define BVH_NODE_STACK_SIZE_WIDTH            6
`define BVH_NODE_STACK_SIZE                  2**`BVH_NODE_STACK_SIZE_WIDTH

// Primitives ---------------------------------------------------------------------
`define LOAD_BVH_MODEL                      1
`ifdef LOAD_BVH_MODEL
    `define BVH_MODEL_RAW_DATA_SIZE         207
`else
    `define BVH_MODEL_RAW_DATA_SIZE         0
`endif
`define BVH_GLOBAL_PRIMITIVE_START_IDX      `BVH_MODEL_RAW_DATA_SIZE
`define BVH_AABB_RAW_DATA_SIZE              `BVH_MODEL_RAW_DATA_SIZE + 10
`define BVH_SPHERE_RAW_DATA_SIZE            4

// Thread Generator ------------------------------------------------------
`define MULTI_ISSUE                         1

// Ray Core --------------------------------------------------------------
//`define IMPLEMENT_SHADOWING                 1
`define IMPLEMENT_REFLECTION                1
//`define IMPLEMENT_REFRACTION                1
`define IMPLEMENT_BVH_TRAVERSAL             1

//`define DEBUG_CORE                          1
`define RAY_CORE_SIZE_WIDTH                 0
`define RAY_CORE_SIZE                       2**`RAY_CORE_SIZE_WIDTH

`define AABB_TEST_UNIT_SIZE_WIDTH           0
`define AABB_TEST_UNIT_SIZE                 2**`AABB_TEST_UNIT_SIZE_WIDTH

`define SPHERE_TEST_UNIT_SIZE_WIDTH         0
`define SPHERE_TEST_UNIT_SIZE               2**`SPHERE_TEST_UNIT_SIZE_WIDTH


// Ray tracing level -----------------------------------------------------
`define BOUNCE_LEVEL_WIDTH                  4
`define BOUNCE_LEVEL                        [`BOUNCE_LEVEL_WIDTH-1:0]
`define RS_MAX_BOUNCE_LEVEL                 3//0


// Configuration >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
typedef struct {
    logic [15:0] LED;
    logic [15:0] Number;    
    // UART tx signal, connected to host-PC's UART-RXD, baud=115200 @ 50MHz    
    logic UARTDataValid;
    logic [7:0] UARTData;
} DebugData;

typedef enum logic [3:0] {
   State_Ready              = 4'd0, 
   State_Busy               = 4'd1,
   State_Done               = 4'd2
} State;

typedef struct {
    logic [`FIXED_WIDTH-1:0] Value;    
} Fixed;

typedef struct {
    Fixed Dim[3];        
} Fixed3;

typedef struct {
    logic [`FIXED_NORM_WIDTH-1:0] Value;    
} FixedNorm;

typedef struct {
    FixedNorm Dim[3];        
} FixedNorm3;

typedef struct {
    logic [3:0] Channel[3];            
} RGB4;

typedef struct {
    logic [3:0] Channel[4];            
} RGBA4;

typedef struct {
    logic [7:0] Channel[3];                
} RGB8;

function automatic RGB8 _RGB8(
    input [7:0] r,
    input [7:0] g,
    input [7:0] b
    );
    begin
        _RGB8.Channel[0] = r;
        _RGB8.Channel[1] = g;
        _RGB8.Channel[2] = b;
    end    
endfunction 

typedef struct {
    logic [7:0] Channel[4];            
} RGBA8;

typedef enum logic [3:0] {
   MRUT_FrameBuffer         = 4'd0, 
   MRUT_BVHStructure        = 4'd1   
} MemoryRequestUnitType;

typedef struct {
    logic [ADDR_WIDTH-1:0] Address;
    logic [2:0] BlockCount; // 1 ~ 4 : Write size = 128 bits * BlockCount
    MemoryRequestUnitType ID;
} MemoryReadTask;

typedef struct {
    logic [2:0] BlockCount; // 1 ~ 4 : Write size = 128 bits * BlockCount
    logic [`MC_CACHE_DATA_WIDTH-1:0] Data[`MC_CACHE_BLOCK_SIZE];
    logic [ADDR_WIDTH-1:0] Address;        
} MemoryWriteTask;

typedef struct {
    logic [`MC_CACHE_DATA_WIDTH-1:0] Data[`MC_CACHE_BLOCK_SIZE];
    MemoryRequestUnitType ID;    
    logic Valid;
} MemoryReadData;

typedef struct {
    logic ReadStrobe;        
    logic [ADDR_WIDTH-1:0] ReadAddress;    
    logic [2:0] BlockCount; // 1 ~ 4 : Write size = 128 bits * BlockCount
    MemoryRequestUnitType ReadID;
} MemoryReadRequest;

typedef struct {
    logic WriteStrobe;
    logic [2:0] BlockCount; // 1 ~ 4 : Write size = 128 bits * BlockCount
    logic [`MC_CACHE_DATA_WIDTH-1:0] WriteData[`MC_CACHE_BLOCK_SIZE];
    logic [ADDR_WIDTH-1:0] WriteAddress;    
} MemoryWriteRequest;

typedef struct {
    logic [`MC_CACHE_SET_SIZE_WIDTH-1:0] CacheSet;
    logic `SCREEN_COORD x, y;    
} CacheWriteElement;

typedef enum logic [3:0] {
    MCS_Init                = 4'd0, 
    MCS_Wait                = 4'd1, 
    MCS_Write_Init          = 4'd2,
    MCS_Write               = 4'd3,
    MCS_Read_Init           = 4'd4,    
    MCS_Read                = 4'd5,    
    MCS_Read_Wait           = 4'd6    
} MemoryControllerState;

typedef enum logic [3:0] {
    BUS_Init                = 4'd0,     
    BUS_GetNode             = 4'd1, 
    BUS_ProcessNode         = 4'd2, 
    BUS_Done                = 4'd3    
} BVHUnitState;

typedef enum logic [3:0] {
    RS_Init                 = 4'd0, 
    RS_FrameSetup           = 4'd1, 
    RS_RenderStateSetup     = 4'd2, 
    RS_Render               = 4'd3, 
    RS_Wait_VSync           = 4'd4    
} RendererState;

typedef enum logic [5:0] {
    RSS_Init                = 4'd0,
    RSS_InitCameraSetup     = 4'd1,
    RSS_SetupCameraU        = 4'd2, 
    RSS_SetupCameraV        = 4'd3, 
    RSS_SetupCameraW        = 4'd4,
    RSS_SetupCameraBLC      = 4'd5,         
    RSS_Done                = 4'd6    
} RenderStateState;

typedef struct {
    Fixed VPW, VPH;
    Fixed3 Pos;
	Fixed3 Look;
    Fixed FocusDist;
    Fixed3 U, V, W;
	Fixed3 BLC, RH, RV;
    Fixed3 dU, dV;
	Fixed CUB, CVB;
} Camera;	

typedef struct {
    Fixed3 Dir;
    Fixed3 InvDir;
    FixedNorm3 NormDir;    
    RGB8 Color;      
} Light;

typedef struct {
    Camera Camera;
    logic `SCREEN_COORD ViewportWidth, ViewportHeight;
	RGB8 ClearColor;
    logic Lighting;
    logic Shadow;
    Light Light[1];
    logic `BOUNCE_LEVEL MaxBounceLevel;
    Fixed3 PositionOffset;
    Fixed3 PositionOffset2;
} RenderState;	
	
typedef struct {
    Fixed3 Min;
    Fixed3 Max;            
} AABB;

typedef struct {
    Fixed3 Center;
    Fixed Radius;            
} Sphere;

typedef struct {
    Fixed3 P[3];    
} Triangle;

typedef enum logic [1:0] {
    Null_Ray                = 2'd0, 
    Surface_Ray             = 2'd1, 
    Shadow_Ray              = 2'd2     
} RayType;

typedef struct {
    logic `PRIMITIVE_INDEX PI;    
    Fixed3 Orig;
    Fixed3 Dir;
    Fixed3 InvDir;
    Fixed MinT;
    Fixed MaxT;        
} Ray;

typedef enum logic [1:0] {
    PT_AABB                 = 2'd0,
    PT_Sphere               = 2'd1,
    ST_Triangle             = 2'd2     
} PrimitiveType;

typedef enum logic [1:0] {
    ST_None                 = 2'd0,
    ST_Lambertian           = 2'd1,
    ST_Metal                = 2'd2, 
    ST_Dielectric           = 2'd3
} SurfaceType;

typedef struct {    
    logic bHit;
    Fixed T;
    FixedNorm3 Normal;  
    RGB8 Color;    
    logic `PRIMITIVE_INDEX PI;      
    SurfaceType SurfaceType;
} HitData;

typedef enum logic [3:0] {
    QM_Node                 = 4'd0,     
    QM_Leaf                 = 4'd1, 
    QM_Primitive            = 4'd2     
} BVHQueryMode;

typedef struct {
    AABB Aabb;   
    logic [`BVH_NODE_INDEX_WIDTH-1:0] Nodes[2];
} BVH_Node;

typedef struct {
    AABB Aabb;      
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] StartPrimitive;
    logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] NumPrimitives;
} BVH_Leaf;

typedef struct {
    AABB Aabb;      
    RGB8 Color;      
    logic `PRIMITIVE_INDEX PI;      
    SurfaceType SurfaceType;
} BVH_Primitive_AABB;

typedef struct {
    Sphere Sphere;      
    RGB8 Color;      
    logic `PRIMITIVE_INDEX PI;      
    SurfaceType SurfaceType;
} BVH_Primitive_Sphere;

typedef struct {
    Triangle Triangle;      
    RGB8 Color;      
    logic `PRIMITIVE_INDEX PI;      
    SurfaceType SurfaceType;
} BVH_Primitive_Triangle;

typedef struct {
    PrimitiveType PrimType;
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] StartPrimitive;
    logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] NumPrimitives;
} PrimitiveGroup;

typedef struct {
    PrimitiveGroup Groups[16];
    logic [3:0] Top;
    logic [3:0] Bottom;
} PrimitiveGroupFIFO;

// Ray Core >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
typedef enum logic [3:0] {
    DCS_Init                = 4'd0,     
    DCS_Render              = 4'd1,     
    DCS_Done                = 4'd2    
} DebugCoreState;

typedef enum logic [3:0] {
    RGS_Init                = 4'd0,     
    RGS_Generate            = 4'd1,     
    RGS_Done                = 4'd2    
} RayGeneratorState;

// Thread Generator -------------------------------------------
typedef enum logic [3:0] {
    TGS_Init                = 4'd0, 
    TGS_Wait                = 4'd1,
    TGS_Generate            = 4'd2,         
    TGS_NextThread          = 4'd3,
    TGS_Debug               = 4'd4          
} ThreadGeneratorState;

typedef struct { 
    RGB8 LastColor;
    logic `BOUNCE_LEVEL BounceLevel;
    logic `SCREEN_COORD x, y;
    Ray SurfaceRay;        
} SurfaceInputData;

typedef struct { 
    logic DataValid;       
    SurfaceInputData RayCoreInput;
} ThreadData;

// Surface Stage -----------------------------------------------------
typedef enum logic [3:0] {
    SURFS_Init              = 4'd0,    
    SURFS_Surfacing         = 4'd1,     
    SURFS_Done              = 4'd2
} SurfaceState;

typedef struct { 
    RGB8 LastColor;
    logic `BOUNCE_LEVEL BounceLevel;
    logic `SCREEN_COORD x, y;
    Fixed3 ViewDir;    
    logic `PRIMITIVE_INDEX PI;    
    Fixed3 HitPos;             
    RGB8 Color;
    FixedNorm3 Normal;    
    SurfaceType SurfaceType;
    Ray ShadowRay;
} SurfaceOutputData;

// Shdow Stage -----------------------------------------------------
typedef enum logic [3:0] {
    SHDWS_Init              = 4'd0,    
    SHDWS_AnyHit            = 4'd1, 
    SHDWS_GenOutput         = 4'd2,
    SHDWS_Done              = 4'd3
} ShadowState;

typedef struct {         
    RGB8 LastColor;
    logic `BOUNCE_LEVEL BounceLevel;
    logic `SCREEN_COORD x, y; 
    Fixed3 ViewDir;       
    logic `PRIMITIVE_INDEX PI;   
    Fixed3 HitPos; 
    RGB8 Color;
    FixedNorm3 Normal;        
    SurfaceType SurfaceType;
    logic bShadow;
} ShadowOutputData;

// Shade Stage-----------------------------------------------------
typedef enum logic [3:0] {
    SS_Init                 = 4'd0,
    SS_Combine              = 4'd1, 
    SS_Surface              = 4'd2,     
    SS_RefractDir           = 4'd3,     
    SS_RefDone              = 4'd4,
    SS_RefractDone          = 4'd5,
    SS_Done                 = 4'd6
} ShadeState;

typedef struct {    
    logic `SCREEN_COORD x, y;
    RGB8 Color;    
} ShadeOutputData;

`endif
