with Ada.Exceptions;
with Interfaces;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Float16_Row_Access is

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
       (Row_Array'Component_Size /= 16,
        "Float16 row array components must be packed 16-bit values");
   pragma
     Compile_Time_Error
       (Float16_Value'Alignment > 2,
        "Float16_Value alignment must not exceed native CV_16F alignment");

   package Borrowing is new
     OpenCV.Core.Internal.Typed_Row_Borrowing
       (Element_Type             => Float16_Value,
        Row_Array                => Row_Array,
        Required_Depth           => Float16,
        Required_Channels        => 1,
        Expected_Element_Bits    => 16,
        Native_Element_Alignment => 2,
        Type_Name                => "Float16");

   procedure Raise_Invalid_Access (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Access;

   procedure Validate (Image : Mat; Row : Natural; Length : Natural) is
   begin
      if Image.Depth /= Float16 then
         Raise_Invalid_Access ("Float16 row access requires a Float16 Mat");

      elsif Image.Channels /= 1 then
         Raise_Invalid_Access
           ("typed Mat row access requires exactly one channel");

      elsif Image.Dimension_Count /= 2 then
         Raise_Invalid_Access
           ("typed Mat row access requires a two-dimensional Mat");

      elsif Row >= Image.Rows then
         Raise_Invalid_Access ("Mat row index is outside the valid range");

      elsif Length /= Image.Columns then
         Raise_Invalid_Access
           ("typed Mat row access requires one value per Mat column");
      end if;
   end Validate;

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array) is
      Buffer :
        OpenCV.Core.Internal.Typed_Access.Float16_Row_Buffer
          (1 .. Data'Length);
   begin
      Validate (Image, Row, Data'Length);
      OpenCV.Core.Internal.Typed_Access.Read_Float16_Row
        (Image, Integer (Row), Buffer);

      for Index in Data'Range loop
         Data (Index) :=
           Float16_From_Bits
             (Interfaces.Unsigned_16
                (Buffer (Index - Data'First + Buffer'First)));
      end loop;
   end Read_Row;

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
      Buffer :
        OpenCV.Core.Internal.Typed_Access.Float16_Row_Buffer
          (1 .. Data'Length);
   begin
      Validate (Image, Row, Data'Length);

      for Index in Data'Range loop
         Buffer (Index - Data'First + Buffer'First) :=
           OpenCV.Internal.C_API.C_UInt16 (Float16_Bits (Data (Index)));
      end loop;

      OpenCV.Core.Internal.Typed_Access.Write_Float16_Row
        (Image, Integer (Row), Buffer);
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

end OpenCV.Core.Float16_Row_Access;
