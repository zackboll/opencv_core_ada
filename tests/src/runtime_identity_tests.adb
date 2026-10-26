with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support; use Mat_Test_Support;
with OpenCV;
with OpenCV.Core;      use OpenCV.Core;
with Interfaces;
with Interfaces.C;
with System;

package body Runtime_Identity_Tests is
   use type Interfaces.C.int;
   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Matches
     (Build  : Interfaces.C.int;
      Text   : System.Address;
      Length : Interfaces.Unsigned_64) return Interfaces.C.int
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_runtime_text_matches";

   procedure Native_Parity (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Version : constant String := Native_Version_String;
      Build   : constant String := Native_Build_Information;
      Lines   : Natural := 0;
   begin
      Assert (Version'Length > 0, "nonempty linked native version");
      Assert (Build'Length > 0, "nonempty linked native build information");
      Assert
        (Matches (0, Version'Address, Version'Length) = 1,
         "version matches independent direct-native runtime query");
      Assert
        (Matches (1, Build'Address, Build'Length) = 1,
         "entire build payload matches direct native bytes and length");
      for Byte of Build loop
         if Byte = ASCII.LF then
            Lines := Lines + 1;
         end if;
      end loop;
      Assert (Lines > 1, "multiline build content is not truncated");
   end Native_Parity;

   procedure Ownership (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Version : constant String := Native_Version_String;
      Build   : constant String := Native_Build_Information;
   begin
      for Iteration in 1 .. 25 loop
         declare
            Next_Build   : constant String := Native_Build_Information;
            Next_Version : String := Native_Version_String;
            Image        : Mat := Create (2, 3, (UInt8, 1));
         begin
            Image.Set_To (OpenCV.Make_Scalar (Long_Float (Iteration)));
            Assert
              (Next_Version = Version and then Next_Build = Build,
               "repeated/interleaved query contents");
            Next_Version (Next_Version'First) := '#';
            Assert
              (Version = Native_Version_String,
               "mutating a returned String cannot alter saved/native text");
         end;
         Assert
           (Version = Native_Version_String
            and then Build = Native_Build_Information,
            "saved Strings survive native operations and finalization");
      end loop;
      Assert
        (Matches (1, Build'Address, Build'Length) = 1,
         "saved build bytes remain independently owned");
   end Ownership;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Runtime identity: direct native parity", Native_Parity'Access));
      Result.Add_Test
        (Caller.Create
           ("Runtime identity: independent Ada ownership", Ownership'Access));
      return Result'Access;
   end Suite;
end Runtime_Identity_Tests;
