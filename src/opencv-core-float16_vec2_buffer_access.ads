with OpenCV.Core.Float16_Vec2;

package OpenCV.Core.Float16_Vec2_Buffer_Access is

   type Buffer_Array is array (Natural range <>) of Float16_Vec2.Vector;

   --  Invokes Process with a zero-copy view of a continuous Float16 C2 Mat
   --  of any dimension count; genuine N-D Mats are supported. Data directly
   --  aliases native CV_16FC2 storage. Each Data element is one complete
   --  4-byte C2 element: Data (Index) (0 .. 1) are channels 0 and 1; channels
   --  are never flattened into Data indexing. Each component is the exact
   --  stored IEEE-754 binary16 encoding; signed zeros, subnormals,
   --  infinities, and NaN payloads are not converted or canonicalized.
   --  Data'First = 0 and Data'Length = Natural (Image.Total), in OpenCV
   --  element order with the final dimension varying fastest. Image must be
   --  continuous; a nonempty non-continuous Mat (gapped Region or Slice)
   --  raises OpenCV_Error before Process is invoked. A shallow Mat lease
   --  keeps storage alive for the callback (memory management, not thread
   --  synchronization). Do not retain a reference or address of Data after
   --  Process returns.
   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array));

   --  As With_Read_Only_Buffer, except writes through Data mutate the Mat
   --  storage immediately. Exceptions raised by Process propagate unchanged;
   --  completed writes remain visible.
   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process :
        not null access procedure (Data : aliased in out Buffer_Array));

end OpenCV.Core.Float16_Vec2_Buffer_Access;
