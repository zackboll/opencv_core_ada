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

   --  UMat handles have the same callback-only lifetime. A cooperating module
   --  may pass them only to its private native interop layer. Core owns both
   --  the opaque wrapper and original cv::UMat header: do not delete the header
   --  or retain its pointer after the callback/call scope. No public native
   --  pointer escapes and no ownership transfer, Mat conversion, or mapping
   --  occurs. All module shims must use a compatible OpenCV ABI/installation
   --  with Core. Output operations may rebind the actual Core-owned header.
   type Input_UMat_Handle is private;
   type Output_UMat_Handle is private;

   procedure With_Input_Handle
     (Image   : UMat;
      Process : not null access procedure (Handle : Input_UMat_Handle));

   procedure With_Output_Handle
     (Image   : in out UMat;
      Process : not null access procedure (Handle : Output_UMat_Handle));

private

   type Input_Mat_Handle is new OpenCV.Internal.C_API.Mat_Handle
   with Convention => C;

   type Output_Mat_Handle is new OpenCV.Internal.C_API.Mat_Handle
   with Convention => C;

   type Input_UMat_Handle is new OpenCV.Internal.C_API.UMat_Handle
   with Convention => C;

   type Output_UMat_Handle is new OpenCV.Internal.C_API.UMat_Handle
   with Convention => C;

end OpenCV.Core.Module_Interop;
