with OpenCV.Core.Float32_Vec3;

package OpenCV.Core.Float32_Vec3_Row_Access is

   subtype Column_Index is Natural;

   type Row_Array is
     array (Natural range <>) of OpenCV.Core.Float32_Vec3.Vector;

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array);

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array);

   --  Invokes Process with a zero-copy view of one Float32 C3 Mat row.
   --  Data directly aliases native OpenCV storage for that logical row;
   --  no pixel values are copied. Each Data element is one complete
   --  interleaved C3 pixel: Data (Column) (0 .. 2) are the three native
   --  Float32 channels. The explicitly aliased callback formal guarantees
   --  that Data is passed by reference and directly denotes the borrowed
   --  Mat row for the duration of Process. The ordinary lifetime of the
   --  view is the callback. Data is indexed with zero-based Mat columns:
   --  Data'First = 0, Data'Last = Image.Columns - 1, and Data'Length =
   --  Image.Columns. Only the active row elements are exposed, never
   --  inter-row padding. Non-contiguous Regions are supported because
   --  each 2-D logical row remains a contiguous sequence even when the
   --  parent stride is larger. The implementation holds a shallow Mat
   --  lease for the callback so referenced storage cannot disappear
   --  merely because another header is rebound or finalized. That lease
   --  is deterministic memory management, not thread synchronization.
   --  Do not retain a reference or address of Data after Process
   --  returns. Read-only access performs no copy; if another alias
   --  mutates the shared storage during the callback, Data observes
   --  those changes according to ordinary aliasing rules.
   --  Image.Is_Continuous is not required.
   procedure With_Read_Only_Row
     (Image   : Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased Row_Array));

   --  As With_Read_Only_Row, except Process receives an in-out view.
   --  Writes through Data mutate the actual Mat storage immediately.
   --  There is no write-back phase. A write through Data is visible
   --  through Image and any shallow alias before Process returns, and
   --  a write through another alias is immediately visible through
   --  Data. Exceptions raised by Process propagate unchanged; any
   --  writes completed before the exception remain visible.
   procedure With_Writable_Row
     (Image   : in out Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased in out Row_Array));

end OpenCV.Core.Float32_Vec3_Row_Access;
