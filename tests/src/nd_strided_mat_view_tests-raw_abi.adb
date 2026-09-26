with AUnit.Assertions;
with Interfaces;
with Module_Bridge_Probe;
with OpenCV.Internal.C_API;
with System;
with System.Storage_Elements;

package body ND_Strided_Mat_View_Tests.Raw_ABI is

   package C renames OpenCV.Internal.C_API;

   use type C.Status;
   use type C.Mat_Handle;
   use type C.C_Int32;
   use type C.C_UInt64;
   use type C.C_Boolean;
   use type Interfaces.Unsigned_16;
   use type Interfaces.IEEE_Float_64;
   use type System.Address;
   use type System.Storage_Elements.Integer_Address;

   type UInt16_Array is
     array (Natural range <>) of aliased Interfaces.Unsigned_16
   with Convention => C;

   type Float64_Array is array (Natural range <>) of aliased C.C_Float64
   with Convention => C;

   Fill_Value : constant Interfaces.Unsigned_16 := 16#55AA#;

   --  2**62 and 2**40 element strides for overflow fixtures.
   Two_62 : constant C.C_UInt64 := 2**62;
   Two_40 : constant C.C_UInt64 := 2**40;

   function Diagnostic return String
   is (C.Last_Error_Message);

   function Contains (Source, Fragment : String) return Boolean
   is (Source'Length >= Fragment'Length
       and then (for some Offset in 0 .. Source'Length - Fragment'Length =>
                   Source
                     (Source'First
                      + Offset
                      .. Source'First + Offset + Fragment'Length - 1)
                   = Fragment));

   procedure Expect_Rejected
     (Ndims    : C.C_Int32;
      Sizes    : access C.C_Int32;
      Strides  : access C.C_UInt64;
      Depth    : C.C_Int32;
      Channels : C.C_Int32;
      Data     : System.Address;
      Bytes    : C.C_UInt64;
      Storage  : UInt16_Array;
      Reason   : String)
   is
      --  Non-null sentinel proves the shim initializes *out_mat to null.
      Handle : aliased C.Mat_Handle :=
        C.Mat_Handle (Storage (Storage'First)'Address);
      Status : constant C.Status :=
        C.Mat_Create_External_ND_Strided
          (Ndims, Sizes, Strides, Depth, Channels, Data, Bytes, Handle'Access);
   begin
      AUnit.Assertions.Assert
        (Status = C.Error_Invalid_Argument
         and then Handle = C.Null_Mat_Handle
         and then Contains (Diagnostic, Reason),
         "external strided N-D C ABI must reject with a null output for '"
         & Reason
         & "'; diagnostic was '"
         & Diagnostic
         & "'");
      AUnit.Assertions.Assert
        ((for all Value of Storage => Value = Fill_Value),
         "a rejected strided N-D construction must not touch storage");
   end Expect_Rejected;

   procedure Check_Rejections is
      --  Canonical gapped fixture: Shape (2, 3, 4), strides (20, 6, 1),
      --  40 UInt16 elements = 80 bytes of required capacity.
      Data       : aliased UInt16_Array (0 .. 39) := (others => Fill_Value);
      Base       : constant System.Address := Data (0)'Address;
      Cube       : aliased C.C_Int32_Array := (2, 3, 4);
      Gap        : aliased C.C_UInt64_Array := (20, 6, 1);
      One_D      : aliased C.C_Int32_Array := (0 => 6);
      One_Stride : aliased C.C_UInt64_Array := (0 => 1);
      Many       : aliased C.C_Int32_Array (0 .. 32) := (others => 1);
      Many_Gap   : aliased C.C_UInt64_Array (0 .. 32) := (others => 1);
      --  (1, .., 1, 2) shapes with strides (2, .., 2, 1): four bytes.
      Eleven     : aliased C.C_Int32_Array (0 .. 10) := (10 => 2, others => 1);
      Eleven_Gap : aliased C.C_UInt64_Array (0 .. 10) :=
        (10 => 1, others => 2);
      Zero       : aliased C.C_Int32_Array := (2, 0, 4);
      Negative   : aliased C.C_Int32_Array := (2, -3, 4);
      Zero_Gap   : aliased C.C_UInt64_Array := (20, 0, 1);
      Final_Two  : aliased C.C_UInt64_Array := (20, 6, 2);
      Inner      : aliased C.C_UInt64_Array := (20, 3, 1);
      Outer      : aliased C.C_UInt64_Array := (17, 6, 1);
      --  2**62 * 4 overflows uint64 in the nested-block product.
      Nest_Wide  : aliased C.C_Int32_Array := (2, 4, 1);
      Nest_Gap   : aliased C.C_UInt64_Array := (Two_62 * 2, Two_62, 1);
      Pair       : aliased C.C_Int32_Array := (1, 2);
      --  2**62 Float64 elements overflow a 64-bit byte stride.
      Byte_Gap   : aliased C.C_UInt64_Array := (Two_62, 1);
      --  8 * 2**61 elements overflow a 64-bit capacity product.
      Wide_Outer : aliased C.C_Int32_Array := (8, 2);
      Cap_Gap    : aliased C.C_UInt64_Array := (Two_62 / 2, 1);
      --  A 2**40 stride fits uint64 but not a 32-bit size_t.
      Wide_Gap   : aliased C.C_UInt64_Array := (Two_40, 1);
      U16        : constant C.C_Int32 := C.Depth_UInt16;
      Near_Limit : constant System.Address :=
        System.Storage_Elements.To_Address
          (System.Storage_Elements.Integer_Address'Last - 1);
      Misaligned : constant System.Address :=
        System.Storage_Elements."+" (Base, 1);
      Status     : C.Status;

      procedure Reject
        (Reason   : String;
         Sizes    : access C.C_Int32 := Cube (0)'Access;
         Strides  : access C.C_UInt64 := Gap (0)'Access;
         Ndims    : C.C_Int32 := 3;
         Bytes    : C.C_UInt64 := 80;
         Depth    : C.C_Int32 := U16;
         Channels : C.C_Int32 := 1;
         Address  : System.Address := Base) is
      begin
         Expect_Rejected
           (Ndims,
            Sizes,
            Strides,
            Depth,
            Channels,
            Address,
            Bytes,
            Data,
            Reason);
      end Reject;

      Count_Text : constant String := "dimension count must be in 2 .. 32";
      Nest_Text  : constant String := "smaller than its nested inner block";
      Short_Text : constant String := "backing storage is too short";
   begin
      Status :=
        C.Mat_Create_External_ND_Strided
          (3, Cube (0)'Access, Gap (0)'Access, U16, 1, Base, 80, null);
      AUnit.Assertions.Assert
        (Status = C.Error_Invalid_Argument
         and then Contains (Diagnostic, "out_mat must not be null"),
         "external strided N-D C ABI must reject a null out_mat");

      Reject (Count_Text, One_D (0)'Access, One_Stride (0)'Access, Ndims => 1);
      Reject (Count_Text, One_D (0)'Access, One_Stride (0)'Access, Ndims => 0);
      Reject
        (Count_Text, One_D (0)'Access, One_Stride (0)'Access, Ndims => -1);
      Reject (Count_Text, Many (0)'Access, Many_Gap (0)'Access, Ndims => 33);
      if Module_Bridge_Probe.OpenCV_Major_Version >= 5 then
         --  OpenCV 5.0's native MatShape capacity is 10 dimensions; the
         --  shim rejects longer shapes before the native constructor.
         Reject
           ("exceeds this OpenCV version's native Mat limit",
            Eleven (0)'Access,
            Eleven_Gap (0)'Access,
            Ndims => 11,
            Bytes => 4);
      end if;
      Reject ("sizes must not be null", Sizes => null);
      Reject ("strides must not be null", Strides => null);
      Reject ("extents must be positive", Zero (0)'Access);
      Reject ("extents must be positive", Negative (0)'Access);
      Reject ("not a supported depth identifier", Depth => 99);
      Reject ("channels must be in the range", Channels => 0);
      Reject ("channels must be in the range", Channels => 513);
      Reject ("strides must be positive", Strides => Zero_Gap (0)'Access);
      Reject ("final stride must be 1", Strides => Final_Two (0)'Access);
      --  3 < 1 * 4 and 17 < 6 * 3: overlapping layouts.
      Reject (Nest_Text, Strides => Inner (0)'Access);
      Reject (Nest_Text, Strides => Outer (0)'Access);
      Reject
        ("nested stride exceeds the C ABI range",
         Nest_Wide (0)'Access,
         Nest_Gap (0)'Access);
      if Standard'Address_Size < 64 then
         Reject
           ("stride exceeds the native size range",
            Pair (0)'Access,
            Wide_Gap (0)'Access,
            Ndims => 2);
      else
         Reject
           ("byte stride exceeds the native size range",
            Pair (0)'Access,
            Byte_Gap (0)'Access,
            Ndims => 2,
            Depth => C.Depth_Float64);
         Reject
           ("required capacity exceeds the native size range",
            Wide_Outer (0)'Access,
            Cap_Gap (0)'Access,
            Ndims => 2);
      end if;
      --  Capacity must cover the complete outer stride (80 bytes), not
      --  merely the final logical element (36 elements = 72 bytes).
      Reject (Short_Text, Bytes => 79);
      Reject (Short_Text, Bytes => 72);
      Reject ("data must not be null", Address => System.Null_Address);
      Reject ("not aligned for the selected depth", Address => Misaligned);
      Reject ("address extent exceeds native range", Address => Near_Limit);
   end Check_Rejections;

   procedure Expect_Geometry
     (Handle     : C.Mat_Handle;
      Extents    : C.C_Int32_Array;
      Depth      : C.C_Int32;
      Channels   : C.C_Int32;
      Continuous : Boolean;
      Label      : String)
   is
      Value : aliased C.C_Int32 := -1;
      Flag  : aliased C.C_Boolean := C.C_False;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Dimension_Count (Handle, Value'Access) = C.Success
         and then Value = Extents'Length,
         Label & " must report the requested dimension count");
      for Axis in Extents'Range loop
         AUnit.Assertions.Assert
           (C.Mat_Extent
              (Handle, C.C_Int32 (Axis - Extents'First), Value'Access)
            = C.Success
            and then Value = Extents (Axis),
            Label & " must report every requested extent");
      end loop;
      AUnit.Assertions.Assert
        (C.Mat_Depth (Handle, Value'Access) = C.Success
         and then Value = Depth
         and then C.Mat_Channels (Handle, Value'Access) = C.Success
         and then Value = Channels,
         Label & " must report the requested depth and channel count");
      AUnit.Assertions.Assert
        (C.Mat_Is_Continuous (Handle, Flag'Access) = C.Success
         and then (Flag = C.C_True) = Continuous,
         Label & " must report the expected continuity");
   end Expect_Geometry;

   procedure Check_Valid_Views is
      --  44 Float64 elements: 40 required by (20, 6, 1) plus 4 trailing.
      Volume : aliased Float64_Array (0 .. 43) := (others => -1.0);
      Cube   : aliased C.C_Int32_Array := (2, 3, 4);
      Gap    : aliased C.C_UInt64_Array := (20, 6, 1);
      Packed : aliased C.C_UInt64_Array := (12, 4, 1);
      Handle : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Probe  : aliased C.C_Float64 := 0.0;
      At_012 : aliased C.C_Int32_Array := (0, 1, 2);
      At_123 : aliased C.C_Int32_Array := (1, 2, 3);
      At_100 : aliased C.C_Int32_Array := (1, 0, 0);
   begin
      Volume (8) := 8.5;
      AUnit.Assertions.Assert
        (C.Mat_Create_External_ND_Strided
           (3,
            Cube (0)'Access,
            Gap (0)'Access,
            C.Depth_Float64,
            1,
            Volume (0)'Address,
            352,
            Handle'Access)
         = C.Success
         and then Handle /= C.Null_Mat_Handle,
         "a valid raw gapped 3-D view with trailing capacity must be created");
      Expect_Geometry
        (Handle, Cube, C.Depth_Float64, 1, False, "raw gapped 3-D view");
      AUnit.Assertions.Assert
        (C.Mat_Get_Float64_ND (Handle, 3, At_012 (0)'Access, Probe'Access)
         = C.Success
         and then Probe = 8.5,
         "raw gapped (0, 1, 2) must read caller element 8");
      AUnit.Assertions.Assert
        (C.Mat_Set_Float64_ND (Handle, 3, At_123 (0)'Access, 35.5) = C.Success
         and then C.Mat_Set_Float64_ND (Handle, 3, At_100 (0)'Access, 20.5)
                  = C.Success,
         "raw gapped N-D Set must succeed");
      C.Mat_Destroy (Handle);
      AUnit.Assertions.Assert
        (Volume (35) = 35.5 and then Volume (20) = 20.5,
         "raw gapped (1, 2, 3) and (1, 0, 0) must reach offsets 35 and 20");
      AUnit.Assertions.Assert
        ((for all Offset in Volume'Range =>
            Offset in 8 | 20 | 35 or else Volume (Offset) = -1.0),
         "raw gapped view and its destruction must leave other caller"
         & " storage intact");

      Handle := C.Null_Mat_Handle;
      AUnit.Assertions.Assert
        (C.Mat_Create_External_ND_Strided
           (3,
            Cube (0)'Access,
            Packed (0)'Access,
            C.Depth_Float64,
            1,
            Volume (0)'Address,
            192,
            Handle'Access)
         = C.Success
         and then Handle /= C.Null_Mat_Handle,
         "a valid raw packed-equivalent 3-D view must be created");
      Expect_Geometry
        (Handle,
         Cube,
         C.Depth_Float64,
         1,
         True,
         "raw packed-equivalent 3-D view");
      declare
         Address  : aliased System.Address := System.Null_Address;
         Borrowed : aliased C.C_UInt64 := 0;
      begin
         AUnit.Assertions.Assert
           (C.Mat_Borrow_Contiguous_Data
              (Handle, Address'Access, Borrowed'Access)
            = C.Success
            and then Address = Volume (0)'Address
            and then Borrowed = 192,
            "raw packed-equivalent view must alias exactly the caller"
            & " buffer");
      end;
      C.Mat_Destroy (Handle);

      --  Highest dimension count accepted natively by the linked OpenCV:
      --  the historic 32 on 4.x, MatShape::MAX_DIMS = 10 on 5.0. A
      --  (1, .., 1, 2) shape with strides (2, .., 2, 1) spans two elements.
      --  On OpenCV 4.1 setSize() reads _steps[ndims-1]; the shim's full
      --  ndims-entry native step array keeps that read in bounds.
      declare
         Native_Limit : constant Positive :=
           (if Module_Bridge_Probe.OpenCV_Major_Version >= 5 then 10 else 32);
         Tall         : aliased C.C_Int32_Array (0 .. Native_Limit - 1) :=
           (others => 1);
         Tall_Gap     : aliased C.C_UInt64_Array (0 .. Native_Limit - 1) :=
           (others => 2);
      begin
         Tall (Tall'Last) := 2;
         Tall_Gap (Tall_Gap'Last) := 1;
         Handle := C.Null_Mat_Handle;
         AUnit.Assertions.Assert
           (C.Mat_Create_External_ND_Strided
              (C.C_Int32 (Native_Limit),
               Tall (0)'Access,
               Tall_Gap (0)'Access,
               C.Depth_Float64,
               1,
               Volume (0)'Address,
               16,
               Handle'Access)
            = C.Success
            and then Handle /= C.Null_Mat_Handle,
            "a raw strided view at the native dimension limit must be"
            & " created");
         Expect_Geometry
           (Handle,
            Tall,
            C.Depth_Float64,
            1,
            True,
            "raw native-limit strided view");
         C.Mat_Destroy (Handle);
      end;
   end Check_Valid_Views;

   procedure Check_Temporary_View is
      Data   : aliased UInt16_Array (0 .. 39) := (others => Fill_Value);
      Cube   : aliased C.C_Int32_Array := (2, 3, 4);
      Gap    : aliased C.C_UInt64_Array := (20, 6, 1);
      Starts : aliased C.C_Int32_Array := (0, 0, 0);
      Stops  : aliased C.C_Int32_Array := (1, 3, 4);
      Flat   : aliased C.C_Int32_Array := (6, 4);
      View   : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Clone  : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Result : aliased C.Mat_Handle;
      Status : C.Status;

      procedure Expect_Alias_Rejected (Operation : String) is
      begin
         AUnit.Assertions.Assert
           (Status = C.Error_Invalid_Argument
            and then Result = C.Null_Mat_Handle
            and then Contains (Diagnostic, "cannot create shallow aliases"),
            "raw strided N-D external view "
            & Operation
            & " must be rejected");
      end Expect_Alias_Rejected;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Create_External_ND_Strided
           (3,
            Cube (0)'Access,
            Gap (0)'Access,
            C.Depth_UInt16,
            1,
            Data (0)'Address,
            80,
            View'Access)
         = C.Success,
         "the raw strided N-D temporary-view fixture must be created");

      Result := C.Mat_Handle (Data (0)'Address);
      Status := C.Mat_Copy (View, Result'Access);
      Expect_Alias_Rejected ("shallow copy");

      Result := C.Mat_Handle (Data (0)'Address);
      Status :=
        C.Mat_Slice_ND
          (View, 3, Starts (0)'Access, Stops (0)'Access, Result'Access);
      Expect_Alias_Rejected ("Slice");

      Result := C.Mat_Handle (Data (0)'Address);
      Status := C.Mat_Reshape_ND (View, 1, 2, Flat (0)'Access, Result'Access);
      Expect_Alias_Rejected ("Reshape");

      AUnit.Assertions.Assert
        (C.Mat_Clone (View, Clone'Access) = C.Success
         and then Clone /= C.Null_Mat_Handle,
         "raw strided N-D external view Clone must succeed");
      C.Mat_Destroy (View);

      declare
         Address  : aliased System.Address := System.Null_Address;
         Borrowed : aliased C.C_UInt64 := 0;
      begin
         --  The Clone holds only the 24 logical elements, packed.
         AUnit.Assertions.Assert
           (C.Mat_Borrow_Contiguous_Data
              (Clone, Address'Access, Borrowed'Access)
            = C.Success
            and then Borrowed = 48
            and then Address /= Data (0)'Address,
            "the raw Clone must own independent packed storage");
      end;

      --  The owned Clone is not a temporary view: it may shallow-alias.
      Result := C.Null_Mat_Handle;
      AUnit.Assertions.Assert
        (C.Mat_Reshape_ND (Clone, 1, 2, Flat (0)'Access, Result'Access)
         = C.Success
         and then Result /= C.Null_Mat_Handle,
         "an owned Clone of a raw strided N-D view must Reshape");
      C.Mat_Destroy (Result);
      C.Mat_Destroy (Clone);
      AUnit.Assertions.Assert
        ((for all Value of Data => Value = Fill_Value),
         "rejected raw aliases and Clone must leave caller storage intact");
   end Check_Temporary_View;

end ND_Strided_Mat_View_Tests.Raw_ABI;
