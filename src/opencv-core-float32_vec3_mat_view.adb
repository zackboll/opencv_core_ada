with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.Float32_Vec3_Mat_View is

   pragma
     Compile_Time_Error
       (OpenCV.Core.Float32_Vec3.Vector'Size /= 96,
        "Float32 Vec3 Vector must be exactly 96 bits for zero-copy C3 views");
   pragma
     Compile_Time_Error
       (OpenCV.Core.Float32_Vec3.Vector'Component_Size /= 32,
        "Float32 Vec3 components must be tightly packed 32-bit channels");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 96,
        "Float32 Vec3 Buffer_Array must be tightly packed 96-bit pixels");
   pragma
     Compile_Time_Error
       (OpenCV.Core.Float32_Vec3.Vector'Alignment > 4,
        "Float32 Vec3 Vector alignment is stricter than CV_32FC3 guarantees");
   pragma
     Compile_Time_Error
       (OpenCV.Core.Float32_Vec3.Component_Index'First /= 0
          or else OpenCV.Core.Float32_Vec3.Component_Index'Last /= 2,
        "Float32 Vec3 components must be indexed 0 .. 2");

   package Viewing is new
     OpenCV.Core.Internal.Typed_External_Mat_View
       (Element_Type             => OpenCV.Core.Float32_Vec3.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float32,
        Required_Channels        => 3,
        Expected_Element_Bits    => 96,
        Native_Element_Alignment => 4,
        Type_Name                => "Float32 Vec3");

   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Rows, Columns, Process);
   end With_Writable_Mat_View;

end OpenCV.Core.Float32_Vec3_Mat_View;
