with OpenCV.Core.Float64_Vec2;

package OpenCV.Core.Float64_Vec2_Row_Access is
   subtype Column_Index is Natural;
   type Row_Array is array (Natural range <>) of Float64_Vec2.Vector;
   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array);
   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array);
   --  Borrowed storage is valid only during Process; no references may escape.
   procedure With_Read_Only_Row
     (Image   : Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased Row_Array));
   procedure With_Writable_Row
     (Image   : in out Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased in out Row_Array));
end OpenCV.Core.Float64_Vec2_Row_Access;
