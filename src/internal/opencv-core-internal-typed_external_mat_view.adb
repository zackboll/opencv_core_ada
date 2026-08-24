with Ada.Exceptions;
with OpenCV.Internal.C_API;
with OpenCV.Internal.Safe_Arithmetic;
with System;

package body OpenCV.Core.Internal.Typed_External_Mat_View is

   use type OpenCV.Internal.C_API.C_UInt64;
   use type OpenCV.Internal.C_API.Status;

   pragma
     Compile_Time_Error
       (Expected_Element_Bits rem System.Storage_Unit /= 0,
        "typed external-view element size must be an integral number of"
          & " storage bytes");
   pragma
     Compile_Time_Error
       (Element_Type'Size /= Expected_Element_Bits,
        "typed external-view element size does not match"
          & " Expected_Element_Bits");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= Expected_Element_Bits,
        "typed external-view array component size does not match"
          & " Expected_Element_Bits");
   pragma
     Compile_Time_Error
       (Element_Type'Alignment > Native_Element_Alignment,
        "typed external-view element requires stricter alignment than"
          & " native Mat storage guarantees");

   Element_Bytes : constant OpenCV.Internal.C_API.C_UInt64 :=
     OpenCV.Internal.C_API.C_UInt64
       (Expected_Element_Bits / System.Storage_Unit);

   procedure Raise_Invalid_View (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_View;

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

   function Expected_Byte_Count
     (Element_Count : Natural) return OpenCV.Internal.C_API.C_UInt64
   is
      Elements : constant OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64 (Element_Count);
   begin
      if Element_Count /= 0
        and then Elements > OpenCV.Internal.C_API.C_UInt64'Last / Element_Bytes
      then
         Raise_Invalid_View
           (Type_Name
            & " external Mat view byte count exceeds the"
            & " representable range");
      end if;

      return Elements * Element_Bytes;
   end Expected_Byte_Count;

   function Expected_Element_Count (Rows, Columns : Positive) return Natural is
   begin
      if not OpenCV.Internal.Safe_Arithmetic.Fits_Signed_Int32
               (Long_Long_Integer (Rows))
      then
         Raise_Invalid_View
           (Type_Name
            & " external Mat view row count exceeds the native"
            & " dimension range");
      end if;

      if not OpenCV.Internal.Safe_Arithmetic.Fits_Signed_Int32
               (Long_Long_Integer (Columns))
      then
         Raise_Invalid_View
           (Type_Name
            & " external Mat view column count exceeds the native"
            & " dimension range");
      end if;

      if Rows > 0 and then Columns > Natural'Last / Rows then
         Raise_Invalid_View
           (Type_Name
            & " external Mat view element count exceeds the representable"
            & " range");
      end if;

      return Rows * Columns;
   end Expected_Element_Count;

   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat))
   is
      Element_Count : constant Natural :=
        Expected_Element_Count (Rows, Columns);
      Byte_Count    : OpenCV.Internal.C_API.C_UInt64;
      Image         : Mat;
      New_Handle    : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status        : OpenCV.Internal.C_API.Status;
   begin
      if Data'Length /= Element_Count then
         Raise_Invalid_View
           (Type_Name
            & " external Mat view requires Data'Length = Rows * Columns");
      end if;

      Byte_Count := Expected_Byte_Count (Element_Count);

      Status :=
        OpenCV.Internal.C_API.Mat_Create_External_2D
          (Rows       => OpenCV.Internal.C_API.C_Int32 (Rows),
           Columns    => OpenCV.Internal.C_API.C_Int32 (Columns),
           Depth      => To_C_Depth (Required_Depth),
           Channels   => OpenCV.Internal.C_API.C_Int32 (Required_Channels),
           Data       => Data (Data'First)'Address,
           Byte_Count => Byte_Count,
           Result     => New_Handle'Access);
      Raise_On_Error (Status, Type_Name & " external Mat view construction");

      OpenCV.Internal.C_API.Mat_Destroy (Image.Handle);
      Image.Handle := New_Handle;
      Process (Image);
   end With_Writable_Mat_View;

   procedure With_Writable_Strided_Mat_View
     (Data                : aliased in out Buffer_Array;
      Rows                : Positive;
      Columns             : Positive;
      Row_Stride_Elements : Positive;
      Process             : not null access procedure (Image : in out Mat))
   is
      Required_Element_Capacity : Natural;
      Byte_Count                : OpenCV.Internal.C_API.C_UInt64;
      Row_Stride_Bytes          : OpenCV.Internal.C_API.C_UInt64;
      Image                     : Mat;
      New_Handle                : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status                    : OpenCV.Internal.C_API.Status;
   begin
      --  Also validates that Rows and Columns fit the native signed range.
      declare
         Unused_Element_Count : constant Natural :=
           Expected_Element_Count (Rows, Columns);
         pragma Unreferenced (Unused_Element_Count);
      begin
         null;
      end;

      if Row_Stride_Elements < Columns then
         Raise_Invalid_View
           (Type_Name
            & " strided external Mat view row stride must be at least"
            & " Columns");
      end if;

      if Row_Stride_Elements > Natural'Last / Rows then
         Raise_Invalid_View
           (Type_Name
            & " strided external Mat view required element capacity exceeds"
            & " the"
            & " representable range");
      end if;
      Required_Element_Capacity := Rows * Row_Stride_Elements;

      if Data'Length < Required_Element_Capacity then
         Raise_Invalid_View
           (Type_Name
            & " strided external Mat view requires Data storage for complete"
            & " row strides");
      end if;

      Row_Stride_Bytes := Expected_Byte_Count (Row_Stride_Elements);
      Byte_Count := Expected_Byte_Count (Data'Length);

      Status :=
        OpenCV.Internal.C_API.Mat_Create_External_2D_Strided
          (Rows             => OpenCV.Internal.C_API.C_Int32 (Rows),
           Columns          => OpenCV.Internal.C_API.C_Int32 (Columns),
           Depth            => To_C_Depth (Required_Depth),
           Channels         =>
             OpenCV.Internal.C_API.C_Int32 (Required_Channels),
           Data             => Data (Data'First)'Address,
           Byte_Count       => Byte_Count,
           Row_Stride_Bytes => Row_Stride_Bytes,
           Result           => New_Handle'Access);
      Raise_On_Error
        (Status, Type_Name & " strided external Mat view construction");

      OpenCV.Internal.C_API.Mat_Destroy (Image.Handle);
      Image.Handle := New_Handle;
      Process (Image);
   end With_Writable_Strided_Mat_View;

end OpenCV.Core.Internal.Typed_External_Mat_View;
