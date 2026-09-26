with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Float32_Vec2_Row_Access is
   pragma
     Compile_Time_Error
       (Float32_Vec2.Vector'Size /= 64, "Float32 Vec2 must occupy 64 bits");
   pragma
     Compile_Time_Error
       (Float32_Vec2.Vector'Component_Size /= 32,
        "Float32 Vec2 channels must occupy 32 bits");
   pragma
     Compile_Time_Error
       (Row_Array'Component_Size /= 64,
        "Float32 Vec2 row elements must occupy 64 bits");
   pragma
     Compile_Time_Error
       (Float32_Vec2.Vector'Alignment > 4,
        "Float32 Vec2 alignment exceeds native scalar");
   pragma
     Compile_Time_Error
       (Float32_Vec2.Component_Index'First /= 0
          or else Float32_Vec2.Component_Index'Last /= 1,
        "Vec2 indices must be 0 .. 1");
   package Borrowing is new
     Internal.Typed_Row_Borrowing
       (Element_Type             => Float32_Vec2.Vector,
        Row_Array                => Row_Array,
        Required_Depth           => Float32,
        Required_Channels        => 2,
        Expected_Element_Bits    => 64,
        Native_Element_Alignment => 4,
        Type_Name                => "Float32 Vec2");
   procedure Validate (Image : Mat; Row, Length : Natural) is
   begin
      if Image.Depth /= Float32
        or else Image.Channels /= 2
        or else Row >= Image.Rows
        or else Length /= Image.Columns
        or else Length > Natural'Last / 2
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Invalid Float32 Vec2 row access");
      end if;
   end Validate;
   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         B : Internal.Typed_Access.Float32_Row_Buffer (1 .. Data'Length * 2);
      begin
         Internal.Typed_Access.Read_Float32_Vec2_Row (Image, Integer (Row), B);
         for I in Data'Range loop
            Data (I) :=
              (0 => Float32_Value (B (1 + (I - Data'First) * 2)),
               1 => Float32_Value (B (2 + (I - Data'First) * 2)));
         end loop;
      end;
   end Read_Row;
   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         B : Internal.Typed_Access.Float32_Row_Buffer (1 .. Data'Length * 2);
      begin
         for I in Data'Range loop
            B (1 + (I - Data'First) * 2) :=
              OpenCV.Internal.C_API.C_Float32 (Data (I) (0));
            B (2 + (I - Data'First) * 2) :=
              OpenCV.Internal.C_API.C_Float32 (Data (I) (1));
         end loop;
         Internal.Typed_Access.Write_Float32_Vec2_Row
           (Image, Integer (Row), B);
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
end OpenCV.Core.Float32_Vec2_Row_Access;
