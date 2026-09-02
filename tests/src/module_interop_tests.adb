with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;

package body Module_Interop_Tests is

   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure Input_Probe_Observes_Original_And_Noncontiguous_Mat
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      Region : constant OpenCV.Core.Mat :=
        Source.Region ((X => 0, Y => 0, Width => 1, Height => 3));
      Seen   : Module_Bridge_Probe.Input_Observation;

      procedure Inspect (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
      begin
         Module_Bridge_Probe.Inspect (Handle, Seen);
      end Inspect;
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 41);
      OpenCV.Core.Module_Interop.With_Input_Handle (Region, Inspect'Access);
      AUnit.Assertions.Assert
        (Seen.Rows = 3
         and then Seen.Columns = 1
         and then Seen.Depth = 0
         and then Seen.Value = 41
         and then not Region.Is_Continuous,
         "module input probe must receive the original non-contiguous Mat");
   end Input_Probe_Observes_Original_And_Noncontiguous_Mat;

   procedure Input_Callback_Exception_Propagates (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Invoked : Boolean := False;

      procedure Raise_From_Callback
        (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         pragma Unreferenced (Handle);
      begin
         Invoked := True;
         raise Constraint_Error;
      end Raise_From_Callback;

      procedure Attempt is
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle
           (Image, Raise_From_Callback'Access);
      end Attempt;
   begin
      begin
         Attempt;
         AUnit.Assertions.Assert (False, "callback exception must propagate");
      exception
         when Constraint_Error =>
            null;
      end;
      AUnit.Assertions.Assert (Invoked, "input callback must have run");
   end Input_Callback_Exception_Propagates;

   procedure Output_Mutation_Shares_And_Clone_Remains_Independent
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 0, 0, 23);
      declare
         Alias : constant OpenCV.Core.Mat := Image;
         Copy  : constant OpenCV.Core.Mat := Image.Clone;

         procedure Mutate
           (Handle : OpenCV.Core.Module_Interop.Output_Mat_Handle) is
         begin
            Module_Bridge_Probe.Mutate (Handle, 77);
         end Mutate;
      begin
         OpenCV.Core.Module_Interop.With_Output_Handle (Image, Mutate'Access);
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Access.Get (Image, 0, 0) = 77
            and then OpenCV.Core.UInt8_Access.Get (Alias, 0, 0) = 77
            and then OpenCV.Core.UInt8_Access.Get (Copy, 0, 0) = 23,
            "output mutation must share ordinary aliases but not Clone "
            & "storage");
      end;
   end Output_Mutation_Shares_And_Clone_Remains_Independent;

   procedure Output_Probe_Rebinds_Actual_Core_Header (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Destination : OpenCV.Core.Mat;

      procedure Allocate
        (Handle : OpenCV.Core.Module_Interop.Output_Mat_Handle) is
      begin
         Module_Bridge_Probe.Create (Handle, 2, 3, 91);
      end Allocate;
   begin
      OpenCV.Core.Module_Interop.With_Output_Handle
        (Destination, Allocate'Access);
      AUnit.Assertions.Assert
        (Destination.Rows = 2
         and then Destination.Columns = 3
         and then Destination.Depth = OpenCV.Core.UInt8
         and then Destination.Channels = 1
         and then OpenCV.Core.UInt8_Access.Get (Destination, 1, 2) = 91,
         "output probe must rebind the actual Core-owned Mat header");
   end Output_Probe_Rebinds_Actual_Core_Header;

   procedure External_View_Is_Input_Only (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data           : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (1, 2, 3, 4);
      Input_Invoked  : Boolean := False;
      Output_Invoked : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is
         Seen : Module_Bridge_Probe.Input_Observation;

         procedure Inspect
           (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         begin
            Module_Bridge_Probe.Inspect (Handle, Seen);
            Input_Invoked := True;
         end Inspect;

         procedure Output
           (Handle : OpenCV.Core.Module_Interop.Output_Mat_Handle) is
         begin
            pragma Unreferenced (Handle);
            Output_Invoked := True;
         end Output;

         procedure Attempt_Output is
         begin
            OpenCV.Core.Module_Interop.With_Output_Handle
              (Image, Output'Access);
         end Attempt_Output;
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle (Image, Inspect'Access);
         Assert_Raises_OpenCV_Error
           (Attempt_Output'Access,
            "external views must reject output handles");
         AUnit.Assertions.Assert
           (Seen.Value = 1 and then Input_Invoked and then not Output_Invoked,
            "external view input must work and rejected output must not run");
      end Process;
   begin
      OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
        (Data, 2, 2, Process'Access);
   end External_View_Is_Input_Only;

   procedure Invalid_Resolver_Inputs_Are_Rejected (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Module_Bridge_Probe.Check_Invalid_Inputs;
   end Invalid_Resolver_Inputs_Are_Rejected;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Module input bridge observes original non-contiguous Mat",
            Input_Probe_Observes_Original_And_Noncontiguous_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("Module input callback exceptions propagate",
            Input_Callback_Exception_Propagates'Access));
      Result.Add_Test
        (Caller.Create
           ("Module output mutation shares and Clone isolates",
            Output_Mutation_Shares_And_Clone_Remains_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Module output bridge rebinds Core Mat header",
            Output_Probe_Rebinds_Actual_Core_Header'Access));
      Result.Add_Test
        (Caller.Create
           ("External Mat view is module input only",
            External_View_Is_Input_Only'Access));
      Result.Add_Test
        (Caller.Create
           ("Module resolver rejects invalid native inputs",
            Invalid_Resolver_Inputs_Are_Rejected'Access));
      return Result'Access;
   end Suite;

end Module_Interop_Tests;
