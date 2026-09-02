package OpenCV.Core.Float64_Mat_View is

   type Buffer_Array is array (Natural range <>) of Float64_Value;

   --  Invokes Process with a temporary writable CV_64FC1 Mat that aliases
   --  Data. Image (0, 0) is Data (Data'First), and row-major element Image
   --  (Row, Column) is Data (Data'First + Row * Columns + Column).
   --  Data'Length must equal Rows * Columns. The Ada lower bound is not
   --  exposed through the Mat. Image is valid only during Process and must
   --  not be retained. Ordinary shallow copies and views are rejected
   --  because they would share the caller-owned buffer after Process returns.
   --  Clone is the supported way to keep an independent Mat. Writes through
   --  Image immediately modify Data, and writes through Data immediately
   --  affect Image. The temporary cv::Mat header does not own or copy Data.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary writable CV_64FC1 Mat that aliases
   --  Data with Row_Stride Float64 elements between logical row starts.
   --  Row_Stride must be at least Columns. Image (Row, Column) maps to
   --  Data (Data'First + Row * Row_Stride + Column). Data'Length must be at
   --  least (Rows - 1) * Row_Stride + Columns; final-row padding need not be
   --  present. Padding and extra trailing storage are outside the logical Mat.
   --  No data is copied. Ownership, callback lifetime, and escape rules are
   --  identical to With_Writable_Mat_View; Clone is the safe escape path.
   procedure With_Writable_Strided_Mat_View
     (Data       : aliased in out Buffer_Array;
      Rows       : Positive;
      Columns    : Positive;
      Row_Stride : Positive;
      Process    : not null access procedure (Image : in out Mat));

end OpenCV.Core.Float64_Mat_View;
