with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.Float32_Buffer_Access is

   package Borrowing is new
     OpenCV.Core.Internal.Typed_Continuous_Borrowing
       (Element_Type             => Float32_Value,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float32,
        Required_Channels        => 1,
        Expected_Element_Bits    => 32,
        Native_Element_Alignment => 4,
        Type_Name                => "Float32");

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

end OpenCV.Core.Float32_Buffer_Access;
