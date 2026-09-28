with AUnit.Test_Suites;

--  Float16 C2 / C4 exact-bit typed and zero-copy coverage. Every assertion
--  compares stored binary16 bit patterns (Float16_Bits), never numeric
--  Float16 equality, so NaN payloads and signed zeros are observable.

package Float16_Vector_Tests is
   function Suite return AUnit.Test_Suites.Access_Test_Suite;
end Float16_Vector_Tests;
