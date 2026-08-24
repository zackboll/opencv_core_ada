package OpenCV.Core.Float32_Buffer_Access is

   type Buffer_Array is array (Natural range <>) of Float32_Value;

   --  Invokes Process with a zero-copy view of a continuous Float32 C1
   --  Mat. Data directly aliases native OpenCV storage for the entire
   --  logical buffer; no pixel values are copied. The explicitly
   --  aliased callback formal guarantees that Data is passed by
   --  reference and directly denotes the borrowed Mat for the duration
   --  of Process. The ordinary lifetime of the view is the callback.
   --  Data is a flat zero-based row-major array of Mat elements:
   --  Data'First = 0, Data'Last = Natural (Image.Total) - 1, and
   --  Data'Length = Natural (Image.Total). Element
   --  Data (Row * Image.Columns + Column) denotes Image (Row, Column).
   --  There are no row separators or inter-row padding. Image must be
   --  continuous; a nonempty non-continuous Mat raises OpenCV_Error
   --  before Process is invoked. A continuous Region is accepted even
   --  when it is a submatrix. The implementation holds one shallow Mat
   --  lease for the callback so referenced storage cannot disappear
   --  merely because another header is rebound or finalized. That lease
   --  is deterministic memory management, not thread synchronization.
   --  Do not retain a reference or address of Data after Process
   --  returns. Read-only access performs no copy; if another alias
   --  mutates the shared storage during the callback, Data observes
   --  those changes according to ordinary aliasing rules.
   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array));

   --  As With_Read_Only_Buffer, except Process receives an in-out view.
   --  Writes through Data mutate the actual Mat storage immediately.
   --  There is no write-back phase. A write through Data is visible
   --  through Image and any shallow alias before Process returns, and
   --  a write through another alias is immediately visible through
   --  Data. Exceptions raised by Process propagate unchanged; any
   --  writes completed before the exception remain visible.
   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process :
        not null access procedure (Data : aliased in out Buffer_Array));

end OpenCV.Core.Float32_Buffer_Access;
