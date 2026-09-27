with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.Int16_Vec4_Buffer_Access is
   pragma Compile_Time_Error (Int16_Vec4.Vector'Size /= 64, "Vec4 size");
   pragma
     Compile_Time_Error
       (Int16_Vec4.Vector'Component_Size /= 16, "Vec4 scalar size");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 64, "Vec4 buffer packing");
   pragma
     Compile_Time_Error (Int16_Vec4.Vector'Alignment > 2, "Vec4 alignment");
   pragma
     Compile_Time_Error
       (Int16_Vec4.Component_Index'First /= 0
          or else Int16_Vec4.Component_Index'Last /= 3,
        "Vec4 indices");
   package Borrowing is new
     Internal.Typed_Continuous_Borrowing
       (Element_Type             => Int16_Vec4.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Int16,
        Required_Channels        => 4,
        Expected_Element_Bits    => 64,
        Native_Element_Alignment => 2,
        Type_Name                => "Int16 Vec4");
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
end OpenCV.Core.Int16_Vec4_Buffer_Access;
