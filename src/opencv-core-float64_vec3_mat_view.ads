with OpenCV.Core.Float64_Vec3;

package OpenCV.Core.Float64_Vec3_Mat_View is
   type Buffer_Array is array (Natural range <>) of Float64_Vec3.Vector;
   --  Callback-scoped zero-copy view of caller storage. Each entry is one
   --  C3 element. A shallow Mat must not escape; Clone makes an independent
   --  copy. Packed views require Rows * Columns entries.
   procedure With_Writable_Mat_View
     (Data          : aliased in out Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : in out Mat));
   --  Packed N-D view: Shape'Length in 2 .. 32, positive extents in OpenCV
   --  dimension order, Data'Length = product (Shape) complete C3 elements,
   --  final dimension fastest. Neither Ada lower bound is visible. No copy
   --  or narrowing; the caller keeps ownership; shallow escape (including
   --  Slice and Reshape) is rejected and Clone is the independent escape.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat));
   --  2-D only. Row_Stride counts complete Vec3 elements. Rows * Row_Stride
   --  entries
   --  are required, including final-row padding outside the logical Mat.
   procedure With_Writable_Strided_Mat_View
     (Data                      : aliased in out Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   :
        not null access procedure (Image : in out Mat));
end OpenCV.Core.Float64_Vec3_Mat_View;
