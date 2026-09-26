with Ada.Exceptions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Integer_Borrow_Lifetime_Probe;
with Interfaces;
with Mat_Test_Support;
with ND_Buffer_Access_Tests.Raw_ABI;
with ND_Buffer_Checks;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float16_Buffer_Access;
with OpenCV.Core.Float16_Vec3;
with OpenCV.Core.Float16_Vec3_Access;
with OpenCV.Core.Float16_Vec3_Buffer_Access;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Buffer_Access;
with OpenCV.Core.Float32_Vec2;
with OpenCV.Core.Float32_Vec2_Access;
with OpenCV.Core.Float32_Vec2_Buffer_Access;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.Float32_Vec3_Buffer_Access;
with OpenCV.Core.Float32_Vec4;
with OpenCV.Core.Float32_Vec4_Access;
with OpenCV.Core.Float32_Vec4_Buffer_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float64_Buffer_Access;
with OpenCV.Core.Float64_Vec2;
with OpenCV.Core.Float64_Vec2_Access;
with OpenCV.Core.Float64_Vec2_Buffer_Access;
with OpenCV.Core.Float64_Vec3;
with OpenCV.Core.Float64_Vec3_Access;
with OpenCV.Core.Float64_Vec3_Buffer_Access;
with OpenCV.Core.Float64_Vec4;
with OpenCV.Core.Float64_Vec4_Access;
with OpenCV.Core.Float64_Vec4_Buffer_Access;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Int16_Buffer_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Int32_Buffer_Access;
with OpenCV.Core.Int8_Access;
with OpenCV.Core.Int8_Buffer_Access;
with OpenCV.Core.UInt16_Access;
with OpenCV.Core.UInt16_Buffer_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Buffer_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with OpenCV.Core.UInt8_Vec3_Buffer_Access;

