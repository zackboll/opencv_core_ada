with Ada.Command_Line;
with Ada.Text_IO;
with AUnit;
with AUnit.Reporter.Text;
with AUnit.Run;
with AUnit.Test_Suites;
with Interfaces.C;
with Mat_Tests;

--  Execute the authoritative all-family public-API suite with the same real
--  constructor and lease interception as the focused layout controls.

procedure All_Family_Controls is
   use type AUnit.Status;
   use type Interfaces.C.unsigned;
   function Suite return AUnit.Test_Suites.Access_Test_Suite
   renames Mat_Tests.Suite;
   function Run is new AUnit.Run.Test_Runner_With_Status (Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
   function Constructors
     (Boundary : Interfaces.C.unsigned) return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3b_constructor_count";
   function Live_Views return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3c_live_views";
   function Leases return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3g_lease_count";
   function Live_Leases return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3h_live_leases";
   function Destroyed_Leases return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3h_destroyed_leases";
begin
   if Run (Reporter) /= AUnit.Success then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;
   for Boundary in Interfaces.C.unsigned range 0 .. 3 loop
      if Constructors (Boundary) = 0 then
         raise Program_Error
           with "native constructor interception not exercised";
      end if;
   end loop;
   if Leases = 0 or else Leases /= Destroyed_Leases then
      raise Program_Error with "native lease interception is unbalanced";
   end if;
   if Live_Views /= 0 or else Live_Leases /= 0 then
      raise Program_Error
        with "public API suite leaked external view or lease";
   end if;
   Ada.Text_IO.Put_Line
     ("PASS all-family public API suite with live constructor/lease controls");
end All_Family_Controls;
