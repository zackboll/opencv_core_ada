with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;

package body Float16_Value_Tests is

   package Caller is new AUnit.Test_Caller (Mat_Test_Support.Mat_Test_Fixture);

   use type Interfaces.Unsigned_16;

   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;

   function Value_Of
     (Bits : Interfaces.Unsigned_16) return OpenCV.Core.Float16_Value
   is (OpenCV.Core.Float16_From_Bits (Bits));

   procedure Assert_Bits (Bits : Interfaces.Unsigned_16; Message : String) is
      Value : constant OpenCV.Core.Float16_Value := Value_Of (Bits);
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Float16_Bits (Value) = Bits, Message);
   end Assert_Bits;

   procedure Assert_Class
     (Bits      : Interfaces.Unsigned_16;
      Zero      : Boolean;
      Subnormal : Boolean;
      Finite    : Boolean;
      Infinite  : Boolean;
      NaN       : Boolean;
      Negative  : Boolean;
      Message   : String)
   is
      Value : constant OpenCV.Core.Float16_Value := Value_Of (Bits);
   begin
      Assert_Bits
        (Bits, Message & ": bits must round-trip without normalization");
      AUnit.Assertions.Assert
        (OpenCV.Core.Is_Zero (Value) = Zero
         and then OpenCV.Core.Is_Subnormal (Value) = Subnormal
         and then OpenCV.Core.Is_Finite (Value) = Finite
         and then OpenCV.Core.Is_Infinite (Value) = Infinite
         and then OpenCV.Core.Is_NaN (Value) = NaN
         and then OpenCV.Core.Is_Negative (Value) = Negative,
         Message);
   end Assert_Class;

   procedure Canonical_Encodings_Preserve_Bits_And_Classification
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Float16_Value'Size = 16,
         "Float16_Value must occupy exactly 16 bits");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float16_Value'Max_Size_In_Storage_Elements = 2,
         "Float16_Value component storage must be 2 bytes");

      Assert_Class
        (16#0000#,
         Zero      => True,
         Subnormal => False,
         Finite    => True,
         Infinite  => False,
         NaN       => False,
         Negative  => False,
         Message   => "+0 must be a nonnegative finite zero");
      Assert_Class
        (16#8000#,
         Zero      => True,
         Subnormal => False,
         Finite    => True,
         Infinite  => False,
         NaN       => False,
         Negative  => True,
         Message   => "-0 must retain the sign bit");
      Assert_Class
        (16#0001#,
         Zero      => False,
         Subnormal => True,
         Finite    => True,
         Infinite  => False,
         NaN       => False,
         Negative  => False,
         Message   => "smallest positive subnormal must stay subnormal");
      Assert_Class
        (16#03FF#,
         Zero      => False,
         Subnormal => True,
         Finite    => True,
         Infinite  => False,
         NaN       => False,
         Negative  => False,
         Message   => "largest positive subnormal must stay subnormal");
      Assert_Class
        (16#0400#,
         Zero      => False,
         Subnormal => False,
         Finite    => True,
         Infinite  => False,
         NaN       => False,
         Negative  => False,
         Message   => "smallest positive normal must be finite");
      Assert_Class
        (16#3C00#,
         Zero      => False,
         Subnormal => False,
         Finite    => True,
         Infinite  => False,
         NaN       => False,
         Negative  => False,
         Message   => "+1.0 must be a positive finite normal");
      Assert_Class
        (16#BC00#,
         Zero      => False,
         Subnormal => False,
         Finite    => True,
         Infinite  => False,
         NaN       => False,
         Negative  => True,
         Message   => "-1.0 must be a negative finite normal");
      Assert_Class
        (16#7BFF#,
         Zero      => False,
         Subnormal => False,
         Finite    => True,
         Infinite  => False,
         NaN       => False,
         Negative  => False,
         Message   => "maximum positive finite must stay finite");
      Assert_Class
        (16#FBFF#,
         Zero      => False,
         Subnormal => False,
         Finite    => True,
         Infinite  => False,
         NaN       => False,
         Negative  => True,
         Message   => "maximum-magnitude negative finite must stay finite");
      Assert_Class
        (16#7C00#,
         Zero      => False,
         Subnormal => False,
         Finite    => False,
         Infinite  => True,
         NaN       => False,
         Negative  => False,
         Message   => "+infinity must be infinite and non-NaN");
      Assert_Class
        (16#FC00#,
         Zero      => False,
         Subnormal => False,
         Finite    => False,
         Infinite  => True,
         NaN       => False,
         Negative  => True,
         Message   => "-infinity must retain the sign bit");
      Assert_Class
        (16#7E00#,
         Zero      => False,
         Subnormal => False,
         Finite    => False,
         Infinite  => False,
         NaN       => True,
         Negative  => False,
         Message   => "canonical quiet NaN must keep its payload");
      Assert_Class
        (16#7C01#,
         Zero      => False,
         Subnormal => False,
         Finite    => False,
         Infinite  => False,
         NaN       => True,
         Negative  => False,
         Message   => "positive NaN payload must not be canonicalized");
      Assert_Class
        (16#FC01#,
         Zero      => False,
         Subnormal => False,
         Finite    => False,
         Infinite  => False,
         NaN       => True,
         Negative  => True,
         Message   => "negative NaN payload must retain the sign bit");
   end Canonical_Encodings_Preserve_Bits_And_Classification;

   procedure All_65536_Encodings_Round_Trip (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Bits   : Interfaces.Unsigned_16 := 0;
      Failed : Natural := 0;
   begin
      loop
         if OpenCV.Core.Float16_Bits (Value_Of (Bits)) /= Bits then
            Failed := Failed + 1;
         end if;
         exit when Bits = Interfaces.Unsigned_16'Last;
         Bits := Bits + 1;
      end loop;

      AUnit.Assertions.Assert
        (Failed = 0,
         "every binary16 encoding must round-trip without normalization");
   end All_65536_Encodings_Round_Trip;

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float16 canonical encodings preserve bits and classification",
            Canonical_Encodings_Preserve_Bits_And_Classification'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 preserves all 65536 binary16 encodings",
            All_65536_Encodings_Round_Trip'Access));
      return Result'Access;
   end Suite;

end Float16_Value_Tests;
