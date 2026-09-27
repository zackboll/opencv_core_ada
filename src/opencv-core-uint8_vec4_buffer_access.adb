with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.UInt8_Vec4_Buffer_Access is
   pragma Compile_Time_Error (UInt8_Vec4.Vector'Size /= 32, "Vec4 size");
   pragma
     Compile_Time_Error
       (UInt8_Vec4.Vector'Component_Size /= 8, "Vec4 scalar size");
   pragma
     Compile_Time_Error (Buffer_Array'Component_Size /= 32, "Vec4 packing");
   pragma
     Compile_Time_Error (UInt8_Vec4.Vector'Alignment > 1, "Vec4 alignment");
   pragma
     Compile_Time_Error
       (UInt8_Vec4.Component_Index'First /= 0
          or else UInt8_Vec4.Component_Index'Last /= 3,
        "Vec4 indices");
   package Borrowing is new
     Internal.Typed_Continuous_Borrowing
       (Element_Type             => UInt8_Vec4.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => UInt8,
        Required_Channels        => 4,
        Expected_Element_Bits    => 32,
        Native_Element_Alignment => 1,
        Type_Name                => "UInt8 Vec4");
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
end OpenCV.Core.UInt8_Vec4_Buffer_Access;
