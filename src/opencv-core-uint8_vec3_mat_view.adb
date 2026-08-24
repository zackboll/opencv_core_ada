with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.UInt8_Vec3_Mat_View is

   pragma
     Compile_Time_Error
       (OpenCV.Core.UInt8_Vec3.Vector'Size /= 24,
        "UInt8 Vec3 Vector must be exactly 24 bits for zero-copy C3 views");
   pragma
     Compile_Time_Error
       (OpenCV.Core.UInt8_Vec3.Vector'Component_Size /= 8,
        "UInt8 Vec3 components must be tightly packed 8-bit channels");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 24,
        "UInt8 Vec3 Buffer_Array must be tightly packed 24-bit pixels");
   pragma
     Compile_Time_Error
       (OpenCV.Core.UInt8_Vec3.Vector'Alignment > 1,
        "UInt8 Vec3 Vector alignment is stricter than CV_8UC3 guarantees");
   pragma
     Compile_Time_Error
       (OpenCV.Core.UInt8_Vec3.Component_Index'First /= 0
          or else OpenCV.Core.UInt8_Vec3.Component_Index'Last /= 2,
        "UInt8 Vec3 components must be indexed 0 .. 2");

   package Viewing is new
     OpenCV.Core.Internal.Typed_External_Mat_View
       (Element_Type             => OpenCV.Core.UInt8_Vec3.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => UInt8,
        Required_Channels        => 3,
        Expected_Element_Bits    => 24,
        Native_Element_Alignment => 1,
        Type_Name                => "UInt8 Vec3");

   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Rows, Columns, Process);
   end With_Writable_Mat_View;

end OpenCV.Core.UInt8_Vec3_Mat_View;
