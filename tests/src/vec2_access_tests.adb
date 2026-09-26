with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float32_Vec2;
with OpenCV.Core.Float64_Vec2;
with OpenCV.Core.Float32_Vec2_Access;
with OpenCV.Core.Float64_Vec2_Access;
with OpenCV.Core.Float32_Vec2_Row_Access;
with OpenCV.Core.Float64_Vec2_Row_Access;
with OpenCV.Core.Float32_Vec2_Buffer_Access;
with OpenCV.Core.Float64_Vec2_Buffer_Access;
with OpenCV.Core.Float32_Vec2_Mat_View;
with OpenCV.Core.Float64_Vec2_Mat_View;
with Vec2_Access_Tests.Raw_ABI;

package body Vec2_Access_Tests is
   use OpenCV;
   use type OpenCV.Core.Float32_Vec2.Vector;
   use type OpenCV.Core.Float64_Vec2.Vector;
   use type OpenCV.Float32_Value;
   use type OpenCV.Float64_Value;
   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   procedure Float32_Elements_And_Spectrum (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      package V renames Float32_Vec2_Access;
      Image  : Mat := Create (2, 3, (Float32, 2));
      Volume : Mat :=
        Create (Shape => (2, 3, 4), Element_Type => (Float32, 2));
      Source : Mat := Create (1, 4, (Float32, 1));
      A      : Mat := Create (1, 2, (Float32, 2));
      B      : Mat := Create (1, 2, (Float32, 2));
   begin
      V.Set (Image, 1, 2, (2.0, 3.0));
      AUnit.Assertions.Assert
        (V.Get (Image, 1, 2) = (2.0, 3.0), "Float32 C2 round trip");
      declare
         Alias : Mat := Image;
         Copy  : constant Mat := Image.Clone;
      begin
         V.Set (Alias, 1, 2, (4.0, 5.0));
         AUnit.Assertions.Assert
           (V.Get (Image, 1, 2) = (4.0, 5.0)
            and then V.Get (Copy, 1, 2) = (2.0, 3.0),
            "sharing and clone");
      end;
      V.Set (Volume, (0, 2, 3), (10.0, 11.0));
      V.Set (Volume, (5 => 1, 6 => 2, 7 => 3), (6.0, 7.0));
      AUnit.Assertions.Assert
        (V.Get (Volume, (0, 2, 3)) = (10.0, 11.0),
         "N-D axis order and neighbor isolation");
      AUnit.Assertions.Assert
        (V.Get (Volume, (1, 2, 3)) = (6.0, 7.0), "shifted index bounds");
      V.Set (Image, (0, 1), (8.0, 9.0));
      AUnit.Assertions.Assert
        (V.Get (Image, 0, 1) = (8.0, 9.0), "2-D N-D agreement");
      for Col in 0 .. 3 loop
         OpenCV.Core.Float32_Access.Set
           (Source, 0, Col, (if Col = 0 then 1.0 else 0.0));
      end loop;
      declare
         Spectrum : constant Mat := Source.Discrete_Fourier_Transform;
      begin
         AUnit.Assertions.Assert
           (Spectrum.Depth = Float32 and then Spectrum.Channels = 2,
            "DFT output is Float32 C2");
         for Col in 0 .. 3 loop
            declare
               Bin : constant Float32_Vec2.Vector := V.Get (Spectrum, 0, Col);
            begin
               AUnit.Assertions.Assert
                 (abs (Bin (0) - 1.0) < 0.0001 and then abs Bin (1) < 0.0001,
                  "impulse bin real/imaginary");
            end;
         end loop;
         AUnit.Assertions.Assert
           (not Spectrum.Inverse_Discrete_Fourier_Transform.Is_Empty,
            "full-complex inverse accepts Vec2 Mat");
      end;
      V.Set (A, 0, 0, (2.0, 3.0));
      V.Set (B, 0, 0, (4.0, 5.0));
      declare
         Product : constant Mat := Multiply_Spectra (A, B);
      begin
         AUnit.Assertions.Assert
           (V.Get (Product, 0, 0) = (-7.0, 22.0),
            "complex spectrum multiplication");
      end;
   end Float32_Elements_And_Spectrum;

   procedure Float64_Elements_And_Spectrum (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      package V renames Float64_Vec2_Access;
      Precise : constant OpenCV.Float64_Value := 1.0 + 2.0**(-40);
      Image   : Mat := Create (1, 4, (Float64, 2));
      Volume  : Mat :=
        Create (Shape => (2, 3, 4), Element_Type => (Float64, 2));
      Source  : Mat := Create (1, 4, (Float64, 1));
   begin
      V.Set (Image, 0, 2, (Precise, -Precise));
      AUnit.Assertions.Assert
        (V.Get (Image, 0, 2) = (Precise, -Precise),
         "binary64 C2 must not narrow");
      V.Set (Volume, (8 => 1, 9 => 2, 10 => 3), (Precise, 2.0));
      AUnit.Assertions.Assert
        (V.Get (Volume, (1, 2, 3)) = (Precise, 2.0), "binary64 N-D transport");
      for Col in 0 .. 3 loop
         OpenCV.Core.Float64_Access.Set
           (Source, 0, Col, (if Col = 0 then 1.0 else 0.0));
      end loop;
      declare
         Right : Mat := Create (1, 4, (Float64, 2));
      begin
         V.Set (Right, 0, 0, (4.0, 5.0));
         V.Set (Image, 0, 0, (2.0, 3.0));
         declare
            Product : constant Mat := Multiply_Spectra (Image, Right);
         begin
            AUnit.Assertions.Assert
              (V.Get (Product, 0, 0) = (-7.0, 22.0),
               "Float64 complex spectrum product");
         end;
      end;
      declare
         Spectrum : constant Mat := Source.Discrete_Fourier_Transform;
      begin
         AUnit.Assertions.Assert
           (Spectrum.Depth = Float64 and then Spectrum.Channels = 2,
            "DFT output is Float64 C2");
         for Col in 0 .. 3 loop
            declare
               Bin : constant Float64_Vec2.Vector := V.Get (Spectrum, 0, Col);
            begin
               AUnit.Assertions.Assert
                 (abs (Bin (0) - 1.0) < 1.0E-12 and then abs Bin (1) < 1.0E-12,
                  "Float64 impulse bin");
            end;
         end loop;
         AUnit.Assertions.Assert
           (not Spectrum.Inverse_Discrete_Fourier_Transform.Is_Empty,
            "Float64 full-complex inverse accepts typed spectrum");
      end;
   end Float64_Elements_And_Spectrum;

   procedure Float32_Rows_Buffers_Views (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      package V renames Float32_Vec2_Access;
      package R renames Float32_Vec2_Row_Access;
      package B renames Float32_Vec2_Buffer_Access;
      package E renames Float32_Vec2_Mat_View;
      Image   : Mat := Create (2, 3, (Float32, 2));
      Row     : aliased R.Row_Array (5 .. 7) := (others => (2.0, 3.0));
      Backing : aliased E.Buffer_Array := (5 .. 12 => (9.0, 9.0));
      procedure Observe (Data : aliased B.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 6 and then Data (2) = (2.0, 3.0),
            "borrow complete C2 elements");
      end Observe;
      procedure Change (Data : aliased in out R.Row_Array) is
      begin
         Data (0) := (4.0, 5.0);
         AUnit.Assertions.Assert
           (V.Get (Image, 0, 0) = (4.0, 5.0), "row write immediately visible");
      end Change;
      procedure View (M : in out Mat) is
      begin
         AUnit.Assertions.Assert
           (V.Get (M, 1, 2) = (9.0, 9.0), "strided final logical element");
         V.Set (M, 0, 0, (7.0, 8.0));
      end View;
   begin
      R.Write_Row (Image, 0, Row);
      R.Read_Row (Image, 0, Row);
      AUnit.Assertions.Assert (Row (7) = (2.0, 3.0), "shifted copied row");
      B.With_Read_Only_Buffer (Image, Observe'Access);
      R.With_Writable_Row (Image, 0, Change'Access);
      E.With_Writable_Strided_Mat_View (Backing, 2, 3, 4, View'Access);
      AUnit.Assertions.Assert
        (Backing (5) = (7.0, 8.0)
         and then Backing (8) = (9.0, 9.0)
         and then Backing (12) = (9.0, 9.0),
         "external view aliases data but leaves padding unchanged");
   end Float32_Rows_Buffers_Views;

   procedure Float64_Rows_Buffers_Views (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      package V renames Float64_Vec2_Access;
      package R renames Float64_Vec2_Row_Access;
      package B renames Float64_Vec2_Buffer_Access;
      package E renames Float64_Vec2_Mat_View;
      Precise : constant OpenCV.Float64_Value := 1.0 + 2.0**(-40);
      Image   : Mat := Create (2, 3, (Float64, 2));
      Row     : aliased R.Row_Array (5 .. 7) :=
        (others => (Precise, -Precise));
      Backing : aliased E.Buffer_Array := (5 .. 12 => (9.0, 9.0));
      procedure Observe (Data : aliased B.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 6 and then Data (2) = (Precise, -Precise),
            "borrow binary64 C2 elements");
      end Observe;
      procedure Change (Data : aliased in out R.Row_Array) is
      begin
         Data (0) := (Precise, 5.0);
         AUnit.Assertions.Assert
           (V.Get (Image, 0, 0) = (Precise, 5.0),
            "binary64 row write immediately visible");
      end Change;
      procedure View (M : in out Mat) is
      begin
         AUnit.Assertions.Assert
           (V.Get (M, 1, 2) = (9.0, 9.0), "binary64 strided final element");
         V.Set (M, 0, 0, (Precise, 8.0));
      end View;
   begin
      R.Write_Row (Image, 0, Row);
      R.Read_Row (Image, 0, Row);
      AUnit.Assertions.Assert
        (Row (7) = (Precise, -Precise),
         "copied Float64 row preserves precision");
      B.With_Read_Only_Buffer (Image, Observe'Access);
      R.With_Writable_Row (Image, 0, Change'Access);
      E.With_Writable_Strided_Mat_View (Backing, 2, 3, 4, View'Access);
      AUnit.Assertions.Assert
        (Backing (5) = (Precise, 8.0)
         and then Backing (8) = (9.0, 9.0)
         and then Backing (12) = (9.0, 9.0),
         "binary64 caller storage and padding");
   end Float64_Rows_Buffers_Views;

   procedure Float32_Rejects_Invalid_Elements (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      package V renames Float32_Vec2_Access;
      Good           : Mat :=
        Create (Shape => (2, 3, 4), Element_Type => (Float32, 2));
      Wrong_Depth    : Mat := Create (2, 3, (Float64, 2));
      Wrong_Channels : Mat := Create (2, 3, (Float32, 1));
      Value          : constant Float32_Vec2.Vector := (1.0, 2.0);
      procedure Reject_Get (M : Mat; Indices : Index_Array) is
      begin
         declare
            Ignored : constant Float32_Vec2.Vector := V.Get (M, Indices);
            pragma Unreferenced (Ignored);
         begin
            AUnit.Assertions.Assert (False, "invalid Get accepted");
         end;
      exception
         when OpenCV_Error =>
            null;
      end Reject_Get;
      procedure Reject_Set (M : in out Mat; Indices : Index_Array) is
      begin
         V.Set (M, Indices, Value);
         AUnit.Assertions.Assert (False, "invalid Set accepted");
      exception
         when OpenCV_Error =>
            null;
      end Reject_Set;
   begin
      Reject_Get (Wrong_Depth, (0, 0));
      Reject_Set (Wrong_Depth, (0, 0));
      Reject_Get (Wrong_Channels, (0, 0));
      Reject_Set (Wrong_Channels, (0, 0));
      Reject_Get (Good, (0, 0));
      Reject_Set (Good, (0, 0));
      Reject_Get (Good, (0, 0, 0, 0));
      Reject_Set (Good, (0, 0, 0, 0));
      Reject_Get (Good, (1, 3, 0));
      Reject_Set (Good, (1, 3, 0));
      begin
         V.Set (Wrong_Depth, 0, 0, Value);
         AUnit.Assertions.Assert (False, "2-D wrong-depth Set accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
   end Float32_Rejects_Invalid_Elements;

   procedure Float64_Rejects_Invalid_Elements (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      package V renames Float64_Vec2_Access;
      Good           : Mat :=
        Create (Shape => (2, 3, 4), Element_Type => (Float64, 2));
      Wrong_Depth    : Mat := Create (2, 3, (Float32, 2));
      Wrong_Channels : Mat := Create (2, 3, (Float64, 1));
      Value          : constant Float64_Vec2.Vector := (1.0, 2.0);
      procedure Reject_Get (M : Mat; Indices : Index_Array) is
      begin
         declare
            Ignored : constant Float64_Vec2.Vector := V.Get (M, Indices);
            pragma Unreferenced (Ignored);
         begin
            AUnit.Assertions.Assert (False, "invalid Float64 Get accepted");
         end;
      exception
         when OpenCV_Error =>
            null;
      end Reject_Get;
      procedure Reject_Set (M : in out Mat; Indices : Index_Array) is
      begin
         V.Set (M, Indices, Value);
         AUnit.Assertions.Assert (False, "invalid Float64 Set accepted");
      exception
         when OpenCV_Error =>
            null;
      end Reject_Set;
   begin
      Reject_Get (Wrong_Depth, (0, 0));
      Reject_Set (Wrong_Depth, (0, 0));
      Reject_Get (Wrong_Channels, (0, 0));
      Reject_Set (Wrong_Channels, (0, 0));
      Reject_Get (Good, (0, 0));
      Reject_Set (Good, (0, 0));
      Reject_Get (Good, (0, 0, 0, 0));
      Reject_Set (Good, (0, 0, 0, 0));
      Reject_Get (Good, (1, 3, 0));
      Reject_Set (Good, (1, 3, 0));
      begin
         declare
            Ignored : constant Float64_Vec2.Vector :=
              V.Get (Wrong_Depth, 0, 0);
            pragma Unreferenced (Ignored);
         begin
            AUnit.Assertions.Assert (False, "2-D wrong-depth Get accepted");
         end;
      exception
         when OpenCV_Error =>
            null;
      end;
   end Float64_Rejects_Invalid_Elements;

   procedure Float32_Borrow_And_View_Boundaries (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      package V renames Float32_Vec2_Access;
      package R renames Float32_Vec2_Row_Access;
      package B renames Float32_Vec2_Buffer_Access;
      package E renames Float32_Vec2_Mat_View;
      Image   : Mat := Create (2, 4, (Float32, 2));
      Alias   : constant Mat := Image;
      ROI     : Mat :=
        Image.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      Values  : aliased E.Buffer_Array := (4 .. 7 => (2.0, 3.0));
      Saved   : Mat;
      Invoked : Boolean := False;
      procedure Read_Row (Data : aliased R.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 2 and then Data (0) = (4.0, 5.0),
            "non-contiguous row excludes padding");
      end Read_Row;
      procedure Write_Row (Data : aliased in out R.Row_Array) is
      begin
         Data (1) := (6.0, 7.0);
         AUnit.Assertions.Assert
           (V.Get (Alias, 0, 2) = (6.0, 7.0),
            "borrowed Region row aliases parent");
      end Write_Row;
      procedure Observe (Data : aliased B.Buffer_Array) is
      begin
         Invoked := True;
         AUnit.Assertions.Assert (Data'Length = 8, "complete Mat buffer");
      end Observe;
      procedure Write_Buffer (Data : aliased in out B.Buffer_Array) is
      begin
         Data (0) := (8.0, 9.0);
         AUnit.Assertions.Assert
           (V.Get (Alias, 0, 0) = (8.0, 9.0),
            "buffer alias visible in callback");
         raise Constraint_Error;
      end Write_Buffer;
      procedure View (M : in out Mat) is
      begin
         Saved := M.Clone;
         V.Set (M, 1, 1, (10.0, 11.0));
      end View;
   begin
      V.Set (Image, 0, 1, (4.0, 5.0));
      R.With_Read_Only_Row (ROI, 0, Read_Row'Access);
      R.With_Writable_Row (ROI, 0, Write_Row'Access);
      B.With_Read_Only_Buffer (Image, Observe'Access);
      Invoked := False;
      begin
         B.With_Read_Only_Buffer (ROI, Observe'Access);
         AUnit.Assertions.Assert (False, "noncontinuous buffer accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      AUnit.Assertions.Assert (not Invoked, "rejected callback not invoked");
      begin
         B.With_Writable_Buffer (Image, Write_Buffer'Access);
         AUnit.Assertions.Assert (False, "callback exception swallowed");
      exception
         when Constraint_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (V.Get (Image, 0, 0) = (8.0, 9.0),
         "completed callback write persists");
      E.With_Writable_Mat_View (Values, 2, 2, View'Access);
      AUnit.Assertions.Assert
        (Values (7) = (10.0, 11.0) and then V.Get (Saved, 1, 1) = (2.0, 3.0),
         "Clone safely escapes view");
   end Float32_Borrow_And_View_Boundaries;

   procedure Float64_Borrow_And_View_Boundaries (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      package V renames Float64_Vec2_Access;
      package R renames Float64_Vec2_Row_Access;
      package B renames Float64_Vec2_Buffer_Access;
      package E renames Float64_Vec2_Mat_View;
      Precise : constant OpenCV.Float64_Value := 1.0 + 2.0**(-40);
      Image   : Mat := Create (2, 4, (Float64, 2));
      Alias   : constant Mat := Image;
      ROI     : Mat :=
        Image.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      Values  : aliased E.Buffer_Array := (4 .. 7 => (Precise, 3.0));
      Saved   : Mat;
      Invoked : Boolean := False;
      procedure Read_Row (Data : aliased R.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 2 and then Data (0) = (Precise, 5.0),
            "Float64 Region row excludes padding");
      end Read_Row;
      procedure Write_Row (Data : aliased in out R.Row_Array) is
      begin
         Data (1) := (Precise, 7.0);
         AUnit.Assertions.Assert
           (V.Get (Alias, 0, 2) = (Precise, 7.0),
            "Float64 Region row aliases parent");
      end Write_Row;
      procedure Observe (Data : aliased B.Buffer_Array) is
      begin
         Invoked := True;
         AUnit.Assertions.Assert (Data'Length = 8, "Float64 flat Vec2 count");
      end Observe;
      procedure Write_Buffer (Data : aliased in out B.Buffer_Array) is
      begin
         Data (0) := (Precise, 9.0);
         AUnit.Assertions.Assert
           (V.Get (Alias, 0, 0) = (Precise, 9.0),
            "Float64 immediate alias visibility");
         raise Constraint_Error;
      end Write_Buffer;
      procedure View (M : in out Mat) is
      begin
         Saved := M.Clone;
         V.Set (M, 1, 1, (Precise, 11.0));
      end View;
   begin
      V.Set (Image, 0, 1, (Precise, 5.0));
      R.With_Read_Only_Row (ROI, 0, Read_Row'Access);
      R.With_Writable_Row (ROI, 0, Write_Row'Access);
      B.With_Read_Only_Buffer (Image, Observe'Access);
      Invoked := False;
      begin
         B.With_Read_Only_Buffer (ROI, Observe'Access);
         AUnit.Assertions.Assert
           (False, "Float64 noncontinuous buffer accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (not Invoked, "Float64 rejection skips callback");
      begin
         B.With_Writable_Buffer (Image, Write_Buffer'Access);
         AUnit.Assertions.Assert
           (False, "Float64 callback exception swallowed");
      exception
         when Constraint_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (V.Get (Image, 0, 0) = (Precise, 9.0),
         "Float64 completed write persists");
      E.With_Writable_Mat_View (Values, 2, 2, View'Access);
      AUnit.Assertions.Assert
        (Values (7) = (Precise, 11.0)
         and then V.Get (Saved, 1, 1) = (Precise, 3.0),
         "Float64 Clone escapes view");
   end Float64_Borrow_And_View_Boundaries;

   procedure Vec2_Row_And_View_Validation (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      package R32 renames Float32_Vec2_Row_Access;
      package R64 renames Float64_Vec2_Row_Access;
      package E32 renames Float32_Vec2_Mat_View;
      package E64 renames Float64_Vec2_Mat_View;
      F32     : constant Mat := Create (1, 3, (Float32, 2));
      F64     : constant Mat := Create (1, 3, (Float64, 2));
      C1      : Mat := Create (1, 3, (Float32, 1));
      D1      : Mat := Create (1, 3, (Float64, 1));
      Short32 : R32.Row_Array (1 .. 2);
      Short64 : R64.Row_Array (1 .. 2);
      Full32  : R32.Row_Array (1 .. 3);
      Full64  : R64.Row_Array (1 .. 3);
      B32     : aliased E32.Buffer_Array := (0 .. 6 => (0.0, 0.0));
      B64     : aliased E64.Buffer_Array := (0 .. 6 => (0.0, 0.0));
      Invoked : Boolean := False;
      procedure Callback (Image : in out Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Callback;
   begin
      begin
         R32.Read_Row (F32, 0, Short32);
         AUnit.Assertions.Assert (False, "Float32 short row accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      begin
         R32.Write_Row (C1, 0, (1 .. 3 => (0.0, 0.0)));
         AUnit.Assertions.Assert (False, "Float32 C1 row accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      begin
         R32.Read_Row (F32, 1, Full32);
         AUnit.Assertions.Assert (False, "Float32 past row accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      begin
         R64.Read_Row (F64, 0, Short64);
         AUnit.Assertions.Assert (False, "Float64 short row accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      begin
         R64.Write_Row (D1, 0, (1 .. 3 => (0.0, 0.0)));
         AUnit.Assertions.Assert (False, "Float64 C1 row accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      begin
         R64.Read_Row (F64, 1, Full64);
         AUnit.Assertions.Assert (False, "Float64 past row accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      begin
         E32.With_Writable_Strided_Mat_View (B32, 2, 3, 4, Callback'Access);
         AUnit.Assertions.Assert (False, "Float32 missing padding accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      begin
         E64.With_Writable_Strided_Mat_View (B64, 2, 3, 4, Callback'Access);
         AUnit.Assertions.Assert (False, "Float64 missing padding accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      begin
         E32.With_Writable_Strided_Mat_View (B32, 2, 3, 2, Callback'Access);
         AUnit.Assertions.Assert (False, "Float32 narrow stride accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      begin
         E64.With_Writable_Strided_Mat_View (B64, 2, 3, 2, Callback'Access);
         AUnit.Assertions.Assert (False, "Float64 narrow stride accepted");
      exception
         when OpenCV_Error =>
            null;
      end;
      AUnit.Assertions.Assert (not Invoked, "invalid views skip callback");
   end Vec2_Row_And_View_Validation;

   procedure Vec2_Continuous_Regions_And_Leases (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core;
      package F32 renames Float32_Vec2_Access;
      package F64 renames Float64_Vec2_Access;
      package B32 renames Float32_Vec2_Buffer_Access;
      package B64 renames Float64_Vec2_Buffer_Access;
      package R32 renames Float32_Vec2_Row_Access;
      package R64 renames Float64_Vec2_Row_Access;
      Image32 : Mat := Create (2, 3, (Float32, 2));
      Image64 : Mat := Create (2, 3, (Float64, 2));
      Alias32 : constant Mat := Image32;
      Alias64 : constant Mat := Image64;
      ROI32   : Mat :=
        Image32.Region ((X => 0, Y => 1, Width => 3, Height => 1));
      ROI64   : Mat :=
        Image64.Region ((X => 0, Y => 1, Width => 3, Height => 1));
      procedure Borrow32 (Data : aliased in out B32.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 3, "continuous Float32 Region is three Vec2s");
         Image32 := Create (1, 1, (Float32, 2));
         Data (2) := (3.0, 4.0);
      end Borrow32;
      procedure Borrow64 (Data : aliased in out B64.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 3, "continuous Float64 Region is three Vec2s");
         Image64 := Create (1, 1, (Float64, 2));
         Data (2) := (5.0, 6.0);
      end Borrow64;
      procedure Row32 (Data : aliased in out R32.Row_Array) is
      begin
         ROI32 := Create (1, 1, (Float32, 2));
         Data (0) := (7.0, 8.0);
         raise Constraint_Error;
      end Row32;
      procedure Row64 (Data : aliased in out R64.Row_Array) is
      begin
         ROI64 := Create (1, 1, (Float64, 2));
         Data (0) := (9.0, 10.0);
         raise Constraint_Error;
      end Row64;
   begin
      B32.With_Writable_Buffer (ROI32, Borrow32'Access);
      B64.With_Writable_Buffer (ROI64, Borrow64'Access);
      AUnit.Assertions.Assert
        (F32.Get (Alias32, 1, 2) = (3.0, 4.0)
         and then F64.Get (Alias64, 1, 2) = (5.0, 6.0),
         "buffer lease protects storage after parent rebinding");
      begin
         R32.With_Writable_Row (ROI32, 0, Row32'Access);
         AUnit.Assertions.Assert (False, "Float32 row exception swallowed");
      exception
         when Constraint_Error =>
            null;
      end;
      begin
         R64.With_Writable_Row (ROI64, 0, Row64'Access);
         AUnit.Assertions.Assert (False, "Float64 row exception swallowed");
      exception
         when Constraint_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (F32.Get (Alias32, 1, 0) = (7.0, 8.0)
         and then F64.Get (Alias64, 1, 0) = (9.0, 10.0),
         "row leases protect storage and completed writes survive exceptions");
   end Vec2_Continuous_Regions_And_Leases;
   procedure Raw_ABI_Safety (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check;
   end Raw_ABI_Safety;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec2 elements and DFT",
            Float32_Elements_And_Spectrum'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec2 elements and DFT",
            Float64_Elements_And_Spectrum'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec2 rows buffers views",
            Float32_Rows_Buffers_Views'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec2 rows buffers views",
            Float64_Rows_Buffers_Views'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec2 element validation",
            Float32_Rejects_Invalid_Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec2 element validation",
            Float64_Rejects_Invalid_Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec2 borrow and view boundaries",
            Float32_Borrow_And_View_Boundaries'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec2 borrow and view boundaries",
            Float64_Borrow_And_View_Boundaries'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec2 row and view validation",
            Vec2_Row_And_View_Validation'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec2 continuous Regions and leases",
            Vec2_Continuous_Regions_And_Leases'Access));
      Result.Add_Test
        (Caller.Create ("Vec2 raw ABI layout safety", Raw_ABI_Safety'Access));
      return Result'Access;
   end Suite;
end Vec2_Access_Tests;
