with OpenCV.Core;

generic
   type Element is private;
   type View_Array is array (Natural range <>) of Element;
   type Borrow_Array is array (Natural range <>) of Element;
   Expected : OpenCV.Core.Mat_Type;
   Name : String;
   with function Value_At (Offset : Natural) return Element;
   with
     function Get
       (Image : OpenCV.Core.Mat; Indices : OpenCV.Core.Index_Array)
        return Element;
   with
     procedure Packed_2D
       (Data          : aliased View_Array;
        Rows, Columns : Positive;
        Process       : not null access procedure (Image : OpenCV.Core.Mat));
   with
     procedure Packed_ND
       (Data    : aliased View_Array;
        Shape   : OpenCV.Core.Dimension_Array;
        Process : not null access procedure (Image : OpenCV.Core.Mat));
   with
     procedure Strided_2D
       (Data                      : aliased View_Array;
        Rows, Columns, Row_Stride : Positive;
        Process                   :
          not null access procedure (Image : OpenCV.Core.Mat));
   with
     procedure Strided_ND
       (Data    : aliased View_Array;
        Shape   : OpenCV.Core.Dimension_Array;
        Strides : OpenCV.Core.Dimension_Stride_Array;
        Process : not null access procedure (Image : OpenCV.Core.Mat));
   with
     procedure Borrow
       (Image   : OpenCV.Core.Mat;
        Process : not null access procedure (Data : aliased Borrow_Array));
package Read_Only_Mat_View_Checks is
   procedure Check_Packed;
   procedure Check_Strided;
end Read_Only_Mat_View_Checks;
