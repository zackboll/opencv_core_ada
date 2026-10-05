with AUnit.Test_Suites;

package Bitwise_Destination_Tests is
   type Bitwise_Operation is
     (And_Operation, Or_Operation, Xor_Operation, Not_Operation);
   function Suite return AUnit.Test_Suites.Access_Test_Suite;
end Bitwise_Destination_Tests;
