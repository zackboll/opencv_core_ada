with OpenCV.Core.Float32_Vec4;

package OpenCV.Core.Float32_Vec4_Mat_View is
   type Buffer_Array is array (Natural range <>) of Float32_Vec4.Vector;
   --  Caller owns storage. A shallow Mat must not escape; Clone is safe.
   procedure With_Writable_Mat_View
     (Data          : aliased in out Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : in out Mat));
   --  Row_Stride counts complete Vec4 elements, including final-row padding.
   procedure With_Writable_Strided_Mat_View
     (Data                      : aliased in out Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   :
        not null access procedure (Image : in out Mat));
end OpenCV.Core.Float32_Vec4_Mat_View;
