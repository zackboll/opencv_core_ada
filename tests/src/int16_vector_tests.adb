with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Int16_Vec2;
with OpenCV.Core.Int16_Vec3;
with OpenCV.Core.Int16_Vec4;
with OpenCV.Core.Int16_Vec2_Access;
with OpenCV.Core.Int16_Vec3_Access;
with OpenCV.Core.Int16_Vec4_Access;
with OpenCV.Core.Int16_Vec2_Row_Access;
with OpenCV.Core.Int16_Vec3_Row_Access;
with OpenCV.Core.Int16_Vec4_Row_Access;
with OpenCV.Core.Int16_Vec2_Buffer_Access;
with OpenCV.Core.Int16_Vec4_Buffer_Access;
with OpenCV.Core.Int16_Vec3_Buffer_Access;
with Int16_Vector_Tests.Raw_ABI;

package body Int16_Vector_Tests is
   use type OpenCV.Core.Int16_Vec2.Vector;
   use type OpenCV.Core.Int16_Vec3.Vector;
   use type OpenCV.Core.Int16_Vec4.Vector;
   use type OpenCV.Core.Int16_Vec2_Row_Access.Row_Array;
   use type OpenCV.Core.Int16_Vec3_Row_Access.Row_Array;
   use type OpenCV.Core.Int16_Vec4_Row_Access.Row_Array;
   use type OpenCV.Int16_Value;
   use Mat_Test_Support;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   A2 : constant OpenCV.Core.Int16_Vec2.Vector :=
     (OpenCV.Int16_Value'First, OpenCV.Int16_Value'Last);
   A3 : constant OpenCV.Core.Int16_Vec3.Vector := (-32_767, -1, 32_766);
   A4 : constant OpenCV.Core.Int16_Vec4.Vector := (-32_768, 0, 1, 32_767);

   procedure Elements (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2                     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int16, 2));
      M3                     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int16, 3));
      M4                     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int16, 4));
      N2                     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Int16, 2));
      N3                     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Int16, 3));
      N4                     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Int16, 4));
      Indices                : constant OpenCV.Core.Index_Array (7 .. 9) :=
        (1, 2, 3);
      Alias2, Alias3, Alias4 : OpenCV.Core.Mat;
      Copy2, Copy3, Copy4    : OpenCV.Core.Mat;
      procedure Wrong_2D is
         V : constant OpenCV.Core.Int16_Vec2.Vector :=
           OpenCV.Core.Int16_Vec2_Access.Get (N2, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Wrong_2D;
      procedure Wrong_ND is
      begin
         OpenCV.Core.Int16_Vec3_Access.Set (N3, (0, 3, 0), A3);
      end Wrong_ND;
      procedure Wrong_Layout is
         Other : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 4));
         V     : constant OpenCV.Core.Int16_Vec4.Vector :=
           OpenCV.Core.Int16_Vec4_Access.Get (Other, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Wrong_Layout;
   begin
      M2.Set_To (OpenCV.Make_Scalar (-1.0, 1.0));
      M3.Set_To (OpenCV.Make_Scalar (-1.0, 0.0, 1.0));
      M4.Set_To (OpenCV.Make_Scalar (-1.0, 0.0, 1.0, -32_767.0));
      OpenCV.Core.Int16_Vec2_Access.Set (M2, 1, 2, A2);
      OpenCV.Core.Int16_Vec3_Access.Set (M3, 1, 2, A3);
      OpenCV.Core.Int16_Vec4_Access.Set (M4, 1, 2, A4);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int16_Vec2_Access.Get (M2, 1, 2) = A2
         and then OpenCV.Core.Int16_Vec2_Access.Get (M2, 1, 1) = (-1, 1)
         and then OpenCV.Core.Int16_Vec3_Access.Get (M3, 1, 2) = A3
         and then OpenCV.Core.Int16_Vec3_Access.Get (M3, 1, 1) = (-1, 0, 1)
         and then OpenCV.Core.Int16_Vec4_Access.Get (M4, 1, 2) = A4
         and then OpenCV.Core.Int16_Vec4_Access.Get (M4, 1, 1)
                  = (-1, 0, 1, -32_767),
         "signed 2-D pixels and neighbor isolation");
      Alias2 := M2;
      Alias3 := M3;
      Alias4 := M4;
      Copy2 := M2.Clone;
      Copy3 := M3.Clone;
      Copy4 := M4.Clone;
      OpenCV.Core.Int16_Vec2_Access.Set (Alias2, 1, 2, (-1, 0));
      OpenCV.Core.Int16_Vec3_Access.Set (Alias3, 1, 2, (-1, 0, 1));
      OpenCV.Core.Int16_Vec4_Access.Set (Alias4, 1, 2, (-1, 0, 1, 2));
      AUnit.Assertions.Assert
        (OpenCV.Core.Int16_Vec2_Access.Get (M2, 1, 2) = (-1, 0)
         and then OpenCV.Core.Int16_Vec2_Access.Get (Copy2, 1, 2) = A2
         and then OpenCV.Core.Int16_Vec3_Access.Get (M3, 1, 2) = (-1, 0, 1)
         and then OpenCV.Core.Int16_Vec3_Access.Get (Copy3, 1, 2) = A3
         and then OpenCV.Core.Int16_Vec4_Access.Get (M4, 1, 2) = (-1, 0, 1, 2)
         and then OpenCV.Core.Int16_Vec4_Access.Get (Copy4, 1, 2) = A4,
         "shallow assignment shares; Clone isolates all signed layouts");
      OpenCV.Core.Int16_Vec2_Access.Set (N2, Indices, A2);
      OpenCV.Core.Int16_Vec3_Access.Set (N3, Indices, A3);
      OpenCV.Core.Int16_Vec4_Access.Set (N4, Indices, A4);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int16_Vec2_Access.Get (N2, (1, 2, 3)) = A2
         and then OpenCV.Core.Int16_Vec3_Access.Get (N3, Indices) = A3
         and then OpenCV.Core.Int16_Vec4_Access.Get (N4, Indices) = A4,
         "shifted logical N-D indices preserve signed values");
      Alias2 := N2;
      Alias3 := N3;
      Alias4 := N4;
      Copy2 := N2.Clone;
      Copy3 := N3.Clone;
      Copy4 := N4.Clone;
      OpenCV.Core.Int16_Vec2_Access.Set (Alias2, Indices, (-1, 0));
      OpenCV.Core.Int16_Vec3_Access.Set (Alias3, Indices, (-1, 0, 1));
      OpenCV.Core.Int16_Vec4_Access.Set (Alias4, Indices, (-1, 0, 1, 2));
      AUnit.Assertions.Assert
        (OpenCV.Core.Int16_Vec2_Access.Get (N2, Indices) = (-1, 0)
         and then OpenCV.Core.Int16_Vec2_Access.Get (Copy2, Indices) = A2
         and then OpenCV.Core.Int16_Vec3_Access.Get (N3, Indices) = (-1, 0, 1)
         and then OpenCV.Core.Int16_Vec3_Access.Get (Copy3, Indices) = A3
         and then OpenCV.Core.Int16_Vec4_Access.Get (N4, Indices)
                  = (-1, 0, 1, 2)
         and then OpenCV.Core.Int16_Vec4_Access.Get (Copy4, Indices) = A4,
         "genuine N-D assignment and Clone semantics");
      Assert_Raises_OpenCV_Error (Wrong_2D'Access, "2-D API rejects N-D");
      Assert_Raises_OpenCV_Error (Wrong_ND'Access, "N-D extent check");
      Assert_Raises_OpenCV_Error (Wrong_Layout'Access, "exact depth");
   end Elements;

   Lease_Error : exception;
   procedure Rows_And_Leases (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2                : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int16, 2));
      M3                : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int16, 3));
      M4                : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int16, 4));
      R2                : OpenCV.Core.Int16_Vec2_Row_Access.Row_Array (7 .. 8);
      R3                : OpenCV.Core.Int16_Vec3_Row_Access.Row_Array (7 .. 8);
      R4                : OpenCV.Core.Int16_Vec4_Row_Access.Row_Array (7 .. 8);
      Survivor          : constant OpenCV.Core.Mat := M3;
      Survivor2         : constant OpenCV.Core.Mat := M2;
      Survivor4         : constant OpenCV.Core.Mat := M4;
      Parent            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Int16, 3));
      Region            : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      Region_Survivor   : constant OpenCV.Core.Mat := Region;
      Rejected_Callback : Boolean := False;
      procedure Edit2
        (Data : aliased in out OpenCV.Core.Int16_Vec2_Row_Access.Row_Array) is
      begin
         Data (0) := (-1, 1);
      end Edit2;
      procedure Edit3
        (Data : aliased in out OpenCV.Core.Int16_Vec3_Row_Access.Row_Array)
      is
         Replacement : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      begin
         M3 := Replacement;
         Data (1) := (-32_768, 0, 32_767);
         raise Lease_Error;
      end Edit3;
      procedure Edit4
        (Data : aliased in out OpenCV.Core.Int16_Vec4_Row_Access.Row_Array) is
      begin
         Data (0) := A4;
      end Edit4;
      procedure Inspect2
        (Data : aliased OpenCV.Core.Int16_Vec2_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 4 and then Data (2) = (-1, 1),
            "Vec2 whole-buffer count and alias");
      end Inspect2;
      procedure Inspect3
        (Data : aliased OpenCV.Core.Int16_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data (1) = (-32_768, 0, 32_767), "Vec3 completed borrowed write");
      end Inspect3;
      procedure Inspect4
        (Data : aliased OpenCV.Core.Int16_Vec4_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 4 and then Data (2) = A4,
            "Vec4 whole-buffer count and alias");
      end Inspect4;
      procedure Rebind2
        (Data :
           aliased in out OpenCV.Core.Int16_Vec2_Buffer_Access.Buffer_Array)
      is
         Replacement : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      begin
         M2 := Replacement;
         Data (3) := A2;
         raise Lease_Error;
      end Rebind2;
      procedure Rebind4
        (Data :
           aliased in out OpenCV.Core.Int16_Vec4_Buffer_Access.Buffer_Array)
      is
         Replacement : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      begin
         M4 := Replacement;
         Data (3) := A4;
         raise Lease_Error;
      end Rebind4;
      procedure Edit_Region
        (Data : aliased in out OpenCV.Core.Int16_Vec3_Row_Access.Row_Array) is
      begin
         Parent := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Region := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A3;
      end Edit_Region;
      procedure Never
        (Data : aliased OpenCV.Core.Int16_Vec3_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Rejected_Callback := True;
      end Never;
      procedure Bad_Region_Buffer is
      begin
         OpenCV.Core.Int16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Region_Survivor, Never'Access);
      end Bad_Region_Buffer;
   begin
      OpenCV.Core.Int16_Vec2_Row_Access.Write_Row (M2, 1, (7 => A2, 8 => A2));
      OpenCV.Core.Int16_Vec3_Row_Access.Write_Row (M3, 1, (7 => A3, 8 => A3));
      OpenCV.Core.Int16_Vec4_Row_Access.Write_Row (M4, 1, (7 => A4, 8 => A4));
      OpenCV.Core.Int16_Vec2_Row_Access.Read_Row (M2, 1, R2);
      OpenCV.Core.Int16_Vec3_Row_Access.Read_Row (M3, 1, R3);
      OpenCV.Core.Int16_Vec4_Row_Access.Read_Row (M4, 1, R4);
      AUnit.Assertions.Assert
        (R2 = (A2, A2) and then R3 = (A3, A3) and then R4 = (A4, A4),
         "shifted copied rows preserve signed channels");
      OpenCV.Core.Int16_Vec2_Row_Access.With_Writable_Row
        (M2, 1, Edit2'Access);
      OpenCV.Core.Int16_Vec4_Row_Access.With_Writable_Row
        (M4, 1, Edit4'Access);
      OpenCV.Core.Int16_Vec2_Buffer_Access.With_Read_Only_Buffer
        (M2, Inspect2'Access);
      OpenCV.Core.Int16_Vec4_Buffer_Access.With_Read_Only_Buffer
        (M4, Inspect4'Access);
      begin
         OpenCV.Core.Int16_Vec3_Row_Access.With_Writable_Row
           (M3, 1, Edit3'Access);
         AUnit.Assertions.Assert (False, "callback must propagate exception");
      exception
         when Lease_Error =>
            null;
      end;
      OpenCV.Core.Int16_Vec3_Row_Access.With_Read_Only_Row
        (Survivor, 1, Inspect3'Access);
      begin
         OpenCV.Core.Int16_Vec2_Buffer_Access.With_Writable_Buffer
           (M2, Rebind2'Access);
         AUnit.Assertions.Assert
           (False, "Vec2 buffer exception must propagate");
      exception
         when Lease_Error =>
            null;
      end;
      begin
         OpenCV.Core.Int16_Vec4_Buffer_Access.With_Writable_Buffer
           (M4, Rebind4'Access);
         AUnit.Assertions.Assert
           (False, "Vec4 buffer exception must propagate");
      exception
         when Lease_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Int16_Vec2_Access.Get (Survivor2, 1, 1) = A2
         and then OpenCV.Core.Int16_Vec4_Access.Get (Survivor4, 1, 1) = A4,
         "Vec2/Vec4 buffer leases survive rebinding and completed writes");
      AUnit.Assertions.Assert
        (not Region_Survivor.Is_Continuous, "Region has gapped rows");
      OpenCV.Core.Int16_Vec3_Row_Access.With_Writable_Row
        (Region, 1, Edit_Region'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int16_Vec3_Access.Get (Region_Survivor, 1, 1) = A3,
         "Region borrow survives parent and wrapper rebinding");
      Assert_Raises_OpenCV_Error
        (Bad_Region_Buffer'Access, "gapped Vec3 buffer rejected");
      AUnit.Assertions.Assert
        (not Rejected_Callback, "rejected buffer callback not invoked");
   end Rows_And_Leases;

   procedure Channels_And_Transform (Test : in out Fixture) is
      pragma Unreferenced (Test);
      C1     : OpenCV.Core.Mat_Array (1 .. 4) :=
        (others => OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1)));
      Values : constant array (1 .. 4) of OpenCV.Int16_Value :=
        (-32_768, 32_767, -1, 1);
      procedure Check (N : Positive) is
         Source       : OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (1, 1, (OpenCV.Core.Int16, OpenCV.Core.Channel_Count (N)));
         Coefficients : OpenCV.Core.Mat :=
           OpenCV.Core.Create (N, N, (OpenCV.Core.Float32, 1));
      begin
         for I in 1 .. N loop
            OpenCV.Core.Int16_Access.Set (C1 (I), 0, 0, Values (I));
         end loop;
         declare
            Merged : constant OpenCV.Core.Mat :=
              OpenCV.Core.Merge (C1 (1 .. N));
            Parts  : constant OpenCV.Core.Mat_Array := Merged.Split;
         begin
            for I in 1 .. N loop
               AUnit.Assertions.Assert
                 (OpenCV.Core.Int16_Access.Get
                    (Parts (Parts'First + I - 1), 0, 0)
                  = Values (I),
                  "signed Split and Merge component order");
            end loop;
            if N = 2 then
               AUnit.Assertions.Assert
                 (OpenCV.Core.Int16_Vec2_Access.Get (Merged, 0, 0) = A2,
                  "signed Vec2 Merge");
            elsif N = 3 then
               AUnit.Assertions.Assert
                 (OpenCV.Core.Int16_Vec3_Access.Get (Merged, 0, 0)
                  = (-32_768, 32_767, -1),
                  "signed Vec3 Merge");
            else
               AUnit.Assertions.Assert
                 (OpenCV.Core.Int16_Vec4_Access.Get (Merged, 0, 0)
                  = (-32_768, 32_767, -1, 1),
                  "signed Vec4 Merge");
            end if;
         end;
         Source.Set_To (OpenCV.Make_Scalar (-32_768.0, 32_767.0, -1.0, 1.0));
         Coefficients.Set_Identity;
         declare
            Transformed : constant OpenCV.Core.Mat :=
              Source.Transform (Coefficients);
         begin
            if N = 2 then
               AUnit.Assertions.Assert
                 (OpenCV.Core.Int16_Vec2_Access.Get (Transformed, 0, 0) = A2,
                  "Int16 C2 Scalar and identity Transform");
            elsif N = 3 then
               AUnit.Assertions.Assert
                 (OpenCV.Core.Int16_Vec3_Access.Get (Transformed, 0, 0)
                  = (-32_768, 32_767, -1),
                  "Int16 C3 Scalar and identity Transform");
            else
               AUnit.Assertions.Assert
                 (OpenCV.Core.Int16_Vec4_Access.Get (Transformed, 0, 0)
                  = (-32_768, 32_767, -1, 1),
                  "Int16 C4 Scalar and identity Transform");
            end if;
         end;
      end Check;
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 2));
      Expand : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
   begin
      for N in 2 .. 4 loop
         Check (N);
      end loop;
      Source.Set_To (OpenCV.Make_Scalar (-1.0, 32_766.0));
      Expand.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Expand, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Expand, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Expand, 2, 2, 1.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int16_Vec3_Access.Get (Source.Transform (Expand), 0, 0)
         = (-1, 32_766, 1),
         "Int16 C2 to C3 affine Transform");
   end Channels_And_Transform;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Int16 Vec2/3/4 signed elements and ownership", Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Int16 Vec2/3/4 rows and leased buffers", Rows_And_Leases'Access));
      Result.Add_Test
        (Caller.Create
           ("Int16 Vec2/3/4 Merge Split Scalar Transform",
            Channels_And_Transform'Access));
      Result.Add_Test
        (Caller.Create
           ("Int16 Vec2/3/4 raw ABI layout safety", Raw_ABI.Check'Access));
      return Result'Access;
   end Suite;
end Int16_Vector_Tests;
