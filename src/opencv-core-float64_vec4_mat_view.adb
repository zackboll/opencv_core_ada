with OpenCV.Core.Internal.Typed_External_Mat_View;

package body OpenCV.Core.Float64_Vec4_Mat_View is
   pragma Compile_Time_Error (Float64_Vec4.Vector'Size /= 256, "Vec4 size");
   pragma
     Compile_Time_Error
       (Float64_Vec4.Vector'Component_Size /= 64, "Vec4 scalar size");
   pragma
     Compile_Time_Error (Buffer_Array'Component_Size /= 256, "Vec4 packing");
   pragma
     Compile_Time_Error (Float64_Vec4.Vector'Alignment > 8, "Vec4 alignment");
   pragma
     Compile_Time_Error
       (Float64_Vec4.Component_Index'First /= 0
          or else Float64_Vec4.Component_Index'Last /= 3,
        "Vec4 indices");
   package Viewing is new
     Internal.Typed_External_Mat_View
       (Element_Type             => Float64_Vec4.Vector,
        Buffer_Array             => Buffer_Array,
        Required_Depth           => Float64,
        Required_Channels        => 4,
        Expected_Element_Bits    => 256,
        Native_Element_Alignment => 8,
        Type_Name                => "Float64 Vec4");
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
end OpenCV.Core.Float64_Vec4_Mat_View;
