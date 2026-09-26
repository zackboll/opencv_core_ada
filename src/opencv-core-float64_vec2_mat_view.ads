with OpenCV.Core.Float64_Vec2;

package OpenCV.Core.Float64_Vec2_Mat_View is
   type Buffer_Array is array (Natural range <>) of Float64_Vec2.Vector;
   --  One Data element is one complete C2 element. The temporary Mat must
   --  not escape Process; Clone is the supported independent escape path.
   procedure With_Writable_Mat_View
     (Data          : aliased in out Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : in out Mat));
   --  Row_Stride counts Vec2 elements; backing includes final-row padding.
   procedure With_Writable_Strided_Mat_View
     (Data                      : aliased in out Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   :
        not null access procedure (Image : in out Mat));
end OpenCV.Core.Float64_Vec2_Mat_View;
