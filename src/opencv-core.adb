with Ada.Exceptions;
with Interfaces.C;

package body OpenCV.Core is

   use type OpenCV.Internal.C_API.C_Boolean;
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

   function Is_Empty (Self : Mat) return Boolean is
      Empty  : aliased OpenCV.Internal.C_API.C_Boolean :=
        OpenCV.Internal.C_API.C_False;
      Result : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Is_Empty (Self.Handle, Empty'Access);
   begin
      Raise_On_Error (Result, "Mat empty query");

      if Empty = OpenCV.Internal.C_API.C_True then
         return True;
      elsif Empty = OpenCV.Internal.C_API.C_False then
         return False;
      else
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Mat empty query returned an invalid Boolean value");
      end if;
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
