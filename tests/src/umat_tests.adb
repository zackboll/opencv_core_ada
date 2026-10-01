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
with OpenCV.Internal.C_API;

package body UMat_Tests is
   package C renames OpenCV.Internal.C_API;
   package T renames OpenCV.Core.Transfers;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Integer_32;
   use type Interfaces.IEEE_Float_32;
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
