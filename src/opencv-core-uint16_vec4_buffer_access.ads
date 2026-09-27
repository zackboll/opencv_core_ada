with OpenCV.Core.UInt16_Vec4;

package OpenCV.Core.UInt16_Vec4_Buffer_Access is
   type Buffer_Array is array (Natural range <>) of UInt16_Vec4.Vector;
   --  Continuous Mats only; one entry per complete C4 element.
   --  A shallow lease retains storage until Process returns.
   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array));
   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process :
        not null access procedure (Data : aliased in out Buffer_Array));
end OpenCV.Core.UInt16_Vec4_Buffer_Access;
