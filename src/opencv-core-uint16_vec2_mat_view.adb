with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.UInt16_Vec2_Mat_View is
   pragma Compile_Time_Error (UInt16_Vec2.Vector'Size /= 32, "Vec2 size");
   pragma
     Compile_Time_Error
       (UInt16_Vec2.Vector'Component_Size /= 16, "Vec2 scalar size");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 32, "Vec2 view packing");
   pragma
     Compile_Time_Error (UInt16_Vec2.Vector'Alignment > 2, "Vec2 alignment");
   pragma
     Compile_Time_Error
       (UInt16_Vec2.Component_Index'First /= 0
          or else UInt16_Vec2.Component_Index'Last /= 1,
        "Vec2 indices");
   package Viewing is new
     Internal.Typed_External_Mat_View
       (Element_Type             => UInt16_Vec2.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => UInt16,
        Required_Channels        => 2,
        Expected_Element_Bits    => 32,
        Native_Element_Alignment => 2,
        Type_Name                => "UInt16 Vec2");
   procedure With_Writable_Mat_View
     (Data          : aliased in out Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Rows, Columns, Process);
   end With_Writable_Mat_View;
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Mat_View (Data, Shape, Process);
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
   procedure With_Writable_Strided_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : in out Mat)) is
   begin
      Viewing.With_Writable_Strided_Mat_View (Data, Shape, Strides, Process);
   end With_Writable_Strided_Mat_View;
   procedure With_Read_Only_Mat_View
     (Data          : aliased Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : Mat)) is
   begin
      Viewing.With_Read_Only_Mat_View (Data, Rows, Columns, Process);
   end With_Read_Only_Mat_View;
   procedure With_Read_Only_Mat_View
     (Data    : aliased Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : Mat)) is
   begin
      Viewing.With_Read_Only_Mat_View (Data, Shape, Process);
   end With_Read_Only_Mat_View;
   procedure With_Read_Only_Strided_Mat_View
     (Data                      : aliased Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   : not null access procedure (Image : Mat)) is
   begin
      Viewing.With_Read_Only_Strided_Mat_View
        (Data, Rows, Columns, Row_Stride, Process);
   end With_Read_Only_Strided_Mat_View;
   procedure With_Read_Only_Strided_Mat_View
     (Data    : aliased Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : Mat)) is
   begin
      Viewing.With_Read_Only_Strided_Mat_View (Data, Shape, Strides, Process);
   end With_Read_Only_Strided_Mat_View;
end OpenCV.Core.UInt16_Vec2_Mat_View;
