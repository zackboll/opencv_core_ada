with System.Storage_Elements;

package body OpenCV.Core.Internal.External_View_Alignment is
   use System.Storage_Elements;
   use type System.Address;

   function Verified_Address
     (Address : System.Address; Native_Alignment : Positive)
      return System.Address is
   begin
      if Address = System.Null_Address
        or else To_Integer (Address) rem Integer_Address (Native_Alignment)
                /= 0
      then
         raise OpenCV_Error
           with "external Mat view backing address is misaligned";
      end if;
      return Address;
   end Verified_Address;
end OpenCV.Core.Internal.External_View_Alignment;
