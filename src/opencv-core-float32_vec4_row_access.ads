with OpenCV.Core.Float32_Vec4;

package OpenCV.Core.Float32_Vec4_Row_Access is
   type Row_Array is array (Natural range <>) of Float32_Vec4.Vector;
   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array);
   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array);
   --  Callback-scoped zero-copy borrow; shallow lease protects storage.
   procedure With_Read_Only_Row
     (Image   : Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased Row_Array));
   procedure With_Writable_Row
     (Image   : in out Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased in out Row_Array));
end OpenCV.Core.Float32_Vec4_Row_Access;
