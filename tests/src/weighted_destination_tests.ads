with AUnit.Test_Suites;

package Weighted_Destination_Tests is
   function Suite return AUnit.Test_Suites.Access_Test_Suite;
private
   type Operation_Kind is (Weighted, Scaled);
end Weighted_Destination_Tests;
