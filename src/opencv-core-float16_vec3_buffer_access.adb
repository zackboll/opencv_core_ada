with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.Float16_Vec3_Buffer_Access is

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
          & " buffers");
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

   package Borrowing is new
     OpenCV.Core.Internal.Typed_Continuous_Borrowing
       (Element_Type             => OpenCV.Core.Float16_Vec3.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float16,
        Required_Channels        => 3,
        Expected_Element_Bits    => 48,
        Native_Element_Alignment => 2,
        Type_Name                => "Float16 Vec3");

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

end OpenCV.Core.Float16_Vec3_Buffer_Access;
