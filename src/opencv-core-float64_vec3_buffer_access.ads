with OpenCV.Core.Float64_Vec3;

package OpenCV.Core.Float64_Vec3_Buffer_Access is
   type Buffer_Array is array (Natural range <>) of Float64_Vec3.Vector;
   --  Callback-scoped zero-copy borrow of continuous storage, in Mat order.
   --  Each entry is one complete C3 element. A shallow Mat lease protects
   --  the storage; do not retain Data after the callback returns.
   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array));
   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process :
        not null access procedure (Data : aliased in out Buffer_Array));
end OpenCV.Core.Float64_Vec3_Buffer_Access;
