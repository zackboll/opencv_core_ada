with Ada.Exceptions;
with System;

package body OpenCV.Core.Internal.Typed_Access is

   use type OpenCV.Internal.C_API.Status;

   procedure Raise_On_Error
     (Status : OpenCV.Internal.C_API.Status; Operation : String)
   is
      Diagnostic : constant String := OpenCV.Internal.C_API.Last_Error_Message;
   begin
      if Status = OpenCV.Internal.C_API.Success then
         return;
      end if;

      if Diagnostic'Length = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " failed");
      else
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " failed: " & Diagnostic);
      end if;
   end Raise_On_Error;

   function Get_UInt8 (Image : Mat; Row, Column : Integer) return UInt8_Value
   is
      Result : aliased OpenCV.Internal.C_API.C_UInt8 := 0;
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Get_UInt8
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Result => Result'Access);
   begin
      Raise_On_Error (Status, "UInt8 typed Mat read");
      return UInt8_Value (Result);
   end Get_UInt8;

   procedure Set_UInt8
     (Image : in out Mat; Row, Column : Integer; Value : UInt8_Value)
   is
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Set_UInt8
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Value  => OpenCV.Internal.C_API.C_UInt8 (Value));
   begin
      Raise_On_Error (Status, "UInt8 typed Mat write");
   end Set_UInt8;

   function Get_Float32
     (Image : Mat; Row, Column : Integer) return Float32_Value
   is
      Result : aliased OpenCV.Internal.C_API.C_Float32 := 0.0;
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Get_Float32
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Result => Result'Access);
   begin
      Raise_On_Error (Status, "Float32 typed Mat read");
      return Float32_Value (Result);
   end Get_Float32;

   procedure Set_Float32
     (Image : in out Mat; Row, Column : Integer; Value : Float32_Value)
   is
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Set_Float32
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Value  => OpenCV.Internal.C_API.C_Float32 (Value));
   begin
      Raise_On_Error (Status, "Float32 typed Mat write");
   end Set_Float32;

   function Address_Of (Data : UInt8_Row_Buffer) return System.Address is
   begin
      if Data'Length = 0 then
         return System.Null_Address;
      end if;

      return Data (Data'First)'Address;
   end Address_Of;

   function Address_Of (Data : Float32_Row_Buffer) return System.Address is
   begin
      if Data'Length = 0 then
         return System.Null_Address;
      end if;

      return Data (Data'First)'Address;
   end Address_Of;

   procedure Read_UInt8_Row
     (Image : Mat; Row : Integer; Data : out UInt8_Row_Buffer)
   is
      pragma
        Warnings
          (GNAT,
           Off,
           Data,
           Reason =>
             "Data is written by the imported C row-read operation"
             & " through its address.");
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Read_UInt8_Row
          (Self          => Image.Handle,
           Row           => OpenCV.Internal.C_API.C_Int32 (Row),
           Data          => Address_Of (Data),
           Element_Count => OpenCV.Internal.C_API.C_UInt64 (Data'Length));
   begin
      Raise_On_Error (Status, "UInt8 typed Mat row read");
   end Read_UInt8_Row;

   procedure Write_UInt8_Row
     (Image : in out Mat; Row : Integer; Data : UInt8_Row_Buffer)
   is
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Write_UInt8_Row
          (Self          => Image.Handle,
           Row           => OpenCV.Internal.C_API.C_Int32 (Row),
           Data          => Address_Of (Data),
           Element_Count => OpenCV.Internal.C_API.C_UInt64 (Data'Length));
   begin
      Raise_On_Error (Status, "UInt8 typed Mat row write");
   end Write_UInt8_Row;

   procedure Read_Float32_Row
     (Image : Mat; Row : Integer; Data : out Float32_Row_Buffer)
   is
      pragma
        Warnings
          (GNAT,
           Off,
           Data,
           Reason =>
             "Data is written by the imported C row-read operation"
             & " through its address.");
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Read_Float32_Row
          (Self          => Image.Handle,
           Row           => OpenCV.Internal.C_API.C_Int32 (Row),
           Data          => Address_Of (Data),
           Element_Count => OpenCV.Internal.C_API.C_UInt64 (Data'Length));
   begin
      Raise_On_Error (Status, "Float32 typed Mat row read");
   end Read_Float32_Row;

   procedure Write_Float32_Row
     (Image : in out Mat; Row : Integer; Data : Float32_Row_Buffer)
   is
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Write_Float32_Row
          (Self          => Image.Handle,
           Row           => OpenCV.Internal.C_API.C_Int32 (Row),
           Data          => Address_Of (Data),
           Element_Count => OpenCV.Internal.C_API.C_UInt64 (Data'Length));
   begin
      Raise_On_Error (Status, "Float32 typed Mat row write");
   end Write_Float32_Row;

   function Get_UInt8_Vec3
     (Image : Mat; Row, Column : Integer) return OpenCV.Core.UInt8_Vec3.Vector
   is
      Result : aliased OpenCV.Internal.C_API.UInt8_Vec3 := (others => 0);
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Get_UInt8_Vec3
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Result => Result'Access);
   begin
      Raise_On_Error (Status, "UInt8 Vec3 typed Mat read");
      return
        (0 => UInt8_Value (Result.Component_0),
         1 => UInt8_Value (Result.Component_1),
         2 => UInt8_Value (Result.Component_2));
   end Get_UInt8_Vec3;

   procedure Set_UInt8_Vec3
     (Image  : in out Mat;
      Row    : Integer;
      Column : Integer;
      Value  : OpenCV.Core.UInt8_Vec3.Vector)
   is
      C_Value : aliased constant OpenCV.Internal.C_API.UInt8_Vec3 :=
        (Component_0 => OpenCV.Internal.C_API.C_UInt8 (Value (0)),
         Component_1 => OpenCV.Internal.C_API.C_UInt8 (Value (1)),
         Component_2 => OpenCV.Internal.C_API.C_UInt8 (Value (2)));
      Status  : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Set_UInt8_Vec3
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Value  => C_Value'Access);
   begin
      Raise_On_Error (Status, "UInt8 Vec3 typed Mat write");
   end Set_UInt8_Vec3;

   function Get_Float32_Vec3
     (Image : Mat; Row, Column : Integer)
      return OpenCV.Core.Float32_Vec3.Vector
   is
      Result : aliased OpenCV.Internal.C_API.Float32_Vec3 := (others => 0.0);
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Get_Float32_Vec3
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Result => Result'Access);
   begin
      Raise_On_Error (Status, "Float32 Vec3 typed Mat read");
      return
        (0 => Float32_Value (Result.Component_0),
         1 => Float32_Value (Result.Component_1),
         2 => Float32_Value (Result.Component_2));
   end Get_Float32_Vec3;

   procedure Set_Float32_Vec3
     (Image  : in out Mat;
      Row    : Integer;
      Column : Integer;
      Value  : OpenCV.Core.Float32_Vec3.Vector)
   is
      C_Value : aliased constant OpenCV.Internal.C_API.Float32_Vec3 :=
        (Component_0 => OpenCV.Internal.C_API.C_Float32 (Value (0)),
         Component_1 => OpenCV.Internal.C_API.C_Float32 (Value (1)),
         Component_2 => OpenCV.Internal.C_API.C_Float32 (Value (2)));
      Status  : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Set_Float32_Vec3
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Value  => C_Value'Access);
   begin
      Raise_On_Error (Status, "Float32 Vec3 typed Mat write");
   end Set_Float32_Vec3;

end OpenCV.Core.Internal.Typed_Access;
