with System;

package OpenCV.Core.Internal.External_View_Alignment is
   --  No access through Address is performed. This validator can also be
   --  exercised with untyped storage without constructing an invalid object.
   function Verified_Address
     (Address : System.Address; Native_Alignment : Positive)
      return System.Address;
end OpenCV.Core.Internal.External_View_Alignment;
