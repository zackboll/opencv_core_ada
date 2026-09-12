with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.Float16_Mat_View is

   pragma
     Compile_Time_Error
       (Float16_Value'Object_Size /= 16,
        "Float16_Value must have no hidden padding");

   package Viewing is new
     OpenCV.Core.Internal.Typed_External_Mat_View
       (Element_Type                 => Float16_Value,
        Buffer_Array                 => Buffer_Array,
        Required_Depth               => Float16,
        Required_Channels            => 1,
        Expected_Element_Bits        => 16,
        Native_Element_Alignment     => 2,
        Type_Name                    => "Float16",
        Require_Complete_Row_Strides => False);

   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Rows, Columns, Process);
   end With_Writable_Mat_View;

   procedure With_Writable_Strided_Mat_View
     (Data       : aliased in out Buffer_Array;
      Rows       : Positive;
      Columns    : Positive;
      Row_Stride : Positive;
      Process    : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Strided_Mat_View
        (Data, Rows, Columns, Row_Stride, Process);
   end With_Writable_Strided_Mat_View;

end OpenCV.Core.Float16_Mat_View;
