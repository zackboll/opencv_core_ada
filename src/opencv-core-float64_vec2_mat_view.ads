with OpenCV.Core.Float64_Vec2;

package OpenCV.Core.Float64_Vec2_Mat_View is
   type Buffer_Array is array (Natural range <>) of Float64_Vec2.Vector;
   --  One Data element is one complete C2 element. The temporary Mat must
   --  not escape Process; Clone is the supported independent escape path.
   procedure With_Writable_Mat_View
     (Data          : aliased in out Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : in out Mat));
   --  Packed N-D view: Shape'Length in 2 .. 32, positive extents in OpenCV
   --  dimension order, Data'Length = product (Shape) complete C2 elements,
   --  final dimension fastest. Neither Ada lower bound is visible. No copy
   --  or narrowing; the caller keeps ownership; shallow escape (including
   --  Slice and Reshape) is rejected and Clone is the independent escape.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat));
   --  2-D row-strided view. Row_Stride counts Vec2 elements; backing
   --  includes final-row padding.
   procedure With_Writable_Strided_Mat_View
     (Data                      : aliased in out Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   :
        not null access procedure (Image : in out Mat));
   --  Strided N-D view: one stride per Shape dimension (bounds irrelevant),
   --  counted in complete Vec2 elements, not scalars or bytes. Final stride
   --  is 1 and Strides (I) >= Strides (I + 1) * Shape (I + 1). Index
   --  (I1, .., In) is Data (Data'First + I1 * S1 + .. + In * Sn).
   --  Data'Length >= Shape (first) * Strides (first), including final outer
   --  padding; extra trailing entries are allowed and padding is untouched.
   --  No copy or narrowing; the caller keeps ownership; shallow escape is
   --  rejected and Clone is the independent escape path.
   procedure With_Writable_Strided_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : in out Mat));
end OpenCV.Core.Float64_Vec2_Mat_View;
