with OpenCV.Core.UInt16_Vec2;

package OpenCV.Core.UInt16_Vec2_Buffer_Access is
   type Buffer_Array is array (Natural range <>) of UInt16_Vec2.Vector;
   --  Each entry is one complete C2 element; borrow is callback-scoped.
   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array));
   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process :
        not null access procedure (Data : aliased in out Buffer_Array));
end OpenCV.Core.UInt16_Vec2_Buffer_Access;
