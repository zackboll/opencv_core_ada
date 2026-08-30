with Ada.Command_Line;
with Ada.Environment_Variables;
with Ada.Text_IO;
with AUnit;
with AUnit.Options;
with AUnit.Reporter.Text;
with AUnit.Run;
with AUnit.Test_Results;
with AUnit.Test_Suites;
with Mat_Tests;
with Concise_CI_Output;

procedure Tests is

   use type AUnit.Status;

   Suite : constant AUnit.Test_Suites.Access_Test_Suite := Mat_Tests.Suite;

   function Stored_Suite return AUnit.Test_Suites.Access_Test_Suite is (Suite);

   function Run is new AUnit.Run.Test_Runner_With_Status (Stored_Suite);

   procedure Run_With_Results is new AUnit.Run.Test_Runner_With_Results
     (Stored_Suite);

   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Status   : AUnit.Status;
begin
   if Ada.Environment_Variables.Exists ("OPENCV_CORE_CI") then
      declare
         Count_Filter : aliased Concise_CI_Output.Counting_Filter;
         Count_Result : AUnit.Test_Results.Result;
         Count_Status : AUnit.Status;
         Count_Options : AUnit.Options.AUnit_Options :=
           AUnit.Options.Default_Options;
      begin
         Count_Options.Filter := Count_Filter'Unchecked_Access;
         AUnit.Test_Suites.Run
           (Suite, Count_Options, Count_Result, Count_Status);

         declare
            Total      : constant Natural :=
              Concise_CI_Output.Count (Count_Filter);
            Run_Filter : aliased Concise_CI_Output.Running_Filter (Total);
            Results    : Concise_CI_Output.Concise_Result (Total);
            Summary    : Concise_CI_Output.Summary_Reporter;
            Options    : AUnit.Options.AUnit_Options :=
              AUnit.Options.Default_Options;
         begin
            Ada.Text_IO.Put_Line ("OpenCV Core Ada CI test run");
            Ada.Text_IO.Put_Line ("Registered tests:" & Natural'Image (Total));
            Ada.Text_IO.New_Line;
            Ada.Text_IO.Flush;

            Options.Report_Successes := False;
            Options.Filter := Run_Filter'Unchecked_Access;
            Run_With_Results (Summary, Results, Options);

            if Results.Successful then
               Status := AUnit.Success;
            else
               Status := AUnit.Failure;
            end if;
         end;
      end;
   else
      Status := Run (Reporter);
   end if;

   if Status = AUnit.Failure then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
