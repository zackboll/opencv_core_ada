with Ada.Exceptions;
with System;

package body OpenCV.Core.Module_Interop is

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
     (Image   : Mat;
      Process : not null access procedure (Handle : Input_Mat_Handle)) is
   begin
      Process (Input_Mat_Handle (Image.Handle));
   end With_Input_Handle;

   procedure With_Output_Handle
     (Image   : in out Mat;
      Process : not null access procedure (Handle : Output_Mat_Handle))
   is
      Borrowed_Native_Mat : aliased System.Address := System.Null_Address;
      Status              : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Resolve_Output
          (Image.Handle, Borrowed_Native_Mat'Access);
   begin
      --  The resolver is deliberately called before Process. In particular it
      --  rejects a temporary external-buffer view, whose header cannot safely
      --  be rebound by an OutputArray operation.
      Raise_On_Error (Status, "module output Mat access");
      Process (Output_Mat_Handle (Image.Handle));
   end With_Output_Handle;

end OpenCV.Core.Module_Interop;
