with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.Float64_Mat_View is

   package Viewing is new
     OpenCV.Core.Internal.Typed_External_Mat_View
       (Element_Type             => Float64_Value,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float64,
        Required_Channels        => 1,
        Expected_Element_Bits    => 64,
        Native_Element_Alignment => 8,
        Type_Name                => "Float64");

   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Rows, Columns, Process);
   end With_Writable_Mat_View;

end OpenCV.Core.Float64_Mat_View;
