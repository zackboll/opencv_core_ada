with Ada.Exceptions;
with Interfaces.C;

package body OpenCV.Core is

   use type OpenCV.Internal.C_API.C_Boolean;
   use type OpenCV.Internal.C_API.C_UInt64;
   use type OpenCV.Internal.C_API.Status;

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

end OpenCV.Core;
