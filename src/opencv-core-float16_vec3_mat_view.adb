with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.Float16_Vec3_Mat_View is

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
       (OpenCV.Core.Float16_Vec3.Vector'Component_Size /= 16,
        "Float16 Vec3 components must be tightly packed 16-bit channels");
   pragma
     Compile_Time_Error
       (OpenCV.Core.Float16_Vec3.Vector'Size /= 48,
        "Float16 Vec3 Vector must be exactly 48 bits for zero-copy C3"
          & " views");
   pragma
     Compile_Time_Error
       (OpenCV.Core.Float16_Vec3.Vector'Object_Size /= 48,
        "Float16 Vec3 Vector must have no hidden padding");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 48,
        "Float16 Vec3 Buffer_Array must be tightly packed 48-bit pixels");
   pragma
     Compile_Time_Error
       (OpenCV.Core.Float16_Vec3.Vector'Alignment > 2,
        "Float16 Vec3 Vector alignment is stricter than CV_16FC3 guarantees");
   pragma
     Compile_Time_Error
       (OpenCV.Core.Float16_Vec3.Component_Index'First /= 0
          or else OpenCV.Core.Float16_Vec3.Component_Index'Last /= 2,
        "Float16 Vec3 components must be indexed 0 .. 2");

   package Viewing is new
     OpenCV.Core.Internal.Typed_External_Mat_View
       (Element_Type             => OpenCV.Core.Float16_Vec3.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float16,
        Required_Channels        => 3,
        Expected_Element_Bits    => 48,
        Native_Element_Alignment => 2,
        Type_Name                => "Float16 Vec3");

   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Rows, Columns, Process);
   end With_Writable_Mat_View;

   procedure With_Writable_Strided_Mat_View
     (Data       : aliased in out Buffer_Array;
      Rows       : Positive;
      Columns    : Positive;
      Row_Stride : Positive;
      Process    : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Strided_Mat_View
        (Data, Rows, Columns, Row_Stride, Process);
   end With_Writable_Strided_Mat_View;

   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Shape, Process);
   end With_Writable_Mat_View;

end OpenCV.Core.Float16_Vec3_Mat_View;
