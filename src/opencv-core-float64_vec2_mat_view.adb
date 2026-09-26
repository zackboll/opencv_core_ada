with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.Float64_Vec2_Mat_View is
   pragma
     Compile_Time_Error
       (Float64_Vec2.Vector'Size /= 128
          or else Float64_Vec2.Vector'Component_Size /= 64
          or else Buffer_Array'Component_Size /= 128
          or else Float64_Vec2.Vector'Alignment > 8
          or else Float64_Vec2.Component_Index'First /= 0
          or else Float64_Vec2.Component_Index'Last /= 1,
        "Float64 Vec2 overlay must be two packed native Float64 channels");
   package Viewing is new
     Internal.Typed_External_Mat_View
       (Element_Type             => Float64_Vec2.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float64,
        Required_Channels        => 2,
        Expected_Element_Bits    => 128,
        Native_Element_Alignment => 8,
        Type_Name                => "Float64 Vec2");
   procedure With_Writable_Mat_View
     (Data          : aliased in out Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Rows, Columns, Process);
   end With_Writable_Mat_View;
   procedure With_Writable_Strided_Mat_View
     (Data                      : aliased in out Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   :
        not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Strided_Mat_View
        (Data, Rows, Columns, Row_Stride, Process);
   end With_Writable_Strided_Mat_View;
end OpenCV.Core.Float64_Vec2_Mat_View;
