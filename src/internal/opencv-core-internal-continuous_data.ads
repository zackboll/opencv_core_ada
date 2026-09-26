with System;
with OpenCV.Internal.C_API;

package OpenCV.Core.Internal.Continuous_Data is

   --  Complete logical storage of a continuous Mat of any dimensionality,
   --  as opposed to Row_Data, which describes one logical 2-D row.
   type Borrowed_Buffer is record
      Address    : System.Address := System.Null_Address;
      Byte_Count : OpenCV.Internal.C_API.C_UInt64 := 0;
   end record;

   --  Returns the start of Image's contiguous element storage and exactly
   --  product (all extents) * Element_Size logical bytes. A zero-element
   --  Mat returns a null address and zero bytes. Raises OpenCV_Error when
   --  the storage is not continuous or the byte count is not
   --  representable. The address is valid only while Image (or another
   --  header sharing the same storage) remains alive.
   function Borrow (Image : Mat) return Borrowed_Buffer;

end OpenCV.Core.Internal.Continuous_Data;
