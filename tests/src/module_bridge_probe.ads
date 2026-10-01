with Interfaces;
with OpenCV.Core.Module_Interop;
with OpenCV.Core.Sparse.Module_Interop;

package Module_Bridge_Probe is

   function OpenCV_Major_Version return Natural;

   type Input_Observation is record
      Rows    : Integer;
      Columns : Integer;
      Depth   : Integer;
      Value   : Integer;
   end record;

   procedure Inspect
     (Handle      : OpenCV.Core.Module_Interop.Input_Mat_Handle;
      Observation : out Input_Observation);

   procedure Mutate
     (Handle : OpenCV.Core.Module_Interop.Output_Mat_Handle;
      Value  : Interfaces.Unsigned_8);

   procedure Create
     (Handle  : OpenCV.Core.Module_Interop.Output_Mat_Handle;
      Rows    : Natural;
      Columns : Natural;
      Value   : Interfaces.Unsigned_8);

   procedure Check_Invalid_Inputs;

   type Sparse_Input_Observation is record
      Dimensions : Integer;
      Extent_0   : Integer;
      Extent_1   : Integer;
      Nodes      : Integer;
      Value      : Integer;
   end record;

   procedure Inspect_Sparse
     (Handle      : OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Observation : out Sparse_Input_Observation);

   procedure Mutate_Sparse
     (Handle : OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle;
      Value  : Interfaces.IEEE_Float_32);

   procedure Create_Sparse
     (Handle   : OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle;
      Extent_0 : Natural;
      Extent_1 : Natural;
      Value    : Interfaces.IEEE_Float_32);

   procedure Check_Invalid_Sparse_Inputs;

end Module_Bridge_Probe;
