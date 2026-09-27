with OpenCV.Core.UInt16_Vec2;

package OpenCV.Core.UInt16_Vec2_Mat_View is
   type Buffer_Array is array (Natural range <>) of UInt16_Vec2.Vector;
   --  Strides count complete vectors. Shallow escape is prohibited;
   --  Clone may escape.
   procedure With_Writable_Mat_View
     (Data          : aliased in out Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : in out Mat));
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : in out Mat));
   procedure With_Writable_Strided_Mat_View
     (Data                      : aliased in out Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   :
        not null access procedure (Image : in out Mat));
   procedure With_Writable_Strided_Mat_View
     (Data    : aliased in out Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : in out Mat));
   procedure With_Read_Only_Mat_View
     (Data          : aliased Buffer_Array;
      Rows, Columns : Positive;
      Process       : not null access procedure (Image : Mat));
   procedure With_Read_Only_Mat_View
     (Data    : aliased Buffer_Array;
      Shape   : Dimension_Array;
      Process : not null access procedure (Image : Mat));
   procedure With_Read_Only_Strided_Mat_View
     (Data                      : aliased Buffer_Array;
      Rows, Columns, Row_Stride : Positive;
      Process                   : not null access procedure (Image : Mat));
   procedure With_Read_Only_Strided_Mat_View
     (Data    : aliased Buffer_Array;
      Shape   : Dimension_Array;
      Strides : Dimension_Stride_Array;
      Process : not null access procedure (Image : Mat));
end OpenCV.Core.UInt16_Vec2_Mat_View;
