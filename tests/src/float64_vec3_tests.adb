with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float64_Vec3;
with OpenCV.Core.Float64_Vec3_Access;
with OpenCV.Core.Float64_Vec3_Row_Access;
with OpenCV.Core.Float64_Vec3_Buffer_Access;
with OpenCV.Core.Float64_Vec3_Mat_View;
with Float64_Vec3_Tests.Raw_ABI;

package body Float64_Vec3_Tests is
   use type OpenCV.Float64_Value;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Float64_Vec3.Vector;
   use Mat_Test_Support;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   A       : constant OpenCV.Float64_Value := 1.0 + 2.0**(-40);
   B       : constant OpenCV.Float64_Value := -2.0 - 2.0**(-42);
   C       : constant OpenCV.Float64_Value := 3.0 + 2.0**(-44);
   Precise : constant OpenCV.Core.Float64_Vec3.Vector := (A, B, C);
   Other   : constant OpenCV.Core.Float64_Vec3.Vector := (C, A, B);

   procedure Raw_ABI_Safety (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check;
   end Raw_ABI_Safety;

   procedure Elements (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 3));
      Alias   : OpenCV.Core.Mat;
      Copy    : OpenCV.Core.Mat;
      Volume  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float64, 3));
      Shifted : constant OpenCV.Core.Index_Array (7 .. 9) := (1, 2, 3);
      procedure Bad_Row is
         V : constant OpenCV.Core.Float64_Vec3.Vector :=
           OpenCV.Core.Float64_Vec3_Access.Get (Image, -1, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Row;
      procedure Bad_Count is
      begin
         OpenCV.Core.Float64_Vec3_Access.Set (Volume, (1, 2), Precise);
      end Bad_Count;
      procedure Bad_Axis is
         V : constant OpenCV.Core.Float64_Vec3.Vector :=
           OpenCV.Core.Float64_Vec3_Access.Get (Volume, (1, 3, 0));
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Axis;
   begin
      Image.Set_To (OpenCV.Make_Scalar (0.0, 0.0, 0.0));
      OpenCV.Core.Float64_Vec3_Access.Set (Image, 1, 2, Precise);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec3_Access.Get (Image, 1, 2) = Precise
         and then OpenCV.Core.Float64_Vec3_Access.Get (Image, (1, 2)) = Precise
         and then OpenCV.Core.Float64_Vec3_Access.Get (Image, 1, 1)
                  = (0.0, 0.0, 0.0),
         "Float64 C3 2-D exact element order and neighbor isolation");
      Alias := Image;
      Copy := Image.Clone;
      OpenCV.Core.Float64_Vec3_Access.Set (Alias, (1, 2), Other);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec3_Access.Get (Image, 1, 2) = Other
         and then OpenCV.Core.Float64_Vec3_Access.Get (Copy, 1, 2) = Precise,
         "shallow assignment shares, Clone isolates");
      Volume.Set_To (OpenCV.Make_Scalar (0.0, 0.0, 0.0));
      OpenCV.Core.Float64_Vec3_Access.Set (Volume, Shifted, Precise);
      OpenCV.Core.Float64_Vec3_Access.Set (Volume, (0, 1, 2), Other);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec3_Access.Get (Volume, (1, 2, 3)) = Precise
         and then OpenCV.Core.Float64_Vec3_Access.Get (Volume, (0, 1, 2))
                  = Other
         and then OpenCV.Core.Float64_Vec3_Access.Get (Volume, (1, 2, 2))
                  = (0.0, 0.0, 0.0),
         "N-D shifted indices preserve dimension order and neighbors");
      Assert_Raises_OpenCV_Error (Bad_Row'Access, "negative row");
      Assert_Raises_OpenCV_Error (Bad_Count'Access, "too few indices");
      Assert_Raises_OpenCV_Error (Bad_Axis'Access, "past N-D axis");
   end Elements;

   procedure Rows_And_Buffers (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 3));
      Alias : OpenCV.Core.Mat;
      Row   : aliased OpenCV.Core.Float64_Vec3_Row_Access.Row_Array (8 .. 10);
      procedure Read_Row
        (Data : aliased OpenCV.Core.Float64_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 3 and then Data (2) = Precise,
            "borrowed row exposes complete elements");
      end Read_Row;
      procedure Write_Row
        (Data : aliased in out OpenCV.Core.Float64_Vec3_Row_Access.Row_Array)
      is
      begin
         Data (1) := Other;
      end Write_Row;
      procedure Read_Buffer
        (Data : aliased OpenCV.Core.Float64_Vec3_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 6 and then Data (5) = Precise,
            "flat buffer has six Vec3s, not 18 doubles");
      end Read_Buffer;
      procedure Write_Buffer
        (Data :
           aliased in out OpenCV.Core.Float64_Vec3_Buffer_Access.Buffer_Array)
      is
      begin
         Data (0) := Precise;
      end Write_Buffer;
   begin
      Image.Set_To (OpenCV.Make_Scalar (0.0, 0.0, 0.0));
      Row := (others => Precise);
      OpenCV.Core.Float64_Vec3_Row_Access.Write_Row (Image, 1, Row);
      OpenCV.Core.Float64_Vec3_Row_Access.Read_Row (Image, 1, Row);
      AUnit.Assertions.Assert
        (Row (8) = Precise and then Row (10) = Precise,
         "copied shifted row preserves binary64");
      Alias := Image;
      OpenCV.Core.Float64_Vec3_Row_Access.With_Read_Only_Row
        (Image, 1, Read_Row'Access);
      OpenCV.Core.Float64_Vec3_Row_Access.With_Writable_Row
        (Image, 1, Write_Row'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec3_Access.Get (Alias, 1, 1) = Other,
         "row borrow writes immediately through aliases");
      OpenCV.Core.Float64_Vec3_Buffer_Access.With_Read_Only_Buffer
        (Image, Read_Buffer'Access);
      OpenCV.Core.Float64_Vec3_Buffer_Access.With_Writable_Buffer
        (Image, Write_Buffer'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec3_Access.Get (Alias, 0, 0) = Precise,
         "buffer borrow writes through alias without narrowing");
   end Rows_And_Buffers;

   procedure Views (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Packed  : aliased OpenCV.Core.Float64_Vec3_Mat_View.Buffer_Array :=
        (5 .. 10 => Precise);
      Strided : aliased OpenCV.Core.Float64_Vec3_Mat_View.Buffer_Array :=
        (7 .. 14 => Other);
      Saved   : OpenCV.Core.Mat;
      procedure Packed_View (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec3_Access.Get (Image, 0, 0) = Precise,
            "caller storage visible in packed Mat");
         OpenCV.Core.Float64_Vec3_Access.Set (Image, 1, 2, Other);
         Saved := Image.Clone;
      end Packed_View;
      procedure Strided_View (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec3_Access.Get (Image, 0, 0) = Precise,
            "strided first logical element");
         OpenCV.Core.Float64_Vec3_Access.Set (Image, 1, 2, Precise);
      end Strided_View;
      procedure Short_Stride (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         null;
      end Short_Stride;
      procedure Bad_Stride is
      begin
         OpenCV.Core.Float64_Vec3_Mat_View.With_Writable_Strided_Mat_View
           (Strided, 2, 3, 2, Short_Stride'Access);
      end Bad_Stride;
   begin
      OpenCV.Core.Float64_Vec3_Mat_View.With_Writable_Mat_View
        (Packed, 2, 3, Packed_View'Access);
      AUnit.Assertions.Assert
        (Packed (10) = Other, "packed Mat writes caller memory");
      Packed (10) := Precise;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec3_Access.Get (Saved, 1, 2) = Other,
         "Clone escapes independently");
      Strided (7) := Precise;
      OpenCV.Core.Float64_Vec3_Mat_View.With_Writable_Strided_Mat_View
        (Strided, 2, 3, 4, Strided_View'Access);
      AUnit.Assertions.Assert
        (Strided (13) = Precise
         and then Strided (10) = Other
         and then Strided (14) = Other,
         "both row paddings remain untouched");
      Assert_Raises_OpenCV_Error (Bad_Stride'Access, "short stride");
   end Views;

   procedure Transforms (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float64, 3));
      Identity : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float64, 1));
      Affine   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float64, 1));
   begin
      Identity.Set_Identity;
      Affine.Set_Identity;
      OpenCV.Core.Float64_Vec3_Access.Set (Source, 0, 0, Precise);
      declare
         P : constant OpenCV.Core.Mat :=
           Source.Perspective_Transform (Identity);
         T : constant OpenCV.Core.Mat := Source.Transform (Affine);
      begin
         AUnit.Assertions.Assert
           (P.Depth = OpenCV.Core.Float64
            and then P.Channels = 3
            and then OpenCV.Core.Float64_Vec3_Access.Get (P, 0, 0) = Precise,
            "identity perspective preserves binary64 precision");
         AUnit.Assertions.Assert
           (T.Depth = OpenCV.Core.Float64
            and then T.Channels = 3
            and then OpenCV.Core.Float64_Vec3_Access.Get (T, 0, 0) = Precise,
            "Transform Float64 C3 output directly readable");
      end;
      OpenCV.Core.Float64_Access.Set (Identity, 3, 3, 2.0);
      OpenCV.Core.Float64_Vec3_Access.Set (Source, 0, 0, (2.0, 4.0, 1.0));
      declare
         P : constant OpenCV.Core.Mat :=
           Source.Perspective_Transform (Identity);
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec3_Access.Get (P, 0, 0) = (1.0, 2.0, 0.5),
            "4x4 homogeneous division directly inspected as Float64 Vec3");
      end;
   end Transforms;

   procedure Validation (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 3));
      Wrong_Depth    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 3));
      Wrong_Channels : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 2));
      Data           : OpenCV.Core.Float64_Vec3_Row_Access.Row_Array (1 .. 2);
      procedure Get_Depth is
         V : constant OpenCV.Core.Float64_Vec3.Vector :=
           OpenCV.Core.Float64_Vec3_Access.Get (Wrong_Depth, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Get_Depth;
      procedure Set_Depth is
      begin
         OpenCV.Core.Float64_Vec3_Access.Set (Wrong_Depth, (0, 0), Precise);
      end Set_Depth;
      procedure Get_Channels is
         V : constant OpenCV.Core.Float64_Vec3.Vector :=
           OpenCV.Core.Float64_Vec3_Access.Get (Wrong_Channels, (0, 0));
         pragma Unreferenced (V);
      begin
         null;
      end Get_Channels;
      procedure Set_Channels is
      begin
         OpenCV.Core.Float64_Vec3_Access.Set (Wrong_Channels, 0, 0, Precise);
      end Set_Channels;
      procedure Get_Past is
         V : constant OpenCV.Core.Float64_Vec3.Vector :=
           OpenCV.Core.Float64_Vec3_Access.Get (Image, 0, 3);
         pragma Unreferenced (V);
      begin
         null;
      end Get_Past;
      procedure Set_Past is
      begin
         OpenCV.Core.Float64_Vec3_Access.Set (Image, -1, 0, Precise);
      end Set_Past;
      procedure Get_Too_Many is
         V : constant OpenCV.Core.Float64_Vec3.Vector :=
           OpenCV.Core.Float64_Vec3_Access.Get (Image, (0, 0, 0));
         pragma Unreferenced (V);
      begin
         null;
      end Get_Too_Many;
      procedure Set_Too_Many is
      begin
         OpenCV.Core.Float64_Vec3_Access.Set (Image, (0, 0, 0), Precise);
      end Set_Too_Many;
      procedure Bad_Row_Size is
      begin
         OpenCV.Core.Float64_Vec3_Row_Access.Read_Row (Image, 0, Data);
      end Bad_Row_Size;
      procedure Bad_Row_Depth is
      begin
         OpenCV.Core.Float64_Vec3_Row_Access.Write_Row (Wrong_Depth, 0, Data);
      end Bad_Row_Depth;
      procedure Bad_Row_Channels is
      begin
         OpenCV.Core.Float64_Vec3_Row_Access.Read_Row
           (Wrong_Channels, 0, Data);
      end Bad_Row_Channels;
      procedure Bad_Row_Index is
      begin
         OpenCV.Core.Float64_Vec3_Row_Access.Write_Row (Image, 2, Data);
      end Bad_Row_Index;
   begin
      Assert_Raises_OpenCV_Error (Get_Depth'Access, "Get wrong depth");
      Assert_Raises_OpenCV_Error (Set_Depth'Access, "Set wrong depth");
      Assert_Raises_OpenCV_Error (Get_Channels'Access, "Get wrong channels");
      Assert_Raises_OpenCV_Error (Set_Channels'Access, "Set wrong channels");
      Assert_Raises_OpenCV_Error (Get_Past'Access, "Get past column");
      Assert_Raises_OpenCV_Error (Set_Past'Access, "Set negative row");
      Assert_Raises_OpenCV_Error (Get_Too_Many'Access, "Get too many indices");
      Assert_Raises_OpenCV_Error (Set_Too_Many'Access, "Set too many indices");
      Assert_Raises_OpenCV_Error (Bad_Row_Size'Access, "row length mismatch");
      Assert_Raises_OpenCV_Error (Bad_Row_Depth'Access, "row wrong depth");
      Assert_Raises_OpenCV_Error
        (Bad_Row_Channels'Access, "row wrong channels");
      Assert_Raises_OpenCV_Error (Bad_Row_Index'Access, "past row");
   end Validation;

   procedure Borrow_Boundaries (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.Float64, 3));
      Alias      : OpenCV.Core.Mat := Image;
      ROI        : OpenCV.Core.Mat :=
        Image.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      Invoked    : Boolean := False;
      procedure Read_Row
        (Data : aliased OpenCV.Core.Float64_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 2 and then Data (0) = Precise,
            "non-contiguous row excludes padding");
      end Read_Row;
      procedure Write_Row
        (Data : aliased in out OpenCV.Core.Float64_Vec3_Row_Access.Row_Array)
      is
      begin
         Data (0) := Other;
         raise Constraint_Error;
      end Write_Row;
      procedure Observe
        (Data : aliased OpenCV.Core.Float64_Vec3_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Observe;
      procedure Write_Buffer
        (Data :
           aliased in out OpenCV.Core.Float64_Vec3_Buffer_Access.Buffer_Array)
      is
      begin
         Data (0) := Precise;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec3_Access.Get (Alias, 0, 0) = Precise,
            "shallow alias observes borrowed buffer write");
         Alias := OpenCV.Core.Create (1, 1, (OpenCV.Core.Float64, 3));
         AUnit.Assertions.Assert
           (Data (0) = Precise, "lease protects storage after header rebind");
         raise Constraint_Error;
      end Write_Buffer;
      procedure Short_View (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Short_View;
      Short_Data : aliased OpenCV.Core.Float64_Vec3_Mat_View.Buffer_Array :=
        (0 .. 6 => Other);
      procedure Bad_Backing is
      begin
         OpenCV.Core.Float64_Vec3_Mat_View.With_Writable_Strided_Mat_View
           (Short_Data, 2, 3, 4, Short_View'Access);
      end Bad_Backing;
      procedure Bad_Continuous is
      begin
         OpenCV.Core.Float64_Vec3_Buffer_Access.With_Read_Only_Buffer
           (ROI, Observe'Access);
      end Bad_Continuous;
   begin
      OpenCV.Core.Float64_Vec3_Access.Set (Image, 0, 1, Precise);
      OpenCV.Core.Float64_Vec3_Row_Access.With_Read_Only_Row
        (ROI, 0, Read_Row'Access);
      begin
         OpenCV.Core.Float64_Vec3_Row_Access.With_Writable_Row
           (ROI, 0, Write_Row'Access);
         AUnit.Assertions.Assert (False, "row callback exception swallowed");
      exception
         when Constraint_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec3_Access.Get (Image, 0, 1) = Other,
         "completed row write remains visible after exception");
      Assert_Raises_OpenCV_Error
        (Bad_Continuous'Access, "non-continuous buffer");
      AUnit.Assertions.Assert
        (not Invoked, "rejected buffer callback not invoked");
      Assert_Raises_OpenCV_Error
        (Bad_Backing'Access, "final row padding required");
      AUnit.Assertions.Assert
        (not Invoked, "rejected view callback not invoked");
      begin
         OpenCV.Core.Float64_Vec3_Buffer_Access.With_Writable_Buffer
           (Image, Write_Buffer'Access);
         AUnit.Assertions.Assert
           (False, "buffer callback exception swallowed");
      exception
         when Constraint_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec3_Access.Get (Image, 0, 0) = Precise,
         "completed buffer write remains visible");
   end Borrow_Boundaries;

   procedure Continuous_Region_And_Row_Lease (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float64, 3));
      Alias      : OpenCV.Core.Mat := Image;
      Whole_Rows : constant OpenCV.Core.Mat :=
        Image.Region ((X => 0, Y => 1, Width => 3, Height => 2));
      procedure Observe
        (Data : aliased OpenCV.Core.Float64_Vec3_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 6 and then Data (0) = Precise,
            "continuous Region exposes six complete Vec3 elements");
      end Observe;
      procedure Rebind_And_Write
        (Data : aliased in out OpenCV.Core.Float64_Vec3_Row_Access.Row_Array)
      is
      begin
         Data (0) := Other;
         Image := OpenCV.Core.Create (1, 1, (OpenCV.Core.Float64, 3));
         AUnit.Assertions.Assert
           (Data (0) = Other, "borrowed row lease survives header rebind");
      end Rebind_And_Write;
   begin
      OpenCV.Core.Float64_Vec3_Access.Set (Image, 1, 0, Precise);
      OpenCV.Core.Float64_Vec3_Buffer_Access.With_Read_Only_Buffer
        (Whole_Rows, Observe'Access);
      OpenCV.Core.Float64_Vec3_Row_Access.With_Writable_Row
        (Alias, 1, Rebind_And_Write'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Vec3_Access.Get (Alias, 1, 0) = Other,
         "row lease retains shared storage and writes remain visible");
   end Continuous_Region_And_Row_Lease;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create ("Float64 Vec3 2-D and N-D elements", Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec3 rows and buffers", Rows_And_Buffers'Access));
      Result.Add_Test
        (Caller.Create ("Float64 Vec3 external views", Views'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec3 transform interoperability", Transforms'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec3 raw ABI rejection", Raw_ABI_Safety'Access));
      Result.Add_Test
        (Caller.Create ("Float64 Vec3 validation paths", Validation'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec3 borrowing boundaries", Borrow_Boundaries'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 Vec3 continuous Region and row lease",
            Continuous_Region_And_Row_Lease'Access));
      return Result'Access;
   end Suite;
end Float64_Vec3_Tests;
