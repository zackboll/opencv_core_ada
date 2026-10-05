with Ada.Text_IO;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.UInt8_Access;

procedure Installed_Mat_Consumer is
   use OpenCV.Core;
   use type OpenCV.UInt8_Value;
   Image : Mat := Create (3, 4, (Depth => UInt8, Channels => 1));
begin
   OpenCV.Core.UInt8_Access.Set (Image, 1, 2, 37);
   declare
      Copy : constant Mat := Clone (Image);
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 1, 2, 19);
      if Rows (Copy) /= 3
        or else Columns (Copy) /= 4
        or else OpenCV.Core.UInt8_Access.Get (Copy, 1, 2) /= 37
        or else OpenCV.Core.UInt8_Access.Get (Image, 1, 2) /= 19
      then
         raise Program_Error with "installed Mat/clone contract failed";
      end if;
   end;
   Ada.Text_IO.Put_Line ("opencv_core installed Mat consumer ok");
end Installed_Mat_Consumer;
