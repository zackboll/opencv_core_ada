with Ada.Exceptions;
with Interfaces;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Float16_Vec2_Row_Access is
   pragma
     Compile_Time_Error
       (Float16_Value'Size /= 16,
        "Float16_Value must be exactly 16 bits to alias CV_16F storage");
   pragma
     Compile_Time_Error
       (Float16_Value'Object_Size /= 16,
        "Float16_Value must have no hidden padding");
   pragma
     Compile_Time_Error
       (Float16_Vec2.Vector'Component_Size /= 16,
        "Float16 Vec2 components must be tightly packed 16-bit channels");
   pragma
     Compile_Time_Error
       (Float16_Vec2.Vector'Size /= 32,
        "Float16 Vec2 Vector must be exactly 32 bits for zero-copy C2 rows");
   pragma
     Compile_Time_Error
       (Float16_Vec2.Vector'Object_Size /= 32,
        "Float16 Vec2 Vector must have no hidden padding");
   pragma
     Compile_Time_Error
       (Row_Array'Component_Size /= 32,
        "Float16 Vec2 Row_Array must be tightly packed 32-bit elements");
   pragma
     Compile_Time_Error
       (Float16_Vec2.Vector'Alignment > 2,
        "Float16 Vec2 Vector alignment is stricter than CV_16FC2 guarantees");
   pragma
     Compile_Time_Error
       (Float16_Vec2.Component_Index'First /= 0
          or else Float16_Vec2.Component_Index'Last /= 1,
        "Float16 Vec2 components must be indexed 0 .. 1");

   package Borrowing is new
     Internal.Typed_Row_Borrowing
       (Element_Type             => Float16_Vec2.Vector,
        Row_Array                => Row_Array,
        Required_Depth           => Float16,
        Required_Channels        => 2,
        Expected_Element_Bits    => 32,
        Native_Element_Alignment => 2,
        Type_Name                => "Float16 Vec2");

   Scalars_Per_Element : constant := 2;

   procedure Validate (Image : Mat; Row, Length : Natural) is
   begin
      if Image.Depth /= Float16 or else Image.Channels /= 2 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Float16 Vec2 row requires Float16 C2 Mat");
      elsif Image.Dimension_Count /= 2
        or else Row >= Image.Rows
        or else Length /= Image.Columns
        or else Length > Natural'Last / Scalars_Per_Element
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "Float16 Vec2 row or length outside bounds");
      end if;
   end Validate;

   function Bits (Value : Float16_Value) return OpenCV.Internal.C_API.C_UInt16
   is (OpenCV.Internal.C_API.C_UInt16 (Float16_Bits (Value)));

   function From (Bits : OpenCV.Internal.C_API.C_UInt16) return Float16_Value
   is (Float16_From_Bits (Interfaces.Unsigned_16 (Bits)));

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Float16_Row_Buffer
             (1 .. Data'Length * Scalars_Per_Element);
      begin
         Internal.Typed_Access.Read_Float16_Vec2_Row
           (Image, Integer (Row), Buffer);
         for I in Data'Range loop
            declare
               J : constant Natural :=
                 (I - Data'First) * Scalars_Per_Element + Buffer'First;
            begin
               Data (I) :=
                 (0 => From (Buffer (J)), 1 => From (Buffer (J + 1)));
            end;
         end loop;
      end;
   end Read_Row;

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Float16_Row_Buffer
             (1 .. Data'Length * Scalars_Per_Element);
      begin
         for I in Data'Range loop
            declare
               J : constant Natural :=
                 (I - Data'First) * Scalars_Per_Element + Buffer'First;
            begin
               Buffer (J) := Bits (Data (I) (0));
               Buffer (J + 1) := Bits (Data (I) (1));
            end;
         end loop;
         Internal.Typed_Access.Write_Float16_Vec2_Row
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
end OpenCV.Core.Float16_Vec2_Row_Access;
