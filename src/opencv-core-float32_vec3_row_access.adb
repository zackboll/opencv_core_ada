with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Float32_Vec3_Row_Access is

   Scalars_Per_Element : constant Natural := 3;

   procedure Raise_Invalid_Access (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Access;

   procedure Validate (Image : Mat; Row : Natural; Length : Natural) is
   begin
      if Image.Depth /= Float32 then
         Raise_Invalid_Access
           ("Float32 Vec3 row access requires a Float32 Mat");

      elsif Image.Channels /= 3 then
         Raise_Invalid_Access
           ("Vec3 typed Mat row access requires exactly three channels");

      elsif Row >= Image.Rows then
         Raise_Invalid_Access ("Mat row index is outside the valid range");

      elsif Length /= Image.Columns then
         Raise_Invalid_Access
           ("Vec3 typed Mat row access requires one value per Mat column");

      elsif Length > Natural'Last / Scalars_Per_Element then
         Raise_Invalid_Access
           ("Vec3 typed Mat row access buffer length is too large");
      end if;
   end Validate;

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array) is
   begin
      Validate (Image, Row, Data'Length);

      declare
         Buffer :
           OpenCV.Core.Internal.Typed_Access.Float32_Row_Buffer
             (1 .. Data'Length * Scalars_Per_Element);
      begin
         OpenCV.Core.Internal.Typed_Access.Read_Float32_Vec3_Row
           (Image, Integer (Row), Buffer);

         for Index in Data'Range loop
            declare
               Scalar_Index : constant Natural :=
                 (Index - Data'First) * Scalars_Per_Element + Buffer'First;
            begin
               Data (Index) :=
                 (0 => Float32_Value (Buffer (Scalar_Index)),
                  1 => Float32_Value (Buffer (Scalar_Index + 1)),
                  2 => Float32_Value (Buffer (Scalar_Index + 2)));
            end;
         end loop;
      end;
   end Read_Row;

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
   begin
      Validate (Image, Row, Data'Length);

      declare
         Buffer :
           OpenCV.Core.Internal.Typed_Access.Float32_Row_Buffer
             (1 .. Data'Length * Scalars_Per_Element);
      begin
         for Index in Data'Range loop
            declare
               Scalar_Index : constant Natural :=
                 (Index - Data'First) * Scalars_Per_Element + Buffer'First;
            begin
               Buffer (Scalar_Index) :=
                 OpenCV.Internal.C_API.C_Float32 (Data (Index) (0));
               Buffer (Scalar_Index + 1) :=
                 OpenCV.Internal.C_API.C_Float32 (Data (Index) (1));
               Buffer (Scalar_Index + 2) :=
                 OpenCV.Internal.C_API.C_Float32 (Data (Index) (2));
            end;
         end loop;

         OpenCV.Core.Internal.Typed_Access.Write_Float32_Vec3_Row
           (Image, Integer (Row), Buffer);
      end;
   end Write_Row;

end OpenCV.Core.Float32_Vec3_Row_Access;
