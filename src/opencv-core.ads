with Ada.Finalization;
with Interfaces;
private with OpenCV.Internal.C_API;

package OpenCV.Core is

   type Depth_Type is
     (UInt8, Int8, UInt16, Int16, Int32, Float32, Float64, Float16);

   type Norm_Kind is (L1, L2, Infinity);

   --  Min_Max is a normalization mode rather than a Mat.Norm reduction kind.
   type Normalize_Kind is (L1, L2, Infinity, Min_Max);

   type Comparison_Kind is
     (Equal,
      Not_Equal,
      Less_Than,
      Less_Or_Equal,
      Greater_Than,
      Greater_Or_Equal);

   type Flip_Kind is (Vertical, Horizontal, Both_Axes);

   type Border_Kind is
     (Constant_Border, Replicate, Reflect, Reflect_101, Wrap);

   type Rotation_Kind is (Clockwise_90, Half_Turn, Counterclockwise_90);

   type Reduction_Axis is (Across_Rows, Across_Columns);

   type Reduction_Kind is (Sum, Average, Maximum, Minimum, Sum_Of_Squares);

   type Channel_Count is new Interfaces.Integer_32 range 1 .. 512;

   type Mat_Size is
     new Interfaces.Integer_64 range 0 .. Interfaces.Integer_64'Last;

   type Size_Coordinate is
     new Interfaces.Integer_32 range 0 .. Interfaces.Integer_32'Last;

   type Point_Coordinate is new Interfaces.Integer_32;

   --  A zero-based half-open index interval: Start <= index < Stop.
   type Index_Range is record
      Start : Size_Coordinate := 0;
      Stop  : Size_Coordinate := 0;
   end record;

   type Size is record
      Width  : Size_Coordinate := 0;
      Height : Size_Coordinate := 0;
   end record;

   type Point is record
      X : Point_Coordinate := 0;
      Y : Point_Coordinate := 0;
   end record;

   --  A zero-based, value-semantic sequence of points. An empty result has
   --  the null range 1 .. 0.
   type Point_Array is array (Natural range <>) of Point;

   --  CV_8U and CV_32F element value domains used by typed Mat accessors.
   subtype UInt8_Value is Interfaces.Unsigned_8;
   subtype Float32_Value is Interfaces.IEEE_Float_32;

   type Mat_Type is record
      Depth    : Depth_Type;
      Channels : Channel_Count;
   end record;

   type Scalar is record
      Component_0 : Long_Float := 0.0;
      Component_1 : Long_Float := 0.0;
      Component_2 : Long_Float := 0.0;
      Component_3 : Long_Float := 0.0;
   end record;

   type Min_Max_Result is record
      Minimum          : Long_Float;
      Maximum          : Long_Float;
      Minimum_Location : Point;
      Maximum_Location : Point;
   end record;

   type Mean_Std_Dev_Result is record
      Mean               : Scalar;
      Standard_Deviation : Scalar;
   end record;

   type Rect is record
      X      : Size_Coordinate := 0;
      Y      : Size_Coordinate := 0;
      Width  : Size_Coordinate := 0;
      Height : Size_Coordinate := 0;
   end record;

   function Make_Scalar
     (Component_0 : Long_Float;
      Component_1 : Long_Float := 0.0;
      Component_2 : Long_Float := 0.0;
      Component_3 : Long_Float := 0.0) return Scalar;

   type Mat is tagged private;

   --  A zero-based, owning sequence of Mats. An empty result has the null
   --  range 1 .. 0. Each element has normal Mat controlled ownership and
   --  shallow-copy assignment semantics.
   type Mat_Array is array (Natural range <>) of Mat;

   type Channel_Source_Kind is (From_Source, Zero_Fill);

   --  Source_Index and Destination_Index are the actual indices of Sources
   --  and Destinations, respectively. Channel indices are zero-based within
   --  their selected Mat. Zero_Fill writes zero to the destination channel.
   type Channel_Route (Source_Kind : Channel_Source_Kind := From_Source) is
   record
      Destination_Index   : Natural;
      Destination_Channel : Natural;
      case Source_Kind is
         when From_Source =>
            Source_Index   : Natural;
            Source_Channel : Natural;

         when Zero_Fill =>
            null;
      end case;
   end record;

   type Channel_Route_Array is array (Natural range <>) of Channel_Route;

   function Create
     (Rows, Columns : Natural; Element_Type : Mat_Type) return Mat
   with Pre => Rows <= 2_147_483_647 and then Columns <= 2_147_483_647;

   function Create (Dimensions : Size; Element_Type : Mat_Type) return Mat;

   --  Creates an independent square matrix with Diagonal on its main diagonal
   --  and zero in every off-diagonal element. Diagonal must be a row or column
   --  vector. The result preserves Diagonal's depth and channel count.
   function Diagonal_Matrix (Diagonal : Mat) return Mat;

   --  Both operations create a distinct Mat header sharing Self's storage.
   --  Depth and total scalar storage are preserved; Columns is derived.
   function Reshape (Self : Mat; Channels : Channel_Count) return Mat;
   function Reshape
     (Self : Mat; Channels : Channel_Count; Rows : Positive) return Mat;

   --  Creates a distinct single-column Mat header sharing Self's storage for
   --  the selected diagonal. Offset zero selects the main diagonal; positive
   --  offsets select diagonals above it (Offset 1 starts at row 0, column 1),
   --  and negative offsets select diagonals below it (Offset -1 starts at row
   --  1, column 0). Offset must select at least one element.
   function Diagonal_View
     (Self : Mat; Offset : Point_Coordinate := 0) return Mat;

   function Clone (Self : Mat) return Mat;
   --  Returns an independent Mat whose rows and columns are swapped. Element
   --  depth and channel count are preserved, including for multi-channel Mats.
   --  Empty Mats produce an empty result. Non-contiguous Regions are accepted.
   function Transpose (Self : Mat) return Mat;
   --  Returns an independent Mat with the same dimensions and element type as
   --  Self. Vertical reverses row order, Horizontal reverses column order,
   --  and Both_Axes reverses both. Empty Mats produce an empty result.
   --  Non-contiguous Regions are accepted.
   function Flip (Self : Mat; Kind : Flip_Kind) return Mat;
   --  Returns an independent Mat with a border of the requested thickness.
   --  Constant uses Value; other border kinds extrapolate source pixels.
   --  When Self is a Region, Isolated is false by default so OpenCV may use
   --  pixels from its parent Mat. Isolated true restricts extrapolation to the
   --  Region boundaries. Empty Mats produce an empty result when every border
   --  is zero.
   function Copy_Make_Border
     (Self     : Mat;
      Top      : Natural;
      Bottom   : Natural;
      Left     : Natural;
      Right    : Natural;
      Kind     : Border_Kind;
      Value    : Scalar := (others => 0.0);
      Isolated : Boolean := False) return Mat;
   --  Separates Self into one independent single-channel Mat per channel.
   --  Results use channel indices 0 .. Self.Channels - 1, preserve Self's
   --  depth and dimensions, and do not share pixel storage with Self. Empty
   --  Mats return an empty Mat_Array. Single-channel Mats return one deep
   --  copy.
   --  Non-contiguous Regions and all supported Mat depths are accepted.
   function Split (Self : Mat) return Mat_Array;
   --  Returns an independent single-channel Mat containing the zero-based
   --  Channel of Self. Channel must be in 0 .. Self.Channels - 1. The result
   --  preserves Self's depth and dimensions, and does not share pixel storage
   --  with Self. Non-contiguous Regions and all supported Mat depths are
   --  accepted. An empty Mat accepts channel 0 and returns an empty,
   --  single-channel UInt8 Mat, matching OpenCV semantics.
   function Extract_Channel (Self : Mat; Channel : Natural) return Mat;
   --  Copies the single channel in Source into the zero-based Channel of Self.
   --  Source and Self must have identical dimensions and depth; Channel must
   --  be in 0 .. Self.Channels - 1. Self is modified in place, preserving its
   --  dimensions and element type. Non-contiguous Regions are accepted and
   --  retain normal shared-storage view semantics. Empty UInt8 single-channel
   --  Mats accept channel 0 as a no-op, matching OpenCV semantics.
   procedure Insert_Channel
     (Self : in out Mat; Source : Mat; Channel : Natural);
   --  Copies or zero-fills the specified channels into preallocated
   --  Destinations. Mat indices in Routes directly index the supplied arrays;
   --  their lower bounds need not be zero. All source and destination Mats
   --  must have identical dimensions and depth. A destination channel may
   --  occur in at most one route. Routes are applied in array iteration order.
   --  An empty Routes array is a no-op.
   procedure Mix_Channels
     (Sources      : Mat_Array;
      Destinations : in out Mat_Array;
      Routes       : Channel_Route_Array);
   --  Concatenates the channels of every non-empty input Mat, in array
   --  iteration order, into an independent Mat. Inputs may themselves be
   --  multi-channel, but must have identical dimensions and depth. The input
   --  array must not be empty and the total channel count must not exceed 512.
   function Merge (Channels : Mat_Array) return Mat;
   --  Copies Self into Destination, allocating or reallocating Destination to
   --  Self's shape and element type when necessary. Destination may be a
   --  compatible view. Exact self-copy is supported; partially overlapping
   --  source and destination storage is not supported by OpenCV.
   procedure Copy_To (Self : Mat; Destination : in out Mat);
   --  Copies elements selected by Mask into Destination. Mask uses the common
   --  mask contract (UInt8, one channel, same shape as Self). Any nonzero mask
   --  value selects the complete element, including every channel. Unselected
   --  elements retain their values in a compatible Destination; if Destination
   --  is allocated or reallocated, they are initialized to zero.
   procedure Copy_To (Self : Mat; Destination : in out Mat; Mask : Mat);
   function Convert_To
     (Self   : Mat;
      Depth  : Depth_Type;
      Scale  : Long_Float := 1.0;
      Offset : Long_Float := 0.0) return Mat;
   --  Returns an independent UInt8 Mat with Self's shape and channel count.
   --  Each channel is converted as saturate_cast<UInt8>
   --  (abs (Self * Scale + Offset)).
   function Convert_Scale_Abs
     (Self : Mat; Scale : Long_Float := 1.0; Offset : Long_Float := 0.0)
      return Mat;
   --  Applies a 256-entry lookup table to an 8-bit source. Self must have
   --  UInt8 or Int8 depth. Table must contain exactly 256 continuous
   --  elements and either one channel or the same channel count as Self.
   --  The result has Self's shape and channel count and Table's depth, and
   --  owns independent storage. Int8 sources are indexed by their stored
   --  8-bit pattern (0 .. 255), matching OpenCV 4.10.0. Float16 tables and
   --  16-bit sources are not supported. A 0x0 8-bit source produces a 0x0
   --  result; a default empty Mat is rejected by OpenCV.
   function Apply_LUT (Self : Mat; Table : Mat) return Mat;

   --  Returns an independent Mat with Self's shape and element type.  For L1,
   --  L2, and Infinity, Alpha is the target norm and Beta is ignored.  For
   --  Min_Max, Alpha and Beta specify the destination range bounds.
   function Normalize
     (Self  : Mat;
      Kind  : Normalize_Kind := L2;
      Alpha : Long_Float := 1.0;
      Beta  : Long_Float := 0.0) return Mat;
   --  Both operands must have identical 2D shape and element type.  Each
   --  result owns independent storage and preserves that element type.
   function Add (Left, Right : Mat) return Mat;
   function Subtract (Left, Right : Mat) return Mat;
   function Multiply (Left, Right : Mat) return Mat;
   function Divide (Left, Right : Mat) return Mat;
   function Abs_Diff (Left, Right : Mat) return Mat;
   function Minimum (Left, Right : Mat) return Mat;
   function Maximum (Left, Right : Mat) return Mat;
   function Add_Weighted
     (Left  : Mat;
      Alpha : Long_Float;
      Right : Mat;
      Beta  : Long_Float;
      Gamma : Long_Float := 0.0) return Mat;
   --  Returns an independent Mat with Self's shape and element type.
   --  Each element is Self * Scale + Right. Depths below Float32 use
   --  OpenCV's addWeighted path: UInt8, Int8, UInt16, and Int16 saturate;
   --  Int32 does not. Float32 and Float64 use the dedicated scaleAdd
   --  kernels. Float16 is not supported by OpenCV.
   --  Both operands must have identical 2D shape and element type.
   function Scale_Add (Self : Mat; Scale : Long_Float; Right : Mat) return Mat;

   function Bitwise_And (Left, Right : Mat) return Mat;
   function Bitwise_And (Left, Right, Mask : Mat) return Mat;
   function Bitwise_Or (Left, Right : Mat) return Mat;
   function Bitwise_Or (Left, Right, Mask : Mat) return Mat;
   function Bitwise_Xor (Left, Right : Mat) return Mat;
   function Bitwise_Xor (Left, Right, Mask : Mat) return Mat;
   function Bitwise_Not (Self : Mat) return Mat;
   function Bitwise_Not (Self, Mask : Mat) return Mat;
   function In_Range (Self : Mat; Lower, Upper : Scalar) return Mat;
   --  Returns an independent Mat rotated by Kind.  90-degree rotations
   --  exchange rows and columns; a half turn preserves dimensions and every
   --  variant preserves element depth and channel count.
   function Rotate (Self : Mat; Kind : Rotation_Kind) return Mat;
   --  Returns an independent Mat tiled vertically Row_Repetitions times and
   --  horizontally Column_Repetitions times. Element depth and channel count
   --  are preserved. Empty Mats produce an empty result.
   function Repeat
     (Self : Mat; Row_Repetitions : Positive; Column_Repetitions : Positive)
      return Mat;
   --  Concatenates Sources left to right into an independent Mat. Inputs must
   --  have identical row counts and complete element types. Their column
   --  counts may differ. An empty input array produces an empty Mat; empty
   --  individual Mats are accepted when they satisfy the same requirements.
   function HConcat (Sources : Mat_Array) return Mat;
   --  Concatenates Sources top to bottom into an independent Mat. Inputs must
   --  have identical column counts and complete element types. Their row
   --  counts may differ. An empty input array produces an empty Mat; empty
   --  individual Mats are accepted when they satisfy the same requirements.
   function VConcat (Sources : Mat_Array) return Mat;
   --  Both operands must be single-channel with identical rows, columns, and
   --  depth.  The result is an independent UInt8 single-channel mask with 255
   --  where the comparison is true and 0 otherwise, suitable for masked ops.
   function Compare (Left, Right : Mat; Kind : Comparison_Kind) return Mat;
   function Is_Empty (Self : Mat) return Boolean;
   function Rows (Self : Mat) return Natural;
   function Columns (Self : Mat) return Natural;

   --  Composed from the established column and row queries: Width = Columns,
   --  Height = Rows.  No separate C ABI accessor is required.
   function Dimensions (Self : Mat) return Size;
   function Channels (Self : Mat) return Channel_Count;
   function Depth (Self : Mat) return Depth_Type;
   function Total (Self : Mat) return Mat_Size;
   function Element_Size (Self : Mat) return Mat_Size;
   function Channel_Size (Self : Mat) return Mat_Size;
   function Is_Continuous (Self : Mat) return Boolean;
   function Is_Submatrix (Self : Mat) return Boolean;
   function Region (Self : Mat; Area : Rect) return Mat;

   --  These operations create distinct Mat headers sharing Self's storage.
   --  Index_Range uses its direct half-open [Start, Stop) representation.
   function Row_View (Self : Mat; Row : Size_Coordinate) return Mat;
   function Row_View (Self : Mat; Rows : Index_Range) return Mat;
   function Column_View (Self : Mat; Column : Size_Coordinate) return Mat;
   function Column_View (Self : Mat; Columns : Index_Range) return Mat;

   procedure Set_To (Self : in out Mat; Value : Scalar);
   --  Sets elements selected by Mask to Value. Mask uses the common mask
   --  contract (UInt8, one channel, same shape as Self). Any nonzero mask
   --  value selects the complete element, including every channel.
   procedure Set_To (Self : in out Mat; Value : Scalar; Mask : Mat);
   function Sum (Self : Mat) return Scalar;
   --  Returns the per-channel sum of Self's main diagonal. Rectangular and
   --  empty Mats are accepted. Self must have at most four channels, matching
   --  Scalar's complete representation. Float16 Mats are not supported by
   --  OpenCV's trace implementation. Non-contiguous views are accepted.
   function Trace (Self : Mat) return Scalar;
   --  Reduces a two-dimensional Mat independently in every channel.
   --  Across_Rows
   --  produces one row; Across_Columns produces one column. The result owns
   --  independent storage. Without Output_Depth, OpenCV uses Self's depth.
   --  Maximum and Minimum require their output depth to equal Self.Depth.
   function Reduce
     (Self : Mat; Axis : Reduction_Axis; Kind : Reduction_Kind) return Mat;
   function Reduce
     (Self         : Mat;
      Axis         : Reduction_Axis;
      Kind         : Reduction_Kind;
      Output_Depth : Depth_Type) return Mat;
   --  Both reductions operate independently on each channel.  They support
   --  one through four channels, matching Scalar's complete representation.
   --  Mean returns a zero Scalar for an empty Mat; Mean_Std_Dev rejects one.
   function Mean (Self : Mat) return Scalar;
   --  Mean of Self elements selected by Mask. Mask uses the common mask
   --  contract (UInt8, one channel, same shape as Self). Any nonzero mask
   --  value selects the element. An all-zero mask returns a zero Scalar.
   --  Empty Self/Mask follow OpenCV mean semantics (zero Scalar).
   function Mean (Self, Mask : Mat) return Scalar;
   function Mean_Std_Dev (Self : Mat) return Mean_Std_Dev_Result;
   --  Per-channel mean and population standard deviation of Self elements
   --  selected by Mask. Mask uses the common mask contract. Any nonzero mask
   --  value selects the element. An all-zero mask returns zero mean and
   --  standard-deviation Scalars. Empty Self/Mask is rejected.
   function Mean_Std_Dev (Self, Mask : Mat) return Mean_Std_Dev_Result;
   function Norm (Self : Mat; Kind : Norm_Kind := L2) return Long_Float;
   --  Computes the requested norm over elements selected by Mask. Mask uses
   --  the common mask contract (UInt8, one channel, same shape as Self). Any
   --  nonzero mask value selects every scalar component of the element. Empty
   --  Self/Mask and all-zero masks return zero according to OpenCV semantics.
   function Norm
     (Self : Mat; Mask : Mat; Kind : Norm_Kind := L2) return Long_Float;
   function Min_Max_Loc (Self : Mat) return Min_Max_Result;
   --  Finds extrema among Self elements selected by Mask. Mask uses the
   --  common mask contract. Any nonzero mask value selects the element. An
   --  all-zero mask returns zero extrema and (-1, -1) locations. Point.X is
   --  the column and Point.Y is the row.
   function Min_Max_Loc (Self, Mask : Mat) return Min_Max_Result;

   --  Counts nonzero scalar elements. Supports single-channel Mats of any
   --  supported depth (including Float16). Rejects multi-channel Mats.
   --  Non-contiguous views are supported. Empty Mat returns 0.
   function Count_Non_Zero (Self : Mat) return Mat_Size;

   --  Returns true if a single-channel Mat contains at least one nonzero
   --  element. Supports non-contiguous views. Rejects multi-channel Mats.
   --  Empty Mat returns false.
   function Has_Non_Zero (Self : Mat) return Boolean;

   --  Returns locations of all nonzero elements in row-major order. Point.X
   --  is the column and Point.Y is the row. Supports 2-D, single-channel Mats
   --  with UInt8, Int8, UInt16, Int16, Int32, Float32, or Float64 depth;
   --  Float16 and multi-channel Mats are rejected. Empty and all-zero Mats
   --  return an empty Point_Array. Locations for a Region are relative to that
   --  Region rather than to its parent Mat.
   function Find_Non_Zero (Self : Mat) return Point_Array;
private

   type Mat is new Ada.Finalization.Controlled with record
      Handle : OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
   end record;

   overriding
   procedure Initialize (Self : in out Mat);
   overriding
   procedure Adjust (Self : in out Mat);
   overriding
   procedure Finalize (Self : in out Mat);

end OpenCV.Core;
