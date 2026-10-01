with Ada.Exceptions;
with Interfaces.C;

package body Module_Bridge_Probe is

   subtype C_Int32 is Interfaces.C.int;
   subtype C_UInt8 is Interfaces.C.unsigned_char;

   use type C_Int32;

   function Probe_Version_Major return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_version_major";

   function Probe_Input
     (Handle  : OpenCV.Core.Module_Interop.Input_Mat_Handle;
      Rows    : access C_Int32;
      Columns : access C_Int32;
      Depth   : access C_Int32;
      Value   : access C_Int32) return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_input";

   function Probe_Mutate
     (Handle : OpenCV.Core.Module_Interop.Output_Mat_Handle; Value : C_UInt8)
      return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_mutate";

   function Probe_Create
     (Handle  : OpenCV.Core.Module_Interop.Output_Mat_Handle;
      Rows    : C_Int32;
      Columns : C_Int32;
      Value   : C_UInt8) return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_create";

   function Probe_Invalid_Inputs return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_invalid_inputs";

   subtype C_Float32 is Interfaces.C.C_float;

   function Probe_Sparse_Input
     (Handle   : OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Dims     : access C_Int32;
      Extent_0 : access C_Int32;
      Extent_1 : access C_Int32;
      Nodes    : access C_Int32;
      Value    : access C_Int32) return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_sparse_input";

   function Probe_Sparse_Mutate
     (Handle : OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle;
      Value  : C_Float32) return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_sparse_mutate";

   function Probe_Sparse_Create
     (Handle   : OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle;
      Extent_0 : C_Int32;
      Extent_1 : C_Int32;
      Value    : C_Float32) return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_sparse_create";

   function Probe_Sparse_Invalid_Inputs return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_sparse_invalid_inputs";

   procedure Raise_On_Error (Status : C_Int32; Operation : String) is
   begin
      if Status /= 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV.OpenCV_Error'Identity, Operation & " failed");
      end if;
   end Raise_On_Error;

   function OpenCV_Major_Version return Natural is
   begin
      return Natural (Probe_Version_Major);
   end OpenCV_Major_Version;

   procedure Inspect
     (Handle      : OpenCV.Core.Module_Interop.Input_Mat_Handle;
      Observation : out Input_Observation)
   is
      Rows    : aliased C_Int32 := 0;
      Columns : aliased C_Int32 := 0;
      Depth   : aliased C_Int32 := 0;
      Value   : aliased C_Int32 := 0;
   begin
      Raise_On_Error
        (Probe_Input
           (Handle, Rows'Access, Columns'Access, Depth'Access, Value'Access),
         "module bridge input probe");
      Observation :=
        (Integer (Rows), Integer (Columns), Integer (Depth), Integer (Value));
   end Inspect;

   procedure Mutate
     (Handle : OpenCV.Core.Module_Interop.Output_Mat_Handle;
      Value  : Interfaces.Unsigned_8) is
   begin
      Raise_On_Error
        (Probe_Mutate (Handle, C_UInt8 (Value)),
         "module bridge mutation probe");
   end Mutate;

   procedure Create
     (Handle  : OpenCV.Core.Module_Interop.Output_Mat_Handle;
      Rows    : Natural;
      Columns : Natural;
      Value   : Interfaces.Unsigned_8) is
   begin
      Raise_On_Error
        (Probe_Create
           (Handle, C_Int32 (Rows), C_Int32 (Columns), C_UInt8 (Value)),
         "module bridge create probe");
   end Create;

   procedure Check_Invalid_Inputs is
   begin
      Raise_On_Error
        (Probe_Invalid_Inputs, "module bridge invalid-input probe");
   end Check_Invalid_Inputs;

   procedure Inspect_Sparse
     (Handle      : OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Observation : out Sparse_Input_Observation)
   is
      Dims     : aliased C_Int32 := 0;
      Extent_0 : aliased C_Int32 := 0;
      Extent_1 : aliased C_Int32 := 0;
      Nodes    : aliased C_Int32 := 0;
      Value    : aliased C_Int32 := 0;
   begin
      Raise_On_Error
        (Probe_Sparse_Input
           (Handle,
            Dims'Access,
            Extent_0'Access,
            Extent_1'Access,
            Nodes'Access,
            Value'Access),
         "module bridge sparse input probe");
      Observation :=
        (Integer (Dims),
         Integer (Extent_0),
         Integer (Extent_1),
         Integer (Nodes),
         Integer (Value));
   end Inspect_Sparse;

   procedure Mutate_Sparse
     (Handle : OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle;
      Value  : Interfaces.IEEE_Float_32) is
   begin
      Raise_On_Error
        (Probe_Sparse_Mutate (Handle, C_Float32 (Value)),
         "module bridge sparse mutation probe");
   end Mutate_Sparse;

   procedure Create_Sparse
     (Handle   : OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle;
      Extent_0 : Natural;
      Extent_1 : Natural;
      Value    : Interfaces.IEEE_Float_32) is
   begin
      Raise_On_Error
        (Probe_Sparse_Create
           (Handle, C_Int32 (Extent_0), C_Int32 (Extent_1), C_Float32 (Value)),
         "module bridge sparse create probe");
   end Create_Sparse;

   procedure Check_Invalid_Sparse_Inputs is
   begin
      Raise_On_Error
        (Probe_Sparse_Invalid_Inputs,
         "module bridge sparse invalid-input probe");
   end Check_Invalid_Sparse_Inputs;

end Module_Bridge_Probe;
