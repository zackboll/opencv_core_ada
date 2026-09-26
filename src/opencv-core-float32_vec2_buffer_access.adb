with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.Float32_Vec2_Buffer_Access is
   pragma
     Compile_Time_Error
       (Float32_Vec2.Vector'Size /= 64
          or else Float32_Vec2.Vector'Component_Size /= 32
          or else Buffer_Array'Component_Size /= 64
          or else Float32_Vec2.Vector'Alignment > 4
          or else Float32_Vec2.Component_Index'First /= 0
          or else Float32_Vec2.Component_Index'Last /= 1,
        "Float32 Vec2 overlay must be two packed native Float32 channels");
   package Borrowing is new
     Internal.Typed_Continuous_Borrowing
       (Element_Type             => Float32_Vec2.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float32,
        Required_Channels        => 2,
        Expected_Element_Bits    => 64,
        Native_Element_Alignment => 4,
        Type_Name                => "Float32 Vec2");
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
end OpenCV.Core.Float32_Vec2_Buffer_Access;
