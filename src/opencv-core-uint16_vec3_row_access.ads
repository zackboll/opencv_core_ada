with OpenCV.Core.UInt16_Vec3;

package OpenCV.Core.UInt16_Vec3_Row_Access is
   type Row_Array is array (Natural range <>) of UInt16_Vec3.Vector;
   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array);
   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array);
   --  Callback-scoped, zero-copy row access with a shallow storage lease.
   procedure With_Read_Only_Row
     (Image   : Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased Row_Array));
   procedure With_Writable_Row
     (Image   : in out Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased in out Row_Array));
end OpenCV.Core.UInt16_Vec3_Row_Access;
