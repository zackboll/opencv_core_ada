with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Float64_Vec4_Row_Access is
   pragma Compile_Time_Error (Float64_Vec4.Vector'Size /= 256, "Vec4 size");
   pragma
     Compile_Time_Error
       (Float64_Vec4.Vector'Component_Size /= 64, "Vec4 scalar size");
   pragma
     Compile_Time_Error (Row_Array'Component_Size /= 256, "Vec4 row packing");
   pragma
     Compile_Time_Error (Float64_Vec4.Vector'Alignment > 8, "Vec4 alignment");
   pragma
     Compile_Time_Error
       (Float64_Vec4.Component_Index'First /= 0
          or else Float64_Vec4.Component_Index'Last /= 3,
        "Vec4 indices");

   package Borrowing is new
     Internal.Typed_Row_Borrowing
       (Element_Type             => Float64_Vec4.Vector,
        Row_Array                => Row_Array,
        Required_Depth           => Float64,
        Required_Channels        => 4,
        Expected_Element_Bits    => 256,
        Native_Element_Alignment => 8,
        Type_Name                => "Float64 Vec4");

   procedure Validate (Image : Mat; Row : Natural; Length : Natural) is
   begin
      if Image.Depth /= Float64 or else Image.Channels /= 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Float64 Vec4 row requires Float64 C4 Mat");
      elsif Row >= Image.Rows
        or else Length /= Image.Columns
        or else Length > Natural'Last / 4
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Float64 Vec4 row or length outside bounds");
      end if;
   end Validate;

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Float64_Row_Buffer (1 .. Data'Length * 4);
      begin
         Internal.Typed_Access.Read_Float64_Vec4_Row
           (Image, Integer (Row), Buffer);
         for I in Data'Range loop
            declare
               J : constant Natural := (I - Data'First) * 4 + Buffer'First;
            begin
               Data (I) :=
                 (0 => Float64_Value (Buffer (J)),
                  1 => Float64_Value (Buffer (J + 1)),
                  2 => Float64_Value (Buffer (J + 2)),
                  3 => Float64_Value (Buffer (J + 3)));
            end;
         end loop;
      end;
   end Read_Row;

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Float64_Row_Buffer (1 .. Data'Length * 4);
      begin
         for I in Data'Range loop
            declare
               J : constant Natural := (I - Data'First) * 4 + Buffer'First;
            begin
               for K in Float64_Vec4.Component_Index loop
                  Buffer (J + K) :=
                    OpenCV.Internal.C_API.C_Float64 (Data (I) (K));
               end loop;
            end;
         end loop;
         Internal.Typed_Access.Write_Float64_Vec4_Row
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
end OpenCV.Core.Float64_Vec4_Row_Access;
