with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Float64_Row_Access is

   package Borrowing is new
     OpenCV.Core.Internal.Typed_Row_Borrowing
       (Element_Type             => Float64_Value,
        Row_Array                => Row_Array,
        Required_Depth           => Float64,
        Required_Channels        => 1,
        Expected_Element_Bits    => 64,
        Native_Element_Alignment => 8,
        Type_Name                => "Float64");

   procedure Raise_Invalid_Access (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Access;

   procedure Validate (Image : Mat; Row : Natural; Length : Natural) is
   begin
      if Image.Depth /= Float64 then
         Raise_Invalid_Access ("Float64 row access requires a Float64 Mat");

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
        OpenCV.Core.Internal.Typed_Access.Float64_Row_Buffer
          (1 .. Data'Length);
   begin
      Validate (Image, Row, Data'Length);
      OpenCV.Core.Internal.Typed_Access.Read_Float64_Row
        (Image, Integer (Row), Buffer);

      for Index in Data'Range loop
         Data (Index) :=
           Float64_Value (Buffer (Index - Data'First + Buffer'First));
      end loop;
   end Read_Row;

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
      Buffer :
        OpenCV.Core.Internal.Typed_Access.Float64_Row_Buffer
          (1 .. Data'Length);
   begin
      Validate (Image, Row, Data'Length);

      for Index in Data'Range loop
         Buffer (Index - Data'First + Buffer'First) :=
           OpenCV.Internal.C_API.C_Float64 (Data (Index));
      end loop;

      OpenCV.Core.Internal.Typed_Access.Write_Float64_Row
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

end OpenCV.Core.Float64_Row_Access;
