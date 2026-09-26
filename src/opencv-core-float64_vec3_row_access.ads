with OpenCV.Core.Float64_Vec3;

package OpenCV.Core.Float64_Vec3_Row_Access is
   type Row_Array is array (Natural range <>) of Float64_Vec3.Vector;
   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array);
   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array);
   --  Callback-scoped zero-copy row, including non-contiguous Regions.
   --  A shallow Mat lease protects storage. Do not retain Data afterward.
   procedure With_Read_Only_Row
     (Image   : Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased Row_Array));
   procedure With_Writable_Row
     (Image   : in out Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased in out Row_Array));
end OpenCV.Core.Float64_Vec3_Row_Access;
