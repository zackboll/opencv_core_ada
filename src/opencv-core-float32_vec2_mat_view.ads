with OpenCV.Core.Float32_Vec2;

package OpenCV.Core.Float32_Vec2_Mat_View is
   type Buffer_Array is array (Natural range <>) of Float32_Vec2.Vector;
   --  One Data element is one complete C2 element. The temporary Mat must
   --  not escape Process; Clone is the supported independent escape path.
   procedure With_Writable_Mat_View
     (Data          : aliased in out Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : in out Mat));
   --  Packed N-D view: Shape'Length in 2 .. 32, positive extents in OpenCV
   --  dimension order, Data'Length = product (Shape) complete C2 elements,
   --  final dimension fastest. Neither Ada lower bound is visible. No copy;
   --  the caller keeps ownership; shallow escape (including Slice and
   --  Reshape) is rejected and Clone is the independent escape path.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat));
   --  2-D only. Row_Stride counts Vec2 elements; backing includes final-row
   --  padding.
   procedure With_Writable_Strided_Mat_View
     (Data                      : aliased in out Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   :
        not null access procedure (Image : in out Mat));
end OpenCV.Core.Float32_Vec2_Mat_View;
