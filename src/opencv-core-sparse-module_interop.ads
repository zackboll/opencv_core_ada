private with OpenCV.Internal.C_API;

package OpenCV.Core.Sparse.Module_Interop is

   --  Binding implementation interface for cooperating OpenCV Ada module
   --  crates. This is not an ordinary application API.
   --
   --  Each handle is valid only during its callback. A module implementation
   --  passes it only to its private C interop layer; it neither owns nor
   --  retains the associated native SparseMat header, and it does not copy
   --  node storage. There is no temporary external-buffer SparseMat view.
   --  Output handles expose the actual Core header so an operation such as
   --  calcHist can call SparseMat::create on it in place.
   type Input_Sparse_Mat_Handle is private;
   type Output_Sparse_Mat_Handle is private;

   procedure With_Input_Handle
     (Image   : Sparse_Mat;
      Process : not null access procedure (Handle : Input_Sparse_Mat_Handle));

   procedure With_Output_Handle
     (Image   : in out Sparse_Mat;
      Process : not null access procedure (Handle : Output_Sparse_Mat_Handle));

private

   type Input_Sparse_Mat_Handle is new OpenCV.Internal.C_API.Sparse_Mat_Handle
   with Convention => C;

   type Output_Sparse_Mat_Handle is new OpenCV.Internal.C_API.Sparse_Mat_Handle
   with Convention => C;

end OpenCV.Core.Sparse.Module_Interop;
