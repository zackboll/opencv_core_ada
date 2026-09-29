with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Int8_Vec2_Row_Access is
   pragma
     Compile_Time_Error
       (Int8_Value'Size /= 8,
        "Int8_Value must be exactly 8 bits to alias CV_8S storage");
   pragma
     Compile_Time_Error
       (Int8_Value'Object_Size /= 8, "Int8_Value must have no hidden padding");
   pragma
     Compile_Time_Error
       (Int8_Vec2.Vector'Component_Size /= 8,
        "Int8 Vec2 components must be tightly packed 8-bit channels");
   pragma
     Compile_Time_Error
       (Int8_Vec2.Vector'Size /= 16,
        "Int8 Vec2 Vector must be exactly 16 bits for zero-copy C2 rows");
   pragma
     Compile_Time_Error
       (Int8_Vec2.Vector'Object_Size /= 16,
        "Int8 Vec2 Vector must have no hidden padding");
   pragma
     Compile_Time_Error
       (Row_Array'Component_Size /= 16,
        "Int8 Vec2 Row_Array must be tightly packed 16-bit elements");
   pragma
     Compile_Time_Error
       (Int8_Vec2.Vector'Alignment > 1,
        "Int8 Vec2 Vector alignment is stricter than CV_8SC2 guarantees");
   pragma
     Compile_Time_Error
       (Int8_Vec2.Component_Index'First /= 0
          or else Int8_Vec2.Component_Index'Last /= 1,
        "Int8 Vec2 components must be indexed 0 .. 1");

   package Borrowing is new
     Internal.Typed_Row_Borrowing
       (Element_Type             => Int8_Vec2.Vector,
        Row_Array                => Row_Array,
        Required_Depth           => Int8,
        Required_Channels        => 2,
        Expected_Element_Bits    => 16,
        Native_Element_Alignment => 1,
        Type_Name                => "Int8 Vec2");

   Scalars_Per_Element : constant := 2;

   procedure Validate (Image : Mat; Row, Length : Natural) is
   begin
      if Image.Depth /= Int8 or else Image.Channels /= 2 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Int8 Vec2 row requires Int8 C2 Mat");
      elsif Image.Dimension_Count /= 2
        or else Row >= Image.Rows
        or else Length /= Image.Columns
        or else Length > Natural'Last / Scalars_Per_Element
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Int8 Vec2 row or length outside bounds");
      end if;
   end Validate;

   function To_C (Value : Int8_Value) return OpenCV.Internal.C_API.C_Int8
   is (OpenCV.Internal.C_API.C_Int8 (Value));

   function From_C (Value : OpenCV.Internal.C_API.C_Int8) return Int8_Value
   is (Int8_Value (Value));

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Int8_Row_Buffer
             (1 .. Data'Length * Scalars_Per_Element);
      begin
         Internal.Typed_Access.Read_Int8_Vec2_Row
           (Image, Integer (Row), Buffer);
         for I in Data'Range loop
            declare
               J : constant Natural :=
                 (I - Data'First) * Scalars_Per_Element + Buffer'First;
            begin
               Data (I) :=
                 (0 => From_C (Buffer (J)), 1 => From_C (Buffer (J + 1)));
            end;
         end loop;
      end;
   end Read_Row;

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
   begin
      Validate (Image, Row, Data'Length);
      declare
         Buffer :
           Internal.Typed_Access.Int8_Row_Buffer
             (1 .. Data'Length * Scalars_Per_Element);
      begin
         for I in Data'Range loop
            declare
               J : constant Natural :=
                 (I - Data'First) * Scalars_Per_Element + Buffer'First;
            begin
               Buffer (J) := To_C (Data (I) (0));
               Buffer (J + 1) := To_C (Data (I) (1));
            end;
         end loop;
         Internal.Typed_Access.Write_Int8_Vec2_Row
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
end OpenCV.Core.Int8_Vec2_Row_Access;
