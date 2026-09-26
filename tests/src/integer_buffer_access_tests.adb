with Ada.Exceptions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Integer_Borrow_Lifetime_Probe;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Int16_Buffer_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Int32_Buffer_Access;
with OpenCV.Core.UInt16_Access;
with OpenCV.Core.UInt16_Buffer_Access;

package body Integer_Buffer_Access_Tests is

   use type Ada.Exceptions.Exception_Id;
   use type OpenCV.Int16_Value;
   use type OpenCV.Int32_Value;
   use type OpenCV.UInt16_Value;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Core.UInt16_Buffer_Access.Buffer_Array;
   use Mat_Test_Support;

   procedure Assert_Target_Attached is
   begin
      AUnit.Assertions.Assert
        (Integer_Borrow_Lifetime_Probe.Target_Captured
         and then Integer_Borrow_Lifetime_Probe.Target_Live
         and then Integer_Borrow_Lifetime_Probe.Deallocation_Count = 0
         and then Integer_Borrow_Lifetime_Probe.Target_Size > 0,
         "The original OpenCV allocation must be the observed target");
   end Assert_Target_Attached;

   procedure Assert_Target_Still_Leased is
   begin
      AUnit.Assertions.Assert
        (Integer_Borrow_Lifetime_Probe.Target_Live
         and then Integer_Borrow_Lifetime_Probe.Deallocation_Count = 0,
         "The borrow lease must keep the original allocation live");
   end Assert_Target_Still_Leased;

   procedure Assert_Target_Released_Once is
   begin
      AUnit.Assertions.Assert
        (not Integer_Borrow_Lifetime_Probe.Target_Live
         and then Integer_Borrow_Lifetime_Probe.Deallocation_Count = 1,
         "The original allocation must be deallocated exactly once");
   end Assert_Target_Released_Once;

   Probe_Cleanup_Error : exception;

   Observation_Cleanup_Fails : Boolean := False;

   procedure Finish_Started_Observation (Started : in out Boolean) is
   begin
      if Started then
         if Observation_Cleanup_Fails then
            raise Probe_Cleanup_Error
              with "deliberate observation cleanup failure";
         end if;
         Integer_Borrow_Lifetime_Probe.Finish;
         Started := False;
      end if;
   end Finish_Started_Observation;

   procedure Cleanup_Started_Observation
     (Started : in out Boolean; Original : Ada.Exceptions.Exception_Occurrence)
   is
   begin
      if Started then
         begin
            Finish_Started_Observation (Started);
         exception
            when others =>
               --  A failing Finish must not replace the exception already
               --  being handled, and it must not be attempted again.
               Started := False;
         end;
      end if;
      Ada.Exceptions.Reraise_Occurrence (Original);
   end Cleanup_Started_Observation;

   Callback_Error : exception;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure Exact_Values_And_Zero_Based_Row_Major_Extents
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U16 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 1));
      I16 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int16, 1));
      I32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int32, 1));

      procedure Mutate_U16
        (Data : aliased in out OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5,
            "UInt16 borrowed buffer must be zero-based");
         Data := (0, 32_767, 32_768, 65_534, 65_535, 1);
      end Mutate_U16;
      procedure Mutate_I16
        (Data : aliased in out OpenCV.Core.Int16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5,
            "Int16 borrowed buffer must be zero-based");
         Data :=
           (OpenCV.Int16_Value'First, -1, 0, 1, OpenCV.Int16_Value'Last, -7);
      end Mutate_I16;
      procedure Mutate_I32
        (Data : aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5,
            "Int32 borrowed buffer must be zero-based");
         Data :=
           (OpenCV.Int32_Value'First,
            -1,
            0,
            16_777_217,
            OpenCV.Int32_Value'Last,
            9);
      end Mutate_I32;
   begin
      OpenCV.Core.UInt16_Buffer_Access.With_Writable_Buffer
        (U16, Mutate_U16'Access);
      OpenCV.Core.Int16_Buffer_Access.With_Writable_Buffer
        (I16, Mutate_I16'Access);
      OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
        (I32, Mutate_I32'Access);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Access.Get (U16, 0, 2) = 32_768
         and then OpenCV.Core.UInt16_Access.Get (U16, 1, 1) = 65_535,
         "UInt16 buffer writes must preserve the signed boundary and"
         & " endpoint");
      AUnit.Assertions.Assert
        (OpenCV.Core.Int16_Access.Get (I16, 0, 0) = OpenCV.Int16_Value'First
         and then OpenCV.Core.Int16_Access.Get (I16, 1, 1)
                  = OpenCV.Int16_Value'Last,
         "Int16 buffer writes must preserve signed endpoints");
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (I32, 0, 0) = OpenCV.Int32_Value'First
         and then OpenCV.Core.Int32_Access.Get (I32, 1, 0) = 16_777_217
         and then OpenCV.Core.Int32_Access.Get (I32, 1, 1)
                  = OpenCV.Int32_Value'Last,
         "Int32 buffer writes must avoid floating-point intermediates");
   end Exact_Values_And_Zero_Based_Row_Major_Extents;

   procedure Continuous_Regions_Are_Accepted_And_Strided_Regions_Rejected
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U_Parent  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.UInt16, 1));
      I_Parent  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Int16, 1));
      L_Parent  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Int32, 1));
      U_Cont    : OpenCV.Core.Mat :=
        U_Parent.Region ((X => 0, Y => 1, Width => 5, Height => 2));
      I_Cont    : OpenCV.Core.Mat :=
        I_Parent.Region ((X => 0, Y => 1, Width => 5, Height => 2));
      L_Cont    : OpenCV.Core.Mat :=
        L_Parent.Region ((X => 0, Y => 1, Width => 5, Height => 2));
      U_Strided : constant OpenCV.Core.Mat :=
        U_Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      I_Strided : constant OpenCV.Core.Mat :=
        I_Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      L_Strided : constant OpenCV.Core.Mat :=
        L_Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Invoked   : Boolean := False;

      procedure Write_U
        (Data : aliased in out OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
      is
      begin
         Data (0) := 65_535;
         Data (9) := 32_768;
      end Write_U;
      procedure Write_I
        (Data : aliased in out OpenCV.Core.Int16_Buffer_Access.Buffer_Array) is
      begin
         Data (0) := OpenCV.Int16_Value'First;
         Data (9) := OpenCV.Int16_Value'Last;
      end Write_I;
      procedure Write_L
        (Data : aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         Data (0) := 16_777_217;
         Data (9) := OpenCV.Int32_Value'Last;
      end Write_L;
      procedure Mark_U
        (Data : aliased OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_U;
      procedure Mark_I
        (Data : aliased OpenCV.Core.Int16_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_I;
      procedure Mark_L
        (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_L;
      procedure Borrow_U is
      begin
         OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
           (U_Strided, Mark_U'Access);
      end Borrow_U;
      procedure Borrow_I is
      begin
         OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
           (I_Strided, Mark_I'Access);
      end Borrow_I;
      procedure Borrow_L is
      begin
         OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
           (L_Strided, Mark_L'Access);
      end Borrow_L;
   begin
      OpenCV.Core.UInt16_Buffer_Access.With_Writable_Buffer
        (U_Cont, Write_U'Access);
      OpenCV.Core.Int16_Buffer_Access.With_Writable_Buffer
        (I_Cont, Write_I'Access);
      OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
        (L_Cont, Write_L'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Access.Get (U_Parent, 1, 0) = 65_535
         and then OpenCV.Core.Int16_Access.Get (I_Parent, 2, 4)
                  = OpenCV.Int16_Value'Last
         and then OpenCV.Core.Int32_Access.Get (L_Parent, 1, 0) = 16_777_217,
         "Continuous Region buffers must share parent storage"
         & " immediately");
      Assert_Raises_OpenCV_Error (Borrow_U'Access, "UInt16 strided Region");
      Assert_Raises_OpenCV_Error (Borrow_I'Access, "Int16 strided Region");
      Assert_Raises_OpenCV_Error (Borrow_L'Access, "Int32 strided Region");
      AUnit.Assertions.Assert
        (not Invoked,
         "Non-contiguous buffer rejection must suppress callbacks");
   end Continuous_Regions_Are_Accepted_And_Strided_Regions_Rejected;

   procedure Empty_Type_And_Dimension_Validation_Covers_All_Families
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U_Empty         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt16, 1));
      I_Empty         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Int16, 1));
      L_Empty         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Int32, 1));
      Wrong           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      U_Multi         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt16, 2));
      I_Multi         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int16, 2));
      L_Multi         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 2));
      --  Continuous N-D Mats are accepted; a gapped N-D Slice is not.
      U_N_D           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 2, 2), Element_Type => (OpenCV.Core.UInt16, 1))
          .Slice (((0, 2), (1, 2), (0, 2)));
      I_N_D           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 2, 2), Element_Type => (OpenCV.Core.Int16, 1))
          .Slice (((0, 2), (1, 2), (0, 2)));
      L_N_D           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 2, 2), Element_Type => (OpenCV.Core.Int32, 1))
          .Slice (((0, 2), (1, 2), (0, 2)));
      Empty_Count     : Natural := 0;
      Invalid_Invoked : Boolean := False;

      procedure Empty_U
        (Data : aliased OpenCV.Core.UInt16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 1 and then Data'Last = 0 and then Data'Length = 0,
            "Empty UInt16 read-only buffer uses the 1 .. 0 null range");
         Empty_Count := Empty_Count + 1;
      end Empty_U;
      procedure Empty_I
        (Data : aliased OpenCV.Core.Int16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 1 and then Data'Last = 0 and then Data'Length = 0,
            "Empty Int16 read-only buffer uses the 1 .. 0 null range");
         Empty_Count := Empty_Count + 1;
      end Empty_I;
      procedure Empty_L
        (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 1 and then Data'Last = 0 and then Data'Length = 0,
            "Empty Int32 read-only buffer uses the 1 .. 0 null range");
         Empty_Count := Empty_Count + 1;
      end Empty_L;
      procedure Mark_L
        (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invalid_Invoked := True;
      end Mark_L;
      procedure Mark_U
        (Data : aliased OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invalid_Invoked := True;
      end Mark_U;
      procedure Mark_I
        (Data : aliased OpenCV.Core.Int16_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invalid_Invoked := True;
      end Mark_I;
      procedure U_Wrong_Depth is
      begin
         OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
           (Wrong, Mark_U'Access);
      end U_Wrong_Depth;
      procedure I_Wrong_Depth is
      begin
         OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
           (Wrong, Mark_I'Access);
      end I_Wrong_Depth;
      procedure L_Wrong_Depth is
      begin
         OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
           (Wrong, Mark_L'Access);
      end L_Wrong_Depth;
      procedure U_Wrong_Channels is
      begin
         OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
           (U_Multi, Mark_U'Access);
      end U_Wrong_Channels;
      procedure I_Wrong_Channels is
      begin
         OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
           (I_Multi, Mark_I'Access);
      end I_Wrong_Channels;
      procedure L_Wrong_Channels is
      begin
         OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
           (L_Multi, Mark_L'Access);
      end L_Wrong_Channels;
      procedure U_Wrong_Dimensions is
      begin
         OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
           (U_N_D, Mark_U'Access);
      end U_Wrong_Dimensions;
      procedure I_Wrong_Dimensions is
      begin
         OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
           (I_N_D, Mark_I'Access);
      end I_Wrong_Dimensions;
      procedure L_Wrong_Dimensions is
      begin
         OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
           (L_N_D, Mark_L'Access);
      end L_Wrong_Dimensions;
   begin
      OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
        (U_Empty, Empty_U'Access);
      OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
        (I_Empty, Empty_I'Access);
      OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
        (L_Empty, Empty_L'Access);
      AUnit.Assertions.Assert
        (Empty_Count = 3,
         "Each typed empty integer buffer must invoke callback");
      Assert_Raises_OpenCV_Error (U_Wrong_Depth'Access, "wrong UInt16 depth");
      Assert_Raises_OpenCV_Error (I_Wrong_Depth'Access, "wrong Int16 depth");
      Assert_Raises_OpenCV_Error (L_Wrong_Depth'Access, "wrong Int32 depth");
      Assert_Raises_OpenCV_Error (U_Wrong_Channels'Access, "UInt16 C2 buffer");
      Assert_Raises_OpenCV_Error (I_Wrong_Channels'Access, "Int16 C2 buffer");
      Assert_Raises_OpenCV_Error (L_Wrong_Channels'Access, "Int32 C2 buffer");
      AUnit.Assertions.Assert
        (not U_N_D.Is_Continuous
         and then not I_N_D.Is_Continuous
         and then not L_N_D.Is_Continuous,
         "The integer N-D Slice fixtures must be non-continuous");
      Assert_Raises_OpenCV_Error
        (U_Wrong_Dimensions'Access, "UInt16 gapped N-D Slice");
      Assert_Raises_OpenCV_Error
        (I_Wrong_Dimensions'Access, "Int16 gapped N-D Slice");
      Assert_Raises_OpenCV_Error
        (L_Wrong_Dimensions'Access, "Int32 gapped N-D Slice");
      AUnit.Assertions.Assert
        (not Invalid_Invoked,
         "Invalid integer buffers must suppress callback");
   end Empty_Type_And_Dimension_Validation_Covers_All_Families;

   procedure Writable_Empty_Buffers_Use_The_Null_Range (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U_Empty     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt16, 1));
      I_Empty     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Int16, 1));
      L_Empty     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Int32, 1));
      Empty_Count : Natural := 0;

      procedure Empty_U
        (Data : aliased in out OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 1 and then Data'Last = 0 and then Data'Length = 0,
            "Empty UInt16 writable buffer uses the 1 .. 0 null range");
         Empty_Count := Empty_Count + 1;
      end Empty_U;
      procedure Empty_I
        (Data : aliased in out OpenCV.Core.Int16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 1 and then Data'Last = 0 and then Data'Length = 0,
            "Empty Int16 writable buffer uses the 1 .. 0 null range");
         Empty_Count := Empty_Count + 1;
      end Empty_I;
      procedure Empty_L
        (Data : aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 1 and then Data'Last = 0 and then Data'Length = 0,
            "Empty Int32 writable buffer uses the 1 .. 0 null range");
         Empty_Count := Empty_Count + 1;
      end Empty_L;
   begin
      OpenCV.Core.UInt16_Buffer_Access.With_Writable_Buffer
        (U_Empty, Empty_U'Access);
      OpenCV.Core.Int16_Buffer_Access.With_Writable_Buffer
        (I_Empty, Empty_I'Access);
      OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
        (L_Empty, Empty_L'Access);
      AUnit.Assertions.Assert
        (Empty_Count = 3,
         "Each typed empty writable integer buffer must invoke callback once");
   end Writable_Empty_Buffers_Use_The_Null_Range;

   procedure UInt16_Read_Only_Buffer_Exposes_Row_Major_Values
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 1));

      procedure Inspect
        (Data : aliased OpenCV.Core.UInt16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5 and then Data'Length = 6,
            "Nonempty UInt16 read-only buffer must be zero-based");
         AUnit.Assertions.Assert
           (Data = (0, 1, 32_768, 65_534, 65_535, 7),
            "UInt16 read-only buffer must expose row-major stored values");
      end Inspect;
   begin
      OpenCV.Core.UInt16_Access.Set (Image, 0, 0, 0);
      OpenCV.Core.UInt16_Access.Set (Image, 0, 1, 1);
      OpenCV.Core.UInt16_Access.Set (Image, 0, 2, 32_768);
      OpenCV.Core.UInt16_Access.Set (Image, 1, 0, 65_534);
      OpenCV.Core.UInt16_Access.Set (Image, 1, 1, 65_535);
      OpenCV.Core.UInt16_Access.Set (Image, 1, 2, 7);
      OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
        (Image, Inspect'Access);
   end UInt16_Read_Only_Buffer_Exposes_Row_Major_Values;

   procedure Alias_Rebind_Leaves_Source_Header_Owning_Storage
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 1));
      Alias : OpenCV.Core.Mat := Image;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         Alias := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
         Data (0) := 16_777_217;
         Data (1) := OpenCV.Int32_Value'Last;
      end Mutate;
   begin
      OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
        (Image, Mutate'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (Image, 0, 0) = 16_777_217
         and then OpenCV.Core.Int32_Access.Get (Image, 0, 1)
                  = OpenCV.Int32_Value'Last
         and then Alias.Depth = OpenCV.Core.UInt16
         and then Alias.Total = 1,
         "Rebinding only an alias still leaves Image owning the allocation");
   end Alias_Rebind_Leaves_Source_Header_Owning_Storage;

   procedure Read_Only_Lease_Retains_Released_UInt16_Storage
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Started : Boolean := False;
   begin
      begin
         declare
            Image : OpenCV.Core.Mat;
            Alias : OpenCV.Core.Mat;

            procedure Inspect
              (Data : aliased OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
            is
               Replacement : OpenCV.Core.Mat;
               Empty       : OpenCV.Core.Mat;
            begin
               Image := Replacement;
               Alias := Empty;
               Assert_Target_Still_Leased;
               AUnit.Assertions.Assert
                 (Data (0) = 65_535 and then Data (1) = 7,
                  "The leased UInt16 allocation must still expose its values");
               Replacement :=
                 OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
               Image := Replacement;
               AUnit.Assertions.Assert
                 (Image.Depth = OpenCV.Core.Int16 and then Alias.Is_Empty,
                  "UInt16 headers must show their rebound state"
                  & " during the lease");
            end Inspect;
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt16, 1));
            Assert_Target_Attached;

            Integer_Borrow_Lifetime_Probe.Restore_Default_Allocator;
            OpenCV.Core.UInt16_Access.Set (Image, 0, 0, 65_535);
            OpenCV.Core.UInt16_Access.Set (Image, 0, 1, 7);
            Alias := Image;
            OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
              (Image, Inspect'Access);
            Assert_Target_Released_Once;
            AUnit.Assertions.Assert
              (Image.Depth = OpenCV.Core.Int16 and then Alias.Is_Empty,
               "UInt16 headers must retain their rebound state"
               & " after the callback");
         end;
      exception
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;
      Finish_Started_Observation (Started);
   end Read_Only_Lease_Retains_Released_UInt16_Storage;

   procedure Read_Only_Lease_Retains_Released_Int16_Storage
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Started : Boolean := False;
   begin
      begin
         declare
            Image : OpenCV.Core.Mat;
            Alias : OpenCV.Core.Mat;

            procedure Inspect
              (Data : aliased OpenCV.Core.Int16_Buffer_Access.Buffer_Array)
            is
               Replacement : OpenCV.Core.Mat;
               Empty       : OpenCV.Core.Mat;
            begin
               Image := Replacement;
               Alias := Empty;
               Assert_Target_Still_Leased;
               AUnit.Assertions.Assert
                 (Data (0) = OpenCV.Int16_Value'First and then Data (1) = -7,
                  "The leased Int16 allocation must still expose its values");
               Replacement :=
                 OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
               Image := Replacement;
               AUnit.Assertions.Assert
                 (Image.Depth = OpenCV.Core.UInt16 and then Alias.Is_Empty,
                  "Int16 headers must show their rebound state"
                  & " during the lease");
            end Inspect;
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 2, (OpenCV.Core.Int16, 1));
            Assert_Target_Attached;

            Integer_Borrow_Lifetime_Probe.Restore_Default_Allocator;
            OpenCV.Core.Int16_Access.Set
              (Image, 0, 0, OpenCV.Int16_Value'First);
            OpenCV.Core.Int16_Access.Set (Image, 0, 1, -7);
            Alias := Image;
            OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
              (Image, Inspect'Access);
            Assert_Target_Released_Once;
            AUnit.Assertions.Assert
              (Image.Depth = OpenCV.Core.UInt16 and then Alias.Is_Empty,
               "Int16 headers must retain their rebound state"
               & " after the callback");
         end;
      exception
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;
      Finish_Started_Observation (Started);
   end Read_Only_Lease_Retains_Released_Int16_Storage;

   procedure Writable_Lease_Retains_Released_Int32_Storage
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Started : Boolean := False;
   begin
      begin
         declare
            Image : OpenCV.Core.Mat;
            Alias : OpenCV.Core.Mat;

            procedure Mutate
              (Data :
                 aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array)
            is
               Replacement : OpenCV.Core.Mat;
               Empty       : OpenCV.Core.Mat;
            begin
               Image := Replacement;
               Alias := Empty;
               Assert_Target_Still_Leased;
               AUnit.Assertions.Assert
                 (Data (0) = 3 and then Data (1) = 4,
                  "The leased Int32 allocation must still expose its values");
               Data (0) := 16_777_217;
               Data (1) := OpenCV.Int32_Value'Last;
               AUnit.Assertions.Assert
                 (Data (0) = 16_777_217
                  and then Data (1) = OpenCV.Int32_Value'Last,
                  "Writes through the leased Int32 array must remain usable");
               Replacement :=
                 OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
               Image := Replacement;
               AUnit.Assertions.Assert
                 (Image.Depth = OpenCV.Core.UInt16
                  and then Image.Total = 1
                  and then Alias.Is_Empty,
                  "Releasing both ordinary owners must leave the Int32 lease");
            end Mutate;
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 1));
            Assert_Target_Attached;
            Integer_Borrow_Lifetime_Probe.Restore_Default_Allocator;
            OpenCV.Core.Int32_Access.Set (Image, 0, 0, 3);
            OpenCV.Core.Int32_Access.Set (Image, 0, 1, 4);

            Alias := Image;
            OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
              (Image, Mutate'Access);
            Assert_Target_Released_Once;
            AUnit.Assertions.Assert
              (Image.Depth = OpenCV.Core.UInt16 and then Alias.Is_Empty,
               "Int32 headers must retain their rebound state"
               & " after the callback");
         end;
      exception
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;
      Finish_Started_Observation (Started);
   end Writable_Lease_Retains_Released_Int32_Storage;

   procedure Observer_Sees_Ordinary_Release_Exactly_Once
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Started : Boolean := False;
   begin
      begin
         declare
            Image       : OpenCV.Core.Mat;
            Replacement : OpenCV.Core.Mat;
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
            Assert_Target_Attached;

            Integer_Borrow_Lifetime_Probe.Restore_Default_Allocator;
            Replacement := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
            AUnit.Assertions.Assert
              (not Image.Is_Empty
               and then Integer_Borrow_Lifetime_Probe.Target_Live
               and then Integer_Borrow_Lifetime_Probe.Deallocation_Count = 0,
               "A replacement allocation must not count as the original"
               & " release");

            Image := Replacement;
            Assert_Target_Released_Once;
         end;
      exception
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;
      Finish_Started_Observation (Started);

      begin
         declare
            Image : OpenCV.Core.Mat;
            pragma Unreferenced (Image);
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
            Assert_Target_Attached;

            Image := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
            Assert_Target_Released_Once;
         end;
      exception
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;
      Finish_Started_Observation (Started);
   end Observer_Sees_Ordinary_Release_Exactly_Once;

   procedure Lease_Exception_Releases_Original_Allocation_Once
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Started : Boolean := False;
   begin
      begin
         declare
            Image : OpenCV.Core.Mat;
            Alias : OpenCV.Core.Mat;

            procedure Fail
              (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array)
            is
               Empty : OpenCV.Core.Mat;
            begin
               Image := Empty;
               Alias := Empty;
               Assert_Target_Still_Leased;
               AUnit.Assertions.Assert
                 (Data (0) = 11 and then Data (1) = 22,
                  "The leased Int32 allocation must be readable"
                  & " before failure");
               raise Callback_Error;
            end Fail;
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 1));
            Assert_Target_Attached;
            Integer_Borrow_Lifetime_Probe.Restore_Default_Allocator;
            OpenCV.Core.Int32_Access.Set (Image, 0, 0, 11);
            OpenCV.Core.Int32_Access.Set (Image, 0, 1, 22);

            Alias := Image;
            begin
               OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
                 (Image, Fail'Access);
               AUnit.Assertions.Assert
                 (False, "The callback exception must propagate");
            exception
               when Callback_Error =>
                  null;
            end;
            Assert_Target_Released_Once;
            AUnit.Assertions.Assert
              (Image.Is_Empty and then Alias.Is_Empty,
               "Exception unwinding must leave both rebound headers empty");
         end;
      exception
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;
      Finish_Started_Observation (Started);

      begin
         declare
            Image : OpenCV.Core.Mat;
            pragma Unreferenced (Image);
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 1, (OpenCV.Core.Int32, 1));
            Assert_Target_Attached;

            declare
               Empty : OpenCV.Core.Mat;
            begin
               Image := Empty;
            end;

            Assert_Target_Released_Once;
         end;
      exception
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;
      Finish_Started_Observation (Started);
   end Lease_Exception_Releases_Original_Allocation_Once;

   procedure Finish_While_Live_Keeps_Session_Until_Release
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Started : Boolean := False;
   begin
      begin
         declare
            Image : OpenCV.Core.Mat;
            pragma Unreferenced (Image);
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt16, 1));
            Assert_Target_Attached;

            begin
               Integer_Borrow_Lifetime_Probe.Finish;
               AUnit.Assertions.Assert
                 (False, "Finish must reject a target that is still live");
            exception
               when Integer_Borrow_Lifetime_Probe.Probe_Error =>
                  null;
            end;
            Assert_Target_Attached;

            begin
               Integer_Borrow_Lifetime_Probe.Begin_Observation;
               AUnit.Assertions.Assert
                 (False, "A nested observation must be rejected");
            exception
               when Integer_Borrow_Lifetime_Probe.Probe_Error =>
                  null;
            end;
            Assert_Target_Attached;

            declare
               Empty : OpenCV.Core.Mat;
            begin
               Image := Empty;
            end;
            Assert_Target_Released_Once;
         end;
      exception
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;
      Finish_Started_Observation (Started);

      begin
         declare
            Image : OpenCV.Core.Mat;
            pragma Unreferenced (Image);
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
            Assert_Target_Attached;
            declare
               Empty : OpenCV.Core.Mat;
            begin
               Image := Empty;
            end;
            Assert_Target_Released_Once;
         end;
      exception
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;
      Finish_Started_Observation (Started);
   end Finish_While_Live_Keeps_Session_Until_Release;

   Early_Failure : exception;

   procedure Early_Failure_Releases_Before_Finish (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Started  : Boolean := False;
      Identity : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;
   begin
      begin
         declare
            Image : OpenCV.Core.Mat;
            pragma Unreferenced (Image);
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 2, (OpenCV.Core.Int16, 1));
            Assert_Target_Attached;
            raise Early_Failure;
         end;
      exception
         when Error : Early_Failure =>
            Identity := Ada.Exceptions.Exception_Identity (Error);
            Assert_Target_Released_Once;
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;

      AUnit.Assertions.Assert
        (Identity = Early_Failure'Identity,
         "Early observation failure must preserve the original exception");
      Finish_Started_Observation (Started);

      begin
         declare
            Image : OpenCV.Core.Mat;
            pragma Unreferenced (Image);
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
            Assert_Target_Attached;
            declare
               Empty : OpenCV.Core.Mat;
            begin
               Image := Empty;
            end;
            Assert_Target_Released_Once;
         end;
      exception
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;
      Finish_Started_Observation (Started);
   end Early_Failure_Releases_Before_Finish;

   Body_Error : exception;

   procedure Body_Exception_Finalizes_Before_Cleanup (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Started                 : Boolean := False;
      Released_Before_Cleanup : Boolean := False;
   begin
      begin
         begin
            declare
               Image : OpenCV.Core.Mat;
               pragma Unreferenced (Image);
            begin
               Integer_Borrow_Lifetime_Probe.Begin_Observation;
               Started := True;
               Image := OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt16, 1));
               Assert_Target_Attached;
               raise Body_Error with "body exception before manual release";
            end;
         exception
            when Error : Body_Error =>
               Released_Before_Cleanup :=
                 not Integer_Borrow_Lifetime_Probe.Target_Live
                 and then Integer_Borrow_Lifetime_Probe.Deallocation_Count = 1;
               Cleanup_Started_Observation (Started, Error);
            when Original : others =>
               Cleanup_Started_Observation (Started, Original);
         end;
         Finish_Started_Observation (Started);
         AUnit.Assertions.Assert
           (False, "The body exception must propagate through cleanup");
      exception
         when Error : Body_Error =>
            AUnit.Assertions.Assert
              (Released_Before_Cleanup,
               "The tracked Mat must release its allocation before cleanup");
            AUnit.Assertions.Assert
              (Ada.Exceptions.Exception_Identity (Error) = Body_Error'Identity
               and then Ada.Exceptions.Exception_Message (Error)
                        = "body exception before manual release",
               "Successful cleanup must preserve the body exception identity"
               & " and message");
      end;

      begin
         declare
            Image : OpenCV.Core.Mat;
            pragma Unreferenced (Image);
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
            Assert_Target_Attached;
            declare
               Empty : OpenCV.Core.Mat;
            begin
               Image := Empty;
            end;
            Assert_Target_Released_Once;
         end;
      exception
         when Original : others =>
            Cleanup_Started_Observation (Started, Original);
      end;
      Finish_Started_Observation (Started);
   end Body_Exception_Finalizes_Before_Cleanup;

   procedure Observation_Cleanup_Preserves_Primary_Exception
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);

      Primary_Error : exception;

      Finish_Attempts  : Natural := 0;
      Cleanup_Attempts : Natural := 0;

      type Body_Kind is (Fail, Succeed);

      procedure Run_Session (Kind : Body_Kind) is
         Started : Boolean := False;
      begin
         begin
            declare
               Marker : Boolean := False;
               pragma Unreferenced (Marker);
            begin
               Started := True;
               case Kind is
                  when Fail    =>
                     raise Primary_Error with "primary observation failure";

                  when Succeed =>
                     Marker := True;
               end case;
            end;
         exception
            when Original : others =>
               Cleanup_Attempts := Cleanup_Attempts + 1;
               Cleanup_Started_Observation (Started, Original);
         end;
         Finish_Attempts := Finish_Attempts + 1;
         Finish_Started_Observation (Started);
      end Run_Session;

      procedure Expect_Primary (Kind : Body_Kind; Cleanup_Count : Natural) is
      begin
         Finish_Attempts := 0;
         Cleanup_Attempts := 0;
         begin
            Run_Session (Kind);
            AUnit.Assertions.Assert
              (False, "The primary observation failure must propagate");
         exception
            when Error : Primary_Error =>
               AUnit.Assertions.Assert
                 (Ada.Exceptions.Exception_Identity (Error)
                  = Primary_Error'Identity
                  and then Ada.Exceptions.Exception_Message (Error)
                           = "primary observation failure",
                  "Cleanup must preserve the primary exception identity"
                  & " and message");
            when Probe_Cleanup_Error =>
               AUnit.Assertions.Assert
                 (False,
                  "Cleanup failure must not replace the primary exception");
         end;
         AUnit.Assertions.Assert
           (Cleanup_Attempts = Cleanup_Count and then Finish_Attempts = 0,
            "Exceptional cleanup must run once and normal Finish must not");
      end Expect_Primary;
   begin
      Observation_Cleanup_Fails := True;
      Expect_Primary (Fail, Cleanup_Count => 1);

      Finish_Attempts := 0;
      Cleanup_Attempts := 0;
      begin
         Run_Session (Succeed);
         AUnit.Assertions.Assert
           (False, "A normal Finish failure must propagate");
      exception
         when Error : Probe_Cleanup_Error =>
            AUnit.Assertions.Assert
              (Ada.Exceptions.Exception_Message (Error)
               = "deliberate observation cleanup failure",
               "A normal Finish failure must remain visible");
         when Primary_Error =>
            AUnit.Assertions.Assert
              (False, "A normal Finish failure must not become Primary_Error");
      end;
      AUnit.Assertions.Assert
        (Finish_Attempts = 1 and then Cleanup_Attempts = 0,
         "A failing normal Finish must run once and not enter cleanup");

      Observation_Cleanup_Fails := False;
      Expect_Primary (Fail, Cleanup_Count => 1);
   exception
      when others =>
         Observation_Cleanup_Fails := False;
         raise;
   end Observation_Cleanup_Preserves_Primary_Exception;

   procedure Whole_Buffer_Callback_Exceptions_Propagate (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U16      : OpenCV.Core.Mat :=

          OpenCV
          .Core
          .Create (1, 2, (OpenCV.Core.UInt16, 1));
      I16      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int16, 1));
      I32      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 1));
      Raised   : Boolean := False;
      Identity : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Fail_Read_U
        (Data : aliased OpenCV.Core.UInt16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data (0) = 1 and then Data (1) = 2, "UInt16 read-only values");
         raise Callback_Error;
      end Fail_Read_U;
      procedure Fail_Read_I
        (Data : aliased OpenCV.Core.Int16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert (Data (0) = -3, "Int16 read-only value");
         raise Callback_Error;
      end Fail_Read_I;
      procedure Fail_Read_L
        (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data (0) = 16_777_217, "Int32 read-only value");
         raise Callback_Error;
      end Fail_Read_L;
      procedure Fail_Write_U
        (Data : aliased in out OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
      is
      begin
         Data (0) := 65_535;
         raise Callback_Error;
      end Fail_Write_U;
      procedure Fail_Write_I
        (Data : aliased in out OpenCV.Core.Int16_Buffer_Access.Buffer_Array) is
      begin
         Data (1) := OpenCV.Int16_Value'First;
         raise Callback_Error;
      end Fail_Write_I;
      procedure Fail_Write_L
        (Data : aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         Data (0) := OpenCV.Int32_Value'Last;
         raise Callback_Error;
      end Fail_Write_L;
      procedure Read_Again_U
        (Data : aliased OpenCV.Core.UInt16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data (0) = 65_535 and then Data (1) = 9,
            "A later UInt16 borrow must succeed after the exception");
      end Read_Again_U;
      procedure Read_Again_I
        (Data : aliased OpenCV.Core.Int16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data (1) = OpenCV.Int16_Value'First,
            "A later Int16 borrow must succeed after the exception");
      end Read_Again_I;
      procedure Read_Again_L
        (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data (0) = OpenCV.Int32_Value'Last,
            "A later Int32 borrow must succeed after the exception");
      end Read_Again_L;

      procedure Expect (Attempt : not null access procedure) is
      begin
         Raised := False;
         Identity := Ada.Exceptions.Null_Id;
         begin
            Attempt.all;
         exception
            when Error : Callback_Error =>
               Raised := True;
               Identity := Ada.Exceptions.Exception_Identity (Error);
         end;
         AUnit.Assertions.Assert
           (Raised and then Identity = Callback_Error'Identity,
            "Whole-buffer callback exceptions must propagate unchanged");
      end Expect;

      procedure Read_U is
      begin
         OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
           (U16, Fail_Read_U'Access);
      end Read_U;
      procedure Read_I is
      begin
         OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
           (I16, Fail_Read_I'Access);
      end Read_I;
      procedure Read_L is
      begin
         OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
           (I32, Fail_Read_L'Access);
      end Read_L;
      procedure Write_U is
      begin
         OpenCV.Core.UInt16_Buffer_Access.With_Writable_Buffer
           (U16, Fail_Write_U'Access);
      end Write_U;
      procedure Write_I is
      begin
         OpenCV.Core.Int16_Buffer_Access.With_Writable_Buffer
           (I16, Fail_Write_I'Access);
      end Write_I;
      procedure Write_L is
      begin
         OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
           (I32, Fail_Write_L'Access);
      end Write_L;
   begin
      OpenCV.Core.UInt16_Access.Set (U16, 0, 0, 1);
      OpenCV.Core.UInt16_Access.Set (U16, 0, 1, 2);
      OpenCV.Core.Int16_Access.Set (I16, 0, 0, -3);
      OpenCV.Core.Int16_Access.Set (I16, 0, 1, 4);
      OpenCV.Core.Int32_Access.Set (I32, 0, 0, 16_777_217);
      OpenCV.Core.Int32_Access.Set (I32, 0, 1, 5);
      Expect (Read_U'Access);
      Expect (Read_I'Access);
      Expect (Read_L'Access);
      Expect (Write_U'Access);
      Expect (Write_I'Access);
      Expect (Write_L'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Access.Get (U16, 0, 0) = 65_535
         and then OpenCV.Core.UInt16_Access.Get (U16, 0, 1) = 2
         and then OpenCV.Core.Int16_Access.Get (I16, 0, 1)
                  = OpenCV.Int16_Value'First
         and then OpenCV.Core.Int32_Access.Get (I32, 0, 0)
                  = OpenCV.Int32_Value'Last,
         "Writes completed before a whole-buffer exception must remain");
      OpenCV.Core.UInt16_Access.Set (U16, 0, 1, 9);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Access.Get (U16, 0, 1) = 9,
         "The Mat must remain usable after a whole-buffer exception");
      OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
        (U16, Read_Again_U'Access);
      OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
        (I16, Read_Again_I'Access);
      OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
        (I32, Read_Again_L'Access);
   end Whole_Buffer_Callback_Exceptions_Propagate;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Integer buffers preserve exact values and row-major extents",
            Exact_Values_And_Zero_Based_Row_Major_Extents'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer buffers accept continuous and reject strided Regions",
            Continuous_Regions_Are_Accepted_And_Strided_Regions_Rejected
              'Access));

      Result.Add_Test
        (Caller.Create
           ("Integer buffers validate empty type channels and dimensions",
            Empty_Type_And_Dimension_Validation_Covers_All_Families'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer empty writable buffers use the null range",
            Writable_Empty_Buffers_Use_The_Null_Range'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt16 read-only buffer exposes row-major values",
            UInt16_Read_Only_Buffer_Exposes_Row_Major_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer alias rebind leaves source owning storage",
            Alias_Rebind_Leaves_Source_Header_Owning_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Borrow observer sees one ordinary release",
            Observer_Sees_Ordinary_Release_Exactly_Once'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt16 buffer lease retains storage after ordinary release",
            Read_Only_Lease_Retains_Released_UInt16_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Int16 buffer lease retains storage after ordinary release",
            Read_Only_Lease_Retains_Released_Int16_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Int32 buffer lease retains storage after ordinary release",
            Writable_Lease_Retains_Released_Int32_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer buffer lease releases once on callback exception",
            Lease_Exception_Releases_Original_Allocation_Once'Access));
      Result.Add_Test
        (Caller.Create
           ("Finish while live keeps the observation until release",
            Finish_While_Live_Keeps_Session_Until_Release'Access));
      Result.Add_Test
        (Caller.Create
           ("Early observation failure releases before finish",
            Early_Failure_Releases_Before_Finish'Access));
      Result.Add_Test
        (Caller.Create
           ("Body exception finalizes the tracked Mat before cleanup",
            Body_Exception_Finalizes_Before_Cleanup'Access));
      Result.Add_Test
        (Caller.Create
           ("Observation cleanup preserves the primary exception",
            Observation_Cleanup_Preserves_Primary_Exception'Access));

      Result.Add_Test
        (Caller.Create
           ("Integer whole-buffer callback exceptions propagate",
            Whole_Buffer_Callback_Exceptions_Propagate'Access));
      return Result'Access;
   end Suite;

end Integer_Buffer_Access_Tests;
