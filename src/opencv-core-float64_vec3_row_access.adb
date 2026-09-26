with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Float64_Vec3_Row_Access is
   pragma
     Compile_Time_Error
       (Float64_Vec3.Vector'Size /= 192, "Float64 Vec3 must occupy 192 bits");
   pragma
     Compile_Time_Error
       (Float64_Vec3.Vector'Component_Size /= 64,
        "Float64 Vec3 channels must occupy 64 bits");
   pragma
     Compile_Time_Error
       (Row_Array'Component_Size /= 192,
        "Float64 Vec3 rows must be tightly packed");
   pragma
     Compile_Time_Error
       (Float64_Vec3.Vector'Alignment > 8,
        "Float64 Vec3 alignment exceeds native alignment");
   pragma
     Compile_Time_Error
       (Float64_Vec3.Component_Index'First /= 0
          or else Float64_Vec3.Component_Index'Last /= 2,
        "Float64 Vec3 indices must be 0 .. 2");

   package Borrowing is new
     Internal.Typed_Row_Borrowing
       (Element_Type             => Float64_Vec3.Vector,
        Row_Array                => Row_Array,
        Required_Depth           => Float64,
        Required_Channels        => 3,
        Expected_Element_Bits    => 192,
        Native_Element_Alignment => 8,
        Type_Name                => "Float64 Vec3");

   procedure Validate (Image : Mat; Row : Natural; Length : Natural) is
   begin
      if Image.Depth /= Float64 or else Image.Channels /= 3 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Float64 Vec3 row requires Float64 C3 Mat");
      elsif Row >= Image.Rows
        or else Length /= Image.Columns
        or else Length > Natural'Last / 3
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Float64 Vec3 row or length outside bounds");
      end if;
   end Validate;

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Float64_Row_Buffer (1 .. Data'Length * 3);
      begin
         Internal.Typed_Access.Read_Float64_Vec3_Row
           (Image, Integer (Row), Buffer);
         for I in Data'Range loop
            declare
               J : constant Natural := (I - Data'First) * 3 + Buffer'First;
            begin
               Data (I) :=
                 (0 => Float64_Value (Buffer (J)),
                  1 => Float64_Value (Buffer (J + 1)),
                  2 => Float64_Value (Buffer (J + 2)));
            end;
         end loop;
      end;
   end Read_Row;

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Float64_Row_Buffer (1 .. Data'Length * 3);
      begin
         for I in Data'Range loop
            declare
               J : constant Natural := (I - Data'First) * 3 + Buffer'First;
            begin
               Buffer (J) := OpenCV.Internal.C_API.C_Float64 (Data (I) (0));
               Buffer (J + 1) :=
                 OpenCV.Internal.C_API.C_Float64 (Data (I) (1));
               Buffer (J + 2) :=
                 OpenCV.Internal.C_API.C_Float64 (Data (I) (2));
            end;
         end loop;
         Internal.Typed_Access.Write_Float64_Vec3_Row
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
end OpenCV.Core.Float64_Vec3_Row_Access;
