with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

package body OpenCV.Core.Int32_Vec3_Buffer_Access is
   pragma Compile_Time_Error (Int32_Vec3.Vector'Size /= 96, "Vec3 size");
   pragma
     Compile_Time_Error
       (Int32_Vec3.Vector'Component_Size /= 32, "Vec3 scalar size");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 96, "Vec3 buffer packing");
   pragma
     Compile_Time_Error (Int32_Vec3.Vector'Alignment > 4, "Vec3 alignment");
   pragma
     Compile_Time_Error
       (Int32_Vec3.Component_Index'First /= 0
          or else Int32_Vec3.Component_Index'Last /= 2,
        "Vec3 indices");
   package Borrowing is new
     Internal.Typed_Continuous_Borrowing
       (Element_Type             => Int32_Vec3.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Int32,
        Required_Channels        => 3,
        Expected_Element_Bits    => 96,
        Native_Element_Alignment => 4,
        Type_Name                => "Int32 Vec3");
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
end OpenCV.Core.Int32_Vec3_Buffer_Access;
