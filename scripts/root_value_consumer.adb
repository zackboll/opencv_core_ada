with Ada.Text_IO;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.UInt8_Access;

--  Pinned-source consumer fixture for opencv_core 0.2.0.
--  This is not an index-resolution test.

procedure Root_Value_Consumer is
   use type OpenCV.Point;
   use type OpenCV.Size;
   use type OpenCV.Rect;
   use type OpenCV.Scalar;
   use type OpenCV.Border_Kind;
   use type OpenCV.Size_Coordinate;
   use type OpenCV.UInt8_Value;

   Dimensions : constant OpenCV.Size := (Width => 4, Height => 3);
   Area       : constant OpenCV.Rect :=
     (X => 1, Y => 1, Width => 2, Height => 1);
   Origin     : constant OpenCV.Point := (X => 1, Y => 1);
   Fill       : constant OpenCV.Scalar := OpenCV.Make_Scalar (9.0);
   Image      : OpenCV.Core.Mat :=
     OpenCV.Core.Create
       (Dimensions   => Dimensions,
        Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
   View       : OpenCV.Core.Mat;
   Pixel      : OpenCV.UInt8_Value;
   Donor      : OpenCV.Core.Border_Interpolation_Result;
begin
   if Dimensions /= Image.Dimensions then
      raise Program_Error with "root Size equality failed";
   end if;

   Image.Set_To (Fill);
   View := Image.Region (Area);
   Pixel := OpenCV.Core.UInt8_Access.Get (View, 0, 0);

   if Origin /= (X => Area.X, Y => Area.Y) then
      raise Program_Error with "root Point equality failed";
   end if;

   if Area /= (X => 1, Y => 1, Width => 2, Height => 1) then
      raise Program_Error with "root Rect equality failed";
   end if;

   if Fill /= OpenCV.Make_Scalar (9.0) then
      raise Program_Error with "root Scalar equality failed";
   end if;

   if Pixel /= 9 then
      raise Program_Error with "Make_Scalar/Region did not fill the view";
   end if;

   Donor :=
     OpenCV.Core.Border_Interpolate
       (Position => 1, Length => 3, Kind => OpenCV.Reflect_101);
   if Donor.Uses_Constant or else Donor.Index /= 1 then
      raise Program_Error with "root Border_Kind was not accepted";
   end if;

   Ada.Text_IO.Put_Line ("root value consumer ok");
end Root_Value_Consumer;
