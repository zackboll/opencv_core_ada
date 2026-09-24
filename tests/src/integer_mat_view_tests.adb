with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Int16_Buffer_Access;
with OpenCV.Core.Int16_Mat_View;
with OpenCV.Core.Int16_Row_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Int32_Buffer_Access;
with OpenCV.Core.Int32_Mat_View;
with OpenCV.Core.Int32_Row_Access;
with OpenCV.Core.UInt16_Access;
with OpenCV.Core.UInt16_Buffer_Access;
with OpenCV.Core.UInt16_Mat_View;
with OpenCV.Core.UInt16_Row_Access;

package body Integer_Mat_View_Tests is

   use type OpenCV.Int16_Value;
   use type OpenCV.Int32_Value;
   use type OpenCV.UInt16_Value;
   use Mat_Test_Support;

   Callback_Error : exception;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result         : aliased AUnit.Test_Suites.Test_Suite;

   procedure Packed_Views_Are_Zero_Copy_And_Preserve_Exact_Values
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U : aliased OpenCV.Core.UInt16_Mat_View.Buffer_Array :=
        (11 => 0,
         12 => 32_767,
         13 => 32_768,
         14 => 65_534,
         15 => 65_535,
         16 => 1);
      I : aliased OpenCV.Core.Int16_Mat_View.Buffer_Array :=
        (21 => OpenCV.Int16_Value'First,
         22 => -1,
         23 => 0,
         24 => 1,
         25 => OpenCV.Int16_Value'Last,
         26 => -7);
      L : aliased OpenCV.Core.Int32_Mat_View.Buffer_Array :=
        (31 => OpenCV.Int32_Value'First,
         32 => -1,
         33 => 0,
         34 => 16_777_217,
         35 => OpenCV.Int32_Value'Last,
         36 => 9);

      procedure Process_U (Image : in out OpenCV.Core.Mat) is
         Row : OpenCV.Core.UInt16_Row_Access.Row_Array (4 .. 6);
         procedure Mutate
           (Data :
              aliased in out OpenCV.Core.UInt16_Buffer_Access.Buffer_Array) is
         begin
            Data (5) := 65_533;
         end Mutate;
      begin
         U (13) := 40_000;
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt16_Access.Get (Image, 0, 2) = 40_000,
            "UInt16 caller writes must be immediately visible");
         OpenCV.Core.UInt16_Access.Set (Image, 1, 0, 60_000);
         OpenCV.Core.UInt16_Row_Access.Read_Row (Image, 1, Row);
         AUnit.Assertions.Assert
           (U (14) = 60_000 and then Row (4) = 60_000,
            "UInt16 scalar and row access must alias caller storage");
         OpenCV.Core.UInt16_Buffer_Access.With_Writable_Buffer
           (Image, Mutate'Access);
      end Process_U;
      procedure Process_I (Image : in out OpenCV.Core.Mat) is
         Row : OpenCV.Core.Int16_Row_Access.Row_Array (7 .. 9);
         procedure Inspect
           (Data : aliased OpenCV.Core.Int16_Buffer_Access.Buffer_Array) is
         begin
            AUnit.Assertions.Assert
              (Data (0) = OpenCV.Int16_Value'First and then Data (5) = -7,
               "Int16 whole-buffer access must alias the packed view");
         end Inspect;
      begin
         I (22) := -30_000;
         AUnit.Assertions.Assert
           (OpenCV.Core.Int16_Access.Get (Image, 0, 1) = -30_000,
            "Int16 caller writes must be immediately visible");
         OpenCV.Core.Int16_Access.Set (Image, 1, 1, 30_000);
         OpenCV.Core.Int16_Row_Access.Read_Row (Image, 1, Row);
         AUnit.Assertions.Assert
           (I (25) = 30_000 and then Row (8) = 30_000,
            "Int16 scalar and row access must alias caller storage");
         OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect'Access);
      end Process_I;
      procedure Process_L (Image : in out OpenCV.Core.Mat) is
         Row : OpenCV.Core.Int32_Row_Access.Row_Array (2 .. 4);
         procedure Inspect
           (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
         begin
            AUnit.Assertions.Assert
              (Data (3) = 16_777_217,
               "Int32 buffer access must preserve non-Float32 integer");
         end Inspect;
      begin
         L (34) := 16_777_217;
         AUnit.Assertions.Assert
           (OpenCV.Core.Int32_Access.Get (Image, 1, 0) = 16_777_217,
            "Int32 packed view must preserve exact integer storage");
         OpenCV.Core.Int32_Access.Set (Image, 1, 2, -99);
         AUnit.Assertions.Assert
           (L (36) = -99,
            "Int32 Mat writes must immediately update caller data");
         OpenCV.Core.Int32_Row_Access.Read_Row (Image, 1, Row);
         AUnit.Assertions.Assert
           (Row (2) = 16_777_217 and then Row (4) = -99,
            "Int32 row access must alias the packed view");
         OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect'Access);
      end Process_L;
   begin
      OpenCV.Core.UInt16_Mat_View.With_Writable_Mat_View
        (U, 2, 3, Process_U'Access);
      OpenCV.Core.Int16_Mat_View.With_Writable_Mat_View
        (I, 2, 3, Process_I'Access);
      OpenCV.Core.Int32_Mat_View.With_Writable_Mat_View
        (L, 2, 3, Process_L'Access);
      AUnit.Assertions.Assert
        (U (16) = 65_533 and then I (25) = 30_000 and then L (36) = -99,
         "Packed integer views must have no deferred copy-back phase");
   end Packed_Views_Are_Zero_Copy_And_Preserve_Exact_Values;

   procedure Strided_Views_Preserve_Padding_Continuity_And_Clone
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U                         :
        aliased OpenCV.Core.UInt16_Mat_View.Buffer_Array :=
          (10 .. 28 => 61_000);
      I                         :
        aliased OpenCV.Core.Int16_Mat_View.Buffer_Array :=
          (20 .. 37 => -30_000);
      L                         :
        aliased OpenCV.Core.Int32_Mat_View.Buffer_Array := (30 .. 47 => -777);
      U_Clone, I_Clone, L_Clone : OpenCV.Core.Mat;
      U_Buffer_Invoked          : Boolean := False;
      I_Buffer_Invoked          : Boolean := False;
      L_Buffer_Invoked          : Boolean := False;

      procedure Process_U (Image : in out OpenCV.Core.Mat) is
         procedure Mark
           (Data : aliased OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
         is
            pragma Unreferenced (Data);
         begin
            U_Buffer_Invoked := True;
         end Mark;
         procedure Borrow is
         begin
            OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
              (Image, Mark'Access);
         end Borrow;
      begin
         AUnit.Assertions.Assert
           (not Image.Is_Continuous, "Padded UInt16 view must be strided");
         OpenCV.Core.UInt16_Access.Set (Image, 2, 3, 65_535);
         Assert_Raises_OpenCV_Error (Borrow'Access, "UInt16 strided buffer");
         U_Clone := Image.Clone;
      end Process_U;
      procedure Process_I (Image : in out OpenCV.Core.Mat) is
         Row : OpenCV.Core.Int16_Row_Access.Row_Array (2 .. 5);
         procedure Mark
           (Data : aliased OpenCV.Core.Int16_Buffer_Access.Buffer_Array)
         is
            pragma Unreferenced (Data);
         begin
            I_Buffer_Invoked := True;
         end Mark;
         procedure Borrow is
         begin
            OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
              (Image, Mark'Access);
         end Borrow;
      begin
         OpenCV.Core.Int16_Row_Access.Write_Row
           (Image,
            1,
            (OpenCV.Int16_Value'First, -1, 0, OpenCV.Int16_Value'Last));
         OpenCV.Core.Int16_Row_Access.Read_Row (Image, 1, Row);
         AUnit.Assertions.Assert
           (Row (2) = OpenCV.Int16_Value'First
            and then Row (5) = OpenCV.Int16_Value'Last,
            "Int16 row access must respect external stride");
         Assert_Raises_OpenCV_Error (Borrow'Access, "Int16 strided buffer");
         I_Clone := Image.Clone;
      end Process_I;
      procedure Process_L (Image : in out OpenCV.Core.Mat) is
         procedure Mark
           (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array)
         is
            pragma Unreferenced (Data);
         begin
            L_Buffer_Invoked := True;
         end Mark;
         procedure Borrow is
         begin
            OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
              (Image, Mark'Access);
         end Borrow;
      begin
         OpenCV.Core.Int32_Access.Set (Image, 0, 0, 16_777_217);
         OpenCV.Core.Int32_Access.Set (Image, 2, 3, OpenCV.Int32_Value'Last);
         Assert_Raises_OpenCV_Error (Borrow'Access, "Int32 strided buffer");
         L_Clone := Image.Clone;
      end Process_L;
   begin
      U (10) := 0;
      U (16) := 32_768;
      U (22) := 65_534;
      I (20) := -1;
      I (26) := 0;
      I (32) := 1;
      L (30) := -1;
      L (36) := 0;
      L (42) := 1;
      OpenCV.Core.UInt16_Mat_View.With_Writable_Strided_Mat_View
        (U, 3, 4, 6, Process_U'Access);
      OpenCV.Core.Int16_Mat_View.With_Writable_Strided_Mat_View
        (I, 3, 4, 6, Process_I'Access);
      OpenCV.Core.Int32_Mat_View.With_Writable_Strided_Mat_View
        (L, 3, 4, 6, Process_L'Access);

      AUnit.Assertions.Assert
        (not U_Buffer_Invoked
         and then not I_Buffer_Invoked
         and then not L_Buffer_Invoked
         and then U (26) = 61_000
         and then U (27) = 61_000
         and then U (28) = 61_000
         and then I (24) = -30_000
         and then I (25) = -30_000
         and then L (34) = -777
         and then L (35) = -777,
         "Logical operations must leave padding and trailing storage"
         & " untouched");
      U (25) := 7;
      I (20) := 7;
      L (30) := 7;
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Access.Get (U_Clone, 2, 3) = 65_535
         and then OpenCV.Core.Int16_Access.Get (I_Clone, 1, 0)
                  = OpenCV.Int16_Value'First
         and then OpenCV.Core.Int32_Access.Get (L_Clone, 0, 0) = 16_777_217,
         "Integer strided-view clones must own independent logical"
         & " contents");
   end Strided_Views_Preserve_Padding_Continuity_And_Clone;

   procedure Tight_One_Row_And_One_Column_Strides_Work (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U : aliased OpenCV.Core.UInt16_Mat_View.Buffer_Array :=
        (1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 99, 6 => 99);
      I : aliased OpenCV.Core.Int16_Mat_View.Buffer_Array :=
        (1 => 1,
         2 => 99,
         3 => 99,
         4 => 2,
         5 => 99,
         6 => 99,
         7 => 3,
         8 => 99,
         9 => 99);
      L : aliased OpenCV.Core.Int32_Mat_View.Buffer_Array :=
        (1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6);
      procedure U_Row (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Is_Continuous, "one row is continuous");
         OpenCV.Core.UInt16_Access.Set (Image, 0, 3, 65_535);
      end U_Row;
      procedure I_Column (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (not Image.Is_Continuous, "padded one-column view is strided");
         OpenCV.Core.Int16_Access.Set (Image, 1, 0, -32_000);
      end I_Column;
      procedure L_Tight (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Is_Continuous, "tight stride is packed");
         OpenCV.Core.Int32_Access.Set (Image, 1, 2, 16_777_217);
      end L_Tight;
   begin
      OpenCV.Core.UInt16_Mat_View.With_Writable_Strided_Mat_View
        (U, 1, 4, 6, U_Row'Access);
      OpenCV.Core.Int16_Mat_View.With_Writable_Strided_Mat_View
        (I, 3, 1, 3, I_Column'Access);
      OpenCV.Core.Int32_Mat_View.With_Writable_Strided_Mat_View
        (L, 2, 3, 3, L_Tight'Access);
      AUnit.Assertions.Assert
        (U (4) = 65_535
         and then U (5) = 99
         and then I (4) = -32_000
         and then I (5) = 99
         and then L (6) = 16_777_217,
         "Special stride shapes must map only logical elements");
   end Tight_One_Row_And_One_Column_Strides_Work;

   procedure Invalid_Layouts_And_Callback_Failure_Preserve_Storage
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U       : aliased OpenCV.Core.UInt16_Mat_View.Buffer_Array :=
        (1 .. 16 => 123);
      I       : aliased OpenCV.Core.Int16_Mat_View.Buffer_Array :=
        (1 .. 17 => -123);
      L       : aliased OpenCV.Core.Int32_Mat_View.Buffer_Array :=
        (1 .. 18 => 321);
      Packed  : aliased OpenCV.Core.UInt16_Mat_View.Buffer_Array :=
        (1 .. 12 => 123);
      Invoked : Boolean := False;
      Raised  : Boolean := False;

      procedure Mark (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Mark;
      procedure Short_Stride is
      begin
         OpenCV.Core.UInt16_Mat_View.With_Writable_Strided_Mat_View
           (U, 3, 4, 3, Mark'Access);
      end Short_Stride;
      procedure Logical_End_U is
      begin
         OpenCV.Core.UInt16_Mat_View.With_Writable_Strided_Mat_View
           (U, 3, 4, 6, Mark'Access);
      end Logical_End_U;
      procedure Insufficient_I is
      begin
         OpenCV.Core.Int16_Mat_View.With_Writable_Strided_Mat_View
           (I, 3, 4, 6, Mark'Access);
      end Insufficient_I;
      procedure Wrong_Packed_L is
      begin
         OpenCV.Core.Int32_Mat_View.With_Writable_Mat_View
           (L, 2, 4, Mark'Access);
      end Wrong_Packed_L;
      procedure Raise_L (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Int32_Access.Set (Image, 1, 1, 16_777_217);
         raise Callback_Error;
      end Raise_L;
      procedure Shallow_Escape (Image : in out OpenCV.Core.Mat) is
         procedure Copy is
            Alias : OpenCV.Core.Mat;
            pragma Unreferenced (Alias);
         begin
            begin
               Alias := Image;
            exception
               when Program_Error =>
                  raise OpenCV.OpenCV_Error;
            end;
         end Copy;
      begin
         Assert_Raises_OpenCV_Error (Copy'Access, "shallow external escape");
      end Shallow_Escape;
   begin
      Assert_Raises_OpenCV_Error (Short_Stride'Access, "short UInt16 stride");
      Assert_Raises_OpenCV_Error
        (Logical_End_U'Access, "UInt16 omitted final padding");
      Assert_Raises_OpenCV_Error
        (Insufficient_I'Access, "Int16 insufficient full capacity");
      Assert_Raises_OpenCV_Error
        (Wrong_Packed_L'Access, "Int32 packed length");
      AUnit.Assertions.Assert
        (not Invoked and then U (1) = 123 and then I (1) = -123,
         "Rejected integer views must not invoke callback or mutate storage");

      OpenCV.Core.UInt16_Mat_View.With_Writable_Mat_View
        (Packed, 3, 4, Shallow_Escape'Access);
      begin
         OpenCV.Core.Int32_Mat_View.With_Writable_Strided_Mat_View
           (L, 3, 4, 6, Raise_L'Access);
      exception
         when Callback_Error =>
            Raised := True;
      end;
      AUnit.Assertions.Assert
        (Raised and then L (8) = 16_777_217,
         "Callback exception must propagate without rolling back writes");
      L (1) := -1;
      AUnit.Assertions.Assert
        (L (1) = -1,
         "Caller storage must remain usable after callback failure");
   end Invalid_Layouts_And_Callback_Failure_Preserve_Storage;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Integer packed views are exact bidirectional zero-copy",
            Packed_Views_Are_Zero_Copy_And_Preserve_Exact_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer strided views preserve padding continuity and clones",
            Strided_Views_Preserve_Padding_Continuity_And_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer strided views handle tight and special layouts",
            Tight_One_Row_And_One_Column_Strides_Work'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer views reject layouts and preserve callback writes",
            Invalid_Layouts_And_Callback_Failure_Preserve_Storage'Access));
      return Result'Access;
   end Suite;

end Integer_Mat_View_Tests;
