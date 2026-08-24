package OpenCV.Core.Float32_Mat_View is

   type Buffer_Array is array (Natural range <>) of Float32_Value;

   --  Invokes Process with a temporary writable Mat that aliases Data.
   --  Image (0, 0) is Data (Data'First) and row-major element Image
   --  (Row, Column) is Data (Data'First + Row * Columns + Column).
   --  Data'Length must equal Rows * Columns. The Ada lower bound is
   --  not exposed through the Mat. Image is valid only during Process
   --  and must not be retained. Ordinary shallow copies and views are
   --  rejected because they would share the caller-owned buffer after
   --  Process returns. Clone is the supported way to keep an
   --  independent Mat. Writes through Image immediately modify Data,
   --  and writes through Data immediately affect Image. The temporary
   --  cv::Mat header does not own Data and does not copy it. The aliased
   --  formal passes Data by reference, so Image denotes caller-owned storage.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary writable Mat that aliases Data using
   --  Row_Stride_Elements complete Float32 elements between logical rows.
   --  Image (Row, Column) is Data (Data'First + Row *
   --  Row_Stride_Elements + Column). Row_Stride_Elements must be at least
   --  Columns, and Data'Length must be at least (Rows - 1) *
   --  Row_Stride_Elements + Columns. Data may include row padding and
   --  trailing storage, neither of which is part of Image. The lifetime,
   --  aliasing, and escape rules are the same as With_Writable_Mat_View.
   procedure With_Writable_Mat_View
     (Data                : aliased in out Buffer_Array;
      Rows                : Positive;
      Columns             : Positive;
      Row_Stride_Elements : Positive;
      Process             : not null access procedure (Image : in out Mat));

end OpenCV.Core.Float32_Mat_View;
