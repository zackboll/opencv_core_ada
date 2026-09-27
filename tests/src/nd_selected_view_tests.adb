with Ada.Exceptions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Integer_Borrow_Lifetime_Probe;
with Interfaces;
with Mat_Test_Support;
with ND_Selected_View_Checks;
with ND_Selected_View_Tests.Raw_ABI;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float16_Vec3;
with OpenCV.Core.Float16_Vec3_Access;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Vec2;
with OpenCV.Core.Float32_Vec2_Access;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.Float32_Vec4;
with OpenCV.Core.Float32_Vec4_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float64_Vec2;
with OpenCV.Core.Float64_Vec2_Access;
with OpenCV.Core.Float64_Vec3;
with OpenCV.Core.Float64_Vec3_Access;
with OpenCV.Core.Float64_Vec4;
with OpenCV.Core.Float64_Vec4_Access;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Int32_Buffer_Access;
with OpenCV.Core.Int32_Mat_View;
with OpenCV.Core.Int32_Row_Access;
with OpenCV.Core.Int8_Access;
with OpenCV.Core.Module_Interop;
with OpenCV.Core.UInt16_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;

package body ND_Selected_View_Tests is

   use type Interfaces.Unsigned_16;
   use type OpenCV.Float32_Value;
   use type OpenCV.Float64_Value;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Int32_Value;
   use type OpenCV.Core.Dimension_Array;
   use type OpenCV.Core.Float64_Vec4.Vector;

   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   package Probe renames Integer_Borrow_Lifetime_Probe;

   function F16
     (Bits : Interfaces.Unsigned_16) return OpenCV.Core.Float16_Value
   renames OpenCV.Core.Float16_From_Bits;

   function Bits
     (Value : OpenCV.Core.Float16_Value) return Interfaces.Unsigned_16
   renames OpenCV.Core.Float16_Bits;

   Fine : constant OpenCV.Float64_Value := 2.0**(-40);

   --  Value generators; offsets 0 .. 47, 100 .. 111, and 200 are pairwise
   --  distinct for every layout.

   function UInt8_At (O : Natural) return OpenCV.UInt8_Value
   is (OpenCV.UInt8_Value (O + 1));

   function Int8_At (O : Natural) return OpenCV.Int8_Value
   is (OpenCV.Int8_Value (Integer (O) - 120));

   function UInt16_At (O : Natural) return OpenCV.UInt16_Value
   is (OpenCV.UInt16_Value (65_535 - O));

   function Int16_At (O : Natural) return OpenCV.Int16_Value
   is (OpenCV.Int16_Value (Integer (O) - 32_768));

   function Int32_At (O : Natural) return OpenCV.Int32_Value
   is (OpenCV.Int32_Value (O) * (-1_000) - 7);

   function Float16_At (O : Natural) return OpenCV.Core.Float16_Value
   is (F16 (16#3C00# + Interfaces.Unsigned_16 (O)));

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
       OpenCV.UInt8_Value (255 - O));

   function F16_Vec3_At (O : Natural) return OpenCV.Core.Float16_Vec3.Vector
   is (F16 (16#0001# + Interfaces.Unsigned_16 (O)),
       F16 (16#8000# + Interfaces.Unsigned_16 (O)),
       F16 (16#3C00# + Interfaces.Unsigned_16 (O)));

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

   package UInt8_Checks is new
     ND_Selected_View_Checks
       (OpenCV.UInt8_Value,
        (OpenCV.Core.UInt8, 1),
        "UInt8 C1",
        UInt8_At,
        OpenCV.Core.UInt8_Access.Get,
        OpenCV.Core.UInt8_Access.Set);

   package Int8_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Int8_Value,
        (OpenCV.Core.Int8, 1),
        "Int8 C1",
        Int8_At,
        OpenCV.Core.Int8_Access.Get,
        OpenCV.Core.Int8_Access.Set);

   package UInt16_Checks is new
     ND_Selected_View_Checks
       (OpenCV.UInt16_Value,
        (OpenCV.Core.UInt16, 1),
        "UInt16 C1",
        UInt16_At,
        OpenCV.Core.UInt16_Access.Get,
        OpenCV.Core.UInt16_Access.Set);

   package Int16_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Int16_Value,
        (OpenCV.Core.Int16, 1),
        "Int16 C1",
        Int16_At,
        OpenCV.Core.Int16_Access.Get,
        OpenCV.Core.Int16_Access.Set);

   package Int32_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Int32_Value,
        (OpenCV.Core.Int32, 1),
        "Int32 C1",
        Int32_At,
        OpenCV.Core.Int32_Access.Get,
        OpenCV.Core.Int32_Access.Set);

   package Float16_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Core.Float16_Value,
        (OpenCV.Core.Float16, 1),
        "Float16 C1",
        Float16_At,
        OpenCV.Core.Float16_Access.Get,
        OpenCV.Core.Float16_Access.Set);

   package Float32_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Float32_Value,
        (OpenCV.Core.Float32, 1),
        "Float32 C1",
        Float32_At,
        OpenCV.Core.Float32_Access.Get,
        OpenCV.Core.Float32_Access.Set);

   package Float64_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Float64_Value,
        (OpenCV.Core.Float64, 1),
        "Float64 C1",
        Float64_At,
        OpenCV.Core.Float64_Access.Get,
        OpenCV.Core.Float64_Access.Set);

   package F32_Vec2_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Core.Float32_Vec2.Vector,
        (OpenCV.Core.Float32, 2),
        "Float32 C2",
        F32_Vec2_At,
        OpenCV.Core.Float32_Vec2_Access.Get,
        OpenCV.Core.Float32_Vec2_Access.Set);

   package F64_Vec2_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Core.Float64_Vec2.Vector,
        (OpenCV.Core.Float64, 2),
        "Float64 C2",
        F64_Vec2_At,
        OpenCV.Core.Float64_Vec2_Access.Get,
        OpenCV.Core.Float64_Vec2_Access.Set);

   package U8_Vec3_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Core.UInt8_Vec3.Vector,
        (OpenCV.Core.UInt8, 3),
        "UInt8 C3",
        U8_Vec3_At,
        OpenCV.Core.UInt8_Vec3_Access.Get,
        OpenCV.Core.UInt8_Vec3_Access.Set);

   package F16_Vec3_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Core.Float16_Vec3.Vector,
        (OpenCV.Core.Float16, 3),
        "Float16 C3",
        F16_Vec3_At,
        OpenCV.Core.Float16_Vec3_Access.Get,
        OpenCV.Core.Float16_Vec3_Access.Set);

   package F32_Vec3_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Core.Float32_Vec3.Vector,
        (OpenCV.Core.Float32, 3),
        "Float32 C3",
        F32_Vec3_At,
        OpenCV.Core.Float32_Vec3_Access.Get,
        OpenCV.Core.Float32_Vec3_Access.Set);

   package F64_Vec3_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Core.Float64_Vec3.Vector,
        (OpenCV.Core.Float64, 3),
        "Float64 C3",
        F64_Vec3_At,
        OpenCV.Core.Float64_Vec3_Access.Get,
        OpenCV.Core.Float64_Vec3_Access.Set);

   package F32_Vec4_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Core.Float32_Vec4.Vector,
        (OpenCV.Core.Float32, 4),
        "Float32 C4",
        F32_Vec4_At,
        OpenCV.Core.Float32_Vec4_Access.Get,
        OpenCV.Core.Float32_Vec4_Access.Set);

   package F64_Vec4_Checks is new
     ND_Selected_View_Checks
       (OpenCV.Core.Float64_Vec4.Vector,
        (OpenCV.Core.Float64, 4),
        "Float64 C4",
        F64_Vec4_At,
        OpenCV.Core.Float64_Vec4_Access.Get,
        OpenCV.Core.Float64_Vec4_Access.Set);

   --  Shorthand selectors.
   function Fix
     (Index : OpenCV.Size_Coordinate) return OpenCV.Core.Dimension_Selection
   is ((Kind => OpenCV.Core.Fix_Index, Index => Index));

   function Keep
     (Start, Stop : OpenCV.Size_Coordinate)
      return OpenCV.Core.Dimension_Selection
   is ((Kind => OpenCV.Core.Keep_Range, Bounds => (Start, Stop)));

   --  Canonical Int32 source (2, 3, 2, 4); element (I, J, L, K) holds its
   --  packed ordinal.
   function Int32_Volume return OpenCV.Core.Mat is
      Volume : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 2, 4), Element_Type => (OpenCV.Core.Int32, 1));
   begin
      for I in 0 .. 1 loop
         for J in 0 .. 2 loop
            for L in 0 .. 1 loop
               for K in 0 .. 3 loop
                  OpenCV.Core.Int32_Access.Set
                    (Volume,
                     (OpenCV.Size_Coordinate (I),
                      OpenCV.Size_Coordinate (J),
                      OpenCV.Size_Coordinate (L),
                      OpenCV.Size_Coordinate (K)),
                     OpenCV.Int32_Value (((I * 3 + J) * 2 + L) * 4 + K));
               end loop;
            end loop;
         end loop;
      end loop;
      return Volume;
   end Int32_Volume;

   Middle_Drop : constant OpenCV.Core.Dimension_Selection_Array :=
     (Fix (1), Keep (0, 3), Fix (1), Keep (0, 4));

   procedure Raw_ABI_Rejects_Malformed_Requests (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check_Rejections;
   end Raw_ABI_Rejects_Malformed_Requests;

   procedure Raw_ABI_Creates_Selected_Views (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check_Valid_Views;
   end Raw_ABI_Creates_Selected_Views;

   procedure Raw_ABI_Guards_Source_Storage (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check_Storage_Guard;
   end Raw_ABI_Guards_Source_Storage;

   procedure Raw_ABI_Marks_Temporary_View (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check_Temporary_View;
   end Raw_ABI_Marks_Temporary_View;

   procedure C1_Middle_Drops_Alias_Source (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      UInt8_Checks.Check_Middle_Drop;
      Int8_Checks.Check_Middle_Drop;
      UInt16_Checks.Check_Middle_Drop;
      Int16_Checks.Check_Middle_Drop;
      Int32_Checks.Check_Middle_Drop;
      Float16_Checks.Check_Middle_Drop;
      Float32_Checks.Check_Middle_Drop;
      Float64_Checks.Check_Middle_Drop;
   end C1_Middle_Drops_Alias_Source;

   procedure Vector_Middle_Drops_Alias_Source (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      F32_Vec2_Checks.Check_Middle_Drop;
      F64_Vec2_Checks.Check_Middle_Drop;
      U8_Vec3_Checks.Check_Middle_Drop;
      F16_Vec3_Checks.Check_Middle_Drop;
      F32_Vec3_Checks.Check_Middle_Drop;
      F64_Vec3_Checks.Check_Middle_Drop;
      F32_Vec4_Checks.Check_Middle_Drop;
      F64_Vec4_Checks.Check_Middle_Drop;
   end Vector_Middle_Drops_Alias_Source;

   procedure Range_And_Drop_Offsets_Selection (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (3, 5, 4, 6), Element_Type => (OpenCV.Core.Int32, 1));
      --  Deliberately unusual lower bound: only iteration order matters.
      Selections : constant OpenCV.Core.Dimension_Selection_Array (3 .. 6) :=
        (Fix (2), Keep (1, 4), Fix (1), Keep (2, 6));
      Invoked    : Boolean := False;

      function Ordinal (I, J, L, K : Natural) return OpenCV.Int32_Value
      is (OpenCV.Int32_Value (((I * 5 + J) * 4 + L) * 6 + K));

      procedure Process (View : in out OpenCV.Core.Mat) is
      begin
         Invoked := True;
         AUnit.Assertions.Assert
           (View.Shape = OpenCV.Core.Dimension_Array'(3, 4)
            and then not View.Is_Continuous,
            "range + drop must produce a gapped 3 x 4 view");
         AUnit.Assertions.Assert
           (OpenCV.Core.Int32_Access.Get (View, (0, 0)) = Ordinal (2, 1, 1, 2)
            and then OpenCV.Core.Int32_Access.Get (View, (2, 3))
                     = Ordinal (2, 3, 1, 5),
            "View (0, 0) / (2, 3) must be Source (2, 1, 1, 2) / (2, 3, 1, 5)");
         for J in 0 .. 2 loop
            for K in 0 .. 3 loop
               AUnit.Assertions.Assert
                 (OpenCV.Core.Int32_Access.Get
                    (View,
                     (OpenCV.Size_Coordinate (J), OpenCV.Size_Coordinate (K)))
                  = Ordinal (2, 1 + J, 1, 2 + K),
                  "View (J, K) must be Source (2, 1 + J, 1, 2 + K)");
            end loop;
         end loop;
         OpenCV.Core.Int32_Access.Set (View, (2, 3), -1);
      end Process;
   begin
      for I in 0 .. 2 loop
         for J in 0 .. 4 loop
            for L in 0 .. 3 loop
               for K in 0 .. 5 loop
                  OpenCV.Core.Int32_Access.Set
                    (Source,
                     (OpenCV.Size_Coordinate (I),
                      OpenCV.Size_Coordinate (J),
                      OpenCV.Size_Coordinate (L),
                      OpenCV.Size_Coordinate (K)),
                     Ordinal (I, J, L, K));
               end loop;
            end loop;
         end loop;
      end loop;
      OpenCV.Core.With_Selected_View (Source, Selections, Process'Access);
      AUnit.Assertions.Assert
        (Invoked
         and then OpenCV.Core.Int32_Access.Get (Source, (2, 3, 1, 5)) = -1
         and then OpenCV.Core.Int32_Access.Get (Source, (2, 3, 1, 4))
                  = Ordinal (2, 3, 1, 4),
         "the View write must reach exactly Source (2, 3, 1, 5)");
   end Range_And_Drop_Offsets_Selection;

   procedure Leading_Drop_Plane_Is_Continuous (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Int32, 1));
      Invoked : Natural := 0;

      function Coordinate (Offset : Natural) return OpenCV.Core.Index_Array
      is (OpenCV.Size_Coordinate (Offset / 12),
          OpenCV.Size_Coordinate ((Offset / 4) mod 3),
          OpenCV.Size_Coordinate (Offset mod 4));

      procedure Read
        (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         Invoked := Invoked + 1;
         AUnit.Assertions.Assert
           (Data'Length = 12
            and then (for all Offset in Data'Range =>
                        Data (Offset) = OpenCV.Int32_Value (12 + Offset)),
            "the read-only plane buffer must alias Source (1, *, *)");
      end Read;

      procedure Write
        (Data : aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         Invoked := Invoked + 1;
         AUnit.Assertions.Assert
           (Data'Length = 12, "the writable plane buffer must hold 12");
         for Offset in Data'Range loop
            Data (Offset) := -OpenCV.Int32_Value (Offset) - 1;
         end loop;
      end Write;

      procedure Process (View : in out OpenCV.Core.Mat) is
      begin
         Invoked := Invoked + 1;
         AUnit.Assertions.Assert
           (View.Shape = OpenCV.Core.Dimension_Array'(3, 4)
            and then View.Is_Continuous,
            "a leading drop must produce a continuous 3 x 4 plane");
         AUnit.Assertions.Assert
           (OpenCV.Core.Int32_Access.Get (View, 2, 3) = 23
            and then OpenCV.Core.Int32_Access.Get (View, (1, 2)) = 18,
            "2-D and N-D access must read Source (1, J, K)");
         OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
           (View, Read'Access);
         OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
           (View, Write'Access);
      end Process;
   begin
      for Offset in 0 .. 23 loop
         OpenCV.Core.Int32_Access.Set
           (Source, Coordinate (Offset), OpenCV.Int32_Value (Offset));
      end loop;
      OpenCV.Core.With_Selected_View
        (Source, (Fix (1), Keep (0, 3), Keep (0, 4)), Process'Access);
      AUnit.Assertions.Assert (Invoked = 3, "every callback must run");
      for Offset in 0 .. 23 loop
         AUnit.Assertions.Assert
           (OpenCV.Core.Int32_Access.Get (Source, Coordinate (Offset))
            = (if Offset < 12
               then OpenCV.Int32_Value (Offset)
               else -OpenCV.Int32_Value (Offset - 12) - 1),
            "buffer writes must map to Source (1, *, *) only");
      end loop;
   end Leading_Drop_Plane_Is_Continuous;

   procedure Gapped_View_Borrows_Rows_Only (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source  : OpenCV.Core.Mat := Int32_Volume;
      Invoked : Natural := 0;

      procedure Must_Not_Run
        (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := Invoked + 100;
      end Must_Not_Run;

      procedure Row
        (Data : aliased in out OpenCV.Core.Int32_Row_Access.Row_Array) is
      begin
         Invoked := Invoked + 1;
         AUnit.Assertions.Assert
           (Data'First = 0
            and then Data'Length = 4
            and then Data (0) = 36
            and then Data (3) = 39,
            "row 1 must expose exactly Source (1, 1, 1, 0 .. 3)");
         for K in Data'Range loop
            Data (K) := -OpenCV.Int32_Value (K) - 1;
         end loop;
      end Row;

      procedure Process (View : in out OpenCV.Core.Mat) is
         procedure Attempt_Buffer is
         begin
            OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
              (View, Must_Not_Run'Access);
         end Attempt_Buffer;
      begin
         AUnit.Assertions.Assert
           (not View.Is_Continuous, "the middle-drop view must be gapped");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Buffer'Access,
            "whole-buffer borrowing of a gapped selected view must fail");
         OpenCV.Core.Int32_Row_Access.With_Writable_Row (View, 1, Row'Access);
      end Process;
   begin
      OpenCV.Core.With_Selected_View (Source, Middle_Drop, Process'Access);
      AUnit.Assertions.Assert (Invoked = 1, "only the row callback may run");
      for I in 0 .. 1 loop
         for J in 0 .. 2 loop
            for L in 0 .. 1 loop
               for K in 0 .. 3 loop
                  declare
                     Value : constant OpenCV.Int32_Value :=
                       OpenCV.Core.Int32_Access.Get
                         (Source,
                          (OpenCV.Size_Coordinate (I),
                           OpenCV.Size_Coordinate (J),
                           OpenCV.Size_Coordinate (L),
                           OpenCV.Size_Coordinate (K)));
                  begin
                     AUnit.Assertions.Assert
                       (Value
                        = (if I = 1 and then J = 1 and then L = 1
                           then -OpenCV.Int32_Value (K) - 1
                           else
                             OpenCV.Int32_Value
                               (((I * 3 + J) * 2 + L) * 4 + K)),
                        "the row write must reach only Source (1, 1, 1, *)");
                  end;
               end loop;
            end loop;
         end loop;
      end loop;
   end Gapped_View_Borrows_Rows_Only;

   --  Runs Body_Of while the probe observes the first OpenCV-owned
   --  allocation, always finishing the probe session.
   procedure Observe (Body_Of : not null access procedure) is
      Started : Boolean := False;
   begin
      Probe.Begin_Observation;
      Started := True;
      Body_Of.all;
      Probe.Finish;
      Started := False;
   exception
      when Original : others =>
         if Started then
            begin
               Probe.Finish;
            exception
               when others =>
                  null;
            end;
         end if;
         Ada.Exceptions.Reraise_Occurrence (Original);
   end Observe;

   procedure Storage_Guard_Retains_Released_Source (Test : in out Fixture) is
      pragma Unreferenced (Test);

      procedure Scenario is
         Source : OpenCV.Core.Mat;
         Alias  : OpenCV.Core.Mat;

         procedure Process (View : in out OpenCV.Core.Mat) is
            Empty : OpenCV.Core.Mat;
         begin
            Source := Empty;
            Alias := Empty;
            AUnit.Assertions.Assert
              (Source.Is_Empty
               and then Alias.Is_Empty
               and then Probe.Target_Live
               and then Probe.Deallocation_Count = 0,
               "the selected view must keep the released allocation live");
            AUnit.Assertions.Assert
              (OpenCV.Core.Int32_Access.Get (View, (2, 3)) = 47,
               "the guarded view must remain readable");
            OpenCV.Core.Int32_Access.Set (View, (0, 0), -28);
            AUnit.Assertions.Assert
              (OpenCV.Core.Int32_Access.Get (View, (0, 0)) = -28,
               "the guarded view must remain writable");
         end Process;
      begin
         Source := Int32_Volume;
         AUnit.Assertions.Assert
           (Probe.Target_Captured and then Probe.Target_Size >= 192,
            "the owning N-D source must be the observed allocation");
         Probe.Restore_Default_Allocator;
         Alias := Source;
         OpenCV.Core.With_Selected_View (Source, Middle_Drop, Process'Access);
         AUnit.Assertions.Assert
           (not Probe.Target_Live and then Probe.Deallocation_Count = 1,
            "the allocation must be released exactly once after the view");
      end Scenario;
   begin
      Observe (Scenario'Access);
   end Storage_Guard_Retains_Released_Source;

   procedure Nested_Row_Borrow_Retains_Guard (Test : in out Fixture) is
      pragma Unreferenced (Test);

      procedure Scenario is
         Source : OpenCV.Core.Mat;

         procedure Process (View : in out OpenCV.Core.Mat) is
            procedure Row
              (Data : aliased in out OpenCV.Core.Int32_Row_Access.Row_Array)
            is
               Empty : OpenCV.Core.Mat;
            begin
               --  Source was released before the callback; now drop the
               --  selected header itself.
               View := Empty;
               AUnit.Assertions.Assert
                 (View.Is_Empty
                  and then Probe.Target_Live
                  and then Probe.Deallocation_Count = 0,
                  "the row lease must keep the guarded allocation live");
               AUnit.Assertions.Assert
                 (Data (0) = 44 and then Data (3) = 47,
                  "the leased row must remain readable");
               Data (3) := -47;
               AUnit.Assertions.Assert
                 (Data (3) = -47, "the leased row must remain writable");
            end Row;

            Empty : OpenCV.Core.Mat;
         begin
            Source := Empty;
            OpenCV.Core.Int32_Row_Access.With_Writable_Row
              (View, 2, Row'Access);
            AUnit.Assertions.Assert
              (not Probe.Target_Live and then Probe.Deallocation_Count = 1,
               "the allocation must be released exactly once at lease end");
         end Process;
      begin
         Source := Int32_Volume;
         AUnit.Assertions.Assert
           (Probe.Target_Captured, "the source must be the observed target");
         Probe.Restore_Default_Allocator;
         OpenCV.Core.With_Selected_View (Source, Middle_Drop, Process'Access);
         AUnit.Assertions.Assert
           (Probe.Deallocation_Count = 1,
            "the allocation must not be released twice");
      end Scenario;
   begin
      Observe (Scenario'Access);
   end Nested_Row_Borrow_Retains_Guard;

   procedure Nested_Buffer_Borrow_Retains_Guard (Test : in out Fixture) is
      pragma Unreferenced (Test);

      procedure Scenario is
         Source : OpenCV.Core.Mat;

         procedure Process (View : in out OpenCV.Core.Mat) is
            procedure Buffer
              (Data :
                 aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array)
            is
               Replacement : constant OpenCV.Core.Mat :=
                 OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
            begin
               View := Replacement;
               AUnit.Assertions.Assert
                 (View.Depth = OpenCV.Core.UInt8
                  and then Probe.Target_Live
                  and then Probe.Deallocation_Count = 0,
                  "the buffer lease must keep the guarded allocation live");
               AUnit.Assertions.Assert
                 (Data'Length = 12
                  and then Data (0) = 12
                  and then Data (11) = 23,
                  "the leased plane must remain readable");
               Data (11) := -23;
               AUnit.Assertions.Assert
                 (Data (11) = -23, "the leased plane must remain writable");
            end Buffer;

            Empty : OpenCV.Core.Mat;
         begin
            Source := Empty;
            OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
              (View, Buffer'Access);
            AUnit.Assertions.Assert
              (not Probe.Target_Live and then Probe.Deallocation_Count = 1,
               "the allocation must be released exactly once at lease end");
         end Process;
      begin
         Source :=
           OpenCV.Core.Create
             (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Int32, 1));
         AUnit.Assertions.Assert
           (Probe.Target_Captured, "the source must be the observed target");
         Probe.Restore_Default_Allocator;
         for Offset in 0 .. 23 loop
            OpenCV.Core.Int32_Access.Set
              (Source,
               (OpenCV.Size_Coordinate (Offset / 12),
                OpenCV.Size_Coordinate ((Offset / 4) mod 3),
                OpenCV.Size_Coordinate (Offset mod 4)),
               OpenCV.Int32_Value (Offset));
         end loop;
         OpenCV.Core.With_Selected_View
           (Source, (Fix (1), Keep (0, 3), Keep (0, 4)), Process'Access);
         AUnit.Assertions.Assert
           (Probe.Deallocation_Count = 1,
            "the allocation must not be released twice");
      end Scenario;
   begin
      Observe (Scenario'Access);
   end Nested_Buffer_Borrow_Retains_Guard;

   procedure Float16_Selection_Preserves_Exact_Bits (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Patterns : constant array (0 .. 3) of Interfaces.Unsigned_16 :=
        (16#7C01#, 16#8000#, 16#0001#, 16#03FF#);
      Scalars  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 2, 4), Element_Type => (OpenCV.Core.Float16, 1));
      Pixels   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 2, 4), Element_Type => (OpenCV.Core.Float16, 3));
      Invoked  : Natural := 0;

      procedure Scalar_Process (View : in out OpenCV.Core.Mat) is
      begin
         Invoked := Invoked + 1;
         for P in Patterns'Range loop
            AUnit.Assertions.Assert
              (Bits
                 (OpenCV.Core.Float16_Access.Get
                    (View, (1, OpenCV.Size_Coordinate (P))))
               = Patterns (P),
               "a Float16 C1 selected view must read exact bits");
            OpenCV.Core.Float16_Access.Set
              (View, (2, OpenCV.Size_Coordinate (P)), F16 (Patterns (3 - P)));
         end loop;
      end Scalar_Process;

      procedure Pixel_Process (View : in out OpenCV.Core.Mat) is
         Value : constant OpenCV.Core.Float16_Vec3.Vector :=
           OpenCV.Core.Float16_Vec3_Access.Get (View, (1, 2));
      begin
         Invoked := Invoked + 1;
         AUnit.Assertions.Assert
           (Bits (Value (0)) = 16#7C01#
            and then Bits (Value (1)) = 16#8000#
            and then Bits (Value (2)) = 16#0001#,
            "a Float16 C3 selected view must read exact bits");
         OpenCV.Core.Float16_Vec3_Access.Set
           (View, (2, 3), (F16 (16#03FF#), F16 (16#7C01#), F16 (16#8000#)));
      end Pixel_Process;
   begin
      for P in Patterns'Range loop
         OpenCV.Core.Float16_Access.Set
           (Scalars,
            (1, 1, 1, OpenCV.Size_Coordinate (P)),
            F16 (Patterns (P)));
      end loop;
      OpenCV.Core.Float16_Vec3_Access.Set
        (Pixels,
         (1, 1, 1, 2),
         (F16 (16#7C01#), F16 (16#8000#), F16 (16#0001#)));

      OpenCV.Core.With_Selected_View
        (Scalars, Middle_Drop, Scalar_Process'Access);
      OpenCV.Core.With_Selected_View
        (Pixels, Middle_Drop, Pixel_Process'Access);
      AUnit.Assertions.Assert (Invoked = 2, "both callbacks must run");

      for P in Patterns'Range loop
         AUnit.Assertions.Assert
           (Bits
              (OpenCV.Core.Float16_Access.Get
                 (Scalars, (1, 2, 1, OpenCV.Size_Coordinate (P))))
            = Patterns (3 - P),
            "Float16 C1 selected writes must store exact bits in the source");
      end loop;
      declare
         Written : constant OpenCV.Core.Float16_Vec3.Vector :=
           OpenCV.Core.Float16_Vec3_Access.Get (Pixels, (1, 2, 1, 3));
      begin
         AUnit.Assertions.Assert
           (Bits (Written (0)) = 16#03FF#
            and then Bits (Written (1)) = 16#7C01#
            and then Bits (Written (2)) = 16#8000#,
            "Float16 C3 selected writes must store exact bits in the source");
      end;
   end Float16_Selection_Preserves_Exact_Bits;

   procedure Float64_Selection_Does_Not_Narrow (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Precise_A : constant OpenCV.Float64_Value := 1.0 + 2.0**(-40);
      Precise_B : constant OpenCV.Float64_Value := -2.0 - 2.0**(-42);
      Source    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 2, 4), Element_Type => (OpenCV.Core.Float64, 4));
      Original  : constant OpenCV.Core.Float64_Vec4.Vector :=
        (Precise_A, Precise_B, 3.0 + 2.0**(-44), -Precise_A);
      Written   : constant OpenCV.Core.Float64_Vec4.Vector :=
        (Precise_B, -Precise_A, Precise_A, 5.0 - 2.0**(-41));
      Invoked   : Boolean := False;

      procedure Process (View : in out OpenCV.Core.Mat) is
      begin
         Invoked := True;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec4_Access.Get (View, (0, 1)) = Original,
            "a Float64 C4 selected view must read exact source values");
         OpenCV.Core.Float64_Vec4_Access.Set (View, (2, 2), Written);
      end Process;
   begin
      OpenCV.Core.Float64_Vec4_Access.Set (Source, (1, 0, 1, 1), Original);
      OpenCV.Core.With_Selected_View (Source, Middle_Drop, Process'Access);
      AUnit.Assertions.Assert
        (Invoked
         and then OpenCV.Core.Float64_Vec4_Access.Get (Source, (1, 2, 1, 2))
                  = Written,
         "Float64 C4 selected writes must reach the source without narrowing");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec4_Access.Get (Source, (1, 2, 1, 2)) (0)
         = Precise_B,
         "the 2**-42 component must survive exactly");
   end Float64_Selection_Does_Not_Narrow;

   procedure Selection_From_Existing_Slice (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source  : constant OpenCV.Core.Mat := Int32_Volume;
      --  Ordinary shallow Slice (1 .. 2, 1 .. 3, 0 .. 2, 1 .. 4): a
      --  non-continuous source whose data differs from datastart.
      Slice   : OpenCV.Core.Mat :=
        Source.Slice (((1, 2), (1, 3), (0, 2), (1, 4)));
      Invoked : Boolean := False;

      function Ordinal (I, J, L, K : Natural) return OpenCV.Int32_Value
      is (OpenCV.Int32_Value (((I * 3 + J) * 2 + L) * 4 + K));

      procedure Process (View : in out OpenCV.Core.Mat) is
      begin
         Invoked := True;
         --  Slice (0, J, 1, K) = Source (1, 1 + J, 1, 1 + K).
         AUnit.Assertions.Assert
           (View.Shape = OpenCV.Core.Dimension_Array'(2, 3)
            and then not View.Is_Continuous,
            "a selection from a Slice must be a gapped 2 x 3 view");
         for J in 0 .. 1 loop
            for K in 0 .. 2 loop
               AUnit.Assertions.Assert
                 (OpenCV.Core.Int32_Access.Get
                    (View,
                     (OpenCV.Size_Coordinate (J), OpenCV.Size_Coordinate (K)))
                  = Ordinal (1, 1 + J, 1, 1 + K),
                  "View (J, K) must be Source (1, 1 + J, 1, 1 + K)");
            end loop;
         end loop;
         OpenCV.Core.Int32_Access.Set (View, (1, 2), -1);
      end Process;
   begin
      AUnit.Assertions.Assert
        (not Slice.Is_Continuous and then Slice.Is_Submatrix,
         "the Slice fixture must be a non-continuous submatrix");
      OpenCV.Core.With_Selected_View
        (Slice, (Fix (0), Keep (0, 2), Fix (1), Keep (0, 3)), Process'Access);
      AUnit.Assertions.Assert
        (Invoked
         and then OpenCV.Core.Int32_Access.Get (Source, (1, 2, 1, 3)) = -1
         and then OpenCV.Core.Int32_Access.Get (Slice, (0, 1, 1, 2)) = -1,
         "a write through the selection must reach Source and Slice");
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (Source, (1, 2, 1, 2))
         = Ordinal (1, 2, 1, 2)
         and then OpenCV.Core.Int32_Access.Get (Source, (1, 2, 0, 3))
                  = Ordinal (1, 2, 0, 3),
         "neighbouring source elements must be unchanged");
   end Selection_From_Existing_Slice;

   procedure View_Rejects_Shallow_Escape (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source         : OpenCV.Core.Mat := Int32_Volume;
      Copy           : OpenCV.Core.Mat;
      Input_Invoked  : Boolean := False;
      Output_Invoked : Boolean := False;

      procedure Process (View : in out OpenCV.Core.Mat) is
         procedure Attempt_Copy is
            Alias : OpenCV.Core.Mat;
            pragma Unreferenced (Alias);
         begin
            Alias := View;
         exception
            when Program_Error =>
               raise OpenCV.OpenCV_Error;
         end Attempt_Copy;

         procedure Attempt_Slice is
            Ignored : constant OpenCV.Core.Mat :=
              View.Slice (((0, 1), (0, 4)));
         begin
            null;
         end Attempt_Slice;

         procedure Attempt_Reshape is
            Ignored : constant OpenCV.Core.Mat :=
              View.Reshape (Shape => (4, 3));
         begin
            null;
         end Attempt_Reshape;

         procedure Attempt_Row_View is
            Ignored : constant OpenCV.Core.Mat := View.Row_View (0);
         begin
            null;
         end Attempt_Row_View;

         procedure Attempt_Region is
            Ignored : constant OpenCV.Core.Mat :=
              View.Region ((X => 0, Y => 0, Width => 2, Height => 2));
         begin
            null;
         end Attempt_Region;

         procedure Inspect
           (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle)
         is
            pragma Unreferenced (Handle);
         begin
            Input_Invoked := True;
         end Inspect;

         procedure Output
           (Handle : OpenCV.Core.Module_Interop.Output_Mat_Handle)
         is
            pragma Unreferenced (Handle);
         begin
            Output_Invoked := True;
         end Output;

         procedure Attempt_Output is
         begin
            OpenCV.Core.Module_Interop.With_Output_Handle
              (View, Output'Access);
         end Attempt_Output;
      begin
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Copy'Access, "selected view shallow copy must fail");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Slice'Access, "selected view Slice must fail");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Reshape'Access, "selected view Reshape must fail");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Row_View'Access, "selected view Row_View must fail");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Region'Access, "selected view Region must fail");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Output'Access, "selected view output handle must fail");
         OpenCV.Core.Module_Interop.With_Input_Handle (View, Inspect'Access);
         Copy := View.Clone;
      end Process;
   begin
      OpenCV.Core.With_Selected_View (Source, Middle_Drop, Process'Access);
      AUnit.Assertions.Assert
        (Input_Invoked and then not Output_Invoked,
         "Module_Interop input must work and output must not");

      AUnit.Assertions.Assert
        (Copy.Shape = OpenCV.Core.Dimension_Array'(3, 4)
         and then Copy.Is_Continuous
         and then OpenCV.Core.Int32_Access.Get (Copy, (2, 3)) = 47,
         "Clone must be a continuous owned copy of the selected values");
      OpenCV.Core.Int32_Access.Set (Source, (1, 2, 1, 3), -1);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (Copy, (2, 3)) = 47,
         "later source writes must not reach the Clone");
      OpenCV.Core.Int32_Access.Set (Copy, (0, 0), -2);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (Source, (1, 0, 1, 0)) = 28,
         "Clone writes must not reach the source");
      declare
         Tail : constant OpenCV.Core.Mat := Copy.Slice (((1, 3), (0, 4)));
         Flat : constant OpenCV.Core.Mat := Copy.Reshape (Shape => (4, 3));
      begin
         AUnit.Assertions.Assert
           (Tail.Shape = OpenCV.Core.Dimension_Array'(2, 4)
            and then Flat.Shape = OpenCV.Core.Dimension_Array'(4, 3),
            "an owned Clone must Slice and Reshape normally");
      end;
   end View_Rejects_Shallow_Escape;

   Process_Failure : exception;

   procedure Process_Exception_Propagates (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : OpenCV.Core.Mat := Int32_Volume;
      Raised : Boolean := False;

      procedure Process (View : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Int32_Access.Set (View, (1, 1), -37);
         raise Process_Failure with "selected view callback failure";
      end Process;
   begin
      begin
         OpenCV.Core.With_Selected_View (Source, Middle_Drop, Process'Access);
      exception
         when Error : Process_Failure =>
            Raised :=
              Ada.Exceptions.Exception_Message (Error)
              = "selected view callback failure";
      end;
      AUnit.Assertions.Assert
        (Raised, "the original Process exception must propagate unchanged");
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (Source, (1, 1, 1, 1)) = -37,
         "a write completed before the exception must remain visible");
      OpenCV.Core.Int32_Access.Set (Source, (0, 0, 0, 0), 99);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (Source, (0, 0, 0, 0)) = 99
         and then Source.Shape = OpenCV.Core.Dimension_Array'(2, 3, 2, 4),
         "the source must remain usable after the exception");
   end Process_Exception_Propagates;

   procedure Temporary_External_Source_Rejected (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Storage  : aliased OpenCV.Core.Int32_Mat_View.Buffer_Array :=
        (0 .. 23 => 5);
      Invoked  : Boolean := False;
      Rejected : Boolean := False;

      procedure Inner (View : in out OpenCV.Core.Mat) is
         pragma Unreferenced (View);
      begin
         Invoked := True;
      end Inner;

      procedure Outer (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.With_Selected_View
           (Image, (Fix (1), Keep (0, 3), Keep (0, 4)), Inner'Access);
      exception
         when OpenCV.OpenCV_Error =>
            Rejected := True;
      end Outer;
   begin
      OpenCV.Core.Int32_Mat_View.With_Writable_Mat_View
        (Storage, (2, 3, 4), Outer'Access);
      AUnit.Assertions.Assert
        (Rejected and then not Invoked,
         "a temporary external source must be rejected before Process");
      AUnit.Assertions.Assert
        ((for all Value of Storage => Value = 5),
         "a rejected external selection must leave caller storage intact");
   end Temporary_External_Source_Rejected;

   procedure Invalid_Selections_Rejected_Before_Process (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Source  : OpenCV.Core.Mat := Int32_Volume;
      Empty   : OpenCV.Core.Mat;
      Plane   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.Int32, 1));
      Invoked : Boolean := False;

      procedure Process (View : in out OpenCV.Core.Mat) is
         pragma Unreferenced (View);
      begin
         Invoked := True;
      end Process;

      procedure Expect_Rejected
        (Target     : in out OpenCV.Core.Mat;
         Selections : OpenCV.Core.Dimension_Selection_Array;
         Reason     : String)
      is
         Raised : Boolean := False;
      begin
         Invoked := False;
         begin
            OpenCV.Core.With_Selected_View
              (Target, Selections, Process'Access);
         exception
            when OpenCV.OpenCV_Error =>
               Raised := True;
         end;
         AUnit.Assertions.Assert
           (Raised and then not Invoked,
            Reason & " must raise OpenCV_Error before Process");
      end Expect_Rejected;
   begin
      Expect_Rejected
        (Empty, (Fix (0), Keep (0, 1)), "a default empty source");
      Expect_Rejected (Plane, (Fix (0), Keep (0, 4)), "a 2-D source");
      Expect_Rejected
        (Source, (Fix (1), Keep (0, 3), Keep (0, 4)), "too few selectors");
      Expect_Rejected
        (Source,
         (Fix (1), Keep (0, 3), Fix (1), Keep (0, 4), Keep (0, 1)),
         "too many selectors");
      Expect_Rejected
        (Source,
         (Fix (1), Keep (2, 1), Fix (1), Keep (0, 4)),
         "Keep_Range Start > Stop");
      Expect_Rejected
        (Source,
         (Fix (1), Keep (2, 2), Fix (1), Keep (0, 4)),
         "an empty Keep_Range");
      Expect_Rejected
        (Source,
         (Fix (1), Keep (0, 4), Fix (1), Keep (0, 4)),
         "a Keep_Range past its extent");
      Expect_Rejected
        (Source,
         (Fix (2), Keep (0, 3), Fix (1), Keep (0, 4)),
         "a Fix_Index past its extent");
      Expect_Rejected
        (Source,
         (Keep (0, 2), Keep (0, 3), Keep (0, 2), Keep (0, 4)),
         "no Fix_Index at all");
      Expect_Rejected
        (Source,
         (Fix (1), Fix (1), Fix (1), Keep (0, 4)),
         "only one retained dimension");
      Expect_Rejected
        (Source,
         (Fix (1), Fix (1), Fix (1), Fix (1)),
         "no retained dimensions");
      Expect_Rejected
        (Source,
         (Keep (0, 2), Keep (0, 3), Keep (0, 2), Fix (1)),
         "a fixed final source dimension");
      Expect_Rejected
        (Source,
         (Keep (0, 2), Fix (1), Keep (0, 2), Fix (3)),
         "a fixed final dimension with two kept dimensions");

      AUnit.Assertions.Assert
        (Plane.Rows = 3 and then Empty.Is_Empty,
         "rejected sources must keep their state");
      for I in 0 .. 1 loop
         for J in 0 .. 2 loop
            for L in 0 .. 1 loop
               for K in 0 .. 3 loop
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int32_Access.Get
                       (Source,
                        (OpenCV.Size_Coordinate (I),
                         OpenCV.Size_Coordinate (J),
                         OpenCV.Size_Coordinate (L),
                         OpenCV.Size_Coordinate (K)))
                     = OpenCV.Int32_Value (((I * 3 + J) * 2 + L) * 4 + K),
                     "rejected selections must leave source data unchanged");
               end loop;
            end loop;
         end loop;
      end loop;
   end Invalid_Selections_Rejected_Before_Process;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Selected N-D view raw ABI rejects malformed requests",
            Raw_ABI_Rejects_Malformed_Requests'Access));
      Result.Add_Test
        (Caller.Create
           ("Selected N-D view raw ABI creates plane, gapped, and 3-D views",
            Raw_ABI_Creates_Selected_Views'Access));
      Result.Add_Test
        (Caller.Create
           ("Selected N-D view raw ABI guards source storage and leases",
            Raw_ABI_Guards_Source_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Selected N-D view raw ABI marks a temporary view",
            Raw_ABI_Marks_Temporary_View'Access));
      Result.Add_Test
        (Caller.Create
           ("C1 middle-axis selected views alias the source (x8)",
            C1_Middle_Drops_Alias_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("C2/C3/C4 middle-axis selected views alias the source (x8)",
            Vector_Middle_Drops_Alias_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Range + drop selections offset and drop correctly",
            Range_And_Drop_Offsets_Selection'Access));
      Result.Add_Test
        (Caller.Create
           ("Leading-drop selected plane is continuous and borrowable",
            Leading_Drop_Plane_Is_Continuous'Access));
      Result.Add_Test
        (Caller.Create
           ("Gapped selected view rejects buffer borrow, allows rows",
            Gapped_View_Borrows_Rows_Only'Access));
      Result.Add_Test
        (Caller.Create
           ("Selected view storage guard retains a released source",
            Storage_Guard_Retains_Released_Source'Access));
      Result.Add_Test
        (Caller.Create
           ("Nested row borrow retains the selected storage guard",
            Nested_Row_Borrow_Retains_Guard'Access));
      Result.Add_Test
        (Caller.Create
           ("Nested buffer borrow retains the selected storage guard",
            Nested_Buffer_Borrow_Retains_Guard'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 C1/C3 selected views preserve exact binary16 bits",
            Float16_Selection_Preserves_Exact_Bits'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 C4 selected views do not narrow",
            Float64_Selection_Does_Not_Narrow'Access));
      Result.Add_Test
        (Caller.Create
           ("Selected views compose with an existing N-D Slice",
            Selection_From_Existing_Slice'Access));
      Result.Add_Test
        (Caller.Create
           ("Selected views reject shallow escape; Clone is independent",
            View_Rejects_Shallow_Escape'Access));
      Result.Add_Test
        (Caller.Create
           ("Selected view Process exceptions propagate unchanged",
            Process_Exception_Propagates'Access));
      Result.Add_Test
        (Caller.Create
           ("Selected views reject temporary external sources",
            Temporary_External_Source_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Invalid selections are rejected before Process",
            Invalid_Selections_Rejected_Before_Process'Access));
      return Result'Access;
   end Suite;

end ND_Selected_View_Tests;
