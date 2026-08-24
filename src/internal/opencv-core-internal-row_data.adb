with Ada.Exceptions;

package body OpenCV.Core.Internal.Row_Data is

   use type OpenCV.Internal.C_API.Status;

   procedure Raise_On_Error
     (Status : OpenCV.Internal.C_API.Status; Operation : String)
   is
      Diagnostic : constant String := OpenCV.Internal.C_API.Last_Error_Message;
   begin
      if Status = OpenCV.Internal.C_API.Success then
         return;
      end if;

      if Diagnostic'Length = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " failed");
      else
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " failed: " & Diagnostic);
      end if;
   end Raise_On_Error;

   function Borrow_Row (Image : Mat; Row : Natural) return Borrowed_Row is
      Address    : aliased System.Address := System.Null_Address;
      Byte_Count : aliased OpenCV.Internal.C_API.C_UInt64 := 0;
      Status     : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Borrow_Row_Data
          (Self           => Image.Handle,
           Row            => OpenCV.Internal.C_API.C_Int32 (Row),
           Data           => Address'Access,
           Out_Byte_Count => Byte_Count'Access);
   begin
      Raise_On_Error (Status, "Mat row borrow");
      return (Address => Address, Byte_Count => Byte_Count);
   end Borrow_Row;

end OpenCV.Core.Internal.Row_Data;
