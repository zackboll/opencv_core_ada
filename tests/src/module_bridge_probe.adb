with Ada.Exceptions;
with Interfaces.C;

package body Module_Bridge_Probe is

   subtype C_Int32 is Interfaces.C.int;
   subtype C_UInt8 is Interfaces.C.unsigned_char;

   use type C_Int32;

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

   procedure Raise_On_Error (Status : C_Int32; Operation : String) is
   begin
      if Status /= 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV.OpenCV_Error'Identity, Operation & " failed");
      end if;
   end Raise_On_Error;

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

end Module_Bridge_Probe;
