with Ada.Text_IO;
with Interfaces.C;
with OpenCV;
with OpenCV.Core;

procedure Runtime_Identity_Controls is
   procedure Fault_Mode (Mode : Interfaces.C.int)
   with
     Import,
     Convention    => C,
     External_Name => "runtime_identity_fault_mode";
   Version : constant String := OpenCV.Core.Native_Version_String;
   Build   : constant String := OpenCV.Core.Native_Build_Information;
begin
   for Build_Query in Boolean loop
      for Mode in Interfaces.C.int range 1 .. 7 loop
         Fault_Mode (Mode);
         begin
            declare
               Invalid : constant String :=
                 (if Build_Query
                  then OpenCV.Core.Native_Build_Information
                  else OpenCV.Core.Native_Version_String);
            begin
               raise Program_Error
                 with "partial/invalid text accepted: " & Invalid;
            end;
         exception
            when OpenCV.OpenCV_Error =>
               null;
         end;
      end loop;
   end loop;
   Fault_Mode (0);
   if Version /= OpenCV.Core.Native_Version_String
     or else Build /= OpenCV.Core.Native_Build_Information
   then
      raise Program_Error with "saved text changed after failed queries";
   end if;
   Ada.Text_IO.Put_Line
     ("PASS Ada runtime identity count/overflow/failure controls");
end Runtime_Identity_Controls;
