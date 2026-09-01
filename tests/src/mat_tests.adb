with Mat_Basic_Tests;
with Mat_Access_Tests;
with Mat_View_Tests;
with Mat_Conversion_Tests;
with Mat_Arithmetic_Tests;
with Mat_Channel_Tests;
with Mat_Mask_Tests;
with Mat_Reduction_Tests;
with Mat_Least_Squares_Tests;
with Linear_Program_Tests;
with Mat_Arg_Reduction_Tests;
with Mat_Range_Tests;
with Mat_Transform_Tests;
with Persistence_Tests;
with Cubic_Tests;
with Polynomial_Tests;
with K_Means_Tests;
with K_Nearest_Neighbor_Tests;
with Random_Tests;
with Linear_Discriminant_Analysis_Tests;
with Float64_Row_Access_Tests;

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
      Result.Add_Test (Mat_Least_Squares_Tests.Suite);
      Result.Add_Test (Linear_Program_Tests.Suite);
      Result.Add_Test (Mat_Arg_Reduction_Tests.Suite);
      Result.Add_Test (Mat_Range_Tests.Suite);
      Result.Add_Test (Mat_Transform_Tests.Suite);
      Result.Add_Test (Persistence_Tests.Suite);
      Result.Add_Test (Cubic_Tests.Suite);
      Result.Add_Test (Polynomial_Tests.Suite);
      Result.Add_Test (K_Means_Tests.Suite);
      Result.Add_Test (K_Nearest_Neighbor_Tests.Suite);
      Result.Add_Test (Random_Tests.Suite);
      Result.Add_Test (Linear_Discriminant_Analysis_Tests.Suite);
      Result.Add_Test (Float64_Row_Access_Tests.Suite);
      return Result'Access;
   end Suite;

end Mat_Tests;
