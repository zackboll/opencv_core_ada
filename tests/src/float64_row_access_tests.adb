with AUnit.Assertions;
with AUnit.Test_Caller;
with OpenCV.Core;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float64_Row_Access;
with Mat_Test_Support;

package body Float64_Row_Access_Tests is

   use type OpenCV.Core.Float64_Value;
   use type OpenCV.Core.Float32_Value;
   use type OpenCV.Core.Float64_Access.Float64_Classification;
   use type OpenCV.Core.Float64_Row_Access.Row_Array;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Float64_Image
     (Rows, Columns : Natural; Channels : OpenCV.Core.Channel_Count := 1)
      return OpenCV.Core.Mat
   is (OpenCV.Core.Create
         (Rows,
          Columns,
          (Depth => OpenCV.Core.Float64, Channels => Channels)));

   procedure Copied_Rows_Preserve_Binary64_Values_And_Boundaries
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      First       : constant OpenCV.Core.Float64_Value := 1.0;
      Distinct    : OpenCV.Core.Float64_Value;
      First_32    : OpenCV.Core.Float32_Value;
      Distinct_32 : OpenCV.Core.Float32_Value;
      Image       : OpenCV.Core.Mat := Float64_Image (3, 4);
      Written     : OpenCV.Core.Float64_Row_Access.Row_Array (5 .. 8);
      Readback    : OpenCV.Core.Float64_Row_Access.Row_Array (10 .. 13);
      Last_Row    :
        constant OpenCV.Core.Float64_Row_Access.Row_Array (0 .. 3) :=
          (9.0, 8.0, 7.0, 6.0);
      Single_Row  : OpenCV.Core.Mat := Float64_Image (1, 3);
      Single_Col  : OpenCV.Core.Mat := Float64_Image (2, 1);
      Three       :
        constant OpenCV.Core.Float64_Row_Access.Row_Array (0 .. 2) :=
          (1.0, 2.0, 3.0);
      One         : OpenCV.Core.Float64_Row_Access.Row_Array (0 .. 0);
      One_Result  : OpenCV.Core.Float64_Row_Access.Row_Array (0 .. 0);
   begin
      Distinct := First + 2.0**(-40);
      First_32 := OpenCV.Core.Float32_Value (First);
      Distinct_32 := OpenCV.Core.Float32_Value (Distinct);
      Written := (First, Distinct, -1.0E-200, 3.141592653589793);
      One := (0 => Distinct);
      AUnit.Assertions.Assert
        (First /= Distinct and then First_32 = Distinct_32,
         "The precision regression values must collapse as Float32");

      Image.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float64_Row_Access.Write_Row (Image, 0, Written);
      OpenCV.Core.Float64_Row_Access.Write_Row (Image, 2, Last_Row);
      OpenCV.Core.Float64_Row_Access.Read_Row (Image, 0, Readback);
      AUnit.Assertions.Assert
        (Readback = Written,
         "Copied Float64 rows must preserve exact values and arbitrary"
         & " bounds");
      OpenCV.Core.Float64_Access.Set (Image, 0, 0, 99.0);
      AUnit.Assertions.Assert
        (Readback (10) = First,
         "A copied row result must not alias Mat storage");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Get (Image, 2, 0) = 9.0
         and then OpenCV.Core.Float64_Access.Get (Image, 2, 3) = 6.0,
         "Copied writes must support the last row and all columns");

      OpenCV.Core.Float64_Row_Access.Write_Row (Single_Row, 0, Three);
      OpenCV.Core.Float64_Row_Access.Write_Row (Single_Col, 1, One);
      OpenCV.Core.Float64_Row_Access.Read_Row (Single_Col, 1, One_Result);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Get (Single_Row, 0, 2) = 3.0
         and then One_Result = One,
         "Copied rows must support single-row and single-column Mats");
   end Copied_Rows_Preserve_Binary64_Values_And_Boundaries;

   procedure Copied_Region_Writes_Respect_Stride_Aliases_And_Clone
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Parent   : OpenCV.Core.Mat := Float64_Image (4, 6);
      Region   : OpenCV.Core.Mat :=
        Parent.Region ((X => 2, Y => 1, Width => 3, Height => 2));
      Alias    : OpenCV.Core.Mat;
      Copy     : OpenCV.Core.Mat;
      Values   : constant OpenCV.Core.Float64_Row_Access.Row_Array (0 .. 2) :=
        (11.25, 12.5, 13.75);
      Readback : OpenCV.Core.Float64_Row_Access.Row_Array (0 .. 2);
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Alias := Parent;
      Copy := Parent.Clone;
      AUnit.Assertions.Assert
        (not Region.Is_Continuous,
         "The copied-row Region test must exercise a row-strided Mat");
      OpenCV.Core.Float64_Row_Access.Write_Row (Region, 1, Values);
      OpenCV.Core.Float64_Row_Access.Read_Row (Region, 1, Readback);
      AUnit.Assertions.Assert
        (Readback = Values,
         "Copied Region row access must transfer exactly the Region columns");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Get (Parent, 2, 2) = 11.25
         and then OpenCV.Core.Float64_Access.Get (Alias, 2, 4) = 13.75
         and then OpenCV.Core.Float64_Access.Get (Parent, 2, 1) = 1.0
         and then OpenCV.Core.Float64_Access.Get (Parent, 2, 5) = 1.0,
         "Region writes must follow row step without touching parent padding");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Get (Copy, 2, 2) = 1.0,
         "A Clone must remain independent of copied row mutations");
   end Copied_Region_Writes_Respect_Stride_Aliases_And_Clone;

   procedure Copied_Row_Validation_Rejects_Invalid_Input
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Valid : OpenCV.Core.Mat := Float64_Image (1, 2);
      Wrong : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Multi : constant OpenCV.Core.Mat := Float64_Image (1, 2, 2);
      Empty : OpenCV.Core.Mat;
      N_D   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 2, 2), Element_Type => (OpenCV.Core.Float64, 1));
      Data  : OpenCV.Core.Float64_Row_Access.Row_Array (0 .. 1);
      Short : constant OpenCV.Core.Float64_Row_Access.Row_Array (0 .. 0) :=
        (0 => 0.0);

      procedure Read_Wrong is
      begin
         OpenCV.Core.Float64_Row_Access.Read_Row (Wrong, 0, Data);
      end Read_Wrong;
      procedure Read_Multi is
      begin
         OpenCV.Core.Float64_Row_Access.Read_Row (Multi, 0, Data);
      end Read_Multi;
      procedure Read_Past is
      begin
         OpenCV.Core.Float64_Row_Access.Read_Row (Valid, 1, Data);
      end Read_Past;
      procedure Read_Empty is
      begin
         OpenCV.Core.Float64_Row_Access.Read_Row (Empty, 0, Data);
      end Read_Empty;
      procedure Read_N_D is
      begin
         OpenCV.Core.Float64_Row_Access.Read_Row (N_D, 0, Data);
      end Read_N_D;
      procedure Write_Short is
      begin
         OpenCV.Core.Float64_Row_Access.Write_Row (Valid, 0, Short);
      end Write_Short;
   begin
      Assert_Raises_OpenCV_Error (Read_Wrong'Access, "wrong depth");
      Assert_Raises_OpenCV_Error (Read_Multi'Access, "multiple channels");
      Assert_Raises_OpenCV_Error (Read_Past'Access, "row past end");
      Assert_Raises_OpenCV_Error (Read_Empty'Access, "default empty Mat");
      Assert_Raises_OpenCV_Error (Read_N_D'Access, "N-D Mat");
      Assert_Raises_OpenCV_Error (Write_Short'Access, "row length mismatch");

      declare
         Negative : constant Integer := -1;
         Raised   : Boolean := False;
      begin
         begin
            declare
               Row : Natural;
            begin
               Row := Natural (Integer'Value (Integer'Image (Negative)));
               OpenCV.Core.Float64_Row_Access.Read_Row (Valid, Row, Data);
            end;
         exception
            when Constraint_Error =>
               Raised := True;
         end;
         AUnit.Assertions.Assert
           (Raised, "Natural row selection must reject a negative row");
      end;
   end Copied_Row_Validation_Rejects_Invalid_Input;

   procedure Borrowed_Row_Read_Preserves_Precision_And_Extent
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      First    : constant OpenCV.Core.Float64_Value := 1.0;
      Distinct : constant OpenCV.Core.Float64_Value := First + 2.0**(-40);
      Image    : OpenCV.Core.Mat := Float64_Image (2, 3);
      Values   : constant OpenCV.Core.Float64_Row_Access.Row_Array (0 .. 2) :=
        (First, Distinct, -8.125);
      procedure Inspect
        (Data : aliased OpenCV.Core.Float64_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A borrowed Float64 row must exactly span zero-based columns");
         AUnit.Assertions.Assert
           (Data = Values,
            "Borrowed Float64 reads must preserve binary64 precision");
      end Inspect;
   begin
      OpenCV.Core.Float64_Row_Access.Write_Row (Image, 1, Values);
      OpenCV.Core.Float64_Row_Access.With_Read_Only_Row
        (Image, 1, Inspect'Access);
   end Borrowed_Row_Read_Preserves_Precision_And_Extent;

   procedure Borrowed_Region_Mutation_Is_Zero_Copy_And_Shared
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Parent  : OpenCV.Core.Mat := Float64_Image (4, 6);
      Region  : OpenCV.Core.Mat :=
        Parent.Region ((X => 2, Y => 1, Width => 3, Height => 2));
      Alias   : OpenCV.Core.Mat;
      Copy    : OpenCV.Core.Mat;
      Precise : constant OpenCV.Core.Float64_Value := 1.0 + 2.0**(-40);
      procedure Mutate
        (Data : aliased in out OpenCV.Core.Float64_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 2 and then Data'Length = 3,
            "A borrowed Region row must expose only Region columns");
         Data (0) := Precise;
         Data (2) := 13.5;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Access.Get (Alias, 2, 2) = Precise,
            "Borrowed writes must be immediately visible through aliases");
      end Mutate;
   begin
      Parent.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Alias := Parent;
      Copy := Parent.Clone;
      OpenCV.Core.Float64_Row_Access.With_Writable_Row
        (Region, 1, Mutate'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Get (Parent, 2, 2) = Precise
         and then OpenCV.Core.Float64_Access.Get (Parent, 2, 4) = 13.5
         and then OpenCV.Core.Float64_Access.Get (Parent, 2, 1) = 1.0
         and then OpenCV.Core.Float64_Access.Get (Parent, 2, 5) = 1.0,
         "Borrowed Region mutation must respect native row stride");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Get (Copy, 2, 2) = 1.0,
         "A Clone must remain independent of borrowed row mutation");
   end Borrowed_Region_Mutation_Is_Zero_Copy_And_Shared;

   procedure Borrowed_Row_Validation_Does_Not_Invoke_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Wrong   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Multi   : constant OpenCV.Core.Mat := Float64_Image (1, 2, 2);
      Valid   : constant OpenCV.Core.Mat := Float64_Image (1, 2);
      Empty   : OpenCV.Core.Mat;
      N_D     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 2, 2), Element_Type => (OpenCV.Core.Float64, 1));
      Invoked : Boolean := False;
      procedure Inspect
        (Data : aliased OpenCV.Core.Float64_Row_Access.Row_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Inspect;
      procedure Bad_Wrong is
      begin
         OpenCV.Core.Float64_Row_Access.With_Read_Only_Row
           (Wrong, 0, Inspect'Access);
      end Bad_Wrong;
      procedure Bad_Multi is
      begin
         OpenCV.Core.Float64_Row_Access.With_Read_Only_Row
           (Multi, 0, Inspect'Access);
      end Bad_Multi;
      procedure Bad_Past is
      begin
         OpenCV.Core.Float64_Row_Access.With_Read_Only_Row
           (Valid, 1, Inspect'Access);
      end Bad_Past;
      procedure Bad_Empty is
      begin
         OpenCV.Core.Float64_Row_Access.With_Read_Only_Row
           (Empty, 0, Inspect'Access);
      end Bad_Empty;
      procedure Bad_N_D is
      begin
         OpenCV.Core.Float64_Row_Access.With_Read_Only_Row
           (N_D, 0, Inspect'Access);
      end Bad_N_D;
   begin
      Assert_Raises_OpenCV_Error (Bad_Wrong'Access, "wrong borrowed depth");
      Assert_Raises_OpenCV_Error (Bad_Multi'Access, "borrowed channels");
      Assert_Raises_OpenCV_Error (Bad_Past'Access, "borrowed row past end");
      Assert_Raises_OpenCV_Error (Bad_Empty'Access, "borrowed default Mat");
      Assert_Raises_OpenCV_Error (Bad_N_D'Access, "borrowed N-D Mat");
      AUnit.Assertions.Assert
        (not Invoked, "Invalid borrowed rows must not invoke the callback");
   end Borrowed_Row_Validation_Does_Not_Invoke_Callback;

   procedure Row_Transfer_Preserves_Nonfinite_Classification
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Numerator   : OpenCV.Core.Mat := Float64_Image (1, 3);
      Denominator : OpenCV.Core.Mat := Float64_Image (1, 3);
      Nonfinite   : OpenCV.Core.Mat;
      Destination : OpenCV.Core.Mat := Float64_Image (1, 3);
      procedure Inspect
        (Data : aliased OpenCV.Core.Float64_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 3,
            "A borrowed nonfinite row must preserve its extent");
      end Inspect;

      procedure Transfer
        (Data : aliased OpenCV.Core.Float64_Row_Access.Row_Array)
      is
         procedure Write
           (Output : aliased in out OpenCV.Core.Float64_Row_Access.Row_Array)
         is
         begin
            Output := Data;
         end Write;
      begin
         OpenCV.Core.Float64_Row_Access.With_Writable_Row
           (Destination, 0, Write'Access);
      end Transfer;
   begin
      OpenCV.Core.Float64_Access.Set (Numerator, 0, 0, 1.0);
      OpenCV.Core.Float64_Access.Set (Numerator, 0, 1, -1.0);
      OpenCV.Core.Float64_Access.Set (Numerator, 0, 2, 0.0);
      Denominator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Nonfinite := Numerator.Divide (Denominator);

      OpenCV.Core.Float64_Row_Access.With_Read_Only_Row
        (Nonfinite, 0, Transfer'Access);
      OpenCV.Core.Float64_Row_Access.With_Read_Only_Row
        (Destination, 0, Inspect'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Classify (Destination, 0, 0)
         = OpenCV.Core.Float64_Access.Positive_Infinity
         and then OpenCV.Core.Float64_Access.Classify (Destination, 0, 1)
                  = OpenCV.Core.Float64_Access.Negative_Infinity
         and then OpenCV.Core.Float64_Access.Classify (Destination, 0, 2)
                  = OpenCV.Core.Float64_Access.Not_A_Number,
         "Borrowed Float64 rows must preserve nonfinite values");
   end Row_Transfer_Preserves_Nonfinite_Classification;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float64 copied rows preserve binary64 values and boundaries",
            Copied_Rows_Preserve_Binary64_Values_And_Boundaries'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 copied Region rows respect stride aliases and Clone",
            Copied_Region_Writes_Respect_Stride_Aliases_And_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 copied row validation rejects invalid input",
            Copied_Row_Validation_Rejects_Invalid_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 borrowed row read preserves precision and extent",
            Borrowed_Row_Read_Preserves_Precision_And_Extent'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 borrowed Region mutation is zero-copy and shared",
            Borrowed_Region_Mutation_Is_Zero_Copy_And_Shared'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 borrowed row validation does not invoke callback",
            Borrowed_Row_Validation_Does_Not_Invoke_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 row transfer preserves nonfinite classification",
            Row_Transfer_Preserves_Nonfinite_Classification'Access));
      return Result'Access;
   end Suite;

end Float64_Row_Access_Tests;
