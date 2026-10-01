with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float16_Access;
with OpenCV.Internal.C_API;

package body UMat_Tests is
   package C renames OpenCV.Internal.C_API;
   package T renames OpenCV.Core.Transfers;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Integer_32;
   use type Interfaces.IEEE_Float_32;
   use type Interfaces.IEEE_Float_64;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Core.Dimension_Array;
   use type OpenCV.Core.UInt8_Vec3.Vector;
   use type OpenCV.Size_Coordinate;
   use type C.Status;
   use type C.UMat_Handle;
   use type C.Mat_Handle;
   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Use_OpenCL return Interfaces.Unsigned_8
   with Import, Convention => C, External_Name => "umat_probe_use_opencl";
   function Set_OpenCL
     (Enabled : Interfaces.Unsigned_8) return Interfaces.Unsigned_8
   with Import, Convention => C, External_Name => "umat_probe_set_opencl";

   function Pixel
     (Image : OpenCV.Core.UMat; Row, Column : Natural := 0)
      return Interfaces.Unsigned_8
   is
      Host : constant OpenCV.Core.Mat := T.To_Mat (Image);
   begin
      return OpenCV.Core.UInt8_Access.Get (Host, Row, Column);
   end Pixel;

   procedure Default_And_Create
     (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty  : OpenCV.Core.UMat;
      Image  : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 3, (OpenCV.Core.Float32, 3));
      Half   : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 2, (OpenCV.Core.Float16, 1));
      Byte   : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 2, (OpenCV.Core.UInt8, 1));
      Double : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 2, (OpenCV.Core.Float64, 4));
   begin
      AUnit.Assertions.Assert
        (Empty.Is_Empty
         and then Empty.Dimension_Count = 0
         and then Empty.Total = 0,
         "default UMat metadata");
      AUnit.Assertions.Assert
        (Image.Rows = 2
         and then Image.Columns = 3
         and then Image.Depth = OpenCV.Core.Float32
         and then Image.Channels = 3
         and then Image.Total = 6
         and then Image.Element_Size = 12
         and then Image.Channel_Size = 4
         and then Image.Is_Continuous
         and then not Image.Is_Submatrix,
         "2-D C3 UMat metadata");
      AUnit.Assertions.Assert
        (Half.Depth = OpenCV.Core.Float16 and then Half.Channel_Size = 2,
         "Float16 UMat storage");
      AUnit.Assertions.Assert
        (Byte.Element_Size = 1
         and then Double.Element_Size = 32
         and then Double.Channels = 4,
         "UInt8 C1 and Float64 C4");
   end Default_And_Create;

   procedure ND_And_Views (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Parent        : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat ((2, 3, 4), (OpenCV.Core.UInt8, 1));
      View          : OpenCV.Core.UMat :=
        Parent.Slice
          (OpenCV.Core.Index_Range_Array'
             ((Start => 0, Stop => 2),
              (Start => 1, Stop => 3),
              (Start => 0, Stop => 4)));
      Clone         : OpenCV.Core.UMat := View.Clone;
      Wide          : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat ((2, 2, 2, 3, 2), (OpenCV.Core.UInt8, 1));
      Shifted       : constant OpenCV.Core.Dimension_Array (4 .. 6) :=
        (2, 3, 4);
      Shifted_Image : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (Shifted, (OpenCV.Core.Float64, 4));
      Ten           : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat
          ((1, 1, 1, 1, 1, 1, 1, 1, 1, 1), (OpenCV.Core.UInt8, 1));
      Eleven        : constant OpenCV.Core.Dimension_Array := (1 .. 11 => 1);
   begin
      Parent.Set_To (OpenCV.Make_Scalar (4.0));
      View.Set_To (OpenCV.Make_Scalar (9.0));
      AUnit.Assertions.Assert
        (Parent.Shape = (2, 3, 4)
         and then View.Shape = (2, 2, 4)
         and then View.Is_Submatrix
         and then Wide.Total = 48
         and then Shifted_Image.Shape = (2, 3, 4)
         and then Shifted_Image.Channels = 4
         and then Ten.Dimension_Count = 10
         and then Parent.Extent (2) = 3,
         "N-D metadata and shallow slice");
      if Module_Bridge_Probe.OpenCV_Major_Version >= 5 then
         declare
            procedure Reject_Eleven is
               Too_Wide : constant OpenCV.Core.UMat :=
                 OpenCV.Core.Create_UMat (Eleven, (OpenCV.Core.UInt8, 1));
            begin
               AUnit.Assertions.Assert
                 (Too_Wide.Is_Empty, "unreachable 11-D UMat");
            end Reject_Eleven;
         begin
            Mat_Test_Support.Assert_Raises_OpenCV_Error
              (Reject_Eleven'Access, "OpenCV 5 native capacity");
         end;
      else
         declare
            Extra : constant OpenCV.Core.UMat :=
              OpenCV.Core.Create_UMat ((1 .. 32 => 1), (OpenCV.Core.UInt8, 1));
         begin
            AUnit.Assertions.Assert
              (Extra.Dimension_Count = 32, "OpenCV 4 32-D capacity");
         end;
      end if;
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (T.To_Mat (Parent), (0, 1, 0)) = 9,
         "slice writes shared storage");
      Clone.Set_To (OpenCV.Make_Scalar (3.0));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (T.To_Mat (View), (0, 0, 0)) = 9,
         "slice clone independent");
   end ND_And_Views;

   procedure Invalid_Public_Bounds
     (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 3, (OpenCV.Core.UInt8, 1));
      procedure Empty_Shape is
         U : constant OpenCV.Core.UMat :=
           OpenCV.Core.Create_UMat ((2, 0, 4), (OpenCV.Core.UInt8, 1));
      begin
         AUnit.Assertions.Assert (U.Is_Empty, "unreachable empty UMat");
      end Empty_Shape;
      procedure Outside_Region is
         U : constant OpenCV.Core.UMat :=
           Image.Region ((X => 2, Y => 0, Width => 2, Height => 1));
      begin
         AUnit.Assertions.Assert (U.Is_Empty, "unreachable region");
      end Outside_Region;
      procedure Outside_Slice is
         U : constant OpenCV.Core.UMat :=
           Image.Slice
             (OpenCV.Core.Index_Range_Array'
                ((Start => 0, Stop => 2), (Start => 1, Stop => 4)));
      begin
         AUnit.Assertions.Assert (U.Is_Empty, "unreachable slice");
      end Outside_Slice;
      procedure Excess_Channels is
         U : OpenCV.Core.UMat :=
           OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.UInt8, 5));
      begin
         U.Set_To (OpenCV.Make_Scalar (1.0));
      end Excess_Channels;
      procedure ND_Rows is
         U     : constant OpenCV.Core.UMat :=
           OpenCV.Core.Create_UMat ((2, 3, 4), (OpenCV.Core.UInt8, 1));
         Count : constant Natural := U.Rows;
      begin
         AUnit.Assertions.Assert (Count = 0, "unreachable N-D rows");
      end ND_Rows;
   begin
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Empty_Shape'Access, "UMat shape rejects zero extents");
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Outside_Region'Access, "UMat Region validates coordinates in Ada");
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Outside_Slice'Access, "UMat Slice validates ranges in Ada");
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Excess_Channels'Access, "UMat Scalar cannot represent C5");
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (ND_Rows'Access, "UMat Rows rejects genuine N-D shapes");
   end Invalid_Public_Bounds;

   procedure Multi_Channel_And_ND_Transfers
     (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source    : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat ((2, 3, 4), (OpenCV.Core.UInt8, 3));
      Alias     : OpenCV.Core.UMat := Source;
      Converted : OpenCV.Core.UMat;
      Host      : OpenCV.Core.Mat;
      Roundtrip : OpenCV.Core.UMat;
      Copy      : OpenCV.Core.UMat;
   begin
      Source.Set_To (OpenCV.Make_Scalar (12.0, 24.0, 36.0));
      Converted := Source.Convert_To (OpenCV.Core.Float32, 0.5, 1.0);
      Host := T.To_Mat (Source);
      Roundtrip := T.To_UMat (Host);
      Copy := Source.Clone;
      Alias.Set_To (OpenCV.Make_Scalar (4.0, 5.0, 6.0));
      AUnit.Assertions.Assert
        (Converted.Shape = (2, 3, 4)
         and then Converted.Channels = 3
         and then Converted.Depth = OpenCV.Core.Float32
         and then Roundtrip.Shape = (2, 3, 4)
         and then Copy.Shape = (2, 3, 4),
         "N-D multi-channel transfers and conversion metadata");
      AUnit.Assertions.Assert
        (Source.Shape = (2, 3, 4)
         and then T.To_Mat (Roundtrip).Shape = (2, 3, 4)
         and then T.To_Mat (Copy).Shape = (2, 3, 4)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (T.To_Mat (Roundtrip), (0, 0, 0))
                  = (12, 24, 36)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (T.To_Mat (Copy), (0, 0, 0))
                  = (12, 24, 36)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (T.To_Mat (Source), (0, 0, 0))
                  = (4, 5, 6),
         "N-D C3 transfers and clone retain independent values");
   end Multi_Channel_And_ND_Transfers;

   procedure Alias_Survives_Parent
     (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Alias : OpenCV.Core.UMat;
   begin
      declare
         Parent : OpenCV.Core.UMat :=
           OpenCV.Core.Create_UMat (3, 4, (OpenCV.Core.UInt8, 1));
      begin
         Parent.Set_To (OpenCV.Make_Scalar (27.0));
         Alias := Parent.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      end;
      AUnit.Assertions.Assert
        (Alias.Shape = (2, 2) and then Pixel (Alias) = 27,
         "self-assigned shallow view survives parent finalization");
   end Alias_Survives_Parent;

   procedure Transfer_And_Ownership
     (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Host        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.UInt8, 1));
      Part        : OpenCV.Core.Mat :=
        Host.Region ((X => 1, Y => 1, Width => 2, Height => 2));
      Device      : OpenCV.Core.UMat;
      Alias       : OpenCV.Core.UMat;
      Independent : OpenCV.Core.UMat;
      Download    : OpenCV.Core.Mat;
   begin
      Host.Set_To (OpenCV.Make_Scalar (6.0));
      Device := T.To_UMat (Part);
      Alias := Device;
      Independent := Device.Copy_To;
      OpenCV.Core.UInt8_Access.Set (Part, 0, 0, 11);
      AUnit.Assertions.Assert
        (Device.Shape = (2, 2) and then Pixel (Device) = 6,
         "non-contiguous Mat Region transfers independently");
      Device.Set_To (OpenCV.Make_Scalar (20.0));
      AUnit.Assertions.Assert
        (Pixel (Alias) = 20
         and then Pixel (Independent) = 6
         and then OpenCV.Core.UInt8_Access.Get (Part, 0, 0) = 11,
         "UMat assignment aliases while Copy_To and Mat transfer do not");
      Download := T.To_Mat (Device);
      OpenCV.Core.UInt8_Access.Set (Download, 0, 0, 5);
      AUnit.Assertions.Assert (Pixel (Device) = 20, "download independent");
   end Transfer_And_Ownership;

   procedure Convert_Region_And_Fallback
     (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Previous : constant Interfaces.Unsigned_8 := Use_OpenCL;
   begin
      AUnit.Assertions.Assert (Set_OpenCL (0) = 1, "disable OpenCL probe");
      begin
         AUnit.Assertions.Assert (Use_OpenCL = 0, "OpenCL disabled");
         declare
            Host        : OpenCV.Core.Mat :=
              OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
            Device      : OpenCV.Core.UMat;
            Copy        : OpenCV.Core.UMat;
            Float_Image : OpenCV.Core.UMat;
            Saturated   : OpenCV.Core.UMat;
            Window      : OpenCV.Core.UMat;
         begin
            OpenCV.Core.UInt8_Access.Set (Host, 0, 0, 5);
            Device := T.To_UMat (Host);
            Copy := Device.Clone;
            Device.Set_To (OpenCV.Make_Scalar (10.0));
            Float_Image := Device.Convert_To (OpenCV.Core.Float32, 2.0, 3.0);
            Saturated := Float_Image.Convert_To (OpenCV.Core.UInt8, 20.0, 0.0);
            Window :=
              Device.Region ((X => 1, Y => 0, Width => 2, Height => 1));
            Window.Set_To (OpenCV.Make_Scalar (30.0));
            AUnit.Assertions.Assert
              (Pixel (Device, 0, 1) = 30
               and then Pixel (Copy) = 5
               and then Pixel (Saturated) = 255
               and then OpenCV.Core.Float32_Access.Get
                          (T.To_Mat (Float_Image), 0, 0)
                        = 23.0,
               "UMat operations work with OpenCL explicitly disabled");
         end;
      exception
         when others =>
            AUnit.Assertions.Assert
              (Set_OpenCL (Previous) = 1, "restore OpenCL on failure");
            raise;
      end;
      AUnit.Assertions.Assert
        (Set_OpenCL (Previous) = 1, "restore OpenCL after test");
   end Convert_Region_And_Fallback;

   procedure Arithmetic_Float32 (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Left  : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.Float32, 1));
      Right : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.Float32, 1));
      function Value (Image : OpenCV.Core.UMat) return OpenCV.Float32_Value
      is (OpenCV.Core.Float32_Access.Get (T.To_Mat (Image), 0, 0));
   begin
      Left.Set_To (OpenCV.Make_Scalar (12.0));
      Right.Set_To (OpenCV.Make_Scalar (3.0));
      AUnit.Assertions.Assert
        (Value (OpenCV.Core.Add (Left, Right)) = 15.0, "UMat add");
      AUnit.Assertions.Assert
        (Value (OpenCV.Core.Subtract (Left, Right)) = 9.0, "UMat subtract");
      AUnit.Assertions.Assert
        (Value (OpenCV.Core.Multiply (Left, Right)) = 36.0, "UMat multiply");
      AUnit.Assertions.Assert
        (abs (Value (OpenCV.Core.Divide (Left, Right)) - 4.0) < 0.000_01,
         "UMat divide");
      AUnit.Assertions.Assert
        (Value (OpenCV.Core.Abs_Diff (Left, Right)) = 9.0, "UMat absdiff");
      AUnit.Assertions.Assert
        (Value (OpenCV.Core.Minimum (Left, Right)) = 3.0, "UMat minimum");
      AUnit.Assertions.Assert
        (Value (OpenCV.Core.Maximum (Left, Right)) = 12.0, "UMat maximum");
   end Arithmetic_Float32;

   procedure Arithmetic_Numeric_And_Regions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      L   : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 4, (OpenCV.Core.UInt8, 1));
      R   : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 4, (OpenCV.Core.UInt8, 1));
      A   : OpenCV.Core.UMat;
      B   : OpenCV.Core.UMat;
      Sum : OpenCV.Core.UMat;
      D   : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.Float64, 1));
   begin
      L.Set_To (OpenCV.Make_Scalar (250.0));
      R.Set_To (OpenCV.Make_Scalar (10.0));
      A := L.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      B := R.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      Sum := OpenCV.Core.Add (A, B);
      AUnit.Assertions.Assert
        (Sum.Rows = 2
         and then Sum.Columns = 2
         and then Pixel (Sum, 1, 1) = 255,
         "noncontiguous add saturates");
      AUnit.Assertions.Assert
        (Pixel (OpenCV.Core.Subtract (B, A)) = 0
         and then Pixel (OpenCV.Core.Multiply (A, B)) = 255
         and then Pixel (OpenCV.Core.Divide (A, B)) = 25
         and then Pixel (OpenCV.Core.Abs_Diff (A, B)) = 240
         and then Pixel (OpenCV.Core.Minimum (A, B)) = 10
         and then Pixel (OpenCV.Core.Maximum (A, B)) = 250,
         "UInt8 native arithmetic and noncontiguous regions");
      L.Set_To (OpenCV.Make_Scalar (1.0));
      AUnit.Assertions.Assert
        (Pixel (Sum) = 255 and then Pixel (OpenCV.Core.Abs_Diff (A, B)) = 9,
         "result independent of parent mutation");
      D.Set_To (OpenCV.Make_Scalar (2.5));
      AUnit.Assertions.Assert
        (OpenCV.Core.Float64_Access.Get
           (T.To_Mat (OpenCV.Core.Add (D, D)), 0, 0)
         = 5.0,
         "Float64 UMat arithmetic");
   end Arithmetic_Numeric_And_Regions;

   procedure Arithmetic_Channels (Test : in out Fixture) is
      pragma Unreferenced (Test);
      L : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.UInt8, 3));
      R : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.UInt8, 3));
      H : OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      K : OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      use OpenCV.Core.UInt8_Vec3;
      function Vector
        (U : OpenCV.Core.UMat) return OpenCV.Core.UInt8_Vec3.Vector
      is (OpenCV.Core.UInt8_Vec3_Access.Get (T.To_Mat (U), 0, 0));
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (H, 0, 0, (2, 5, 9));
      OpenCV.Core.UInt8_Vec3_Access.Set (K, 0, 0, (3, 4, 1));
      L := T.To_UMat (H);
      R := T.To_UMat (K);
      AUnit.Assertions.Assert
        (Vector (OpenCV.Core.Add (L, R)) = (5, 9, 10)
         and then Vector (OpenCV.Core.Minimum (L, R)) = (2, 4, 1)
         and then Vector (OpenCV.Core.Maximum (L, R)) = (3, 5, 9)
         and then Vector (OpenCV.Core.Multiply (L, R)) = (6, 20, 9)
         and then OpenCV.Core.Add (L, R).Channels = 3,
         "all C3 channels retained");
   end Arithmetic_Channels;

   procedure Arithmetic_Half_And_Empty (Test : in out Fixture) is
      pragma Unreferenced (Test);
      H : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));
      K : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float16, 1));
      L : OpenCV.Core.UMat;
      R : OpenCV.Core.UMat;
      E : OpenCV.Core.UMat;
      Z : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (0, 0, (OpenCV.Core.UInt8, 1));
      function Half (U : OpenCV.Core.UMat) return OpenCV.Float32_Value
      is (OpenCV.Core.To_Float32
            (OpenCV.Core.Float16_Access.Get (T.To_Mat (U), 0, 0)));
   begin
      OpenCV.Core.Float16_Access.Set (H, 0, 0, OpenCV.Core.To_Float16 (12.0));
      OpenCV.Core.Float16_Access.Set (K, 0, 0, OpenCV.Core.To_Float16 (3.0));
      L := T.To_UMat (H);
      R := T.To_UMat (K);
      AUnit.Assertions.Assert
        (Half (OpenCV.Core.Add (L, R)) = 15.0
         and then Half (OpenCV.Core.Subtract (L, R)) = 9.0
         and then Half (OpenCV.Core.Multiply (L, R)) = 36.0
         and then Half (OpenCV.Core.Divide (L, R)) = 4.0
         and then Half (OpenCV.Core.Abs_Diff (L, R)) = 9.0
         and then Half (OpenCV.Core.Minimum (L, R)) = 3.0
         and then Half (OpenCV.Core.Maximum (L, R)) = 12.0,
         "seven Float16 UMat results");
      AUnit.Assertions.Assert
        (OpenCV.Core.Add (E, E).Is_Empty
         and then OpenCV.Core.Subtract (Z, Z).Is_Empty
         and then OpenCV.Core.Abs_Diff (E, Z).Is_Empty
         and then OpenCV.Core.Multiply (E, E).Is_Empty
         and then OpenCV.Core.Divide (E, Z).Is_Empty
         and then OpenCV.Core.Minimum (Z, E).Is_Empty
         and then OpenCV.Core.Maximum (Z, Z).Is_Empty,
         "default and typed empty UMat results");
   end Arithmetic_Half_And_Empty;

   procedure Arithmetic_Half_Special (Test : in out Fixture) is
      pragma Unreferenced (Test);
      pragma Suppress (Validity_Check);
      H                      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float16, 1));
      K                      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float16, 1));
      F32_L, F32_R           : OpenCV.Core.UMat;
      Min_H, Max_H           : OpenCV.Core.Mat;
      Min_Oracle, Max_Oracle : OpenCV.Core.Mat;
      L_Bits                 :
        constant array (0 .. 3) of Interfaces.Unsigned_16 :=
          (16#0000#, 16#8000#, 16#7C00#, 16#7E00#);
      R_Bits                 :
        constant array (0 .. 3) of Interfaces.Unsigned_16 :=
          (16#8000#, 16#0000#, 16#3C00#, 16#3C00#);
   begin
      for Column in 0 .. 3 loop
         OpenCV.Core.Float16_Access.Set
           (H, 0, Column, OpenCV.Core.Float16_From_Bits (L_Bits (Column)));
         OpenCV.Core.Float16_Access.Set
           (K, 0, Column, OpenCV.Core.Float16_From_Bits (R_Bits (Column)));
      end loop;
      F32_L := T.To_UMat (H).Convert_To (OpenCV.Core.Float32);
      F32_R := T.To_UMat (K).Convert_To (OpenCV.Core.Float32);
      Min_H := T.To_Mat (OpenCV.Core.Minimum (T.To_UMat (H), T.To_UMat (K)));
      Max_H := T.To_Mat (OpenCV.Core.Maximum (T.To_UMat (H), T.To_UMat (K)));
      Min_Oracle := T.To_Mat (OpenCV.Core.Minimum (F32_L, F32_R));
      Max_Oracle := T.To_Mat (OpenCV.Core.Maximum (F32_L, F32_R));
      for Column in 0 .. 3 loop
         AUnit.Assertions.Assert
           (OpenCV.Core.Float16_Bits
              (OpenCV.Core.Float16_Access.Get (Min_H, 0, Column))
            = OpenCV.Core.Float16_Bits
                (OpenCV.Core.To_Float16
                   (OpenCV.Core.Float32_Access.Get (Min_Oracle, 0, Column)))
            and then OpenCV.Core.Float16_Bits
                       (OpenCV.Core.Float16_Access.Get (Max_H, 0, Column))
                     = OpenCV.Core.Float16_Bits
                         (OpenCV.Core.To_Float16
                            (OpenCV.Core.Float32_Access.Get
                               (Max_Oracle, 0, Column))),
            "Float16 UMat special min/max Float32 model");
      end loop;
   end Arithmetic_Half_Special;

   procedure Arithmetic_Invalid (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Base     : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 3, (OpenCV.Core.UInt8, 1));
      Rows     : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (3, 3, (OpenCV.Core.UInt8, 1));
      Cols     : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 4, (OpenCV.Core.UInt8, 1));
      Depth    : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 3, (OpenCV.Core.Float32, 1));
      Channels : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 3, (OpenCV.Core.UInt8, 3));
      ND       : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat ((2, 3, 2), (OpenCV.Core.UInt8, 1));
      procedure Bad_Rows is
         X : constant OpenCV.Core.UMat := OpenCV.Core.Add (Base, Rows);
      begin
         AUnit.Assertions.Assert (X.Is_Empty, "unreachable");
      end Bad_Rows;
      procedure Bad_Cols is
         X : constant OpenCV.Core.UMat := OpenCV.Core.Minimum (Base, Cols);
      begin
         AUnit.Assertions.Assert (X.Is_Empty, "unreachable");
      end Bad_Cols;
      procedure Bad_Depth is
         X : constant OpenCV.Core.UMat := OpenCV.Core.Subtract (Base, Depth);
      begin
         AUnit.Assertions.Assert (X.Is_Empty, "unreachable");
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.UMat := OpenCV.Core.Maximum (Base, Channels);
      begin
         AUnit.Assertions.Assert (X.Is_Empty, "unreachable");
      end Bad_Channels;
      procedure Bad_ND is
         X : constant OpenCV.Core.UMat := OpenCV.Core.Add (ND, ND);
      begin
         AUnit.Assertions.Assert (X.Is_Empty, "unreachable");
      end Bad_ND;
   begin
      Mat_Test_Support.Assert_Raises_OpenCV_Error (Bad_Rows'Access, "rows");
      Mat_Test_Support.Assert_Raises_OpenCV_Error (Bad_Cols'Access, "columns");
      Mat_Test_Support.Assert_Raises_OpenCV_Error (Bad_Depth'Access, "depth");
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "channels");
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Bad_ND'Access, "2-D policy");
   end Arithmetic_Invalid;

   procedure Arithmetic_OpenCL_Disabled (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Previous : constant Interfaces.Unsigned_8 := Use_OpenCL;
   begin
      AUnit.Assertions.Assert (Set_OpenCL (0) = 1, "disable OpenCL");
      begin
         declare
            L : OpenCV.Core.UMat :=
              OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.Float32, 1));
            R : OpenCV.Core.UMat :=
              OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.Float32, 1));
            function V (U : OpenCV.Core.UMat) return OpenCV.Float32_Value
            is (OpenCV.Core.Float32_Access.Get (T.To_Mat (U), 0, 0));
         begin
            L.Set_To (OpenCV.Make_Scalar (12.0));
            R.Set_To (OpenCV.Make_Scalar (3.0));
            AUnit.Assertions.Assert
              (Use_OpenCL = 0
               and then V (OpenCV.Core.Add (L, R)) = 15.0
               and then V (OpenCV.Core.Subtract (L, R)) = 9.0
               and then V (OpenCV.Core.Multiply (L, R)) = 36.0
               and then abs (V (OpenCV.Core.Divide (L, R)) - 4.0) < 0.000_01
               and then V (OpenCV.Core.Abs_Diff (L, R)) = 9.0
               and then V (OpenCV.Core.Minimum (L, R)) = 3.0
               and then V (OpenCV.Core.Maximum (L, R)) = 12.0,
               "seven numerical results without OpenCL");
         end;
      exception
         when others =>
            AUnit.Assertions.Assert
              (Set_OpenCL (Previous) = 1, "restore OpenCL after failure");
            raise;
      end;
      AUnit.Assertions.Assert (Set_OpenCL (Previous) = 1, "restore OpenCL");
   end Arithmetic_OpenCL_Disabled;

   procedure Arithmetic_Raw_ABI (Test : in out Fixture) is
      pragma Unreferenced (Test);
      L          : aliased C.UMat_Handle := C.Null_UMat_Handle;
      R          : aliased C.UMat_Handle := C.Null_UMat_Handle;
      Out_Handle : aliased C.UMat_Handle := C.Null_UMat_Handle;
      F          : aliased C.UMat_Handle := C.Null_UMat_Handle;
   begin
      AUnit.Assertions.Assert
        (C.UMat_Add (C.Null_UMat_Handle, C.Null_UMat_Handle, null)
         = C.Error_Invalid_Argument,
         "raw null output");
      AUnit.Assertions.Assert
        (C.UMat_Create_2D (1, 1, 0, 1, L'Access) = C.Success
         and then C.UMat_Create_2D (1, 1, 0, 1, R'Access) = C.Success,
         "raw operands");
      begin
         AUnit.Assertions.Assert
           (C.UMat_Add (C.Null_UMat_Handle, R, Out_Handle'Access)
            = C.Error_Invalid_Argument
            and then Out_Handle = C.Null_UMat_Handle
            and then C.UMat_Add (L, C.Null_UMat_Handle, Out_Handle'Access)
                     = C.Error_Invalid_Argument
            and then Out_Handle = C.Null_UMat_Handle,
            "raw null inputs clear result");
         AUnit.Assertions.Assert
           (C.UMat_Add (L, R, Out_Handle'Access) = C.Success
            and then Out_Handle /= C.Null_UMat_Handle,
            "raw result publication");
         C.UMat_Destroy (L);
         L := C.Null_UMat_Handle;
         C.UMat_Destroy (R);
         R := C.Null_UMat_Handle;
         declare
            Count : aliased C.C_Int32 := 0;
         begin
            AUnit.Assertions.Assert
              (C.UMat_Rows (Out_Handle, Count'Access) = C.Success
               and then Count = 1,
               "raw result survives source destruction");
         end;
         AUnit.Assertions.Assert
           (C.UMat_Create_2D (1, 1, 7, 1, F'Access) = C.Success,
            "raw Float16 operands");
         C.UMat_Destroy (Out_Handle);
         Out_Handle := C.Null_UMat_Handle;
         AUnit.Assertions.Assert
           (C.UMat_Add (F, F, Out_Handle'Access) = C.Success
            and then Out_Handle /= C.Null_UMat_Handle,
            "raw Float16 compatibility");
      exception
         when others =>
            C.UMat_Destroy (L);
            C.UMat_Destroy (R);
            C.UMat_Destroy (F);
            C.UMat_Destroy (Out_Handle);
            raise;
      end;
      C.UMat_Destroy (F);
      C.UMat_Destroy (Out_Handle);
   end Arithmetic_Raw_ABI;

   procedure Weighted_Numeric (Test : in out Fixture) is
      pragma Unreferenced (Test);
      L : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 3, (OpenCV.Core.Float32, 1));
      R : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (2, 3, (OpenCV.Core.Float32, 1));
      A : OpenCV.Core.UMat;
      B : OpenCV.Core.UMat;
      W : OpenCV.Core.UMat;
      S : OpenCV.Core.UMat;
      D : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.Float64, 1));
      I : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.UInt8, 1));
      function Value (U : OpenCV.Core.UMat) return OpenCV.Float32_Value
      is (OpenCV.Core.Float32_Access.Get (T.To_Mat (U), 0, 0));
   begin
      L.Set_To (OpenCV.Make_Scalar (10.0));
      R.Set_To (OpenCV.Make_Scalar (4.0));
      A := L.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      B := R.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      W := OpenCV.Core.Add_Weighted (A, 2.0, B, 3.0, 5.0);
      S := OpenCV.Core.Scale_Add (A, 2.5, B);
      AUnit.Assertions.Assert
        (W.Rows = 2
         and then W.Columns = 2
         and then S.Rows = 2
         and then S.Columns = 2
         and then Value (W) = 37.0
         and then Value (S) = 29.0,
         "Float32 noncontiguous Region weighted results");
      L.Set_To (OpenCV.Make_Scalar (1.0));
      R.Set_To (OpenCV.Make_Scalar (2.0));
      AUnit.Assertions.Assert
        (Value (W) = 37.0
         and then Value (S) = 29.0
         and then Value (A) = 1.0
         and then Value (B) = 2.0,
         "results independent of UMat parents and Regions");
      D.Set_To (OpenCV.Make_Scalar (1.25));
      AUnit.Assertions.Assert
        (OpenCV.Core.Add_Weighted (D, 2.0, D, 3.0).Depth = OpenCV.Core.Float64
         and then OpenCV.Core.Float64_Access.Get
                    (T.To_Mat (OpenCV.Core.Add_Weighted (D, 2.0, D, 3.0)),
                     0,
                     0)
                  = 6.25
         and then OpenCV.Core.Float64_Access.Get
                    (T.To_Mat (OpenCV.Core.Scale_Add (D, 2.0, D)), 0, 0)
                  = 3.75,
         "Float64 weighted native path");
      I.Set_To (OpenCV.Make_Scalar (250.0));
      AUnit.Assertions.Assert
        (Pixel (OpenCV.Core.Add_Weighted (I, 2.0, I, 1.0)) = 255
         and then Pixel (OpenCV.Core.Scale_Add (I, 2.0, I)) = 255,
         "UInt8 weighted saturation");
   end Weighted_Numeric;

   procedure Weighted_ND_And_Channels (Test : in out Fixture) is
      pragma Unreferenced (Test);
      L   : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat ((2, 3, 2, 4, 2), (OpenCV.Core.Float32, 1));
      R   : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat ((2, 3, 2, 4, 2), (OpenCV.Core.Float32, 1));
      Bad : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat ((2, 3, 2, 4, 3), (OpenCV.Core.Float32, 1));
      C1  : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.UInt8, 3));
      C2  : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.UInt8, 3));
      procedure Wrong_Extent is
         X : constant OpenCV.Core.UMat :=
           OpenCV.Core.Add_Weighted (L, 1.0, Bad, 1.0);
      begin
         AUnit.Assertions.Assert (X.Is_Empty, "unreachable");
      end Wrong_Extent;
      procedure Wrong_Dimension is
         X : constant OpenCV.Core.UMat := OpenCV.Core.Scale_Add (L, 1.0, R);
      begin
         AUnit.Assertions.Assert (X.Is_Empty, "unreachable");
      end Wrong_Dimension;
   begin
      L.Set_To (OpenCV.Make_Scalar (10.0));
      R.Set_To (OpenCV.Make_Scalar (4.0));
      declare
         W : constant OpenCV.Core.UMat :=
           OpenCV.Core.Add_Weighted (L, 2.0, R, 3.0, 5.0);
      begin
         AUnit.Assertions.Assert
           (W.Shape = (2, 3, 2, 4, 2)
            and then W.Depth = OpenCV.Core.Float32
            and then W.Channels = 1
            and then OpenCV.Core.Float32_Access.Get
                       (T.To_Mat (W), (1, 2, 1, 3, 1))
                     = 37.0,
            "genuine 5-D UMat weighted addition");
      end;
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Wrong_Extent'Access, "weighted N-D mismatched extent");
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Wrong_Dimension'Access, "scale-add remains 2-D");
      C1.Set_To (OpenCV.Make_Scalar (2.0, 5.0, 9.0));
      C2.Set_To (OpenCV.Make_Scalar (3.0, 4.0, 1.0));
      AUnit.Assertions.Assert
        (OpenCV.Core.Add_Weighted (C1, 2.0, C2, 1.0).Channels = 3
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (T.To_Mat (OpenCV.Core.Add_Weighted (C1, 2.0, C2, 1.0)),
                     0,
                     0)
                  = (7, 14, 19)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (T.To_Mat (OpenCV.Core.Scale_Add (C1, 2.0, C2)), 0, 0)
                  = (7, 14, 19),
         "C3 weighted channels");
   end Weighted_ND_And_Channels;

   procedure Weighted_Half_And_Empty (Test : in out Fixture) is
      pragma Unreferenced (Test);
      L     : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.Float16, 1));
      R     : OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.Float16, 1));
      E     : OpenCV.Core.UMat;
      Z     : constant OpenCV.Core.UMat :=
        OpenCV.Core.Create_UMat (0, 0, (OpenCV.Core.Float16, 1));
      Alpha : constant Long_Float := 1.0 + 2.0**(-25);
      Scale : constant Long_Float := 1.0 + 2.0**(-25);
      function Half (U : OpenCV.Core.UMat) return OpenCV.Float32_Value
      is (OpenCV.Core.To_Float32
            (OpenCV.Core.Float16_Access.Get (T.To_Mat (U), 0, 0)));
   begin
      L.Set_To (OpenCV.Make_Scalar (2.0));
      R.Set_To (OpenCV.Make_Scalar (3.0));
      AUnit.Assertions.Assert
        (Half (OpenCV.Core.Add_Weighted (L, 2.0, R, 3.0, 5.0)) = 18.0
         and then Half (OpenCV.Core.Scale_Add (L, 2.5, R)) = 8.0,
         "Float16 weighted and scale-add native compatibility");
      --  Compare the same coefficient policy against the established Mat
      --  path; optimized OpenCV kernels may round intermediate products.
      L.Set_To (OpenCV.Make_Scalar (16_384.0));
      R.Set_To (OpenCV.Make_Scalar (-16_384.0));
      declare
         Host_L   : constant OpenCV.Core.Mat := T.To_Mat (L);
         Host_R   : constant OpenCV.Core.Mat := T.To_Mat (R);
         Expected : constant OpenCV.Float32_Value :=
           OpenCV.Core.To_Float32
             (OpenCV.Core.Float16_Access.Get
                (OpenCV.Core.Add_Weighted (Host_L, Alpha, Host_R, 1.0), 0, 0));
      begin
         AUnit.Assertions.Assert
           (abs (Half (OpenCV.Core.Add_Weighted (L, Alpha, R, 1.0)) - Expected)
            < 0.002,
            "Add_Weighted matches Mat double coefficient policy");
      end;
      --  Float32(Scale) rounds 1 + 2**(-25) to 1; with these operands
      --  a full-double multiply would instead leave 2**(-11).
      L.Set_To (OpenCV.Make_Scalar (16_384.0));
      R.Set_To (OpenCV.Make_Scalar (-16_384.0));
      declare
         Host_L : constant OpenCV.Core.Mat := T.To_Mat (L);
         Host_R : constant OpenCV.Core.Mat := T.To_Mat (R);
         Model  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Scale_Add
             (Host_L.Convert_To (OpenCV.Core.Float32),
              Long_Float (OpenCV.Float32_Value (Scale)),
              Host_R.Convert_To (OpenCV.Core.Float32));
      begin
         AUnit.Assertions.Assert
           (Half (OpenCV.Core.Scale_Add (L, Scale, R)) = 0.0
            and then OpenCV.Core.Float32_Access.Get (Model, 0, 0) = 0.0,
            "Float16 Scale_Add narrows coefficient before Float32 kernel");
      end;
      AUnit.Assertions.Assert
        (OpenCV.Core.Add_Weighted (E, 1.0, E, 1.0).Is_Empty
         and then OpenCV.Core.Scale_Add (E, 1.0, E).Is_Empty
         and then OpenCV.Core.Add_Weighted (Z, 1.0, Z, 1.0).Is_Empty
         and then OpenCV.Core.Scale_Add (Z, 1.0, Z).Is_Empty,
         "Float16 default and typed empty weighted operations");
   end Weighted_Half_And_Empty;

   procedure Weighted_Without_OpenCL (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Previous : constant Interfaces.Unsigned_8 := Use_OpenCL;
   begin
      AUnit.Assertions.Assert (Set_OpenCL (0) = 1, "disable OpenCL");
      begin
         declare
            L : OpenCV.Core.UMat :=
              OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.Float32, 1));
            R : OpenCV.Core.UMat :=
              OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.Float32, 1));
            H : OpenCV.Core.UMat :=
              OpenCV.Core.Create_UMat (1, 1, (OpenCV.Core.Float16, 1));
         begin
            L.Set_To (OpenCV.Make_Scalar (10.0));
            R.Set_To (OpenCV.Make_Scalar (4.0));
            H.Set_To (OpenCV.Make_Scalar (2.0));
            AUnit.Assertions.Assert
              (Use_OpenCL = 0
               and then OpenCV.Core.Float32_Access.Get
                          (T.To_Mat
                             (OpenCV.Core.Add_Weighted (L, 2.0, R, 3.0, 5.0)),
                           0,
                           0)
                        = 37.0
               and then OpenCV.Core.Float32_Access.Get
                          (T.To_Mat (OpenCV.Core.Scale_Add (L, 2.5, R)), 0, 0)
                        = 29.0
               and then OpenCV.Core.To_Float32
                          (OpenCV.Core.Float16_Access.Get
                             (T.To_Mat (OpenCV.Core.Scale_Add (H, 2.5, H)),
                              0,
                              0))
                        = 7.0,
               "weighted CPU fallback including Float16");
         end;
      exception
         when others =>
            AUnit.Assertions.Assert
              (Set_OpenCL (Previous) = 1, "restore OpenCL on failure");
            raise;
      end;
      AUnit.Assertions.Assert (Set_OpenCL (Previous) = 1, "restore OpenCL");
   end Weighted_Without_OpenCL;

   procedure Weighted_Raw_ABI (Test : in out Fixture) is
      pragma Unreferenced (Test);
      L      : aliased C.UMat_Handle := C.Null_UMat_Handle;
      R      : aliased C.UMat_Handle := C.Null_UMat_Handle;
      H      : aliased C.UMat_Handle := C.Null_UMat_Handle;
      Output : aliased C.UMat_Handle := C.Null_UMat_Handle;
   begin
      AUnit.Assertions.Assert
        (C.UMat_Add_Weighted
           (C.Null_UMat_Handle, 1.0, C.Null_UMat_Handle, 1.0, 0.0, null)
         = C.Error_Invalid_Argument
         and then C.UMat_Scale_Add
                    (C.Null_UMat_Handle, 1.0, C.Null_UMat_Handle, null)
                  = C.Error_Invalid_Argument,
         "weighted raw null output pointers");
      AUnit.Assertions.Assert
        (C.UMat_Create_2D (1, 1, 5, 1, L'Access) = C.Success
         and then C.UMat_Create_2D (1, 1, 5, 1, R'Access) = C.Success
         and then C.UMat_Create_2D (1, 1, 7, 1, H'Access) = C.Success,
         "weighted raw operands");
      begin
         AUnit.Assertions.Assert
           (C.UMat_Add_Weighted
              (C.Null_UMat_Handle, 1.0, R, 1.0, 0.0, Output'Access)
            = C.Error_Invalid_Argument
            and then Output = C.Null_UMat_Handle
            and then C.UMat_Scale_Add
                       (L, 1.0, C.Null_UMat_Handle, Output'Access)
                     = C.Error_Invalid_Argument
            and then Output = C.Null_UMat_Handle,
            "weighted raw null operands clear output");
         AUnit.Assertions.Assert
           (C.UMat_Add_Weighted (L, 2.0, R, 3.0, 5.0, Output'Access)
            = C.Success
            and then Output /= C.Null_UMat_Handle,
            "raw weighted result published");
         C.UMat_Destroy (L);
         L := C.Null_UMat_Handle;
         C.UMat_Destroy (R);
         R := C.Null_UMat_Handle;
         declare
            Rows : aliased C.C_Int32 := 0;
         begin
            AUnit.Assertions.Assert
              (C.UMat_Rows (Output, Rows'Access) = C.Success and then Rows = 1,
               "weighted result survives operands");
         end;
         C.UMat_Destroy (Output);
         Output := C.Null_UMat_Handle;
         AUnit.Assertions.Assert
           (C.UMat_Scale_Add (H, 2.0, H, Output'Access) = C.Success
            and then Output /= C.Null_UMat_Handle,
            "raw Float16 scale-add compatibility");
      exception
         when others =>
            C.UMat_Destroy (L);
            C.UMat_Destroy (R);
            C.UMat_Destroy (H);
            C.UMat_Destroy (Output);
            raise;
      end;
      C.UMat_Destroy (H);
      C.UMat_Destroy (Output);
   end Weighted_Raw_ABI;

   procedure Raw_ABI_Safety (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Handle   : aliased C.UMat_Handle := C.Null_UMat_Handle;
      Value    : aliased C.C_Int32 := 99;
      Sizes    : aliased constant C.C_Int32_Array := (2, 3, 4);
      Negative : aliased constant C.C_Int32_Array := (2, -1, 4);
   begin
      AUnit.Assertions.Assert
        (C.UMat_Create (null) = C.Error_Invalid_Argument,
         "null output rejected");
      AUnit.Assertions.Assert
        (C.UMat_Clone (C.Null_UMat_Handle, Handle'Access)
         = C.Error_Invalid_Argument
         and then Handle = C.Null_UMat_Handle,
         "null input and cleared output");
      AUnit.Assertions.Assert
        (C.UMat_Create_ND (33, Sizes (0)'Access, 0, 1, Handle'Access)
         = C.Error_Invalid_Argument
         and then Handle = C.Null_UMat_Handle,
         "oversized raw shape rejected before native array access");
      AUnit.Assertions.Assert
        (C.UMat_Create_2D (2, 3, 99, 1, Handle'Access)
         = C.Error_Invalid_Argument
         and then Handle = C.Null_UMat_Handle,
         "invalid depth and output initialization");
      AUnit.Assertions.Assert
        (C.UMat_Create_2D (2, 3, 0, 0, Handle'Access)
         = C.Error_Invalid_Argument
         and then Handle = C.Null_UMat_Handle,
         "invalid packed channels rejected");
      AUnit.Assertions.Assert
        (C.UMat_Create_ND (3, null, 0, 1, Handle'Access)
         = C.Error_Invalid_Argument
         and then Handle = C.Null_UMat_Handle,
         "null N-D sizes rejected");
      AUnit.Assertions.Assert
        (C.UMat_Create_ND (3, Negative (0)'Access, 0, 1, Handle'Access)
         = C.Error_Invalid_Argument
         and then Handle = C.Null_UMat_Handle,
         "negative raw extents rejected before allocation arithmetic");
      AUnit.Assertions.Assert
        (C.UMat_Convert_To (C.Null_UMat_Handle, 0, 1.0, 0.0, Handle'Access)
         = C.Error_Invalid_Argument
         and then Handle = C.Null_UMat_Handle,
         "conversion failure clears handle");
      AUnit.Assertions.Assert
        (C.UMat_Dimension_Count (C.Null_UMat_Handle, Value'Access)
         = C.Error_Invalid_Argument
         and then Value = 0,
         "metadata reset on failure");
      AUnit.Assertions.Assert
        (C.UMat_Create (Handle'Access) = C.Success,
         "raw default create succeeds");
      begin
         AUnit.Assertions.Assert
           (C.UMat_Dimension_Count (Handle, Value'Access) = C.Success
            and then Value = 0,
            "raw default has zero dimensions");
      exception
         when others =>
            C.UMat_Destroy (Handle);
            raise;
      end;
      C.UMat_Destroy (Handle);
      Handle := C.Null_UMat_Handle;
      AUnit.Assertions.Assert
        (C.UMat_Create_ND (3, Sizes (0)'Access, 0, 1, Handle'Access)
         = C.Success,
         "raw valid N-D create");
      declare
         Alias : aliased C.UMat_Handle := C.Null_UMat_Handle;
         Clone : aliased C.UMat_Handle := C.Null_UMat_Handle;
         Host  : aliased C.Mat_Handle := C.Null_Mat_Handle;
      begin
         AUnit.Assertions.Assert
           (C.UMat_Copy (Handle, Alias'Access) = C.Success
            and then C.UMat_Clone (Handle, Clone'Access) = C.Success,
            "raw shallow and deep header copies");
         C.UMat_Destroy (Handle);
         Handle := C.Null_UMat_Handle;
         AUnit.Assertions.Assert
           (C.UMat_To_Mat (Alias, Host'Access) = C.Success
            and then Host /= C.Null_Mat_Handle,
            "raw shallow copy survives parent finalization");
         C.Mat_Destroy (Host);
         C.UMat_Destroy (Alias);
         AUnit.Assertions.Assert
           (C.UMat_Dimension_Count (Clone, Value'Access) = C.Success
            and then Value = 3,
            "raw clone survives source destruction");
         C.UMat_Destroy (Clone);
      end;
      AUnit.Assertions.Assert
        (C.UMat_Create_2D (2, 3, 0, 1, Handle'Access) = C.Success,
         "raw valid 2-D create");
      declare
         Bad : aliased C.UMat_Handle := C.Null_UMat_Handle;
      begin
         AUnit.Assertions.Assert
           (C.UMat_Region (Handle, 2, 0, 2, 1, Bad'Access) /= C.Success
            and then Bad = C.Null_UMat_Handle,
            "raw invalid region rejected without publishing");
      end;
      C.UMat_Destroy (Handle);
   end Raw_ABI_Safety;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("UMat weighted numeric and Regions", Weighted_Numeric'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat weighted N-D and C3", Weighted_ND_And_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat weighted Float16", Weighted_Half_And_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat weighted without OpenCL", Weighted_Without_OpenCL'Access));
      Result.Add_Test
        (Caller.Create ("UMat weighted raw ABI", Weighted_Raw_ABI'Access));
      Result.Add_Test
        (Caller.Create ("UMat Float32 arithmetic", Arithmetic_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat numeric and Region arithmetic",
            Arithmetic_Numeric_And_Regions'Access));
      Result.Add_Test
        (Caller.Create ("UMat C3 arithmetic", Arithmetic_Channels'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat Float16 and empty arithmetic",
            Arithmetic_Half_And_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat Float16 min max special values",
            Arithmetic_Half_Special'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat arithmetic validation", Arithmetic_Invalid'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat arithmetic without OpenCL",
            Arithmetic_OpenCL_Disabled'Access));
      Result.Add_Test
        (Caller.Create ("UMat arithmetic raw ABI", Arithmetic_Raw_ABI'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat default and 2-D create", Default_And_Create'Access));
      Result.Add_Test (Caller.Create ("UMat N-D slice", ND_And_Views'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat transfer and ownership", Transfer_And_Ownership'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat OpenCL-disabled fallback",
            Convert_Region_And_Fallback'Access));
      Result.Add_Test
        (Caller.Create ("UMat raw ABI safety", Raw_ABI_Safety'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat N-D C3 transfer", Multi_Channel_And_ND_Transfers'Access));
      Result.Add_Test
        (Caller.Create ("UMat view lifetime", Alias_Survives_Parent'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat public validation", Invalid_Public_Bounds'Access));
      return Result'Access;
   end Suite;
end UMat_Tests;
