with Mat_Basic_Tests;
with Mat_Access_Tests;
with Mat_View_Tests;
with Mat_Conversion_Tests;
with Mat_Arithmetic_Tests;
with Mat_Channel_Tests;
with Mat_Mask_Tests;
with Mat_Reduction_Tests;
with Mat_Range_Tests;
with Mat_Transform_Tests;

package body Mat_Tests is

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test (Mat_Basic_Tests.Suite);
      Result.Add_Test (Mat_Access_Tests.Suite);
      Result.Add_Test (Mat_View_Tests.Suite);
      Result.Add_Test (Mat_Conversion_Tests.Suite);
      Result.Add_Test (Mat_Arithmetic_Tests.Suite);
      Result.Add_Test (Mat_Channel_Tests.Suite);
      Result.Add_Test (Mat_Mask_Tests.Suite);
      Result.Add_Test (Mat_Reduction_Tests.Suite);
      Result.Add_Test (Mat_Range_Tests.Suite);
      Result.Add_Test (Mat_Transform_Tests.Suite);
      return Result'Access;
   end Suite;

end Mat_Tests;
