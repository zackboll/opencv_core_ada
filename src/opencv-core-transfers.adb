with OpenCV.Internal.C_API;

package body OpenCV.Core.Transfers is
   use type OpenCV.Internal.C_API.Status;

   function To_UMat (Self : Mat) return UMat is
      Result : UMat;
      Handle : aliased OpenCV.Internal.C_API.UMat_Handle :=
        OpenCV.Internal.C_API.Null_UMat_Handle;
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_To_UMat (Self.Handle, Handle'Access);
   begin
      if Status /= OpenCV.Internal.C_API.Success then
         raise OpenCV_Error
           with
             "Mat to UMat copy: " & OpenCV.Internal.C_API.Last_Error_Message;
      end if;
      OpenCV.Internal.C_API.UMat_Destroy (Result.Handle);
      Result.Handle := Handle;
      return Result;
   end To_UMat;

   function To_Mat (Self : UMat) return Mat is
      Result : Mat;
      Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.UMat_To_Mat (Self.Handle, Handle'Access);
   begin
      if Status /= OpenCV.Internal.C_API.Success then
         raise OpenCV_Error
           with
             "UMat to Mat copy: " & OpenCV.Internal.C_API.Last_Error_Message;
      end if;
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := Handle;
      return Result;
   end To_Mat;
end OpenCV.Core.Transfers;
