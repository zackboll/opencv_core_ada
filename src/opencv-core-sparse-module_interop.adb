with Ada.Exceptions;
with System;

package body OpenCV.Core.Sparse.Module_Interop is

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

   procedure With_Input_Handle
     (Image   : Sparse_Mat;
      Process : not null access procedure (Handle : Input_Sparse_Mat_Handle))
   is
   begin
      Process (Input_Sparse_Mat_Handle (Image.Handle));
   end With_Input_Handle;

   procedure With_Output_Handle
     (Image   : in out Sparse_Mat;
      Process : not null access procedure (Handle : Output_Sparse_Mat_Handle))
   is
      Borrowed_Native_Sparse : aliased System.Address := System.Null_Address;
      Status                 : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Sparse_Resolve_Output
          (Image.Handle, Borrowed_Native_Sparse'Access);
   begin
      --  The resolver runs before Process so a null or invalid Core header is
      --  rejected without invoking the module callback. Unlike Mat, SparseMat
      --  has no temporary external-buffer view to reject.
      Raise_On_Error (Status, "module output SparseMat access");
      Process (Output_Sparse_Mat_Handle (Image.Handle));
   end With_Output_Handle;

end OpenCV.Core.Sparse.Module_Interop;
