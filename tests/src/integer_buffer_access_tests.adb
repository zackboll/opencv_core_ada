with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Int16_Buffer_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Int32_Buffer_Access;
with OpenCV.Core.UInt16_Access;
with OpenCV.Core.UInt16_Buffer_Access;

package body Integer_Buffer_Access_Tests is

   use type OpenCV.Int16_Value;
   use type OpenCV.Int32_Value;
   use type OpenCV.UInt16_Value;
   use type OpenCV.Core.Depth_Type;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure Exact_Values_And_Zero_Based_Row_Major_Extents
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U16 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 1));
      I16 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int16, 1));
      I32 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Int32, 1));

      procedure Mutate_U16
        (Data : aliased in out OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5,
            "UInt16 borrowed buffer must be zero-based");
         Data := (0, 32_767, 32_768, 65_534, 65_535, 1);
      end Mutate_U16;
      procedure Mutate_I16
        (Data : aliased in out OpenCV.Core.Int16_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5,
            "Int16 borrowed buffer must be zero-based");
         Data :=
           (OpenCV.Int16_Value'First, -1, 0, 1, OpenCV.Int16_Value'Last, -7);
      end Mutate_I16;
      procedure Mutate_I32
        (Data : aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Last = 5,
            "Int32 borrowed buffer must be zero-based");
         Data :=
           (OpenCV.Int32_Value'First,
            -1,
            0,
            16_777_217,
            OpenCV.Int32_Value'Last,
            9);
      end Mutate_I32;
   begin
      OpenCV.Core.UInt16_Buffer_Access.With_Writable_Buffer
        (U16, Mutate_U16'Access);
      OpenCV.Core.Int16_Buffer_Access.With_Writable_Buffer
        (I16, Mutate_I16'Access);
      OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
        (I32, Mutate_I32'Access);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Access.Get (U16, 0, 2) = 32_768
         and then OpenCV.Core.UInt16_Access.Get (U16, 1, 1) = 65_535,
         "UInt16 buffer writes must preserve the signed boundary and"
         & " endpoint");
      AUnit.Assertions.Assert
        (OpenCV.Core.Int16_Access.Get (I16, 0, 0) = OpenCV.Int16_Value'First
         and then OpenCV.Core.Int16_Access.Get (I16, 1, 1)
                  = OpenCV.Int16_Value'Last,
         "Int16 buffer writes must preserve signed endpoints");
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (I32, 0, 0) = OpenCV.Int32_Value'First
         and then OpenCV.Core.Int32_Access.Get (I32, 1, 0) = 16_777_217
         and then OpenCV.Core.Int32_Access.Get (I32, 1, 1)
                  = OpenCV.Int32_Value'Last,
         "Int32 buffer writes must avoid floating-point intermediates");
   end Exact_Values_And_Zero_Based_Row_Major_Extents;

   procedure Continuous_Regions_Are_Accepted_And_Strided_Regions_Rejected
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U_Parent  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.UInt16, 1));
      I_Parent  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Int16, 1));
      L_Parent  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Int32, 1));
      U_Cont    : OpenCV.Core.Mat :=
        U_Parent.Region ((X => 0, Y => 1, Width => 5, Height => 2));
      I_Cont    : OpenCV.Core.Mat :=
        I_Parent.Region ((X => 0, Y => 1, Width => 5, Height => 2));
      L_Cont    : OpenCV.Core.Mat :=
        L_Parent.Region ((X => 0, Y => 1, Width => 5, Height => 2));
      U_Strided : constant OpenCV.Core.Mat :=
        U_Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      I_Strided : constant OpenCV.Core.Mat :=
        I_Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      L_Strided : constant OpenCV.Core.Mat :=
        L_Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Invoked   : Boolean := False;

      procedure Write_U
        (Data : aliased in out OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
      is
      begin
         Data (0) := 65_535;
         Data (9) := 32_768;
      end Write_U;
      procedure Write_I
        (Data : aliased in out OpenCV.Core.Int16_Buffer_Access.Buffer_Array) is
      begin
         Data (0) := OpenCV.Int16_Value'First;
         Data (9) := OpenCV.Int16_Value'Last;
      end Write_I;
      procedure Write_L
        (Data : aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         Data (0) := 16_777_217;
         Data (9) := OpenCV.Int32_Value'Last;
      end Write_L;
      procedure Mark_U
        (Data : aliased OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_U;
      procedure Mark_I
        (Data : aliased OpenCV.Core.Int16_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_I;
      procedure Mark_L
        (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mark_L;
      procedure Borrow_U is
      begin
         OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
           (U_Strided, Mark_U'Access);
      end Borrow_U;
      procedure Borrow_I is
      begin
         OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
           (I_Strided, Mark_I'Access);
      end Borrow_I;
      procedure Borrow_L is
      begin
         OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
           (L_Strided, Mark_L'Access);
      end Borrow_L;
   begin
      OpenCV.Core.UInt16_Buffer_Access.With_Writable_Buffer
        (U_Cont, Write_U'Access);
      OpenCV.Core.Int16_Buffer_Access.With_Writable_Buffer
        (I_Cont, Write_I'Access);
      OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
        (L_Cont, Write_L'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Access.Get (U_Parent, 1, 0) = 65_535
         and then OpenCV.Core.Int16_Access.Get (I_Parent, 2, 4)
                  = OpenCV.Int16_Value'Last
         and then OpenCV.Core.Int32_Access.Get (L_Parent, 1, 0) = 16_777_217,
         "Continuous Region buffers must share parent storage"
         & " immediately");
      Assert_Raises_OpenCV_Error (Borrow_U'Access, "UInt16 strided Region");
      Assert_Raises_OpenCV_Error (Borrow_I'Access, "Int16 strided Region");
      Assert_Raises_OpenCV_Error (Borrow_L'Access, "Int32 strided Region");
      AUnit.Assertions.Assert
        (not Invoked,
         "Non-contiguous buffer rejection must suppress callbacks");
   end Continuous_Regions_Are_Accepted_And_Strided_Regions_Rejected;

   procedure Empty_Type_And_Dimension_Validation_Covers_All_Families
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      U_Empty         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt16, 1));
      I_Empty         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Int16, 1));
      L_Empty         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.Int32, 1));
      Wrong           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      U_Multi         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt16, 2));
      I_Multi         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int16, 2));
      L_Multi         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 2));
      U_N_D           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 2, 2), Element_Type => (OpenCV.Core.UInt16, 1));
      I_N_D           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 2, 2), Element_Type => (OpenCV.Core.Int16, 1));
      L_N_D           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 2, 2), Element_Type => (OpenCV.Core.Int32, 1));
      Empty_Count     : Natural := 0;
      Invalid_Invoked : Boolean := False;

      procedure Empty_U
        (Data : aliased OpenCV.Core.UInt16_Buffer_Access.Buffer_Array) is
      begin
         if Data'Length = 0 then
            Empty_Count := Empty_Count + 1;
         end if;
      end Empty_U;
      procedure Empty_I
        (Data : aliased OpenCV.Core.Int16_Buffer_Access.Buffer_Array) is
      begin
         if Data'Length = 0 then
            Empty_Count := Empty_Count + 1;
         end if;
      end Empty_I;
      procedure Empty_L
        (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         if Data'Length = 0 then
            Empty_Count := Empty_Count + 1;
         end if;
      end Empty_L;
      procedure Mark_L
        (Data : aliased OpenCV.Core.Int32_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invalid_Invoked := True;
      end Mark_L;
      procedure Mark_U
        (Data : aliased OpenCV.Core.UInt16_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invalid_Invoked := True;
      end Mark_U;
      procedure Mark_I
        (Data : aliased OpenCV.Core.Int16_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Invalid_Invoked := True;
      end Mark_I;
      procedure U_Wrong_Depth is
      begin
         OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
           (Wrong, Mark_U'Access);
      end U_Wrong_Depth;
      procedure I_Wrong_Depth is
      begin
         OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
           (Wrong, Mark_I'Access);
      end I_Wrong_Depth;
      procedure L_Wrong_Depth is
      begin
         OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
           (Wrong, Mark_L'Access);
      end L_Wrong_Depth;
      procedure U_Wrong_Channels is
      begin
         OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
           (U_Multi, Mark_U'Access);
      end U_Wrong_Channels;
      procedure I_Wrong_Channels is
      begin
         OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
           (I_Multi, Mark_I'Access);
      end I_Wrong_Channels;
      procedure L_Wrong_Channels is
      begin
         OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
           (L_Multi, Mark_L'Access);
      end L_Wrong_Channels;
      procedure U_Wrong_Dimensions is
      begin
         OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
           (U_N_D, Mark_U'Access);
      end U_Wrong_Dimensions;
      procedure I_Wrong_Dimensions is
      begin
         OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
           (I_N_D, Mark_I'Access);
      end I_Wrong_Dimensions;
      procedure L_Wrong_Dimensions is
      begin
         OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
           (L_N_D, Mark_L'Access);
      end L_Wrong_Dimensions;
   begin
      OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer
        (U_Empty, Empty_U'Access);
      OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer
        (I_Empty, Empty_I'Access);
      OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer
        (L_Empty, Empty_L'Access);
      AUnit.Assertions.Assert
        (Empty_Count = 3,
         "Each typed empty integer buffer must invoke callback");
      Assert_Raises_OpenCV_Error (U_Wrong_Depth'Access, "wrong UInt16 depth");
      Assert_Raises_OpenCV_Error (I_Wrong_Depth'Access, "wrong Int16 depth");
      Assert_Raises_OpenCV_Error (L_Wrong_Depth'Access, "wrong Int32 depth");
      Assert_Raises_OpenCV_Error (U_Wrong_Channels'Access, "UInt16 C2 buffer");
      Assert_Raises_OpenCV_Error (I_Wrong_Channels'Access, "Int16 C2 buffer");
      Assert_Raises_OpenCV_Error (L_Wrong_Channels'Access, "Int32 C2 buffer");
      Assert_Raises_OpenCV_Error (U_Wrong_Dimensions'Access, "UInt16 N-D");
      Assert_Raises_OpenCV_Error (I_Wrong_Dimensions'Access, "Int16 N-D");
      Assert_Raises_OpenCV_Error (L_Wrong_Dimensions'Access, "Int32 N-D");
      AUnit.Assertions.Assert
        (not Invalid_Invoked,
         "Invalid integer buffers must suppress callback");
   end Empty_Type_And_Dimension_Validation_Covers_All_Families;

   procedure Borrow_Lease_Retains_Storage_When_Another_Header_Is_Rebound
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Int32, 1));
      Alias : OpenCV.Core.Mat := Image;

      procedure Mutate
        (Data : aliased in out OpenCV.Core.Int32_Buffer_Access.Buffer_Array) is
      begin
         Alias := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
         Data (0) := 16_777_217;
         Data (1) := OpenCV.Int32_Value'Last;
      end Mutate;
   begin
      OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer
        (Image, Mutate'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.Int32_Access.Get (Image, 0, 0) = 16_777_217
         and then OpenCV.Core.Int32_Access.Get (Image, 0, 1)
                  = OpenCV.Int32_Value'Last
         and then Alias.Depth = OpenCV.Core.UInt16,
         "Borrow lease must retain ordinary OpenCV-owned storage");
   end Borrow_Lease_Retains_Storage_When_Another_Header_Is_Rebound;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Integer buffers preserve exact values and row-major extents",
            Exact_Values_And_Zero_Based_Row_Major_Extents'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer buffers accept continuous and reject strided Regions",
            Continuous_Regions_Are_Accepted_And_Strided_Regions_Rejected
              'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer buffers validate empty type channels and dimensions",
            Empty_Type_And_Dimension_Validation_Covers_All_Families'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer buffer borrow lease retains storage across rebind",
            Borrow_Lease_Retains_Storage_When_Another_Header_Is_Rebound
              'Access));
      return Result'Access;
   end Suite;

end Integer_Buffer_Access_Tests;