package body ND_Buffer_Access_Tests is

   use type Interfaces.Unsigned_16;
   use type OpenCV.Float32_Value;
   use type OpenCV.Float64_Value;
   use type OpenCV.Int32_Value;
   use type OpenCV.Core.Float64_Vec4.Vector;

   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   --  Value generators. Offsets 0 .. 23 and 100 .. 102 are distinct.

   function F16
     (Bits : Interfaces.Unsigned_16) return OpenCV.Core.Float16_Value
   renames OpenCV.Core.Float16_From_Bits;

   --  2**-40 is not representable next to 1.0 in Float32.
   Fine : constant OpenCV.Float64_Value := 2.0**(-40);

   function UInt8_At (O : Natural) return OpenCV.UInt8_Value
   is (OpenCV.UInt8_Value (O + 1));

   function Int8_At (O : Natural) return OpenCV.Int8_Value
   is (OpenCV.Int8_Value (O - 120));

   function UInt16_At (O : Natural) return OpenCV.UInt16_Value
   is (OpenCV.UInt16_Value (65_535 - O));

   function Int16_At (O : Natural) return OpenCV.Int16_Value
   is (OpenCV.Int16_Value (Integer (O) - 32_768));

   function Int32_At (O : Natural) return OpenCV.Int32_Value
   is (case O is
         when 100    => OpenCV.Int32_Value'First,
         when 101    => OpenCV.Int32_Value'Last,
         when others => OpenCV.Int32_Value (O) * (-1_000) - 7);

   --  Normal values near 1.0, and for the mutation offsets a signalling
   --  NaN payload, the smallest subnormal, and negative zero. A Float32
   --  round trip would quiet the signalling NaN.
   function Float16_At (O : Natural) return OpenCV.Core.Float16_Value
   is (case O is
         when 100    => F16 (16#7C01#),
         when 101    => F16 (16#0001#),
         when 102    => F16 (16#8000#),
         when others => F16 (16#3C00# + Interfaces.Unsigned_16 (O)));

   function Float32_At (O : Natural) return OpenCV.Float32_Value
   is (OpenCV.Float32_Value (O) * 0.5 - 3.25);

   function Float64_At (O : Natural) return OpenCV.Float64_Value
   is (1.0 + OpenCV.Float64_Value (O + 1) * Fine);

   function F32_Vec2_At (O : Natural) return OpenCV.Core.Float32_Vec2.Vector
   is (Float32_At (O), -Float32_At (O) - 100.0);

   function F64_Vec2_At (O : Natural) return OpenCV.Core.Float64_Vec2.Vector
   is (Float64_At (O), -Float64_At (O));

   function U8_Vec3_At (O : Natural) return OpenCV.Core.UInt8_Vec3.Vector
   is (OpenCV.UInt8_Value (O),
       OpenCV.UInt8_Value (O + 50),
       OpenCV.UInt8_Value (O + 150));

   --  Every element carries a distinct signalling-NaN payload in its last
   --  component, so any conversion through Float32 would be detected.
   function F16_Vec3_At (O : Natural) return OpenCV.Core.Float16_Vec3.Vector
   is (F16 (16#3C00# + Interfaces.Unsigned_16 (O)),
       F16 (16#BC00# + Interfaces.Unsigned_16 (O)),
       F16 (16#7C01# + Interfaces.Unsigned_16 (O)));

   function F32_Vec3_At (O : Natural) return OpenCV.Core.Float32_Vec3.Vector
   is (Float32_At (O), Float32_At (O) + 0.25, -Float32_At (O));

   function F64_Vec3_At (O : Natural) return OpenCV.Core.Float64_Vec3.Vector
   is (Float64_At (O), -Float64_At (O), Float64_At (O) * 3.0);

   function F32_Vec4_At (O : Natural) return OpenCV.Core.Float32_Vec4.Vector
   is (Float32_At (O), 1.0, -Float32_At (O), 2.0);

   function F64_Vec4_At (O : Natural) return OpenCV.Core.Float64_Vec4.Vector
   is (Float64_At (O),
       -2.0 - OpenCV.Float64_Value (O) * Fine,
       3.0 + 2.0**(-44),
       -Float64_At (O));

   --  One instance per typed buffer-access package.

   package UInt8_Checks is new
     ND_Buffer_Checks
       (OpenCV.UInt8_Value,
        OpenCV.Core.UInt8_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 1),
        "UInt8 C1",
        UInt8_At,
        OpenCV.Core.UInt8_Access.Get,
        OpenCV.Core.UInt8_Access.Set,
        OpenCV.Core.UInt8_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt8_Buffer_Access.With_Writable_Buffer);

   package Int8_Checks is new
     ND_Buffer_Checks
       (OpenCV.Int8_Value,
        OpenCV.Core.Int8_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int8, 1),
        "Int8 C1",
        Int8_At,
        OpenCV.Core.Int8_Access.Get,
        OpenCV.Core.Int8_Access.Set,
        OpenCV.Core.Int8_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int8_Buffer_Access.With_Writable_Buffer);

   package UInt16_Checks is new
     ND_Buffer_Checks
       (OpenCV.UInt16_Value,
        OpenCV.Core.UInt16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt16, 1),
        "UInt16 C1",
        UInt16_At,
        OpenCV.Core.UInt16_Access.Get,
        OpenCV.Core.UInt16_Access.Set,
        OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt16_Buffer_Access.With_Writable_Buffer);

   package Int16_Checks is new
     ND_Buffer_Checks
       (OpenCV.Int16_Value,
        OpenCV.Core.Int16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int16, 1),
        "Int16 C1",
        Int16_At,
        OpenCV.Core.Int16_Access.Get,
        OpenCV.Core.Int16_Access.Set,
        OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int16_Buffer_Access.With_Writable_Buffer);

   package Int32_Checks is new
     ND_Buffer_Checks
       (OpenCV.Int32_Value,
        OpenCV.Core.Int32_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int32, 1),
        "Int32 C1",
        Int32_At,
        OpenCV.Core.Int32_Access.Get,
        OpenCV.Core.Int32_Access.Set,
        OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer);

   package Float16_Checks is new
     ND_Buffer_Checks
       (OpenCV.Core.Float16_Value,
        OpenCV.Core.Float16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float16, 1),
        "Float16 C1",
        Float16_At,
        OpenCV.Core.Float16_Access.Get,
        OpenCV.Core.Float16_Access.Set,
        OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer);

   package Float32_Checks is new
     ND_Buffer_Checks
       (OpenCV.Float32_Value,
        OpenCV.Core.Float32_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 1),
        "Float32 C1",
        Float32_At,
        OpenCV.Core.Float32_Access.Get,
        OpenCV.Core.Float32_Access.Set,
        OpenCV.Core.Float32_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Buffer_Access.With_Writable_Buffer);

   package Float64_Checks is new
     ND_Buffer_Checks
       (OpenCV.Float64_Value,
        OpenCV.Core.Float64_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 1),
        "Float64 C1",
        Float64_At,
        OpenCV.Core.Float64_Access.Get,
        OpenCV.Core.Float64_Access.Set,
        OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Buffer_Access.With_Writable_Buffer);

   package F32_Vec2_Checks is new
     ND_Buffer_Checks
       (OpenCV.Core.Float32_Vec2.Vector,
        OpenCV.Core.Float32_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 2),
        "Float32 C2",
        F32_Vec2_At,
        OpenCV.Core.Float32_Vec2_Access.Get,
        OpenCV.Core.Float32_Vec2_Access.Set,
        OpenCV.Core.Float32_Vec2_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Vec2_Buffer_Access.With_Writable_Buffer);

   package F64_Vec2_Checks is new
     ND_Buffer_Checks
       (OpenCV.Core.Float64_Vec2.Vector,
        OpenCV.Core.Float64_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 2),
        "Float64 C2",
        F64_Vec2_At,
        OpenCV.Core.Float64_Vec2_Access.Get,
        OpenCV.Core.Float64_Vec2_Access.Set,
        OpenCV.Core.Float64_Vec2_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Vec2_Buffer_Access.With_Writable_Buffer);

   package U8_Vec3_Checks is new
     ND_Buffer_Checks
       (OpenCV.Core.UInt8_Vec3.Vector,
        OpenCV.Core.UInt8_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 3),
        "UInt8 C3",
        U8_Vec3_At,
        OpenCV.Core.UInt8_Vec3_Access.Get,
        OpenCV.Core.UInt8_Vec3_Access.Set,
        OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Writable_Buffer);

   package F16_Vec3_Checks is new
     ND_Buffer_Checks
       (OpenCV.Core.Float16_Vec3.Vector,
        OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float16, 3),
        "Float16 C3",
        F16_Vec3_At,
        OpenCV.Core.Float16_Vec3_Access.Get,
        OpenCV.Core.Float16_Vec3_Access.Set,
        OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float16_Vec3_Buffer_Access.With_Writable_Buffer);

   package F32_Vec3_Checks is new
     ND_Buffer_Checks
       (OpenCV.Core.Float32_Vec3.Vector,
        OpenCV.Core.Float32_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 3),
        "Float32 C3",
        F32_Vec3_At,
        OpenCV.Core.Float32_Vec3_Access.Get,
        OpenCV.Core.Float32_Vec3_Access.Set,
        OpenCV.Core.Float32_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Vec3_Buffer_Access.With_Writable_Buffer);

   package F64_Vec3_Checks is new
     ND_Buffer_Checks
       (OpenCV.Core.Float64_Vec3.Vector,
        OpenCV.Core.Float64_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 3),
        "Float64 C3",
        F64_Vec3_At,
        OpenCV.Core.Float64_Vec3_Access.Get,
        OpenCV.Core.Float64_Vec3_Access.Set,
        OpenCV.Core.Float64_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Vec3_Buffer_Access.With_Writable_Buffer);

   package F32_Vec4_Checks is new
     ND_Buffer_Checks
       (OpenCV.Core.Float32_Vec4.Vector,
        OpenCV.Core.Float32_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 4),
        "Float32 C4",
        F32_Vec4_At,
        OpenCV.Core.Float32_Vec4_Access.Get,
        OpenCV.Core.Float32_Vec4_Access.Set,
        OpenCV.Core.Float32_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Vec4_Buffer_Access.With_Writable_Buffer);

   package F64_Vec4_Checks is new
     ND_Buffer_Checks
       (OpenCV.Core.Float64_Vec4.Vector,
        OpenCV.Core.Float64_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 4),
        "Float64 C4",
        F64_Vec4_At,
        OpenCV.Core.Float64_Vec4_Access.Get,
        OpenCV.Core.Float64_Vec4_Access.Set,
        OpenCV.Core.Float64_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Vec4_Buffer_Access.With_Writable_Buffer);

   procedure Raw_Contiguous_Data_ABI (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      ND_Buffer_Access_Tests.Raw_ABI.Check;
   end Raw_Contiguous_Data_ABI;

   procedure Integer_C1_Volumes (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      UInt8_Checks.Check_Volume;
      Int8_Checks.Check_Volume;
      UInt16_Checks.Check_Volume;
      Int16_Checks.Check_Volume;
      Int32_Checks.Check_Volume;
   end Integer_C1_Volumes;

   procedure Float16_C1_Volume_Preserves_Bits (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Volume : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float16, 1));

      procedure Write
        (Data : aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
      is
      begin
         Data (0) := F16 (16#7C01#);
         Data (13) := F16 (16#8000#);
         Data (23) := F16 (16#03FF#);
      end Write;

      procedure Inspect
        (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float16_Bits (Data (0)) = 16#7C01#
            and then OpenCV.Core.Float16_Bits (Data (13)) = 16#8000#
            and then OpenCV.Core.Float16_Bits (Data (23)) = 16#03FF#,
            "Float16 N-D buffer must keep sNaN, -0 and subnormal bits");
      end Inspect;
   begin
      Float16_Checks.Check_Volume;
      OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
        (Volume, Write'Access);
      --  Offset 13 = ((1 * 3) + 0) * 4 + 1 = index (1, 0, 1).
      AUnit.Assertions.Assert
        (OpenCV.Core.Float16_Bits
           (OpenCV.Core.Float16_Access.Get (Volume, (0, 0, 0)))
         = 16#7C01#
         and then OpenCV.Core.Float16_Bits
                    (OpenCV.Core.Float16_Access.Get (Volume, (1, 0, 1)))
                  = 16#8000#
         and then OpenCV.Core.Float16_Bits
                    (OpenCV.Core.Float16_Access.Get (Volume, (1, 2, 3)))
                  = 16#03FF#,
         "Float16 N-D buffer writes must reach N-D Get bit-exactly");
      OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
        (Volume, Inspect'Access);
   end Float16_C1_Volume_Preserves_Bits;

   procedure Float32_Float64_C1_Volumes (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Float32_Checks.Check_Volume;
      Float64_Checks.Check_Volume;
   end Float32_Float64_C1_Volumes;

   procedure Vec2_Volumes (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      F32_Vec2_Checks.Check_Volume;
      F64_Vec2_Checks.Check_Volume;
   end Vec2_Volumes;

   procedure Vec3_Volumes (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      U8_Vec3_Checks.Check_Volume;
      F16_Vec3_Checks.Check_Volume;
      F32_Vec3_Checks.Check_Volume;
      F64_Vec3_Checks.Check_Volume;
   end Vec3_Volumes;

   procedure Vec4_Volumes_Preserve_Float64 (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Precise : constant OpenCV.Core.Float64_Vec4.Vector := F64_Vec4_At (5);
   begin
      AUnit.Assertions.Assert
        (OpenCV.Float64_Value (OpenCV.Float32_Value (Precise (0)))
         /= Precise (0),
         "The Float64 C4 fixture must not be representable in Float32");
      F32_Vec4_Checks.Check_Volume;
      F64_Vec4_Checks.Check_Volume;
   end Vec4_Volumes_Preserve_Float64;

   procedure Continuous_ND_Slices_Borrow (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      UInt8_Checks.Check_Continuous_Slice;
      Int8_Checks.Check_Continuous_Slice;
      UInt16_Checks.Check_Continuous_Slice;
      Int16_Checks.Check_Continuous_Slice;
      Int32_Checks.Check_Continuous_Slice;
      Float16_Checks.Check_Continuous_Slice;
      Float32_Checks.Check_Continuous_Slice;
      Float64_Checks.Check_Continuous_Slice;
      F32_Vec2_Checks.Check_Continuous_Slice;
      F64_Vec2_Checks.Check_Continuous_Slice;
      U8_Vec3_Checks.Check_Continuous_Slice;
      F16_Vec3_Checks.Check_Continuous_Slice;
      F32_Vec3_Checks.Check_Continuous_Slice;
      F64_Vec3_Checks.Check_Continuous_Slice;
      F32_Vec4_Checks.Check_Continuous_Slice;
      F64_Vec4_Checks.Check_Continuous_Slice;
   end Continuous_ND_Slices_Borrow;

   procedure Gapped_ND_Slices_Rejected (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      UInt8_Checks.Check_Gapped_Slice;
      Int8_Checks.Check_Gapped_Slice;
      UInt16_Checks.Check_Gapped_Slice;
      Int16_Checks.Check_Gapped_Slice;
      Int32_Checks.Check_Gapped_Slice;
      Float16_Checks.Check_Gapped_Slice;
      Float32_Checks.Check_Gapped_Slice;
      Float64_Checks.Check_Gapped_Slice;
      F32_Vec2_Checks.Check_Gapped_Slice;
      F64_Vec2_Checks.Check_Gapped_Slice;
      U8_Vec3_Checks.Check_Gapped_Slice;
      F16_Vec3_Checks.Check_Gapped_Slice;
      F32_Vec3_Checks.Check_Gapped_Slice;
      F64_Vec3_Checks.Check_Gapped_Slice;
      F32_Vec4_Checks.Check_Gapped_Slice;
      F64_Vec4_Checks.Check_Gapped_Slice;
   end Gapped_ND_Slices_Rejected;

   Lease_Callback_Error : exception;

   --  The lease protects memory lifetime only; it is not synchronization.
   procedure ND_Writable_Lease_Survives_Rebinding (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float64, 4));
      Survivor : constant OpenCV.Core.Mat := Image;
      Precise  : constant OpenCV.Core.Float64_Vec4.Vector := F64_Vec4_At (7);

      procedure Rebind_Then_Write
        (Data :
           aliased in out OpenCV.Core.Float64_Vec4_Buffer_Access.Buffer_Array)
      is
         Replacement : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      begin
         Image := Replacement;
         AUnit.Assertions.Assert
           (Image.Dimension_Count = 2 and then Data'Length = 24,
            "The original header must be rebound while Data stays valid");
         Data (23) := Precise;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec4_Access.Get (Survivor, (1, 2, 3))
            = Precise,
            "A write after rebinding must reach the shared N-D storage");
         raise Lease_Callback_Error;
      end Rebind_Then_Write;
   begin
      begin
         OpenCV.Core.Float64_Vec4_Buffer_Access.With_Writable_Buffer
           (Image, Rebind_Then_Write'Access);
         AUnit.Assertions.Assert
           (False, "The N-D callback exception must propagate");
      exception
         when Lease_Callback_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (Survivor.Dimension_Count = 3
         and then OpenCV.Core.Float64_Vec4_Access.Get (Survivor, (1, 2, 3))
                  = Precise,
         "The surviving alias must retain the completed exact Float64 write");
   end ND_Writable_Lease_Survives_Rebinding;

   procedure ND_Lease_Retains_Released_Allocation (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Started : Boolean := False;
   begin
      begin
         declare
            Image : OpenCV.Core.Mat;
            Alias : OpenCV.Core.Mat;

            procedure Release_Owners_Then_Write
              (Data :
                 aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array)
            is
               Empty : OpenCV.Core.Mat;
            begin
               Image := Empty;
               Alias := Empty;
               AUnit.Assertions.Assert
                 (Image.Is_Empty
                  and then Alias.Is_Empty
                  and then Integer_Borrow_Lifetime_Probe.Target_Live
                  and then Integer_Borrow_Lifetime_Probe.Deallocation_Count
                           = 0,
                  "The lease must keep the released N-D allocation live");
               Data (23) := -99;
               AUnit.Assertions.Assert
                 (Data (0) = 11 and then Data (23) = -99,
                  "The leased N-D allocation must remain readable/writable");
            end Release_Owners_Then_Write;
         begin
            Integer_Borrow_Lifetime_Probe.Begin_Observation;
            Started := True;
            Image :=
              OpenCV.Core.Create
                (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Int32, 1));
            AUnit.Assertions.Assert
              (Integer_Borrow_Lifetime_Probe.Target_Captured
               and then Integer_Borrow_Lifetime_Probe.Target_Size >= 96,
               "The N-D allocation must be the observed target");
            Integer_Borrow_Lifetime_Probe.Restore_Default_Allocator;
            OpenCV.Core.Int32_Access.Set (Image, (0, 0, 0), 11);
            Alias := Image;
            OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
              (Image, Release_Owners_Then_Write'Access);
            AUnit.Assertions.Assert
              (not Integer_Borrow_Lifetime_Probe.Target_Live
               and then Integer_Borrow_Lifetime_Probe.Deallocation_Count = 1,
               "The N-D allocation must be released exactly once at lease"
               & " end");
         end;
         Integer_Borrow_Lifetime_Probe.Finish;
         Started := False;
      exception
         when Original : others =>
            if Started then
               begin
                  Integer_Borrow_Lifetime_Probe.Finish;
               exception
                  when others =>
                     null;
               end;
            end if;
            Ada.Exceptions.Reraise_Occurrence (Original);
      end;
   end ND_Lease_Retains_Released_Allocation;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Contiguous-data raw ABI: nulls, 2-D, N-D, gaps, empty",
            Raw_Contiguous_Data_ABI'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer C1 N-D buffers follow flat N-D order",
            Integer_C1_Volumes'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 C1 N-D buffers preserve exact binary16 bits",
            Float16_C1_Volume_Preserves_Bits'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 and Float64 C1 N-D buffers follow flat N-D order",
            Float32_Float64_C1_Volumes'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec2 N-D buffers expose complete C2 elements",
            Vec2_Volumes'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec3 N-D buffers expose complete C3 elements",
            Vec3_Volumes'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec4 N-D buffers expose complete C4 elements without narrowing",
            Vec4_Volumes_Preserve_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Continuous N-D Slices borrow for every buffer package",
            Continuous_ND_Slices_Borrow'Access));
      Result.Add_Test
        (Caller.Create
           ("Non-contiguous N-D Slices are rejected before Process",
            Gapped_ND_Slices_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("N-D writable lease survives header rebinding and exceptions",
            ND_Writable_Lease_Survives_Rebinding'Access));
      Result.Add_Test
        (Caller.Create
           ("N-D lease retains a released allocation until callback exit",
            ND_Lease_Retains_Released_Allocation'Access));
      return Result'Access;
   end Suite;

end ND_Buffer_Access_Tests;
