with Ada.Exceptions;
with Interfaces;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Float16_Vec3_Row_Access is

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
       (OpenCV.Core.Float16_Vec3.Vector'Component_Size /= 16,
        "Float16 Vec3 components must be tightly packed 16-bit channels");
   pragma
     Compile_Time_Error
       (OpenCV.Core.Float16_Vec3.Vector'Size /= 48,
        "Float16 Vec3 Vector must be exactly 48 bits for zero-copy C3 rows");
   pragma
     Compile_Time_Error
       (OpenCV.Core.Float16_Vec3.Vector'Object_Size /= 48,
        "Float16 Vec3 Vector must have no hidden padding");
   pragma
     Compile_Time_Error
       (Row_Array'Component_Size /= 48,
        "Float16 Vec3 Row_Array must be tightly packed 48-bit pixels");
   pragma
     Compile_Time_Error
       (OpenCV.Core.Float16_Vec3.Vector'Alignment > 2,
        "Float16 Vec3 Vector alignment is stricter than CV_16FC3 guarantees");
   pragma
     Compile_Time_Error
       (OpenCV.Core.Float16_Vec3.Component_Index'First /= 0
          or else OpenCV.Core.Float16_Vec3.Component_Index'Last /= 2,
        "Float16 Vec3 components must be indexed 0 .. 2");

   package Borrowing is new
     OpenCV.Core.Internal.Typed_Row_Borrowing
       (Element_Type             => OpenCV.Core.Float16_Vec3.Vector,
        Row_Array                => Row_Array,
        Required_Depth           => Float16,
        Required_Channels        => 3,
        Expected_Element_Bits    => 48,
        Native_Element_Alignment => 2,
        Type_Name                => "Float16 Vec3");

   Scalars_Per_Element : constant Natural := 3;

   procedure Raise_Invalid_Access (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Access;

   procedure Validate (Image : Mat; Row : Natural; Length : Natural) is
   begin
      if Image.Depth /= Float16 then
         Raise_Invalid_Access
           ("Float16 Vec3 row access requires a Float16 Mat");

      elsif Image.Channels /= 3 then
         Raise_Invalid_Access
           ("Vec3 typed Mat row access requires exactly three channels");

      elsif Image.Dimension_Count /= 2 then
         Raise_Invalid_Access
           ("typed Mat row access requires a two-dimensional Mat");

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
           OpenCV.Core.Internal.Typed_Access.Float16_Row_Buffer
             (1 .. Data'Length * Scalars_Per_Element);
      begin
         OpenCV.Core.Internal.Typed_Access.Read_Float16_Vec3_Row
           (Image, Integer (Row), Buffer);

         for Index in Data'Range loop
            declare
               Scalar_Index : constant Natural :=
                 (Index - Data'First) * Scalars_Per_Element + Buffer'First;
            begin
               Data (Index) :=
                 (0 =>
                    Float16_From_Bits
                      (Interfaces.Unsigned_16 (Buffer (Scalar_Index))),
                  1 =>
                    Float16_From_Bits
                      (Interfaces.Unsigned_16 (Buffer (Scalar_Index + 1))),
                  2 =>
                    Float16_From_Bits
                      (Interfaces.Unsigned_16 (Buffer (Scalar_Index + 2))));
            end;
         end loop;
      end;
   end Read_Row;

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
   begin
      Validate (Image, Row, Data'Length);

      declare
         Buffer :
           OpenCV.Core.Internal.Typed_Access.Float16_Row_Buffer
             (1 .. Data'Length * Scalars_Per_Element);
      begin
         for Index in Data'Range loop
            declare
               Scalar_Index : constant Natural :=
                 (Index - Data'First) * Scalars_Per_Element + Buffer'First;
            begin
               Buffer (Scalar_Index) :=
                 OpenCV.Internal.C_API.C_UInt16
                   (Float16_Bits (Data (Index) (0)));
               Buffer (Scalar_Index + 1) :=
                 OpenCV.Internal.C_API.C_UInt16
                   (Float16_Bits (Data (Index) (1)));
               Buffer (Scalar_Index + 2) :=
                 OpenCV.Internal.C_API.C_UInt16
                   (Float16_Bits (Data (Index) (2)));
            end;
         end loop;

         OpenCV.Core.Internal.Typed_Access.Write_Float16_Vec3_Row
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

end OpenCV.Core.Float16_Vec3_Row_Access;
