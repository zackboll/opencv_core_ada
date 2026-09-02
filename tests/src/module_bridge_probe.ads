with Interfaces;
with OpenCV.Core.Module_Interop;

package Module_Bridge_Probe is

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

end Module_Bridge_Probe;
