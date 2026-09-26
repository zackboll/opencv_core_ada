with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.Float32_Vec2_Mat_View is
   pragma
     Compile_Time_Error
       (Float32_Vec2.Vector'Size /= 64
          or else Float32_Vec2.Vector'Component_Size /= 32
          or else Buffer_Array'Component_Size /= 64
          or else Float32_Vec2.Vector'Alignment > 4
          or else Float32_Vec2.Component_Index'First /= 0
          or else Float32_Vec2.Component_Index'Last /= 1,
        "Float32 Vec2 overlay must be two packed native Float32 channels");
   package Viewing is new
     Internal.Typed_External_Mat_View
       (Element_Type             => Float32_Vec2.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float32,
        Required_Channels        => 2,
        Expected_Element_Bits    => 64,
        Native_Element_Alignment => 4,
        Type_Name                => "Float32 Vec2");
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
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Shape, Process);
   end With_Writable_Mat_View;
end OpenCV.Core.Float32_Vec2_Mat_View;
