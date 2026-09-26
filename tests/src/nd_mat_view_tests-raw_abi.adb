with AUnit.Assertions;
with Interfaces;
with OpenCV.Internal.C_API;
with System;
with System.Storage_Elements;

package body ND_Mat_View_Tests.Raw_ABI is

   package C renames OpenCV.Internal.C_API;

   use type C.Status;
   use type C.Mat_Handle;
   use type C.C_Int32;
   use type C.C_UInt64;
   use type C.C_Boolean;
   use type Interfaces.Unsigned_16;
   use type System.Address;
   use type System.Storage_Elements.Integer_Address;

   type UInt16_Array is
     array (Natural range <>) of aliased Interfaces.Unsigned_16
   with Convention => C;

   type Float32_Array is array (Natural range <>) of aliased C.C_Float32
   with Convention => C;

   Fill_Value : constant Interfaces.Unsigned_16 := 16#55AA#;

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
        C.Mat_Create_External_ND
          (Ndims, Sizes, Depth, Channels, Data, Bytes, Handle'Access);
   begin
      AUnit.Assertions.Assert
        (Status = C.Error_Invalid_Argument
         and then Handle = C.Null_Mat_Handle
         and then Contains (Diagnostic, Reason),
         "external N-D C ABI must reject with a null output for '"
         & Reason
         & "'; diagnostic was '"
         & Diagnostic
         & "'");
      AUnit.Assertions.Assert
        ((for all Value of Storage => Value = Fill_Value),
         "a rejected external N-D construction must not touch storage");
   end Expect_Rejected;

   procedure Check_Rejections is
      Data         : aliased UInt16_Array (0 .. 11) := (others => Fill_Value);
      Base         : constant System.Address := Data (0)'Address;
      Two_By_Three : aliased C.C_Int32_Array := (2, 3);
      One_D        : aliased C.C_Int32_Array := (0 => 6);
      Many         : aliased C.C_Int32_Array (0 .. 32) := (others => 1);
      Zero         : aliased C.C_Int32_Array := (2, 0);
      Negative     : aliased C.C_Int32_Array := (2, -3);
      Huge         : aliased C.C_Int32_Array (0 .. 2) :=
        (others => C.C_Int32'Last);
      Wide         : aliased C.C_Int32_Array :=
        (C.C_Int32'Last, C.C_Int32'Last, 4);
      U16          : constant C.C_Int32 := C.Depth_UInt16;
      Near_Limit   : constant System.Address :=
        System.Storage_Elements.To_Address
          (System.Storage_Elements.Integer_Address'Last - 1);
      Misaligned   : constant System.Address :=
        System.Storage_Elements."+" (Base, 1);
      Status       : C.Status;
      Count_Text   : constant String := "dimension count must be in 2 .. 32";
      Extent_Text  : constant String := "extents must be positive";
      Channel_Text : constant String := "channels must be in the range";
      Byte_Text    : constant String := "byte count must equal";
   begin
      Status :=
        C.Mat_Create_External_ND
          (2, Two_By_Three (0)'Access, U16, 1, Base, 12, null);
      AUnit.Assertions.Assert
        (Status = C.Error_Invalid_Argument
         and then Contains (Diagnostic, "out_mat must not be null"),
         "external N-D C ABI must reject a null out_mat");

      Expect_Rejected
        (1, One_D (0)'Access, U16, 1, Base, 12, Data, Count_Text);
      Expect_Rejected
        (0, One_D (0)'Access, U16, 1, Base, 12, Data, Count_Text);
      Expect_Rejected
        (-1, One_D (0)'Access, U16, 1, Base, 12, Data, Count_Text);
      Expect_Rejected (33, Many (0)'Access, U16, 1, Base, 2, Data, Count_Text);
      Expect_Rejected
        (2, null, U16, 1, Base, 12, Data, "sizes must not be null");
      Expect_Rejected (2, Zero (0)'Access, U16, 1, Base, 0, Data, Extent_Text);
      Expect_Rejected
        (2, Negative (0)'Access, U16, 1, Base, 12, Data, Extent_Text);
      Expect_Rejected
        (2,
         Two_By_Three (0)'Access,
         99,
         1,
         Base,
         12,
         Data,
         "not a supported depth identifier");
      Expect_Rejected
        (2, Two_By_Three (0)'Access, U16, 0, Base, 12, Data, Channel_Text);
      Expect_Rejected
        (2, Two_By_Three (0)'Access, U16, 513, Base, 12, Data, Channel_Text);
      Expect_Rejected
        (2,
         Two_By_Three (0)'Access,
         U16,
         1,
         System.Null_Address,
         12,
         Data,
         "data must not be null");
      Expect_Rejected
        (2,
         Two_By_Three (0)'Access,
         U16,
         1,
         Misaligned,
         12,
         Data,
         "not aligned for the selected depth");
      --  Exact byte count: short, one byte long, and a whole buffer long.
      Expect_Rejected
        (2, Two_By_Three (0)'Access, U16, 1, Base, 11, Data, Byte_Text);
      Expect_Rejected
        (2, Two_By_Three (0)'Access, U16, 1, Base, 13, Data, Byte_Text);
      Expect_Rejected
        (2, Two_By_Three (0)'Access, U16, 1, Base, 24, Data, Byte_Text);
      --  (2**31 - 1)**3 overflows a 64-bit size_t element count, while
      --  (2**31 - 1)**2 * 4 fits but overflows once multiplied by 2 bytes.
      Expect_Rejected
        (3,
         Huge (0)'Access,
         U16,
         1,
         Base,
         12,
         Data,
         "element count exceeds the native size range");
      Expect_Rejected
        (3,
         Wide (0)'Access,
         U16,
         1,
         Base,
         12,
         Data,
         "exceeds the native size range");
      Expect_Rejected
        (2,
         Two_By_Three (0)'Access,
         U16,
         1,
         Near_Limit,
         12,
         Data,
         "address extent exceeds native range");
   end Check_Rejections;

   procedure Expect_View
     (Handle   : C.Mat_Handle;
      Extents  : C.C_Int32_Array;
      Depth    : C.C_Int32;
      Channels : C.C_Int32;
      Data     : System.Address;
      Bytes    : C.C_UInt64;
      Label    : String)
   is
      Value      : aliased C.C_Int32 := -1;
      Continuous : aliased C.C_Boolean := C.C_False;
      Address    : aliased System.Address := System.Null_Address;
      Borrowed   : aliased C.C_UInt64 := 0;
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
        (C.Mat_Is_Continuous (Handle, Continuous'Access) = C.Success
         and then Continuous = C.C_True,
         Label & " must be continuous");
      AUnit.Assertions.Assert
        (C.Mat_Borrow_Contiguous_Data (Handle, Address'Access, Borrowed'Access)
         = C.Success
         and then Address = Data
         and then Borrowed = Bytes,
         Label & " must alias exactly the caller buffer");
   end Expect_View;

   procedure Check_Valid_Views is
      Plane  : aliased UInt16_Array (0 .. 5) := (0, 1, 2, 3, 4, 5);
      Volume : aliased Float32_Array (0 .. 71) := (others => 0.0);
      Pair   : aliased C.C_Int32_Array := (2, 3);
      Cube   : aliased C.C_Int32_Array := (2, 3, 4);
      Handle : aliased C.Mat_Handle := C.Null_Mat_Handle;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Create_External_ND
           (2,
            Pair (0)'Access,
            C.Depth_UInt16,
            1,
            Plane (0)'Address,
            12,
            Handle'Access)
         = C.Success
         and then Handle /= C.Null_Mat_Handle,
         "a valid raw 2-D packed external view must be created");
      Expect_View
        (Handle,
         Pair,
         C.Depth_UInt16,
         1,
         Plane (0)'Address,
         12,
         "raw 2-D packed view");
      C.Mat_Destroy (Handle);
      AUnit.Assertions.Assert
        (Plane = (0, 1, 2, 3, 4, 5),
         "destroying the raw view must leave caller storage intact");

      --  24 complete Float32 C3 elements, i.e. 72 scalars and 288 bytes.
      Handle := C.Null_Mat_Handle;
      AUnit.Assertions.Assert
        (C.Mat_Create_External_ND
           (3,
            Cube (0)'Access,
            C.Depth_Float32,
            3,
            Volume (0)'Address,
            288,
            Handle'Access)
         = C.Success
         and then Handle /= C.Null_Mat_Handle,
         "a valid raw 3-D packed external view must be created");
      Expect_View
        (Handle,
         Cube,
         C.Depth_Float32,
         3,
         Volume (0)'Address,
         288,
         "raw 3-D packed view");
      C.Mat_Destroy (Handle);
   end Check_Valid_Views;

   procedure Check_Temporary_View is
      Data   : aliased UInt16_Array (0 .. 23) := (others => Fill_Value);
      Cube   : aliased C.C_Int32_Array := (2, 3, 4);
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
            "raw N-D external view " & Operation & " must be rejected");
      end Expect_Alias_Rejected;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Create_External_ND
           (3,
            Cube (0)'Access,
            C.Depth_UInt16,
            1,
            Data (0)'Address,
            48,
            View'Access)
         = C.Success,
         "the raw N-D temporary-view fixture must be created");

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
         "raw N-D external view Clone must succeed");
      C.Mat_Destroy (View);

      --  The owned Clone is not a temporary view: it may shallow-alias.
      Result := C.Null_Mat_Handle;
      AUnit.Assertions.Assert
        (C.Mat_Reshape_ND (Clone, 1, 2, Flat (0)'Access, Result'Access)
         = C.Success
         and then Result /= C.Null_Mat_Handle,
         "an owned Clone of a raw N-D external view must Reshape");
      C.Mat_Destroy (Result);

      declare
         Address  : aliased System.Address := System.Null_Address;
         Borrowed : aliased C.C_UInt64 := 0;
      begin
         AUnit.Assertions.Assert
           (C.Mat_Borrow_Contiguous_Data
              (Clone, Address'Access, Borrowed'Access)
            = C.Success
            and then Borrowed = 48
            and then Address /= Data (0)'Address,
            "the raw Clone must own independent storage");
      end;
      C.Mat_Destroy (Clone);
      AUnit.Assertions.Assert
        ((for all Value of Data => Value = Fill_Value),
         "rejected raw aliases and Clone must leave caller storage intact");
   end Check_Temporary_View;

end ND_Mat_View_Tests.Raw_ABI;
