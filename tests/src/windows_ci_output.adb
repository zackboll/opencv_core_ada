with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with AUnit.Simple_Test_Cases;

package body Windows_CI_Output is

   use type AUnit.Message_String;

   function Image (Value : Natural) return String is
     (Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both));

   function Full_Name
     (Test_Name, Routine_Name : AUnit.Message_String) return String
   is
   begin
      if Routine_Name = null then
         return Test_Name.all;
      else
         return Test_Name.all & " : " & Routine_Name.all;
      end if;
   end Full_Name;

   function Full_Name (Test : AUnit.Tests.Test'Class) return String is
      use AUnit.Simple_Test_Cases;
      Current_Test : Test_Case'Class renames Test_Case'Class (Test);
   begin
      return Full_Name (Name (Current_Test), Routine_Name (Current_Test));
   end Full_Name;

   overriding function Is_Active
     (Filter : Counting_Filter; Test : AUnit.Tests.Test'Class) return Boolean
   is
      pragma Unreferenced (Test);
      Mutable_Filter : Counting_Filter renames Filter'Unrestricted_Access.all;
   begin
      Mutable_Filter.Registered := Mutable_Filter.Registered + 1;
      return False;
   end Is_Active;

   function Count (Filter : Counting_Filter) return Natural is
     (Filter.Registered);

   overriding function Is_Active
     (Filter : Running_Filter; Test : AUnit.Tests.Test'Class) return Boolean
   is
      Mutable_Filter : Running_Filter renames Filter'Unrestricted_Access.all;
   begin
      Mutable_Filter.Current := Mutable_Filter.Current + 1;
      Ada.Text_IO.Put_Line
        ("RUN " & Image (Mutable_Filter.Current) & "/" & Image (Filter.Total)
         & ": " & Full_Name (Test));
      Ada.Text_IO.Flush;
      return True;
   end Is_Active;

   overriding procedure Start_Test
     (Result        : in out Concise_Result;
      Subtest_Count : Ada_Containers.Count_Type) is
   begin
      Result.Current := Result.Current + Natural (Subtest_Count);
      AUnit.Test_Results.Start_Test
        (AUnit.Test_Results.Result (Result), Subtest_Count);
   end Start_Test;

   overriding procedure Add_Failure
     (Result       : in out Concise_Result;
      Test_Name    : AUnit.Message_String;
      Routine_Name : AUnit.Message_String;
      Failure      : AUnit.Test_Results.Test_Failure;
      Elapsed      : AUnit.Time_Measure.Time) is
   begin
      Ada.Text_IO.Put_Line
        ("FAIL " & Image (Result.Current) & "/" & Image (Result.Total) & ": "
         & Full_Name (Test_Name, Routine_Name));
      Ada.Text_IO.Put_Line (Failure.Message.all);
      Ada.Text_IO.Put_Line
        ("at " & Failure.Source_Name.all & ":" & Image (Failure.Line));
      Ada.Text_IO.Flush;
      AUnit.Test_Results.Add_Failure
        (AUnit.Test_Results.Result (Result), Test_Name, Routine_Name, Failure,
         Elapsed);
   end Add_Failure;

   overriding procedure Add_Error
     (Result       : in out Concise_Result;
      Test_Name    : AUnit.Message_String;
      Routine_Name : AUnit.Message_String;
      Error        : AUnit.Test_Results.Test_Error;
      Elapsed      : AUnit.Time_Measure.Time) is
   begin
      Ada.Text_IO.Put_Line
        ("ERROR " & Image (Result.Current) & "/" & Image (Result.Total) & ": "
         & Full_Name (Test_Name, Routine_Name));
      Ada.Text_IO.Put_Line (Error.Exception_Name.all);
      if Error.Exception_Message /= null then
         Ada.Text_IO.Put_Line (Error.Exception_Message.all);
      end if;
      if Error.Traceback /= null then
         Ada.Text_IO.Put_Line (Error.Traceback.all);
      end if;
      Ada.Text_IO.Flush;
      AUnit.Test_Results.Add_Error
        (AUnit.Test_Results.Result (Result), Test_Name, Routine_Name, Error,
         Elapsed);
   end Add_Error;

   overriding procedure Report
     (Engine  : Summary_Reporter;
      Result  : in out AUnit.Test_Results.Result'Class;
      Options : AUnit.Options.AUnit_Options := AUnit.Options.Default_Options)
   is
      pragma Unreferenced (Engine, Options);
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line
        ("Total Tests Run:   " & Image (Natural (Result.Test_Count)));
      Ada.Text_IO.Put_Line
        ("Successful Tests:  " & Image (Natural (Result.Success_Count)));
      Ada.Text_IO.Put_Line
        ("Failed Assertions: " & Image (Natural (Result.Failure_Count)));
      Ada.Text_IO.Put_Line
        ("Unexpected Errors: " & Image (Natural (Result.Error_Count)));
   end Report;

end Windows_CI_Output;