with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;

package body OpenCV.Core.Float32_Vec3_Access is

   procedure Raise_Invalid_Access (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Access;

   procedure Validate (Image : Mat; Row, Column : Integer) is
   begin
      if Image.Depth /= Float32 then
         Raise_Invalid_Access
           ("Float32 Vec3 typed Mat access requires a Float32 Mat");

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
      return OpenCV.Core.Float32_Vec3.Vector is
   begin
      Validate (Image, Row, Column);
      return
        OpenCV.Core.Internal.Typed_Access.Get_Float32_Vec3
          (Image, Row, Column);
   end Get;

   procedure Set
     (Image  : in out Mat;
      Row    : Integer;
      Column : Integer;
      Value  : OpenCV.Core.Float32_Vec3.Vector) is
   begin
      Validate (Image, Row, Column);
      OpenCV.Core.Internal.Typed_Access.Set_Float32_Vec3
        (Image, Row, Column, Value);
   end Set;

end OpenCV.Core.Float32_Vec3_Access;
