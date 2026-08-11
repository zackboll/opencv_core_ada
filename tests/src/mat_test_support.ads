with AUnit.Test_Fixtures;

package Mat_Test_Support is

   type Mat_Test_Fixture is new AUnit.Test_Fixtures.Test_Fixture
   with null record;

   function Approximately_Equal
     (Left, Right : Long_Float; Tolerance : Long_Float := 0.000_001)
      return Boolean;

   procedure Assert_Raises_OpenCV_Error
     (Attempt : not null access procedure; Message : String);

end Mat_Test_Support;
