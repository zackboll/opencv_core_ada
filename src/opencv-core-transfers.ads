package OpenCV.Core.Transfers is
   --  Explicit independent copies. These non-primitive operations live in a
   --  child because Ada cannot dispatch simultaneously on Mat and UMat.
   function To_UMat (Self : Mat) return UMat;
   function To_Mat (Self : UMat) return Mat;
end OpenCV.Core.Transfers;
