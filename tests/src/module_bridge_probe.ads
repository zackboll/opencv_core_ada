with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Core.Sparse.Module_Interop;

package Module_Bridge_Probe is

   type UMat_Extents is array (1 .. 32) of Interfaces.Integer_32
   with Convention => C;

   type UMat_Observation is record
      Dims, Rows, Columns, Depth, Channels, Continuous, Submatrix :
        Interfaces.Integer_32;
      Extents                                                     :
        UMat_Extents;
      Sum                                                         :
        Interfaces.IEEE_Float_64;
   end record
   with Convention => C;

   function Inspect_UMat
     (Handle      : OpenCV.Core.Module_Interop.Input_UMat_Handle;
      Observation : access UMat_Observation) return Interfaces.Integer_32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_umat_input";

   function Inspect_UMat_Pair
     (Left, Right                         :
        OpenCV.Core.Module_Interop.Input_UMat_Handle;
      Left_Observation, Right_Observation : access UMat_Observation)
      return Interfaces.Integer_32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_umat_pair";

   function Mutate_UMat
     (Handle : OpenCV.Core.Module_Interop.Output_UMat_Handle;
      Value  : Interfaces.IEEE_Float_64) return Interfaces.Integer_32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_umat_mutate";

   function Create_UMat
     (Handle : OpenCV.Core.Module_Interop.Output_UMat_Handle)
      return Interfaces.Integer_32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_umat_create";

   function Add_UMat
     (Input  : OpenCV.Core.Module_Interop.Input_UMat_Handle;
      Output : OpenCV.Core.Module_Interop.Output_UMat_Handle)
      return Interfaces.Integer_32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_umat_add";

   function Invalid_UMat
     (Handle : OpenCV.Core.Module_Interop.Output_UMat_Handle)
      return Interfaces.Integer_32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_umat_invalid";

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
      Extents    : OpenCV.Core.Dimension_Array (1 .. 32);
      Depth      : Integer;
      Channels   : Integer;
      Nodes      : Integer;
      Value      : Integer;
   end record;

   procedure Inspect_Sparse
     (Handle      : OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Indices     : OpenCV.Core.Index_Array;
      Observation : out Sparse_Input_Observation);

   procedure Inspect_Sparse_Pair
     (Left              :
        OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Right             :
        OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Left_Indices      : OpenCV.Core.Index_Array;
      Right_Indices     : OpenCV.Core.Index_Array;
      Left_Observation  : out Sparse_Input_Observation;
      Right_Observation : out Sparse_Input_Observation);

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
