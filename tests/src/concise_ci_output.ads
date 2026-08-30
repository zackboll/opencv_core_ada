with Ada_Containers;
with AUnit.Options;
with AUnit.Reporter;
with AUnit.Test_Filters;
with AUnit.Test_Results;
with AUnit.Time_Measure;
with AUnit.Tests;

package Concise_CI_Output is

   type Counting_Filter is new AUnit.Test_Filters.Test_Filter with private;

   overriding function Is_Active
     (Filter : Counting_Filter; Test : AUnit.Tests.Test'Class) return Boolean;

   function Count (Filter : Counting_Filter) return Natural;

   type Running_Filter (Total : Natural) is
     new AUnit.Test_Filters.Test_Filter with private;

   overriding function Is_Active
     (Filter : Running_Filter; Test : AUnit.Tests.Test'Class) return Boolean;

   type Concise_Result (Total : Natural) is
     new AUnit.Test_Results.Result with private;

   overriding procedure Start_Test
     (Result        : in out Concise_Result;
      Subtest_Count : Ada_Containers.Count_Type);

   overriding procedure Add_Failure
     (Result       : in out Concise_Result;
      Test_Name    : AUnit.Message_String;
      Routine_Name : AUnit.Message_String;
      Failure      : AUnit.Test_Results.Test_Failure;
      Elapsed      : AUnit.Time_Measure.Time);

   overriding procedure Add_Error
     (Result       : in out Concise_Result;
      Test_Name    : AUnit.Message_String;
      Routine_Name : AUnit.Message_String;
      Error        : AUnit.Test_Results.Test_Error;
      Elapsed      : AUnit.Time_Measure.Time);

   type Summary_Reporter is new AUnit.Reporter.Reporter with null record;

   overriding procedure Report
     (Engine  : Summary_Reporter;
      Result  : in out AUnit.Test_Results.Result'Class;
      Options : AUnit.Options.AUnit_Options := AUnit.Options.Default_Options);

private

   type Counting_Filter is new AUnit.Test_Filters.Test_Filter with record
      Registered : Natural := 0;
   end record;

   type Running_Filter (Total : Natural) is
     new AUnit.Test_Filters.Test_Filter with record
      Current : Natural := 0;
   end record;

   type Concise_Result (Total : Natural) is
     new AUnit.Test_Results.Result with record
      Current : Natural := 0;
   end record;

end Concise_CI_Output;