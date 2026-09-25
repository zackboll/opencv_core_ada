with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;

package body OpenCV.Core.Float16_Vec3_Access is

   procedure Raise_Invalid_Access (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Access;

   procedure Validate (Image : Mat; Row, Column : Integer) is
   begin
      if Image.Depth /= Float16 then
         Raise_Invalid_Access
           ("Float16 Vec3 typed Mat access requires a Float16 Mat");

      elsif Image.Channels /= 3 then
         Raise_Invalid_Access
           ("Vec3 typed Mat access requires exactly three channels");

      elsif Row < 0 or else Row >= Image.Rows then
         Raise_Invalid_Access ("Mat row index is outside the valid range");

      elsif Column < 0 or else Column >= Image.Columns then
         Raise_Invalid_Access ("Mat column index is outside the valid range");
      end if;
   end Validate;

   function Get
     (Image : Mat; Row, Column : Integer)
      return OpenCV.Core.Float16_Vec3.Vector is
   begin
      Validate (Image, Row, Column);
      return
        OpenCV.Core.Internal.Typed_Access.Get_Float16_Vec3
          (Image, Row, Column);
   end Get;

   procedure Set
     (Image  : in out Mat;
      Row    : Integer;
      Column : Integer;
      Value  : OpenCV.Core.Float16_Vec3.Vector) is
   begin
      Validate (Image, Row, Column);
      OpenCV.Core.Internal.Typed_Access.Set_Float16_Vec3
        (Image, Row, Column, Value);
   end Set;

   procedure Validate (Image : Mat; Indices : Index_Array) is
      Axis : Positive := 1;
   begin
      if Image.Depth /= Float16 then
         Raise_Invalid_Access
           ("Float16 Vec3 typed Mat access requires a Float16 Mat");

      elsif Image.Channels /= 3 then
         Raise_Invalid_Access
           ("Vec3 typed Mat access requires exactly three channels");

      elsif Image.Dimension_Count = 0 then
         Raise_Invalid_Access
           ("typed Mat access requires a Mat with at least one dimension");

      elsif Indices'Length /= Image.Dimension_Count then
         Raise_Invalid_Access
           ("typed Mat access requires one index per Mat dimension");
      end if;

      for Index_Value of Indices loop
         if Index_Value >= Image.Extent (Axis) then
            Raise_Invalid_Access ("Mat index is outside the valid range");
         end if;

         Axis := Axis + 1;
      end loop;
   end Validate;

   function Get
     (Image : Mat; Indices : Index_Array)
      return OpenCV.Core.Float16_Vec3.Vector is
   begin
      Validate (Image, Indices);
      return
        OpenCV.Core.Internal.Typed_Access.Get_Float16_Vec3 (Image, Indices);
   end Get;

   procedure Set
     (Image   : in out Mat;
      Indices : Index_Array;
      Value   : OpenCV.Core.Float16_Vec3.Vector) is
   begin
      Validate (Image, Indices);
      OpenCV.Core.Internal.Typed_Access.Set_Float16_Vec3
        (Image, Indices, Value);
   end Set;

end OpenCV.Core.Float16_Vec3_Access;
