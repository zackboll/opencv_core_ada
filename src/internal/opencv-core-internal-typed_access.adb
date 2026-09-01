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
   function Get_Float64
     (Image : Mat; Row, Column : Integer) return Float64_Value
   is
      Result : aliased OpenCV.Internal.C_API.C_Float64 := 0.0;
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Get_Float64
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Result => Result'Access);
   begin
      Raise_On_Error (Status, "Float64 typed Mat read");
      return Float64_Value (Result);
   end Get_Float64;

   procedure Set_Float64
     (Image : in out Mat; Row, Column : Integer; Value : Float64_Value)
   is
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Set_Float64
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Value  => OpenCV.Internal.C_API.C_Float64 (Value));
   begin
      Raise_On_Error (Status, "Float64 typed Mat write");
   end Set_Float64;

   procedure Fill_C_Indices
     (Indices : Index_Array;
      Result  : in out OpenCV.Internal.C_API.C_Int32_Array)
   is
      Position : Natural := Result'First;
   begin
      for Index_Value of Indices loop
         Result (Position) := OpenCV.Internal.C_API.C_Int32 (Index_Value);
         Position := Position + 1;
      end loop;
   end Fill_C_Indices;

   function Get_UInt8 (Image : Mat; Indices : Index_Array) return UInt8_Value
   is
      Result : aliased OpenCV.Internal.C_API.C_UInt8 := 0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      if Indices'Length = 0 then
         Status :=
           OpenCV.Internal.C_API.Mat_Get_UInt8_ND
             (Self            => Image.Handle,
              Dimension_Count => 0,
              Indices         => null,
              Result          => Result'Access);
      else
         declare
            C_Indices :
              OpenCV.Internal.C_API.C_Int32_Array (0 .. Indices'Length - 1);
         begin
            Fill_C_Indices (Indices, C_Indices);
            Status :=
              OpenCV.Internal.C_API.Mat_Get_UInt8_ND
                (Self            => Image.Handle,
                 Dimension_Count =>
                   OpenCV.Internal.C_API.C_Int32 (Indices'Length),
                 Indices         => C_Indices (C_Indices'First)'Access,
                 Result          => Result'Access);
         end;
      end if;

      Raise_On_Error (Status, "UInt8 typed Mat N-dimensional read");
      return UInt8_Value (Result);
   end Get_UInt8;

   procedure Set_UInt8
     (Image : in out Mat; Indices : Index_Array; Value : UInt8_Value)
   is
      Status : OpenCV.Internal.C_API.Status;
   begin
      if Indices'Length = 0 then
         Status :=
           OpenCV.Internal.C_API.Mat_Set_UInt8_ND
             (Self            => Image.Handle,
              Dimension_Count => 0,
              Indices         => null,
              Value           => OpenCV.Internal.C_API.C_UInt8 (Value));
      else
         declare
            C_Indices :
              OpenCV.Internal.C_API.C_Int32_Array (0 .. Indices'Length - 1);
         begin
            Fill_C_Indices (Indices, C_Indices);
            Status :=
              OpenCV.Internal.C_API.Mat_Set_UInt8_ND
                (Self            => Image.Handle,
                 Dimension_Count =>
                   OpenCV.Internal.C_API.C_Int32 (Indices'Length),
                 Indices         => C_Indices (C_Indices'First)'Access,
                 Value           => OpenCV.Internal.C_API.C_UInt8 (Value));
         end;
      end if;

      Raise_On_Error (Status, "UInt8 typed Mat N-dimensional write");
   end Set_UInt8;

   function Get_Float32
     (Image : Mat; Indices : Index_Array) return Float32_Value
   is
      Result : aliased OpenCV.Internal.C_API.C_Float32 := 0.0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      if Indices'Length = 0 then
         Status :=
           OpenCV.Internal.C_API.Mat_Get_Float32_ND
             (Self            => Image.Handle,
              Dimension_Count => 0,
              Indices         => null,
              Result          => Result'Access);
      else
         declare
            C_Indices :
              OpenCV.Internal.C_API.C_Int32_Array (0 .. Indices'Length - 1);
         begin
            Fill_C_Indices (Indices, C_Indices);
            Status :=
              OpenCV.Internal.C_API.Mat_Get_Float32_ND
                (Self            => Image.Handle,
                 Dimension_Count =>
                   OpenCV.Internal.C_API.C_Int32 (Indices'Length),
                 Indices         => C_Indices (C_Indices'First)'Access,
                 Result          => Result'Access);
         end;
      end if;

      Raise_On_Error (Status, "Float32 typed Mat N-dimensional read");
      return Float32_Value (Result);
   end Get_Float32;

   procedure Set_Float32
     (Image : in out Mat; Indices : Index_Array; Value : Float32_Value)
   is
      Status : OpenCV.Internal.C_API.Status;
   begin
      if Indices'Length = 0 then
         Status :=
           OpenCV.Internal.C_API.Mat_Set_Float32_ND
             (Self            => Image.Handle,
              Dimension_Count => 0,
              Indices         => null,
              Value           => OpenCV.Internal.C_API.C_Float32 (Value));
      else
         declare
            C_Indices :
              OpenCV.Internal.C_API.C_Int32_Array (0 .. Indices'Length - 1);
         begin
            Fill_C_Indices (Indices, C_Indices);
            Status :=
              OpenCV.Internal.C_API.Mat_Set_Float32_ND
                (Self            => Image.Handle,
                 Dimension_Count =>
                   OpenCV.Internal.C_API.C_Int32 (Indices'Length),
                 Indices         => C_Indices (C_Indices'First)'Access,
                 Value           => OpenCV.Internal.C_API.C_Float32 (Value));
         end;
      end if;

      Raise_On_Error (Status, "Float32 typed Mat N-dimensional write");
   end Set_Float32;

   function Get_Float64
     (Image : Mat; Indices : Index_Array) return Float64_Value
   is
      Result : aliased OpenCV.Internal.C_API.C_Float64 := 0.0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      if Indices'Length = 0 then
         Status :=
           OpenCV.Internal.C_API.Mat_Get_Float64_ND
             (Self            => Image.Handle,
              Dimension_Count => 0,
              Indices         => null,
              Result          => Result'Access);
      else
         declare
            C_Indices :
              OpenCV.Internal.C_API.C_Int32_Array (0 .. Indices'Length - 1);
         begin
            Fill_C_Indices (Indices, C_Indices);
            Status :=
              OpenCV.Internal.C_API.Mat_Get_Float64_ND
                (Self            => Image.Handle,
                 Dimension_Count =>
                   OpenCV.Internal.C_API.C_Int32 (Indices'Length),
                 Indices         => C_Indices (C_Indices'First)'Access,
                 Result          => Result'Access);
         end;
      end if;

      Raise_On_Error (Status, "Float64 typed Mat N-dimensional read");
      return Float64_Value (Result);
   end Get_Float64;

   procedure Set_Float64
     (Image : in out Mat; Indices : Index_Array; Value : Float64_Value)
   is
      Status : OpenCV.Internal.C_API.Status;
   begin
      if Indices'Length = 0 then
         Status :=
           OpenCV.Internal.C_API.Mat_Set_Float64_ND
             (Self            => Image.Handle,
              Dimension_Count => 0,
              Indices         => null,
              Value           => OpenCV.Internal.C_API.C_Float64 (Value));
      else
         declare
            C_Indices :
              OpenCV.Internal.C_API.C_Int32_Array (0 .. Indices'Length - 1);
         begin
            Fill_C_Indices (Indices, C_Indices);
            Status :=
              OpenCV.Internal.C_API.Mat_Set_Float64_ND
                (Self            => Image.Handle,
                 Dimension_Count =>
                   OpenCV.Internal.C_API.C_Int32 (Indices'Length),
                 Indices         => C_Indices (C_Indices'First)'Access,
                 Value           => OpenCV.Internal.C_API.C_Float64 (Value));
         end;
      end if;

      Raise_On_Error (Status, "Float64 typed Mat N-dimensional write");
   end Set_Float64;

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

   procedure Read_UInt8_Vec3_Row
     (Image : Mat; Row : Integer; Data : out UInt8_Row_Buffer)
   is
      pragma
        Warnings
          (GNAT,
           Off,
           Data,
           Reason =>
             "Data is written by the imported C Vec3 row-read operation"
             & " through its address.");
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Read_UInt8_Vec3_Row
          (Self          => Image.Handle,
           Row           => OpenCV.Internal.C_API.C_Int32 (Row),
           Data          => Address_Of (Data),
           Element_Count => OpenCV.Internal.C_API.C_UInt64 (Data'Length / 3));
   begin
      Raise_On_Error (Status, "UInt8 Vec3 typed Mat row read");
   end Read_UInt8_Vec3_Row;

   procedure Write_UInt8_Vec3_Row
     (Image : in out Mat; Row : Integer; Data : UInt8_Row_Buffer)
   is
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Write_UInt8_Vec3_Row
          (Self          => Image.Handle,
           Row           => OpenCV.Internal.C_API.C_Int32 (Row),
           Data          => Address_Of (Data),
           Element_Count => OpenCV.Internal.C_API.C_UInt64 (Data'Length / 3));
   begin
      Raise_On_Error (Status, "UInt8 Vec3 typed Mat row write");
   end Write_UInt8_Vec3_Row;

   procedure Read_Float32_Vec3_Row
     (Image : Mat; Row : Integer; Data : out Float32_Row_Buffer)
   is
      pragma
        Warnings
          (GNAT,
           Off,
           Data,
           Reason =>
             "Data is written by the imported C Vec3 row-read operation"
             & " through its address.");
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Read_Float32_Vec3_Row
          (Self          => Image.Handle,
           Row           => OpenCV.Internal.C_API.C_Int32 (Row),
           Data          => Address_Of (Data),
           Element_Count => OpenCV.Internal.C_API.C_UInt64 (Data'Length / 3));
   begin
      Raise_On_Error (Status, "Float32 Vec3 typed Mat row read");
   end Read_Float32_Vec3_Row;

   procedure Write_Float32_Vec3_Row
     (Image : in out Mat; Row : Integer; Data : Float32_Row_Buffer)
   is
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Write_Float32_Vec3_Row
          (Self          => Image.Handle,
           Row           => OpenCV.Internal.C_API.C_Int32 (Row),
           Data          => Address_Of (Data),
           Element_Count => OpenCV.Internal.C_API.C_UInt64 (Data'Length / 3));
   begin
      Raise_On_Error (Status, "Float32 Vec3 typed Mat row write");
   end Write_Float32_Vec3_Row;

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
