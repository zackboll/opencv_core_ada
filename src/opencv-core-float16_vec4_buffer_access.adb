with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.Float16_Vec4_Buffer_Access is

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
       (Float16_Vec4.Vector'Component_Size /= 16,
        "Float16 Vec4 components must be tightly packed 16-bit channels");
   pragma
     Compile_Time_Error
       (Float16_Vec4.Vector'Size /= 64,
        "Float16 Vec4 Vector must be exactly 64 bits for zero-copy buffers");
   pragma
     Compile_Time_Error
       (Float16_Vec4.Vector'Object_Size /= 64,
        "Float16 Vec4 Vector must have no hidden padding");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 64,
        "Float16 Vec4 Buffer_Array must be tightly packed 64-bit elements");
   pragma
     Compile_Time_Error
       (Float16_Vec4.Vector'Alignment > 2,
        "Float16 Vec4 Vector alignment is stricter than CV_16FC4 guarantees");
   pragma
     Compile_Time_Error
       (Float16_Vec4.Component_Index'First /= 0
          or else Float16_Vec4.Component_Index'Last /= 3,
        "Float16 Vec4 components must be indexed 0 .. 3");

   package Borrowing is new
     Internal.Typed_Continuous_Borrowing
       (Element_Type             => Float16_Vec4.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float16,
        Required_Channels        => 4,
        Expected_Element_Bits    => 64,
        Native_Element_Alignment => 2,
        Type_Name                => "Float16 Vec4");

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

end OpenCV.Core.Float16_Vec4_Buffer_Access;
