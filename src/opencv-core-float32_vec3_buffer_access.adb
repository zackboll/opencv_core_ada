with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.Float32_Vec3_Buffer_Access is

   pragma
     Compile_Time_Error
       (OpenCV.Core.Float32_Vec3.Vector'Size /= 96,
        "Float32 Vec3 Vector must be exactly 96 bits for zero-copy C3 rows");
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

   package Borrowing is new
     OpenCV.Core.Internal.Typed_Continuous_Borrowing
       (Element_Type             => OpenCV.Core.Float32_Vec3.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float32,
        Required_Channels        => 3,
        Expected_Element_Bits    => 96,
        Native_Element_Alignment => 4,
        Type_Name                => "Float32 Vec3");

   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array)) is
   begin
      Borrowing.With_Read_Only_Buffer (Image, Process);
   end With_Read_Only_Buffer;

   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process : not null access procedure (Data : aliased in out Buffer_Array))
   is
   begin
      Borrowing.With_Writable_Buffer (Image, Process);
   end With_Writable_Buffer;

end OpenCV.Core.Float32_Vec3_Buffer_Access;
