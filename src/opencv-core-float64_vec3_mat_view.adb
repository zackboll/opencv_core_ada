with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.Float64_Vec3_Mat_View is
   pragma
     Compile_Time_Error
       (Float64_Vec3.Vector'Size /= 192, "Float64 Vec3 must occupy 192 bits");
   pragma
     Compile_Time_Error
       (Float64_Vec3.Vector'Component_Size /= 64,
        "Float64 Vec3 channels must occupy 64 bits");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= 192,
        "Float64 Vec3 buffer must be tightly packed");
   pragma
     Compile_Time_Error
       (Float64_Vec3.Vector'Alignment > 8,
        "Float64 Vec3 alignment exceeds native alignment");
   pragma
     Compile_Time_Error
       (Float64_Vec3.Component_Index'First /= 0
          or else Float64_Vec3.Component_Index'Last /= 2,
        "Float64 Vec3 indices must be 0 .. 2");

   package Viewing is new
     Internal.Typed_External_Mat_View
       (Element_Type             => Float64_Vec3.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float64,
        Required_Channels        => 3,
        Expected_Element_Bits    => 192,
        Native_Element_Alignment => 8,
        Type_Name                => "Float64 Vec3");

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

end OpenCV.Core.Float64_Vec3_Mat_View;
