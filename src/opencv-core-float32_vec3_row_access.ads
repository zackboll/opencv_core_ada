with OpenCV.Core.Float32_Vec3;

package OpenCV.Core.Float32_Vec3_Row_Access is

   subtype Column_Index is Natural;

   type Row_Array is
     array (Natural range <>) of OpenCV.Core.Float32_Vec3.Vector;

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array);

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array);

end OpenCV.Core.Float32_Vec3_Row_Access;
