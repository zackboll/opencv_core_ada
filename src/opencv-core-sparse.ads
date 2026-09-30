with Ada.Finalization;
private with OpenCV.Internal.C_API;

package OpenCV.Core.Sparse is
   type Sparse_Mat is tagged private;

   function Create
     (Shape : Dimension_Array; Element_Type : Mat_Type) return Sparse_Mat;
   function From_Dense (Source : Mat) return Sparse_Mat;
   function To_Dense (Self : Sparse_Mat) return Mat;
   --  Native SparseMat::convertTo into an independent Sparse_Mat. Shape and
   --  channel count are preserved. Only stored nodes are converted, including
   --  an explicitly stored zero; missing coordinates stay missing. Each stored
   --  component becomes saturate_cast (source * Scale) at Depth. There is no
   --  offset. Scale 1.0 uses OpenCV's unscaled conversion. Float16 is not a
   --  supported source or destination: OpenCV 4.1 through 5.0 leave both
   --  directions null in the sparse conversion tables, and this binding does
   --  not substitute a Float32 fallback. Float16 Get/Set bit preservation is
   --  unchanged.
   function Convert_To
     (Self : Sparse_Mat; Depth : Depth_Type; Scale : Long_Float := 1.0)
      return Sparse_Mat;
   --  Native SparseMat::convertTo into an independent dense Mat. Shape and
   --  channel count are preserved. A stored component becomes
   --  saturate_cast (source * Scale + Offset). A missing element is
   --  initialized with OpenCV Scalar (Offset): channel 0 receives Offset and
   --  every later channel receives 0, because Scalar supplies one value and
   --  three zeros. Float16 source and destination depths are rejected for the
   --  same OpenCV 4.1-5.0 table gap as Convert_To. On OpenCV 5, dimension
   --  counts above the native dense Mat capacity are rejected before
   --  conversion.
   function To_Dense
     (Self   : Sparse_Mat;
      Depth  : Depth_Type;
      Scale  : Long_Float := 1.0;
      Offset : Long_Float := 0.0) return Mat;
   --  Native sparse cv::norm over stored nodes only. Missing coordinates
   --  contribute zero and are not created. An explicitly stored zero
   --  contributes zero and remains a node. The matrix is not modified.
   --  Requires an allocated Float32 or Float64 matrix with exactly one
   --  channel. An allocated matrix with no stored nodes returns 0.0.
   --  L1 is the sum of absolute stored values, L2 is the square root of the
   --  sum of their squares, and Infinity is the maximum absolute stored
   --  value. Multi-channel, integer, and Float16 layouts are rejected
   --  before the ABI call. Min_Max is not a sparse norm.
   function Norm (Self : Sparse_Mat; Kind : Norm_Kind := L2) return Long_Float;
   --  Native sparse cv::normalize into an independent Sparse_Mat. Shape,
   --  depth, channel count, and stored-node coordinates are preserved,
   --  including explicitly stored zeros. Values are scaled by
   --  Target_Norm / Norm when that norm exceeds OpenCV's DBL_EPSILON;
   --  otherwise the scale is 0.0 and every stored value becomes zero while
   --  its node remains stored. An allocated matrix with no nodes stays
   --  empty. A negative Target_Norm is native and deterministic: it reverses
   --  the sign of every stored value. The source is unchanged. The same
   --  Float32/Float64 single-channel restriction as Norm applies. Min_Max
   --  normalization is unavailable because shifting implicit zeros would
   --  change sparse semantics.
   function Normalize
     (Self        : Sparse_Mat;
      Target_Norm : Long_Float := 1.0;
      Kind        : Norm_Kind := L2) return Sparse_Mat;
   function Clone (Self : Sparse_Mat) return Sparse_Mat;
   procedure Clear (Self : in out Sparse_Mat);
   function Is_Allocated (Self : Sparse_Mat) return Boolean;
   function Dimension_Count (Self : Sparse_Mat) return Natural;
   function Shape (Self : Sparse_Mat) return Dimension_Array;
   function Extent (Self : Sparse_Mat; Axis : Positive) return Size_Coordinate;
   function Depth (Self : Sparse_Mat) return Depth_Type;
   function Channels (Self : Sparse_Mat) return Channel_Count;
   function Element_Size (Self : Sparse_Mat) return Mat_Size;
   function Channel_Size (Self : Sparse_Mat) return Mat_Size;
   function Stored_Element_Count (Self : Sparse_Mat) return Mat_Size;
   function Contains (Self : Sparse_Mat; Indices : Index_Array) return Boolean;
   procedure Erase (Self : in out Sparse_Mat; Indices : Index_Array);

private
   type Sparse_Mat is new Ada.Finalization.Controlled with record
      Handle : OpenCV.Internal.C_API.Sparse_Mat_Handle :=
        OpenCV.Internal.C_API.Null_Sparse_Mat_Handle;
   end record;
   overriding
   procedure Initialize (Self : in out Sparse_Mat);
   overriding
   procedure Adjust (Self : in out Sparse_Mat);
   overriding
   procedure Finalize (Self : in out Sparse_Mat);

   procedure Check_Indices (Self : Sparse_Mat; Indices : Index_Array);
   --  Require an allocated matrix whose runtime depth and channel count
   --  both match the typed access package exactly.
   procedure Check_Layout
     (Self              : Sparse_Mat;
      Indices           : Index_Array;
      Expected          : Depth_Type;
      Expected_Channels : Channel_Count := 1);
   procedure Check_Layout
     (Self              : Sparse_Mat;
      Expected          : Depth_Type;
      Expected_Channels : Channel_Count := 1);
   function C_Indices
     (Indices : Index_Array) return OpenCV.Internal.C_API.C_Int32_Array;
   procedure Check (Status : OpenCV.Internal.C_API.Status; Operation : String);
end OpenCV.Core.Sparse;
