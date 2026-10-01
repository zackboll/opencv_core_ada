with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Core.Sparse;
with OpenCV.Core.Sparse.Float32_Access;
with OpenCV.Core.Sparse.Module_Interop;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;

package body Module_Interop_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Dimension_Array;
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Size_Coordinate;
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

   procedure Sparse_Input_Observes_Stored_Node (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Shape    : constant OpenCV.Core.Dimension_Array := (2, 3, 2, 4, 2);
      Location : constant OpenCV.Core.Index_Array := (1, 2, 0, 3, 1);
      Image    : OpenCV.Core.Sparse.Sparse_Mat :=
        OpenCV.Core.Sparse.Create (Shape, (OpenCV.Core.Float32, 1));
      Seen     : Module_Bridge_Probe.Sparse_Input_Observation;

      procedure Inspect
        (Handle : OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle) is
      begin
         Module_Bridge_Probe.Inspect_Sparse (Handle, Location, Seen);
      end Inspect;
   begin
      OpenCV.Core.Sparse.Float32_Access.Set (Image, Location, 41.0);
      OpenCV.Core.Sparse.Module_Interop.With_Input_Handle
        (Image, Inspect'Access);
      AUnit.Assertions.Assert
        (Seen.Dimensions = 5
         and then Seen.Extents (1 .. 5) = Shape
         and then Seen.Depth = 5
         and then Seen.Channels = 1
         and then Seen.Nodes = 1
         and then Seen.Value = 41,
         "sparse module input probe must observe the original 5-D header");
   end Sparse_Input_Observes_Stored_Node;

   procedure Sparse_Inputs_Can_Be_Borrowed_Together (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Shape          : constant OpenCV.Core.Dimension_Array := (2, 3, 2, 4, 2);
      Left_Location  : constant OpenCV.Core.Index_Array := (1, 2, 0, 3, 1);
      Right_Location : constant OpenCV.Core.Index_Array := (0, 1, 1, 2, 0);
      Left           : OpenCV.Core.Sparse.Sparse_Mat :=
        OpenCV.Core.Sparse.Create (Shape, (OpenCV.Core.Float32, 1));
      Right          : OpenCV.Core.Sparse.Sparse_Mat :=
        OpenCV.Core.Sparse.Create (Shape, (OpenCV.Core.Float32, 1));
      Seen_Left      : Module_Bridge_Probe.Sparse_Input_Observation;
      Seen_Right     : Module_Bridge_Probe.Sparse_Input_Observation;

      procedure Inspect_Left
        (Left_Handle :
           OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle)
      is
         procedure Nested
           (Right_Handle :
              OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle) is
         begin
            Module_Bridge_Probe.Inspect_Sparse_Pair
              (Left_Handle,
               Right_Handle,
               Left_Location,
               Right_Location,
               Seen_Left,
               Seen_Right);
         end Nested;
      begin
         OpenCV.Core.Sparse.Module_Interop.With_Input_Handle
           (Right, Nested'Access);
      end Inspect_Left;
   begin
      OpenCV.Core.Sparse.Float32_Access.Set (Left, Left_Location, 41.0);
      OpenCV.Core.Sparse.Float32_Access.Set (Right, Right_Location, 17.0);
      OpenCV.Core.Sparse.Module_Interop.With_Input_Handle
        (Left, Inspect_Left'Access);
      AUnit.Assertions.Assert
        (Seen_Left.Dimensions = 5
         and then Seen_Left.Extents (1 .. 5) = Shape
         and then Seen_Left.Depth = 5
         and then Seen_Left.Channels = 1
         and then Seen_Left.Nodes = 1
         and then Seen_Left.Value = 41
         and then Seen_Right.Dimensions = 5
         and then Seen_Right.Extents (1 .. 5) = Shape
         and then Seen_Right.Depth = 5
         and then Seen_Right.Channels = 1
         and then Seen_Right.Nodes = 1
         and then Seen_Right.Value = 17
         and then OpenCV.Core.Sparse.Float32_Access.Get (Left, Left_Location)
                  = 41.0
         and then OpenCV.Core.Sparse.Float32_Access.Get (Right, Right_Location)
                  = 17.0
         and then Left.Stored_Element_Count = 1
         and then Right.Stored_Element_Count = 1,
         "two borrowed sparse headers must remain distinct and unchanged");
   end Sparse_Inputs_Can_Be_Borrowed_Together;

   procedure Sparse_Input_Callback_Exception_Propagates (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image   : constant OpenCV.Core.Sparse.Sparse_Mat :=
        OpenCV.Core.Sparse.Create ((2, 2), (OpenCV.Core.Float32, 1));
      Invoked : Boolean := False;

      procedure Raise_From_Callback
        (Handle : OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle)
      is
         pragma Unreferenced (Handle);
      begin
         Invoked := True;
         raise Constraint_Error;
      end Raise_From_Callback;

      procedure Attempt is
      begin
         OpenCV.Core.Sparse.Module_Interop.With_Input_Handle
           (Image, Raise_From_Callback'Access);
      end Attempt;
   begin
      begin
         Attempt;
         AUnit.Assertions.Assert
           (False, "sparse callback exception must propagate");
      exception
         when Constraint_Error =>
            null;
      end;
      AUnit.Assertions.Assert (Invoked, "sparse input callback must have run");
   end Sparse_Input_Callback_Exception_Propagates;

   procedure Sparse_Output_Mutation_Shares_And_Clone_Is_Independent
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Sparse.Sparse_Mat :=
        OpenCV.Core.Sparse.Create ((2, 3), (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.Sparse.Float32_Access.Set (Image, (0, 1), 23.0);
      declare
         Alias : constant OpenCV.Core.Sparse.Sparse_Mat := Image;
         Copy  : constant OpenCV.Core.Sparse.Sparse_Mat := Image.Clone;

         procedure Mutate
           (Handle :
              OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle) is
         begin
            Module_Bridge_Probe.Mutate_Sparse (Handle, 77.0);
         end Mutate;
      begin
         OpenCV.Core.Sparse.Module_Interop.With_Output_Handle
           (Image, Mutate'Access);
         AUnit.Assertions.Assert
           (OpenCV.Core.Sparse.Float32_Access.Get (Image, (0, 1)) = 77.0
            and then OpenCV.Core.Sparse.Float32_Access.Get (Alias, (0, 1))
                     = 77.0
            and then OpenCV.Core.Sparse.Float32_Access.Get (Copy, (0, 1))
                     = 23.0
            and then Image.Stored_Element_Count = 1
            and then Copy.Stored_Element_Count = 1,
            "sparse output mutation shares aliases but not Clone");
      end;
   end Sparse_Output_Mutation_Shares_And_Clone_Is_Independent;

   procedure Sparse_Output_Create_Rebinds_Actual_Core_Header
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Destination : OpenCV.Core.Sparse.Sparse_Mat;

      procedure Allocate
        (Handle : OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle)
      is
      begin
         Module_Bridge_Probe.Create_Sparse (Handle, 3, 4, 91.0);
      end Allocate;
   begin
      AUnit.Assertions.Assert
        (not Destination.Is_Allocated,
         "default Sparse_Mat starts unallocated");
      OpenCV.Core.Sparse.Module_Interop.With_Output_Handle
        (Destination, Allocate'Access);
      AUnit.Assertions.Assert
        (Destination.Is_Allocated
         and then Destination.Dimension_Count = 2
         and then Destination.Extent (1) = 3
         and then Destination.Extent (2) = 4
         and then Destination.Depth = OpenCV.Core.Float32
         and then Destination.Channels = 1
         and then Destination.Stored_Element_Count = 1
         and then OpenCV.Core.Sparse.Float32_Access.Get (Destination, (0, 1))
                  = 91.0,
         "sparse output probe must recreate the actual Core-owned header");
   end Sparse_Output_Create_Rebinds_Actual_Core_Header;

   procedure Sparse_Invalid_Resolver_Inputs_Are_Rejected
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
   begin
      Module_Bridge_Probe.Check_Invalid_Sparse_Inputs;
   end Sparse_Invalid_Resolver_Inputs_Are_Rejected;

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
      Result.Add_Test
        (Caller.Create
           ("Sparse module input bridge observes original 5-D header",
            Sparse_Input_Observes_Stored_Node'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse module input bridge borrows two headers together",
            Sparse_Inputs_Can_Be_Borrowed_Together'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse module input callback exceptions propagate",
            Sparse_Input_Callback_Exception_Propagates'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse module output mutation shares and Clone isolates",
            Sparse_Output_Mutation_Shares_And_Clone_Is_Independent'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse module output bridge recreates Core header",
            Sparse_Output_Create_Rebinds_Actual_Core_Header'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse module resolver rejects invalid native inputs",
            Sparse_Invalid_Resolver_Inputs_Are_Rejected'Access));
      return Result'Access;
   end Suite;

end Module_Interop_Tests;
