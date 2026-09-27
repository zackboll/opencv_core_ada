with OpenCV.Core.Int32_Vec2;

package OpenCV.Core.Int32_Vec2_Buffer_Access is
   type Buffer_Array is array (Natural range <>) of Int32_Vec2.Vector;
   --  Each entry is one complete C2 element of a continuous Mat.
   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array));
   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process :
        not null access procedure (Data : aliased in out Buffer_Array));
end OpenCV.Core.Int32_Vec2_Buffer_Access;
