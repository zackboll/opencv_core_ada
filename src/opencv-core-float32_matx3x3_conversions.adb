with Ada.Exceptions;
with OpenCV.Core.Float32_Row_Access;

package body OpenCV.Core.Float32_Matx3x3_Conversions is

   procedure Raise_Invalid_Conversion (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Conversion;

   procedure Validate (Image : Mat) is
   begin
      if Image.Rows /= 3 then
         Raise_Invalid_Conversion
           ("Float32 Matx3x3 conversion requires exactly three rows");

      elsif Image.Columns /= 3 then
         Raise_Invalid_Conversion
           ("Float32 Matx3x3 conversion requires exactly three columns");

      elsif Image.Depth /= Float32 then
         Raise_Invalid_Conversion
           ("Float32 Matx3x3 conversion requires a Float32 Mat");

      elsif Image.Channels /= 1 then
         Raise_Invalid_Conversion
           ("Float32 Matx3x3 conversion requires exactly one channel");
      end if;
   end Validate;

   function To_Mat (Value : OpenCV.Core.Float32_Matx3x3.Matrix) return Mat is
      Image    : Mat :=
        Create
          (Rows         => 3,
           Columns      => 3,
           Element_Type => (Depth => Float32, Channels => 1));
      Row_Data : OpenCV.Core.Float32_Row_Access.Row_Array (Value'Range (2));
   begin
      for Row in Value'Range (1) loop
         for Column in Value'Range (2) loop
            Row_Data (Column) := Value (Row, Column);
         end loop;

         OpenCV.Core.Float32_Row_Access.Write_Row (Image, Row, Row_Data);
      end loop;

      return Image;
   end To_Mat;

   function To_Matx3x3 (Image : Mat) return OpenCV.Core.Float32_Matx3x3.Matrix
   is
      Value    : OpenCV.Core.Float32_Matx3x3.Matrix;
      Row_Data : OpenCV.Core.Float32_Row_Access.Row_Array (Value'Range (2));
   begin
      Validate (Image);

      for Row in Value'Range (1) loop
         OpenCV.Core.Float32_Row_Access.Read_Row (Image, Row, Row_Data);

         for Column in Value'Range (2) loop
            Value (Row, Column) := Row_Data (Column);
         end loop;
      end loop;

      return Value;
   end To_Matx3x3;

end OpenCV.Core.Float32_Matx3x3_Conversions;
