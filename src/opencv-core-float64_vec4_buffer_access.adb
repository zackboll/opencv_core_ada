with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.Float64_Vec4_Buffer_Access is
   pragma Compile_Time_Error (Float64_Vec4.Vector'Size /= 256, "Vec4 size");
   pragma
     Compile_Time_Error
       (Float64_Vec4.Vector'Component_Size /= 64, "Vec4 scalar size");
   pragma
     Compile_Time_Error (Buffer_Array'Component_Size /= 256, "Vec4 packing");
   pragma
     Compile_Time_Error (Float64_Vec4.Vector'Alignment > 8, "Vec4 alignment");
   pragma
     Compile_Time_Error
       (Float64_Vec4.Component_Index'First /= 0
          or else Float64_Vec4.Component_Index'Last /= 3,
        "Vec4 indices");
   package Borrowing is new
     Internal.Typed_Continuous_Borrowing
       (Element_Type             => Float64_Vec4.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float64,
        Required_Channels        => 4,
        Expected_Element_Bits    => 256,
        Native_Element_Alignment => 8,
        Type_Name                => "Float64 Vec4");
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
end OpenCV.Core.Float64_Vec4_Buffer_Access;
