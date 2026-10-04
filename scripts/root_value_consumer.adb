with Ada.Text_IO;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.UInt8_Access;

--  Pinned-source consumer fixture for opencv_core release candidates.
--  This is not an index-resolution test.

procedure Root_Value_Consumer is
   use type OpenCV.Point;
   use type OpenCV.Point_Coordinate;
   use type OpenCV.Point_3D;
   use type OpenCV.Point_3D_Array;
   use type OpenCV.Float32_Point_3D;
   use type OpenCV.Float32_Point_3D_Array;
   use type OpenCV.Float32_Value;
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
   P          : OpenCV.Point_3D := (X => 1, Y => 2, Z => 3);
   F          : OpenCV.Float32_Point_3D := (X => 1.25, Y => -2.5, Z => 3.75);
   Points     : constant OpenCV.Point_3D_Array (7 .. 8) := (others => P);
   Floats     : constant OpenCV.Float32_Point_3D_Array (13 .. 14) :=
     (others => F);
   Empty      : constant OpenCV.Point_3D_Array (1 .. 0) := (others => <>);
   Empty_F    : constant OpenCV.Float32_Point_3D_Array (1 .. 0) :=
     (others => <>);
   Zero       : constant OpenCV.Point_3D_Array (0 .. 1) := Points;
   Zero_F     : constant OpenCV.Float32_Point_3D_Array (0 .. 1) := Floats;
begin
   if P /= (X => 1, Y => 2, Z => 3)
     or else F /= (X => 1.25, Y => -2.5, Z => 3.75)
     or else Points'First /= 7
     or else Points (8) /= P
     or else Floats'First /= 13
     or else Floats (14) /= F
     or else Empty'Length /= 0
     or else Empty_F'Length /= 0
     or else Zero'First /= 0
     or else Zero_F'First /= 0
     or else Zero /= Points
     or else Zero_F /= Floats
   then
      raise Program_Error with "root 3-D point values or bounds failed";
   end if;

   P := (X => -1, Y => -2, Z => -3);
   F := (X => -1.25, Y => 2.5, Z => -3.75);
   if Points (7) = P
     or else Floats (13) = F
     or else Points (7) /= (X => 1, Y => 2, Z => 3)
     or else Floats (13) /= (X => 1.25, Y => -2.5, Z => 3.75)
   then
      raise Program_Error with "root 3-D point copies are not independent";
   end if;

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
