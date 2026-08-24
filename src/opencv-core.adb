with Ada.Exceptions;
with Interfaces.C;
with OpenCV.Internal.Safe_Arithmetic;

package body OpenCV.Core is

   Maximum_Jacobi_Dimension : constant Natural := 8_460;

   use type OpenCV.Internal.C_API.C_Boolean;
   use type OpenCV.Internal.C_API.C_Double;
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

   function To_C_Last_Index
     (Value : Extremum_Occurrence) return OpenCV.Internal.C_API.C_UInt8
   is (case Value is
         when First_Occurrence => 0,
         when Last_Occurrence  => 1);

   function To_C_Sample_Orientation
     (Value : Sample_Orientation) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when Samples_Are_Rows    =>
           OpenCV.Internal.C_API.Sample_Orientation_Rows,
         when Samples_Are_Columns =>
           OpenCV.Internal.C_API.Sample_Orientation_Columns);

   function To_C_Covariance_Scaling
     (Value : Covariance_Scaling) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when Unscaled        =>
           OpenCV.Internal.C_API.Covariance_Scaling_Unscaled,
         when By_Sample_Count =>
           OpenCV.Internal.C_API.Covariance_Scaling_By_Sample_Count);
   function To_C_Spectrum_Multiplication_Kind
     (Value : Spectrum_Multiplication_Kind)
      return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when Ordinary_Spectrum_Product        =>
           OpenCV.Internal.C_API.Spectrum_Product_Ordinary,
         when Conjugate_Right_Spectrum_Product =>
           OpenCV.Internal.C_API.Spectrum_Product_Conjugate_Right);

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

   function To_C_K_Means_Initialization
     (Value : K_Means_Initialization) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when Random_Centers    =>
           OpenCV.Internal.C_API.K_Means_Random_Centers,
         when Plus_Plus_Centers =>
           OpenCV.Internal.C_API.K_Means_Plus_Plus_Centers);

   procedure Validate_K_Means
     (Samples       : Mat;
      Cluster_Count : Positive;
      Criteria      : K_Means_Criteria;
      Attempts      : Positive)
   is
      Sample_Count  : Natural;
      Feature_Count : Mat_Size;
   begin
      if Samples.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "K_Means requires non-empty samples");
      end if;
      if Samples.Depth /= Float32 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "K_Means requires Float32 samples");
      end if;

      if Samples.Rows = 1 then
         Sample_Count := Samples.Columns;
         Feature_Count := Mat_Size (Samples.Channels);
      else
         Sample_Count := Samples.Rows;
         Feature_Count :=
           Mat_Size (Samples.Columns) * Mat_Size (Samples.Channels);
      end if;
      if Sample_Count = 0 or else Feature_Count = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Means requires a positive sample count and feature dimension");
      end if;
      if Cluster_Count > Sample_Count then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Means cluster count must not exceed sample count");
      end if;
      pragma Warnings (Off);
      if not Criteria.Epsilon'Valid
        or else Criteria.Epsilon < 0.0
        or else Criteria.Epsilon > Long_Float (Interfaces.C.double'Last)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Means epsilon must be finite, nonnegative, and"
            & " C-double representable");
      end if;
      pragma Warnings (On);
   end Validate_K_Means;

   function K_Means
     (Samples        : Mat;
      Cluster_Count  : Positive;
      Criteria       : K_Means_Criteria :=
        (Maximum_Iterations => 100, Epsilon => 1.0E-4);
      Attempts       : Positive := 3;
      Initialization : K_Means_Initialization := Plus_Plus_Centers)
      return K_Means_Result
   is
      Result         : K_Means_Result;
      Labels_Handle  : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Centers_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Compactness    : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status         : OpenCV.Internal.C_API.Status;
   begin
      Validate_K_Means (Samples, Cluster_Count, Criteria, Attempts);
      Status :=
        OpenCV.Internal.C_API.Mat_K_Means
          (Samples            => Samples.Handle,
           Cluster_Count      => OpenCV.Internal.C_API.C_Int32 (Cluster_Count),
           Maximum_Iterations =>
             OpenCV.Internal.C_API.C_Int32 (Criteria.Maximum_Iterations),
           Epsilon            => Interfaces.C.double (Criteria.Epsilon),
           Attempts           => OpenCV.Internal.C_API.C_Int32 (Attempts),
           Initialization     => To_C_K_Means_Initialization (Initialization),
           Labels             => Labels_Handle'Access,
           Centers            => Centers_Handle'Access,
           Compactness        => Compactness'Access);
      Raise_On_Error (Status, "K_Means");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Labels.Handle);
      OpenCV.Internal.C_API.Mat_Destroy (Result.Centers.Handle);
      Result.Labels.Handle := Labels_Handle;
      Result.Centers.Handle := Centers_Handle;
      Result.Compactness := Long_Float (Compactness);
      return Result;
   end K_Means;

   procedure Validate_K_Means_Initial_Labels
     (Samples        : Mat;
      Cluster_Count  : Positive;
      Initial_Labels : Mat;
      Criteria       : K_Means_Criteria;
      Attempts       : Positive)
   is
      Sample_Count : Natural;
   begin
      Validate_K_Means (Samples, Cluster_Count, Criteria, Attempts);
      if Initial_Labels.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "K_Means initial labels must be non-empty");
      end if;
      if Initial_Labels.Depth /= Int32 or else Initial_Labels.Channels /= 1
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "K_Means initial labels must be Int32 C1");
      end if;
      if Initial_Labels.Rows /= 1 and then Initial_Labels.Columns /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Means initial labels must be a row or column vector");
      end if;
      Sample_Count :=
        (if Samples.Rows = 1 then Samples.Columns else Samples.Rows);
      if Initial_Labels.Total /= Mat_Size (Sample_Count) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Means initial label count must equal the sample count");
      end if;
   end Validate_K_Means_Initial_Labels;

   function K_Means
     (Samples                   : Mat;
      Cluster_Count             : Positive;
      Initial_Labels            : Mat;
      Criteria                  : K_Means_Criteria :=
        (Maximum_Iterations => 100, Epsilon => 1.0E-4);
      Attempts                  : Positive := 1;
      Subsequent_Initialization : K_Means_Initialization := Plus_Plus_Centers)
      return K_Means_Result
   is
      Result         : K_Means_Result;
      Labels_Handle  : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Centers_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Compactness    : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status         : OpenCV.Internal.C_API.Status;
   begin
      Validate_K_Means_Initial_Labels
        (Samples, Cluster_Count, Initial_Labels, Criteria, Attempts);
      Status :=
        OpenCV.Internal.C_API.Mat_K_Means_With_Initial_Labels
          (Samples                   => Samples.Handle,
           Initial_Labels            => Initial_Labels.Handle,
           Cluster_Count             =>
             OpenCV.Internal.C_API.C_Int32 (Cluster_Count),
           Maximum_Iterations        =>
             OpenCV.Internal.C_API.C_Int32 (Criteria.Maximum_Iterations),
           Epsilon                   => Interfaces.C.double (Criteria.Epsilon),
           Attempts                  =>
             OpenCV.Internal.C_API.C_Int32 (Attempts),
           Subsequent_Initialization =>
             To_C_K_Means_Initialization (Subsequent_Initialization),
           Labels                    => Labels_Handle'Access,
           Centers                   => Centers_Handle'Access,
           Compactness               => Compactness'Access);
      Raise_On_Error (Status, "K_Means with initial labels");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Labels.Handle);
      OpenCV.Internal.C_API.Mat_Destroy (Result.Centers.Handle);
      Result.Labels.Handle := Labels_Handle;
      Result.Centers.Handle := Centers_Handle;
      Result.Compactness := Long_Float (Compactness);
      return Result;
   end K_Means;

   function To_C_Batch_Distance_Kind
     (Value : Batch_Distance_Kind) return OpenCV.Internal.C_API.C_Int32
   is (case Value is
         when L1_Distance         => OpenCV.Internal.C_API.Batch_Distance_L1,
         when L2_Distance         => OpenCV.Internal.C_API.Batch_Distance_L2,
         when Squared_L2_Distance =>
           OpenCV.Internal.C_API.Batch_Distance_Squared_L2,
         when Hamming_Distance    =>
           OpenCV.Internal.C_API.Batch_Distance_Hamming,
         when Hamming_2_Distance  =>
           OpenCV.Internal.C_API.Batch_Distance_Hamming_2);

   procedure Validate_K_Nearest_Neighbors
     (Queries        : Mat;
      Candidates     : Mat;
      Neighbor_Count : Positive;
      Kind           : Batch_Distance_Kind) is
   begin
      if Queries.Is_Empty or else Candidates.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Nearest_Neighbors requires non-empty inputs");
      end if;
      if Queries.Channels /= 1 or else Candidates.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Nearest_Neighbors requires single-channel inputs");
      end if;
      if Queries.Depth /= Candidates.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Nearest_Neighbors requires matching input depths");
      end if;
      if Queries.Columns /= Candidates.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Nearest_Neighbors requires matching vector widths");
      end if;
      if Queries.Depth /= UInt8 and then Queries.Depth /= Float32 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Nearest_Neighbors supports UInt8 and Float32 inputs only");
      end if;
      if Neighbor_Count > Candidates.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Nearest_Neighbors neighbor count exceeds candidate count");
      end if;
      if Queries.Depth = Float32
        and then (Kind = Hamming_Distance or else Kind = Hamming_2_Distance)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "K_Nearest_Neighbors Hamming distance requires UInt8 inputs");
      end if;
   end Validate_K_Nearest_Neighbors;

   function K_Nearest_Neighbors
     (Queries        : Mat;
      Candidates     : Mat;
      Neighbor_Count : Positive;
      Kind           : Batch_Distance_Kind := L2_Distance)
      return Nearest_Neighbor_Result
   is
      Result           : Nearest_Neighbor_Result;
      Distances_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Indices_Handle   : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status           : OpenCV.Internal.C_API.Status;
   begin
      Validate_K_Nearest_Neighbors (Queries, Candidates, Neighbor_Count, Kind);
      Status :=
        OpenCV.Internal.C_API.Mat_Batch_Distance
          (Queries        => Queries.Handle,
           Candidates     => Candidates.Handle,
           Neighbor_Count => OpenCV.Internal.C_API.C_Int32 (Neighbor_Count),
           Kind           => To_C_Batch_Distance_Kind (Kind),
           Distances      => Distances_Handle'Access,
           Indices        => Indices_Handle'Access);
      Raise_On_Error (Status, "K_Nearest_Neighbors");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Distances.Handle);
      OpenCV.Internal.C_API.Mat_Destroy (Result.Indices.Handle);
      Result.Distances.Handle := Distances_Handle;
      Result.Indices.Handle := Indices_Handle;
      return Result;
   end K_Nearest_Neighbors;

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

   procedure Validate_Single_Channel_Sortable (Self : Mat; Operation : String)
   is
   begin
      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires a single-channel Mat");
      end if;

      if Self.Depth = Float16 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " does not support Float16 Mats");
      end if;
   end Validate_Single_Channel_Sortable;

   function Sort
     (Self  : Mat;
      Axis  : Sort_Axis := Each_Row;
      Order : Sort_Order := Ascending) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Single_Channel_Sortable (Self, "Sort");

      Status :=
        OpenCV.Internal.C_API.Mat_Sort
          (Source     => Self.Handle,
           Axis       => (if Axis = Each_Row then 0 else 1),
           Descending => (if Order = Descending then 1 else 0),
           Result     => New_Handle'Access);
      Raise_On_Error (Status, "Mat sort");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Sort;

   function Sort_Indices
     (Self  : Mat;
      Axis  : Sort_Axis := Each_Row;
      Order : Sort_Order := Ascending) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Single_Channel_Sortable (Self, "Sort_Indices");

      Status :=
        OpenCV.Internal.C_API.Mat_Sort_Indices
          (Source     => Self.Handle,
           Axis       => (if Axis = Each_Row then 0 else 1),
           Descending => (if Order = Descending then 1 else 0),
           Result     => New_Handle'Access);
      Raise_On_Error (Status, "Mat sort indices");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Sort_Indices;

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

   function Border_Interpolate
     (Position : Point_Coordinate; Length : Positive; Kind : Border_Kind)
      return Border_Interpolation_Result
   is
      Index  : aliased OpenCV.Internal.C_API.C_Int32 := -1;
      Status : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Border_Interpolate
          (Position => OpenCV.Internal.C_API.C_Int32 (Position),
           Length   => OpenCV.Internal.C_API.C_Int32 (Length),
           Kind     => To_C_Border_Kind (Kind),
           Index    => Index'Access);
      Raise_On_Error (Status, "Border interpolate");

      if Index >= 0 then
         return (Uses_Constant => False, Index => Size_Coordinate (Index));
      elsif Index = -1 then
         return (Uses_Constant => True);
      else
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Border interpolate returned an invalid negative source index");
      end if;
   end Border_Interpolate;

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

   function Is_Integer_Power (Power : Long_Float) return Boolean is
      Rounded : constant Long_Float := Long_Float'Rounding (Power);
      Min_Int : constant Long_Float :=
        Long_Float (OpenCV.Internal.C_API.C_Int32'First);
      Max_Int : constant Long_Float :=
        Long_Float (OpenCV.Internal.C_API.C_Int32'Last);
   begin
      if Rounded < Min_Int or else Rounded > Max_Int then
         return False;
      end if;

      return abs (Rounded - Power) < Long_Float'Model_Epsilon;
   end Is_Integer_Power;

   procedure Validate_Pow (Source : Mat; Power : Long_Float) is
   begin
      if Source.Depth = Float16 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Pow does not support a Float16 source");
      end if;

      if Source.Depth = Float32 or else Source.Depth = Float64 then
         return;
      end if;

      if not Is_Integer_Power (Power) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Pow requires a Float32 or Float64 source for a non-integer"
            & " power");
      end if;

      if Power < 0.0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Pow does not support a negative power for an integer-depth"
            & " source");
      end if;
   end Validate_Pow;

   function Pow (Self : Mat; Power : Long_Float) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Pow (Self, Power);
      Status :=
        OpenCV.Internal.C_API.Mat_Pow
          (Source => Self.Handle,
           Power  => OpenCV.Internal.C_API.C_Double (Power),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat power operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Pow;

   procedure Validate_Matching_Float_Operands (X, Y : Mat; Operation : String)
   is
   begin
      if X.Depth /= Float32 and then X.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires a Float32 or Float64 X operand");
      end if;

      if Y.Depth /= Float32 and then Y.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires a Float32 or Float64 Y operand");
      end if;

      if X.Rows /= Y.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires operands with identical row counts");
      end if;

      if X.Columns /= Y.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires operands with identical column counts");
      end if;

      if X.Depth /= Y.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires operands with identical depths");
      end if;

      if X.Channels /= Y.Channels then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires operands with identical channel counts");
      end if;
   end Validate_Matching_Float_Operands;

   function Magnitude (X, Y : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Matching_Float_Operands (X, Y, "Magnitude");
      Status :=
        OpenCV.Internal.C_API.Mat_Magnitude
          (X => X.Handle, Y => Y.Handle, Result => New_Handle'Access);
      Raise_On_Error (Status, "Mat magnitude operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Magnitude;

   function Phase (X, Y : Mat; Units : Angle_Unit := Radians) return Mat is
      Result           : Mat;
      New_Handle       : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Angle_In_Degrees : constant OpenCV.Internal.C_API.C_Boolean :=
        (if Units = Degrees
         then OpenCV.Internal.C_API.C_True
         else OpenCV.Internal.C_API.C_False);
      Status           : OpenCV.Internal.C_API.Status;
   begin
      Validate_Matching_Float_Operands (X, Y, "Phase");
      Status :=
        OpenCV.Internal.C_API.Mat_Phase
          (X                => X.Handle,
           Y                => Y.Handle,
           Angle_In_Degrees => Angle_In_Degrees,
           Result           => New_Handle'Access);
      Raise_On_Error (Status, "Mat phase operation");

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Phase;
   function Cart_To_Polar
     (X, Y : Mat; Units : Angle_Unit := Radians) return Polar_Coordinates
   is
      Result           : Polar_Coordinates;
      Magnitude_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Angle_Handle     : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Angle_In_Degrees : constant OpenCV.Internal.C_API.C_Boolean :=
        (if Units = Degrees
         then OpenCV.Internal.C_API.C_True
         else OpenCV.Internal.C_API.C_False);
      Status           : OpenCV.Internal.C_API.Status;
   begin
      Validate_Matching_Float_Operands (X, Y, "Cart_To_Polar");
      Status :=
        OpenCV.Internal.C_API.Mat_Cart_To_Polar
          (X                => X.Handle,
           Y                => Y.Handle,
           Angle_In_Degrees => Angle_In_Degrees,
           Magnitude        => Magnitude_Handle'Access,
           Angle            => Angle_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (Magnitude_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Angle_Handle);
         Raise_On_Error (Status, "Mat cart-to-polar operation");
      end if;

      if Magnitude_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else Angle_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
      then
         OpenCV.Internal.C_API.Mat_Destroy (Magnitude_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Angle_Handle);
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat cart-to-polar operation returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Magnitude.Handle);
      Result.Magnitude.Handle := Magnitude_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Angle.Handle);
      Result.Angle.Handle := Angle_Handle;
      return Result;
   end Cart_To_Polar;

   procedure Validate_Polar_To_Cart_Operands (Magnitude, Angle : Mat) is
   begin
      if Angle.Depth /= Float32 and then Angle.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Polar_To_Cart requires a Float32 or Float64 Angle operand");
      end if;

      if Magnitude.Is_Empty then
         return;
      end if;

      if Magnitude.Depth /= Angle.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Polar_To_Cart requires Magnitude and Angle with identical"
            & " depths");
      end if;

      if Magnitude.Channels /= Angle.Channels then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Polar_To_Cart requires Magnitude and Angle with identical"
            & " channel counts");
      end if;

      if Magnitude.Rows /= Angle.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Polar_To_Cart requires Magnitude and Angle with identical"
            & " row counts");
      end if;

      if Magnitude.Columns /= Angle.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Polar_To_Cart requires Magnitude and Angle with identical"
            & " column counts");
      end if;
   end Validate_Polar_To_Cart_Operands;

   function Polar_To_Cart
     (Magnitude, Angle : Mat; Units : Angle_Unit := Radians)
      return Cartesian_Coordinates
   is
      Result           : Cartesian_Coordinates;
      X_Handle         : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Y_Handle         : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Angle_In_Degrees : constant OpenCV.Internal.C_API.C_Boolean :=
        (if Units = Degrees
         then OpenCV.Internal.C_API.C_True
         else OpenCV.Internal.C_API.C_False);
      Status           : OpenCV.Internal.C_API.Status;
   begin
      Validate_Polar_To_Cart_Operands (Magnitude, Angle);
      Status :=
        OpenCV.Internal.C_API.Mat_Polar_To_Cart
          (Magnitude        => Magnitude.Handle,
           Angle            => Angle.Handle,
           Angle_In_Degrees => Angle_In_Degrees,
           X                => X_Handle'Access,
           Y                => Y_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (X_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Y_Handle);
         Raise_On_Error (Status, "Mat polar-to-cart operation");
      end if;

      if X_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else Y_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
      then
         OpenCV.Internal.C_API.Mat_Destroy (X_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Y_Handle);
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat polar-to-cart operation returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.X.Handle);
      Result.X.Handle := X_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Y.Handle);
      Result.Y.Handle := Y_Handle;
      return Result;
   end Polar_To_Cart;

   function Polar_To_Cart
     (Angle : Mat; Units : Angle_Unit := Radians) return Cartesian_Coordinates
   is
      Empty_Magnitude : Mat;
   begin
      return Polar_To_Cart (Empty_Magnitude, Angle, Units);
   end Polar_To_Cart;

   procedure Validate_DFT_Floating_Source
     (Self : Mat; Operation : String; Require_Complex : Boolean) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " requires a non-empty Mat");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires a Float32 or Float64 Mat");
      end if;

      if Require_Complex then
         if Self.Channels /= 2 then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               Operation & " requires a two-channel complex Mat");
         end if;
      elsif Self.Channels /= 1 and then Self.Channels /= 2 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation
            & " requires a one-channel real or two-channel"
            & " complex Mat");
      end if;

      declare
         function Product_Exceeds_Signed_Int32
           (Left, Right : Natural) return Boolean
         renames OpenCV.Internal.Safe_Arithmetic.Product_Exceeds_Signed_Int32;

         Complex_Element_Bytes : constant Natural :=
           (if Self.Depth = Float32 then 8 else 16);
      begin
         if Product_Exceeds_Signed_Int32 (Self.Rows, Self.Columns)
           or else Product_Exceeds_Signed_Int32
                     (Self.Rows, Complex_Element_Bytes)
           or else Product_Exceeds_Signed_Int32
                     (Self.Columns, Complex_Element_Bytes)
         then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               Operation
               & " dimensions exceed the OpenCV 4.10"
               & " signed-arithmetic safety limit");
         end if;
      end;
   end Validate_DFT_Floating_Source;

   function Discrete_Fourier_Transform (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_DFT_Floating_Source
        (Self, "Discrete_Fourier_Transform", Require_Complex => False);

      Status :=
        OpenCV.Internal.C_API.Mat_DFT
          (Source         => Self.Handle,
           Transform_Kind => OpenCV.Internal.C_API.DFT_Forward_Complex,
           Result         => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat discrete Fourier transform");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat discrete Fourier transform returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Discrete_Fourier_Transform;

   function Inverse_Discrete_Fourier_Transform (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_DFT_Floating_Source
        (Self, "Inverse_Discrete_Fourier_Transform", Require_Complex => True);

      Status :=
        OpenCV.Internal.C_API.Mat_DFT
          (Source         => Self.Handle,
           Transform_Kind => OpenCV.Internal.C_API.DFT_Inverse_Complex,
           Result         => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat inverse discrete Fourier transform");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat inverse discrete Fourier transform returned a null"
            & " result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Inverse_Discrete_Fourier_Transform;

   function Inverse_Real_Discrete_Fourier_Transform (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_DFT_Floating_Source
        (Self,
         "Inverse_Real_Discrete_Fourier_Transform",
         Require_Complex => True);

      Status :=
        OpenCV.Internal.C_API.Mat_DFT
          (Source         => Self.Handle,
           Transform_Kind => OpenCV.Internal.C_API.DFT_Inverse_Real,
           Result         => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error
           (Status, "Mat inverse real discrete Fourier transform");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat inverse real discrete Fourier transform returned a null"
            & " result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Inverse_Real_Discrete_Fourier_Transform;

   procedure Validate_DCT_Source (Self : Mat; Operation : String) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " requires a non-empty Mat");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires a Float32 or Float64 Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " requires a one-channel Mat");
      end if;

      declare
         Row_Count    : constant Natural := Self.Rows;
         Column_Count : constant Natural := Self.Columns;
         Even_Length  : Boolean;
      begin
         if Row_Count = 1 and then Column_Count = 1 then
            Even_Length := True;
         elsif Row_Count = 1 then
            Even_Length := Column_Count mod 2 = 0;
         elsif Column_Count = 1 then
            Even_Length := Row_Count mod 2 = 0;
         else
            Even_Length := Row_Count mod 2 = 0 and then Column_Count mod 2 = 0;
         end if;

         if not Even_Length then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               Operation & " requires even transform sizes greater than 1");
         end if;
      end;

      declare
         function Product_Exceeds_Signed_Int32
           (Left, Right : Natural) return Boolean
         renames OpenCV.Internal.Safe_Arithmetic.Product_Exceeds_Signed_Int32;

         Complex_Element_Bytes : constant Natural :=
           (if Self.Depth = Float32 then 8 else 16);
      begin
         if Product_Exceeds_Signed_Int32 (Self.Rows, Complex_Element_Bytes)
           or else Product_Exceeds_Signed_Int32
                     (Self.Columns, Complex_Element_Bytes)
         then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               Operation
               & " dimensions exceed the OpenCV 4.10"
               & " signed-arithmetic safety limit");
         end if;
      end;
   end Validate_DCT_Source;

   function Discrete_Cosine_Transform (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_DCT_Source (Self, "Discrete_Cosine_Transform");

      Status :=
        OpenCV.Internal.C_API.Mat_DCT
          (Source         => Self.Handle,
           Transform_Kind => OpenCV.Internal.C_API.DCT_Forward,
           Result         => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat discrete cosine transform");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat discrete cosine transform returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Discrete_Cosine_Transform;

   function Inverse_Discrete_Cosine_Transform (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_DCT_Source (Self, "Inverse_Discrete_Cosine_Transform");

      Status :=
        OpenCV.Internal.C_API.Mat_DCT
          (Source         => Self.Handle,
           Transform_Kind => OpenCV.Internal.C_API.DCT_Inverse,
           Result         => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat inverse discrete cosine transform");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat inverse discrete cosine transform returned a null"
            & " result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Inverse_Discrete_Cosine_Transform;

   procedure Validate_Spectrum_Multiplication_Operands (Left, Right : Mat) is
   begin
      if Left.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Multiply_Spectra requires a non-empty Left Mat");
      end if;

      if Right.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Multiply_Spectra requires a non-empty Right Mat");
      end if;

      if Left.Rows /= Right.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Multiply_Spectra requires operands with identical row counts");
      end if;

      if Left.Columns /= Right.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Multiply_Spectra requires operands with identical column counts");
      end if;

      if Left.Depth /= Right.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Multiply_Spectra requires operands with identical depths");
      end if;

      if Left.Depth /= Float32 and then Left.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Multiply_Spectra requires Float32 or Float64 spectra");
      end if;

      if Left.Channels /= 2 or else Right.Channels /= 2 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Multiply_Spectra requires explicit two-channel complex spectra");
      end if;
   end Validate_Spectrum_Multiplication_Operands;

   function Multiply_Spectra
     (Left  : Mat;
      Right : Mat;
      Kind  : Spectrum_Multiplication_Kind := Ordinary_Spectrum_Product)
      return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Spectrum_Multiplication_Operands (Left, Right);

      Status :=
        OpenCV.Internal.C_API.Mat_Multiply_Spectra
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Kind   => To_C_Spectrum_Multiplication_Kind (Kind),
           Result => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat spectrum multiplication");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat spectrum multiplication returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Multiply_Spectra;

   function Optimal_DFT_Size (Minimum_Size : Positive) return Positive is
      Wide_Minimum : constant Long_Long_Integer :=
        Long_Long_Integer (Minimum_Size);
      Result       : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Status       : OpenCV.Internal.C_API.Status;
   begin
      if not OpenCV.Internal.Safe_Arithmetic.Fits_Signed_Int32 (Wide_Minimum)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Optimal_DFT_Size minimum size exceeds the signed 32-bit"
            & " OpenCV domain");
      end if;

      Status :=
        OpenCV.Internal.C_API.Get_Optimal_DFT_Size
          (Minimum_Size =>
             OpenCV.Internal.Safe_Arithmetic.To_Signed_Int32 (Wide_Minimum),
           Result       => Result'Access);
      Raise_On_Error (Status, "Optimal DFT size query");

      if Result <= 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Optimal_DFT_Size returned a non-positive result");
      end if;

      return Positive (Result);
   end Optimal_DFT_Size;

   function Optimal_DCT_Size (Minimum_Size : Positive) return Positive is
      Wide_Minimum : constant Long_Long_Integer :=
        Long_Long_Integer (Minimum_Size);
      Half_Minimum : Positive;
      Half_Optimal : Positive;
      Wide_Result  : Long_Long_Integer;
   begin
      if not OpenCV.Internal.Safe_Arithmetic.Fits_Signed_Int32 (Wide_Minimum)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Optimal_DCT_Size minimum size exceeds the signed 32-bit"
            & " OpenCV dimension domain");
      end if;

      Half_Minimum := Minimum_Size / 2 + Minimum_Size mod 2;
      Half_Optimal := Optimal_DFT_Size (Half_Minimum);
      Wide_Result := 2 * Long_Long_Integer (Half_Optimal);

      if not OpenCV.Internal.Safe_Arithmetic.Fits_Signed_Int32 (Wide_Result)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Optimal_DCT_Size result exceeds the signed 32-bit"
            & " OpenCV dimension domain");
      end if;

      return Positive (Wide_Result);
   end Optimal_DCT_Size;

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

   procedure Set_Random_Seed (Seed : Interfaces.Integer_32) is
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Set_RNG_Seed
          (OpenCV.Internal.C_API.C_Int32 (Seed));
   begin
      Raise_On_Error (Result, "OpenCV random seed operation");
   end Set_Random_Seed;

   function Make_Random_Number_Generator
     (Seed : Interfaces.Unsigned_64 := 16#FFFF_FFFF#)
      return Random_Number_Generator
   is (State => (if Seed = 0 then 16#FFFF_FFFF# else Seed));

   procedure Reseed
     (Generator : in out Random_Number_Generator;
      Seed      : Interfaces.Unsigned_64) is
   begin
      Generator.State := (if Seed = 0 then 16#FFFF_FFFF# else Seed);
   end Reseed;

   procedure Raise_Invalid_Random_Argument (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Random_Argument;

   function Is_Finite_C_Double (Value : Long_Float) return Boolean is
      pragma Suppress (Validity_Check);
   begin
      --  Nonfinite bounds must be rejected as OpenCV_Error, so validity
      --  checks cannot fire before 'Valid is tested.
      return
        Value'Valid
        and then Value = Value
        and then Value >= Long_Float (OpenCV.Internal.C_API.C_Double'First)
        and then Value <= Long_Float (OpenCV.Internal.C_API.C_Double'Last);
   end Is_Finite_C_Double;

   procedure Validate_Uniform_Random_Bounds
     (Lower_Bound : Long_Float;
      Upper_Bound : Long_Float;
      C_Lower     : out OpenCV.Internal.C_API.C_Double;
      C_Upper     : out OpenCV.Internal.C_API.C_Double)
   is
      pragma Suppress (Validity_Check);
   begin
      if not Is_Finite_C_Double (Lower_Bound)
        or else not Is_Finite_C_Double (Upper_Bound)
      then
         Raise_Invalid_Random_Argument
           ("Uniform random bounds must be finite C double values");
      end if;

      if Lower_Bound > Upper_Bound then
         Raise_Invalid_Random_Argument
           ("Uniform random lower bound must not exceed upper bound");
      end if;

      C_Lower := OpenCV.Internal.C_API.C_Double (Lower_Bound);
      C_Upper := OpenCV.Internal.C_API.C_Double (Upper_Bound);

      --  This comparison avoids evaluating the potentially overflowing
      --  subtraction OpenCV performs for the distribution width.
      if C_Lower < 0.0
        and then C_Upper > 0.0
        and then C_Upper > OpenCV.Internal.C_API.C_Double'Last + C_Lower
      then
         Raise_Invalid_Random_Argument
           ("Uniform random bound width must be finite C double");
      end if;
   end Validate_Uniform_Random_Bounds;

   procedure Next_Random
     (Generator : in out Random_Number_Generator;
      Value     : out Interfaces.Unsigned_32)
   is
      C_State : aliased OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64 (Generator.State);
      C_Value : aliased OpenCV.Internal.C_API.C_UInt32 := 0;
      Result  : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.RNG_Next (C_State'Access, C_Value'Access);
   begin
      Raise_On_Error (Result, "OpenCV random next operation");
      Generator.State := Interfaces.Unsigned_64 (C_State);
      Value := Interfaces.Unsigned_32 (C_Value);
   end Next_Random;

   procedure Uniform_Random
     (Generator   : in out Random_Number_Generator;
      Lower_Bound : Long_Float;
      Upper_Bound : Long_Float;
      Value       : out Long_Float)
   is
      pragma Suppress (Validity_Check);
      C_Lower : OpenCV.Internal.C_API.C_Double;
      C_Upper : OpenCV.Internal.C_API.C_Double;
      C_State : aliased OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64 (Generator.State);
      C_Value : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Result  : OpenCV.Internal.C_API.Status;
   begin
      Validate_Uniform_Random_Bounds
        (Lower_Bound, Upper_Bound, C_Lower, C_Upper);
      Result :=
        OpenCV.Internal.C_API.RNG_Uniform_Double
          (C_State'Access, C_Lower, C_Upper, C_Value'Access);
      Raise_On_Error (Result, "OpenCV uniform random operation");
      Generator.State := Interfaces.Unsigned_64 (C_State);
      Value := Long_Float (C_Value);
   end Uniform_Random;

   procedure Validate_Random_Fill_Destination
     (Self : Mat; Operation : String; Normal : Boolean) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " requires a non-empty Mat");
      end if;

      if Self.Channels > 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " supports Mats with one through four channels");
      end if;

      if Normal and then Self.Depth = Float16 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Normal random fill does not support Float16 Mats");
      end if;
   end Validate_Random_Fill_Destination;

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

   procedure Fill_Uniform
     (Self : in out Mat; Lower_Bound, Upper_Bound : Scalar)
   is
      C_Lower : aliased OpenCV.Internal.C_API.Scalar :=
        To_C_Scalar (Lower_Bound);
      C_Upper : aliased OpenCV.Internal.C_API.Scalar :=
        To_C_Scalar (Upper_Bound);
      Result  : OpenCV.Internal.C_API.Status;
   begin
      Validate_Random_Fill_Destination (Self, "Uniform random fill", False);
      Result :=
        OpenCV.Internal.C_API.Mat_Fill_Uniform
          (Self.Handle, C_Lower'Access, C_Upper'Access);
      Raise_On_Error (Result, "Uniform random fill");
   end Fill_Uniform;

   procedure Fill_Uniform
     (Self        : in out Mat;
      Generator   : in out Random_Number_Generator;
      Lower_Bound : Scalar;
      Upper_Bound : Scalar)
   is
      C_Lower : aliased OpenCV.Internal.C_API.Scalar :=
        To_C_Scalar (Lower_Bound);
      C_Upper : aliased OpenCV.Internal.C_API.Scalar :=
        To_C_Scalar (Upper_Bound);
      C_State : aliased OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64 (Generator.State);
      Result  : OpenCV.Internal.C_API.Status;
   begin
      Validate_Random_Fill_Destination (Self, "Uniform random fill", False);
      Result :=
        OpenCV.Internal.C_API.Mat_Fill_Uniform_RNG
          (Self.Handle, C_Lower'Access, C_Upper'Access, C_State'Access);
      Raise_On_Error (Result, "Uniform random fill");
      Generator.State := Interfaces.Unsigned_64 (C_State);
   end Fill_Uniform;

   procedure Fill_Normal
     (Self : in out Mat; Mean : Scalar; Standard_Deviation : Scalar)
   is
      C_Mean   : aliased OpenCV.Internal.C_API.Scalar := To_C_Scalar (Mean);
      C_Stddev : aliased OpenCV.Internal.C_API.Scalar :=
        To_C_Scalar (Standard_Deviation);
      Result   : OpenCV.Internal.C_API.Status;
   begin
      Validate_Random_Fill_Destination (Self, "Normal random fill", True);
      Result :=
        OpenCV.Internal.C_API.Mat_Fill_Normal
          (Self.Handle, C_Mean'Access, C_Stddev'Access);
      Raise_On_Error (Result, "Normal random fill");
   end Fill_Normal;

   procedure Fill_Normal
     (Self               : in out Mat;
      Generator          : in out Random_Number_Generator;
      Mean               : Scalar;
      Standard_Deviation : Scalar)
   is
      C_Mean   : aliased OpenCV.Internal.C_API.Scalar := To_C_Scalar (Mean);
      C_Stddev : aliased OpenCV.Internal.C_API.Scalar :=
        To_C_Scalar (Standard_Deviation);
      C_State  : aliased OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64 (Generator.State);
      Result   : OpenCV.Internal.C_API.Status;
   begin
      Validate_Random_Fill_Destination (Self, "Normal random fill", True);
      Result :=
        OpenCV.Internal.C_API.Mat_Fill_Normal_RNG
          (Self.Handle, C_Mean'Access, C_Stddev'Access, C_State'Access);
      Raise_On_Error (Result, "Normal random fill");
      Generator.State := Interfaces.Unsigned_64 (C_State);
   end Fill_Normal;

   function Shuffle_Element_Size (Self : Mat) return Mat_Size is
      Channel_Bytes : constant Mat_Size :=
        (case Self.Depth is
           when UInt8 | Int8             => 1,
           when UInt16 | Int16 | Float16 => 2,
           when Int32 | Float32          => 4,
           when Float64                  => 8);
   begin
      return Channel_Bytes * Mat_Size (Self.Channels);
   end Shuffle_Element_Size;

   procedure Validate_Shuffle_Destination (Self : Mat) is
      Element_Bytes : Mat_Size;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Shuffle requires a non-empty Mat");
      end if;

      if Self.Rows /= 1 and then Self.Columns /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Shuffle requires a row or column vector");
      end if;

      Element_Bytes := Shuffle_Element_Size (Self);
      if Element_Bytes not in 1 | 2 | 3 | 4 | 6 | 8 | 12 | 16 | 24 | 32 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Shuffle does not support this complete Mat element size");
      end if;
   end Validate_Shuffle_Destination;

   procedure Shuffle (Self : in out Mat) is
      Result : OpenCV.Internal.C_API.Status;
   begin
      Validate_Shuffle_Destination (Self);
      Result := OpenCV.Internal.C_API.Mat_Shuffle (Self.Handle);
      Raise_On_Error (Result, "Mat shuffle");
   end Shuffle;

   procedure Shuffle
     (Self : in out Mat; Generator : in out Random_Number_Generator)
   is
      C_State : aliased OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64 (Generator.State);
      Result  : OpenCV.Internal.C_API.Status;
   begin
      Validate_Shuffle_Destination (Self);
      Result :=
        OpenCV.Internal.C_API.Mat_Shuffle_RNG (Self.Handle, C_State'Access);
      Raise_On_Error (Result, "Mat shuffle");
      Generator.State := Interfaces.Unsigned_64 (C_State);
   end Shuffle;

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

   function Determinant (Self : Mat) return Long_Float is
      C_Result : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status   : OpenCV.Internal.C_API.Status;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Determinant requires a non-empty Mat");
      end if;

      if Self.Rows /= Self.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Determinant requires a square Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Determinant requires a single-channel Mat");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Determinant requires a Float32 or Float64 Mat");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Determinant
          (Source => Self.Handle, Result => C_Result'Access);
      Raise_On_Error (Status, "Mat determinant operation");
      return Long_Float (C_Result);
   end Determinant;

   function Invert (Self : Mat) return Inversion_Result is
      Invertible : aliased OpenCV.Internal.C_API.C_Boolean :=
        OpenCV.Internal.C_API.C_False;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Invert requires a non-empty Mat");
      end if;

      if Self.Rows /= Self.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Invert requires a square Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Invert requires a single-channel Mat");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Invert requires a Float32 or Float64 Mat");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Invert
          (Source     => Self.Handle,
           Invertible => Invertible'Access,
           Result     => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat invert operation");
      end if;

      if Invertible = OpenCV.Internal.C_API.C_False then
         if New_Handle /= OpenCV.Internal.C_API.Null_Mat_Handle then
            OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Mat invert operation reported a singular matrix with a result"
               & " handle");
         end if;

         return (Invertible => False);
      end if;

      if Invertible /= OpenCV.Internal.C_API.C_True then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat invert operation returned an invalid Boolean value");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat invert operation returned a null result handle");
      end if;

      declare
         Result : Inversion_Result (Invertible => True);
      begin
         OpenCV.Internal.C_API.Mat_Destroy (Result.Inverse.Handle);
         Result.Inverse.Handle := New_Handle;
         return Result;
      end;
   end Invert;

   function Solve (Self : Mat; Right_Hand_Side : Mat) return Solve_Result is
      Solved     : aliased OpenCV.Internal.C_API.C_Boolean :=
        OpenCV.Internal.C_API.C_False;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Solve requires a non-empty Mat");
      end if;

      if Self.Rows /= Self.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Solve requires a square Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Solve requires a single-channel Mat");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Solve requires a Float32 or Float64 Mat");
      end if;

      if Right_Hand_Side.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve requires a non-empty right-hand side");
      end if;

      if Right_Hand_Side.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve requires a single-channel right-hand side");
      end if;

      if Right_Hand_Side.Depth /= Self.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve requires a right-hand side with the same depth as Self");
      end if;

      if Right_Hand_Side.Rows /= Self.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve requires a right-hand side with the same number of rows"
            & " as Self");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Solve
          (Coefficients    => Self.Handle,
           Right_Hand_Side => Right_Hand_Side.Handle,
           Solved          => Solved'Access,
           Result          => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat solve operation");
      end if;

      if Solved = OpenCV.Internal.C_API.C_False then
         if New_Handle /= OpenCV.Internal.C_API.Null_Mat_Handle then
            OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Mat solve operation reported a singular matrix with a result"
               & " handle");
         end if;

         return (Solved => False);
      end if;

      if Solved /= OpenCV.Internal.C_API.C_True then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat solve operation returned an invalid Boolean value");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat solve operation returned a null result handle");
      end if;

      declare
         Result : Solve_Result (Solved => True);
      begin
         OpenCV.Internal.C_API.Mat_Destroy (Result.Solution.Handle);
         Result.Solution.Handle := New_Handle;
         return Result;
      end;
   end Solve;

   function Solve_Least_Squares (Self : Mat; Right_Hand_Side : Mat) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Least_Squares requires a non-empty coefficient Mat");
      end if;
      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Least_Squares requires a single-channel coefficient Mat");
      end if;
      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Least_Squares requires Float32 or Float64 coefficients");
      end if;
      if Self.Rows < Self.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Least_Squares does not support underdetermined systems");
      end if;
      if Right_Hand_Side.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Least_Squares requires a non-empty right-hand side");
      end if;
      if Right_Hand_Side.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Least_Squares requires a single-channel right-hand side");
      end if;
      if Right_Hand_Side.Depth /= Float32
        and then Right_Hand_Side.Depth /= Float64
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Least_Squares requires a Float32 or Float64"
            & " right-hand side");
      end if;
      if Right_Hand_Side.Depth /= Self.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Least_Squares requires matching input depths");
      end if;
      if Right_Hand_Side.Rows /= Self.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Least_Squares requires B.Rows = A.Rows");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Solve_Least_Squares
          (Coefficients    => Self.Handle,
           Right_Hand_Side => Right_Hand_Side.Handle,
           Result          => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat SVD least-squares solve operation");
      end if;
      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat SVD least-squares solve operation returned a null"
            & " result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Solve_Least_Squares;

   function Solve_Linear_Program
     (Objective            : Mat;
      Constraints          : Mat;
      Constraint_Tolerance : Long_Float := 1.0E-12)
      return Linear_Program_Result
   is
      LP_Status  : aliased OpenCV.Internal.C_API.C_Int32 :=
        OpenCV.Internal.C_API.LP_Infeasible;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
      Variables  : Natural;
   begin
      if Objective.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires a non-empty objective");
      end if;
      if Objective.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires a single-channel objective");
      end if;
      if Objective.Depth /= Float32 and then Objective.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires a Float32 or Float64 objective");
      end if;
      if not (Objective.Rows = 1 or else Objective.Columns = 1) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires a row or column objective vector");
      end if;
      Variables :=
        (if Objective.Rows = 1 then Objective.Columns else Objective.Rows);
      if Variables = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires at least one variable");
      end if;
      if Variables > OpenCV.Internal.Safe_Arithmetic.Signed_Int32_Max - 2 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program variable count exceeds INT32_MAX - 2");
      end if;
      if Constraints.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires non-empty constraints");
      end if;
      if Constraints.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires single-channel constraints");
      end if;
      if Constraints.Depth /= Float32 and then Constraints.Depth /= Float64
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires Float32 or Float64 constraints");
      end if;
      if Constraints.Rows = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires at least one constraint row");
      end if;
      if Constraints.Columns /= Variables + 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires Constraints.Columns = N + 1");
      end if;
      if not Objective.Check_Range.Valid
        or else not Constraints.Check_Range.Valid
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires finite coefficients");
      end if;
      if not (Constraint_Tolerance >= 0.0
              and then Constraint_Tolerance <= Long_Float'Last)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Linear_Program requires a finite nonnegative tolerance");
      end if;

      Status :=
        OpenCV.Internal.C_API.Solve_Linear_Program
          (Objective            => Objective.Handle,
           Constraints          => Constraints.Handle,
           Constraint_Tolerance =>
             OpenCV.Internal.C_API.C_Double (Constraint_Tolerance),
           LP_Status            => LP_Status'Access,
           Solution             => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         declare
            Diagnostic : constant String :=
              OpenCV.Internal.C_API.Last_Error_Message;
         begin
            if New_Handle /= OpenCV.Internal.C_API.Null_Mat_Handle then
               OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
            end if;
            if Diagnostic'Length = 0 then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "linear program solve operation failed");
            else
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "linear program solve operation failed: " & Diagnostic);
            end if;
         end;
      end if;

      case LP_Status is
         when OpenCV.Internal.C_API.LP_Unique
            | OpenCV.Internal.C_API.LP_Multiple       =>
            if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "linear program returned an optimum without a solution");
            end if;
            if LP_Status = OpenCV.Internal.C_API.LP_Unique then
               declare
                  Result : Linear_Program_Result (Status => Unique_Optimum);
               begin
                  OpenCV.Internal.C_API.Mat_Destroy (Result.Solution.Handle);
                  Result.Solution.Handle := New_Handle;
                  return Result;
               end;
            else
               declare
                  Result : Linear_Program_Result (Status => Multiple_Optima);
               begin
                  OpenCV.Internal.C_API.Mat_Destroy (Result.Solution.Handle);
                  Result.Solution.Handle := New_Handle;
                  return Result;
               end;
            end if;

         when OpenCV.Internal.C_API.LP_Unbounded
            | OpenCV.Internal.C_API.LP_Infeasible
            | OpenCV.Internal.C_API.LP_Numerical_Loss =>
            if New_Handle /= OpenCV.Internal.C_API.Null_Mat_Handle then
               OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "linear program returned a solution for a non-optimal"
                  & " status");
            end if;
            if LP_Status = OpenCV.Internal.C_API.LP_Unbounded then
               return (Status => Unbounded);
            elsif LP_Status = OpenCV.Internal.C_API.LP_Infeasible then
               return (Status => Infeasible);
            else
               return (Status => Numerical_Loss);
            end if;

         when others                                  =>
            OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "linear program returned an invalid binding status");
      end case;
   end Solve_Linear_Program;

   function Solve_Cubic (Coefficients : Mat) return Cubic_Solution_Result is
      Root_Count : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      if Coefficients.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Solve_Cubic requires a non-empty Mat");
      end if;

      if Coefficients.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Cubic requires a single-channel coefficient vector");
      end if;

      if Coefficients.Depth /= Float32 and then Coefficients.Depth /= Float64
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Cubic requires a Float32 or Float64 coefficient vector");
      end if;

      if not ((Coefficients.Rows = 1
               and then (Coefficients.Columns = 3
                         or else Coefficients.Columns = 4))
              or else (Coefficients.Columns = 1
                       and then (Coefficients.Rows = 3
                                 or else Coefficients.Rows = 4)))
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Cubic requires a 1 x 3, 3 x 1, 1 x 4, or 4 x 1 vector");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Solve_Cubic
          (Coefficients => Coefficients.Handle,
           Root_Count   => Root_Count'Access,
           Result       => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Solve_Cubic operation");
      end if;

      case Root_Count is
         when -1        =>
            if New_Handle /= OpenCV.Internal.C_API.Null_Mat_Handle then
               OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Solve_Cubic returned roots for an identically-zero"
                  & " equation");
            end if;
            return (Status => Infinitely_Many_Roots);

         when 0         =>
            if New_Handle /= OpenCV.Internal.C_API.Null_Mat_Handle then
               OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Solve_Cubic returned roots for an equation without"
                  & " real roots");
            end if;
            return (Status => No_Real_Roots);

         when 1 | 2 | 3 =>
            if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Solve_Cubic returned a positive root count without roots");
            end if;

            declare
               Result :
                 Cubic_Solution_Result
                   (Status =>
                      (case Root_Count is
                         when 1      => One_Real_Root,
                         when 2      => Two_Real_Roots,
                         when others => Three_Real_Roots));
            begin
               OpenCV.Internal.C_API.Mat_Destroy (Result.Roots.Handle);
               Result.Roots.Handle := New_Handle;
               return Result;
            end;

         when others    =>
            OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Solve_Cubic returned an invalid mathematical root count");
      end case;
   end Solve_Cubic;

   function Solve_Polynomial
     (Coefficients : Mat; Maximum_Iterations : Positive := 300)
      return Polynomial_Solution_Result
   is
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Correction : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status     : OpenCV.Internal.C_API.Status;

      Coefficient_Count       : Natural;
      Effective_Degree        : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Has_Leading_Coefficient : aliased OpenCV.Internal.C_API.C_Boolean :=
        OpenCV.Internal.C_API.C_False;
   begin
      if Coefficients.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Polynomial requires a non-empty coefficient vector");
      end if;

      if Coefficients.Channels > 2 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Polynomial requires one or two coefficient channels");
      end if;

      if Coefficients.Depth /= Float32 and then Coefficients.Depth /= Float64
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Polynomial requires Float32 or Float64 coefficients");
      end if;

      if Coefficients.Rows /= 1 and then Coefficients.Columns /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Polynomial requires a row or column coefficient vector");
      end if;

      Coefficient_Count :=
        (if Coefficients.Rows = 1
         then Coefficients.Columns
         else Coefficients.Rows);
      if Coefficient_Count < 2 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Polynomial requires at least two coefficients");
      end if;

      if Coefficient_Count - 1 > 1_073_741_822 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Polynomial coefficient vector exceeds OpenCV's safe range");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Solve_Poly_Effective_Degree
          (Coefficients            => Coefficients.Handle,
           Degree                  => Effective_Degree'Access,
           Has_Leading_Coefficient => Has_Leading_Coefficient'Access);
      Raise_On_Error (Status, "Solve_Polynomial effective-degree calculation");

      if Effective_Degree <= 0
        or else Has_Leading_Coefficient = OpenCV.Internal.C_API.C_False
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Polynomial rejects constant and identically-zero"
            & " polynomials");
      end if;

      if not OpenCV.Internal.Safe_Arithmetic.Fits_Signed_Int32
               (Long_Long_Integer (Maximum_Iterations))
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Polynomial maximum iterations exceeds the C ABI range");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Solve_Poly
          (Coefficients       => Coefficients.Handle,
           Maximum_Iterations =>
             OpenCV.Internal.Safe_Arithmetic.To_Signed_Int32
               (Long_Long_Integer (Maximum_Iterations)),
           Roots              => New_Handle'Access,
           Maximum_Correction => Correction'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Solve_Polynomial operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Solve_Polynomial returned a null roots handle");
      end if;

      declare
         Result : Polynomial_Solution_Result;
      begin
         OpenCV.Internal.C_API.Mat_Destroy (Result.Roots.Handle);
         Result.Roots.Handle := New_Handle;
         Result.Maximum_Correction := Long_Float (Correction);
         return Result;
      end;
   end Solve_Polynomial;

   function Supports_Dot_Product_Depth (Self : Mat) return Boolean
   is (Self.Depth = UInt8
       or else Self.Depth = Int8
       or else Self.Depth = UInt16
       or else Self.Depth = Int16
       or else Self.Depth = Int32
       or else Self.Depth = Float32
       or else Self.Depth = Float64);

   function Dot_Product (Self : Mat; Other : Mat) return Long_Float is
      C_Result : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status   : OpenCV.Internal.C_API.Status;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Dot_Product requires a non-empty Self Mat");
      end if;

      if Other.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Dot_Product requires a non-empty Other Mat");
      end if;

      if Self.Rows /= Other.Rows or else Self.Columns /= Other.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Dot_Product requires operands with identical rows and columns");
      end if;

      if Self.Depth /= Other.Depth or else Self.Channels /= Other.Channels then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Dot_Product requires operands with identical complete"
            & " element types");
      end if;

      if not Supports_Dot_Product_Depth (Self) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Dot_Product requires a UInt8, Int8, UInt16, Int16, Int32,"
            & " Float32, or Float64 Mat");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Dot_Product
          (Left   => Self.Handle,
           Right  => Other.Handle,
           Result => C_Result'Access);
      Raise_On_Error (Status, "Mat dot product operation");
      return Long_Float (C_Result);
   end Dot_Product;

   function Is_Row_Or_Column_Vector (Self : Mat) return Boolean
   is (Self.Rows = 1 or else Self.Columns = 1);

   function Vector_Length (Self : Mat) return Natural
   is (if Self.Rows = 1 then Self.Columns else Self.Rows);

   function Mahalanobis_Distance
     (Self : Mat; Other : Mat; Inverse_Covariance : Mat) return Long_Float
   is
      C_Result : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status   : OpenCV.Internal.C_API.Status;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mahalanobis_Distance requires a non-empty Self Mat");
      end if;

      if Other.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mahalanobis_Distance requires a non-empty Other Mat");
      end if;

      if Self.Rows /= Other.Rows or else Self.Columns /= Other.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mahalanobis_Distance requires Self and Other with identical"
            & " rows and columns");
      end if;

      if Self.Depth /= Other.Depth or else Self.Channels /= Other.Channels then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mahalanobis_Distance requires Self and Other with identical"
            & " complete element types");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mahalanobis_Distance requires single-channel vectors");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mahalanobis_Distance requires Float32 or Float64 vectors");
      end if;

      if not Is_Row_Or_Column_Vector (Self) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mahalanobis_Distance requires Self and Other to be row or"
            & " column vectors");
      end if;

      if Inverse_Covariance.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mahalanobis_Distance requires a non-empty Inverse_Covariance"
            & " Mat");
      end if;

      if Inverse_Covariance.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mahalanobis_Distance requires a single-channel"
            & " Inverse_Covariance");
      end if;

      if Inverse_Covariance.Depth /= Self.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mahalanobis_Distance requires Inverse_Covariance to have the"
            & " same depth as the vectors");
      end if;

      if Inverse_Covariance.Rows /= Vector_Length (Self)
        or else Inverse_Covariance.Columns /= Vector_Length (Self)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mahalanobis_Distance requires Inverse_Covariance to be N x N"
            & " for an N-element vector");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Mahalanobis_Distance
          (Left               => Self.Handle,
           Right              => Other.Handle,
           Inverse_Covariance => Inverse_Covariance.Handle,
           Result             => C_Result'Access);
      Raise_On_Error (Status, "Mat Mahalanobis distance operation");
      return Long_Float (C_Result);
   end Mahalanobis_Distance;

   function Is_Supported_Cross_Product_Vector (Self : Mat) return Boolean
   is ((Self.Rows = 3 and then Self.Columns = 1 and then Self.Channels = 1)
       or else (Self.Rows = 1
                and then Self.Columns = 3
                and then Self.Channels = 1)
       or else (Self.Rows = 1
                and then Self.Columns = 1
                and then Self.Channels = 3));

   function Cross_Product (Self : Mat; Other : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Cross_Product requires a non-empty Self Mat");
      end if;

      if Other.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Cross_Product requires a non-empty Other Mat");
      end if;

      if Self.Rows /= Other.Rows or else Self.Columns /= Other.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Cross_Product requires operands with identical rows"
            & " and columns");
      end if;

      if Self.Depth /= Other.Depth or else Self.Channels /= Other.Channels then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Cross_Product requires operands with identical complete"
            & " element types");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Cross_Product requires Float32 or Float64 vectors");
      end if;

      if not Is_Supported_Cross_Product_Vector (Self) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Cross_Product requires a 3x1 C1, 1x3 C1, or 1x1 C3 vector");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Cross_Product
          (Left   => Self.Handle,
           Right  => Other.Handle,
           Result => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat cross product operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat cross product operation returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Cross_Product;

   function Matrix_Multiply (Left, Right : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      if Left.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply requires a non-empty Left Mat");
      end if;

      if Right.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply requires a non-empty Right Mat");
      end if;

      if Left.Depth /= Right.Depth or else Left.Channels /= Right.Channels then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply requires operands with identical complete"
            & " element types");
      end if;

      if (Left.Depth /= Float32 and then Left.Depth /= Float64)
        or else (Left.Channels /= 1 and then Left.Channels /= 2)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply requires Float32 or Float64 Mats with one or"
            & " two channels");
      end if;

      if Left.Columns /= Right.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply requires Left.Columns to equal Right.Rows");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Matrix_Multiply
          (Left   => Left.Handle,
           Right  => Right.Handle,
           Result => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat matrix multiply operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat matrix multiply operation returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Matrix_Multiply;

   function Matrix_Multiply_Add
     (Left, Right   : Mat;
      Addend        : Mat;
      Product_Scale : Long_Float := 1.0;
      Addend_Scale  : Long_Float := 1.0) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      if Left.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply_Add requires a non-empty Left Mat");
      end if;

      if Right.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply_Add requires a non-empty Right Mat");
      end if;

      if Addend.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply_Add requires a non-empty Addend Mat");
      end if;

      if Left.Depth /= Right.Depth or else Left.Channels /= Right.Channels then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply_Add requires Left and Right with identical"
            & " complete element types");
      end if;

      if Addend.Depth /= Left.Depth or else Addend.Channels /= Left.Channels
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply_Add requires Addend to have the same complete"
            & " element type as Left and Right");
      end if;

      if (Left.Depth /= Float32 and then Left.Depth /= Float64)
        or else (Left.Channels /= 1 and then Left.Channels /= 2)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply_Add requires Float32 or Float64 Mats with one"
            & " or two channels");
      end if;

      if Left.Columns /= Right.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply_Add requires Left.Columns to equal Right.Rows");
      end if;

      if Addend.Rows /= Left.Rows or else Addend.Columns /= Right.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Matrix_Multiply_Add requires Addend to have shape Left.Rows x"
            & " Right.Columns");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Matrix_Multiply_Add
          (Left          => Left.Handle,
           Right         => Right.Handle,
           Addend        => Addend.Handle,
           Product_Scale => OpenCV.Internal.C_API.C_Double (Product_Scale),
           Addend_Scale  => OpenCV.Internal.C_API.C_Double (Addend_Scale),
           Result        => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat matrix multiply-add operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat matrix multiply-add operation returned a null result"
            & " handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Matrix_Multiply_Add;

   function To_C_Transposed_Product_Order
     (Value : Transposed_Product_Order) return OpenCV.Internal.C_API.C_UInt8
   is (case Value is
         when Transpose_Times_Self =>
           OpenCV.Internal.C_API.Transposed_Product_Transpose_Times_Self,
         when Self_Times_Transpose =>
           OpenCV.Internal.C_API.Transposed_Product_Self_Times_Transpose);

   function Supports_Transposed_Product_Source (Self : Mat) return Boolean
   is (Self.Depth = UInt8
       or else Self.Depth = UInt16
       or else Self.Depth = Int16
       or else Self.Depth = Float32
       or else Self.Depth = Float64);

   procedure Validate_Transposed_Product
     (Self : Mat; Output_Depth : Depth_Type; Explicit_Depth : Boolean) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transposed_Product requires a non-empty Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transposed_Product requires a single-channel Mat");
      end if;

      if not Supports_Transposed_Product_Source (Self) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transposed_Product requires a UInt8, UInt16, Int16, Float32,"
            & " or Float64 Mat");
      end if;

      if Explicit_Depth then
         if Output_Depth /= Float32 and then Output_Depth /= Float64 then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Transposed_Product output depth must be Float32 or Float64");
         end if;

         if Self.Depth = Float64 and then Output_Depth = Float32 then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Transposed_Product does not support Float64 source with"
               & " Float32 output");
         end if;
      end if;
   end Validate_Transposed_Product;

   function Call_Transposed_Product
     (Self         : Mat;
      Order        : Transposed_Product_Order;
      Scale        : Long_Float;
      Output_Depth : OpenCV.Internal.C_API.C_Int32) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Transposed_Product
          (Source       => Self.Handle,
           Order        => To_C_Transposed_Product_Order (Order),
           Scale        => OpenCV.Internal.C_API.C_Double (Scale),
           Output_Depth => Output_Depth,
           Result       => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat transposed product operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat transposed product operation returned a null result"
            & " handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Call_Transposed_Product;

   function Transposed_Product
     (Self : Mat; Order : Transposed_Product_Order; Scale : Long_Float := 1.0)
      return Mat is
   begin
      Validate_Transposed_Product
        (Self, Output_Depth => Float32, Explicit_Depth => False);
      return
        Call_Transposed_Product
          (Self, Order, Scale, OpenCV.Internal.C_API.Default_Output_Depth);
   end Transposed_Product;

   function Transposed_Product
     (Self         : Mat;
      Order        : Transposed_Product_Order;
      Output_Depth : Depth_Type;
      Scale        : Long_Float := 1.0) return Mat is
   begin
      Validate_Transposed_Product
        (Self, Output_Depth => Output_Depth, Explicit_Depth => True);
      return
        Call_Transposed_Product
          (Self, Order, Scale, To_C_Depth (Output_Depth));
   end Transposed_Product;

   function Supports_Transposed_Product_Offset (Offset : Mat) return Boolean
   is (Offset.Depth = UInt8
       or else Offset.Depth = Int8
       or else Offset.Depth = UInt16
       or else Offset.Depth = Int16
       or else Offset.Depth = Int32
       or else Offset.Depth = Float32
       or else Offset.Depth = Float64);

   function Offset_Broadcasts_To (Offset, Self : Mat) return Boolean
   is ((Offset.Rows = Self.Rows or else Offset.Rows = 1)
       and then (Offset.Columns = Self.Columns or else Offset.Columns = 1));

   procedure Validate_Transposed_Product_With_Offset
     (Self           : Mat;
      Offset         : Mat;
      Output_Depth   : Depth_Type;
      Explicit_Depth : Boolean) is
   begin
      Validate_Transposed_Product (Self, Output_Depth, Explicit_Depth);

      if Offset.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transposed_Product requires a non-empty Offset");
      end if;

      if Offset.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transposed_Product requires a single-channel Offset");
      end if;

      if Offset.Depth = Float16 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transposed_Product does not support Float16 Offset");
      end if;

      if not Supports_Transposed_Product_Offset (Offset) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transposed_Product requires a UInt8, Int8, UInt16, Int16,"
            & " Int32, Float32, or Float64 Offset");
      end if;

      if not Offset_Broadcasts_To (Offset, Self) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transposed_Product Offset must have Self's rows or one row"
            & " and Self's columns or one column");
      end if;

      if Explicit_Depth
        and then Output_Depth = Float32
        and then Offset.Depth = Float64
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transposed_Product does not support Float64 Offset with"
            & " Float32 output");
      end if;
   end Validate_Transposed_Product_With_Offset;

   function Call_Transposed_Product_With_Offset
     (Self         : Mat;
      Offset       : Mat;
      Order        : Transposed_Product_Order;
      Scale        : Long_Float;
      Output_Depth : OpenCV.Internal.C_API.C_Int32) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Transposed_Product_With_Delta
          (Source       => Self.Handle,
           Offset       => Offset.Handle,
           Order        => To_C_Transposed_Product_Order (Order),
           Scale        => OpenCV.Internal.C_API.C_Double (Scale),
           Output_Depth => Output_Depth,
           Result       => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat centered transposed product operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat centered transposed product operation returned a null"
            & " result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Call_Transposed_Product_With_Offset;

   function Transposed_Product
     (Self   : Mat;
      Offset : Mat;
      Order  : Transposed_Product_Order;
      Scale  : Long_Float := 1.0) return Mat is
   begin
      Validate_Transposed_Product_With_Offset
        (Self, Offset, Output_Depth => Float32, Explicit_Depth => False);
      return
        Call_Transposed_Product_With_Offset
          (Self,
           Offset,
           Order,
           Scale,
           OpenCV.Internal.C_API.Default_Output_Depth);
   end Transposed_Product;

   function Transposed_Product
     (Self         : Mat;
      Offset       : Mat;
      Order        : Transposed_Product_Order;
      Output_Depth : Depth_Type;
      Scale        : Long_Float := 1.0) return Mat is
   begin
      Validate_Transposed_Product_With_Offset
        (Self, Offset, Output_Depth => Output_Depth, Explicit_Depth => True);
      return
        Call_Transposed_Product_With_Offset
          (Self, Offset, Order, Scale, To_C_Depth (Output_Depth));
   end Transposed_Product;

   procedure Validate_Covariance (Self : Mat; Orientation : Sample_Orientation)
   is
      Sample_Count : Natural;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Covariance requires a non-empty Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Covariance requires a single-channel Mat");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Covariance requires a Float32 or Float64 Mat");
      end if;

      Sample_Count :=
        (if Orientation = Samples_Are_Rows then Self.Rows else Self.Columns);
      if Sample_Count = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Covariance requires at least one sample");
      end if;
   end Validate_Covariance;

   function Covariance
     (Self        : Mat;
      Orientation : Sample_Orientation := Samples_Are_Rows;
      Scaling     : Covariance_Scaling := By_Sample_Count)
      return Covariance_Result
   is
      Result            : Covariance_Result;
      Covariance_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Mean_Handle       : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status            : OpenCV.Internal.C_API.Status;
   begin
      Validate_Covariance (Self, Orientation);
      Status :=
        OpenCV.Internal.C_API.Mat_Covariance
          (Source      => Self.Handle,
           Orientation => To_C_Sample_Orientation (Orientation),
           Scaling     => To_C_Covariance_Scaling (Scaling),
           Covariance  => Covariance_Handle'Access,
           Mean        => Mean_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (Covariance_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Mean_Handle);
         Raise_On_Error (Status, "Mat covariance operation");
      end if;

      if Covariance_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else Mean_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
      then
         OpenCV.Internal.C_API.Mat_Destroy (Covariance_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Mean_Handle);
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat covariance operation returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Covariance.Handle);
      Result.Covariance.Handle := Covariance_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Mean.Handle);
      Result.Mean.Handle := Mean_Handle;
      return Result;
   end Covariance;

   procedure Validate_Eigen_Decomposition (Self : Mat) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Eigen_Decomposition requires a non-empty Mat");
      end if;

      if Self.Rows /= Self.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Eigen_Decomposition requires a square Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Eigen_Decomposition requires a single-channel Mat");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Eigen_Decomposition requires a Float32 or Float64 Mat");
      end if;

      if Self.Rows > Maximum_Jacobi_Dimension then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Eigen_Decomposition dimension must not exceed 8460");
      end if;

   end Validate_Eigen_Decomposition;

   function Eigen_Decomposition (Self : Mat) return Eigen_Decomposition_Result
   is
      Result              : Eigen_Decomposition_Result;
      Eigenvalues_Handle  : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Eigenvectors_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status              : OpenCV.Internal.C_API.Status;
   begin
      Validate_Eigen_Decomposition (Self);
      Status :=
        OpenCV.Internal.C_API.Mat_Eigen_Decomposition
          (Source       => Self.Handle,
           Eigenvalues  => Eigenvalues_Handle'Access,
           Eigenvectors => Eigenvectors_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvalues_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvectors_Handle);
         Raise_On_Error (Status, "Mat eigen decomposition operation");
      end if;

      if Eigenvalues_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else Eigenvectors_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
      then
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvalues_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvectors_Handle);
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat eigen decomposition operation returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Eigenvalues.Handle);
      Result.Eigenvalues.Handle := Eigenvalues_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Eigenvectors.Handle);
      Result.Eigenvectors.Handle := Eigenvectors_Handle;
      return Result;
   end Eigen_Decomposition;

   procedure Validate_Non_Symmetric_Eigen_Decomposition (Self : Mat) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Non_Symmetric_Eigen_Decomposition requires a non-empty Mat");
      end if;

      if Self.Rows /= Self.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Non_Symmetric_Eigen_Decomposition requires a square Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Non_Symmetric_Eigen_Decomposition requires a single-channel Mat");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Non_Symmetric_Eigen_Decomposition requires a Float32 or"
            & " Float64 Mat");
      end if;
   end Validate_Non_Symmetric_Eigen_Decomposition;

   function Non_Symmetric_Eigen_Decomposition
     (Self : Mat) return Eigen_Decomposition_Result
   is
      Result              : Eigen_Decomposition_Result;
      Eigenvalues_Handle  : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Eigenvectors_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status              : OpenCV.Internal.C_API.Status;
   begin
      Validate_Non_Symmetric_Eigen_Decomposition (Self);
      Status :=
        OpenCV.Internal.C_API.Mat_Non_Symmetric_Eigen_Decomposition
          (Source       => Self.Handle,
           Eigenvalues  => Eigenvalues_Handle'Access,
           Eigenvectors => Eigenvectors_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvalues_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvectors_Handle);
         Raise_On_Error
           (Status, "Mat non-symmetric eigen decomposition operation");
      end if;

      if Eigenvalues_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else Eigenvectors_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
      then
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvalues_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvectors_Handle);
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat non-symmetric eigen decomposition operation returned a"
            & " null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Eigenvalues.Handle);
      Result.Eigenvalues.Handle := Eigenvalues_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Eigenvectors.Handle);
      Result.Eigenvectors.Handle := Eigenvectors_Handle;
      return Result;
   end Non_Symmetric_Eigen_Decomposition;

   function Validate_Linear_Discriminant_Analysis
     (Samples : Mat; Labels : Mat; Components : Natural; Explicit_K : Boolean)
      return Natural
   is
      Maximum_Components : Natural;
   begin
      if Samples.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Linear_Discriminant_Analysis requires non-empty Samples");
      end if;
      if Samples.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Linear_Discriminant_Analysis requires single-channel Samples");
      end if;
      if Samples.Depth /= Float32 and then Samples.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Linear_Discriminant_Analysis requires Float32 or Float64"
            & " Samples");
      end if;
      if Samples.Rows = 0 or else Samples.Columns = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Linear_Discriminant_Analysis requires at least one sample"
            & " and feature");
      end if;
      if Samples.Columns > Maximum_Jacobi_Dimension then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Linear_Discriminant_Analysis feature count must not exceed 8460");
      end if;
      if not Samples.Check_Range.Valid then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Linear_Discriminant_Analysis requires finite Samples");
      end if;
      if Labels.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Linear_Discriminant_Analysis requires non-empty Labels");
      end if;
      if Labels.Channels /= 1 or else Labels.Depth /= Int32 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Linear_Discriminant_Analysis requires Int32 C1 Labels");
      end if;
      if (Labels.Rows /= 1 and then Labels.Columns /= 1)
        or else Labels.Total /= Mat_Size (Samples.Rows)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Linear_Discriminant_Analysis Labels must be a row or column"
            & " vector with one entry per sample");
      end if;

      Maximum_Components := Samples.Columns;
      if Explicit_K and then Components > Maximum_Components then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Linear_Discriminant_Analysis Components must not exceed"
            & " the feature count");
      end if;
      return Maximum_Components;
   end Validate_Linear_Discriminant_Analysis;

   function Linear_Discriminant_Analysis_Impl
     (Samples : Mat; Labels : Mat; Components : Natural)
      return Linear_Discriminant_Analysis_Result
   is
      Result              : Linear_Discriminant_Analysis_Result;
      Eigenvalues_Handle  : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Eigenvectors_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status              : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Linear_Discriminant_Analysis
          (Samples.Handle,
           Labels.Handle,
           OpenCV.Internal.C_API.C_Int32 (Components),
           Eigenvalues_Handle'Access,
           Eigenvectors_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvalues_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvectors_Handle);
         Raise_On_Error (Status, "Mat linear discriminant analysis operation");
      end if;
      if Eigenvalues_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else Eigenvectors_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
      then
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvalues_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvectors_Handle);
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat linear discriminant analysis operation returned a null"
            & " result handle");
      end if;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Eigenvalues.Handle);
      Result.Eigenvalues.Handle := Eigenvalues_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Eigenvectors.Handle);
      Result.Eigenvectors.Handle := Eigenvectors_Handle;
      return Result;
   end Linear_Discriminant_Analysis_Impl;

   function Linear_Discriminant_Analysis
     (Samples : Mat; Labels : Mat) return Linear_Discriminant_Analysis_Result
   is
      Unused : constant Natural :=
        Validate_Linear_Discriminant_Analysis
          (Samples, Labels, Components => 0, Explicit_K => False);
   begin
      pragma Unreferenced (Unused);
      return
        Linear_Discriminant_Analysis_Impl (Samples, Labels, Components => 0);
   end Linear_Discriminant_Analysis;

   function Linear_Discriminant_Analysis
     (Samples : Mat; Labels : Mat; Components : Positive)
      return Linear_Discriminant_Analysis_Result
   is
      Unused : constant Natural :=
        Validate_Linear_Discriminant_Analysis
          (Samples, Labels, Components, Explicit_K => True);
   begin
      pragma Unreferenced (Unused);
      return Linear_Discriminant_Analysis_Impl (Samples, Labels, Components);
   end Linear_Discriminant_Analysis;

   procedure Validate_LDA_Basis (Basis : Linear_Discriminant_Analysis_Result)
   is
      Feature_Count   : Natural;
      Component_Count : Natural;
   begin
      if Basis.Eigenvectors.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "LDA basis Eigenvectors must be a non-empty Mat");
      end if;
      if Basis.Eigenvectors.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "LDA basis Eigenvectors must be a single-channel Mat");
      end if;
      if Basis.Eigenvectors.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "LDA basis Eigenvectors must be a Float64 Mat");
      end if;

      Feature_Count := Basis.Eigenvectors.Rows;
      Component_Count := Basis.Eigenvectors.Columns;
      if Feature_Count = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "LDA basis Eigenvectors must have at least one row");
      end if;
      if Component_Count = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "LDA basis Eigenvectors must have at least one column");
      end if;
      if Component_Count > Feature_Count then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "LDA basis component count must not exceed the feature count");
      end if;
   end Validate_LDA_Basis;

   procedure Validate_LDA_Source (Self : Mat; Operation : String) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " requires a non-empty Mat");
      end if;
      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires a single-channel Mat");
      end if;
      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires a Float32 or Float64 Mat");
      end if;
      if Self.Rows = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " requires at least one row");
      end if;
   end Validate_LDA_Source;

   function Call_LDA_Projection
     (Self    : Mat;
      Basis   : Linear_Discriminant_Analysis_Result;
      Project : Boolean) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
      Operation  : constant String :=
        (if Project
         then "Mat LDA project operation"
         else "Mat LDA reconstruct operation");
   begin
      if Project then
         Status :=
           OpenCV.Internal.C_API.Mat_LDA_Project
             (Self.Handle, Basis.Eigenvectors.Handle, New_Handle'Access);
      else
         Status :=
           OpenCV.Internal.C_API.Mat_LDA_Reconstruct
             (Self.Handle, Basis.Eigenvectors.Handle, New_Handle'Access);
      end if;
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, Operation);
      end if;
      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " returned a null result handle");
      end if;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Call_LDA_Projection;

   function LDA_Project
     (Self : Mat; Basis : Linear_Discriminant_Analysis_Result) return Mat is
   begin
      Validate_LDA_Source (Self, "LDA_Project");
      Validate_LDA_Basis (Basis);
      if Self.Columns /= Basis.Eigenvectors.Rows then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "LDA_Project requires Self.Columns to equal the basis"
            & " feature count");
      end if;
      return Call_LDA_Projection (Self, Basis, Project => True);
   end LDA_Project;

   function LDA_Reconstruct
     (Self : Mat; Basis : Linear_Discriminant_Analysis_Result) return Mat is
   begin
      Validate_LDA_Source (Self, "LDA_Reconstruct");
      Validate_LDA_Basis (Basis);
      if Self.Columns /= Basis.Eigenvectors.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "LDA_Reconstruct requires Self.Columns to equal the basis"
            & " component count");
      end if;
      return Call_LDA_Projection (Self, Basis, Project => False);
   end LDA_Reconstruct;

   function Validate_Principal_Component_Analysis
     (Self        : Mat;
      Orientation : Sample_Orientation;
      Components  : Natural;
      Explicit_K  : Boolean) return Natural
   is
      Sample_Count         : Natural;
      Feature_Count        : Natural;
      Available_Components : Natural;
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Principal_Component_Analysis requires a non-empty Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Principal_Component_Analysis requires a single-channel Mat");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Principal_Component_Analysis requires a Float32 or Float64 Mat");
      end if;

      if Orientation = Samples_Are_Rows then
         Sample_Count := Self.Rows;
         Feature_Count := Self.Columns;
      else
         Sample_Count := Self.Columns;
         Feature_Count := Self.Rows;
      end if;

      if Sample_Count = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Principal_Component_Analysis requires at least one sample");
      end if;

      if Feature_Count = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Principal_Component_Analysis requires at least one feature");
      end if;

      Available_Components := Natural'Min (Sample_Count, Feature_Count);
      if Available_Components > 8_460 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Principal_Component_Analysis available component count"
            & " must not exceed 8460");
      end if;

      if Explicit_K and then Components > Available_Components then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Principal_Component_Analysis Components must not exceed"
            & " the available component count");
      end if;

      return Available_Components;
   end Validate_Principal_Component_Analysis;

   procedure Validate_Principal_Component_Analysis_Retained_Variance
     (Self              : Mat;
      Orientation       : Sample_Orientation;
      Retained_Variance : Long_Float)
   is
      Available_Components : constant Natural :=
        Validate_Principal_Component_Analysis
          (Self, Orientation, Components => 0, Explicit_K => False);
   begin
      if not (Retained_Variance > 0.0 and then Retained_Variance <= 1.0) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Principal_Component_Analysis Retained_Variance must be"
            & " greater than 0.0 and at most 1.0");
      end if;

      if Available_Components < 2 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Principal_Component_Analysis Retained_Variance requires"
            & " at least two available components");
      end if;
   end Validate_Principal_Component_Analysis_Retained_Variance;

   function Principal_Component_Analysis_Impl
     (Self : Mat; Orientation : Sample_Orientation; Max_Components : Natural)
      return Principal_Component_Analysis_Result
   is
      Result              : Principal_Component_Analysis_Result;
      Mean_Handle         : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Eigenvalues_Handle  : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Eigenvectors_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status              : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Principal_Component_Analysis
          (Source         => Self.Handle,
           Orientation    => To_C_Sample_Orientation (Orientation),
           Max_Components => OpenCV.Internal.C_API.C_Int32 (Max_Components),
           Mean           => Mean_Handle'Access,
           Eigenvalues    => Eigenvalues_Handle'Access,
           Eigenvectors   => Eigenvectors_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (Mean_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvalues_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvectors_Handle);
         Raise_On_Error (Status, "Mat principal component analysis operation");
      end if;

      if Mean_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else Eigenvalues_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else Eigenvectors_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
      then
         OpenCV.Internal.C_API.Mat_Destroy (Mean_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvalues_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvectors_Handle);
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat principal component analysis operation returned a"
            & " null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Mean.Handle);
      Result.Mean.Handle := Mean_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Eigenvalues.Handle);
      Result.Eigenvalues.Handle := Eigenvalues_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Eigenvectors.Handle);
      Result.Eigenvectors.Handle := Eigenvectors_Handle;
      return Result;
   end Principal_Component_Analysis_Impl;

   function Principal_Component_Analysis
     (Self : Mat; Orientation : Sample_Orientation := Samples_Are_Rows)
      return Principal_Component_Analysis_Result
   is
      Unused : constant Natural :=
        Validate_Principal_Component_Analysis
          (Self, Orientation, Components => 0, Explicit_K => False);
   begin
      pragma Unreferenced (Unused);
      return Principal_Component_Analysis_Impl (Self, Orientation, 0);
   end Principal_Component_Analysis;

   function Principal_Component_Analysis
     (Self        : Mat;
      Components  : Positive;
      Orientation : Sample_Orientation := Samples_Are_Rows)
      return Principal_Component_Analysis_Result
   is
      Unused : constant Natural :=
        Validate_Principal_Component_Analysis
          (Self, Orientation, Components, Explicit_K => True);
   begin
      pragma Unreferenced (Unused);
      return Principal_Component_Analysis_Impl (Self, Orientation, Components);
   end Principal_Component_Analysis;

   function Principal_Component_Analysis
     (Self              : Mat;
      Retained_Variance : Long_Float;
      Orientation       : Sample_Orientation := Samples_Are_Rows)
      return Principal_Component_Analysis_Result
   is
      Result              : Principal_Component_Analysis_Result;
      Mean_Handle         : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Eigenvalues_Handle  : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Eigenvectors_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status              : OpenCV.Internal.C_API.Status;
   begin
      Validate_Principal_Component_Analysis_Retained_Variance
        (Self, Orientation, Retained_Variance);
      Status :=
        OpenCV
          .Internal
          .C_API
          .Mat_Principal_Component_Analysis_Retained_Variance
             (Source            => Self.Handle,
              Orientation       => To_C_Sample_Orientation (Orientation),
              Retained_Variance =>
                OpenCV.Internal.C_API.C_Double (Retained_Variance),
              Mean              => Mean_Handle'Access,
              Eigenvalues       => Eigenvalues_Handle'Access,
              Eigenvectors      => Eigenvectors_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (Mean_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvalues_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvectors_Handle);
         Raise_On_Error (Status, "Mat principal component analysis operation");
      end if;

      if Mean_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else Eigenvalues_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else Eigenvectors_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
      then
         OpenCV.Internal.C_API.Mat_Destroy (Mean_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvalues_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (Eigenvectors_Handle);
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat principal component analysis operation returned a"
            & " null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Mean.Handle);
      Result.Mean.Handle := Mean_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Eigenvalues.Handle);
      Result.Eigenvalues.Handle := Eigenvalues_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Eigenvectors.Handle);
      Result.Eigenvectors.Handle := Eigenvectors_Handle;
      return Result;
   end Principal_Component_Analysis;

   procedure Validate_Singular_Value_Decomposition (Self : Mat) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Singular_Value_Decomposition requires a non-empty Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Singular_Value_Decomposition requires a single-channel Mat");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Singular_Value_Decomposition requires a Float32 or Float64 Mat");
      end if;
   end Validate_Singular_Value_Decomposition;

   function Singular_Value_Decomposition
     (Self : Mat) return Singular_Value_Decomposition_Result
   is
      Result                 : Singular_Value_Decomposition_Result;
      Singular_Values_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      U_Handle               : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      V_Transpose_Handle     : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status                 : OpenCV.Internal.C_API.Status;
   begin
      Validate_Singular_Value_Decomposition (Self);
      Status :=
        OpenCV.Internal.C_API.Mat_Singular_Value_Decomposition
          (Source          => Self.Handle,
           Singular_Values => Singular_Values_Handle'Access,
           U               => U_Handle'Access,
           V_Transpose     => V_Transpose_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (Singular_Values_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (U_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (V_Transpose_Handle);
         Raise_On_Error (Status, "Mat singular value decomposition operation");
      end if;

      if Singular_Values_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else U_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
        or else V_Transpose_Handle = OpenCV.Internal.C_API.Null_Mat_Handle
      then
         OpenCV.Internal.C_API.Mat_Destroy (Singular_Values_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (U_Handle);
         OpenCV.Internal.C_API.Mat_Destroy (V_Transpose_Handle);
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat singular value decomposition operation returned a"
            & " null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Singular_Values.Handle);
      Result.Singular_Values.Handle := Singular_Values_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.U.Handle);
      Result.U.Handle := U_Handle;
      OpenCV.Internal.C_API.Mat_Destroy (Result.V_Transpose.Handle);
      Result.V_Transpose.Handle := V_Transpose_Handle;
      return Result;
   end Singular_Value_Decomposition;

   function Is_SVD_Floating_Depth (Value : Depth_Type) return Boolean
   is (Value = Float32 or else Value = Float64);

   function Product_Exceeds_Signed_Int32 (Left, Right : Natural) return Boolean
   renames OpenCV.Internal.Safe_Arithmetic.Product_Exceeds_Signed_Int32;

   procedure Validate_SVD_Basis (Basis : Singular_Value_Decomposition_Result)
   is
      Rank         : Natural;
      Row_Count    : Natural;
      Column_Count : Natural;
      Compact_Rank : Natural;
   begin
      if Basis.Singular_Values.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis Singular_Values must be a non-empty Mat");
      end if;

      if Basis.Singular_Values.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis Singular_Values must be a single-channel Mat");
      end if;

      if not Is_SVD_Floating_Depth (Basis.Singular_Values.Depth) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis Singular_Values must be a Float32 or Float64 Mat");
      end if;

      if Basis.Singular_Values.Columns /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis Singular_Values must be an R x 1 column");
      end if;

      Rank := Basis.Singular_Values.Rows;
      if Rank = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis Singular_Values must have at least one row");
      end if;

      if Basis.U.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "SVD basis U must be a non-empty Mat");
      end if;

      if Basis.U.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "SVD basis U must be a single-channel Mat");
      end if;

      if Basis.U.Depth /= Basis.Singular_Values.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis U must have the same depth as Singular_Values");
      end if;

      Row_Count := Basis.U.Rows;
      if Row_Count = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "SVD basis U must have at least one row");
      end if;

      if Basis.U.Columns /= Rank then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis U must have Singular_Values.Rows columns");
      end if;

      if Basis.V_Transpose.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis V_Transpose must be a non-empty Mat");
      end if;

      if Basis.V_Transpose.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis V_Transpose must be a single-channel Mat");
      end if;

      if Basis.V_Transpose.Depth /= Basis.Singular_Values.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis V_Transpose must have the same depth as"
            & " Singular_Values");
      end if;

      if Basis.V_Transpose.Rows /= Rank then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis V_Transpose must have Singular_Values.Rows rows");
      end if;

      Column_Count := Basis.V_Transpose.Columns;
      if Column_Count = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis V_Transpose must have at least one column");
      end if;

      Compact_Rank :=
        (if Row_Count < Column_Count then Row_Count else Column_Count);
      if Rank /= Compact_Rank then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD basis rank must equal min (U.Rows, V_Transpose.Columns)");
      end if;
   end Validate_SVD_Basis;

   procedure Validate_SVD_Back_Substitution
     (Basis : Singular_Value_Decomposition_Result; Right_Hand_Side : Mat)
   is
      Row_Count    : Natural;
      Column_Count : Natural;
      Rank         : Natural;
   begin
      Validate_SVD_Basis (Basis);

      Row_Count := Basis.U.Rows;
      Column_Count := Basis.V_Transpose.Columns;
      Rank := Basis.Singular_Values.Rows;

      if Right_Hand_Side.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD_Back_Substitute requires a non-empty right-hand side");
      end if;

      if Right_Hand_Side.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD_Back_Substitute requires a single-channel right-hand side");
      end if;

      if Right_Hand_Side.Depth /= Basis.Singular_Values.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD_Back_Substitute requires a right-hand side with the same"
            & " depth as the basis");
      end if;

      if Right_Hand_Side.Rows /= Row_Count then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD_Back_Substitute requires a right-hand side with U.Rows"
            & " rows");
      end if;

      if Right_Hand_Side.Columns = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD_Back_Substitute requires a right-hand side with at least"
            & " one column");
      end if;

      if Product_Exceeds_Signed_Int32 (Column_Count, Right_Hand_Side.Columns)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD_Back_Substitute destination index N * K must not exceed"
            & " 2147483647");
      end if;

      if Product_Exceeds_Signed_Int32 (Row_Count, Rank) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD_Back_Substitute U index M * R must not exceed 2147483647");
      end if;

   end Validate_SVD_Back_Substitution;

   function SVD_Back_Substitute
     (Basis : Singular_Value_Decomposition_Result; Right_Hand_Side : Mat)
      return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_SVD_Back_Substitution (Basis, Right_Hand_Side);
      Status :=
        OpenCV.Internal.C_API.Mat_SVD_Back_Substitute
          (Singular_Values => Basis.Singular_Values.Handle,
           U               => Basis.U.Handle,
           V_Transpose     => Basis.V_Transpose.Handle,
           Right_Hand_Side => Right_Hand_Side.Handle,
           Result          => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat SVD back substitution operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat SVD back substitution operation returned a null result"
            & " handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end SVD_Back_Substitute;

   procedure Validate_Pseudo_Inverse (Self : Mat) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Pseudo_Inverse requires a non-empty Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Pseudo_Inverse requires a single-channel Mat");
      end if;

      if not Is_SVD_Floating_Depth (Self.Depth) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Pseudo_Inverse requires a Float32 or Float64 Mat");
      end if;

      if Product_Exceeds_Signed_Int32 (Self.Rows, Self.Columns) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Pseudo_Inverse destination index N * M must not exceed"
            & " 2147483647");
      end if;
   end Validate_Pseudo_Inverse;

   function Pseudo_Inverse (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Pseudo_Inverse (Self);
      Status :=
        OpenCV.Internal.C_API.Mat_Pseudo_Inverse
          (Source => Self.Handle, Result => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat pseudoinverse operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat pseudoinverse operation returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Pseudo_Inverse;

   procedure Validate_Reciprocal_Condition_Number (Self : Mat) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Reciprocal_Condition_Number requires a non-empty Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Reciprocal_Condition_Number requires a single-channel Mat");
      end if;

      if not Is_SVD_Floating_Depth (Self.Depth) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Reciprocal_Condition_Number requires a Float32 or Float64 Mat");
      end if;
   end Validate_Reciprocal_Condition_Number;

   function Reciprocal_Condition_Number (Self : Mat) return Long_Float is
      C_Result : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status   : OpenCV.Internal.C_API.Status;
   begin
      Validate_Reciprocal_Condition_Number (Self);
      Status :=
        OpenCV.Internal.C_API.Mat_Reciprocal_Condition_Number
          (Source => Self.Handle, Result => C_Result'Access);
      Raise_On_Error (Status, "Mat reciprocal condition number operation");
      return Long_Float (C_Result);
   end Reciprocal_Condition_Number;

   procedure Validate_SVD_Solve_Zero (Self : Mat) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "SVD_Solve_Zero requires a non-empty Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD_Solve_Zero requires a single-channel Mat");
      end if;

      if not Is_SVD_Floating_Depth (Self.Depth) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "SVD_Solve_Zero requires a Float32 or Float64 Mat");
      end if;
   end Validate_SVD_Solve_Zero;

   function SVD_Solve_Zero (Self : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_SVD_Solve_Zero (Self);
      Status :=
        OpenCV.Internal.C_API.Mat_SVD_Solve_Zero
          (Source => Self.Handle, Result => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat SVD solve-zero operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat SVD solve-zero operation returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end SVD_Solve_Zero;

   function Is_PCA_Floating_Depth (Value : Depth_Type) return Boolean
   is (Value = Float32 or else Value = Float64);

   procedure Validate_PCA_Basis
     (Basis       : Principal_Component_Analysis_Result;
      Orientation : Sample_Orientation)
   is
      Feature_Count   : Natural;
      Component_Count : Natural;
   begin
      if Basis.Mean.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "PCA basis Mean must be a non-empty Mat");
      end if;

      if Basis.Mean.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "PCA basis Mean must be a single-channel Mat");
      end if;

      if not Is_PCA_Floating_Depth (Basis.Mean.Depth) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "PCA basis Mean must be a Float32 or Float64 Mat");
      end if;

      if Basis.Eigenvectors.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "PCA basis Eigenvectors must be a non-empty Mat");
      end if;

      if Basis.Eigenvectors.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "PCA basis Eigenvectors must be a single-channel Mat");
      end if;

      if Basis.Eigenvectors.Depth /= Basis.Mean.Depth then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "PCA basis Eigenvectors must have the same depth as Mean");
      end if;

      Component_Count := Basis.Eigenvectors.Rows;
      Feature_Count := Basis.Eigenvectors.Columns;

      if Component_Count = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "PCA basis Eigenvectors must have at least one row");
      end if;

      if Feature_Count = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "PCA basis Eigenvectors must have at least one column");
      end if;

      if Component_Count > Feature_Count then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "PCA basis component count must not exceed the feature count");
      end if;

      if Orientation = Samples_Are_Rows then
         if Basis.Mean.Rows /= 1 or else Basis.Mean.Columns /= Feature_Count
         then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "PCA row orientation requires Mean to be 1 x feature count");
         end if;
      else
         if Basis.Mean.Rows /= Feature_Count or else Basis.Mean.Columns /= 1
         then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "PCA column orientation requires Mean to be feature count x 1");
         end if;
      end if;
   end Validate_PCA_Basis;

   procedure Validate_PCA_Project_Or_Back_Project_Source
     (Self : Mat; Operation : String) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " requires a non-empty Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires a single-channel Mat");
      end if;

      if not Is_PCA_Floating_Depth (Self.Depth) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires a Float32 or Float64 Mat");
      end if;
   end Validate_PCA_Project_Or_Back_Project_Source;

   procedure Validate_PCA_Project
     (Self        : Mat;
      Basis       : Principal_Component_Analysis_Result;
      Orientation : Sample_Orientation)
   is
      Feature_Count : constant Natural := Basis.Eigenvectors.Columns;
   begin
      Validate_PCA_Project_Or_Back_Project_Source (Self, "PCA_Project");
      Validate_PCA_Basis (Basis, Orientation);

      if Orientation = Samples_Are_Rows then
         if Self.Columns /= Feature_Count then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "PCA_Project requires Self.Columns to equal the basis"
               & " feature count");
         end if;
      else
         if Self.Rows /= Feature_Count then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "PCA_Project requires Self.Rows to equal the basis"
               & " feature count");
         end if;
      end if;
   end Validate_PCA_Project;

   procedure Validate_PCA_Back_Project
     (Self        : Mat;
      Basis       : Principal_Component_Analysis_Result;
      Orientation : Sample_Orientation)
   is
      Component_Count : constant Natural := Basis.Eigenvectors.Rows;
   begin
      Validate_PCA_Project_Or_Back_Project_Source (Self, "PCA_Back_Project");
      Validate_PCA_Basis (Basis, Orientation);

      if Orientation = Samples_Are_Rows then
         if Self.Columns /= Component_Count then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "PCA_Back_Project requires Self.Columns to equal the"
               & " basis component count");
         end if;
      else
         if Self.Rows /= Component_Count then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "PCA_Back_Project requires Self.Rows to equal the"
               & " basis component count");
         end if;
      end if;
   end Validate_PCA_Back_Project;

   function Call_PCA_Projection
     (Self        : Mat;
      Basis       : Principal_Component_Analysis_Result;
      Orientation : Sample_Orientation;
      Project     : Boolean) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
      Operation  : constant String :=
        (if Project
         then "Mat PCA project operation"
         else "Mat PCA back-project operation");
   begin
      if Project then
         Status :=
           OpenCV.Internal.C_API.Mat_PCA_Project
             (Source       => Self.Handle,
              Mean         => Basis.Mean.Handle,
              Eigenvectors => Basis.Eigenvectors.Handle,
              Orientation  => To_C_Sample_Orientation (Orientation),
              Result       => New_Handle'Access);
      else
         Status :=
           OpenCV.Internal.C_API.Mat_PCA_Back_Project
             (Source       => Self.Handle,
              Mean         => Basis.Mean.Handle,
              Eigenvectors => Basis.Eigenvectors.Handle,
              Orientation  => To_C_Sample_Orientation (Orientation),
              Result       => New_Handle'Access);
      end if;

      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, Operation);
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Call_PCA_Projection;

   function PCA_Project
     (Self        : Mat;
      Basis       : Principal_Component_Analysis_Result;
      Orientation : Sample_Orientation := Samples_Are_Rows) return Mat is
   begin
      Validate_PCA_Project (Self, Basis, Orientation);
      return Call_PCA_Projection (Self, Basis, Orientation, Project => True);
   end PCA_Project;

   function PCA_Back_Project
     (Self        : Mat;
      Basis       : Principal_Component_Analysis_Result;
      Orientation : Sample_Orientation := Samples_Are_Rows) return Mat is
   begin
      Validate_PCA_Back_Project (Self, Basis, Orientation);
      return Call_PCA_Projection (Self, Basis, Orientation, Project => False);
   end PCA_Back_Project;

   function Supports_Transform_Source (Self : Mat) return Boolean
   is (Self.Depth = UInt8
       or else Self.Depth = Int8
       or else Self.Depth = UInt16
       or else Self.Depth = Int16
       or else Self.Depth = Int32
       or else Self.Depth = Float32
       or else Self.Depth = Float64);

   procedure Validate_Transform (Self, Coefficients : Mat) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Transform requires a non-empty Mat");
      end if;

      if Self.Depth = Float16 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Transform does not support Float16 Mats");
      end if;

      if not Supports_Transform_Source (Self) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transform requires a UInt8, Int8, UInt16, Int16, Int32,"
            & " Float32, or Float64 Mat");
      end if;

      if Self.Channels > 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transform requires a source with 1 to 4 channels");
      end if;

      if Coefficients.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transform requires a non-empty Coefficients Mat");
      end if;

      if Coefficients.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transform requires a single-channel Coefficients Mat");
      end if;

      if Coefficients.Depth /= Float32 and then Coefficients.Depth /= Float64
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transform requires Float32 or Float64 Coefficients");
      end if;

      if Coefficients.Rows = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transform requires Coefficients with at least one row");
      end if;

      if Coefficients.Rows > Natural (Channel_Count'Last) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transform Coefficients rows must not exceed 512");
      end if;

      if Coefficients.Columns /= Natural (Self.Channels)
        and then Coefficients.Columns /= Natural (Self.Channels) + 1
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Transform Coefficients must have Self.Channels or"
            & " Self.Channels + 1 columns");
      end if;
   end Validate_Transform;

   function Transform (Self : Mat; Coefficients : Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Transform (Self, Coefficients);

      Status :=
        OpenCV.Internal.C_API.Mat_Transform
          (Source       => Self.Handle,
           Coefficients => Coefficients.Handle,
           Result       => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat transform operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat transform operation returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Transform;

   function Supports_Perspective_Transform_Source (Self : Mat) return Boolean
   is (Self.Depth = Float32 or else Self.Depth = Float64);

   procedure Validate_Perspective_Transform (Self, Transform_Matrix : Mat) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Perspective_Transform requires a non-empty Mat");
      end if;

      if not Supports_Perspective_Transform_Source (Self) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Perspective_Transform requires a Float32 or Float64 Mat");
      end if;

      if Self.Channels /= 2 and then Self.Channels /= 3 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Perspective_Transform requires a source with 2 or 3 channels");
      end if;

      if Transform_Matrix.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Perspective_Transform requires a non-empty Transform_Matrix");
      end if;

      if Transform_Matrix.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Perspective_Transform requires a single-channel"
            & " Transform_Matrix");
      end if;

      if Transform_Matrix.Depth /= Float32
        and then Transform_Matrix.Depth /= Float64
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Perspective_Transform requires a Float32 or Float64"
            & " Transform_Matrix");
      end if;

      if Self.Channels = 2 then
         if Transform_Matrix.Rows /= 3 or else Transform_Matrix.Columns /= 3
         then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Perspective_Transform of a 2-channel source requires a"
               & " 3x3 Transform_Matrix");
         end if;
      elsif Transform_Matrix.Rows /= 4 or else Transform_Matrix.Columns /= 4
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Perspective_Transform of a 3-channel source requires a"
            & " 4x4 Transform_Matrix");
      end if;
   end Validate_Perspective_Transform;

   function Perspective_Transform
     (Self : Mat; Transform_Matrix : Mat) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Perspective_Transform (Self, Transform_Matrix);

      Status :=
        OpenCV.Internal.C_API.Mat_Perspective_Transform
          (Source           => Self.Handle,
           Transform_Matrix => Transform_Matrix.Handle,
           Result           => New_Handle'Access);
      if Status /= OpenCV.Internal.C_API.Success then
         OpenCV.Internal.C_API.Mat_Destroy (New_Handle);
         Raise_On_Error (Status, "Mat perspective transform operation");
      end if;

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat perspective transform operation returned a null result"
            & " handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Perspective_Transform;

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

   procedure Validate_Arg_Reduction_Input (Self : Mat) is
   begin
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Arg reduction requires a non-empty Mat");
      end if;

      if Self.Channels /= 1 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Arg reduction requires a single-channel Mat");
      end if;

      --  This explicit enumeration is the public supported-depth policy.
      case Self.Depth is
         when UInt8 | Int8 | UInt16 | Int16 | Int32 | Float32 | Float64 =>
            null;

         when Float16                                                   =>
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               "Arg reduction does not support Float16 Mats in OpenCV 4.10");
      end case;
   end Validate_Arg_Reduction_Input;

   function Arg_Reduction
     (Self       : Mat;
      Axis       : Reduction_Axis;
      Occurrence : Extremum_Occurrence;
      Is_Minimum : Boolean) return Mat
   is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Arg_Reduction_Input (Self);
      if Is_Minimum then
         Status :=
           OpenCV.Internal.C_API.Mat_Reduce_Arg_Min
             (Self.Handle,
              To_C_Reduction_Axis (Axis),
              To_C_Last_Index (Occurrence),
              New_Handle'Access);
      else
         Status :=
           OpenCV.Internal.C_API.Mat_Reduce_Arg_Max
             (Self.Handle,
              To_C_Reduction_Axis (Axis),
              To_C_Last_Index (Occurrence),
              New_Handle'Access);
      end if;
      Raise_On_Error (Status, "Mat arg reduction");

      if New_Handle = OpenCV.Internal.C_API.Null_Mat_Handle then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat arg reduction returned a null result handle");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Arg_Reduction;

   function Arg_Minimum
     (Self       : Mat;
      Axis       : Reduction_Axis;
      Occurrence : Extremum_Occurrence := First_Occurrence) return Mat
   is (Arg_Reduction (Self, Axis, Occurrence, True));

   function Arg_Maximum
     (Self       : Mat;
      Axis       : Reduction_Axis;
      Occurrence : Extremum_Occurrence := First_Occurrence) return Mat
   is (Arg_Reduction (Self, Axis, Occurrence, False));

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
      if Self.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Mean/stddev requires a non-empty Mat");
      end if;

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

   function Peak_Signal_To_Noise_Ratio
     (Left : Mat; Right : Mat; Peak_Value : Long_Float := 255.0)
      return Long_Float
   is
      C_Result : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status   : OpenCV.Internal.C_API.Status;
   begin
      if Left.Is_Empty or else Right.Is_Empty then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Peak signal-to-noise ratio requires non-empty Mats");
      end if;

      if Peak_Value <= 0.0
        or else Peak_Value /= Peak_Value
        or else Peak_Value > Long_Float (OpenCV.Internal.C_API.C_Double'Last)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Peak signal-to-noise ratio requires a positive finite"
            & " peak value");
      end if;

      Validate_Arithmetic_Compatibility (Left, Right);

      Status :=
        OpenCV.Internal.C_API.Mat_PSNR
          (Left       => Left.Handle,
           Right      => Right.Handle,
           Peak_Value => OpenCV.Internal.C_API.C_Double (Peak_Value),
           Result     => C_Result'Access);
      Raise_On_Error (Status, "Mat peak signal-to-noise ratio operation");
      return Long_Float (C_Result);
   end Peak_Signal_To_Noise_Ratio;

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

   function Check_Range_With_Mode
     (Self    : Mat;
      Minimum : Long_Float;
      Maximum : Long_Float;
      Bounded : Boolean) return Range_Check_Result
   is
      Valid  : aliased OpenCV.Internal.C_API.C_Boolean :=
        OpenCV.Internal.C_API.C_False;
      X      : aliased OpenCV.Internal.C_API.C_Int32 := -1;
      Y      : aliased OpenCV.Internal.C_API.C_Int32 := -1;
      Status : OpenCV.Internal.C_API.Status;
   begin
      if Self.Depth = Float16 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Check_Range does not support Float16 Mats");
      end if;

      Status :=
        OpenCV.Internal.C_API.Mat_Check_Range
          (Source     => Self.Handle,
           Use_Bounds =>
             (if Bounded
              then OpenCV.Internal.C_API.C_True
              else OpenCV.Internal.C_API.C_False),
           Minimum    => OpenCV.Internal.C_API.C_Double (Minimum),
           Maximum    => OpenCV.Internal.C_API.C_Double (Maximum),
           Valid      => Valid'Access,
           X          => X'Access,
           Y          => Y'Access);
      Raise_On_Error (Status, "Mat check range operation");

      if From_C_Boolean (Valid, "Check_Range") then
         return (Valid => True);
      end if;

      return
        (Valid         => False,
         First_Invalid =>
           (X => Point_Coordinate (X), Y => Point_Coordinate (Y)));
   end Check_Range_With_Mode;

   function Check_Range (Self : Mat) return Range_Check_Result is
   begin
      return Check_Range_With_Mode (Self, 0.0, 0.0, Bounded => False);
   end Check_Range;

   function Check_Range
     (Self : Mat; Minimum : Long_Float; Maximum : Long_Float)
      return Range_Check_Result is
   begin
      return Check_Range_With_Mode (Self, Minimum, Maximum, Bounded => True);
   end Check_Range;

   procedure Patch_NaNs (Self : in out Mat; Value : Float32_Value := 0.0) is
      Result : OpenCV.Internal.C_API.Status;
   begin
      if Self.Depth /= Float32 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Patch_NaNs requires a Float32 Mat");
      end if;

      Result :=
        OpenCV.Internal.C_API.Mat_Patch_NaNs
          (Self  => Self.Handle,
           Value => OpenCV.Internal.C_API.C_Double (Value));
      Raise_On_Error (Result, "Mat patch NaNs operation");
   end Patch_NaNs;

   procedure Complete_Symmetry
     (Self : in out Mat; Source : Symmetry_Source := Upper_Triangle)
   is
      Result : OpenCV.Internal.C_API.Status;
   begin
      if Self.Rows /= Self.Columns then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Complete_Symmetry requires a square Mat");
      end if;

      if Self.Depth /= Float32 and then Self.Depth /= Float64 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Complete_Symmetry requires a Float32 or Float64 Mat");
      end if;

      Result :=
        OpenCV.Internal.C_API.Mat_Complete_Symmetry
          (Self            => Self.Handle,
           Source_Triangle => (if Source = Upper_Triangle then 0 else 1));
      Raise_On_Error (Result, "Mat complete symmetry operation");
   end Complete_Symmetry;

   procedure Set_Identity
     (Self : in out Mat; Value : Scalar := (Component_0 => 1.0, others => 0.0))
   is
      C_Value : aliased OpenCV.Internal.C_API.Scalar := To_C_Scalar (Value);
      Result  : OpenCV.Internal.C_API.Status;
   begin
      if Self.Channels > 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Set_Identity supports Mats with at most four channels");
      end if;

      Result :=
        OpenCV.Internal.C_API.Mat_Set_Identity (Self.Handle, C_Value'Access);
      Raise_On_Error (Result, "Mat set identity operation");
   end Set_Identity;

end OpenCV.Core;
