with Ada.Text_IO;
with Interfaces.C;
with OpenCV.Core;

procedure Installed_Mixed_Consumer is
   use type Interfaces.C.int;
   function Application_OpenCV_Check return Interfaces.C.int
   with Import, Convention => C, External_Name => "application_opencv_check";
   Image : constant OpenCV.Core.Mat :=
     OpenCV.Core.Create (2, 3, (Depth => OpenCV.Core.UInt8, Channels => 1));
begin
   if Image.Rows /= 2 or else Application_OpenCV_Check /= 6 then
      raise Program_Error with "mixed Ada/C++ OpenCV integration failed";
   end if;
   Ada.Text_IO.Put_Line ("opencv_core installed mixed consumer ok");
end Installed_Mixed_Consumer;
