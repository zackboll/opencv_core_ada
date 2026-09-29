with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Int8_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Int8_Vec2;
with OpenCV.Core.Int8_Vec3;
with OpenCV.Core.Int8_Vec4;
with OpenCV.Core.Int8_Vec2_Access;
with OpenCV.Core.Int8_Vec3_Access;
with OpenCV.Core.Int8_Vec4_Access;
with OpenCV.Core.Int8_Vec2_Row_Access;
with OpenCV.Core.Int8_Vec3_Row_Access;
with OpenCV.Core.Int8_Vec4_Row_Access;
with OpenCV.Core.Int8_Vec2_Buffer_Access;
with OpenCV.Core.Int8_Vec3_Buffer_Access;
with OpenCV.Core.Int8_Vec4_Buffer_Access;
with OpenCV.Core.Int8_Vec2_Mat_View;
with OpenCV.Core.Int8_Vec3_Mat_View;
with OpenCV.Core.Int8_Vec4_Mat_View;
with Int8_Vector_Tests.Raw_ABI;

package body Int8_Vector_Tests is
   use Mat_Test_Support;
   use type OpenCV.Core.Int8_Vec2.Vector;
   use type OpenCV.Core.Int8_Vec3.Vector;
   use type OpenCV.Core.Int8_Vec4.Vector;
   use type OpenCV.Core.Int8_Vec2_Row_Access.Row_Array;
   use type OpenCV.Core.Int8_Vec3_Row_Access.Row_Array;
   use type OpenCV.Core.Int8_Vec4_Row_Access.Row_Array;
   use type OpenCV.Int8_Value;
   use type OpenCV.Int32_Value;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   subtype Fixture is Mat_Test_Fixture;
   subtype Int8_Value is OpenCV.Int8_Value;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   --  Mixed-sign samples covering both signed extrema and their neighbours;
   --  an unsigned (UInt8) reinterpretation would turn every negative into
   --  128 .. 255 and fail these equalities.
   A2 : constant OpenCV.Core.Int8_Vec2.Vector :=
     (Int8_Value'First, Int8_Value'Last);
   A3 : constant OpenCV.Core.Int8_Vec3.Vector := (-127, -1, 126);
   A4 : constant OpenCV.Core.Int8_Vec4.Vector :=
     (Int8_Value'First, 0, 1, Int8_Value'Last);
   B2 : constant OpenCV.Core.Int8_Vec2.Vector := (-1, 1);
   B3 : constant OpenCV.Core.Int8_Vec3.Vector := (-100, 0, 100);
   B4 : constant OpenCV.Core.Int8_Vec4.Vector := (-2, -1, 126, -127);

   function Int8_Mat
     (Rows, Columns : Positive; Width : Positive) return OpenCV.Core.Mat
   is (OpenCV.Core.Create
         (Rows,
          Columns,
          (OpenCV.Core.Int8, OpenCV.Core.Channel_Count (Width))));

   function Int8_Volume (Width : Positive) return OpenCV.Core.Mat
   is (OpenCV.Core.Create
         (Shape        => (2, 3, 4),
          Element_Type =>
            (OpenCV.Core.Int8, OpenCV.Core.Channel_Count (Width))));

   procedure Elements (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2                                          : OpenCV.Core.Mat :=
        Int8_Mat (2, 3, 2);
      M3                                          : OpenCV.Core.Mat :=
        Int8_Mat (2, 3, 3);
      M4                                          : OpenCV.Core.Mat :=
        Int8_Mat (2, 3, 4);
      N2                                          : OpenCV.Core.Mat :=
        Int8_Volume (2);
      N3                                          : OpenCV.Core.Mat :=
        Int8_Volume (3);
      N4                                          : OpenCV.Core.Mat :=
        Int8_Volume (4);
      Wrong_Depth                                 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 3));
      Indices                                     :
        constant OpenCV.Core.Index_Array (7 .. 9) := (1, 2, 3);
      Alias2, Alias3, Alias4, Copy2, Copy3, Copy4 : OpenCV.Core.Mat;
      procedure Bad_2D is
         V : constant OpenCV.Core.Int8_Vec2.Vector :=
           OpenCV.Core.Int8_Vec2_Access.Get (N2, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Bad_2D;
      procedure Bad_ND_Extent is
      begin
         OpenCV.Core.Int8_Vec3_Access.Set (N3, (0, 3, 0), A3);
      end Bad_ND_Extent;
      procedure Bad_ND_Count is
      begin
         OpenCV.Core.Int8_Vec4_Access.Set (N4, (0, 0), A4);
      end Bad_ND_Count;
      procedure Bad_Negative is
      begin
         OpenCV.Core.Int8_Vec2_Access.Set (M2, -1, 0, A2);
      end Bad_Negative;
      procedure Bad_Column is
         V : constant OpenCV.Core.Int8_Vec3.Vector :=
           OpenCV.Core.Int8_Vec3_Access.Get (M3, 0, 3);
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Column;
      procedure Bad_Channels is
         V : constant OpenCV.Core.Int8_Vec4.Vector :=
           OpenCV.Core.Int8_Vec4_Access.Get (M3, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Channels;
      procedure Bad_Depth is
         V : constant OpenCV.Core.Int8_Vec3.Vector :=
           OpenCV.Core.Int8_Vec3_Access.Get (Wrong_Depth, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Depth;
   begin
      OpenCV.Core.Int8_Vec2_Access.Set (M2, 1, 2, A2);
      OpenCV.Core.Int8_Vec3_Access.Set (M3, 1, 2, A3);
      OpenCV.Core.Int8_Vec4_Access.Set (M4, 1, 2, A4);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Vec2_Access.Get (M2, 1, 2) = A2
         and then OpenCV.Core.Int8_Vec3_Access.Get (M3, 1, 2) = A3
         and then OpenCV.Core.Int8_Vec4_Access.Get (M4, 1, 2) = A4,
         "2-D exact signed range");
      Alias2 := M2;
      Alias3 := M3;
      Alias4 := M4;
      Copy2 := M2.Clone;
      Copy3 := M3.Clone;
      Copy4 := M4.Clone;
      OpenCV.Core.Int8_Vec2_Access.Set (Alias2, 1, 2, B2);
      OpenCV.Core.Int8_Vec3_Access.Set (Alias3, 1, 2, B3);
      OpenCV.Core.Int8_Vec4_Access.Set (Alias4, 1, 2, B4);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Vec2_Access.Get (M2, 1, 2) = B2
         and then OpenCV.Core.Int8_Vec2_Access.Get (Copy2, 1, 2) = A2
         and then OpenCV.Core.Int8_Vec3_Access.Get (M3, 1, 2) = B3
         and then OpenCV.Core.Int8_Vec3_Access.Get (Copy3, 1, 2) = A3
         and then OpenCV.Core.Int8_Vec4_Access.Get (M4, 1, 2) = B4
         and then OpenCV.Core.Int8_Vec4_Access.Get (Copy4, 1, 2) = A4,
         "2-D assignment shares and Clone isolates");
      OpenCV.Core.Int8_Vec2_Access.Set (N2, Indices, A2);
      OpenCV.Core.Int8_Vec3_Access.Set (N3, Indices, A3);
      OpenCV.Core.Int8_Vec4_Access.Set (N4, Indices, A4);
      Alias2 := N2;
      Alias3 := N3;
      Alias4 := N4;
      Copy2 := N2.Clone;
      Copy3 := N3.Clone;
      Copy4 := N4.Clone;
      OpenCV.Core.Int8_Vec2_Access.Set (Alias2, Indices, B2);
      OpenCV.Core.Int8_Vec3_Access.Set (Alias3, Indices, B3);
      OpenCV.Core.Int8_Vec4_Access.Set (Alias4, Indices, B4);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Vec2_Access.Get (N2, (1, 2, 3)) = B2
         and then OpenCV.Core.Int8_Vec2_Access.Get (Copy2, Indices) = A2
         and then OpenCV.Core.Int8_Vec3_Access.Get (N3, Indices) = B3
         and then OpenCV.Core.Int8_Vec3_Access.Get (Copy3, Indices) = A3
         and then OpenCV.Core.Int8_Vec4_Access.Get (N4, Indices) = B4
         and then OpenCV.Core.Int8_Vec4_Access.Get (Copy4, Indices) = A4,
         "shifted N-D indices, N-D assignment and N-D Clone");
      Assert_Raises_OpenCV_Error (Bad_2D'Access, "2-D accessor rejects N-D");
      Assert_Raises_OpenCV_Error (Bad_ND_Extent'Access, "N-D extent");
      Assert_Raises_OpenCV_Error (Bad_ND_Count'Access, "N-D index count");
      Assert_Raises_OpenCV_Error (Bad_Negative'Access, "negative row");
      Assert_Raises_OpenCV_Error (Bad_Column'Access, "column extent");
      Assert_Raises_OpenCV_Error (Bad_Channels'Access, "exact channels");
      Assert_Raises_OpenCV_Error (Bad_Depth'Access, "UInt8 C3 is not Int8 C3");
   end Elements;

   Lease_Error : exception;
   procedure Rows_And_Leases (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2              : OpenCV.Core.Mat := Int8_Mat (2, 2, 2);
      M3              : OpenCV.Core.Mat := Int8_Mat (2, 2, 3);
      M4              : OpenCV.Core.Mat := Int8_Mat (2, 2, 4);
      Parent          : OpenCV.Core.Mat := Int8_Mat (2, 4, 3);
      Region          : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      Survivor2       : constant OpenCV.Core.Mat := M2;
      Survivor3       : constant OpenCV.Core.Mat := M3;
      Survivor4       : constant OpenCV.Core.Mat := M4;
      Parent_Survivor : constant OpenCV.Core.Mat := Parent;
      Region_Survivor : constant OpenCV.Core.Mat := Region;
      R2              : OpenCV.Core.Int8_Vec2_Row_Access.Row_Array (7 .. 8);
      R3              : OpenCV.Core.Int8_Vec3_Row_Access.Row_Array (7 .. 8);
      R4              : OpenCV.Core.Int8_Vec4_Row_Access.Row_Array (7 .. 8);
      Called          : Boolean := False;
      procedure Edit2
        (Data : aliased in out OpenCV.Core.Int8_Vec2_Row_Access.Row_Array) is
      begin
         M2 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := B2;
         raise Lease_Error;
      end Edit2;
      procedure Edit3
        (Data : aliased in out OpenCV.Core.Int8_Vec3_Row_Access.Row_Array) is
      begin
         M3 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := B3;
         raise Lease_Error;
      end Edit3;
      procedure Edit4
        (Data : aliased in out OpenCV.Core.Int8_Vec4_Row_Access.Row_Array) is
      begin
         M4 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := B4;
         raise Lease_Error;
      end Edit4;
      procedure Edit_Region
        (Data : aliased in out OpenCV.Core.Int8_Vec3_Row_Access.Row_Array) is
      begin
         Parent := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Region := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A3;
      end Edit_Region;
      procedure Read2
        (Data : aliased OpenCV.Core.Int8_Vec2_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data (0) = A2 and then Data (1) = A2,
            "borrowed Vec2 row");
      end Read2;
      procedure Read3
        (Data : aliased OpenCV.Core.Int8_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert (Data (1) = A3, "borrowed Vec3 row");
      end Read3;
      procedure Read4
        (Data : aliased OpenCV.Core.Int8_Vec4_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert (Data (1) = A4, "borrowed Vec4 row");
      end Read4;
      procedure Never
        (Data : aliased OpenCV.Core.Int8_Vec3_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Called := True;
      end Never;
      procedure Bad_Buffer is
      begin
         OpenCV.Core.Int8_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Region_Survivor, Never'Access);
      end Bad_Buffer;
      procedure Bad_Length is
         Short : OpenCV.Core.Int8_Vec2_Row_Access.Row_Array (0 .. 0);
      begin
         OpenCV.Core.Int8_Vec2_Row_Access.Read_Row (Survivor2, 0, Short);
      end Bad_Length;
      procedure Bad_Row_Type is
         Target : OpenCV.Core.Mat := Parent_Survivor;
      begin
         OpenCV.Core.Int8_Vec4_Row_Access.Write_Row
           (Target, 0, (A4, A4, A4, A4));
      end Bad_Row_Type;
   begin
      OpenCV.Core.Int8_Vec2_Row_Access.Write_Row (M2, 1, (7 => A2, 8 => A2));
      OpenCV.Core.Int8_Vec3_Row_Access.Write_Row (M3, 1, (7 => A3, 8 => A3));
      OpenCV.Core.Int8_Vec4_Row_Access.Write_Row (M4, 1, (7 => A4, 8 => A4));
      OpenCV.Core.Int8_Vec2_Row_Access.Read_Row (M2, 1, R2);
      OpenCV.Core.Int8_Vec3_Row_Access.Read_Row (M3, 1, R3);
      OpenCV.Core.Int8_Vec4_Row_Access.Read_Row (M4, 1, R4);
      AUnit.Assertions.Assert
        (R2 = (A2, A2) and then R3 = (A3, A3) and then R4 = (A4, A4),
         "shifted copied rows preserve exact signed channels");
      OpenCV.Core.Int8_Vec2_Row_Access.With_Read_Only_Row
        (M2, 1, Read2'Access);
      OpenCV.Core.Int8_Vec3_Row_Access.With_Read_Only_Row
        (M3, 1, Read3'Access);
      OpenCV.Core.Int8_Vec4_Row_Access.With_Read_Only_Row
        (M4, 1, Read4'Access);
      begin
         OpenCV.Core.Int8_Vec2_Row_Access.With_Writable_Row
           (M2, 1, Edit2'Access);
         AUnit.Assertions.Assert (False, "Vec2 row exception must propagate");
      exception
         when Lease_Error =>
            null;
      end;
      begin
         OpenCV.Core.Int8_Vec3_Row_Access.With_Writable_Row
           (M3, 1, Edit3'Access);
         AUnit.Assertions.Assert (False, "Vec3 row exception must propagate");
      exception
         when Lease_Error =>
            null;
      end;
      begin
         OpenCV.Core.Int8_Vec4_Row_Access.With_Writable_Row
           (M4, 1, Edit4'Access);
         AUnit.Assertions.Assert (False, "Vec4 row exception must propagate");
      exception
         when Lease_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Vec2_Access.Get (Survivor2, 1, 1) = B2
         and then OpenCV.Core.Int8_Vec3_Access.Get (Survivor3, 1, 1) = B3
         and then OpenCV.Core.Int8_Vec4_Access.Get (Survivor4, 1, 1) = B4,
         "borrowed row survives rebinding and callback exception");
      OpenCV.Core.Int8_Vec3_Row_Access.With_Writable_Row
        (Region, 1, Edit_Region'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Vec3_Access.Get (Region_Survivor, 1, 1) = A3
         and then OpenCV.Core.Int8_Vec3_Access.Get (Parent_Survivor, 1, 2)
                  = A3,
         "Region row survives parent and Region rebinding, shares storage");
      Assert_Raises_OpenCV_Error (Bad_Buffer'Access, "gapped buffer rejected");
      AUnit.Assertions.Assert (not Called, "rejected callback not invoked");
      Assert_Raises_OpenCV_Error (Bad_Length'Access, "row length mismatch");
      Assert_Raises_OpenCV_Error (Bad_Row_Type'Access, "row requires C4");
   end Rows_And_Leases;

   procedure Buffers_And_Views (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2        : OpenCV.Core.Mat := Int8_Mat (1, 2, 2);
      M3        : OpenCV.Core.Mat := Int8_Mat (1, 2, 3);
      M4        : OpenCV.Core.Mat := Int8_Mat (1, 2, 4);
      Survivor2 : constant OpenCV.Core.Mat := M2;
      Survivor3 : constant OpenCV.Core.Mat := M3;
      Survivor4 : constant OpenCV.Core.Mat := M4;
      V2        : aliased OpenCV.Core.Int8_Vec2_Mat_View.Buffer_Array :=
        (5 .. 8 => (others => 0));
      V3        : aliased OpenCV.Core.Int8_Vec3_Mat_View.Buffer_Array :=
        (5 .. 8 => (others => 0));
      V4        : aliased OpenCV.Core.Int8_Vec4_Mat_View.Buffer_Array :=
        (5 .. 8 => (others => 0));
      Escaped   : OpenCV.Core.Mat;
      procedure Edit2
        (Data :
           aliased in out OpenCV.Core.Int8_Vec2_Buffer_Access.Buffer_Array) is
      begin
         M2 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A2;
         raise Lease_Error;
      end Edit2;
      procedure Edit3
        (Data :
           aliased in out OpenCV.Core.Int8_Vec3_Buffer_Access.Buffer_Array) is
      begin
         M3 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A3;
         raise Lease_Error;
      end Edit3;
      procedure Edit4
        (Data :
           aliased in out OpenCV.Core.Int8_Vec4_Buffer_Access.Buffer_Array) is
      begin
         M4 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := A4;
         raise Lease_Error;
      end Edit4;
      procedure View2 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Int8_Vec2_Access.Set (Image, 1, 1, A2);
         Escaped := Image.Clone;
      end View2;
      procedure View3 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Int8_Vec3_Access.Set (Image, 1, 1, A3);
      end View3;
      procedure View4 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Int8_Vec4_Access.Set (Image, 1, 1, A4);
      end View4;
      procedure Inspect2 (Image : OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Vec2_Access.Get (Image, 1, 1) = A2,
            "read-only strided Vec2");
      end Inspect2;
      procedure Inspect3 (Image : OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Vec3_Access.Get (Image, 1, 1) = A3,
            "read-only strided Vec3");
      end Inspect3;
      procedure Inspect4 (Image : OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Int8_Vec4_Access.Get (Image, 1, 1) = A4,
            "read-only strided Vec4");
      end Inspect4;
   begin
      begin
         OpenCV.Core.Int8_Vec2_Buffer_Access.With_Writable_Buffer
           (M2, Edit2'Access);
         AUnit.Assertions.Assert (False, "Vec2 buffer exception");
      exception
         when Lease_Error =>
            null;
      end;
      begin
         OpenCV.Core.Int8_Vec3_Buffer_Access.With_Writable_Buffer
           (M3, Edit3'Access);
         AUnit.Assertions.Assert (False, "Vec3 buffer exception");
      exception
         when Lease_Error =>
            null;
      end;
      begin
         OpenCV.Core.Int8_Vec4_Buffer_Access.With_Writable_Buffer
           (M4, Edit4'Access);
         AUnit.Assertions.Assert (False, "Vec4 buffer exception");
      exception
         when Lease_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Vec2_Access.Get (Survivor2, 0, 1) = A2
         and then OpenCV.Core.Int8_Vec3_Access.Get (Survivor3, 0, 1) = A3
         and then OpenCV.Core.Int8_Vec4_Access.Get (Survivor4, 0, 1) = A4,
         "whole-buffer leases survive rebinding, keep writes after exception");

      --  Packed views over buffers with a shifted lower bound (5 .. 8).
      OpenCV.Core.Int8_Vec2_Mat_View.With_Writable_Mat_View
        (V2, 2, 2, View2'Access);
      OpenCV.Core.Int8_Vec3_Mat_View.With_Writable_Mat_View
        (V3, 2, 2, View3'Access);
      OpenCV.Core.Int8_Vec4_Mat_View.With_Writable_Mat_View
        (V4, 2, 2, View4'Access);
      AUnit.Assertions.Assert
        (V2 (8) = A2 and then V3 (8) = A3 and then V4 (8) = A4,
         "packed views write caller-owned complete signed elements");
      V2 (8) := B2;
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Vec2_Access.Get (Escaped, 1, 1) = A2,
         "Clone of a view is independent of caller storage");
      V2 (8) := A2;
      OpenCV.Core.Int8_Vec2_Mat_View.With_Read_Only_Strided_Mat_View
        (V2, 2, 2, 2, Inspect2'Access);
      OpenCV.Core.Int8_Vec3_Mat_View.With_Read_Only_Strided_Mat_View
        (V3, 2, 2, 2, Inspect3'Access);
      OpenCV.Core.Int8_Vec4_Mat_View.With_Read_Only_Strided_Mat_View
        (V4, 2, 2, 2, Inspect4'Access);

      --  Strided views: Row_Stride 3 counts complete vectors; padding
      --  entries (offsets 2 and 5) hold negative sentinels and must remain.
      declare
         G2 : aliased OpenCV.Core.Int8_Vec2_Mat_View.Buffer_Array :=
           (10 .. 15 => (-7, -7));
         G3 : aliased OpenCV.Core.Int8_Vec3_Mat_View.Buffer_Array :=
           (10 .. 15 => (-7, -7, -7));
         G4 : aliased OpenCV.Core.Int8_Vec4_Mat_View.Buffer_Array :=
           (10 .. 15 => (-7, -7, -7, -7));
      begin
         OpenCV.Core.Int8_Vec2_Mat_View.With_Writable_Strided_Mat_View
           (G2, 2, 2, 3, View2'Access);
         OpenCV.Core.Int8_Vec3_Mat_View.With_Writable_Strided_Mat_View
           (G3, 2, 2, 3, View3'Access);
         OpenCV.Core.Int8_Vec4_Mat_View.With_Writable_Strided_Mat_View
           (G4, 2, 2, 3, View4'Access);
         AUnit.Assertions.Assert
           (G2 (14) = A2 and then G3 (14) = A3 and then G4 (14) = A4,
            "row strides count complete vectors, not scalar channels");
         AUnit.Assertions.Assert
           (G2 (12) = (-7, -7)
            and then G2 (15) = (-7, -7)
            and then G3 (12) = (-7, -7, -7)
            and then G3 (15) = (-7, -7, -7)
            and then G4 (12) = (-7, -7, -7, -7)
            and then G4 (15) = (-7, -7, -7, -7),
            "strided views preserve negative padding");
      end;
   end Buffers_And_Views;

   --  Exhaustive signed-domain evidence. Pattern (Column, Component) visits
   --  every -128 .. 127 value exactly once per component as Column runs over
   --  0 .. 255, and neighbouring components differ, so sign loss, UInt8
   --  reinterpretation, a wrong component offset or channel reordering is
   --  detected.
   function Pattern (Column, Component : Natural) return Int8_Value
   is (Int8_Value ((Column + 97 * Component) mod 256 - 128));

   generic
      type Index is range <>;
      type Vector is array (Index) of Int8_Value;
      type Row_Array is array (Natural range <>) of Vector;
      type Buffer_Array is array (Natural range <>) of Vector;
      type View_Array is array (Natural range <>) of Vector;
      Width : Positive;
      with
        function Get
          (Image : OpenCV.Core.Mat; Row, Column : Integer) return Vector;
      with
        procedure Set
          (Image       : in out OpenCV.Core.Mat;
           Row, Column : Integer;
           Value       : Vector);
      with
        procedure Read_Row
          (Image : OpenCV.Core.Mat; Row : Natural; Data : out Row_Array);
      with
        procedure Write_Row
          (Image : in out OpenCV.Core.Mat; Row : Natural; Data : Row_Array);
      with
        procedure With_Read_Only_Buffer
          (Image   : OpenCV.Core.Mat;
           Process : not null access procedure (Data : aliased Buffer_Array));
      with
        procedure With_Writable_Mat_View
          (Data          : aliased in out View_Array;
           Rows, Columns : Positive;
           Process       :
             not null access procedure (Image : in out OpenCV.Core.Mat));
      with
        procedure With_Read_Only_Mat_View
          (Data          : aliased View_Array;
           Rows, Columns : Positive;
           Process       :
             not null access procedure (Image : OpenCV.Core.Mat));
   procedure Exhaustive;

   procedure Exhaustive is
      Name  : constant String := "Int8 C" & Positive'Image (Width);
      Image : OpenCV.Core.Mat := Int8_Mat (2, 256, Width);
      Row   : Row_Array (1000 .. 1255);
      View  : aliased View_Array := (3 .. 258 => (others => 0));
      Ok    : Boolean := True;

      function Expected (Column : Natural) return Vector is
         Result : Vector;
      begin
         for C in Index loop
            Result (C) := Pattern (Column, Natural (C));
         end loop;
         return Result;
      end Expected;

      procedure Check_Buffer (Data : aliased Buffer_Array) is
      begin
         Ok := Data'Length = 512;
         for K in Data'Range loop
            Ok := Ok and then Data (K) = Expected ((K - Data'First) mod 256);
         end loop;
      end Check_Buffer;

      procedure Fill_View (Target : in out OpenCV.Core.Mat) is
      begin
         for J in 0 .. 255 loop
            Set (Target, 0, J, Expected (J));
         end loop;
      end Fill_View;

      procedure Read_View (Source : OpenCV.Core.Mat) is
      begin
         Ok := True;
         for J in 0 .. 255 loop
            Ok := Ok and then Get (Source, 0, J) = Expected (J);
         end loop;
      end Read_View;
   begin
      --  Path 1: typed Set, copied row read into a shifted Ada array.
      for J in 0 .. 255 loop
         Set (Image, 0, J, Expected (J));
      end loop;
      Read_Row (Image, 0, Row);
      for J in Row'Range loop
         Ok := Ok and then Row (J) = Expected (J - Row'First);
      end loop;
      AUnit.Assertions.Assert (Ok, Name & " typed Set / copied row read");

      --  Path 2: copied row write, typed Get.
      Write_Row (Image, 1, Row);
      for J in 0 .. 255 loop
         Ok := Ok and then Get (Image, 1, J) = Expected (J);
      end loop;
      AUnit.Assertions.Assert (Ok, Name & " copied row write / typed Get");

      --  Path 3: zero-copy whole-buffer borrow over both rows.
      With_Read_Only_Buffer (Image, Check_Buffer'Access);
      AUnit.Assertions.Assert (Ok, Name & " whole-buffer borrow");

      --  Path 4: OpenCV's own CV_8S interpretation via Split + Int32.
      declare
         Parts : constant OpenCV.Core.Mat_Array := Image.Split;
      begin
         for C in 0 .. Width - 1 loop
            declare
               Wide : constant OpenCV.Core.Mat :=
                 Parts (Parts'First + C).Convert_To (OpenCV.Core.Int32);
            begin
               for J in 0 .. 255 loop
                  Ok :=
                    Ok
                    and then OpenCV.Core.Int32_Access.Get (Wide, 1, J)
                             = OpenCV.Int32_Value (Pattern (J, C));
               end loop;
            end;
         end loop;
      end;
      AUnit.Assertions.Assert (Ok, Name & " OpenCV sees signed channels");

      --  Path 5: caller-owned external views (writable, then read-only).
      With_Writable_Mat_View (View, 1, 256, Fill_View'Access);
      for K in View'Range loop
         Ok := Ok and then View (K) = Expected (K - View'First);
      end loop;
      AUnit.Assertions.Assert (Ok, Name & " writable external view");
      With_Read_Only_Mat_View (View, 1, 256, Read_View'Access);
      AUnit.Assertions.Assert (Ok, Name & " read-only external view");
   end Exhaustive;

   procedure Exhaustive_Vec2 is new
     Exhaustive
       (Index                   => OpenCV.Core.Int8_Vec2.Component_Index,
        Vector                  => OpenCV.Core.Int8_Vec2.Vector,
        Row_Array               => OpenCV.Core.Int8_Vec2_Row_Access.Row_Array,
        Buffer_Array            =>
          OpenCV.Core.Int8_Vec2_Buffer_Access.Buffer_Array,
        View_Array              => OpenCV.Core.Int8_Vec2_Mat_View.Buffer_Array,
        Width                   => 2,
        Get                     => OpenCV.Core.Int8_Vec2_Access.Get,
        Set                     => OpenCV.Core.Int8_Vec2_Access.Set,
        Read_Row                => OpenCV.Core.Int8_Vec2_Row_Access.Read_Row,
        Write_Row               => OpenCV.Core.Int8_Vec2_Row_Access.Write_Row,
        With_Read_Only_Buffer   =>
          OpenCV.Core.Int8_Vec2_Buffer_Access.With_Read_Only_Buffer,
        With_Writable_Mat_View  =>
          OpenCV.Core.Int8_Vec2_Mat_View.With_Writable_Mat_View,
        With_Read_Only_Mat_View =>
          OpenCV.Core.Int8_Vec2_Mat_View.With_Read_Only_Mat_View);

   procedure Exhaustive_Vec3 is new
     Exhaustive
       (Index                   => OpenCV.Core.Int8_Vec3.Component_Index,
        Vector                  => OpenCV.Core.Int8_Vec3.Vector,
        Row_Array               => OpenCV.Core.Int8_Vec3_Row_Access.Row_Array,
        Buffer_Array            =>
          OpenCV.Core.Int8_Vec3_Buffer_Access.Buffer_Array,
        View_Array              => OpenCV.Core.Int8_Vec3_Mat_View.Buffer_Array,
        Width                   => 3,
        Get                     => OpenCV.Core.Int8_Vec3_Access.Get,
        Set                     => OpenCV.Core.Int8_Vec3_Access.Set,
        Read_Row                => OpenCV.Core.Int8_Vec3_Row_Access.Read_Row,
        Write_Row               => OpenCV.Core.Int8_Vec3_Row_Access.Write_Row,
        With_Read_Only_Buffer   =>
          OpenCV.Core.Int8_Vec3_Buffer_Access.With_Read_Only_Buffer,
        With_Writable_Mat_View  =>
          OpenCV.Core.Int8_Vec3_Mat_View.With_Writable_Mat_View,
        With_Read_Only_Mat_View =>
          OpenCV.Core.Int8_Vec3_Mat_View.With_Read_Only_Mat_View);

   procedure Exhaustive_Vec4 is new
     Exhaustive
       (Index                   => OpenCV.Core.Int8_Vec4.Component_Index,
        Vector                  => OpenCV.Core.Int8_Vec4.Vector,
        Row_Array               => OpenCV.Core.Int8_Vec4_Row_Access.Row_Array,
        Buffer_Array            =>
          OpenCV.Core.Int8_Vec4_Buffer_Access.Buffer_Array,
        View_Array              => OpenCV.Core.Int8_Vec4_Mat_View.Buffer_Array,
        Width                   => 4,
        Get                     => OpenCV.Core.Int8_Vec4_Access.Get,
        Set                     => OpenCV.Core.Int8_Vec4_Access.Set,
        Read_Row                => OpenCV.Core.Int8_Vec4_Row_Access.Read_Row,
        Write_Row               => OpenCV.Core.Int8_Vec4_Row_Access.Write_Row,
        With_Read_Only_Buffer   =>
          OpenCV.Core.Int8_Vec4_Buffer_Access.With_Read_Only_Buffer,
        With_Writable_Mat_View  =>
          OpenCV.Core.Int8_Vec4_Mat_View.With_Writable_Mat_View,
        With_Read_Only_Mat_View =>
          OpenCV.Core.Int8_Vec4_Mat_View.With_Read_Only_Mat_View);

   procedure Exhaustive_Domain (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Exhaustive_Vec2;
      Exhaustive_Vec3;
      Exhaustive_Vec4;
   end Exhaustive_Domain;

   procedure Channels_And_Transform (Test : in out Fixture) is
      pragma Unreferenced (Test);
      C1     : OpenCV.Core.Mat_Array (1 .. 4) :=
        (others => Int8_Mat (1, 1, 1));
      Values : constant array (1 .. 4) of Int8_Value :=
        (Int8_Value'First, -1, 1, Int8_Value'Last);
      procedure Check (N : Positive) is
         Source       : OpenCV.Core.Mat := Int8_Mat (1, 1, N);
         Coefficients : OpenCV.Core.Mat :=
           OpenCV.Core.Create (N, N, (OpenCV.Core.Float64, 1));
      begin
         for I in 1 .. N loop
            OpenCV.Core.Int8_Access.Set (C1 (I), 0, 0, Values (I));
         end loop;
         declare
            Merged : constant OpenCV.Core.Mat :=
              OpenCV.Core.Merge (C1 (1 .. N));
            Parts  : constant OpenCV.Core.Mat_Array := Merged.Split;
         begin
            AUnit.Assertions.Assert
              (Merged.Depth = OpenCV.Core.Int8
               and then Merged.Channels = OpenCV.Core.Channel_Count (N),
               "Merge produces Int8 C" & Positive'Image (N));
            for I in 1 .. N loop
               AUnit.Assertions.Assert
                 (OpenCV.Core.Int8_Access.Get
                    (Parts (Parts'First + I - 1), 0, 0)
                  = Values (I),
                  "Int8 Merge Split exact signed components");
            end loop;
            case N is
               when 2      =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int8_Vec2_Access.Get (Merged, 0, 0)
                     = (Values (1), Values (2)),
                     "Vec2 Merge channel order");

               when 3      =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int8_Vec3_Access.Get (Merged, 0, 0)
                     = (Values (1), Values (2), Values (3)),
                     "Vec3 Merge channel order");

               when others =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int8_Vec4_Access.Get (Merged, 0, 0)
                     = (Values (1), Values (2), Values (3), Values (4)),
                     "Vec4 Merge channel order");
            end case;
         end;

         --  Set_To with representable signed scalars, then identity
         --  Transform with modest values (no saturation involved).
         Source.Set_To (OpenCV.Make_Scalar (-10.0, 12.0, -3.0, 4.0));
         Coefficients.Set_Identity;
         declare
            Transformed : constant OpenCV.Core.Mat :=
              Source.Transform (Coefficients);
         begin
            case N is
               when 2      =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int8_Vec2_Access.Get (Source, 0, 0)
                     = (-10, 12)
                     and then OpenCV.Core.Int8_Vec2_Access.Get
                                (Transformed, 0, 0)
                              = (-10, 12),
                     "Vec2 Set_To and identity Transform");

               when 3      =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int8_Vec3_Access.Get (Source, 0, 0)
                     = (-10, 12, -3)
                     and then OpenCV.Core.Int8_Vec3_Access.Get
                                (Transformed, 0, 0)
                              = (-10, 12, -3),
                     "Vec3 Set_To and identity Transform");

               when others =>
                  AUnit.Assertions.Assert
                    (OpenCV.Core.Int8_Vec4_Access.Get (Source, 0, 0)
                     = (-10, 12, -3, 4)
                     and then OpenCV.Core.Int8_Vec4_Access.Get
                                (Transformed, 0, 0)
                              = (-10, 12, -3, 4),
                     "Vec4 Set_To and identity Transform");
            end case;
         end;
      end Check;
      Source : OpenCV.Core.Mat := Int8_Mat (1, 1, 2);
      Expand : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 2, (OpenCV.Core.Float64, 1));
      Left   : OpenCV.Core.Mat := Int8_Mat (1, 2, 3);
      Right  : OpenCV.Core.Mat := Int8_Mat (1, 2, 3);
   begin
      for N in 2 .. 4 loop
         Check (N);
      end loop;

      --  C2 -> C3 expansion: (a, b) -> (a, b, a + b).
      Source.Set_To (OpenCV.Make_Scalar (-10.0, 4.0));
      Expand.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Float64_Access.Set (Expand, 0, 0, 1.0);
      OpenCV.Core.Float64_Access.Set (Expand, 1, 1, 1.0);
      OpenCV.Core.Float64_Access.Set (Expand, 2, 0, 1.0);
      OpenCV.Core.Float64_Access.Set (Expand, 2, 1, 1.0);
      declare
         Expanded : constant OpenCV.Core.Mat := Source.Transform (Expand);
      begin
         AUnit.Assertions.Assert
           (Expanded.Depth = OpenCV.Core.Int8
            and then Expanded.Channels = 3
            and then OpenCV.Core.Int8_Vec3_Access.Get (Expanded, 0, 0)
                     = (-10, 4, -6),
            "Int8 C2 to C3 Transform");
      end;

      --  Optional arithmetic regression: existing Add on CV_8SC3 with
      --  values far from saturation (no arithmetic production change).
      Left.Set_To (OpenCV.Make_Scalar (0.0));
      Right.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Int8_Vec3_Access.Set (Left, 0, 1, (-10, 20, -30));
      OpenCV.Core.Int8_Vec3_Access.Set (Right, 0, 1, (3, -25, 12));
      AUnit.Assertions.Assert
        (OpenCV.Core.Int8_Vec3_Access.Get (OpenCV.Core.Add (Left, Right), 0, 1)
         = (-7, -5, -18),
         "existing Add supports Int8 C3");
   end Channels_And_Transform;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Int8 Vec2/3/4 exact signed elements, validation and ownership",
            Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 Vec2/3/4 copied rows and borrowed leases",
            Rows_And_Leases'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 Vec2/3/4 whole buffers and caller views",
            Buffers_And_Views'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 Vec2/3/4 exhaustive -128 .. 127 per component",
            Exhaustive_Domain'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 Vec2/3/4 Merge Split Set_To Transform Add",
            Channels_And_Transform'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 Vec2/3/4 raw ABI rejects same-byte wrong layouts",
            Raw_ABI.Check_Wrong_Layouts'Access));
      Result.Add_Test
        (Caller.Create
           ("Int8 Vec2/3/4 raw ABI geometry on matching fixtures",
            Raw_ABI.Check_Geometry'Access));
      return Result'Access;
   end Suite;
end Int8_Vector_Tests;
