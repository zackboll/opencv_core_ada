with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Int32_Vec2;
with OpenCV.Core.Int32_Vec3;
with OpenCV.Core.Int32_Vec4;
with OpenCV.Core.Int32_Vec2_Access;
with OpenCV.Core.Int32_Vec3_Access;
with OpenCV.Core.Int32_Vec4_Access;
with OpenCV.Core.Int32_Vec2_Row_Access;
with OpenCV.Core.Int32_Vec3_Row_Access;
with OpenCV.Core.Int32_Vec4_Row_Access;
with OpenCV.Core.Int32_Vec2_Buffer_Access;
with OpenCV.Core.Int32_Vec3_Buffer_Access;
with OpenCV.Core.Int32_Vec4_Buffer_Access;
with OpenCV.Core.Int32_Vec2_Mat_View;
with OpenCV.Core.Int32_Vec3_Mat_View;
with OpenCV.Core.Int32_Vec4_Mat_View;
with Int32_Vector_Tests.Raw_ABI;

package body Int32_Vector_Tests is
   use Mat_Test_Support;
   use type OpenCV.Core.Int32_Vec2.Vector;
   use type OpenCV.Core.Int32_Vec3.Vector;
   use type OpenCV.Core.Int32_Vec4.Vector;
   use type OpenCV.Core.Int32_Vec2_Row_Access.Row_Array;
   use type OpenCV.Core.Int32_Vec3_Row_Access.Row_Array;
   use type OpenCV.Core.Int32_Vec4_Row_Access.Row_Array;
   use type OpenCV.Int32_Value;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   A2     : constant OpenCV.Core.Int32_Vec2.Vector :=
     (OpenCV.Int32_Value'First, OpenCV.Int32_Value'Last);
   A3     : constant OpenCV.Core.Int32_Vec3.Vector :=
     (-2_147_483_647, -1, 2_147_483_646);
   A4     : constant OpenCV.Core.Int32_Vec4.Vector :=
     (OpenCV.Int32_Value'First, 0, 1, OpenCV.Int32_Value'Last);

   procedure Elements (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2                                          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int32, 2));
      M3                                          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int32, 3));
      M4                                          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int32, 4));
      N2                                          : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Int32, 2));
      N3                                          : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Int32, 3));
      N4                                          : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Int32, 4));
      Indices                                     :
        constant OpenCV.Core.Index_Array (7 .. 9) := (1, 2, 3);
      Alias2, Alias3, Alias4, Copy2, Copy3, Copy4 : OpenCV.Core.Mat;
      procedure Bad_2D is
         V : constant OpenCV.Core.Int32_Vec2.Vector :=
           OpenCV.Core.Int32_Vec2_Access.Get (N2, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Bad_2D;
      procedure Bad_ND is
      begin
         OpenCV.Core.Int32_Vec3_Access.Set (N3, (0, 3, 0), A3);
      end Bad_ND;
      procedure Bad_Type is
         V : constant OpenCV.Core.Int32_Vec4.Vector :=
           OpenCV.Core.Int32_Vec4_Access.Get (M3, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Type;
   begin
      OpenCV.Core.Int32_Vec2_Access.Set (M2, 1, 2, A2);
      OpenCV.Core.Int32_Vec3_Access.Set (M3, 1, 2, A3);
      OpenCV.Core.Int32_Vec4_Access.Set (M4, 1, 2, A4);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Vec2_Access.Get (M2, 1, 2) = A2
         and then OpenCV.Core.Int32_Vec3_Access.Get (M3, 1, 2) = A3
         and then OpenCV.Core.Int32_Vec4_Access.Get (M4, 1, 2) = A4,
         "2-D exact signed range");
      Alias2 := M2;
      Alias3 := M3;
      Alias4 := M4;
      Copy2 := M2.Clone;
      Copy3 := M3.Clone;
      Copy4 := M4.Clone;
      OpenCV.Core.Int32_Vec2_Access.Set (Alias2, 1, 2, (-1, 0));
      OpenCV.Core.Int32_Vec3_Access.Set (Alias3, 1, 2, (-1, 0, 1));
      OpenCV.Core.Int32_Vec4_Access.Set (Alias4, 1, 2, (-1, 0, 1, 2));
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Vec2_Access.Get (M2, 1, 2) = (-1, 0)
         and then OpenCV.Core.Int32_Vec2_Access.Get (Copy2, 1, 2) = A2
         and then OpenCV.Core.Int32_Vec3_Access.Get (M3, 1, 2) = (-1, 0, 1)
         and then OpenCV.Core.Int32_Vec3_Access.Get (Copy3, 1, 2) = A3
         and then OpenCV.Core.Int32_Vec4_Access.Get (M4, 1, 2) = (-1, 0, 1, 2)
         and then OpenCV.Core.Int32_Vec4_Access.Get (Copy4, 1, 2) = A4,
         "2-D assignment shares and Clone isolates");
      OpenCV.Core.Int32_Vec2_Access.Set (N2, Indices, A2);
      OpenCV.Core.Int32_Vec3_Access.Set (N3, Indices, A3);
      OpenCV.Core.Int32_Vec4_Access.Set (N4, Indices, A4);
      Alias2 := N2;
      Alias3 := N3;
      Alias4 := N4;
      Copy2 := N2.Clone;
      Copy3 := N3.Clone;
      Copy4 := N4.Clone;
      OpenCV.Core.Int32_Vec2_Access.Set (Alias2, Indices, (-1, 0));
      OpenCV.Core.Int32_Vec3_Access.Set (Alias3, Indices, (-1, 0, 1));
      OpenCV.Core.Int32_Vec4_Access.Set (Alias4, Indices, (-1, 0, 1, 2));
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Vec2_Access.Get (N2, (1, 2, 3)) = (-1, 0)
         and then OpenCV.Core.Int32_Vec2_Access.Get (Copy2, Indices) = A2
         and then OpenCV.Core.Int32_Vec3_Access.Get (N3, Indices) = (-1, 0, 1)
         and then OpenCV.Core.Int32_Vec3_Access.Get (Copy3, Indices) = A3
         and then OpenCV.Core.Int32_Vec4_Access.Get (N4, Indices)
                  = (-1, 0, 1, 2)
         and then OpenCV.Core.Int32_Vec4_Access.Get (Copy4, Indices) = A4,
         "shifted N-D indices, assignment and Clone");
      Assert_Raises_OpenCV_Error (Bad_2D'Access, "2-D accessor rejects N-D");
      Assert_Raises_OpenCV_Error (Bad_ND'Access, "N-D extent rejected");
      Assert_Raises_OpenCV_Error (Bad_Type'Access, "exact channels required");
   end Elements;

   Lease_Error : exception;
   procedure Rows_And_Leases (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 2));
      M3              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 3));
      M4              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Int32, 4));
      Parent          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Int32, 3));
      Region          : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      Survivor2       : constant OpenCV.Core.Mat := M2;
      Survivor3       : constant OpenCV.Core.Mat := M3;
      Survivor4       : constant OpenCV.Core.Mat := M4;
      Region_Survivor : constant OpenCV.Core.Mat := Region;
      R2              : OpenCV.Core.Int32_Vec2_Row_Access.Row_Array (7 .. 8);
      R3              : OpenCV.Core.Int32_Vec3_Row_Access.Row_Array (7 .. 8);
      R4              : OpenCV.Core.Int32_Vec4_Row_Access.Row_Array (7 .. 8);
      Called          : Boolean := False;
      procedure Edit2
        (Data : aliased in out OpenCV.Core.Int32_Vec2_Row_Access.Row_Array) is
      begin
         M2 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A2;
         raise Lease_Error;
      end Edit2;
      procedure Edit3
        (Data : aliased in out OpenCV.Core.Int32_Vec3_Row_Access.Row_Array) is
      begin
         M3 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A3;
         raise Lease_Error;
      end Edit3;
      procedure Edit4
        (Data : aliased in out OpenCV.Core.Int32_Vec4_Row_Access.Row_Array) is
      begin
         M4 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A4;
         raise Lease_Error;
      end Edit4;
      procedure Edit_Region
        (Data : aliased in out OpenCV.Core.Int32_Vec3_Row_Access.Row_Array) is
      begin
         Parent := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Region := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A3;
      end Edit_Region;
      procedure Read2
        (Data : aliased OpenCV.Core.Int32_Vec2_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert (Data (1) = A2, "borrowed Vec2 row");
      end Read2;
      procedure Read3
        (Data : aliased OpenCV.Core.Int32_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert (Data (1) = A3, "borrowed Vec3 row");
      end Read3;
      procedure Read4
        (Data : aliased OpenCV.Core.Int32_Vec4_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert (Data (1) = A4, "borrowed Vec4 row");
      end Read4;
      procedure Never
        (Data : aliased OpenCV.Core.Int32_Vec3_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Called := True;
      end Never;
      procedure Bad_Buffer is
      begin
         OpenCV.Core.Int32_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Region_Survivor, Never'Access);
      end Bad_Buffer;
   begin
      OpenCV.Core.Int32_Vec2_Row_Access.Write_Row (M2, 1, (7 => A2, 8 => A2));
      OpenCV.Core.Int32_Vec3_Row_Access.Write_Row (M3, 1, (7 => A3, 8 => A3));
      OpenCV.Core.Int32_Vec4_Row_Access.Write_Row (M4, 1, (7 => A4, 8 => A4));
      OpenCV.Core.Int32_Vec2_Row_Access.Read_Row (M2, 1, R2);
      OpenCV.Core.Int32_Vec3_Row_Access.Read_Row (M3, 1, R3);
      OpenCV.Core.Int32_Vec4_Row_Access.Read_Row (M4, 1, R4);
      AUnit.Assertions.Assert
        (R2 = (A2, A2) and then R3 = (A3, A3) and then R4 = (A4, A4),
         "shifted copied rows preserve exact signed channels");
      OpenCV.Core.Int32_Vec2_Row_Access.With_Read_Only_Row
        (M2, 1, Read2'Access);
      OpenCV.Core.Int32_Vec3_Row_Access.With_Read_Only_Row
        (M3, 1, Read3'Access);
      OpenCV.Core.Int32_Vec4_Row_Access.With_Read_Only_Row
        (M4, 1, Read4'Access);
      begin
         OpenCV.Core.Int32_Vec2_Row_Access.With_Writable_Row
           (M2, 1, Edit2'Access);
         AUnit.Assertions.Assert (False, "Vec2 row exception must propagate");
      exception
         when Lease_Error =>
            null;
      end;
      begin
         OpenCV.Core.Int32_Vec3_Row_Access.With_Writable_Row
           (M3, 1, Edit3'Access);
         AUnit.Assertions.Assert (False, "Vec3 row exception must propagate");
      exception
         when Lease_Error =>
            null;
      end;
      begin
         OpenCV.Core.Int32_Vec4_Row_Access.With_Writable_Row
           (M4, 1, Edit4'Access);
         AUnit.Assertions.Assert (False, "Vec4 row exception must propagate");
      exception
         when Lease_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Vec2_Access.Get (Survivor2, 1, 1) = A2
         and then OpenCV.Core.Int32_Vec3_Access.Get (Survivor3, 1, 1) = A3
         and then OpenCV.Core.Int32_Vec4_Access.Get (Survivor4, 1, 1) = A4,
         "borrowed row survives rebinding and callback exception");
      OpenCV.Core.Int32_Vec3_Row_Access.With_Writable_Row
        (Region, 1, Edit_Region'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Vec3_Access.Get (Region_Survivor, 1, 1) = A3,
         "Region row survives parent and Region rebinding");
      Assert_Raises_OpenCV_Error (Bad_Buffer'Access, "gapped buffer rejected");
      AUnit.Assertions.Assert (not Called, "rejected callback not invoked");
   end Rows_And_Leases;

   procedure Buffers_And_Views (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 2));
      M3        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 3));
      M4        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 4));
      Survivor2 : constant OpenCV.Core.Mat := M2;
      Survivor3 : constant OpenCV.Core.Mat := M3;
      Survivor4 : constant OpenCV.Core.Mat := M4;
      B2        : aliased OpenCV.Core.Int32_Vec2_Mat_View.Buffer_Array :=
        (0 .. 3 => (others => 0));
      B3        : aliased OpenCV.Core.Int32_Vec3_Mat_View.Buffer_Array :=
        (0 .. 3 => (others => 0));
      B4        : aliased OpenCV.Core.Int32_Vec4_Mat_View.Buffer_Array :=
        (0 .. 3 => (others => 0));
      procedure Edit2
        (Data :
           aliased in out OpenCV.Core.Int32_Vec2_Buffer_Access.Buffer_Array) is
      begin
         M2 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A2;
         raise Lease_Error;
      end Edit2;
      procedure Edit3
        (Data :
           aliased in out OpenCV.Core.Int32_Vec3_Buffer_Access.Buffer_Array) is
      begin
         M3 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A3;
         raise Lease_Error;
      end Edit3;
      procedure Edit4
        (Data :
           aliased in out OpenCV.Core.Int32_Vec4_Buffer_Access.Buffer_Array) is
      begin
         M4 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A4;
         raise Lease_Error;
      end Edit4;
      procedure View2 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Int32_Vec2_Access.Set (Image, 1, 1, A2);
      end View2;
      procedure View3 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Int32_Vec3_Access.Set (Image, 1, 1, A3);
      end View3;
      procedure View4 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Int32_Vec4_Access.Set (Image, 1, 1, A4);
      end View4;
      procedure Strided2 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Int32_Vec2_Access.Set (Image, 1, 1, A2);
      end Strided2;
      procedure Strided3 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Int32_Vec3_Access.Set (Image, 1, 1, A3);
      end Strided3;
      procedure Strided4 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Int32_Vec4_Access.Set (Image, 1, 1, A4);
      end Strided4;
      procedure Inspect2 (Image : OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int32_Vec2_Access.Get (Image, 1, 1) = A2,
            "read-only strided Vec2");
      end Inspect2;
      procedure Inspect3 (Image : OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int32_Vec3_Access.Get (Image, 1, 1) = A3,
            "read-only strided Vec3");
      end Inspect3;
      procedure Inspect4 (Image : OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int32_Vec4_Access.Get (Image, 1, 1) = A4,
            "read-only strided Vec4");
      end Inspect4;
   begin
      begin
         OpenCV.Core.Int32_Vec2_Buffer_Access.With_Writable_Buffer
           (M2, Edit2'Access);
         AUnit.Assertions.Assert (False, "Vec2 buffer exception");
      exception
         when Lease_Error =>
            null;
      end;
      begin
         OpenCV.Core.Int32_Vec3_Buffer_Access.With_Writable_Buffer
           (M3, Edit3'Access);
         AUnit.Assertions.Assert (False, "Vec3 buffer exception");
      exception
         when Lease_Error =>
            null;
      end;
      begin
         OpenCV.Core.Int32_Vec4_Buffer_Access.With_Writable_Buffer
           (M4, Edit4'Access);
         AUnit.Assertions.Assert (False, "Vec4 buffer exception");
      exception
         when Lease_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Vec2_Access.Get (Survivor2, 0, 1) = A2
         and then OpenCV.Core.Int32_Vec3_Access.Get (Survivor3, 0, 1) = A3
         and then OpenCV.Core.Int32_Vec4_Access.Get (Survivor4, 0, 1) = A4,
         "whole-buffer leases retain exact writes after exception");
      OpenCV.Core.Int32_Vec2_Mat_View.With_Writable_Mat_View
        (B2, 2, 2, View2'Access);
      OpenCV.Core.Int32_Vec3_Mat_View.With_Writable_Mat_View
        (B3, 2, 2, View3'Access);
      OpenCV.Core.Int32_Vec4_Mat_View.With_Writable_Mat_View
        (B4, 2, 2, View4'Access);
      AUnit.Assertions.Assert
        (B2 (3) = A2 and then B3 (3) = A3 and then B4 (3) = A4,
         "packed views write caller-owned complete elements");
      OpenCV.Core.Int32_Vec2_Mat_View.With_Read_Only_Strided_Mat_View
        (B2, 2, 2, 2, Inspect2'Access);
      OpenCV.Core.Int32_Vec3_Mat_View.With_Read_Only_Strided_Mat_View
        (B3, 2, 2, 2, Inspect3'Access);
      OpenCV.Core.Int32_Vec4_Mat_View.With_Read_Only_Strided_Mat_View
        (B4, 2, 2, 2, Inspect4'Access);
      declare
         G2 : aliased OpenCV.Core.Int32_Vec2_Mat_View.Buffer_Array :=
           (0 .. 5 => (others => 0));
         G3 : aliased OpenCV.Core.Int32_Vec3_Mat_View.Buffer_Array :=
           (0 .. 5 => (others => 0));
         G4 : aliased OpenCV.Core.Int32_Vec4_Mat_View.Buffer_Array :=
           (0 .. 5 => (others => 0));
      begin
         OpenCV.Core.Int32_Vec2_Mat_View.With_Writable_Strided_Mat_View
           (G2, 2, 2, 3, Strided2'Access);
         OpenCV.Core.Int32_Vec3_Mat_View.With_Writable_Strided_Mat_View
           (G3, 2, 2, 3, Strided3'Access);
         OpenCV.Core.Int32_Vec4_Mat_View.With_Writable_Strided_Mat_View
           (G4, 2, 2, 3, Strided4'Access);
         AUnit.Assertions.Assert
           (G2 (4) = A2 and then G3 (4) = A3 and then G4 (4) = A4,
            "row strides count complete vectors, not scalar channels");
      end;
   end Buffers_And_Views;

   procedure Channels_And_Transform (Test : in out Fixture) is
      pragma Unreferenced (Test);
      C1     : OpenCV.Core.Mat_Array (1 .. 4) :=
        (others => OpenCV.Core.Create (1, 1, (OpenCV.Core.Int32, 1)));
      Values : constant array (1 .. 4) of OpenCV.Int32_Value :=
        (OpenCV.Int32_Value'First, OpenCV.Int32_Value'Last, -1, 1);
      procedure Check (N : Positive) is
         Source       : OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (1, 1, (OpenCV.Core.Int32, OpenCV.Core.Channel_Count (N)));
         Coefficients : OpenCV.Core.Mat :=
           OpenCV.Core.Create (N, N, (OpenCV.Core.Float64, 1));
      begin
         for I in 1 .. N loop
            OpenCV.Core.Int32_Access.Set (C1 (I), 0, 0, Values (I));
         end loop;
         declare
            Merged : constant OpenCV.Core.Mat :=
              OpenCV.Core.Merge (C1 (1 .. N));
            Parts  : constant OpenCV.Core.Mat_Array := Merged.Split;
         begin
            for I in 1 .. N loop
               AUnit.Assertions.Assert
                 (OpenCV.Core.Int32_Access.Get
                    (Parts (Parts'First + I - 1), 0, 0)
                  = Values (I),
                  "Int32 Merge Split exact signed components");
            end loop;
            case N is
               when 2      =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int32_Vec2_Access.Get (Merged, 0, 0) = A2,
                     "Vec2 Merge");

               when 3      =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int32_Vec3_Access.Get (Merged, 0, 0)
                     = (Values (1), Values (2), Values (3)),
                     "Vec3 Merge");

               when others =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int32_Vec4_Access.Get (Merged, 0, 0)
                     = (Values (1), Values (2), Values (3), Values (4)),
                     "Vec4 Merge");
            end case;
         end;
         Source.Set_To
           (OpenCV.Make_Scalar (-123_456_789.0, 123_456_789.0, -1.0, 1.0));
         Coefficients.Set_Identity;
         declare
            Transformed : constant OpenCV.Core.Mat :=
              Source.Transform (Coefficients);
         begin
            case N is
               when 2      =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int32_Vec2_Access.Get (Transformed, 0, 0)
                     = (-123_456_789, 123_456_789),
                     "Vec2 Scalar Transform");

               when 3      =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int32_Vec3_Access.Get (Transformed, 0, 0)
                     = (-123_456_789, 123_456_789, -1),
                     "Vec3 Scalar Transform");

               when others =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int32_Vec4_Access.Get (Transformed, 0, 0)
                     = (-123_456_789, 123_456_789, -1, 1),
                     "Vec4 Scalar Transform");
            end case;
         end;
      end Check;
      Source : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int32, 2));
      Expand : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float64, 1));
   begin
      for N in 2 .. 4 loop
         Check (N);
      end loop;
      Source.Set_To (OpenCV.Make_Scalar (-5.0, 7.0));
      Expand.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Float64_Access.Set (Expand, 0, 0, 1.0);
      OpenCV.Core.Float64_Access.Set (Expand, 1, 1, 1.0);
      OpenCV.Core.Float64_Access.Set (Expand, 2, 2, 1.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Vec3_Access.Get (Source.Transform (Expand), 0, 0)
         = (-5, 7, 1),
         "Int32 C2 to C3 affine Transform");
   end Channels_And_Transform;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Int32 Vec2/3/4 exact signed elements and ownership",
            Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Int32 Vec2/3/4 copied rows and borrowed leases",
            Rows_And_Leases'Access));
      Result.Add_Test
        (Caller.Create
           ("Int32 Vec2/3/4 whole buffers and caller views",
            Buffers_And_Views'Access));
      Result.Add_Test
        (Caller.Create
           ("Int32 Vec2/3/4 Merge Split Scalar Transform",
            Channels_And_Transform'Access));
      Result.Add_Test
        (Caller.Create
           ("Int32 Vec2/3/4 raw ABI layout and geometry",
            Raw_ABI.Check'Access));
      return Result'Access;
   end Suite;
end Int32_Vector_Tests;
