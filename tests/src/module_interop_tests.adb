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
   use type Interfaces.Integer_32;
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

   package Bridge renames OpenCV.Core.Module_Interop;
   package Probe renames Module_Bridge_Probe;
   use type Interfaces.IEEE_Float_64;

   function Observe (Image : OpenCV.Core.UMat) return Probe.UMat_Observation is
      Observation : aliased Probe.UMat_Observation;
      procedure Inspect (Handle : Bridge.Input_UMat_Handle) is
      begin
         AUnit.Assertions.Assert
           (Probe.Inspect_UMat (Handle, Observation'Access) = 0,
            "native UMat observation succeeds");
      end Inspect;
   begin
      Bridge.With_Input_Handle (Image, Inspect'Access);
      return Observation;
   end Observe;

   procedure UMat_Region_Input (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      Parent : UMat := Create_UMat (4, 5, (Float32, 1));
   begin
      Parent.Set_To (OpenCV.Make_Scalar (3.0));
      declare
         View : constant UMat := Parent.Region ((1, 1, 2, 2));
         O    : constant Probe.UMat_Observation := Observe (View);
      begin
         AUnit.Assertions.Assert
           (O.Dims = 2
            and then O.Rows = 2
            and then O.Columns = 2
            and then O.Depth = 5
            and then O.Channels = 1
            and then O.Continuous = 0
            and then O.Submatrix = 1
            and then O.Sum = 12.0,
            "borrow original non-contiguous UMat Region");
      end;
      AUnit.Assertions.Assert (Observe (Parent).Sum = 60.0, "input unchanged");
   end UMat_Region_Input;

   procedure UMat_Five_Dimensional_Pair (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      Shape : constant Dimension_Array := (2, 3, 2, 4, 2);
      Left  : UMat := Create_UMat (Shape, (Float32, 1));
      Right : UMat := Create_UMat (Shape, (Float32, 1));
      A, B  : aliased Probe.UMat_Observation;
      procedure Borrow_Left (L : Bridge.Input_UMat_Handle) is
         procedure Borrow_Right (R : Bridge.Input_UMat_Handle) is
         begin
            AUnit.Assertions.Assert
              (Probe.Inspect_UMat_Pair (L, R, A'Access, B'Access) = 0,
               "two distinct native headers borrowed simultaneously");
         end Borrow_Right;
      begin
         Bridge.With_Input_Handle (Right, Borrow_Right'Access);
      end Borrow_Left;
   begin
      Left.Set_To (OpenCV.Make_Scalar (2.0));
      Right.Set_To (OpenCV.Make_Scalar (5.0));
      Bridge.With_Input_Handle (Left, Borrow_Left'Access);
      AUnit.Assertions.Assert
        (A.Dims = 5
         and then B.Dims = 5
         and then A.Depth = 5
         and then B.Depth = 5
         and then A.Channels = 1
         and then B.Channels = 1
         and then A.Sum = 192.0
         and then B.Sum = 480.0,
         "independent genuine 5-D UMat contents");
      for Axis in Shape'Range loop
         AUnit.Assertions.Assert
           (A.Extents (Axis) = Interfaces.Integer_32 (Shape (Axis))
            and then B.Extents (Axis) = Interfaces.Integer_32 (Shape (Axis)),
            "every native extent preserved");
      end loop;
      AUnit.Assertions.Assert
        (Observe (Left).Sum = 192.0 and then Observe (Right).Sum = 480.0,
         "both inputs remain usable and unchanged after callbacks");
   end UMat_Five_Dimensional_Pair;

   procedure UMat_Output_Mutation (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      Image : UMat := Create_UMat (2, 3, (Float32, 1));
      procedure Mutate (Handle : Bridge.Output_UMat_Handle) is
      begin
         AUnit.Assertions.Assert
           (Probe.Mutate_UMat (Handle, 9.0) = 0, "native storage mutation");
      end Mutate;
   begin
      Image.Set_To (OpenCV.Make_Scalar (2.0));
      declare
         Alias : constant UMat := Image;
         Copy  : constant UMat := Image.Clone;
      begin
         Bridge.With_Output_Handle (Image, Mutate'Access);
         AUnit.Assertions.Assert
           (Observe (Image).Sum = 54.0
            and then Observe (Alias).Sum = 54.0
            and then Observe (Copy).Sum = 12.0,
            "shallow alias shares mutation; Clone remains independent");
      end;
   end UMat_Output_Mutation;

   procedure UMat_Output_Rebinding (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      Destination : UMat;
      procedure Recreate (Handle : Bridge.Output_UMat_Handle) is
      begin
         AUnit.Assertions.Assert
           (Probe.Create_UMat (Handle) = 0, "create actual output header");
      end Recreate;
   begin
      Bridge.With_Output_Handle (Destination, Recreate'Access);
      AUnit.Assertions.Assert
        (Destination.Rows = 3
         and then Destination.Columns = 4
         and then Destination.Depth = Float32
         and then Destination.Channels = 3
         and then Observe (Destination).Sum = 84.0,
         "Core observes created header and values");
      --  Recreate again from incompatible non-empty metadata.
      Destination := Create_UMat (1, 1, (UInt8, 1));
      Bridge.With_Output_Handle (Destination, Recreate'Access);
      AUnit.Assertions.Assert
        (Destination.Rows = 3
         and then Destination.Columns = 4
         and then Destination.Depth = Float32
         and then Destination.Channels = 3
         and then Observe (Destination).Sum = 84.0,
         "Core observes non-empty header rebinding");
   end UMat_Output_Rebinding;

   procedure UMat_Region_Output (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      Parent : UMat := Create_UMat (4, 5, (Float32, 1));
      procedure Mutate (Handle : Bridge.Output_UMat_Handle) is
      begin
         AUnit.Assertions.Assert
           (Probe.Mutate_UMat (Handle, 8.0) = 0, "Region output is accepted");
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Make_Scalar (1.0));
      declare
         View : UMat := Parent.Region ((1, 1, 2, 2));
      begin
         Bridge.With_Output_Handle (View, Mutate'Access);
         AUnit.Assertions.Assert (Observe (View).Sum = 32.0, "Region changed");
      end;
      for Row in 0 .. 3 loop
         for Column in 0 .. 4 loop
            declare
               Pixel    : constant UMat :=
                 Parent.Region
                   ((OpenCV.Point_Coordinate (Column),
                     OpenCV.Point_Coordinate (Row),
                     1,
                     1));
               Expected : constant Interfaces.IEEE_Float_64 :=
                 (if Row in 1 .. 2 and then Column in 1 .. 2
                  then 8.0
                  else 1.0);
            begin
               AUnit.Assertions.Assert
                 (Observe (Pixel).Sum = Expected,
                  "only corresponding parent pixels change");
            end;
         end loop;
      end loop;
   end UMat_Region_Output;

   procedure UMat_View_Lifetime (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      View : UMat;
   begin
      declare
         Parent : UMat := Create_UMat (4, 5, (Float32, 1));
      begin
         Parent.Set_To (OpenCV.Make_Scalar (6.0));
         View := Parent.Region ((1, 1, 2, 2));
      end;
      declare
         O : constant Probe.UMat_Observation := Observe (View);
      begin
         AUnit.Assertions.Assert
           (O.Sum = 24.0 and then O.Submatrix = 1 and then O.Continuous = 0,
            "Region allocation survives parent finalization");
      end;
   end UMat_View_Lifetime;

   procedure UMat_Empty_And_Failures (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      Default : UMat;
      Typed   : constant UMat := Create_UMat (0, 0, (Float32, 3));
      D       : constant Probe.UMat_Observation := Observe (Default);
      T       : constant Probe.UMat_Observation := Observe (Typed);
      procedure Invalid (Handle : Bridge.Output_UMat_Handle) is
      begin
         AUnit.Assertions.Assert
           (Probe.Invalid_UMat (Handle) = 0,
            "resolver failures publish no pointers");
      end Invalid;
   begin
      AUnit.Assertions.Assert
        (D.Dims = 0
         and then D.Depth = 0
         and then D.Channels = 1
         and then D.Sum = 0.0,
         "default-empty header is valid input");
      AUnit.Assertions.Assert
        (T.Dims = 2
         and then T.Rows = 0
         and then T.Columns = 0
         and then T.Depth = 5
         and then T.Channels = 3
         and then T.Sum = 0.0,
         "typed-empty header metadata is preserved, not reconstructed");
      Bridge.With_Output_Handle (Default, Invalid'Access);
   end UMat_Empty_And_Failures;

   procedure UMat_Callback_Exceptions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image          : OpenCV.Core.UMat;
      Callback_Error : exception;
      procedure Input (Handle : Bridge.Input_UMat_Handle) is
         pragma Unreferenced (Handle);
      begin
         raise Callback_Error with "input callback";
      end Input;
      procedure Output (Handle : Bridge.Output_UMat_Handle) is
         pragma Unreferenced (Handle);
      begin
         raise Callback_Error with "output callback";
      end Output;
   begin
      begin
         Bridge.With_Input_Handle (Image, Input'Access);
         AUnit.Assertions.Assert (False, "input exception must propagate");
      exception
         when Callback_Error =>
            null;
      end;
      begin
         Bridge.With_Output_Handle (Image, Output'Access);
         AUnit.Assertions.Assert (False, "output exception must propagate");
      exception
         when Callback_Error =>
            null;
      end;
   end UMat_Callback_Exceptions;

   procedure UMat_Module_Operation (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      Image       : UMat := Create_UMat (2, 3, (Float32, 1));
      Destination : UMat;
      function Use_OpenCL return Interfaces.Unsigned_8
      with Import, Convention => C, External_Name => "umat_probe_use_opencl";
      function Set_OpenCL
        (Enabled : Interfaces.Unsigned_8) return Interfaces.Unsigned_8
      with Import, Convention => C, External_Name => "umat_probe_set_opencl";
      Previous    : constant Interfaces.Unsigned_8 := Use_OpenCL;
      Ignored     : Interfaces.Unsigned_8;
      procedure Input (Handle : Bridge.Input_UMat_Handle) is
         procedure Output (Target : Bridge.Output_UMat_Handle) is
         begin
            AUnit.Assertions.Assert
              (Probe.Add_UMat (Handle, Target) = 0,
               "native InputArray to OutputArray add");
         end Output;
      begin
         Bridge.With_Output_Handle (Destination, Output'Access);
      end Input;
   begin
      Image.Set_To (OpenCV.Make_Scalar (4.0));
      Ignored := Set_OpenCL (0);
      AUnit.Assertions.Assert
        (Ignored = 1 and then Use_OpenCL = 0, "disable OpenCL successfully");
      Bridge.With_Input_Handle (Image, Input'Access);
      AUnit.Assertions.Assert
        (Destination.Rows = 2
         and then Destination.Columns = 3
         and then Destination.Depth = Float32
         and then Destination.Channels = 1
         and then Observe (Destination).Sum = 48.0
         and then Observe (Image).Sum = 24.0,
         "public UMat result correct without OpenCL or Mat transfers");
      Ignored := Set_OpenCL (Previous);
      AUnit.Assertions.Assert (Ignored = 1, "restore OpenCL successfully");
   exception
      when others =>
         Ignored := Set_OpenCL (Previous);
         raise;
   end UMat_Module_Operation;

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
      Result.Add_Test
        (Caller.Create
           ("UMat module non-contiguous input", UMat_Region_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat module simultaneous 5-D inputs",
            UMat_Five_Dimensional_Pair'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat module alias and Clone mutation",
            UMat_Output_Mutation'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat module actual output header rebinding",
            UMat_Output_Rebinding'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat module Region output", UMat_Region_Output'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat module view outlives parent", UMat_View_Lifetime'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat module empty headers and invalid resolvers",
            UMat_Empty_And_Failures'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat module callback exceptions",
            UMat_Callback_Exceptions'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat module Transparent API without OpenCL",
            UMat_Module_Operation'Access));
      return Result'Access;
   end Suite;

end Module_Interop_Tests;
