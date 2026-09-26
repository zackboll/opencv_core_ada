with OpenCV.Core.Float32_Vec2;

package OpenCV.Core.Float32_Vec2_Buffer_Access is
   type Buffer_Array is array (Natural range <>) of Float32_Vec2.Vector;
   --  Each borrowed element is a complete C2 pixel.
   --  References must not escape the callback.
   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array));
   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process :
        not null access procedure (Data : aliased in out Buffer_Array));
end OpenCV.Core.Float32_Vec2_Buffer_Access;
