with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Internal.C_API;
with System.Storage_Elements;

package body External_View_C_ABI_Tests is

   use type OpenCV.Internal.C_API.Mat_Handle;
   use type OpenCV.Internal.C_API.Status;
   use type Interfaces.Unsigned_16;
   use type System.Storage_Elements.Integer_Address;

   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   type UInt16_Array is
     array (Natural range <>) of aliased Interfaces.Unsigned_16
   with Convention => C;

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
      AUnit.Assertions.Assert
        (Status = OpenCV.Internal.C_API.Error_Invalid_Argument
         and then Handle = OpenCV.Internal.C_API.Null_Mat_Handle,
         "C ABI must reject logical-end-only capacity and clear output"
         & " handle");
      AUnit.Assertions.Assert
        (Data (1) = 16#55AA# and then Data (16) = 16#55AA#,
         "Rejected C ABI construction must not mutate live backing storage");
   end Full_Stride_Capacity_Is_Enforced_With_Null_Output_On_Failure;

   procedure Arithmetic_And_Output_Pointer_Boundaries_Are_Rejected
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data               : aliased UInt16_Array (1 .. 1) := (others => 0);
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
          (Rows             => OpenCV.Internal.C_API.C_Int32'Last,
           Columns          => 1,
           Depth            => OpenCV.Internal.C_API.Depth_UInt16,
           Channels         => 1,
           Data             => Data (1)'Address,
           Byte_Count       => OpenCV.Internal.C_API.C_UInt64'Last,
           Row_Stride_Bytes => OpenCV.Internal.C_API.C_UInt64'Last,
           Result           => Handle'Access);
      AUnit.Assertions.Assert
        (Status = OpenCV.Internal.C_API.Error_Invalid_Argument
         and then Handle = OpenCV.Internal.C_API.Null_Mat_Handle,
         "C ABI must reject non-native stride arithmetic before"
         & " construction");

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
        (Status = OpenCV.Internal.C_API.Error_Invalid_Argument,
         "C ABI must reject a null output pointer before publishing a Mat");

      Handle := OpenCV.Internal.C_API.Mat_Handle (Data (1)'Address);
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
      AUnit.Assertions.Assert
        (Status = OpenCV.Internal.C_API.Error_Invalid_Argument
         and then Handle = OpenCV.Internal.C_API.Null_Mat_Handle,
         "C ABI must reject address-span wrap before dereferencing data");
   end Arithmetic_And_Output_Pointer_Boundaries_Are_Rejected;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("External-view C ABI enforces complete stride capacity",
            Full_Stride_Capacity_Is_Enforced_With_Null_Output_On_Failure
              'Access));
      Result.Add_Test
        (Caller.Create
           ("External-view C ABI rejects arithmetic and output boundaries",
            Arithmetic_And_Output_Pointer_Boundaries_Are_Rejected'Access));
      return Result'Access;
   end Suite;

end External_View_C_ABI_Tests;
