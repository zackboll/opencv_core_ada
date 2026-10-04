with AUnit.Test_Suites;

package Min_Max_Destination_Tests is
   function Suite return AUnit.Test_Suites.Access_Test_Suite;
private
   type Operation_Kind is (Minimum_Operation, Maximum_Operation);
end Min_Max_Destination_Tests;
