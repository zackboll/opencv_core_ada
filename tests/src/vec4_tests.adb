with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.Float64_Vec3_Access;
with OpenCV.Core.Float32_Vec4;
with OpenCV.Core.Float32_Vec4_Access;
with OpenCV.Core.Float32_Vec4_Row_Access;
with OpenCV.Core.Float32_Vec4_Buffer_Access;
with OpenCV.Core.Float32_Vec4_Mat_View;
with OpenCV.Core.Float64_Vec4;
with OpenCV.Core.Float64_Vec4_Access;
with OpenCV.Core.Float64_Vec4_Row_Access;
with OpenCV.Core.Float64_Vec4_Buffer_Access;
with OpenCV.Core.Float64_Vec4_Mat_View;
with Vec4_Tests.Raw_ABI;

package body Vec4_Tests is
   use type OpenCV.Core.Float32_Vec4.Vector;
   use type OpenCV.Core.Float64_Vec4.Vector;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Float64_Value;
   use type OpenCV.Float32_Value;
   use Mat_Test_Support;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result  : aliased AUnit.Test_Suites.Test_Suite;
   A       : constant OpenCV.Float64_Value := 1.0 + 2.0**(-40);
   B       : constant OpenCV.Float64_Value := -2.0 - 2.0**(-42);
   C       : constant OpenCV.Float64_Value := 3.0 + 2.0**(-44);
   D       : constant OpenCV.Float64_Value := -4.0 + 2.0**(-45);
   Precise : constant OpenCV.Core.Float64_Vec4.Vector := (A, B, C, D);
   Other64 : constant OpenCV.Core.Float64_Vec4.Vector := (D, C, B, A);
   Value32 : constant OpenCV.Core.Float32_Vec4.Vector := (2.0, 3.0, 4.0, 9.0);
   Other32 : constant OpenCV.Core.Float32_Vec4.Vector := (9.0, 4.0, 3.0, 2.0);

   procedure Raw_ABI_Safety (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Vec4_Tests.Raw_ABI.Check;
   end Raw_ABI_Safety;

   procedure Elements32 (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 4));
      Alias   : OpenCV.Core.Mat;
      Copy    : OpenCV.Core.Mat;
      Volume  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float32, 4));
      Shifted : constant OpenCV.Core.Index_Array (7 .. 9) := (1, 2, 3);
      procedure Bad_Depth is
         Wrong : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float64, 4));
         V     : constant OpenCV.Core.Float32_Vec4.Vector :=
           OpenCV.Core.Float32_Vec4_Access.Get (Wrong, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Depth;
      procedure Bad_Channels is
         Wrong : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      begin
         OpenCV.Core.Float32_Vec4_Access.Set (Wrong, (0, 0), Value32);
      end Bad_Channels;
      procedure Bad_Row is
         V : constant OpenCV.Core.Float32_Vec4.Vector :=
           OpenCV.Core.Float32_Vec4_Access.Get (Image, -1, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Row;
      procedure Bad_Column is
      begin
         OpenCV.Core.Float32_Vec4_Access.Set (Image, 0, 3, Value32);
      end Bad_Column;
      procedure Bad_Count is
      begin
         OpenCV.Core.Float32_Vec4_Access.Set (Volume, (1, 2), Value32);
      end Bad_Count;
      procedure Bad_Many is
         V : constant OpenCV.Core.Float32_Vec4.Vector :=
           OpenCV.Core.Float32_Vec4_Access.Get (Volume, (0, 0, 0, 0));
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Many;
      procedure Bad_Axis is
         V : constant OpenCV.Core.Float32_Vec4.Vector :=
           OpenCV.Core.Float32_Vec4_Access.Get (Volume, (1, 3, 0));
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Axis;
   begin
      Image.Set_To (OpenCV.Make_Scalar (0.0, 0.0, 0.0, 0.0));
      OpenCV.Core.Float32_Vec4_Access.Set (Image, 1, 2, Value32);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec4_Access.Get (Image, 1, 2) = Value32
         and then OpenCV.Core.Float32_Vec4_Access.Get (Image, (1, 2)) = Value32
         and then OpenCV.Core.Float32_Vec4_Access.Get (Image, 1, 1)
                  = (0.0, 0.0, 0.0, 0.0),
         "Float32 Vec4 component order, scalar Set_To and neighbors");
      Alias := Image;
      Copy := Image.Clone;
      OpenCV.Core.Float32_Vec4_Access.Set (Alias, 1, 2, Other32);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec4_Access.Get (Image, 1, 2) = Other32
         and then OpenCV.Core.Float32_Vec4_Access.Get (Copy, 1, 2) = Value32,
         "Float32 Vec4 assignment shares and Clone isolates");
      Volume.Set_To (OpenCV.Make_Scalar (0.0, 0.0, 0.0, 0.0));
      OpenCV.Core.Float32_Vec4_Access.Set (Volume, Shifted, Value32);
      OpenCV.Core.Float32_Vec4_Access.Set (Volume, (0, 1, 2), Other32);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec4_Access.Get (Volume, (1, 2, 3)) = Value32
         and then OpenCV.Core.Float32_Vec4_Access.Get (Volume, (0, 1, 2))
                  = Other32
         and then OpenCV.Core.Float32_Vec4_Access.Get (Volume, (1, 2, 2))
                  = (0.0, 0.0, 0.0, 0.0),
         "shifted N-D indices map axes in iteration order");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Float32 Vec4 wrong depth");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Float32 Vec4 wrong channels");
      Assert_Raises_OpenCV_Error (Bad_Row'Access, "Float32 Vec4 negative row");
      Assert_Raises_OpenCV_Error
        (Bad_Column'Access, "Float32 Vec4 past column");
      Assert_Raises_OpenCV_Error
        (Bad_Count'Access, "Float32 Vec4 too few indices");
      Assert_Raises_OpenCV_Error
        (Bad_Many'Access, "Float32 Vec4 too many indices");
      Assert_Raises_OpenCV_Error
        (Bad_Axis'Access, "Float32 Vec4 past N-D extent");
   end Elements32;

   procedure Elements64 (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 4));
      Alias   : OpenCV.Core.Mat;
      Copy    : OpenCV.Core.Mat;
      Volume  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float64, 4));
      Shifted : constant OpenCV.Core.Index_Array (7 .. 9) := (1, 2, 3);
      procedure Bad_Depth is
         Wrong : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 4));
         V     : constant OpenCV.Core.Float64_Vec4.Vector :=
           OpenCV.Core.Float64_Vec4_Access.Get (Wrong, (0, 0));
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Depth;
      procedure Bad_Channels is
         Wrong : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float64, 3));
      begin
         OpenCV.Core.Float64_Vec4_Access.Set (Wrong, 0, 0, Precise);
      end Bad_Channels;
      procedure Bad_Row is
         V : constant OpenCV.Core.Float64_Vec4.Vector :=
           OpenCV.Core.Float64_Vec4_Access.Get (Image, -1, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Row;
      procedure Bad_Column is
      begin
         OpenCV.Core.Float64_Vec4_Access.Set (Image, 0, 3, Precise);
      end Bad_Column;
      procedure Bad_Count is
      begin
         OpenCV.Core.Float64_Vec4_Access.Set (Volume, (1, 2), Precise);
      end Bad_Count;
      procedure Bad_Many is
         V : constant OpenCV.Core.Float64_Vec4.Vector :=
           OpenCV.Core.Float64_Vec4_Access.Get (Volume, (0, 0, 0, 0));
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Many;
      procedure Bad_Axis is
         V : constant OpenCV.Core.Float64_Vec4.Vector :=
           OpenCV.Core.Float64_Vec4_Access.Get (Volume, (1, 3, 0));
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Axis;
   begin
      Image.Set_To (OpenCV.Make_Scalar (0.0, 0.0, 0.0, 0.0));
      OpenCV.Core.Float64_Vec4_Access.Set (Image, 1, 2, Precise);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec4_Access.Get (Image, 1, 2) = Precise
         and then OpenCV.Core.Float64_Vec4_Access.Get (Image, (1, 2)) = Precise
         and then OpenCV.Core.Float64_Vec4_Access.Get (Image, 1, 1)
                  = (0.0, 0.0, 0.0, 0.0),
         "Float64 Vec4 retains all binary64 components and neighbors");
      Alias := Image;
      Copy := Image.Clone;
      OpenCV.Core.Float64_Vec4_Access.Set (Alias, 1, 2, Other64);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec4_Access.Get (Image, 1, 2) = Other64
         and then OpenCV.Core.Float64_Vec4_Access.Get (Copy, 1, 2) = Precise,
         "Float64 Vec4 assignment shares and Clone isolates");
      Volume.Set_To (OpenCV.Make_Scalar (0.0, 0.0, 0.0, 0.0));
      OpenCV.Core.Float64_Vec4_Access.Set (Volume, Shifted, Precise);
      OpenCV.Core.Float64_Vec4_Access.Set (Volume, (0, 1, 2), Other64);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec4_Access.Get (Volume, (1, 2, 3)) = Precise
         and then OpenCV.Core.Float64_Vec4_Access.Get (Volume, (0, 1, 2))
                  = Other64
         and then OpenCV.Core.Float64_Vec4_Access.Get (Volume, (1, 2, 2))
                  = (0.0, 0.0, 0.0, 0.0),
         "Float64 N-D shifted bounds and exact precision");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Float64 Vec4 wrong depth");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Float64 Vec4 wrong channels");
      Assert_Raises_OpenCV_Error (Bad_Row'Access, "Float64 Vec4 negative row");
      Assert_Raises_OpenCV_Error
        (Bad_Column'Access, "Float64 Vec4 past column");
      Assert_Raises_OpenCV_Error
        (Bad_Count'Access, "Float64 Vec4 too few indices");
      Assert_Raises_OpenCV_Error
        (Bad_Many'Access, "Float64 Vec4 too many indices");
      Assert_Raises_OpenCV_Error
        (Bad_Axis'Access, "Float64 Vec4 past N-D extent");
   end Elements64;

   procedure Rows_Buffers32 (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 4));
      Alias   : OpenCV.Core.Mat := Image;
      ROI     : OpenCV.Core.Mat := Image.Region ((1, 0, 2, 2));
      Whole   : constant OpenCV.Core.Mat := Image.Region ((0, 1, 3, 2));
      Row     : OpenCV.Core.Float32_Vec4_Row_Access.Row_Array (8 .. 10) :=
        (others => Value32);
      Short   : OpenCV.Core.Float32_Vec4_Row_Access.Row_Array (1 .. 2);
      Invoked : Boolean := False;
      procedure Observe_Row
        (Data : aliased OpenCV.Core.Float32_Vec4_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 2 and then Data (0) = Value32,
            "Float32 non-contiguous row excludes neighbors");
      end Observe_Row;
      procedure Write_Row
        (Data : aliased in out OpenCV.Core.Float32_Vec4_Row_Access.Row_Array)
      is
      begin
         Data (0) := Other32;
         raise Constraint_Error;
      end Write_Row;
      procedure Observe_Buffer
        (Data : aliased OpenCV.Core.Float32_Vec4_Buffer_Access.Buffer_Array) is
      begin
         Invoked := True;
         AUnit.Assertions.Assert
           (Data'Length = 6 and then Data (2) = Value32,
            "Float32 continuous Region has six Vec4 elements");
      end Observe_Buffer;
      procedure Rebind_Buffer
        (Data :
           aliased in out OpenCV.Core.Float32_Vec4_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 9, "Float32 whole buffer has nine elements");
         Data (0) := Value32;
         Alias := OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 4));
         AUnit.Assertions.Assert
           (Data (0) = Value32 and then Alias.Columns = 1,
            "Float32 buffer lease survives rebind");
         raise Constraint_Error;
      end Rebind_Buffer;
      procedure Bad_Row_Size is
      begin
         OpenCV.Core.Float32_Vec4_Row_Access.Read_Row (Image, 0, Short);
      end Bad_Row_Size;
      procedure Bad_Row_Index is
      begin
         OpenCV.Core.Float32_Vec4_Row_Access.Write_Row (Image, 3, Row);
      end Bad_Row_Index;
      procedure Bad_Row_Depth is
         Wrong : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 3, (OpenCV.Core.Float64, 4));
      begin
         OpenCV.Core.Float32_Vec4_Row_Access.Write_Row (Wrong, 0, Row);
      end Bad_Row_Depth;
      procedure Bad_Row_Channels is
         Wrong : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 2));
      begin
         OpenCV.Core.Float32_Vec4_Row_Access.Read_Row (Wrong, 0, Row);
      end Bad_Row_Channels;
      procedure Bad_Continuous is
      begin
         OpenCV.Core.Float32_Vec4_Buffer_Access.With_Read_Only_Buffer
           (ROI, Observe_Buffer'Access);
      end Bad_Continuous;
   begin
      Image.Set_To (OpenCV.Make_Scalar (0.0, 0.0, 0.0, 0.0));
      OpenCV.Core.Float32_Vec4_Row_Access.Write_Row (Image, 1, Row);
      OpenCV.Core.Float32_Vec4_Row_Access.Read_Row (Image, 1, Row);
      AUnit.Assertions.Assert
        (Row (8) = Value32 and then Row (10) = Value32,
         "Float32 shifted copied row round trip");
      OpenCV.Core.Float32_Vec4_Access.Set (Image, 0, 1, Value32);
      OpenCV.Core.Float32_Vec4_Row_Access.With_Read_Only_Row
        (ROI, 0, Observe_Row'Access);
      begin
         OpenCV.Core.Float32_Vec4_Row_Access.With_Writable_Row
           (ROI, 0, Write_Row'Access);
         AUnit.Assertions.Assert (False, "Float32 row exception swallowed");
      exception
         when Constraint_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec4_Access.Get (Image, 0, 1) = Other32,
         "Float32 row write immediately visible after exception");
      OpenCV.Core.Float32_Vec4_Buffer_Access.With_Read_Only_Buffer
        (Whole, Observe_Buffer'Access);
      Invoked := False;
      Assert_Raises_OpenCV_Error
        (Bad_Continuous'Access, "Float32 non-continuous buffer");
      AUnit.Assertions.Assert
        (not Invoked, "Float32 rejected buffer callback not invoked");
      begin
         OpenCV.Core.Float32_Vec4_Buffer_Access.With_Writable_Buffer
           (Image, Rebind_Buffer'Access);
         AUnit.Assertions.Assert (False, "Float32 buffer exception swallowed");
      exception
         when Constraint_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec4_Access.Get (Image, 0, 0) = Value32,
         "Float32 shallow storage retains buffer write");
      Assert_Raises_OpenCV_Error
        (Bad_Row_Size'Access, "Float32 wrong row length");
      Assert_Raises_OpenCV_Error (Bad_Row_Index'Access, "Float32 past row");
      Assert_Raises_OpenCV_Error (Bad_Row_Depth'Access, "Float32 row depth");
      Assert_Raises_OpenCV_Error
        (Bad_Row_Channels'Access, "Float32 row channels");
   end Rows_Buffers32;

   procedure Rows_Buffers64 (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float64, 4));
      Alias   : OpenCV.Core.Mat := Image;
      ROI     : OpenCV.Core.Mat := Image.Region ((1, 0, 2, 2));
      Whole   : constant OpenCV.Core.Mat := Image.Region ((0, 1, 3, 2));
      Row     : OpenCV.Core.Float64_Vec4_Row_Access.Row_Array (8 .. 10) :=
        (others => Precise);
      Short   : OpenCV.Core.Float64_Vec4_Row_Access.Row_Array (1 .. 2);
      Invoked : Boolean := False;
      procedure Observe_Row
        (Data : aliased OpenCV.Core.Float64_Vec4_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 2 and then Data (0) = Precise,
            "Float64 non-contiguous row excludes neighbors");
      end Observe_Row;
      procedure Write_Row
        (Data : aliased in out OpenCV.Core.Float64_Vec4_Row_Access.Row_Array)
      is
      begin
         Data (0) := Other64;
         raise Constraint_Error;
      end Write_Row;
      procedure Observe_Buffer
        (Data : aliased OpenCV.Core.Float64_Vec4_Buffer_Access.Buffer_Array) is
      begin
         Invoked := True;
         AUnit.Assertions.Assert
           (Data'Length = 6 and then Data (2) = Precise,
            "Float64 continuous Region has six Vec4 elements");
      end Observe_Buffer;
      procedure Rebind_Buffer
        (Data :
           aliased in out OpenCV.Core.Float64_Vec4_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 9, "Float64 whole buffer has nine elements");
         Data (0) := Precise;
         Alias := OpenCV.Core.Create (1, 1, (OpenCV.Core.Float64, 4));
         AUnit.Assertions.Assert
           (Data (0) = Precise and then Alias.Columns = 1,
            "Float64 buffer lease survives rebind");
         raise Constraint_Error;
      end Rebind_Buffer;
      procedure Bad_Row_Size is
      begin
         OpenCV.Core.Float64_Vec4_Row_Access.Read_Row (Image, 0, Short);
      end Bad_Row_Size;
      procedure Bad_Row_Index is
      begin
         OpenCV.Core.Float64_Vec4_Row_Access.Write_Row (Image, 3, Row);
      end Bad_Row_Index;
      procedure Bad_Row_Depth is
         Wrong : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 4));
      begin
         OpenCV.Core.Float64_Vec4_Row_Access.Write_Row (Wrong, 0, Row);
      end Bad_Row_Depth;
      procedure Bad_Row_Channels is
         Wrong : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 3, (OpenCV.Core.Float64, 2));
      begin
         OpenCV.Core.Float64_Vec4_Row_Access.Read_Row (Wrong, 0, Row);
      end Bad_Row_Channels;
      procedure Bad_Continuous is
      begin
         OpenCV.Core.Float64_Vec4_Buffer_Access.With_Read_Only_Buffer
           (ROI, Observe_Buffer'Access);
      end Bad_Continuous;
   begin
      Image.Set_To (OpenCV.Make_Scalar (0.0, 0.0, 0.0, 0.0));
      OpenCV.Core.Float64_Vec4_Row_Access.Write_Row (Image, 1, Row);
      OpenCV.Core.Float64_Vec4_Row_Access.Read_Row (Image, 1, Row);
      AUnit.Assertions.Assert
        (Row (8) = Precise and then Row (10) = Precise,
         "Float64 shifted copied row exact round trip");
      OpenCV.Core.Float64_Vec4_Access.Set (Image, 0, 1, Precise);
      OpenCV.Core.Float64_Vec4_Row_Access.With_Read_Only_Row
        (ROI, 0, Observe_Row'Access);
      begin
         OpenCV.Core.Float64_Vec4_Row_Access.With_Writable_Row
           (ROI, 0, Write_Row'Access);
         AUnit.Assertions.Assert (False, "Float64 row exception swallowed");
      exception
         when Constraint_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec4_Access.Get (Image, 0, 1) = Other64,
         "Float64 row write immediately visible after exception");
      OpenCV.Core.Float64_Vec4_Buffer_Access.With_Read_Only_Buffer
        (Whole, Observe_Buffer'Access);
      Invoked := False;
      Assert_Raises_OpenCV_Error
        (Bad_Continuous'Access, "Float64 non-continuous buffer");
      AUnit.Assertions.Assert
        (not Invoked, "Float64 rejected buffer callback not invoked");
      begin
         OpenCV.Core.Float64_Vec4_Buffer_Access.With_Writable_Buffer
           (Image, Rebind_Buffer'Access);
         AUnit.Assertions.Assert (False, "Float64 buffer exception swallowed");
      exception
         when Constraint_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec4_Access.Get (Image, 0, 0) = Precise,
         "Float64 shallow storage retains buffer write exactly");
      Assert_Raises_OpenCV_Error
        (Bad_Row_Size'Access, "Float64 wrong row length");
      Assert_Raises_OpenCV_Error (Bad_Row_Index'Access, "Float64 past row");
      Assert_Raises_OpenCV_Error (Bad_Row_Depth'Access, "Float64 row depth");
      Assert_Raises_OpenCV_Error
        (Bad_Row_Channels'Access, "Float64 row channels");
   end Rows_Buffers64;

   procedure Views32 (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Packed  : aliased OpenCV.Core.Float32_Vec4_Mat_View.Buffer_Array :=
        (5 .. 10 => Value32);
      Strided : aliased OpenCV.Core.Float32_Vec4_Mat_View.Buffer_Array :=
        (7 .. 14 => Other32);
      Short   : aliased OpenCV.Core.Float32_Vec4_Mat_View.Buffer_Array :=
        (0 .. 6 => Value32);
      Saved   : OpenCV.Core.Mat;
      Invoked : Boolean := False;
      procedure Packed_View (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Vec4_Access.Get (Image, 0, 0) = Value32,
            "Float32 caller storage read");
         OpenCV.Core.Float32_Vec4_Access.Set (Image, 1, 2, Other32);
         Saved := Image.Clone;
      end Packed_View;
      procedure Strided_View (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Vec4_Access.Get (Image, 0, 0) = Value32,
            "Float32 strided caller storage read");
         OpenCV.Core.Float32_Vec4_Access.Set (Image, 1, 2, Value32);
      end Strided_View;
      procedure Never (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Never;
      procedure Bad_Stride is
      begin
         OpenCV.Core.Float32_Vec4_Mat_View.With_Writable_Strided_Mat_View
           (Strided, 2, 3, 2, Never'Access);
      end Bad_Stride;
      procedure Bad_Backing is
      begin
         OpenCV.Core.Float32_Vec4_Mat_View.With_Writable_Strided_Mat_View
           (Short, 2, 3, 4, Never'Access);
      end Bad_Backing;
   begin
      OpenCV.Core.Float32_Vec4_Mat_View.With_Writable_Mat_View
        (Packed, 2, 3, Packed_View'Access);
      AUnit.Assertions.Assert
        (Packed (10) = Other32, "Float32 packed view writes caller memory");
      Packed (10) := Value32;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec4_Access.Get (Saved, 1, 2) = Other32,
         "Float32 Clone independently escapes view");
      Strided (7) := Value32;
      OpenCV.Core.Float32_Vec4_Mat_View.With_Writable_Strided_Mat_View
        (Strided, 2, 3, 4, Strided_View'Access);
      AUnit.Assertions.Assert
        (Strided (13) = Value32
         and then Strided (10) = Other32
         and then Strided (14) = Other32,
         "Float32 first/final row padding untouched");
      Assert_Raises_OpenCV_Error (Bad_Stride'Access, "Float32 short stride");
      Assert_Raises_OpenCV_Error (Bad_Backing'Access, "Float32 short backing");
      AUnit.Assertions.Assert
        (not Invoked, "Float32 rejected view callback not invoked");
   end Views32;

   procedure Views64 (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Packed  : aliased OpenCV.Core.Float64_Vec4_Mat_View.Buffer_Array :=
        (5 .. 10 => Precise);
      Strided : aliased OpenCV.Core.Float64_Vec4_Mat_View.Buffer_Array :=
        (7 .. 14 => Other64);
      Short   : aliased OpenCV.Core.Float64_Vec4_Mat_View.Buffer_Array :=
        (0 .. 6 => Precise);
      Saved   : OpenCV.Core.Mat;
      Invoked : Boolean := False;
      procedure Packed_View (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec4_Access.Get (Image, 0, 0) = Precise,
            "Float64 caller storage read without narrowing");
         OpenCV.Core.Float64_Vec4_Access.Set (Image, 1, 2, Other64);
         Saved := Image.Clone;
      end Packed_View;
      procedure Strided_View (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec4_Access.Get (Image, 0, 0) = Precise,
            "Float64 strided caller storage read");
         OpenCV.Core.Float64_Vec4_Access.Set (Image, 1, 2, Precise);
      end Strided_View;
      procedure Never (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Never;
      procedure Bad_Stride is
      begin
         OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Strided_Mat_View
           (Strided, 2, 3, 2, Never'Access);
      end Bad_Stride;
      procedure Bad_Backing is
      begin
         OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Strided_Mat_View
           (Short, 2, 3, 4, Never'Access);
      end Bad_Backing;
   begin
      OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Mat_View
        (Packed, 2, 3, Packed_View'Access);
      AUnit.Assertions.Assert
        (Packed (10) = Other64, "Float64 packed view writes caller memory");
      Packed (10) := Precise;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec4_Access.Get (Saved, 1, 2) = Other64,
         "Float64 Clone independently escapes view");
      Strided (7) := Precise;
      OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Strided_Mat_View
        (Strided, 2, 3, 4, Strided_View'Access);
      AUnit.Assertions.Assert
        (Strided (13) = Precise
         and then Strided (10) = Other64
         and then Strided (14) = Other64,
         "Float64 first/final row padding untouched");
      Assert_Raises_OpenCV_Error (Bad_Stride'Access, "Float64 short stride");
      Assert_Raises_OpenCV_Error (Bad_Backing'Access, "Float64 short backing");
      AUnit.Assertions.Assert
        (not Invoked, "Float64 rejected view callback not invoked");
   end Views64;

   procedure Transforms (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Src32      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 3));
      Src64      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float64, 3));
      Coeff32    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 3, (OpenCV.Core.Float32, 1));
      Coeff64    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 3, (OpenCV.Core.Float64, 1));
      Identity32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
      Identity64 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float64, 1));
   begin
      Coeff32.Set_To (OpenCV.Make_Scalar (0.0));
      Coeff64.Set_To (OpenCV.Make_Scalar (0.0));
      for I in 0 .. 2 loop
         OpenCV.Core.Float32_Access.Set (Coeff32, I, I, 1.0);
         OpenCV.Core.Float32_Access.Set (Coeff32, 3, I, 1.0);
         OpenCV.Core.Float64_Access.Set (Coeff64, I, I, 1.0);
         OpenCV.Core.Float64_Access.Set (Coeff64, 3, I, 1.0);
      end loop;
      Identity32.Set_Identity;
      Identity64.Set_Identity;
      OpenCV.Core.Float32_Vec3_Access.Set (Src32, 0, 0, (2.0, 3.0, 4.0));
      OpenCV.Core.Float64_Vec3_Access.Set (Src64, 0, 0, (A, B, C));
      declare
         Out32 : OpenCV.Core.Mat := Src32.Transform (Coeff32);
         Out64 : OpenCV.Core.Mat := Src64.Transform (Coeff64);
      begin
         AUnit.Assertions.Assert
           (Out32.Channels = 4
            and then OpenCV.Core.Float32_Vec4_Access.Get (Out32, 0, 0)
                     = Value32,
            "Float32 Transform C3 to C4 directly readable as Vec4");
         AUnit.Assertions.Assert
           (Out64.Channels = 4
            and then OpenCV.Core.Float64_Vec4_Access.Get (Out64, 0, 0)
                     = (A, B, C, A + B + C),
            "Float64 Transform C3 to C4 retains binary64 through Vec4");
         OpenCV.Core.Float32_Vec4_Access.Set (Out32, 0, 0, Value32);
         OpenCV.Core.Float64_Vec4_Access.Set (Out64, 0, 0, Precise);
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Vec4_Access.Get
              (Out32.Transform (Identity32), 0, 0)
            = Value32
            and then OpenCV.Core.Float64_Vec4_Access.Get
                       (Out64.Transform (Identity64), 0, 0)
                     = Precise,
            "C4 to C4 identity Transform uses Vec4 input and output");
      end;
   end Transforms;

   procedure Channels_And_Scalar (Test : in out Fixture) is
      pragma Unreferenced (Test);
      One          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Two          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Three        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Four         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Scalar_Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float64, 4));
   begin
      OpenCV.Core.Float32_Access.Set (One, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Two, 0, 0, 3.0);
      OpenCV.Core.Float32_Access.Set (Three, 0, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Four, 0, 0, 9.0);
      declare
         Channels : constant OpenCV.Core.Mat_Array (7 .. 10) :=
           (One, Two, Three, Four);
         Merged   : OpenCV.Core.Mat := OpenCV.Core.Merge (Channels);
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float32_Vec4_Access.Get (Merged, 0, 0) = Value32,
            "Merge four C1 Mats in Ada iteration order yields C4 Vec4");
         OpenCV.Core.Float32_Vec4_Access.Set (Merged, 0, 0, Other32);
         declare
            Parts : constant OpenCV.Core.Mat_Array := Merged.Split;
         begin
            AUnit.Assertions.Assert
              (Parts'Length = 4
               and then OpenCV.Core.Float32_Access.Get
                          (Parts (Parts'First), 0, 0)
                        = 9.0
               and then OpenCV.Core.Float32_Access.Get
                          (Parts (Parts'Last), 0, 0)
                        = 2.0,
               "Split Vec4 element preserves first and last C1 components");
         end;
      end;
      Scalar_Image.Set_To (OpenCV.Make_Scalar (1.0, 2.0, 3.0, 4.0));
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec4_Access.Get (Scalar_Image, 0, 0)
         = (1.0, 2.0, 3.0, 4.0),
         "Scalar initialization fills all four Vec4 channels");
   end Channels_And_Scalar;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Vec4 raw ABI guards and same-width layouts",
            Raw_ABI_Safety'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec4 2-D and N-D elements", Elements32'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec4 2-D and N-D exact elements", Elements64'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec4 copied and borrowed rows and buffers",
            Rows_Buffers32'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec4 copied and borrowed rows and buffers",
            Rows_Buffers64'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec4 caller-owned packed and strided views",
            Views32'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec4 caller-owned packed and strided views",
            Views64'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 and Float64 Vec4 Transform interoperability",
            Transforms'Access));
      Result.Add_Test
        (Caller.Create
           ("Vec4 Merge Split and Scalar interoperability",
            Channels_And_Scalar'Access));
      return Result'Access;
   end Suite;
end Vec4_Tests;
