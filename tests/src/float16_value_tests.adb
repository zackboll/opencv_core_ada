with AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Unchecked_Conversion;
with Interfaces;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;

package body Float16_Value_Tests is

   package Caller is new AUnit.Test_Caller (Mat_Test_Support.Mat_Test_Fixture);

   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type OpenCV.Float32_Value;

   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;

   function Value_Of
     (Bits : Interfaces.Unsigned_16) return OpenCV.Core.Float16_Value
   is (OpenCV.Core.Float16_From_Bits (Bits));

   function Float32_To_Bits is new
     Ada.Unchecked_Conversion
       (OpenCV.Float32_Value,
        Interfaces.Unsigned_32);
   function Bits_To_Float32 is new
     Ada.Unchecked_Conversion
       (Interfaces.Unsigned_32,
        OpenCV.Float32_Value);

   function Float32_Bits_Of
     (Value : OpenCV.Float32_Value) return Interfaces.Unsigned_32
   is
      pragma Suppress (Validity_Check);
   begin
      return Float32_To_Bits (Value);
   end Float32_Bits_Of;

   function Float32_From_Bits
     (Bits : Interfaces.Unsigned_32) return OpenCV.Float32_Value
   is
      pragma Suppress (Validity_Check);
   begin
      return Bits_To_Float32 (Bits);
   end Float32_From_Bits;

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

   procedure Assert_Float16_Bits
     (Value    : OpenCV.Core.Float16_Value;
      Expected : Interfaces.Unsigned_16;
      Message  : String) is
   begin
      AUnit.Assertions.Assert
        (OpenCV.Core.Float16_Bits (Value) = Expected, Message);
   end Assert_Float16_Bits;

   procedure Assert_Float32_Bits
     (Value    : OpenCV.Float32_Value;
      Expected : Interfaces.Unsigned_32;
      Message  : String)
   is
      pragma Suppress (Validity_Check);
   begin
      AUnit.Assertions.Assert (Float32_Bits_Of (Value) = Expected, Message);
   end Assert_Float32_Bits;

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

   procedure To_Float32_Expands_Canonical_Encodings (Test : in out Fixture) is
      pragma Unreferenced (Test);
      pragma Suppress (Validity_Check);
   begin
      Assert_Float32_Bits
        (OpenCV.Core.To_Float32 (Value_Of (16#0000#)),
         16#0000_0000#,
         "+0 must expand to binary32 +0");
      Assert_Float32_Bits
        (OpenCV.Core.To_Float32 (Value_Of (16#8000#)),
         16#8000_0000#,
         "-0 must expand to binary32 -0");
      Assert_Float32_Bits
        (OpenCV.Core.To_Float32 (Value_Of (16#0001#)),
         16#3380_0000#,
         "smallest subnormal must expand to 2^-24");
      Assert_Float32_Bits
        (OpenCV.Core.To_Float32 (Value_Of (16#03FF#)),
         16#387F_C000#,
         "largest subnormal must expand exactly");
      Assert_Float32_Bits
        (OpenCV.Core.To_Float32 (Value_Of (16#0400#)),
         16#3880_0000#,
         "smallest normal must expand to 2^-14");
      AUnit.Assertions.Assert
        (OpenCV.Core.To_Float32 (Value_Of (16#3800#)) = 0.5,
         "+0.5 must expand to Float32 0.5");
      AUnit.Assertions.Assert
        (OpenCV.Core.To_Float32 (Value_Of (16#3C00#)) = 1.0,
         "+1 must expand to Float32 1.0");
      AUnit.Assertions.Assert
        (OpenCV.Core.To_Float32 (Value_Of (16#4000#)) = 2.0,
         "+2 must expand to Float32 2.0");
      AUnit.Assertions.Assert
        (OpenCV.Core.To_Float32 (Value_Of (16#BC00#)) = -1.0,
         "-1 must expand to Float32 -1.0");
      AUnit.Assertions.Assert
        (OpenCV.Core.To_Float32 (Value_Of (16#7BFF#)) = 65_504.0,
         "maximum finite must expand to 65504");
      AUnit.Assertions.Assert
        (OpenCV.Core.To_Float32 (Value_Of (16#FBFF#)) = -65_504.0,
         "maximum-magnitude negative finite must expand to -65504");
      Assert_Float32_Bits
        (OpenCV.Core.To_Float32 (Value_Of (16#7C00#)),
         16#7F80_0000#,
         "+infinity must expand to binary32 +infinity");
      Assert_Float32_Bits
        (OpenCV.Core.To_Float32 (Value_Of (16#FC00#)),
         16#FF80_0000#,
         "-infinity must expand to binary32 -infinity");
      Assert_Float32_Bits
        (OpenCV.Core.To_Float32 (Value_Of (16#7E00#)),
         16#7FC0_0000#,
         "canonical quiet NaN payload must occupy the high fraction bits");
      Assert_Float32_Bits
        (OpenCV.Core.To_Float32 (Value_Of (16#FC01#)),
         16#FF80_2000#,
         "negative NaN payload must remain a negative NaN");
   end To_Float32_Expands_Canonical_Encodings;

   procedure To_Float16_Rounds_Representative_Values (Test : in out Fixture) is
      pragma Unreferenced (Test);
      pragma Suppress (Validity_Check);
      Positive_Infinity : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#7F80_0000#);
      Negative_Infinity : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#FF80_0000#);
      Negative_Zero     : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#8000_0000#);
   begin
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (0.0),
         16#0000#,
         "+0.0 must convert to binary16 +0");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Negative_Zero),
         16#8000#,
         "-0.0 must convert to binary16 -0");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (0.5), 16#3800#, "+0.5 must convert exactly");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (1.0), 16#3C00#, "+1.0 must convert exactly");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (-1.0), 16#BC00#, "-1.0 must convert exactly");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (2.0), 16#4000#, "+2.0 must convert exactly");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (65_504.0),
         16#7BFF#,
         "65504 must convert to the maximum finite binary16");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Positive_Infinity),
         16#7C00#,
         "+infinity must convert to binary16 +infinity");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Negative_Infinity),
         16#FC00#,
         "-infinity must convert to binary16 -infinity");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (65_536.0),
         16#7C00#,
         "values above the finite binary16 range must overflow to +infinity");
   end To_Float16_Rounds_Representative_Values;

   procedure To_Float16_Uses_Round_To_Nearest_Even (Test : in out Fixture) is
      pragma Unreferenced (Test);
      --  Midpoint between 1.0 (16#3C00#, even LSB) and the next binary16
      --  value 16#3C01#. Exact binary32 encoding of 1 + 2^-11.
      Midpoint_Even_Lower : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#3F80_1000#);
      Just_Below_Even     : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#3F80_0FFF#);
      Just_Above_Even     : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#3F80_1001#);
      --  Midpoint between 1 + 2^-10 (16#3C01#, odd LSB) and 16#3C02#.
      Midpoint_Odd_Lower  : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#3F80_3000#);
   begin
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Just_Below_Even),
         16#3C00#,
         "a value just below a midpoint rounds to the nearer encoding");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Midpoint_Even_Lower),
         16#3C00#,
         "a midpoint with even lower LSB must stay at the even encoding");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Just_Above_Even),
         16#3C01#,
         "a value just above a midpoint rounds to the nearer encoding");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Midpoint_Odd_Lower),
         16#3C02#,
         "a midpoint with odd lower LSB must round up to the even encoding");
   end To_Float16_Uses_Round_To_Nearest_Even;

   procedure To_Float16_Rounds_Subnormals_And_Underflow (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Two_To_Minus_24     : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#3380_0000#);
      Two_To_Minus_25     : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#3300_0000#);
      Just_Above_2_M_25   : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#3300_0001#);
      Largest_Subnormal32 : constant OpenCV.Float32_Value :=
        OpenCV.Core.To_Float32 (Value_Of (16#03FF#));
      Smallest_Normal32   : constant OpenCV.Float32_Value :=
        OpenCV.Core.To_Float32 (Value_Of (16#0400#));
      --  Midpoint between 16#03FF# and 16#0400#: binary32 16#387F_E000#.
      Subnormal_Midpoint  : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#387F_E000#);
   begin
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Two_To_Minus_24),
         16#0001#,
         "2^-24 must convert to the smallest positive binary16 subnormal");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Two_To_Minus_25),
         16#0000#,
         "2^-25 is a tie with even zero and must round to zero");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Just_Above_2_M_25),
         16#0001#,
         "a value just greater than 2^-25 must round up to 16#0001#");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Largest_Subnormal32),
         16#03FF#,
         "the largest binary16 subnormal must convert exactly");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Smallest_Normal32),
         16#0400#,
         "the smallest binary16 normal must convert exactly");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Subnormal_Midpoint),
         16#0400#,
         "the 16#03FF#/16#0400# midpoint must round to even 16#0400#");
   end To_Float16_Rounds_Subnormals_And_Underflow;

   procedure To_Float16_Overflows_At_Finite_Boundary (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Maximum_Finite      : constant OpenCV.Float32_Value := 65_504.0;
      --  Midpoint between 65504 and infinity is 65520. 0x7BFF is odd, so
      --  the tie rounds up and overflows to infinity.
      Just_Below_Midpoint : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#477F_EFFF#);
      Overflow_Midpoint   : constant OpenCV.Float32_Value :=
        Float32_From_Bits (16#477F_F000#);
   begin
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Maximum_Finite),
         16#7BFF#,
         "65504 must remain the maximum finite binary16");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Just_Below_Midpoint),
         16#7BFF#,
         "values just below the overflow midpoint must stay finite");
      Assert_Float16_Bits
        (OpenCV.Core.To_Float16 (Overflow_Midpoint),
         16#7C00#,
         "65520 must overflow to binary16 +infinity");
   end To_Float16_Overflows_At_Finite_Boundary;

   procedure All_Non_NaN_Encodings_Round_Trip_Through_Float32
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      pragma Suppress (Validity_Check);
      Bits   : Interfaces.Unsigned_16 := 0;
      Failed : Natural := 0;
   begin
      loop
         declare
            Original   : constant OpenCV.Core.Float16_Value := Value_Of (Bits);
            Round_Trip : constant OpenCV.Core.Float16_Value :=
              OpenCV.Core.To_Float16 (OpenCV.Core.To_Float32 (Original));
         begin
            if OpenCV.Core.Is_NaN (Original) then
               if not OpenCV.Core.Is_NaN (Round_Trip)
                 or else OpenCV.Core.Is_Negative (Round_Trip)
                         /= OpenCV.Core.Is_Negative (Original)
               then
                  Failed := Failed + 1;
               end if;
            elsif OpenCV.Core.Float16_Bits (Round_Trip) /= Bits then
               Failed := Failed + 1;
            end if;
         end;

         exit when Bits = Interfaces.Unsigned_16'Last;
         Bits := Bits + 1;
      end loop;

      AUnit.Assertions.Assert
        (Failed = 0,
         "every non-NaN binary16 encoding must round-trip through Float32");
   end All_Non_NaN_Encodings_Round_Trip_Through_Float32;

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
      Result.Add_Test
        (Caller.Create
           ("Float16 To_Float32 expands canonical encodings exactly",
            To_Float32_Expands_Canonical_Encodings'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 To_Float16 rounds representative Float32 values",
            To_Float16_Rounds_Representative_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 To_Float16 uses round-to-nearest-even",
            To_Float16_Uses_Round_To_Nearest_Even'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 To_Float16 rounds subnormals and underflow",
            To_Float16_Rounds_Subnormals_And_Underflow'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 To_Float16 overflows at the finite boundary",
            To_Float16_Overflows_At_Finite_Boundary'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 non-NaN encodings round-trip through Float32",
            All_Non_NaN_Encodings_Round_Trip_Through_Float32'Access));
      return Result'Access;
   end Suite;

end Float16_Value_Tests;
