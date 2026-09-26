with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;

package body OpenCV.Core.Float64_Vec3_Access is
   procedure Validate (Image : Mat) is
   begin
      if Image.Depth /= Float64 or else Image.Channels /= 3 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Float64 Vec3 requires Float64 C3 Mat");
      end if;
   end Validate;

   procedure Validate (Image : Mat; Row, Column : Integer) is
   begin
      Validate (Image);
      if Row < 0
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

   function Get (Image : Mat; Row, Column : Integer) return Float64_Vec3.Vector
   is
   begin
      Validate (Image, Row, Column);
      return Internal.Typed_Access.Get_Float64_Vec3 (Image, Row, Column);
   end Get;

   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Float64_Vec3.Vector)
   is
   begin
      Validate (Image, Row, Column);
      Internal.Typed_Access.Set_Float64_Vec3 (Image, Row, Column, Value);
   end Set;

   function Get (Image : Mat; Indices : Index_Array) return Float64_Vec3.Vector
   is
   begin
      Validate (Image, Indices);
      return Internal.Typed_Access.Get_Float64_Vec3 (Image, Indices);
   end Get;

   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Float64_Vec3.Vector)
   is
   begin
      Validate (Image, Indices);
      Internal.Typed_Access.Set_Float64_Vec3 (Image, Indices, Value);
   end Set;
end OpenCV.Core.Float64_Vec3_Access;
