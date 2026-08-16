with Ada.Exceptions;
with Interfaces.C;

package body OpenCV.Core is

   use type OpenCV.Internal.C_API.C_Boolean;
   use type OpenCV.Internal.C_API.Mat_Handle;
   use type OpenCV.Internal.C_API.C_UInt64;
   use type OpenCV.Internal.C_API.C_Int32;
   use type OpenCV.Internal.C_API.Status;
   use type Interfaces.Integer_64;

   procedure Raise_On_Error
     (Result : OpenCV.Internal.C_API.Status; Operation : String)
   is
      Known_Error : constant Boolean :=
        Result = OpenCV.Internal.C_API.Error_OpenCV
        or else Result = OpenCV.Internal.C_API.Error_Standard_CPP
        or else Result = OpenCV.Internal.C_API.Error_Unknown
        or else Result = OpenCV.Internal.C_API.Error_Invalid_Argument;
   begin
      if Result = OpenCV.Internal.C_API.Success then
         return;
      end if;

      declare
         Diagnostic  : constant String :=
           OpenCV.Internal.C_API.Last_Error_Message;
         Status_Note : constant String :=
           (if Known_Error
            then ""
            else " (unrecognized shim status" & Result'Image & ")");
      begin
         if Diagnostic'Length = 0 then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity, Operation & " failed" & Status_Note);
         else
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               Operation & " failed" & Status_Note & ": " & Diagnostic);
         end if;
      end;
   end Raise_On_Error;

   function To_C_Scalar (Value : Scalar) return OpenCV.Internal.C_API.Scalar
   is (Component_0 => Interfaces.C.double (Value.Component_0),
       Component_1 => Interfaces.C.double (Value.Component_1),
       Component_2 => Interfaces.C.double (Value.Component_2),
       Component_3 => Interfaces.C.double (Value.Component_3));

   function From_C_Scalar (Value : OpenCV.Internal.C_API.Scalar) return Scalar
   is (Component_0 => Long_Float (Value.Component_0),
       Component_1 => Long_Float (Value.Component_1),
       Component_2 => Long_Float (Value.Component_2),
       Component_3 => Long_Float (Value.Component_3));

   function Make_Scalar
     (Component_0 : Long_Float;
      Component_1 : Long_Float := 0.0;
      Component_2 : Long_Float := 0.0;
      Component_3 : Long_Float := 0.0) return Scalar
   is (Component_0 => Component_0,
       Component_1 => Component_1,
       Component_2 => Component_2,
       Component_3 => Component_3);

   function To_C_Depth
     (Value : Depth_Type) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when UInt8   => OpenCV.Internal.C_API.Depth_UInt8,
         when Int8    => OpenCV.Internal.C_API.Depth_Int8,
         when UInt16  => OpenCV.Internal.C_API.Depth_UInt16,
         when Int16   => OpenCV.Internal.C_API.Depth_Int16,
         when Int32   => OpenCV.Internal.C_API.Depth_Int32,
         when Float32 => OpenCV.Internal.C_API.Depth_Float32,
         when Float64 => OpenCV.Internal.C_API.Depth_Float64,
         when Float16 => OpenCV.Internal.C_API.Depth_Float16);

   function To_C_Norm_Kind
     (Value : Norm_Kind) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when L1       => OpenCV.Internal.C_API.Norm_L1,
         when L2       => OpenCV.Internal.C_API.Norm_L2,
         when Infinity => OpenCV.Internal.C_API.Norm_Inf);

   function To_C_Border_Kind
     (Value : Border_Kind) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when Constant_Border => OpenCV.Internal.C_API.Border_Constant,
         when Replicate       => OpenCV.Internal.C_API.Border_Replicate,
         when Reflect         => OpenCV.Internal.C_API.Border_Reflect,
         when Reflect_101     => OpenCV.Internal.C_API.Border_Reflect_101,
         when Wrap            => OpenCV.Internal.C_API.Border_Wrap);

   function To_C_Border_Size
     (Value : Natural) return OpenCV.Internal.C_API.C_Int32
   is (OpenCV.Internal.C_API.C_Int32 (Value));

   function To_C_Normalize_Kind
     (Value : Normalize_Kind) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when L1       => OpenCV.Internal.C_API.Normalize_L1,
         when L2       => OpenCV.Internal.C_API.Normalize_L2,
         when Infinity => OpenCV.Internal.C_API.Normalize_Inf,
         when Min_Max  => OpenCV.Internal.C_API.Normalize_Min_Max);

   function To_C_Comparison_Kind
     (Value : Comparison_Kind) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when Equal            => OpenCV.Internal.C_API.Compare_Equal,
         when Not_Equal        => OpenCV.Internal.C_API.Compare_Not_Equal,
         when Less_Than        => OpenCV.Internal.C_API.Compare_Less_Than,
         when Less_Or_Equal    => OpenCV.Internal.C_API.Compare_Less_Or_Equal,
         when Greater_Than     => OpenCV.Internal.C_API.Compare_Greater_Than,
         when Greater_Or_Equal =>
           OpenCV.Internal.C_API.Compare_Greater_Or_Equal);

   function To_C_Flip_Kind
     (Value : Flip_Kind) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when Vertical   => OpenCV.Internal.C_API.Flip_Vertical,
         when Horizontal => OpenCV.Internal.C_API.Flip_Horizontal,
         when Both_Axes  => OpenCV.Internal.C_API.Flip_Both_Axes);

   function To_C_Rotation_Kind
     (Value : Rotation_Kind) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when Clockwise_90        => OpenCV.Internal.C_API.Rotate_90_Clockwise,
         when Half_Turn           => OpenCV.Internal.C_API.Rotate_180,
         when Counterclockwise_90 =>
           OpenCV.Internal.C_API.Rotate_90_Counterclockwise);

   function To_C_Reduction_Axis
     (Value : Reduction_Axis) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when Across_Rows    => OpenCV.Internal.C_API.Reduce_Across_Rows,
         when Across_Columns => OpenCV.Internal.C_API.Reduce_Across_Columns);

   function To_C_Reduction_Kind
     (Value : Reduction_Kind) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when Sum            => OpenCV.Internal.C_API.Reduce_Sum,
         when Average        => OpenCV.Internal.C_API.Reduce_Average,
         when Maximum        => OpenCV.Internal.C_API.Reduce_Maximum,
         when Minimum        => OpenCV.Internal.C_API.Reduce_Minimum,
         when Sum_Of_Squares => OpenCV.Internal.C_API.Reduce_Sum_Of_Squares);

   function To_Mat_Size
     (Value : OpenCV.Internal.C_API.C_UInt64) return Mat_Size is
   begin
      if Value > OpenCV.Internal.C_API.C_UInt64 (Mat_Size'Last) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat size query returned a value outside the public size range");
      end if;

      return Mat_Size (Value);
   end To_Mat_Size;

   function From_C_Boolean
     (Value : OpenCV.Internal.C_API.C_Boolean; Operation : String)
      return Boolean is
   begin
      if Value = OpenCV.Internal.C_API.C_True then
         return True;
      elsif Value = OpenCV.Internal.C_API.C_False then
         return False;
      else
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " returned an invalid Boolean value");
      end if;
   end From_C_Boolean;

   function From_C_Depth
     (Value : OpenCV.Internal.C_API.C_Int32) return Depth_Type is
   begin
      case Value is
         when OpenCV.Internal.C_API.Depth_UInt8   =>
            return UInt8;

         when OpenCV.Internal.C_API.Depth_Int8    =>
            return Int8;

         when OpenCV.Internal.C_API.Depth_UInt16  =>
            return UInt16;

         when OpenCV.Internal.C_API.Depth_Int16   =>
            return Int16;

         when OpenCV.Internal.C_API.Depth_Int32   =>
            return Int32;

         when OpenCV.Internal.C_API.Depth_Float32 =>
            return Float32;

         when OpenCV.Internal.C_API.Depth_Float64 =>
            return Float64;

         when OpenCV.Internal.C_API.Depth_Float16 =>
            return Float16;

         when others                              =>
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Mat depth query returned an invalid depth identifier");
      end case;
   end From_C_Depth;

   overriding
   procedure Initialize (Self : in out Mat) is
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Result     : OpenCV.Internal.C_API.Status;
   begin
      Result := OpenCV.Internal.C_API.Mat_Create (New_Handle'Access);
      Raise_On_Error (Result, "default Mat construction");
      Self.Handle := New_Handle;
   end Initialize;

   function Create
     (Rows, Columns : Natural; Element_Type : Mat_Type) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Create_2D
          (Rows     => OpenCV.Internal.C_API.C_Int32 (Rows),
           Columns  => OpenCV.Internal.C_API.C_Int32 (Columns),
           Depth    => To_C_Depth (Element_Type.Depth),
           Channels => OpenCV.Internal.C_API.C_Int32 (Element_Type.Channels),
           Result   => New_Handle'Access);
      Raise_On_Error (Status, "2D Mat construction");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Create;

   function Create (Dimensions : Size; Element_Type : Mat_Type) return Mat
   is (Create
         (Rows         => Natural (Dimensions.Height),
          Columns      => Natural (Dimensions.Width),
          Element_Type => Element_Type));

   procedure Validate_Arithmetic_Compatibility (Left, Right : Mat) is
   begin
      if Left.Rows /= Right.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat arithmetic requires operands with identical row counts");
      end if;

      if Left.Columns /= Right.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat arithmetic requires operands with identical column counts");
      end if;

      if Left.Depth /= Right.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat arithmetic requires operands with identical depths");
      end if;

      if Left.Channels /= Right.Channels then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat arithmetic requires operands with identical channel counts");
      end if;
   end Validate_Arithmetic_Compatibility;

   procedure Validate_Mask (Source, Mask : Mat) is
   begin
      if Mask.Depth /= UInt8 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Mat mask must have UInt8 depth");
      end if;

      if Mask.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Mat mask must have exactly one channel");
      end if;

      if Mask.Rows /= Source.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat mask must have the same row count as its source");
      end if;

      if Mask.Columns /= Source.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat mask must have the same column count as its source");
      end if;
   end Validate_Mask;

   procedure Validate_Compare_Compatibility (Left, Right : Mat) is
   begin
      if Left.Channels /= 1 or else Right.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat compare requires single-channel operands");
      end if;

      if Left.Rows /= Right.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat compare requires operands with identical row counts");
      end if;

      if Left.Columns /= Right.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat compare requires operands with identical column counts");
      end if;

      if Left.Depth /= Right.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat compare requires operands with identical depths");
      end if;
   end Validate_Compare_Compatibility;

   function Add (Left, Right : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Add
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat addition operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Add;

   function Subtract (Left, Right : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Subtract
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat subtraction operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Subtract;

   function Multiply (Left, Right : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Multiply
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat multiplication operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Multiply;

   function Divide (Left, Right : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Divide
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat division operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Divide;

   function Abs_Diff (Left, Right : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Abs_Diff
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat absolute difference operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Abs_Diff;

   function Minimum (Left, Right : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Minimum
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat minimum operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Minimum;

   function Maximum (Left, Right : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Maximum
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat maximum operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Maximum;

   function Add_Weighted
     (Left  : Mat;
      Alpha : Long_Float;
      Right : Mat;
      Beta  : Long_Float;
      Gamma : Long_Float := 0.0) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Add_Weighted
          (Left   => Left.Handle,
           Alpha  => OpenCV.Internal.C_API.C_Double (Alpha),
           Right  => Right.Handle,
           Beta   => OpenCV.Internal.C_API.C_Double (Beta),
           Gamma  => OpenCV.Internal.C_API.C_Double (Gamma),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat weighted addition operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Add_Weighted;

   function Scale_Add (Self : Mat; Scale : Long_Float; Right : Mat) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Self, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Scale_Add
          (Left   => Self.Handle,
           Scale  => OpenCV.Internal.C_API.C_Double (Scale),
           Right  => Right.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat scale-add operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Scale_Add;

   function Bitwise_And (Left, Right : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Bitwise_And
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat bitwise and operation");
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Bitwise_And;

   function Bitwise_And (Left, Right, Mask : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Validate_Mask (Left, Mask);
      Status :=
        OpenCV.Internal.C_API.Mat_Bitwise_And_Masked
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Mask   => Mask.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Masked Mat bitwise and operation");
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Bitwise_And;

   function Bitwise_Or (Left, Right : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Bitwise_Or
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat bitwise or operation");
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Bitwise_Or;

   function Bitwise_Or (Left, Right, Mask : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Validate_Mask (Left, Mask);
      Status :=
        OpenCV.Internal.C_API.Mat_Bitwise_Or_Masked
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Mask   => Mask.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Masked Mat bitwise or operation");
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Bitwise_Or;

   function Bitwise_Xor (Left, Right : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Bitwise_Xor
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat bitwise xor operation");
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Bitwise_Xor;

   function Bitwise_Xor (Left, Right, Mask : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arithmetic_Compatibility (Left, Right);
      Validate_Mask (Left, Mask);
      Status :=
        OpenCV.Internal.C_API.Mat_Bitwise_Xor_Masked
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Mask   => Mask.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Masked Mat bitwise xor operation");
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Bitwise_Xor;

   function Bitwise_Not (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Bitwise_Not (Self.Handle, New_Handle'Access);
      Raise_On_Error (Status, "Mat bitwise not operation");
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Bitwise_Not;

   function Bitwise_Not (Self, Mask : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Mask (Self, Mask);
      Status :=
        OpenCV.Internal.C_API.Mat_Bitwise_Not_Masked
          (Self   => Self.Handle,
           Mask   => Mask.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Masked Mat bitwise not operation");
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Bitwise_Not;

   function In_Range (Self : Mat; Lower, Upper : Scalar) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      C_Lower    : aliased OpenCV.Internal.C_API.Scalar := To_C_Scalar (Lower);
      C_Upper    : aliased OpenCV.Internal.C_API.Scalar := To_C_Scalar (Upper);
      Status     : OpenCV.Internal.C_API.Status;
   begin
      if Self.Channels > 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Scalar-bounded In_Range supports Mats with at most four"
            & " channels");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_In_Range_Scalar
          (Self   => Self.Handle,
           Lower  => C_Lower'Access,
           Upper  => C_Upper'Access,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat scalar-bounded in-range operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end In_Range;

   function Compare (Left, Right : Mat; Kind : Comparison_Kind) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Compare_Compatibility (Left, Right);
      Status :=
        OpenCV.Internal.C_API.Mat_Compare
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Kind   => To_C_Comparison_Kind (Kind),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat compare operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Compare;

   function Normalize
     (Self  : Mat;
      Kind  : Normalize_Kind := L2;
      Alpha : Long_Float := 1.0;
      Beta  : Long_Float := 0.0) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Normalize
          (Source => Self.Handle,
           Kind   => To_C_Normalize_Kind (Kind),
           Alpha  => OpenCV.Internal.C_API.C_Double (Alpha),
           Beta   => OpenCV.Internal.C_API.C_Double (Beta),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat normalization operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Normalize;

   overriding
   procedure Adjust (Self : in out Mat) is
      Source_Handle : constant OpenCV.Internal.C_API.Mat_Handle := Self.Handle;
      New_Handle    : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
   begin
      Self.Handle := OpenCV.Internal.C_API.Null_Mat_Handle;

      declare
         Result : constant OpenCV.Internal.C_API.Status :=
           OpenCV.Internal.C_API.Mat_Copy (Source_Handle, New_Handle'Access);
      begin
         Raise_On_Error (Result, "Mat copy construction");
      end;

      Self.Handle := New_Handle;
   end Adjust;

   overriding
   procedure Finalize (Self : in out Mat) is
      Old_Handle : constant OpenCV.Internal.C_API.Mat_Handle := Self.Handle;
   begin
      Self.Handle := OpenCV.Internal.C_API.Null_Mat_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Old_Handle);
   end Finalize;

   function Greatest_Common_Divisor (Left, Right : Mat_Size) return Mat_Size is
      A : Mat_Size := Left;
      B : Mat_Size := Right;
      R : Mat_Size;
   begin
      while B /= 0 loop
         R := A mod B;
         A := B;
         B := R;
      end loop;

      return A;
   end Greatest_Common_Divisor;

   procedure Validate_Reshape_Shape
     (Self : Mat; Requested_Channels : Channel_Count; Requested_Rows : Natural)
   is
      Source_Rows     : Mat_Size := Mat_Size (Self.Rows);
      Source_Columns  : Mat_Size := Mat_Size (Self.Columns);
      Source_Channels : Mat_Size := Mat_Size (Self.Channels);
      Target_Rows     : Mat_Size := Mat_Size (Requested_Rows);
      Target_Channels : Mat_Size := Mat_Size (Requested_Channels);
      Product         : Mat_Size := 1;
      Maximum_Columns : constant Mat_Size := 2_147_483_647;

      procedure Cancel (Factor : in out Mat_Size) is
         Common : Mat_Size;
      begin
         if Factor = 0 then
            return;
         end if;

         Common := Greatest_Common_Divisor (Source_Rows, Factor);
         Source_Rows := Source_Rows / Common;
         Factor := Factor / Common;

         Common := Greatest_Common_Divisor (Source_Columns, Factor);
         Source_Columns := Source_Columns / Common;
         Factor := Factor / Common;

         Common := Greatest_Common_Divisor (Source_Channels, Factor);
         Source_Channels := Source_Channels / Common;
         Factor := Factor / Common;
      end Cancel;

      procedure Multiply_Within_Column_Range (Factor : Mat_Size) is
      begin
         if Factor /= 0 and then Product > Maximum_Columns / Factor then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Mat reshape would derive a column count outside the supported"
               & " range");
         end if;

         Product := Product * Factor;
      end Multiply_Within_Column_Range;
   begin
      if Requested_Rows = 0 then
         return;
      end if;

      Cancel (Target_Rows);
      Cancel (Target_Channels);

      if Target_Rows /= 1 or else Target_Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat reshape dimensions do not preserve scalar element count");
      end if;

      Multiply_Within_Column_Range (Source_Rows);
      Multiply_Within_Column_Range (Source_Columns);
      Multiply_Within_Column_Range (Source_Channels);
   end Validate_Reshape_Shape;

   function Reshape (Self : Mat; Channels : Channel_Count) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Reshape_Shape
        (Self, Requested_Channels => Channels, Requested_Rows => Self.Rows);
      Status :=
        OpenCV.Internal.C_API.Mat_Reshape
          (Source   => Self.Handle,
           Channels => OpenCV.Internal.C_API.C_Int32 (Channels),
           Rows     => 0,
           Result   => New_Handle'Access);
      Raise_On_Error (Status, "Mat reshape");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Reshape;

   function Reshape
     (Self : Mat; Channels : Channel_Count; Rows : Positive) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Reshape_Shape
        (Self, Requested_Channels => Channels, Requested_Rows => Rows);
      Status :=
        OpenCV.Internal.C_API.Mat_Reshape
          (Source   => Self.Handle,
           Channels => OpenCV.Internal.C_API.C_Int32 (Channels),
           Rows     => OpenCV.Internal.C_API.C_Int32 (Rows),
           Result   => New_Handle'Access);
      Raise_On_Error (Status, "Mat reshape");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Reshape;

   function Clone (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Clone (Self.Handle, New_Handle'Access);
      Raise_On_Error (Status, "Mat clone");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Clone;

   function Transpose (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Transpose (Self.Handle, New_Handle'Access);
      Raise_On_Error (Status, "Mat transpose");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Transpose;

   function Flip (Self : Mat; Kind : Flip_Kind) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Flip
          (Source => Self.Handle,
           Kind   => To_C_Flip_Kind (Kind),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat flip");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Flip;

   function Copy_Make_Border
     (Self     : Mat;
      Top      : Natural;
      Bottom   : Natural;
      Left     : Natural;
      Right    : Natural;
      Kind     : Border_Kind;
      Value    : Scalar := (others => 0.0);
      Isolated : Boolean := False) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      C_Value    : aliased OpenCV.Internal.C_API.Scalar := To_C_Scalar (Value);
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Copy_Make_Border
          (Source   => Self.Handle,
           Top      => To_C_Border_Size (Top),
           Bottom   => To_C_Border_Size (Bottom),
           Left     => To_C_Border_Size (Left),
           Right    => To_C_Border_Size (Right),
           Kind     => To_C_Border_Kind (Kind),
           Value    => C_Value'Access,
           Isolated => (if Isolated then 1 else 0),
           Result   => New_Handle'Access);
      Raise_On_Error (Status, "Mat copy make border");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Copy_Make_Border;

   function Rotate (Self : Mat; Kind : Rotation_Kind) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Rotate
          (Source => Self.Handle,
           Kind   => To_C_Rotation_Kind (Kind),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat rotate");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Rotate;

   procedure Validate_Repeat_Dimensions
     (Self : Mat; Row_Repetitions, Column_Repetitions : Positive)
   is
      Maximum_Dimension : constant Mat_Size := 2_147_483_647;

      procedure Validate_Dimension
        (Source_Dimension : Natural; Repetitions : Positive; Axis : String)
      is
         Source_Size : constant Mat_Size := Mat_Size (Source_Dimension);
      begin
         if Source_Size /= 0
           and then Mat_Size (Repetitions) > Maximum_Dimension / Source_Size
         then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Mat repeat result "
               & Axis
               & " count exceeds the supported range");
         end if;
      end Validate_Dimension;
   begin
      Validate_Dimension (Self.Rows, Row_Repetitions, "row");
      Validate_Dimension (Self.Columns, Column_Repetitions, "column");
   end Validate_Repeat_Dimensions;

   function Repeat
     (Self : Mat; Row_Repetitions : Positive; Column_Repetitions : Positive)
      return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Repeat_Dimensions (Self, Row_Repetitions, Column_Repetitions);
      Status :=
        OpenCV.Internal.C_API.Mat_Repeat
          (Source             => Self.Handle,
           Row_Repetitions    =>
             OpenCV.Internal.C_API.C_Int32 (Row_Repetitions),
           Column_Repetitions =>
             OpenCV.Internal.C_API.C_Int32 (Column_Repetitions),
           Result             => New_Handle'Access);
      Raise_On_Error (Status, "Mat repeat");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Repeat;

   type Concatenation_Axis is
     (Horizontal_Concatenation, Vertical_Concatenation);

   function Concatenate
     (Sources : Mat_Array; Axis : Concatenation_Axis) return Mat
   is
      Maximum_Dimension : constant Mat_Size := 2_147_483_647;
      Maximum_C_Int32   : constant Natural := 2_147_483_647;
      Direction         : constant String :=
        (if Axis = Horizontal_Concatenation then "horizontal" else "vertical");
   begin
      if Sources'Length > Maximum_C_Int32 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat "
            & Direction
            & " concatenation input count exceeds the supported"
            & " range");
      end if;

      if Sources'Length = 0 then
         declare
            Result     : Mat;
            New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
              OpenCV.Internal.C_API.Null_Mat_Handle;
            Status     : OpenCV.Internal.C_API.Status;
         begin
            Status :=
              (if Axis = Horizontal_Concatenation
               then
                 OpenCV.Internal.C_API.Mat_HConcat
                   (Sources => null, Count => 0, Result => New_Handle'Access)
               else
                 OpenCV.Internal.C_API.Mat_VConcat
                   (Sources => null, Count => 0, Result => New_Handle'Access));
            Raise_On_Error (Status, "Mat " & Direction & " concatenation");
            OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
            Result.Handle := New_Handle;
            return Result;
         end;
      end if;

      declare
         First              : constant Mat := Sources (Sources'First);
         Expected_Dimension : constant Natural :=
           (if Axis = Horizontal_Concatenation
            then First.Rows
            else First.Columns);
         Expected_Depth     : constant Depth_Type := First.Depth;
         Expected_Channels  : constant Channel_Count := First.Channels;
         Total_Dimension    : Mat_Size := 0;
         Handles            :
           OpenCV.Internal.C_API.Mat_Handle_Array (0 .. Sources'Length - 1);
         Position           : Natural := Handles'First;
         Result             : Mat;
         New_Handle         : aliased OpenCV.Internal.C_API.Mat_Handle :=
           OpenCV.Internal.C_API.Null_Mat_Handle;
         Status             : OpenCV.Internal.C_API.Status;
      begin
         for Source of Sources loop
            if (if Axis = Horizontal_Concatenation
                then Source.Rows /= Expected_Dimension
                else Source.Columns /= Expected_Dimension)
            then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat "
                  & Direction
                  & " concatenation requires inputs with identical "
                  & (if Axis = Horizontal_Concatenation
                     then "row"
                     else "column")
                  & " counts");
            end if;

            if Source.Depth /= Expected_Depth
              or else Source.Channels /= Expected_Channels
            then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat "
                  & Direction
                  & " concatenation requires inputs with identical"
                  & " element types");
            end if;

            declare
               Source_Dimension : constant Natural :=
                 (if Axis = Horizontal_Concatenation
                  then Source.Columns
                  else Source.Rows);
            begin
               if Total_Dimension
                 > Maximum_Dimension - Mat_Size (Source_Dimension)
               then
                  Ada.Exceptions.Raise_Exception
                    (OpenCV_Error'Identity,
                     "Mat "
                     & Direction
                     & " concatenation result "
                     & (if Axis = Horizontal_Concatenation
                        then "column"
                        else "row")
                     & " count exceeds the supported range");
               end if;
               Total_Dimension :=
                 Total_Dimension + Mat_Size (Source_Dimension);
            end;
            Handles (Position) := Source.Handle;
            Position := Position + 1;
         end loop;

         Status :=
           (if Axis = Horizontal_Concatenation
            then
              OpenCV.Internal.C_API.Mat_HConcat
                (Sources => Handles (Handles'First)'Access,
                 Count   => OpenCV.Internal.C_API.C_Int32 (Sources'Length),
                 Result  => New_Handle'Access)
            else
              OpenCV.Internal.C_API.Mat_VConcat
                (Sources => Handles (Handles'First)'Access,
                 Count   => OpenCV.Internal.C_API.C_Int32 (Sources'Length),
                 Result  => New_Handle'Access));
         if Status /= OpenCV.Internal.C_API.Success then
            OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
            Raise_On_Error (Status, "Mat " & Direction & " concatenation");
         end if;
         if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Mat "
               & Direction
               & " concatenation returned a null result handle");
         end if;

         OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
         Result.Handle := New_Handle;
         return Result;
      end;
   end Concatenate;

   function HConcat (Sources : Mat_Array) return Mat
   is (Concatenate (Sources, Horizontal_Concatenation));

   function VConcat (Sources : Mat_Array) return Mat
   is (Concatenate (Sources, Vertical_Concatenation));

   function Split (Self : Mat) return Mat_Array is
   begin
      if Self.Is_Empty then
         return (1 .. 0 => <>);
      end if;

      declare
         Count   : constant Natural := Natural (Self.Channels);
         Handles : OpenCV.Internal.C_API.Mat_Handle_Array (0 .. Count - 1) :=
           (others => OpenCV.Internal.C_API.Null_Mat_Handle);
         Result  : Mat_Array (0 .. Count - 1);
         Status  : OpenCV.Internal.C_API.Status;
      begin
         Status :=
           OpenCV.Internal.C_API.Mat_Split
             (Source  => Self.Handle,
              Results => Handles (Handles'First)'Access,
              Count   => OpenCV.Internal.C_API.C_Int32 (Count));
         Raise_On_Error (Status, "Mat split operation");

         for Index in Handles'Range loop
            if Handles (Index) = OpenCV.Internal.C_API.Null_Mat_Handle then
               for Handle of Handles loop
                  OpenCV.Internal.C_API.Mat_Destroy (Handle);
               end loop;

               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat split operation returned a null channel handle");
            end if;
         end loop;

         for Index in Result'Range loop
            OpenCV.Internal.C_API.Mat_Destroy (Result (Index).Handle);
            Result (Index).Handle := Handles (Index);
         end loop;

         return Result;
      end;
   end Split;

   function Extract_Channel (Self : Mat; Channel : Natural) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      if Channel >= Natural (Self.Channels) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat channel index is outside the source channel range");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Extract_Channel
          (Source  => Self.Handle,
           Channel => OpenCV.Internal.C_API.C_Int32 (Channel),
           Result  => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat extract channel operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat extract channel operation returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Extract_Channel;

   procedure Insert_Channel
     (Self : in out Mat; Source : Mat; Channel : Natural)
   is
      Status : OpenCV.Internal.C_API.Status;
   begin
      if Source.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat insert channel source must have exactly one channel");
      end if;

      if Source.Rows /= Self.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat insert channel source and destination must have identical"
            & " row counts");
      end if;

      if Source.Columns /= Self.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat insert channel source and destination must have identical"
            & " column counts");
      end if;

      if Source.Depth /= Self.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat insert channel source and destination must have identical"
            & " depths");
      end if;

      if Channel >= Natural (Self.Channels) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat channel index is outside the destination channel range");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Insert_Channel
          (Source      => Source.Handle,
           Destination => Self.Handle,
           Channel     => OpenCV.Internal.C_API.C_Int32 (Channel));
      Raise_On_Error (Status, "Mat insert channel operation");
   end Insert_Channel;

   procedure Mix_Channels
     (Sources      : Mat_Array;
      Destinations : in out Mat_Array;
      Routes       : Channel_Route_Array)
   is
      Maximum_C_Int32 : constant Natural := 2_147_483_647;

      procedure Validate_Collection
        (Collection     : Mat_Array;
         Expected_Rows  : Natural;
         Expected_Cols  : Natural;
         Expected_Depth : Depth_Type;
         Name           : String) is
      begin
         for Item of Collection loop
            if Item.Rows /= Expected_Rows then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat mix channels requires "
                  & Name
                  & " Mats with identical row counts");
            end if;
            if Item.Columns /= Expected_Cols then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat mix channels requires "
                  & Name
                  & " Mats with identical column counts");
            end if;
            if Item.Depth /= Expected_Depth then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat mix channels requires "
                  & Name
                  & " Mats with identical depths");
            end if;
         end loop;
      end Validate_Collection;

      function Flattened_Channel
        (Collection : Mat_Array; Index, Channel : Natural; Name : String)
         return OpenCV.Internal.C_API.C_Int32
      is
         Offset : Natural := 0;
      begin
         if Index not in Collection'Range then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Mat mix channels "
               & Name
               & " index is outside its array range");
         end if;
         if Channel >= Natural (Collection (Index).Channels) then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Mat mix channels "
               & Name
               & " channel is outside the selected Mat channel range");
         end if;

         for Item_Index in Collection'Range loop
            exit when Item_Index = Index;
            Offset := Offset + Natural (Collection (Item_Index).Channels);
         end loop;
         if Offset > Maximum_C_Int32 - Channel then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Mat mix channels flattened channel index exceeds supported"
               & " range");
         end if;
         return OpenCV.Internal.C_API.C_Int32 (Offset + Channel);
      end Flattened_Channel;
   begin
      if Routes'Length = 0 then
         return;
      end if;
      if Sources'Length = 0 or else Destinations'Length = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat mix channels requires nonempty source and destination"
            & " arrays");
      end if;
      if Sources'Length > Maximum_C_Int32
        or else Destinations'Length > Maximum_C_Int32
        or else Routes'Length > Maximum_C_Int32
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat mix channels collection size exceeds supported range");
      end if;

      declare
         Expected_Rows        : constant Natural :=
           Destinations (Destinations'First).Rows;
         Expected_Cols        : constant Natural :=
           Destinations (Destinations'First).Columns;
         Expected_Depth       : constant Depth_Type :=
           Destinations (Destinations'First).Depth;
         Source_Handles       :
           OpenCV.Internal.C_API.Mat_Handle_Array (0 .. Sources'Length - 1);
         Destination_Handles  :
           OpenCV.Internal.C_API.Mat_Handle_Array
             (0 .. Destinations'Length - 1);
         From_To              :
           OpenCV.Internal.C_API.C_Int32_Array (0 .. Routes'Length * 2 - 1);
         Status               : OpenCV.Internal.C_API.Status;
         Source_Position      : Natural := 0;
         Destination_Position : Natural := 0;
      begin
         Validate_Collection
           (Sources, Expected_Rows, Expected_Cols, Expected_Depth, "source");
         Validate_Collection
           (Destinations,
            Expected_Rows,
            Expected_Cols,
            Expected_Depth,
            "destination");

         for Item of Sources loop
            Source_Handles (Source_Position) := Item.Handle;
            Source_Position := Source_Position + 1;
         end loop;
         for Item of Destinations loop
            Destination_Handles (Destination_Position) := Item.Handle;
            Destination_Position := Destination_Position + 1;
         end loop;

         for Route_Index in Routes'Range loop
            declare
               Route      : constant Channel_Route := Routes (Route_Index);
               Pair_Index : constant Natural :=
                 (Route_Index - Routes'First) * 2;
            begin
               From_To (Pair_Index + 1) :=
                 Flattened_Channel
                   (Destinations,
                    Route.Destination_Index,
                    Route.Destination_Channel,
                    "destination");

               if Route_Index /= Routes'First then
                  for Previous_Index in Routes'First .. Route_Index - 1 loop
                     if Routes (Previous_Index).Destination_Index
                       = Route.Destination_Index
                       and then Routes (Previous_Index).Destination_Channel
                                = Route.Destination_Channel
                     then
                        Ada.Exceptions.Raise_Exception
                          (OpenCV_Error'Identity,
                           "Mat mix channels routes must not target the same"
                           & " destination channel");
                     end if;
                  end loop;
               end if;

               case Route.Source_Kind is
                  when From_Source =>
                     From_To (Pair_Index) :=
                       Flattened_Channel
                         (Sources,
                          Route.Source_Index,
                          Route.Source_Channel,
                          "source");

                  when Zero_Fill   =>
                     From_To (Pair_Index) := -1;
               end case;
            end;
         end loop;

         Status :=
           OpenCV.Internal.C_API.Mat_Mix_Channels
             (Sources           =>
                Source_Handles (Source_Handles'First)'Access,
              Source_Count      =>
                OpenCV.Internal.C_API.C_Int32 (Sources'Length),
              Destinations      =>
                Destination_Handles (Destination_Handles'First)'Access,
              Destination_Count =>
                OpenCV.Internal.C_API.C_Int32 (Destinations'Length),
              From_To           => From_To (From_To'First)'Access,
              Pair_Count        =>
                OpenCV.Internal.C_API.C_Int32 (Routes'Length));
         Raise_On_Error (Status, "Mat mix channels operation");
      end;
   end Mix_Channels;

   function Merge (Channels : Mat_Array) return Mat is
      Maximum_Channels : constant Natural := 512;
   begin
      if Channels'Length = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat merge requires at least one input Mat");
      end if;

      declare
         First          : constant Mat := Channels (Channels'First);
         Expected_Rows  : constant Natural := First.Rows;
         Expected_Cols  : constant Natural := First.Columns;
         Expected_Depth : constant Depth_Type := First.Depth;
         Total_Channels : Natural := 0;
      begin
         for Channel of Channels loop
            if Channel.Is_Empty then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat merge does not accept empty input Mats");
            end if;

            if Channel.Rows /= Expected_Rows then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat merge requires inputs with identical row counts");
            end if;

            if Channel.Columns /= Expected_Cols then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat merge requires inputs with identical column counts");
            end if;

            if Channel.Depth /= Expected_Depth then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat merge requires inputs with identical depths");
            end if;

            Total_Channels := Total_Channels + Natural (Channel.Channels);
            if Total_Channels > Maximum_Channels then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat merge result exceeds the maximum channel count");
            end if;
         end loop;

         declare
            Handles    :
              OpenCV.Internal.C_API.Mat_Handle_Array
                (0 .. Channels'Length - 1);
            Result     : Mat;
            New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
              OpenCV.Internal.C_API.Null_Mat_Handle;
            Status     : OpenCV.Internal.C_API.Status;
            Position   : Natural := Handles'First;
         begin
            for Channel of Channels loop
               Handles (Position) := Channel.Handle;
               Position := Position + 1;
            end loop;

            Status :=
              OpenCV.Internal.C_API.Mat_Merge
                (Sources => Handles (Handles'First)'Access,
                 Count   => OpenCV.Internal.C_API.C_Int32 (Channels'Length),
                 Result  => New_Handle'Access);
            if Status /= OpenCV.Internal.C_API.Success then
               OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
               Raise_On_Error (Status, "Mat merge operation");
            end if;

            if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat merge operation returned a null result handle");
            end if;

            OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
            Result.Handle := New_Handle;
            return Result;
         end;
      end;
   end Merge;

   procedure Copy_To (Self : Mat; Destination : in out Mat) is
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Copy_To (Self.Handle, Destination.Handle);
   begin
      Raise_On_Error (Status, "Mat copy operation");
   end Copy_To;

   procedure Copy_To (Self : Mat; Destination : in out Mat; Mask : Mat) is
      Status : OpenCV.Internal.C_API.Status;
   begin
      Validate_Mask (Self, Mask);
      Status :=
        OpenCV.Internal.C_API.Mat_Copy_To_Masked
          (Source      => Self.Handle,
           Destination => Destination.Handle,
           Mask        => Mask.Handle);
      Raise_On_Error (Status, "Masked Mat copy operation");
   end Copy_To;

   function Convert_To
     (Self   : Mat;
      Depth  : Depth_Type;
      Scale  : Long_Float := 1.0;
      Offset : Long_Float := 0.0) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Convert_To
          (Source => Self.Handle,
           Depth  => To_C_Depth (Depth),
           Scale  => Interfaces.C.double (Scale),
           Offset => Interfaces.C.double (Offset),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat type conversion");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Convert_To;

   function Convert_Scale_Abs
     (Self : Mat; Scale : Long_Float := 1.0; Offset : Long_Float := 0.0)
      return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Convert_Scale_Abs
          (Source => Self.Handle,
           Scale  => Interfaces.C.double (Scale),
           Offset => Interfaces.C.double (Offset),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat scale and absolute conversion");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Convert_Scale_Abs;

   procedure Validate_LUT (Source, Table : Mat) is
   begin
      if Source.Depth /= UInt8 and then Source.Depth /= Int8 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Apply_LUT requires a UInt8 or Int8 source");
      end if;

      if Table.Depth = Float16 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Apply_LUT does not support a Float16 lookup table");
      end if;

      if Table.Total /= 256 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Apply_LUT requires a lookup table with exactly 256 elements");
      end if;

      if not Table.Is_Continuous then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Apply_LUT requires a continuous lookup table");
      end if;

      if Table.Channels /= 1 and then Table.Channels /= Source.Channels then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Apply_LUT requires the lookup table to have one channel"
            & " or the same channel count as the source");
      end if;
   end Validate_LUT;

   function Apply_LUT (Self : Mat; Table : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_LUT (Self, Table);
      Status :=
        OpenCV.Internal.C_API.Mat_Apply_LUT
          (Source => Self.Handle,
           Table  => Table.Handle,
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat lookup-table operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Apply_LUT;

   procedure Validate_Sqrt (Source : Mat) is
   begin
      if Source.Depth /= Float32 and then Source.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Sqrt requires a Float32 or Float64 source");
      end if;
   end Validate_Sqrt;

   function Sqrt (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Sqrt (Self);
      Status :=
        OpenCV.Internal.C_API.Mat_Sqrt
          (Source => Self.Handle, Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat square-root operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Sqrt;

   procedure Validate_Exp (Source : Mat) is
   begin
      if Source.Depth /= Float32 and then Source.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Exp requires a Float32 or Float64 source");
      end if;
   end Validate_Exp;

   function Exp (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Exp (Self);
      Status :=
        OpenCV.Internal.C_API.Mat_Exp
          (Source => Self.Handle, Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat exponential operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Exp;

   procedure Validate_Log (Source : Mat) is
   begin
      if Source.Depth /= Float32 and then Source.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Log requires a Float32 or Float64 source");
      end if;
   end Validate_Log;

   function Log (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Log (Self);
      Status :=
        OpenCV.Internal.C_API.Mat_Log
          (Source => Self.Handle, Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat logarithm operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Log;

   function Is_Empty (Self : Mat) return Boolean is
      Empty  : aliased OpenCV.Internal.C_API.C_Boolean :=
        OpenCV.Internal.C_API.C_False;
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Is_Empty (Self.Handle, Empty'Access);
   begin
      Raise_On_Error (Result, "Mat empty query");

      return From_C_Boolean (Empty, "Mat empty query");
   end Is_Empty;

   function Rows (Self : Mat) return Natural is
      Value  : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Rows (Self.Handle, Value'Access);
   begin
      Raise_On_Error (Result, "Mat rows query");
      return Natural (Value);
   end Rows;

   function Columns (Self : Mat) return Natural is
      Value  : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Columns (Self.Handle, Value'Access);
   begin
      Raise_On_Error (Result, "Mat columns query");
      return Natural (Value);
   end Columns;

   function Dimensions (Self : Mat) return Size
   is (Size'
         (Width  => Size_Coordinate (Self.Columns),
          Height => Size_Coordinate (Self.Rows)));

   function Channels (Self : Mat) return Channel_Count is
      Value  : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Channels (Self.Handle, Value'Access);
   begin
      Raise_On_Error (Result, "Mat channels query");
      return Channel_Count (Value);
   end Channels;

   function Depth (Self : Mat) return Depth_Type is
      Value  : aliased OpenCV.Internal.C_API.C_Int32 :=
        OpenCV.Internal.C_API.Depth_UInt8;
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Depth (Self.Handle, Value'Access);
   begin
      Raise_On_Error (Result, "Mat depth query");
      return From_C_Depth (Value);
   end Depth;

   function Total (Self : Mat) return Mat_Size is
      Value  : aliased OpenCV.Internal.C_API.C_UInt64 := 0;
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Total (Self.Handle, Value'Access);
   begin
      Raise_On_Error (Result, "Mat total query");
      return To_Mat_Size (Value);
   end Total;

   function Element_Size (Self : Mat) return Mat_Size is
      Value  : aliased OpenCV.Internal.C_API.C_UInt64 := 0;
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Element_Size (Self.Handle, Value'Access);
   begin
      Raise_On_Error (Result, "Mat element size query");
      return To_Mat_Size (Value);
   end Element_Size;

   function Channel_Size (Self : Mat) return Mat_Size is
      Value  : aliased OpenCV.Internal.C_API.C_UInt64 := 0;
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Channel_Size (Self.Handle, Value'Access);
   begin
      Raise_On_Error (Result, "Mat channel size query");
      return To_Mat_Size (Value);
   end Channel_Size;

   function Is_Continuous (Self : Mat) return Boolean is
      Value  : aliased OpenCV.Internal.C_API.C_Boolean :=
        OpenCV.Internal.C_API.C_False;
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Is_Continuous (Self.Handle, Value'Access);
   begin
      Raise_On_Error (Result, "Mat continuity query");
      return From_C_Boolean (Value, "Mat continuity query");
   end Is_Continuous;

   function Is_Submatrix (Self : Mat) return Boolean is
      Value  : aliased OpenCV.Internal.C_API.C_Boolean :=
        OpenCV.Internal.C_API.C_False;
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Is_Submatrix (Self.Handle, Value'Access);
   begin
      Raise_On_Error (Result, "Mat submatrix query");
      return From_C_Boolean (Value, "Mat submatrix query");
   end Is_Submatrix;

   function Diagonal_View
     (Self : Mat; Offset : Point_Coordinate := 0) return Mat
   is
      Result      : Mat;
      New_Handle  : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status      : OpenCV.Internal.C_API.Status;
      Source_Rows : constant Point_Coordinate := Point_Coordinate (Self.Rows);
      Source_Cols : constant Point_Coordinate :=
        Point_Coordinate (Self.Columns);
   begin
      if Self.Is_Empty
        or else Offset >= Source_Cols
        or else Offset <= -Source_Rows
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat diagonal offset selects no source elements");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Diagonal_View
          (Source => Self.Handle,
           Offset => OpenCV.Internal.C_API.C_Int32 (Offset),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat diagonal view creation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Diagonal_View;

   function Diagonal_Matrix (Diagonal : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      if Diagonal.Rows /= 1 and then Diagonal.Columns /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat diagonal matrix requires a row or column vector");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Diagonal_Matrix
          (Diagonal => Diagonal.Handle, Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat diagonal matrix creation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Diagonal_Matrix;

   function Region (Self : Mat; Area : Rect) return Mat is
      Source_Rows    : constant Size_Coordinate := Size_Coordinate (Self.Rows);
      Source_Columns : constant Size_Coordinate :=
        Size_Coordinate (Self.Columns);
      Result         : Mat;
      New_Handle     : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status         : OpenCV.Internal.C_API.Status;
   begin
      if Area.Width = 0 or else Area.Height = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat region width and height must be positive");
      end if;

      if Area.X >= Source_Columns or else Area.Y >= Source_Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat region origin is outside source bounds");
      end if;

      if Area.Width > Source_Columns - Area.X
        or else Area.Height > Source_Rows - Area.Y
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Mat region extends outside source bounds");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Region
          (Source => Self.Handle,
           X      => OpenCV.Internal.C_API.C_Int32 (Area.X),
           Y      => OpenCV.Internal.C_API.C_Int32 (Area.Y),
           Width  => OpenCV.Internal.C_API.C_Int32 (Area.Width),
           Height => OpenCV.Internal.C_API.C_Int32 (Area.Height),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat region creation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Region;

   function Row_View (Self : Mat; Row : Size_Coordinate) return Mat is
      Source_Rows : constant Size_Coordinate := Size_Coordinate (Self.Rows);
      Result      : Mat;
      New_Handle  : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status      : OpenCV.Internal.C_API.Status;
   begin
      if Row >= Source_Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Mat row index is outside source bounds");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Row_View
          (Source => Self.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat row view creation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Row_View;

   function Row_View (Self : Mat; Rows : Index_Range) return Mat is
      Source_Rows : constant Size_Coordinate := Size_Coordinate (Self.Rows);
      Result      : Mat;
      New_Handle  : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status      : OpenCV.Internal.C_API.Status;
   begin
      if Rows.Start > Rows.Stop then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat row range start must not exceed its stop");
      end if;

      if Rows.Stop > Source_Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat row range stop is outside source bounds");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Row_Range_View
          (Source => Self.Handle,
           Start  => OpenCV.Internal.C_API.C_Int32 (Rows.Start),
           Stop   => OpenCV.Internal.C_API.C_Int32 (Rows.Stop),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat row range view creation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Row_View;

   function Column_View (Self : Mat; Column : Size_Coordinate) return Mat is
      Source_Columns : constant Size_Coordinate :=
        Size_Coordinate (Self.Columns);
      Result         : Mat;
      New_Handle     : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status         : OpenCV.Internal.C_API.Status;
   begin
      if Column >= Source_Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat column index is outside source bounds");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Column_View
          (Source => Self.Handle,
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat column view creation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Column_View;

   function Column_View (Self : Mat; Columns : Index_Range) return Mat is
      Source_Columns : constant Size_Coordinate :=
        Size_Coordinate (Self.Columns);
      Result         : Mat;
      New_Handle     : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status         : OpenCV.Internal.C_API.Status;
   begin
      if Columns.Start > Columns.Stop then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat column range start must not exceed its stop");
      end if;

      if Columns.Stop > Source_Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat column range stop is outside source bounds");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Column_Range_View
          (Source => Self.Handle,
           Start  => OpenCV.Internal.C_API.C_Int32 (Columns.Start),
           Stop   => OpenCV.Internal.C_API.C_Int32 (Columns.Stop),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat column range view creation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Column_View;

   procedure Set_To (Self : in out Mat; Value : Scalar) is
      C_Value : aliased OpenCV.Internal.C_API.Scalar := To_C_Scalar (Value);
      Result  : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Set_To (Self.Handle, C_Value'Access);
   begin
      Raise_On_Error (Result, "Mat set-to operation");
   end Set_To;

   procedure Set_To (Self : in out Mat; Value : Scalar; Mask : Mat) is
      C_Value : aliased OpenCV.Internal.C_API.Scalar := To_C_Scalar (Value);
      Result  : OpenCV.Internal.C_API.Status;
   begin
      Validate_Mask (Self, Mask);
      Result :=
        OpenCV.Internal.C_API.Mat_Set_To_Masked
          (Self => Self.Handle, Value => C_Value'Access, Mask => Mask.Handle);
      Raise_On_Error (Result, "Masked Mat set-to operation");
   end Set_To;

   function Sum (Self : Mat) return Scalar is
      C_Result : aliased OpenCV.Internal.C_API.Scalar :=
        (Component_0 => 0.0,
         Component_1 => 0.0,
         Component_2 => 0.0,
         Component_3 => 0.0);
      Result   : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Sum (Self.Handle, C_Result'Access);
   begin
      Raise_On_Error (Result, "Mat sum operation");
      return From_C_Scalar (C_Result);
   end Sum;

   function Trace (Self : Mat) return Scalar is
      C_Result : aliased OpenCV.Internal.C_API.Scalar :=
        (Component_0 => 0.0,
         Component_1 => 0.0,
         Component_2 => 0.0,
         Component_3 => 0.0);
      Result   : OpenCV.Internal.C_API.Status;
   begin
      if Self.Channels > 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Trace supports Mats with at most four channels");
      end if;

      if Self.Depth = Float16 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Trace does not support Float16 Mats");
      end if;

      Result := OpenCV.Internal.C_API.Mat_Trace (Self.Handle, C_Result'Access);
      Raise_On_Error (Result, "Mat trace operation");
      return From_C_Scalar (C_Result);
   end Trace;

   procedure Validate_Reduce_Depth
     (Self : Mat; Kind : Reduction_Kind; Output_Depth : Depth_Type) is
   begin
      if (Kind = Maximum or else Kind = Minimum)
        and then Output_Depth /= Self.Depth
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Maximum and Minimum reductions require the source output depth");
      end if;
   end Validate_Reduce_Depth;

   function Reduce
     (Self : Mat; Axis : Reduction_Axis; Kind : Reduction_Kind) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Reduce
          (Source       => Self.Handle,
           Axis         => To_C_Reduction_Axis (Axis),
           Kind         => To_C_Reduction_Kind (Kind),
           Output_Depth => OpenCV.Internal.C_API.Default_Output_Depth,
           Result       => New_Handle'Access);
      Raise_On_Error (Status, "Mat reduction");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Reduce;

   function Reduce
     (Self         : Mat;
      Axis         : Reduction_Axis;
      Kind         : Reduction_Kind;
      Output_Depth : Depth_Type) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Reduce_Depth (Self, Kind, Output_Depth);
      Status :=
        OpenCV.Internal.C_API.Mat_Reduce
          (Source       => Self.Handle,
           Axis         => To_C_Reduction_Axis (Axis),
           Kind         => To_C_Reduction_Kind (Kind),
           Output_Depth => To_C_Depth (Output_Depth),
           Result       => New_Handle'Access);
      Raise_On_Error (Status, "Mat reduction");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Reduce;

   function Mean (Self : Mat) return Scalar is
      C_Result : aliased OpenCV.Internal.C_API.Scalar :=
        (Component_0 => 0.0,
         Component_1 => 0.0,
         Component_2 => 0.0,
         Component_3 => 0.0);
      Result   : OpenCV.Internal.C_API.Status;
   begin
      if Self.Channels > 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mean supports Mats with at most four channels");
      end if;

      Result := OpenCV.Internal.C_API.Mat_Mean (Self.Handle, C_Result'Access);
      Raise_On_Error (Result, "Mat mean operation");
      return From_C_Scalar (C_Result);
   end Mean;

   function Mean (Self, Mask : Mat) return Scalar is
      C_Result : aliased OpenCV.Internal.C_API.Scalar :=
        (Component_0 => 0.0,
         Component_1 => 0.0,
         Component_2 => 0.0,
         Component_3 => 0.0);
      Result   : OpenCV.Internal.C_API.Status;
   begin
      if Self.Channels > 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mean supports Mats with at most four channels");
      end if;

      Validate_Mask (Self, Mask);

      Result :=
        OpenCV.Internal.C_API.Mat_Mean_Masked
          (Self   => Self.Handle,
           Mask   => Mask.Handle,
           Result => C_Result'Access);
      Raise_On_Error (Result, "Masked Mat mean operation");
      return From_C_Scalar (C_Result);
   end Mean;

   function Mean_Std_Dev (Self : Mat) return Mean_Std_Dev_Result is
      C_Mean               : aliased OpenCV.Internal.C_API.Scalar :=
        (Component_0 => 0.0,
         Component_1 => 0.0,
         Component_2 => 0.0,
         Component_3 => 0.0);
      C_Standard_Deviation : aliased OpenCV.Internal.C_API.Scalar :=
        (Component_0 => 0.0,
         Component_1 => 0.0,
         Component_2 => 0.0,
         Component_3 => 0.0);
      Result               : OpenCV.Internal.C_API.Status;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Mean/stddev requires a non-empty Mat");
      end if;

      if Self.Channels > 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mean/stddev supports Mats with at most four channels");
      end if;

      Result :=
        OpenCV.Internal.C_API.Mat_Mean_Std_Dev
          (Self               => Self.Handle,
           Mean               => C_Mean'Access,
           Standard_Deviation => C_Standard_Deviation'Access);
      Raise_On_Error (Result, "Mat mean/stddev operation");
      return
        (Mean               => From_C_Scalar (C_Mean),
         Standard_Deviation => From_C_Scalar (C_Standard_Deviation));
   end Mean_Std_Dev;

   function Mean_Std_Dev (Self, Mask : Mat) return Mean_Std_Dev_Result is
      C_Mean               : aliased OpenCV.Internal.C_API.Scalar :=
        (Component_0 => 0.0,
         Component_1 => 0.0,
         Component_2 => 0.0,
         Component_3 => 0.0);
      C_Standard_Deviation : aliased OpenCV.Internal.C_API.Scalar :=
        (Component_0 => 0.0,
         Component_1 => 0.0,
         Component_2 => 0.0,
         Component_3 => 0.0);
      Result               : OpenCV.Internal.C_API.Status;
   begin
      if Self.Channels > 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mean/stddev supports Mats with at most four channels");
      end if;

      Validate_Mask (Self, Mask);

      Result :=
        OpenCV.Internal.C_API.Mat_Mean_Std_Dev_Masked
          (Self               => Self.Handle,
           Mask               => Mask.Handle,
           Mean               => C_Mean'Access,
           Standard_Deviation => C_Standard_Deviation'Access);
      Raise_On_Error (Result, "Masked Mat mean/stddev operation");
      return
        (Mean               => From_C_Scalar (C_Mean),
         Standard_Deviation => From_C_Scalar (C_Standard_Deviation));
   end Mean_Std_Dev;

   function Norm (Self : Mat; Kind : Norm_Kind := L2) return Long_Float is
      C_Result : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status   : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Norm
          (Self   => Self.Handle,
           Kind   => To_C_Norm_Kind (Kind),
           Result => C_Result'Access);
   begin
      Raise_On_Error (Status, "Mat norm operation");
      return Long_Float (C_Result);
   end Norm;

   function Norm
     (Self : Mat; Mask : Mat; Kind : Norm_Kind := L2) return Long_Float
   is
      C_Result : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status   : OpenCV.Internal.C_API.Status;
   begin
      Validate_Mask (Self, Mask);
      Status :=
        OpenCV.Internal.C_API.Mat_Norm_Masked
          (Self   => Self.Handle,
           Mask   => Mask.Handle,
           Kind   => To_C_Norm_Kind (Kind),
           Result => C_Result'Access);
      Raise_On_Error (Status, "Masked Mat norm operation");
      return Long_Float (C_Result);
   end Norm;

   function Min_Max_Loc (Self : Mat) return Min_Max_Result is
      Minimum   : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Maximum   : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Minimum_X : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Minimum_Y : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Maximum_X : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Maximum_Y : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Status    : OpenCV.Internal.C_API.Status;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Min/max location requires a non-empty Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Min/max location requires a single-channel Mat");
      end if;

      if Self.Depth = Float16 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Min/max location does not support Float16 Mats");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Min_Max_Loc
          (Self      => Self.Handle,
           Minimum   => Minimum'Access,
           Maximum   => Maximum'Access,
           Minimum_X => Minimum_X'Access,
           Minimum_Y => Minimum_Y'Access,
           Maximum_X => Maximum_X'Access,
           Maximum_Y => Maximum_Y'Access);
      Raise_On_Error (Status, "Mat min/max location operation");

      return
        (Minimum          => Long_Float (Minimum),
         Maximum          => Long_Float (Maximum),
         Minimum_Location =>
           (X => Point_Coordinate (Minimum_X),
            Y => Point_Coordinate (Minimum_Y)),
         Maximum_Location =>
           (X => Point_Coordinate (Maximum_X),
            Y => Point_Coordinate (Maximum_Y)));
   end Min_Max_Loc;

   function Min_Max_Loc (Self, Mask : Mat) return Min_Max_Result is
      Minimum   : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Maximum   : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Minimum_X : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Minimum_Y : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Maximum_X : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Maximum_Y : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Status    : OpenCV.Internal.C_API.Status;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Min/max location requires a non-empty Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Min/max location requires a single-channel Mat");
      end if;

      if Self.Depth = Float16 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Min/max location does not support Float16 Mats");
      end if;

      Validate_Mask (Self, Mask);

      Status :=
        OpenCV.Internal.C_API.Mat_Min_Max_Loc_Masked
          (Self      => Self.Handle,
           Mask      => Mask.Handle,
           Minimum   => Minimum'Access,
           Maximum   => Maximum'Access,
           Minimum_X => Minimum_X'Access,
           Minimum_Y => Minimum_Y'Access,
           Maximum_X => Maximum_X'Access,
           Maximum_Y => Maximum_Y'Access);
      Raise_On_Error (Status, "Masked Mat min/max location operation");

      return
        (Minimum          => Long_Float (Minimum),
         Maximum          => Long_Float (Maximum),
         Minimum_Location =>
           (X => Point_Coordinate (Minimum_X),
            Y => Point_Coordinate (Minimum_Y)),
         Maximum_Location =>
           (X => Point_Coordinate (Maximum_X),
            Y => Point_Coordinate (Maximum_Y)));
   end Min_Max_Loc;

   function Count_Non_Zero (Self : Mat) return Mat_Size is
      Count  : aliased Interfaces.Integer_64 := 0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Count_Non_Zero requires a single-channel Mat");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Count_Non_Zero (Self.Handle, Count'Access);
      Raise_On_Error (Status, "Mat count non-zero operation");

      if Count < 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Count_Non_Zero result exceeds Mat_Size range");
      end if;

      return Mat_Size (Count);
   end Count_Non_Zero;

   function Has_Non_Zero (Self : Mat) return Boolean is
      Result : aliased Interfaces.Unsigned_8 := 0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Has_Non_Zero requires a single-channel Mat");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Has_Non_Zero (Self.Handle, Result'Access);
      Raise_On_Error (Status, "Mat has non-zero operation");

      return Result = 1;
   end Has_Non_Zero;

   function Find_Non_Zero (Self : Mat) return Point_Array is
   begin
      if Self.Is_Empty then
         return (1 .. 0 => (X => 0, Y => 0));
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Find_Non_Zero requires a single-channel Mat");
      end if;

      if Self.Depth = Float16 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Find_Non_Zero does not support Float16 Mats");
      end if;

      declare
         Count : constant Mat_Size := Self.Count_Non_Zero;
      begin
         if Count = 0 then
            return (1 .. 0 => (X => 0, Y => 0));
         end if;

         if Count > Mat_Size (Natural'Last) then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Find_Non_Zero result exceeds Point_Array range");
         end if;

         declare
            C_Points :
              OpenCV.Internal.C_API.Point_Array (0 .. Natural (Count) - 1);
            Result   : Point_Array (0 .. Natural (Count) - 1);
            Returned : aliased Interfaces.Integer_64 := 0;
            Status   : OpenCV.Internal.C_API.Status;
         begin
            Status :=
              OpenCV.Internal.C_API.Mat_Find_Non_Zero
                (Self.Handle,
                 C_Points (C_Points'First)'Access,
                 Interfaces.Integer_64 (Count),
                 Returned'Access);
            Raise_On_Error (Status, "Mat find non-zero operation");

            if Returned /= Interfaces.Integer_64 (Count) then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Find_Non_Zero result count changed during operation");
            end if;

            for Index in Result'Range loop
               Result (Index) :=
                 (X => Point_Coordinate (C_Points (Index).X),
                  Y => Point_Coordinate (C_Points (Index).Y));
            end loop;

            return Result;
         end;
      end;
   end Find_Non_Zero;

end OpenCV.Core;
