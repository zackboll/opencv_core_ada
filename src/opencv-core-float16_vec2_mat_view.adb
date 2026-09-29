with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.Float16_Vec2_Mat_View is
   pragma
     Compile_Time_Error
       (Float16_Value'Size /= 16,
        "Float16_Value must be exactly 16 bits to alias CV_16F storage");
   pragma
     Compile_Time_Error
       (Float16_Value'Object_Size /= 16,
        "Float16_Value must have no hidden padding");
   pragma
     Compile_Time_Error
       (Float16_Vec2.Vector'Component_Size /= 16,
        "Float16 Vec2 components must be tightly packed 16-bit channels");
   pragma
     Compile_Time_Error
       (Float16_Vec2.Vector'Size /= 32,
        "Float16 Vec2 Vector must be exactly 32 bits for zero-copy views");
   pragma
     Compile_Time_Error
       (Float16_Vec2.Vector'Object_Size /= 32,
        "Float16 Vec2 Vector must have no hidden padding");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 32,
        "Float16 Vec2 Buffer_Array must be tightly packed 32-bit elements");
   pragma
     Compile_Time_Error
       (Float16_Vec2.Vector'Alignment > 2,
        "Float16 Vec2 Vector alignment is stricter than CV_16FC2 guarantees");
   pragma
     Compile_Time_Error
       (Float16_Vec2.Component_Index'First /= 0
          or else Float16_Vec2.Component_Index'Last /= 1,
        "Float16 Vec2 components must be indexed 0 .. 1");

   package Viewing is new
     Internal.Typed_External_Mat_View
       (Element_Type             => Float16_Vec2.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float16,
        Required_Channels        => 2,
        Expected_Element_Bits    => 32,
        Native_Element_Alignment => 2,
        Type_Name                => "Float16 Vec2");

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
end OpenCV.Core.Float16_Vec2_Mat_View;
