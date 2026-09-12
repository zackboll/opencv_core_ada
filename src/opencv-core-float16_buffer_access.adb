with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.Float16_Buffer_Access is

   pragma
     Compile_Time_Error
       (Float16_Value'Object_Size /= 16,
        "Float16_Value must have no hidden padding");

   package Borrowing is new
     OpenCV.Core.Internal.Typed_Continuous_Borrowing
       (Element_Type             => Float16_Value,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float16,
        Required_Channels        => 1,
        Expected_Element_Bits    => 16,
        Native_Element_Alignment => 2,
        Type_Name                => "Float16");

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

end OpenCV.Core.Float16_Buffer_Access;
