with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.Int8_Vec4_Mat_View is
   pragma
     Compile_Time_Error
       (Int8_Value'Size /= 8,
        "Int8_Value must be exactly 8 bits to alias CV_8S storage");
   pragma
     Compile_Time_Error
       (Int8_Value'Object_Size /= 8, "Int8_Value must have no hidden padding");
   pragma
     Compile_Time_Error
       (Int8_Vec4.Vector'Component_Size /= 8,
        "Int8 Vec4 components must be tightly packed 8-bit channels");
   pragma
     Compile_Time_Error
       (Int8_Vec4.Vector'Size /= 32,
        "Int8 Vec4 Vector must be exactly 32 bits for zero-copy views");
   pragma
     Compile_Time_Error
       (Int8_Vec4.Vector'Object_Size /= 32,
        "Int8 Vec4 Vector must have no hidden padding");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 32,
        "Int8 Vec4 Buffer_Array must be tightly packed 32-bit elements");
   pragma
     Compile_Time_Error
       (Int8_Vec4.Vector'Alignment > 1,
        "Int8 Vec4 Vector alignment is stricter than CV_8SC4 guarantees");
   pragma
     Compile_Time_Error
       (Int8_Vec4.Component_Index'First /= 0
          or else Int8_Vec4.Component_Index'Last /= 3,
        "Int8 Vec4 components must be indexed 0 .. 3");

   package Viewing is new
     Internal.Typed_External_Mat_View
       (Element_Type             => Int8_Vec4.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Int8,
        Required_Channels        => 4,
        Expected_Element_Bits    => 32,
        Native_Element_Alignment => 1,
        Type_Name                => "Int8 Vec4");

   procedure With_Writable_Mat_View
     (Data          : aliased in out Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Rows, Columns, Process);
   end With_Writable_Mat_View;
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Shape, Process);
   end With_Writable_Mat_View;
   procedure With_Writable_Strided_Mat_View
     (Data                      : aliased in out Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   :
        not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Strided_Mat_View
        (Data, Rows, Columns, Row_Stride, Process);
   end With_Writable_Strided_Mat_View;
   procedure With_Writable_Strided_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Strided_Mat_View (Data, Shape, Strides, Process);
   end With_Writable_Strided_Mat_View;
   procedure With_Read_Only_Mat_View
     (Data          : aliased Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : Mat)) is
   begin
      Viewing.With_Read_Only_Mat_View (Data, Rows, Columns, Process);
   end With_Read_Only_Mat_View;
   procedure With_Read_Only_Mat_View
     (Data    : aliased Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : Mat)) is
   begin
      Viewing.With_Read_Only_Mat_View (Data, Shape, Process);
   end With_Read_Only_Mat_View;
   procedure With_Read_Only_Strided_Mat_View
     (Data                      : aliased Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   : not null access procedure (Image : Mat)) is
   begin
      Viewing.With_Read_Only_Strided_Mat_View
        (Data, Rows, Columns, Row_Stride, Process);
   end With_Read_Only_Strided_Mat_View;
   procedure With_Read_Only_Strided_Mat_View
     (Data    : aliased Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : Mat)) is
   begin
      Viewing.With_Read_Only_Strided_Mat_View (Data, Shape, Strides, Process);
   end With_Read_Only_Strided_Mat_View;
end OpenCV.Core.Int8_Vec4_Mat_View;
