with System;
with OpenCV.Internal.C_API;

package OpenCV.Core.Internal.Row_Data is

   type Borrowed_Row is record
      Address    : System.Address := System.Null_Address;
      Byte_Count : OpenCV.Internal.C_API.C_UInt64 := 0;
   end record;

   --  Returns the start of one logical 2-D Mat row and the number of
   --  active logical bytes in that row. The address is valid only while
   --  Image (or another header sharing the same storage) remains alive.
   function Borrow_Row (Image : Mat; Row : Natural) return Borrowed_Row;

end OpenCV.Core.Internal.Row_Data;
