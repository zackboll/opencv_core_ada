with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Int8_Vec4_Row_Access is
   pragma
     Compile_Time_Error
       (Int8_Value'Size /= 8,
        "Int8_Value must be exactly 8 bits to alias CV_8S storage");
   pragma
     Compile_Time_Error
       (Int8_Value'Object_Size /= 8, "Int8_Value must have no hidden padding");
   pragma
     Compile_Time_Error
       (Int8_Vec4.Vector'Component_Size /= 8,
        "Int8 Vec4 components must be tightly packed 8-bit channels");
   pragma
     Compile_Time_Error
       (Int8_Vec4.Vector'Size /= 32,
        "Int8 Vec4 Vector must be exactly 32 bits for zero-copy C4 rows");
   pragma
     Compile_Time_Error
       (Int8_Vec4.Vector'Object_Size /= 32,
        "Int8 Vec4 Vector must have no hidden padding");
   pragma
     Compile_Time_Error
       (Row_Array'Component_Size /= 32,
        "Int8 Vec4 Row_Array must be tightly packed 32-bit elements");
   pragma
     Compile_Time_Error
       (Int8_Vec4.Vector'Alignment > 1,
        "Int8 Vec4 Vector alignment is stricter than CV_8SC4 guarantees");
   pragma
     Compile_Time_Error
       (Int8_Vec4.Component_Index'First /= 0
          or else Int8_Vec4.Component_Index'Last /= 3,
        "Int8 Vec4 components must be indexed 0 .. 3");

   package Borrowing is new
     Internal.Typed_Row_Borrowing
       (Element_Type             => Int8_Vec4.Vector,
        Row_Array                => Row_Array,
        Required_Depth           => Int8,
        Required_Channels        => 4,
        Expected_Element_Bits    => 32,
        Native_Element_Alignment => 1,
        Type_Name                => "Int8 Vec4");

   Scalars_Per_Element : constant := 4;

   procedure Validate (Image : Mat; Row, Length : Natural) is
   begin
      if Image.Depth /= Int8 or else Image.Channels /= 4 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Int8 Vec4 row requires Int8 C4 Mat");
      elsif Image.Dimension_Count /= 2
        or else Row >= Image.Rows
        or else Length /= Image.Columns
        or else Length > Natural'Last / Scalars_Per_Element
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "Int8 Vec4 row or length outside bounds");
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
         Internal.Typed_Access.Read_Int8_Vec4_Row
           (Image, Integer (Row), Buffer);
         for I in Data'Range loop
            declare
               J : constant Natural :=
                 (I - Data'First) * Scalars_Per_Element + Buffer'First;
            begin
               Data (I) :=
                 (0 => From_C (Buffer (J)),
                  1 => From_C (Buffer (J + 1)),
                  2 => From_C (Buffer (J + 2)),
                  3 => From_C (Buffer (J + 3)));
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
               Buffer (J + 2) := To_C (Data (I) (2));
               Buffer (J + 3) := To_C (Data (I) (3));
            end;
         end loop;
         Internal.Typed_Access.Write_Int8_Vec4_Row
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
end OpenCV.Core.Int8_Vec4_Row_Access;
