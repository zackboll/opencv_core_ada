with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.UInt16_Vec3_Row_Access is
   pragma Compile_Time_Error (UInt16_Vec3.Vector'Size /= 48, "Vec3 size");
   pragma
     Compile_Time_Error
       (UInt16_Vec3.Vector'Component_Size /= 16, "Vec3 scalar size");
   pragma
     Compile_Time_Error (Row_Array'Component_Size /= 48, "Vec3 row packing");
   pragma
     Compile_Time_Error (UInt16_Vec3.Vector'Alignment > 2, "Vec3 alignment");
   pragma
     Compile_Time_Error
       (UInt16_Vec3.Component_Index'First /= 0
          or else UInt16_Vec3.Component_Index'Last /= 2,
        "Vec3 indices");

   package Borrowing is new
     Internal.Typed_Row_Borrowing
       (Element_Type             => UInt16_Vec3.Vector,
        Row_Array                => Row_Array,
        Required_Depth           => UInt16,
        Required_Channels        => 3,
        Expected_Element_Bits    => 48,
        Native_Element_Alignment => 2,
        Type_Name                => "UInt16 Vec3");

   procedure Validate (Image : Mat; Row, Length : Natural) is
   begin
      if Image.Depth /= UInt16 or else Image.Channels /= 3 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "UInt16 Vec3 row requires UInt16 C3 Mat");
      elsif Image.Dimension_Count /= 2
        or else Row >= Image.Rows
        or else Length /= Image.Columns
        or else Length > Natural'Last / 3
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "UInt16 Vec3 row or length outside bounds");
      end if;
   end Validate;

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.UInt16_Row_Buffer (1 .. Data'Length * 3);
      begin
         Internal.Typed_Access.Read_UInt16_Vec3_Row
           (Image, Integer (Row), Buffer);
         for I in Data'Range loop
            declare
               J : constant Natural := (I - Data'First) * 3 + Buffer'First;
            begin
               Data (I) :=
                 (0 => UInt16_Value (Buffer (J)),
                  1 => UInt16_Value (Buffer (J + 1)),
                  2 => UInt16_Value (Buffer (J + 2)));
            end;
         end loop;
      end;
   end Read_Row;

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.UInt16_Row_Buffer (1 .. Data'Length * 3);
      begin
         for I in Data'Range loop
            declare
               J : constant Natural := (I - Data'First) * 3 + Buffer'First;
            begin
               Buffer (J) := OpenCV.Internal.C_API.C_UInt16 (Data (I) (0));
               Buffer (J + 1) := OpenCV.Internal.C_API.C_UInt16 (Data (I) (1));
               Buffer (J + 2) := OpenCV.Internal.C_API.C_UInt16 (Data (I) (2));
            end;
         end loop;
         Internal.Typed_Access.Write_UInt16_Vec3_Row
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
end OpenCV.Core.UInt16_Vec3_Row_Access;
