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

   Maximum_OpenCV_Dimensions : constant := 32;

   --  Validates the public packed N-D shape contract and returns
   --  product (Shape) as a complete-element count. Every intermediate
   --  product is checked against Natural'Last before it is formed, so the
   --  result is exact and never wraps. Size_Coordinate already confines each
   --  extent to OpenCV's signed int dimension domain.
   function Packed_Element_Count (Shape : Dimension_Array) return Natural is
      Count : Natural := 1;
   begin
      if Shape'Length < 2 then
         Raise_Invalid_View
           (Type_Name
            & " external N-D Mat view requires at least two dimensions");
      end if;

      if Shape'Length > Maximum_OpenCV_Dimensions then
         Raise_Invalid_View
           (Type_Name
            & " external N-D Mat view exceeds OpenCV's 32-dimension limit");
      end if;

      for Extent_Value of Shape loop
         if Extent_Value = 0 then
            Raise_Invalid_View
              (Type_Name & " external N-D Mat view extents must be positive");
         end if;
      end loop;

      for Extent_Value of Shape loop
         if Natural (Extent_Value) > Natural'Last / Count then
            Raise_Invalid_View
              (Type_Name
               & " external N-D Mat view element count exceeds the"
               & " representable range");
         end if;
         Count := Count * Natural (Extent_Value);
      end loop;

      return Count;
   end Packed_Element_Count;

   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat))
   is
      Element_Count : constant Natural := Packed_Element_Count (Shape);
      Byte_Count    : OpenCV.Internal.C_API.C_UInt64;
      Sizes         :
        OpenCV.Internal.C_API.C_Int32_Array (0 .. Shape'Length - 1);
      Position      : Natural := 0;
      Image         : Mat;
      New_Handle    : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status        : OpenCV.Internal.C_API.Status;
   begin
      if Data'Length /= Element_Count then
         Raise_Invalid_View
           (Type_Name
            & " external N-D Mat view requires Data'Length ="
            & " product (Shape)");
      end if;

      for Extent_Value of Shape loop
         Sizes (Position) := OpenCV.Internal.C_API.C_Int32 (Extent_Value);
         Position := Position + 1;
      end loop;

      Byte_Count := Expected_Byte_Count (Element_Count);

      Status :=
        OpenCV.Internal.C_API.Mat_Create_External_ND
          (Dimension_Count => OpenCV.Internal.C_API.C_Int32 (Shape'Length),
           Sizes           => Sizes (Sizes'First)'Access,
           Depth           => To_C_Depth (Required_Depth),
           Channels        =>
             OpenCV.Internal.C_API.C_Int32 (Required_Channels),
           Data            => Data (Data'First)'Address,
           Byte_Count      => Byte_Count,
           Result          => New_Handle'Access);
      Raise_On_Error
        (Status, Type_Name & " external N-D Mat view construction");

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

      --  OpenCV's external-data constructor sets
      --  datalimit = datastart + step * rows, so the final row's trailing
      --  stride padding is part of the header extent even though it is not
      --  a logical Mat element.
      if Row_Stride_Elements > Natural'Last / Rows then
         Raise_Invalid_View
           (Type_Name
            & " strided external Mat view complete row strides exceed"
            & " the representable range");
      end if;
      Required_Element_Capacity := Rows * Row_Stride_Elements;

      if Data'Length < Required_Element_Capacity then
         Raise_Invalid_View
           (Type_Name
            & " strided external Mat view backing storage is too short");
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

   --  Validates the public strided N-D contract and returns the complete
   --  outer-stride element capacity Shape (first) * Strides (first). Every
   --  product and sum is checked against Natural'Last before it is formed.
   --  Shape and Strides are walked by logical position so neither array's
   --  index bounds affect the geometry.
   function Strided_Required_Capacity
     (Shape : Dimension_Array; Strides : Dimension_Stride_Array) return Natural
   is
      Logical_End : Natural := 1;
      Required    : Natural;
      Term        : Natural;
   begin
      --  Also validates the dimension count and every extent.
      declare
         Unused_Packed : constant Natural := Packed_Element_Count (Shape);
         pragma Unreferenced (Unused_Packed);
      begin
         null;
      end;

      if Strides'Length /= Shape'Length then
         Raise_Invalid_View
           (Type_Name
            & " strided external N-D Mat view requires one stride per"
            & " dimension");
      end if;

      if Strides (Strides'Last) /= 1 then
         Raise_Invalid_View
           (Type_Name
            & " strided external N-D Mat view final stride must be 1");
      end if;

      for Offset in 0 .. Shape'Length - 2 loop
         declare
            Inner_Extent : constant Natural :=
              Natural (Shape (Shape'First + Offset + 1));
            Inner_Stride : constant Positive :=
              Strides (Strides'First + Offset + 1);
            Outer_Stride : constant Positive :=
              Strides (Strides'First + Offset);
         begin
            if Inner_Stride > Natural'Last / Inner_Extent then
               Raise_Invalid_View
                 (Type_Name
                  & " strided external N-D Mat view nested stride exceeds"
                  & " the representable range");
            end if;

            if Outer_Stride < Inner_Stride * Inner_Extent then
               Raise_Invalid_View
                 (Type_Name
                  & " strided external N-D Mat view stride is smaller than"
                  & " its nested inner block");
            end if;
         end;
      end loop;

      --  OpenCV's external-data constructor sets
      --  datalimit = datastart + size[0] * step[0], so padding after the
      --  final logical outer block is part of the native header extent.
      declare
         Outer_Extent : constant Natural := Natural (Shape (Shape'First));
         Outer_Stride : constant Positive := Strides (Strides'First);
      begin
         if Outer_Stride > Natural'Last / Outer_Extent then
            Raise_Invalid_View
              (Type_Name
               & " strided external N-D Mat view complete outer stride"
               & " exceeds the representable range");
         end if;
         Required := Outer_Extent * Outer_Stride;
      end;

      for Offset in 0 .. Shape'Length - 1 loop
         declare
            Span   : constant Natural :=
              Natural (Shape (Shape'First + Offset)) - 1;
            Stride : constant Positive := Strides (Strides'First + Offset);
         begin
            if Span /= 0 and then Stride > Natural'Last / Span then
               Raise_Invalid_View
                 (Type_Name
                  & " strided external N-D Mat view logical extent exceeds"
                  & " the representable range");
            end if;
            Term := Span * Stride;
            if Term > Natural'Last - Logical_End then
               Raise_Invalid_View
                 (Type_Name
                  & " strided external N-D Mat view logical extent exceeds"
                  & " the representable range");
            end if;
            Logical_End := Logical_End + Term;
         end;
      end loop;

      --  Implied by the nesting checks above; kept as an explicit guard
      --  because the native header must cover every logical element.
      if Logical_End > Required then
         Raise_Invalid_View
           (Type_Name
            & " strided external N-D Mat view logical extent exceeds its"
            & " outer stride");
      end if;

      return Required;
   end Strided_Required_Capacity;

   procedure With_Writable_Strided_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : in out Mat))
   is
      Required_Capacity : constant Natural :=
        Strided_Required_Capacity (Shape, Strides);
      Byte_Count        : OpenCV.Internal.C_API.C_UInt64;
      Sizes             :
        OpenCV.Internal.C_API.C_Int32_Array (0 .. Shape'Length - 1);
      Steps             :
        OpenCV.Internal.C_API.C_UInt64_Array (0 .. Shape'Length - 1);
      Image             : Mat;
      New_Handle        : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status            : OpenCV.Internal.C_API.Status;
   begin
      if Data'Length < Required_Capacity then
         Raise_Invalid_View
           (Type_Name
            & " strided external N-D Mat view backing storage is too short");
      end if;

      for Offset in Sizes'Range loop
         Sizes (Offset) :=
           OpenCV.Internal.C_API.C_Int32 (Shape (Shape'First + Offset));
         Steps (Offset) :=
           OpenCV.Internal.C_API.C_UInt64 (Strides (Strides'First + Offset));
      end loop;

      Byte_Count := Expected_Byte_Count (Data'Length);

      Status :=
        OpenCV.Internal.C_API.Mat_Create_External_ND_Strided
          (Dimension_Count => OpenCV.Internal.C_API.C_Int32 (Shape'Length),
           Sizes           => Sizes (Sizes'First)'Access,
           Element_Strides => Steps (Steps'First)'Access,
           Depth           => To_C_Depth (Required_Depth),
           Channels        =>
             OpenCV.Internal.C_API.C_Int32 (Required_Channels),
           Data            => Data (Data'First)'Address,
           Byte_Count      => Byte_Count,
           Result          => New_Handle'Access);
      Raise_On_Error
        (Status, Type_Name & " strided external N-D Mat view construction");

      OpenCV.Internal.C_API.Mat_Destroy (Image.Handle);
      Image.Handle := New_Handle;
      Process (Image);
   end With_Writable_Strided_Mat_View;

end OpenCV.Core.Internal.Typed_External_Mat_View;
