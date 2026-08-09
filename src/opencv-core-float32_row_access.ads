package OpenCV.Core.Float32_Row_Access is

   subtype Column_Index is Natural;

   type Row_Array is array (Natural range <>) of Float32_Value;

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array);

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array);

end OpenCV.Core.Float32_Row_Access;
