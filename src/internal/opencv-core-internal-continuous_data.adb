with Ada.Exceptions;

package body OpenCV.Core.Internal.Continuous_Data is

   use type OpenCV.Internal.C_API.Status;

   function Borrow (Image : Mat) return Borrowed_Buffer is
      Address    : aliased System.Address := System.Null_Address;
      Byte_Count : aliased OpenCV.Internal.C_API.C_UInt64 := 0;
      Status     : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Borrow_Contiguous_Data
          (Self           => Image.Handle,
           Data           => Address'Access,
           Out_Byte_Count => Byte_Count'Access);
   begin
      if Status /= OpenCV.Internal.C_API.Success then
         declare
            Diagnostic : constant String :=
              OpenCV.Internal.C_API.Last_Error_Message;
         begin
            if Diagnostic'Length = 0 then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity, "Mat contiguous borrow failed");
            else
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "Mat contiguous borrow failed: " & Diagnostic);
            end if;
         end;
      end if;

      return (Address => Address, Byte_Count => Byte_Count);
   end Borrow;

end OpenCV.Core.Internal.Continuous_Data;
