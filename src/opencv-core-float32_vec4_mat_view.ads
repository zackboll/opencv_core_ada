with OpenCV.Core.Float32_Vec4;

package OpenCV.Core.Float32_Vec4_Mat_View is
   type Buffer_Array is array (Natural range <>) of Float32_Vec4.Vector;
   --  Caller owns storage. A shallow Mat must not escape; Clone is safe.
   procedure With_Writable_Mat_View
     (Data          : aliased in out Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : in out Mat));
   --  Packed N-D view: Shape'Length in 2 .. 32, positive extents in OpenCV
   --  dimension order, Data'Length = product (Shape) complete C4 elements,
   --  final dimension fastest. Neither Ada lower bound is visible. No copy;
   --  the caller keeps ownership; shallow escape (including Slice and
   --  Reshape) is rejected and Clone is the independent escape path.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat));
   --  2-D row-strided view. Row_Stride counts complete Vec4 elements,
   --  including final-row padding.
   procedure With_Writable_Strided_Mat_View
     (Data                      : aliased in out Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   :
        not null access procedure (Image : in out Mat));
   --  Strided N-D view: one stride per Shape dimension (bounds irrelevant),
   --  counted in complete Vec4 elements, not scalars or bytes. Final stride
   --  is 1 and Strides (I) >= Strides (I + 1) * Shape (I + 1). Index
   --  (I1, .., In) is Data (Data'First + I1 * S1 + .. + In * Sn).
   --  Data'Length >= Shape (first) * Strides (first), including final outer
   --  padding; extra trailing entries are allowed and padding is untouched.
   --  No copy; the caller keeps ownership; shallow escape is rejected and
   --  Clone is the independent escape path.
   procedure With_Writable_Strided_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : in out Mat));
end OpenCV.Core.Float32_Vec4_Mat_View;
