package OpenCV.Core.UInt8_Row_Access is

   subtype Column_Index is Natural;

   type Row_Array is array (Natural range <>) of UInt8_Value;

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array);

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array);

end OpenCV.Core.UInt8_Row_Access;
