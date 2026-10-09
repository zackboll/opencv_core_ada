with AUnit.Test_Suites;

package Unary_Math_Destination_Tests is
   function Suite return AUnit.Test_Suites.Access_Test_Suite;
private
   type Operation is (Square_Root, Exponential, Logarithm, Power_Operation);
end Unary_Math_Destination_Tests;
