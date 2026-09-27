with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.UInt16_Access;
with OpenCV.Core.UInt16_Vec3;
with OpenCV.Core.UInt16_Vec3_Access;
with OpenCV.Core.UInt16_Vec3_Row_Access;
with OpenCV.Core.UInt16_Vec3_Buffer_Access;
with OpenCV.Core.UInt16_Vec3_Mat_View;
with OpenCV.Core.UInt16_Vec4;
with OpenCV.Core.UInt16_Vec4_Access;
with UInt16_Vec3_Tests.Raw_ABI;
with System;

package body UInt16_Vec3_Tests is
   use type OpenCV.Core.UInt16_Vec3_Row_Access.Row_Array;
   use type OpenCV.Core.UInt16_Vec4.Vector;
   use type OpenCV.UInt16_Value;
   use type System.Address;
   use type OpenCV.Core.UInt16_Vec3.Vector;
   use type OpenCV.Core.Depth_Type;
   use Mat_Test_Support;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   A      : constant OpenCV.Core.UInt16_Vec3.Vector := (0, 32768, 65535);
   B      : constant OpenCV.Core.UInt16_Vec3.Vector := (1, 65534, 32767);

   procedure Elements (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 3));
      Volume  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt16, 3));
      Shifted : constant OpenCV.Core.Index_Array (7 .. 9) := (1, 2, 3);
      Alias   : OpenCV.Core.Mat;
      Copy    : OpenCV.Core.Mat;
      procedure Wrong_Depth is
         Wrong : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 3));
         V     : constant OpenCV.Core.UInt16_Vec3.Vector :=
           OpenCV.Core.UInt16_Vec3_Access.Get (Wrong, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Wrong_Depth;
      procedure Wrong_Channels is
         Wrong : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 4));
      begin
         OpenCV.Core.UInt16_Vec3_Access.Set (Wrong, 0, 0, A);
      end Wrong_Channels;
      procedure Bad_Indices is
         V : constant OpenCV.Core.UInt16_Vec3.Vector :=
           OpenCV.Core.UInt16_Vec3_Access.Get (Volume, (1, 2));
         pragma Unreferenced (V);
      begin
         null;
      end Bad_Indices;
      procedure Too_Many is
      begin
         OpenCV.Core.UInt16_Vec3_Access.Set (Volume, (1, 2, 3, 0), A);
      end Too_Many;
      procedure Past_Extent is
      begin
         OpenCV.Core.UInt16_Vec3_Access.Set (Volume, (1, 3, 0), A);
      end Past_Extent;
   begin
      Image.Set_To (OpenCV.Make_Scalar (4.0, 5.0, 6.0));
      OpenCV.Core.UInt16_Vec3_Access.Set (Image, 1, 2, A);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec3_Access.Get (Image, 1, 2) = A
         and then OpenCV.Core.UInt16_Vec3_Access.Get (Image, 1, 1) = (4, 5, 6),
         "2-D components and neighbor isolation");
      Alias := Image;
      Copy := Image.Clone;
      OpenCV.Core.UInt16_Vec3_Access.Set (Alias, 1, 2, B);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec3_Access.Get (Image, 1, 2) = B
         and then OpenCV.Core.UInt16_Vec3_Access.Get (Copy, 1, 2) = A,
         "2-D assignment shares pixels but Clone does not");
      Volume.Set_To (OpenCV.Make_Scalar (4.0, 5.0, 6.0));
      OpenCV.Core.UInt16_Vec3_Access.Set (Volume, Shifted, A);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec3_Access.Get (Volume, (1, 2, 3)) = A
         and then OpenCV.Core.UInt16_Vec3_Access.Get (Volume, (1, 2, 2))
                  = (4, 5, 6),
         "shifted N-D indices map one complete pixel");
      Alias := Volume;
      Copy := Volume.Clone;
      OpenCV.Core.UInt16_Vec3_Access.Set (Alias, Shifted, B);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec3_Access.Get (Volume, Shifted) = B
         and then OpenCV.Core.UInt16_Vec3_Access.Get (Copy, Shifted) = A,
         "N-D shallow alias and deep Clone");
      Assert_Raises_OpenCV_Error (Wrong_Depth'Access, "wrong depth");
      Assert_Raises_OpenCV_Error (Wrong_Channels'Access, "wrong channels");
      Assert_Raises_OpenCV_Error (Bad_Indices'Access, "too few indices");
      Assert_Raises_OpenCV_Error (Too_Many'Access, "too many indices");
      Assert_Raises_OpenCV_Error (Past_Extent'Access, "index past extent");
   end Elements;

   procedure Rows_And_Buffer (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 3));
      Data      :
        constant OpenCV.Core.UInt16_Vec3_Row_Access.Row_Array (7 .. 9) :=
          (A, B, A);
      Read_Back : OpenCV.Core.UInt16_Vec3_Row_Access.Row_Array (11 .. 13);
      procedure Edit_Row
        (Row : aliased in out OpenCV.Core.UInt16_Vec3_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Row'Length = 3 and then Row (0) = A, "row overlay");
         Row (0) := B;
      end Edit_Row;
   begin
      OpenCV.Core.UInt16_Vec3_Row_Access.Write_Row (Image, 1, Data);
      OpenCV.Core.UInt16_Vec3_Row_Access.Read_Row (Image, 1, Read_Back);
      AUnit.Assertions.Assert (Read_Back = Data, "copied row shifted bounds");
      OpenCV.Core.UInt16_Vec3_Row_Access.With_Writable_Row
        (Image, 1, Edit_Row'Access);
      --  The copied row is independent; inspect the borrowed buffer by value.
      declare
         procedure Inspect
           (Pixels :
              aliased OpenCV.Core.UInt16_Vec3_Buffer_Access.Buffer_Array) is
         begin
            AUnit.Assertions.Assert
              (Pixels'Length = 6 and then Pixels (3) = B,
               "complete Vec3 per buffer entry");
         end Inspect;
      begin
         OpenCV.Core.UInt16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect'Access);
      end;
   end Rows_And_Buffer;

   procedure Regions_And_Views (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Parent         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 5, (OpenCV.Core.UInt16, 3));
      Region         : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 0, Width => 3, Height => 2));
      Packed         : aliased OpenCV.Core.UInt16_Vec3_Mat_View.Buffer_Array :=
        (11 .. 16 => A);
      Strided        : aliased OpenCV.Core.UInt16_Vec3_Mat_View.Buffer_Array :=
        (0 .. 9 => B);
      Constant_Data  :
        aliased constant OpenCV.Core.UInt16_Vec3_Mat_View.Buffer_Array :=
          (11 .. 16 => A);
      Escaped        : OpenCV.Core.Mat;
      Callback_Error : exception;
      procedure Borrow_Row
        (Data : aliased in out OpenCV.Core.UInt16_Vec3_Row_Access.Row_Array) is
      begin
         Data (2) := B;
         Parent := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 3));
         Data (1) := A;
      end Borrow_Row;
      procedure Packed_View (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt16_Vec3_Access.Get (Image, 1, 2) = A,
            "packed shifted last pixel");
         OpenCV.Core.UInt16_Vec3_Access.Set (Image, 1, 2, B);
         Packed (11) := B;
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt16_Vec3_Access.Get (Image, 0, 0) = B,
            "packed caller writes alias view");
         Escaped := Image.Clone;
      end Packed_View;
      procedure Strided_View (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (not Image.Is_Continuous
            and then OpenCV.Core.UInt16_Vec3_Access.Get (Image, 1, 0)
                     = Strided (5),
            "row stride counts complete vectors");
         OpenCV.Core.UInt16_Vec3_Access.Set (Image, 1, 2, A);
      end Strided_View;
      procedure Constant_View (Image : OpenCV.Core.Mat) is
         procedure Inspect
           (Data : aliased OpenCV.Core.UInt16_Vec3_Buffer_Access.Buffer_Array)
         is
         begin
            AUnit.Assertions.Assert
              (Data (0)'Address = Constant_Data (11)'Address
               and then Data'Length = 6,
               "constant view borrows without copying");
         end Inspect;
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt16_Vec3_Access.Get (Image, 1, 2) = A,
            "constant view exact components");
         OpenCV.Core.UInt16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect'Access);
      end Constant_View;
      procedure Bad_Length is
         Wrong : OpenCV.Core.UInt16_Vec3_Row_Access.Row_Array (1 .. 2);
      begin
         OpenCV.Core.UInt16_Vec3_Row_Access.Read_Row (Region, 0, Wrong);
      end Bad_Length;
      procedure Bad_Buffer is
         procedure Inspect
           (Data : aliased OpenCV.Core.UInt16_Vec3_Buffer_Access.Buffer_Array)
         is
            pragma Unreferenced (Data);
         begin
            null;
         end Inspect;
      begin
         OpenCV.Core.UInt16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Region, Inspect'Access);
      end Bad_Buffer;
      procedure Bad_Row is
         V : OpenCV.Core.UInt16_Vec3_Row_Access.Row_Array (1 .. 3);
      begin
         OpenCV.Core.UInt16_Vec3_Row_Access.Read_Row (Region, 2, V);
      end Bad_Row;
      procedure Bad_Depth is
         Wrong : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 3, (OpenCV.Core.Float16, 3));
         V     : OpenCV.Core.UInt16_Vec3_Row_Access.Row_Array (1 .. 3);
      begin
         OpenCV.Core.UInt16_Vec3_Row_Access.Read_Row (Wrong, 0, V);
      end Bad_Depth;
      procedure Bad_Channels is
         Wrong : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 3, (OpenCV.Core.UInt16, 2));
         V     : OpenCV.Core.UInt16_Vec3_Row_Access.Row_Array (1 .. 3);
      begin
         OpenCV.Core.UInt16_Vec3_Row_Access.Read_Row (Wrong, 0, V);
      end Bad_Channels;
      procedure Throw_In_Row
        (Data : aliased in out OpenCV.Core.UInt16_Vec3_Row_Access.Row_Array) is
      begin
         Data (0) := B;
         raise Callback_Error;
      end Throw_In_Row;
   begin
      Region.Set_To (OpenCV.Make_Scalar (0.0, 32768.0, 65535.0));
      OpenCV.Core.UInt16_Vec3_Row_Access.With_Writable_Row
        (Region, 1, Borrow_Row'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec3_Access.Get (Region, 1, 2) = B,
         "region lease survives parent rebind");
      Assert_Raises_OpenCV_Error (Bad_Length'Access, "copied row length");
      Assert_Raises_OpenCV_Error (Bad_Row'Access, "row past extent");
      Assert_Raises_OpenCV_Error (Bad_Depth'Access, "row wrong depth");
      Assert_Raises_OpenCV_Error (Bad_Channels'Access, "row wrong channels");
      Assert_Raises_OpenCV_Error (Bad_Buffer'Access, "gapped buffer");
      begin
         OpenCV.Core.UInt16_Vec3_Row_Access.With_Writable_Row
           (Region, 0, Throw_In_Row'Access);
         AUnit.Assertions.Assert (False, "callback exception must propagate");
      exception
         when Callback_Error =>
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt16_Vec3_Access.Get (Region, 0, 0) = B,
               "write before callback exception remains visible");
      end;
      OpenCV.Core.UInt16_Vec3_Mat_View.With_Writable_Mat_View
        (Packed, 2, 3, Packed_View'Access);
      Packed (16) := A;
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec3_Access.Get (Escaped, 1, 2) = B,
         "Clone escapes packed view independently");
      OpenCV.Core.UInt16_Vec3_Mat_View.With_Writable_Strided_Mat_View
        (Strided, 2, 3, 5, Strided_View'Access);
      AUnit.Assertions.Assert
        (Strided (7) = A and then Strided (3) = B and then Strided (9) = B,
         "strided padding intact");
      OpenCV.Core.UInt16_Vec3_Mat_View.With_Read_Only_Mat_View
        (Constant_Data, 2, 3, Constant_View'Access);
   end Regions_And_Views;

   procedure Channels_And_Transform (Test : in out Fixture) is
      pragma Unreferenced (Test);
      One          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
      Two          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
      Three        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
      Scalar_Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 3));
      Coeff3       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Coeff4       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 4, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.UInt16_Access.Set (One, 0, 0, 0);
      OpenCV.Core.UInt16_Access.Set (Two, 0, 0, 32768);
      OpenCV.Core.UInt16_Access.Set (Three, 0, 0, 65535);
      declare
         Channels : constant OpenCV.Core.Mat_Array (7 .. 9) :=
           (One, Two, Three);
         Merged   : OpenCV.Core.Mat := OpenCV.Core.Merge (Channels);
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt16_Vec3_Access.Get (Merged, 0, 0) = A,
            "Merge component order");
         OpenCV.Core.UInt16_Vec3_Access.Set (Merged, 0, 0, B);
         declare
            Parts : constant OpenCV.Core.Mat_Array := Merged.Split;
         begin
            for I in 0 .. 2 loop
               AUnit.Assertions.Assert
                 (OpenCV.Core.UInt16_Access.Get (Parts (Parts'First + I), 0, 0)
                  = B (I),
                  "Split component order");
            end loop;
         end;
      end;
      Scalar_Image.Set_To (OpenCV.Make_Scalar (0.0, 32768.0, 65535.0));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec3_Access.Get (Scalar_Image, 0, 0) = A,
         "Scalar component order");
      Coeff3.Set_Identity;
      Coeff4.Set_To (OpenCV.Make_Scalar (0.0));
      for I in 0 .. 2 loop
         OpenCV.Core.Float32_Access.Set (Coeff4, I, I, 1.0);
      end loop;
      OpenCV.Core.Float32_Access.Set (Coeff4, 3, 3, 65535.0);
      OpenCV.Core.UInt16_Vec3_Access.Set (Scalar_Image, 0, 0, B);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec3_Access.Get
           (Scalar_Image.Transform (Coeff3), 0, 0)
         = B,
         "C3 identity Transform");
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec4_Access.Get
           (Scalar_Image.Transform (Coeff4), 0, 0)
         = (1, 65534, 32767, 65535),
         "C3 to C4 Transform");
   end Channels_And_Transform;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("UInt16 Vec3 2-D N-D ownership and validation", Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt16 Vec3 copied and borrowed rows and buffer",
            Rows_And_Buffer'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt16 Vec3 Region lease and packed strided constant views",
            Regions_And_Views'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt16 Vec3 Merge Split Scalar Transform",
            Channels_And_Transform'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt16 Vec3 raw ABI layout and safety", Raw_ABI.Check'Access));
      return Result'Access;
   end Suite;
end UInt16_Vec3_Tests;
