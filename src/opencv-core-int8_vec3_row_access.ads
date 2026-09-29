with OpenCV.Core.Int8_Vec3;

--  Row access for two-dimensional Int8 C3 (CV_8SC3) Mats. Each Row_Array
--  element is one complete 3-byte C3 element: Data (Column) (0 .. 2) are the
--  three native signed channels (-128 .. 127, OpenCV schar storage). No
--  color meaning is assigned to the channels.
--
--  Read_Row / Write_Row copy one complete row; Data'Length must equal
--  Image.Columns and Data'First may be any Natural.
--
--  With_Read_Only_Row / With_Writable_Row invoke Process with a zero-copy
--  view that directly aliases the native row for the duration of the
--  callback: Data'First = 0 and Data'Length = Image.Columns. Non-contiguous
--  Regions are supported. A shallow Mat lease keeps the storage alive even
--  if Image (or a parent Mat) is rebound during Process; the lease is memory
--  management, not synchronization. Writes are immediate; exceptions raised
--  by Process propagate and completed writes remain visible. Do not retain
--  a reference or address of Data after Process returns.

package OpenCV.Core.Int8_Vec3_Row_Access is
   type Row_Array is array (Natural range <>) of Int8_Vec3.Vector;
   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array);
   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array);
   procedure With_Read_Only_Row
     (Image   : Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased Row_Array));
   procedure With_Writable_Row
     (Image   : in out Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased in out Row_Array));
end OpenCV.Core.Int8_Vec3_Row_Access;
