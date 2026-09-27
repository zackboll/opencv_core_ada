with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Int16_Vec4_Row_Access is
   pragma Compile_Time_Error (Int16_Vec4.Vector'Size /= 64, "Vec4 size");
   pragma
     Compile_Time_Error
       (Int16_Vec4.Vector'Component_Size /= 16, "Vec4 scalar size");
   pragma
     Compile_Time_Error (Row_Array'Component_Size /= 64, "Vec4 row packing");
   pragma
     Compile_Time_Error (Int16_Vec4.Vector'Alignment > 2, "Vec4 alignment");
   pragma
     Compile_Time_Error
       (Int16_Vec4.Component_Index'First /= 0
          or else Int16_Vec4.Component_Index'Last /= 3,
        "Vec4 indices");

   package Borrowing is new
     Internal.Typed_Row_Borrowing
       (Element_Type             => Int16_Vec4.Vector,
        Row_Array                => Row_Array,
        Required_Depth           => Int16,
        Required_Channels        => 4,
        Expected_Element_Bits    => 64,
        Native_Element_Alignment => 2,
        Type_Name                => "Int16 Vec4");

   procedure Validate (Image : Mat; Row, Length : Natural) is
   begin
      if Image.Depth /= Int16 or else Image.Channels /= 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Int16 Vec4 row requires Int16 C4 Mat");
      elsif Image.Dimension_Count /= 2
        or else Row >= Image.Rows
        or else Length /= Image.Columns
        or else Length > Natural'Last / 4
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Int16 Vec4 row or length outside bounds");
      end if;
   end Validate;

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Int16_Row_Buffer (1 .. Data'Length * 4);
      begin
         Internal.Typed_Access.Read_Int16_Vec4_Row
           (Image, Integer (Row), Buffer);
         for I in Data'Range loop
            declare
               J : constant Natural := (I - Data'First) * 4 + Buffer'First;
            begin
               Data (I) :=
                 (0 => Int16_Value (Buffer (J)),
                  1 => Int16_Value (Buffer (J + 1)),
                  2 => Int16_Value (Buffer (J + 2)),
                  3 => Int16_Value (Buffer (J + 3)));
            end;
         end loop;
      end;
   end Read_Row;

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Int16_Row_Buffer (1 .. Data'Length * 4);
      begin
         for I in Data'Range loop
            declare
               J : constant Natural := (I - Data'First) * 4 + Buffer'First;
            begin
               Buffer (J) := OpenCV.Internal.C_API.C_Int16 (Data (I) (0));
               Buffer (J + 1) := OpenCV.Internal.C_API.C_Int16 (Data (I) (1));
               Buffer (J + 2) := OpenCV.Internal.C_API.C_Int16 (Data (I) (2));
               Buffer (J + 3) := OpenCV.Internal.C_API.C_Int16 (Data (I) (3));
            end;
         end loop;
         Internal.Typed_Access.Write_Int16_Vec4_Row
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
end OpenCV.Core.Int16_Vec4_Row_Access;
