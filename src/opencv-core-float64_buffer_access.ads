package OpenCV.Core.Float64_Buffer_Access is

   type Buffer_Array is array (Natural range <>) of Float64_Value;

   --  Invokes Process with a zero-copy view of a continuous, two-dimensional
   --  Float64 C1 Mat. Data directly aliases native OpenCV storage for the
   --  entire logical buffer; no values are copied or converted. The callback
   --  bounds the lifetime of the borrowed view, which must not be retained.
   --  Data is flat, zero-based, and in native row-major order, with Length
   --  equal to Image.Total. Nonempty non-continuous Mats raise OpenCV_Error
   --  before Process is invoked. A continuous Region is accepted. A shallow
   --  Mat lease keeps the storage alive for the duration of Process.
   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array));

   --  As With_Read_Only_Buffer, except Process receives an in-out view.
   --  Writes mutate shared Mat storage immediately, without a write-back
   --  phase. Callback exceptions propagate and completed writes remain.
   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process :
        not null access procedure (Data : aliased in out Buffer_Array));

end OpenCV.Core.Float64_Buffer_Access;
