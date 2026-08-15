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

   function Create
     (Rows, Columns : Natural; Element_Type : Mat_Type) return Mat
   with Pre => Rows <= 2_147_483_647 and then Columns <= 2_147_483_647;

   function Create (Dimensions : Size; Element_Type : Mat_Type) return Mat;

   --  Both operations create a distinct Mat header sharing Self's storage.
   --  Depth and total scalar storage are preserved; Columns is derived.
   function Reshape (Self : Mat; Channels : Channel_Count) return Mat;
   function Reshape
     (Self : Mat; Channels : Channel_Count; Rows : Positive) return Mat;

   function Clone (Self : Mat) return Mat;
   function Convert_To
     (Self   : Mat;
      Depth  : Depth_Type;
      Scale  : Long_Float := 1.0;
      Offset : Long_Float := 0.0) return Mat;
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
   function Add_Weighted
     (Left  : Mat;
      Alpha : Long_Float;
      Right : Mat;
      Beta  : Long_Float;
      Gamma : Long_Float := 0.0) return Mat;
   function Bitwise_And (Left, Right : Mat) return Mat;
   function Bitwise_And (Left, Right, Mask : Mat) return Mat;
   function Bitwise_Or (Left, Right : Mat) return Mat;
   function Bitwise_Or (Left, Right, Mask : Mat) return Mat;
   function Bitwise_Xor (Left, Right : Mat) return Mat;
   function Bitwise_Xor (Left, Right, Mask : Mat) return Mat;
   function Bitwise_Not (Self : Mat) return Mat;
   function Bitwise_Not (Self, Mask : Mat) return Mat;
   function In_Range (Self : Mat; Lower, Upper : Scalar) return Mat;
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
   function Sum (Self : Mat) return Scalar;
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
   function Min_Max_Loc (Self : Mat) return Min_Max_Result;

   --  Counts nonzero scalar elements. Supports single-channel Mats of any
   --  supported depth (including Float16). Rejects multi-channel Mats.
   --  Non-contiguous views are supported. Empty Mat returns 0.
   function Count_Non_Zero (Self : Mat) return Mat_Size;

   --  Returns true if a single-channel Mat contains at least one nonzero
   --  element. Supports non-contiguous views. Rejects multi-channel Mats.
   --  Empty Mat returns false.
   function Has_Non_Zero (Self : Mat) return Boolean;
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
