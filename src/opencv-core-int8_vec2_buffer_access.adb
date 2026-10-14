with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.Int8_Vec2_Buffer_Access is

   pragma
     Compile_Time_Error
       (Int8_Value'Size /= 8,
        "Int8_Value must be exactly 8 bits to alias CV_8S storage");
   pragma
     Compile_Time_Error
       (Int8_Value'Object_Size /= 8, "Int8_Value must have no hidden padding");
   pragma
     Compile_Time_Error
       (Int8_Vec2.Vector'Component_Size /= 8,
        "Int8 Vec2 components must be tightly packed 8-bit channels");
   pragma
     Compile_Time_Error
       (Int8_Vec2.Vector'Size /= 16,
        "Int8 Vec2 Vector must be exactly 16 bits for zero-copy buffers");
   --  Borrowing verifies Object_Size before native lease entry (GNAT 12).
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 16,
        "Int8 Vec2 Buffer_Array must be tightly packed 16-bit elements");
   --  Borrowing verifies alignment before lease entry and typed conversion.
   pragma
     Compile_Time_Error
       (Int8_Vec2.Component_Index'First /= 0
          or else Int8_Vec2.Component_Index'Last /= 1,
        "Int8 Vec2 components must be indexed 0 .. 1");

   package Borrowing is new
     Internal.Typed_Continuous_Borrowing
       (Element_Type             => Int8_Vec2.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Int8,
        Required_Channels        => 2,
        Expected_Element_Bits    => 16,
        Native_Element_Alignment => 1,
        Type_Name                => "Int8 Vec2");

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

end OpenCV.Core.Int8_Vec2_Buffer_Access;
