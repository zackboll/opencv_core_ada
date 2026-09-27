with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt16_Access;
with OpenCV.Core.UInt8_Vec3_Access;
with OpenCV.Core.UInt16_Vec3_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt16_Vec3;
with OpenCV.Core.UInt8_Vec2;
with OpenCV.Core.UInt8_Vec2_Access;
with OpenCV.Core.UInt8_Vec2_Row_Access;
with OpenCV.Core.UInt8_Vec2_Buffer_Access;
with OpenCV.Core.UInt8_Vec2_Mat_View;
with OpenCV.Core.UInt16_Vec2;
with OpenCV.Core.UInt16_Vec2_Access;
with OpenCV.Core.UInt16_Vec2_Row_Access;
with OpenCV.Core.UInt16_Vec2_Buffer_Access;
with OpenCV.Core.UInt16_Vec2_Mat_View;
with Unsigned_Vec2_Tests.Raw_ABI;

package body Unsigned_Vec2_Tests is
   use Mat_Test_Support;
   use type OpenCV.Core.UInt8_Vec2.Vector;
   use type OpenCV.Core.UInt16_Vec2.Vector;
   use type OpenCV.Core.UInt8_Vec3.Vector;
   use type OpenCV.Core.UInt16_Vec3.Vector;
   use type OpenCV.UInt8_Value;
   use type OpenCV.UInt16_Value;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   procedure UInt8_Elements (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 2));
      Volume  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt8, 2));
      Shifted : constant OpenCV.Core.Index_Array (7 .. 9) := (1, 2, 3);
      Alias   : OpenCV.Core.Mat;
      Deep    : OpenCV.Core.Mat;
      procedure Wrong_Depth is
         Wrong : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
         V     : constant OpenCV.Core.UInt8_Vec2.Vector :=
           OpenCV.Core.UInt8_Vec2_Access.Get (Wrong, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Wrong_Depth;
      procedure Wrong_Channels is
         Wrong : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      begin
         OpenCV.Core.UInt8_Vec2_Access.Set (Wrong, 0, 0, (0, 255));
      end Wrong_Channels;
      procedure Wrong_Count is
         V : constant OpenCV.Core.UInt8_Vec2.Vector :=
           OpenCV.Core.UInt8_Vec2_Access.Get (Volume, (1, 2));
         pragma Unreferenced (V);
      begin
         null;
      end Wrong_Count;
      procedure Past is
      begin
         OpenCV.Core.UInt8_Vec2_Access.Set (Volume, (1, 3, 0), (0, 255));
      end Past;
      procedure Not_2D is
         V : constant OpenCV.Core.UInt8_Vec2.Vector :=
           OpenCV.Core.UInt8_Vec2_Access.Get (Volume, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Not_2D;
   begin
      Image.Set_To (OpenCV.Make_Scalar (1.0, 254.0));
      OpenCV.Core.UInt8_Vec2_Access.Set (Image, 1, 2, (0, 255));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec2_Access.Get (Image, 1, 2) = (0, 255)
         and then OpenCV.Core.UInt8_Vec2_Access.Get (Image, 1, 1) = (1, 254),
         "UInt8 2-D neighbors");
      Alias := Image;
      Deep := Image.Clone;
      OpenCV.Core.UInt8_Vec2_Access.Set (Alias, 1, 2, (15, 240));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec2_Access.Get (Image, 1, 2) = (15, 240)
         and then OpenCV.Core.UInt8_Vec2_Access.Get (Deep, 1, 2) = (0, 255),
         "UInt8 shallow/deep");
      OpenCV.Core.UInt8_Vec2_Access.Set (Volume, Shifted, (0, 255));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec2_Access.Get (Volume, (1, 2, 3)) = (0, 255),
         "UInt8 shifted N-D");
      Alias := Volume;
      Deep := Volume.Clone;
      OpenCV.Core.UInt8_Vec2_Access.Set (Alias, (1, 2, 3), (1, 254));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec2_Access.Get (Volume, Shifted) = (1, 254)
         and then OpenCV.Core.UInt8_Vec2_Access.Get (Deep, Shifted) = (0, 255),
         "UInt8 N-D ownership");
      Assert_Raises_OpenCV_Error (Wrong_Depth'Access, "UInt8 wrong depth");
      Assert_Raises_OpenCV_Error
        (Wrong_Channels'Access, "UInt8 wrong channels");
      Assert_Raises_OpenCV_Error (Wrong_Count'Access, "UInt8 index count");
      Assert_Raises_OpenCV_Error (Past'Access, "UInt8 past extent");
      Assert_Raises_OpenCV_Error (Not_2D'Access, "UInt8 2-D on volume");
   end UInt8_Elements;

   procedure UInt16_Elements (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 2));
      Volume  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt16, 2));
      Shifted : constant OpenCV.Core.Index_Array (10 .. 12) := (1, 2, 3);
      Alias   : OpenCV.Core.Mat;
      Deep    : OpenCV.Core.Mat;
      procedure Wrong_Depth is
         Wrong : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
         V     : constant OpenCV.Core.UInt16_Vec2.Vector :=
           OpenCV.Core.UInt16_Vec2_Access.Get (Wrong, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Wrong_Depth;
      procedure Wrong_Channels is
         Wrong : OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
      begin
         OpenCV.Core.UInt16_Vec2_Access.Set (Wrong, 0, 0, (0, 65535));
      end Wrong_Channels;
      procedure Wrong_Count is
         V : constant OpenCV.Core.UInt16_Vec2.Vector :=
           OpenCV.Core.UInt16_Vec2_Access.Get (Volume, (1, 2));
         pragma Unreferenced (V);
      begin
         null;
      end Wrong_Count;
      procedure Past is
      begin
         OpenCV.Core.UInt16_Vec2_Access.Set (Volume, (1, 3, 0), (0, 65535));
      end Past;
      procedure Not_2D is
         V : constant OpenCV.Core.UInt16_Vec2.Vector :=
           OpenCV.Core.UInt16_Vec2_Access.Get (Volume, 0, 0);
         pragma Unreferenced (V);
      begin
         null;
      end Not_2D;
   begin
      Image.Set_To (OpenCV.Make_Scalar (32767.0, 32768.0));
      OpenCV.Core.UInt16_Vec2_Access.Set (Image, 1, 2, (0, 65535));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec2_Access.Get (Image, 1, 2) = (0, 65535)
         and then OpenCV.Core.UInt16_Vec2_Access.Get (Image, 1, 1)
                  = (32767, 32768),
         "UInt16 neighbors");
      Alias := Image;
      Deep := Image.Clone;
      OpenCV.Core.UInt16_Vec2_Access.Set (Alias, 1, 2, (1, 65534));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec2_Access.Get (Image, 1, 2) = (1, 65534)
         and then OpenCV.Core.UInt16_Vec2_Access.Get (Deep, 1, 2) = (0, 65535),
         "UInt16 shallow/deep");
      OpenCV.Core.UInt16_Vec2_Access.Set (Volume, Shifted, (0, 65535));
      Alias := Volume;
      Deep := Volume.Clone;
      OpenCV.Core.UInt16_Vec2_Access.Set (Alias, (1, 2, 3), (32767, 32768));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec2_Access.Get (Volume, Shifted) = (32767, 32768)
         and then OpenCV.Core.UInt16_Vec2_Access.Get (Deep, Shifted)
                  = (0, 65535),
         "UInt16 N-D ownership");
      Assert_Raises_OpenCV_Error (Wrong_Depth'Access, "UInt16 wrong depth");
      Assert_Raises_OpenCV_Error
        (Wrong_Channels'Access, "UInt16 wrong channels");
      Assert_Raises_OpenCV_Error (Wrong_Count'Access, "UInt16 index count");
      Assert_Raises_OpenCV_Error (Past'Access, "UInt16 past extent");
      Assert_Raises_OpenCV_Error (Not_2D'Access, "UInt16 2-D on volume");
   end UInt16_Elements;

   procedure UInt8_Rows_And_Buffers (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 2));
      Alias          : OpenCV.Core.Mat := Image;
      Data           : OpenCV.Core.UInt8_Vec2_Row_Access.Row_Array (9 .. 11) :=
        ((0, 255), (1, 254), (15, 240));
      Callback_Error : exception;
      Invoked        : Boolean := False;
      procedure Read (R : aliased OpenCV.Core.UInt8_Vec2_Row_Access.Row_Array)
      is
      begin
         AUnit.Assertions.Assert
           (R'Length = 3 and then R (1) = (1, 254), "UInt8 borrowed row");
      end Read;
      procedure Write
        (R : aliased in out OpenCV.Core.UInt8_Vec2_Row_Access.Row_Array) is
      begin
         Image := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         R (2) := (0, 255);
      end Write;
      procedure Buffer
        (B : aliased in out OpenCV.Core.UInt8_Vec2_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (B'Length = 6, "UInt8 complete element count");
         B (0) := (1, 254);
      end Buffer;
      procedure Reject
        (B : aliased OpenCV.Core.UInt8_Vec2_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (B);
      begin
         Invoked := True;
      end Reject;
      procedure Throw_Row
        (R : aliased in out OpenCV.Core.UInt8_Vec2_Row_Access.Row_Array) is
      begin
         R (0) := (0, 255);
         raise Callback_Error;
      end Throw_Row;
   begin
      OpenCV.Core.UInt8_Vec2_Row_Access.Write_Row (Image, 0, Data);
      OpenCV.Core.UInt8_Vec2_Row_Access.Read_Row (Image, 0, Data);
      AUnit.Assertions.Assert
        (Data (9) = (0, 255) and then Data (11) = (15, 240),
         "UInt8 copied row bounds");
      OpenCV.Core.UInt8_Vec2_Row_Access.With_Read_Only_Row
        (Image, 0, Read'Access);
      OpenCV.Core.UInt8_Vec2_Row_Access.With_Writable_Row
        (Image, 0, Write'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec2_Access.Get (Alias, 0, 2) = (0, 255),
         "UInt8 row lease");
      OpenCV.Core.UInt8_Vec2_Buffer_Access.With_Writable_Buffer
        (Alias, Buffer'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec2_Access.Get (Alias, 0, 0) = (1, 254),
         "UInt8 buffer aliases");
      declare
         Parent : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 2));
         Gap    : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         procedure Bad_Borrow is
         begin
            OpenCV.Core.UInt8_Vec2_Buffer_Access.With_Read_Only_Buffer
              (Gap, Reject'Access);
         end Bad_Borrow;
      begin
         Assert_Raises_OpenCV_Error (Bad_Borrow'Access, "UInt8 gapped buffer");
         AUnit.Assertions.Assert
           (not Invoked, "UInt8 rejected callback not invoked");
         begin
            OpenCV.Core.UInt8_Vec2_Row_Access.With_Writable_Row
              (Parent, 0, Throw_Row'Access);
            AUnit.Assertions.Assert
              (False, "UInt8 row callback must propagate");
         exception
            when Callback_Error =>
               AUnit.Assertions.Assert
                 (OpenCV.Core.UInt8_Vec2_Access.Get (Parent, 0, 0) = (0, 255),
                  "UInt8 completed row write");
         end;
      end;
   end UInt8_Rows_And_Buffers;

   procedure UInt16_Rows_And_Buffers (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image          : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 2));
      Alias          : OpenCV.Core.Mat := Image;
      Data           :
        OpenCV.Core.UInt16_Vec2_Row_Access.Row_Array (9 .. 11) :=
          ((0, 65535), (32767, 32768), (1, 65534));
      Callback_Error : exception;
      Invoked        : Boolean := False;
      procedure Read (R : aliased OpenCV.Core.UInt16_Vec2_Row_Access.Row_Array)
      is
      begin
         AUnit.Assertions.Assert
           (R'Length = 3 and then R (1) = (32767, 32768),
            "UInt16 borrowed row");
      end Read;
      procedure Write
        (R : aliased in out OpenCV.Core.UInt16_Vec2_Row_Access.Row_Array) is
      begin
         Image := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
         R (2) := (0, 65535);
      end Write;
      procedure Buffer
        (B : aliased in out OpenCV.Core.UInt16_Vec2_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (B'Length = 6, "UInt16 complete element count");
         B (0) := (32767, 32768);
      end Buffer;
      procedure Reject
        (B : aliased OpenCV.Core.UInt16_Vec2_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (B);
      begin
         Invoked := True;
      end Reject;
      procedure Throw_Row
        (R : aliased in out OpenCV.Core.UInt16_Vec2_Row_Access.Row_Array) is
      begin
         R (0) := (0, 65535);
         raise Callback_Error;
      end Throw_Row;
   begin
      OpenCV.Core.UInt16_Vec2_Row_Access.Write_Row (Image, 0, Data);
      OpenCV.Core.UInt16_Vec2_Row_Access.Read_Row (Image, 0, Data);
      AUnit.Assertions.Assert
        (Data (9) = (0, 65535) and then Data (11) = (1, 65534),
         "UInt16 copied row bounds");
      OpenCV.Core.UInt16_Vec2_Row_Access.With_Read_Only_Row
        (Image, 0, Read'Access);
      OpenCV.Core.UInt16_Vec2_Row_Access.With_Writable_Row
        (Image, 0, Write'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec2_Access.Get (Alias, 0, 2) = (0, 65535),
         "UInt16 row lease");
      OpenCV.Core.UInt16_Vec2_Buffer_Access.With_Writable_Buffer
        (Alias, Buffer'Access);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec2_Access.Get (Alias, 0, 0) = (32767, 32768),
         "UInt16 buffer aliases");
      declare
         Parent : OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt16, 2));
         Gap    : constant OpenCV.Core.Mat :=
           Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
         procedure Bad_Borrow is
         begin
            OpenCV.Core.UInt16_Vec2_Buffer_Access.With_Read_Only_Buffer
              (Gap, Reject'Access);
         end Bad_Borrow;
      begin
         Assert_Raises_OpenCV_Error
           (Bad_Borrow'Access, "UInt16 gapped buffer");
         AUnit.Assertions.Assert
           (not Invoked, "UInt16 rejected callback not invoked");
         begin
            OpenCV.Core.UInt16_Vec2_Row_Access.With_Writable_Row
              (Parent, 0, Throw_Row'Access);
            AUnit.Assertions.Assert
              (False, "UInt16 row callback must propagate");
         exception
            when Callback_Error =>
               AUnit.Assertions.Assert
                 (OpenCV.Core.UInt16_Vec2_Access.Get (Parent, 0, 0)
                  = (0, 65535),
                  "UInt16 completed row write");
         end;
      end;
   end UInt16_Rows_And_Buffers;

   procedure UInt8_Channels_And_Transform (Test : in out Fixture) is
      pragma Unreferenced (Test);
      One      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Two      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 2));
      Identity : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Expand   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (One, 0, 0, 0);
      OpenCV.Core.UInt8_Access.Set (Two, 0, 0, 255);
      declare
         Merged : OpenCV.Core.Mat := OpenCV.Core.Merge ((7 => One, 8 => Two));
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec2_Access.Get (Merged, 0, 0) = (0, 255),
            "UInt8 Merge order");
         OpenCV.Core.UInt8_Vec2_Access.Set (Merged, 0, 0, (1, 254));
         declare
            Parts : constant OpenCV.Core.Mat_Array := Merged.Split;
         begin
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Access.Get (Parts (Parts'First), 0, 0) = 1
               and then OpenCV.Core.UInt8_Access.Get
                          (Parts (Parts'First + 1), 0, 0)
                        = 254,
               "UInt8 Split order");
         end;
      end;
      Image.Set_To (OpenCV.Make_Scalar (0.0, 255.0));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec2_Access.Get (Image, 0, 0) = (0, 255),
         "UInt8 Scalar order");
      Identity.Set_Identity;
      Expand.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Expand, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Expand, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Expand, 2, 2, 17.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec2_Access.Get (Image.Transform (Identity), 0, 0)
         = (0, 255)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Image.Transform (Expand), 0, 0)
                  = (0, 255, 17),
         "UInt8 C2 Transform identity and expansion");
   end UInt8_Channels_And_Transform;

   procedure UInt16_Channels_And_Transform (Test : in out Fixture) is
      pragma Unreferenced (Test);
      One      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
      Two      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 1));
      Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt16, 2));
      Identity : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float32, 1));
      Expand   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
   begin
      OpenCV.Core.UInt16_Access.Set (One, 0, 0, 0);
      OpenCV.Core.UInt16_Access.Set (Two, 0, 0, 65535);
      declare
         Merged : OpenCV.Core.Mat := OpenCV.Core.Merge ((7 => One, 8 => Two));
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt16_Vec2_Access.Get (Merged, 0, 0) = (0, 65535),
            "UInt16 Merge order");
         OpenCV.Core.UInt16_Vec2_Access.Set (Merged, 0, 0, (32767, 32768));
         declare
            Parts : constant OpenCV.Core.Mat_Array := Merged.Split;
         begin
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt16_Access.Get (Parts (Parts'First), 0, 0)
               = 32767
               and then OpenCV.Core.UInt16_Access.Get
                          (Parts (Parts'First + 1), 0, 0)
                        = 32768,
               "UInt16 Split order");
         end;
      end;
      Image.Set_To (OpenCV.Make_Scalar (0.0, 65535.0));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec2_Access.Get (Image, 0, 0) = (0, 65535),
         "UInt16 Scalar order");
      Identity.Set_Identity;
      Expand.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Expand, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Expand, 1, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Expand, 2, 2, 65534.0);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt16_Vec2_Access.Get (Image.Transform (Identity), 0, 0)
         = (0, 65535)
         and then OpenCV.Core.UInt16_Vec3_Access.Get
                    (Image.Transform (Expand), 0, 0)
                  = (0, 65535, 65534),
         "UInt16 C2 Transform identity and expansion");
   end UInt16_Channels_And_Transform;

   procedure UInt8_Views_And_Regions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Storage       : aliased OpenCV.Core.UInt8_Vec2_Mat_View.Buffer_Array :=
        (7 .. 12 => (0, 255));
      Constant_Data :
        aliased constant OpenCV.Core.UInt8_Vec2_Mat_View.Buffer_Array :=
          (8 .. 13 => (1, 254));
      Image         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 2));
      procedure Writable (View : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.UInt8_Vec2_Access.Set (View, 1, 2, (15, 240));
      end Writable;
      procedure Read_Only (View : OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec2_Access.Get (View, 1, 2) = (1, 254),
            "UInt8 constant view");
      end Read_Only;
      procedure Region_Row
        (Data : aliased OpenCV.Core.UInt8_Vec2_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 2 and then Data (0) = (1, 254),
            "UInt8 gapped Region row");
      end Region_Row;
   begin
      OpenCV.Core.UInt8_Vec2_Mat_View.With_Writable_Mat_View
        (Storage, 2, 3, Writable'Access);
      AUnit.Assertions.Assert
        (Storage (12) = (15, 240), "UInt8 writable external alias");
      OpenCV.Core.UInt8_Vec2_Mat_View.With_Read_Only_Mat_View
        (Constant_Data, 2, 3, Read_Only'Access);
      Image.Set_To (OpenCV.Make_Scalar (1.0, 254.0));
      declare
         Gap : constant OpenCV.Core.Mat :=
           Image.Region ((X => 1, Y => 0, Width => 2, Height => 1));
      begin
         OpenCV.Core.UInt8_Vec2_Row_Access.With_Read_Only_Row
           (Gap, 0, Region_Row'Access);
      end;
   end UInt8_Views_And_Regions;

   procedure UInt16_Views_And_Regions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Storage       : aliased OpenCV.Core.UInt16_Vec2_Mat_View.Buffer_Array :=
        (7 .. 12 => (0, 65535));
      Constant_Data :
        aliased constant OpenCV.Core.UInt16_Vec2_Mat_View.Buffer_Array :=
          (8 .. 13 => (32767, 32768));
      Image         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 2));
      procedure Writable (View : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.UInt16_Vec2_Access.Set (View, 1, 2, (1, 65534));
      end Writable;
      procedure Read_Only (View : OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt16_Vec2_Access.Get (View, 1, 2) = (32767, 32768),
            "UInt16 constant view");
      end Read_Only;
      procedure Region_Row
        (Data : aliased OpenCV.Core.UInt16_Vec2_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 2 and then Data (0) = (32767, 32768),
            "UInt16 gapped Region row");
      end Region_Row;
   begin
      OpenCV.Core.UInt16_Vec2_Mat_View.With_Writable_Mat_View
        (Storage, 2, 3, Writable'Access);
      AUnit.Assertions.Assert
        (Storage (12) = (1, 65534), "UInt16 writable external alias");
      OpenCV.Core.UInt16_Vec2_Mat_View.With_Read_Only_Mat_View
        (Constant_Data, 2, 3, Read_Only'Access);
      Image.Set_To (OpenCV.Make_Scalar (32767.0, 32768.0));
      declare
         Gap : constant OpenCV.Core.Mat :=
           Image.Region ((X => 1, Y => 0, Width => 2, Height => 1));
      begin
         OpenCV.Core.UInt16_Vec2_Row_Access.With_Read_Only_Row
           (Gap, 0, Region_Row'Access);
      end;
   end UInt16_Views_And_Regions;

   procedure Check_Raw_ABI (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Unsigned_Vec2_Tests.Raw_ABI.Check;
   end Check_Raw_ABI;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec2 elements, bounds and ownership",
            UInt8_Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt16 Vec2 elements, bounds and ownership",
            UInt16_Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec2 rows and buffers retain storage",
            UInt8_Rows_And_Buffers'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt16 Vec2 rows and buffers retain storage",
            UInt16_Rows_And_Buffers'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec2 Merge Split Scalar Transform",
            UInt8_Channels_And_Transform'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt16 Vec2 Merge Split Scalar Transform",
            UInt16_Channels_And_Transform'Access));
      Result.Add_Test
        (Caller.Create
           ("Unsigned Vec2 raw ABI layout and pointers",
            Check_Raw_ABI'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec2 views and Region rows",
            UInt8_Views_And_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt16 Vec2 views and Region rows",
            UInt16_Views_And_Regions'Access));
      return Result'Access;
   end Suite;
end Unsigned_Vec2_Tests;
