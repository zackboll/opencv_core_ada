with AUnit.Assertions;
with OpenCV;

package body Mat_Test_Support is

   function Approximately_Equal
     (Left, Right : Long_Float; Tolerance : Long_Float := 0.000_001)
      return Boolean
   is (abs (Left - Right) <= Tolerance);

   procedure Assert_Raises_OpenCV_Error
     (Attempt : not null access procedure; Message : String)
   is
      Raised : Boolean := False;
   begin
      begin
         Attempt.all;
      exception
         when OpenCV.OpenCV_Error =>
            Raised := True;
      end;

      AUnit.Assertions.Assert (Raised, Message);
   end Assert_Raises_OpenCV_Error;

end Mat_Test_Support;
