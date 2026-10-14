with Ada.Text_IO;
with Interfaces.C;
with OpenCV;
with OpenCV.Core;

procedure K_Means_Attempts_Controls is
   use OpenCV;
   use OpenCV.Core;
   use type Interfaces.C.unsigned;

   procedure Expect (Value : Interfaces.C.int)
   with Import, Convention => C, External_Name => "k_means_expect_attempts";
   function Calls return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "k_means_attempt_calls";

   Samples : Mat := Create (4, 2, (Float32, 1));
   Labels  : Mat := Create (4, 1, (Int32, 1));
   Result  : K_Means_Result;

   procedure Check (Expected_Calls : Interfaces.C.unsigned) is
   begin
      if Calls /= Expected_Calls
        or else Result.Compactness /= 0.0
        or else Result.Labels.Rows /= 4
        or else Result.Labels.Columns /= 1
        or else Result.Labels.Depth /= Int32
        or else Result.Centers.Rows /= 1
        or else Result.Centers.Columns /= 2
        or else Result.Centers.Depth /= Float32
        or else Result.Centers.Sum.Component_0 /= 8.0
      then
         raise Program_Error with "K_Means forwarding or result mismatch";
      end if;
   end Check;
begin
   Samples.Set_To (Make_Scalar (4.0));
   Labels.Set_To (Make_Scalar (0.0));
   Expect (3);
   Result := K_Means (Samples, 1);
   Check (1);
   Expect (2);
   Result := K_Means (Samples, 1, Attempts => 2);
   Check (2);
   Expect (1);
   Result := K_Means (Samples, 1, Labels);
   Check (3);
   Expect (4);
   Result := K_Means (Samples, 1, Labels, Attempts => 4);
   Check (4);
   Samples.Set_To (Make_Scalar (99.0));
   Labels.Set_To (Make_Scalar (7.0));
   Check (4);
   Ada.Text_IO.Put_Line
     ("PASS both K_Means overloads: default/explicit native Attempts;"
      & " numerical results and independent outputs; four intercepted calls");
end K_Means_Attempts_Controls;
