with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;

package body OpenCV.Core.Float32_Vec2_Access is
   procedure Validate (Image : Mat) is
   begin
      if Image.Depth /= Float32 or else Image.Channels /= 2 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Float32 Vec2 requires Float32 C2 Mat");
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
   function Get (Image : Mat; Row, Column : Integer) return Float32_Vec2.Vector
   is
   begin
      Validate (Image, Row, Column);
      return Internal.Typed_Access.Get_Float32_Vec2 (Image, Row, Column);
   end Get;
   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Float32_Vec2.Vector)
   is
   begin
      Validate (Image, Row, Column);
      Internal.Typed_Access.Set_Float32_Vec2 (Image, Row, Column, Value);
   end Set;
   function Get (Image : Mat; Indices : Index_Array) return Float32_Vec2.Vector
   is
   begin
      Validate (Image, Indices);
      return Internal.Typed_Access.Get_Float32_Vec2 (Image, Indices);
   end Get;
   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Float32_Vec2.Vector)
   is
   begin
      Validate (Image, Indices);
      Internal.Typed_Access.Set_Float32_Vec2 (Image, Indices, Value);
   end Set;
end OpenCV.Core.Float32_Vec2_Access;
