private with OpenCV.Internal.C_API;

package OpenCV.Core.Module_Interop is

   --  Binding implementation interface for cooperating OpenCV Ada module
   --  crates. This is not an ordinary application API.
   --
   --  Each handle is valid only during its callback. A module implementation
   --  passes it only to its private C interop layer; it neither owns nor
   --  retains the associated native Mat header.
   type Input_Mat_Handle is private;
   type Output_Mat_Handle is private;

   procedure With_Input_Handle
     (Image   : Mat;
      Process : not null access procedure (Handle : Input_Mat_Handle));

   procedure With_Output_Handle
     (Image   : in out Mat;
      Process : not null access procedure (Handle : Output_Mat_Handle));

private

   type Input_Mat_Handle is new OpenCV.Internal.C_API.Mat_Handle
   with Convention => C;

   type Output_Mat_Handle is new OpenCV.Internal.C_API.Mat_Handle
   with Convention => C;

end OpenCV.Core.Module_Interop;
