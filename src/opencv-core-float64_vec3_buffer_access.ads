with OpenCV.Core.Float64_Vec3;

package OpenCV.Core.Float64_Vec3_Buffer_Access is
   type Buffer_Array is array (Natural range <>) of Float64_Vec3.Vector;
   --  Callback-scoped zero-copy borrow of a continuous Float64 C3 Mat of
   --  any dimension count; genuine N-D Mats are supported. Data is one
   --  flat zero-based array, Data'Length = Natural (Image.Total), in
   --  OpenCV element order with the final dimension varying fastest; for
   --  a 2-D Mat, Data (Row * Image.Columns + Column) is (Row, Column).
   --  Each entry is one complete C3 element; channels are never
   --  flattened. Non-continuous Mats (gapped Regions or Slices) raise
   --  OpenCV_Error before Process runs. A shallow Mat lease protects the
   --  storage (memory lifetime, not synchronization); writes are
   --  immediately visible. Do not retain Data after the callback returns.
   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array));
   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process :
        not null access procedure (Data : aliased in out Buffer_Array));
end OpenCV.Core.Float64_Vec3_Buffer_Access;
