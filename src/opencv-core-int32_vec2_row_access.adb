with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Int32_Vec2_Row_Access is
   pragma Compile_Time_Error (Int32_Vec2.Vector'Size /= 64, "Vec2 size");
   pragma
     Compile_Time_Error
       (Int32_Vec2.Vector'Component_Size /= 32, "Vec2 scalar size");
   pragma
     Compile_Time_Error (Row_Array'Component_Size /= 64, "Vec2 row packing");
   pragma
     Compile_Time_Error (Int32_Vec2.Vector'Alignment > 4, "Vec2 alignment");
   pragma
     Compile_Time_Error
       (Int32_Vec2.Component_Index'First /= 0
          or else Int32_Vec2.Component_Index'Last /= 1,
        "Vec2 indices");
   package Borrowing is new
     Internal.Typed_Row_Borrowing
       (Element_Type             => Int32_Vec2.Vector,
        Row_Array                => Row_Array,
        Required_Depth           => Int32,
        Required_Channels        => 2,
        Expected_Element_Bits    => 64,
        Native_Element_Alignment => 4,
        Type_Name                => "Int32 Vec2");
   procedure Validate (Image : Mat; Row, Length : Natural) is
   begin
      if Image.Depth /= Int32 or else Image.Channels /= 2 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Int32 Vec2 row requires Int32 C2 Mat");
      elsif Image.Dimension_Count /= 2
        or else Row >= Image.Rows
        or else Length /= Image.Columns
        or else Length > Natural'Last / 2
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Int32 Vec2 row or length outside bounds");
      end if;
   end Validate;
   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Int32_Row_Buffer (1 .. Data'Length * 2);
      begin
         Internal.Typed_Access.Read_Int32_Vec2_Row
           (Image, Integer (Row), Buffer);
         for I in Data'Range loop
            declare
               J : constant Natural := (I - Data'First) * 2 + Buffer'First;
            begin
               Data (I) :=
                 (0 => Int32_Value (Buffer (J)),
                  1 => Int32_Value (Buffer (J + 1)));
            end;
         end loop;
      end;
   end Read_Row;
   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Int32_Row_Buffer (1 .. Data'Length * 2);
      begin
         for I in Data'Range loop
            declare
               J : constant Natural := (I - Data'First) * 2 + Buffer'First;
            begin
               Buffer (J) := OpenCV.Internal.C_API.C_Int32 (Data (I) (0));
               Buffer (J + 1) := OpenCV.Internal.C_API.C_Int32 (Data (I) (1));
            end;
         end loop;
         Internal.Typed_Access.Write_Int32_Vec2_Row
           (Image, Integer (Row), Buffer);
      end;
   end Write_Row;
   procedure With_Read_Only_Row
     (Image   : Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased Row_Array)) is
   begin
      Borrowing.With_Read_Only_Row (Image, Row, Process);
   end With_Read_Only_Row;
   procedure With_Writable_Row
     (Image   : in out Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased in out Row_Array)) is
   begin
      Borrowing.With_Writable_Row (Image, Row, Process);
   end With_Writable_Row;
end OpenCV.Core.Int32_Vec2_Row_Access;
