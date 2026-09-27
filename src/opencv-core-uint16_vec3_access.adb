with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;

package body OpenCV.Core.UInt16_Vec3_Access is
   procedure Validate (Image : Mat) is
   begin
      if Image.Depth /= UInt16 or else Image.Channels /= 3 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "UInt16 Vec3 requires UInt16 C3 Mat");
      end if;
   end Validate;

   procedure Validate (Image : Mat; Row, Column : Integer) is
   begin
      Validate (Image);
      if Image.Dimension_Count /= 2
        or else Row < 0
        or else Row >= Image.Rows
        or else Column < 0
        or else Column >= Image.Columns
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Mat coordinates outside bounds");
      end if;
   end Validate;

   procedure Validate (Image : Mat; Indices : Index_Array) is
      Axis : Positive := 1;
   begin
      Validate (Image);
      if Image.Dimension_Count = 0
        or else Indices'Length /= Image.Dimension_Count
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Mat dimension count mismatch");
      end if;
      for Index_Value of Indices loop
         if Index_Value >= Image.Extent (Axis) then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity, "Mat index outside bounds");
         end if;
         Axis := Axis + 1;
      end loop;
   end Validate;

   function Get (Image : Mat; Row, Column : Integer) return UInt16_Vec3.Vector
   is
   begin
      Validate (Image, Row, Column);
      return Internal.Typed_Access.Get_UInt16_Vec3 (Image, Row, Column);
   end Get;

   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : UInt16_Vec3.Vector) is
   begin
      Validate (Image, Row, Column);
      Internal.Typed_Access.Set_UInt16_Vec3 (Image, Row, Column, Value);
   end Set;

   function Get (Image : Mat; Indices : Index_Array) return UInt16_Vec3.Vector
   is
   begin
      Validate (Image, Indices);
      return Internal.Typed_Access.Get_UInt16_Vec3 (Image, Indices);
   end Get;

   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : UInt16_Vec3.Vector) is
   begin
      Validate (Image, Indices);
      Internal.Typed_Access.Set_UInt16_Vec3 (Image, Indices, Value);
   end Set;
end OpenCV.Core.UInt16_Vec3_Access;
