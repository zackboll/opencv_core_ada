with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Internal.C_API;
with System.Storage_Elements;

package body External_View_C_ABI_Tests is

   use type OpenCV.Internal.C_API.Mat_Handle;
   use type OpenCV.Internal.C_API.C_UInt64;
   use type OpenCV.Internal.C_API.Status;
   use type Interfaces.Unsigned_16;
   use type System.Storage_Elements.Integer_Address;

   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   type UInt16_Array is
     array (Natural range <>) of aliased Interfaces.Unsigned_16
   with Convention => C;

   function Diagnostic return String
   is (OpenCV.Internal.C_API.Last_Error_Message);

   function Contains (Source, Fragment : String) return Boolean
   is (Source'Length >= Fragment'Length
       and then (for some Offset in 0 .. Source'Length - Fragment'Length =>
                   Source
                     (Source'First
                      + Offset
                      .. Source'First + Offset + Fragment'Length - 1)
                   = Fragment));

   procedure Assert_Rejected
     (Status : OpenCV.Internal.C_API.Status;
      Handle : OpenCV.Internal.C_API.Mat_Handle;
      Data   : UInt16_Array;
      Reason : String) is
   begin
      AUnit.Assertions.Assert
        (Status = OpenCV.Internal.C_API.Error_Invalid_Argument
         and then Handle = OpenCV.Internal.C_API.Null_Mat_Handle
         and then Contains (Diagnostic, Reason),
         "C ABI rejection must be invalid-argument, clear the output, and"
         & " identify '"
         & Reason
         & "'; diagnostic was '"
         & Diagnostic
         & "'");
      AUnit.Assertions.Assert
        (Data (Data'First) = 16#55AA# and then Data (Data'Last) = 16#55AA#,
         "Rejected C ABI construction must not mutate live backing storage");
   end Assert_Rejected;

   procedure Full_Stride_Capacity_Is_Enforced_With_Null_Output_On_Failure
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data   : aliased UInt16_Array (1 .. 16) := (others => 16#55AA#);
      Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Mat_Handle (Data (1)'Address);
      Status : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Create_External_2D_Strided
          (Rows             => 3,
           Columns          => 4,
           Depth            => OpenCV.Internal.C_API.Depth_UInt16,
           Channels         => 1,
           Data             => Data (1)'Address,
           Byte_Count       => 32,
           Row_Stride_Bytes => 12,
           Result           => Handle'Access);
      Assert_Rejected (Status, Handle, Data, "backing storage is too short");
   end Full_Stride_Capacity_Is_Enforced_With_Null_Output_On_Failure;

   procedure Incompatible_Stride_Is_Rejected_Before_Capacity
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data   : aliased UInt16_Array (1 .. 8) := (others => 16#55AA#);
      Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Mat_Handle (Data (1)'Address);
      Status : OpenCV.Internal.C_API.Status;
   begin
      --  Three bytes is at least the 2-byte logical row, but UInt16 scalar
      --  size does not divide it. Capacity is large enough that a later
      --  length check would succeed.
      Status :=
        OpenCV.Internal.C_API.Mat_Create_External_2D_Strided
          (Rows             => 1,
           Columns          => 1,
           Depth            => OpenCV.Internal.C_API.Depth_UInt16,
           Channels         => 1,
           Data             => Data (1)'Address,
           Byte_Count       => 16,
           Row_Stride_Bytes => 3,
           Result           => Handle'Access);
      Assert_Rejected (Status, Handle, Data, "incompatible with scalar size");
   end Incompatible_Stride_Is_Rejected_Before_Capacity;

   procedure Native_Stride_Narrowing_Is_Rejected_Where_Applicable
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data   : aliased UInt16_Array (1 .. 1) := (others => 16#55AA#);
      Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Mat_Handle (Data (1)'Address);
      Status : OpenCV.Internal.C_API.Status;
   begin
      if System.Storage_Elements.Integer_Address'Size < 64 then
         Status :=
           OpenCV.Internal.C_API.Mat_Create_External_2D_Strided
             (Rows             => 1,
              Columns          => 1,
              Depth            => OpenCV.Internal.C_API.Depth_UInt16,
              Channels         => 1,
              Data             => Data (1)'Address,
              Byte_Count       => OpenCV.Internal.C_API.C_UInt64'Last,
              Row_Stride_Bytes => OpenCV.Internal.C_API.C_UInt64'Last,
              Result           => Handle'Access);
         Assert_Rejected
           (Status, Handle, Data, "row stride exceeds native size range");
      end if;
   end Native_Stride_Narrowing_Is_Rejected_Where_Applicable;

   procedure Multiplication_Overflow_Is_Rejected_Before_Construction
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      --  Two live elements are enough. The rejected extent is never allocated.
      Data         : aliased UInt16_Array (1 .. 2) := (others => 16#55AA#);
      Handle       : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Mat_Handle (Data (1)'Address);
      Status       : OpenCV.Internal.C_API.Status;
      Native_Last  : constant OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64
          (System.Storage_Elements.Integer_Address'Last);
      --  Largest even native value: scalar-aligned, at least a 2-byte row,
      --  and Rows * Stride exceeds the native range. The division keeps this
      --  64-bit calculation itself from overflowing.
      Stride_Bytes : constant OpenCV.Internal.C_API.C_UInt64 :=
        (Native_Last / 2) * 2;
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Create_External_2D_Strided
          (Rows             => 2,
           Columns          => 1,
           Depth            => OpenCV.Internal.C_API.Depth_UInt16,
           Channels         => 1,
           Data             => Data (1)'Address,
           Byte_Count       => OpenCV.Internal.C_API.C_UInt64'Last,
           Row_Stride_Bytes => Stride_Bytes,
           Result           => Handle'Access);
      Assert_Rejected
        (Status, Handle, Data, "required capacity exceeds native size range");
   end Multiplication_Overflow_Is_Rejected_Before_Construction;

   procedure Null_Output_And_Address_Span_Wrap_Are_Rejected
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data               : aliased UInt16_Array (1 .. 2) :=
        (others => 16#55AA#);
      Handle             : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Mat_Handle (Data (1)'Address);
      Status             : OpenCV.Internal.C_API.Status;
      Near_Address_Limit : constant System.Address :=
        System.Storage_Elements.To_Address
          (System.Storage_Elements.Integer_Address'Last
           - System.Storage_Elements.Integer_Address (1));
   begin
      Status :=
        OpenCV.Internal.C_API.Mat_Create_External_2D_Strided
          (Rows             => 1,
           Columns          => 1,
           Depth            => OpenCV.Internal.C_API.Depth_UInt16,
           Channels         => 1,
           Data             => Data (1)'Address,
           Byte_Count       => 2,
           Row_Stride_Bytes => 2,
           Result           => null);
      AUnit.Assertions.Assert
        (Status = OpenCV.Internal.C_API.Error_Invalid_Argument
         and then Contains (Diagnostic, "out_mat must not be null"),
         "C ABI must reject a null output pointer before publishing a Mat");

      Status :=
        OpenCV.Internal.C_API.Mat_Create_External_2D_Strided
          (Rows             => 2,
           Columns          => 1,
           Depth            => OpenCV.Internal.C_API.Depth_UInt16,
           Channels         => 1,
           Data             => Near_Address_Limit,
           Byte_Count       => 4,
           Row_Stride_Bytes => 2,
           Result           => Handle'Access);
      Assert_Rejected
        (Status, Handle, Data, "address extent exceeds native range");
   end Null_Output_And_Address_Span_Wrap_Are_Rejected;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("External-view C ABI enforces complete stride capacity",
            Full_Stride_Capacity_Is_Enforced_With_Null_Output_On_Failure
              'Access));
      Result.Add_Test
        (Caller.Create
           ("External-view C ABI rejects an incompatible stride",
            Incompatible_Stride_Is_Rejected_Before_Capacity'Access));
      Result.Add_Test
        (Caller.Create
           ("External-view C ABI rejects non-native strides where applicable",
            Native_Stride_Narrowing_Is_Rejected_Where_Applicable'Access));
      Result.Add_Test
        (Caller.Create
           ("External-view C ABI rejects multiplication overflow",
            Multiplication_Overflow_Is_Rejected_Before_Construction'Access));
      Result.Add_Test
        (Caller.Create
           ("External-view C ABI rejects null output and address-span wrap",
            Null_Output_And_Address_Span_Wrap_Are_Rejected'Access));
      return Result'Access;
   end Suite;

end External_View_C_ABI_Tests;
