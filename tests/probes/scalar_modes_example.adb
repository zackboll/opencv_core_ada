with OpenCV;      use OpenCV;
with OpenCV.Core; use OpenCV.Core;
with OpenCV.Core.UInt8_Access;

procedure Scalar_Modes_Example is
   use type UInt8_Value;
   Image         : Mat := Create (2, 3, (UInt8, 1));
   Shifted, Mask : Mat;
begin
   Image.Set_To (Make_Scalar (8.0));
   Add (Image, Make_Scalar (2.0), Shifted);
   Compare (Shifted, 9.5, Greater_Than, Mask);
   if OpenCV.Core.UInt8_Access.Get (Mask, 0, 0) /= 255 then
      raise Program_Error with "unexpected scalar comparison";
   end if;
end Scalar_Modes_Example;
