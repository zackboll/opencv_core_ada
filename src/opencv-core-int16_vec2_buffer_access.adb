with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.Int16_Vec2_Buffer_Access is
   pragma Compile_Time_Error (Int16_Vec2.Vector'Size /= 32, "Vec2 size");
   pragma
     Compile_Time_Error
       (Int16_Vec2.Vector'Component_Size /= 16, "Vec2 scalar size");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 32, "Vec2 buffer packing");
   pragma
     Compile_Time_Error (Int16_Vec2.Vector'Alignment > 2, "Vec2 alignment");
   pragma
     Compile_Time_Error
       (Int16_Vec2.Component_Index'First /= 0
          or else Int16_Vec2.Component_Index'Last /= 1,
        "Vec2 indices");
   package Borrowing is new
     Internal.Typed_Continuous_Borrowing
       (Element_Type             => Int16_Vec2.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Int16,
        Required_Channels        => 2,
        Expected_Element_Bits    => 32,
        Native_Element_Alignment => 2,
        Type_Name                => "Int16 Vec2");
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
end OpenCV.Core.Int16_Vec2_Buffer_Access;
