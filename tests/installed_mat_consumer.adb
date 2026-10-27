with Ada.Text_IO;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.UInt8_Access;

procedure Installed_Mat_Consumer is
   use OpenCV.Core;
   use type OpenCV.UInt8_Value;
   Image          : Mat := Create (3, 4, (Depth => UInt8, Channels => 1));
   Survivor       : Mat;
   Native_Version : constant String := Native_Version_String;
   Native_Build   : constant String := Native_Build_Information;
begin
   if Image.Is_Empty or else Image.Depth /= UInt8 or else Image.Channels /= 1
   then
      raise Program_Error with "installed Mat metadata failed";
   end if;
   OpenCV.Core.UInt8_Access.Set (Image, 1, 2, 37);
   declare
      Copy   : constant Mat := Clone (Image);
      Shared : constant Mat := Image;
      View   : Mat := Image.Region ((X => 1, Y => 0, Width => 2, Height => 2));
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 1, 2, 19);
      if Rows (Copy) /= 3
        or else Columns (Copy) /= 4
        or else OpenCV.Core.UInt8_Access.Get (Copy, 1, 2) /= 37
        or else OpenCV.Core.UInt8_Access.Get (Image, 1, 2) /= 19
      then
         raise Program_Error with "installed Mat/clone contract failed";
      end if;
      if OpenCV.Core.UInt8_Access.Get (Shared, 1, 2) /= 19 then
         raise Program_Error with "assignment must share storage";
      end if;
      OpenCV.Core.UInt8_Access.Set (View, 1, 1, 53);
      if View.Rows /= 2
        or else View.Columns /= 2
        or else OpenCV.Core.UInt8_Access.Get (Image, 1, 2) /= 53
        or else OpenCV.Core.UInt8_Access.Get (Copy, 1, 2) /= 37
      then
         raise Program_Error with "region sharing/clone independence failed";
      end if;
      Survivor := View;
   end;
   Image := Create (1, 1, (Depth => UInt8, Channels => 1));
   if OpenCV.Core.UInt8_Access.Get (Survivor, 1, 1) /= 53 then
      raise Program_Error with "storage lost after other headers finalized";
   end if;
   begin
      declare
         Invalid : constant Mat :=
           Image.Region ((X => 1, Y => 0, Width => 1, Height => 1));
      begin
         raise Program_Error
           with "invalid region accepted" & Invalid.Rows'Image;
      end;
   exception
      when OpenCV.OpenCV_Error =>
         null;
   end;
   --  The default empty source reaches cv::LUT and tests native translation.
   begin
      declare
         Empty   : Mat;
         Table   : constant Mat :=
           Create (1, 256, (Depth => UInt8, Channels => 1));
         Invalid : constant Mat := Empty.Apply_LUT (Table);
      begin
         raise Program_Error
           with "native failure accepted" & Invalid.Rows'Image;
      end;
   exception
      when OpenCV.OpenCV_Error =>
         null;
   end;
   --  Repeated scopes exercise controlled cleanup, including reassignment.
   for Iteration in 1 .. 100 loop
      declare
         Temporary : Mat := Survivor.Clone;
      begin
         Temporary := Image;
         if Temporary.Rows /= 1 then
            raise Program_Error with "reassignment failed" & Iteration'Image;
         end if;
      end;
   end loop;
   if Native_Version'Length = 0 or else Native_Build'Length = 0 then
      raise Program_Error with "installed native runtime identity is empty";
   end if;
   for Iteration in 1 .. 20 loop
      declare
         Build     : constant String := Native_Build_Information;
         Version   : String := Native_Version_String;
         Temporary : Mat := Create (1, 1, (UInt8, 1));
      begin
         Temporary.Set_To (OpenCV.Make_Scalar (Long_Float (Iteration)));
         if Version /= Native_Version or else Build /= Native_Build then
            raise Program_Error with "installed runtime identity changed";
         end if;
         Version (Version'First) := '#';
      end;
      if Native_Version_String /= Native_Version
        or else Native_Build_Information /= Native_Build
      then
         raise Program_Error with "installed runtime String ownership failed";
      end if;
   end loop;
   --  CORE-FIN-02: compile and execute new operations using only installed
   --  projects/sources, including after relocating the installation prefix.
   declare
      Left  : Mat := Create (1, 3, (UInt8, 1));
      Right : Mat := Create (1, 3, (UInt8, 1));
      Mask  : Mat := Create (1, 3, (UInt8, 1));
   begin
      Left.Set_To (OpenCV.Make_Scalar (3.0));
      Right.Set_To (OpenCV.Make_Scalar (0.0));
      Mask.Set_To (OpenCV.Make_Scalar (127.0));
      if Difference_Norm (Left, Right, Kind => L1) /= 9.0
        or else Squared_L2_Norm (Left, Mask) /= 27.0
        or else Squared_L2_Difference_Norm (Left, Right, Mask) /= 27.0
        or else Hamming_Norm (Left) /= 6.0
        or else Hamming_Pairwise_Norm (Left, Right, Two_Bits) /= 3.0
      then
         raise Program_Error with "installed numerical norms failed";
      end if;
   end;
   Ada.Text_IO.Put_Line ("opencv_core installed Mat consumer ok");
end Installed_Mat_Consumer;
