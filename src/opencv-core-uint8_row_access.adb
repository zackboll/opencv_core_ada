with Ada.Exceptions;
with OpenCV.Core.Internal.Row_Data;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Internal.C_API;
with System;
with System.Address_To_Access_Conversions;

package body OpenCV.Core.UInt8_Row_Access is

   use type OpenCV.Internal.C_API.C_UInt64;

   pragma
     Compile_Time_Error
       (UInt8_Value'Size /= 8,
        "UInt8_Value must be 8 bits for zero-copy Mat row views");
   pragma
     Compile_Time_Error
       (UInt8_Value'Alignment < 1,
        "UInt8_Value alignment is incompatible with OpenCV CV_8U rows");
   pragma
     Compile_Time_Error
       (Row_Array'Component_Size /= 8,
        "UInt8 Row_Array must be tightly packed 8-bit unsigned elements");

   procedure Raise_Invalid_Access (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Access;

   procedure Validate_Borrow (Image : Mat; Row : Natural) is
   begin
      if Image.Depth /= UInt8 then
         Raise_Invalid_Access ("UInt8 row access requires a UInt8 Mat");

      elsif Image.Channels /= 1 then
         Raise_Invalid_Access
           ("typed Mat row access requires exactly one channel");

      elsif Row >= Image.Rows then
         Raise_Invalid_Access ("Mat row index is outside the valid range");
      end if;
   end Validate_Borrow;

   procedure Validate (Image : Mat; Row : Natural; Length : Natural) is
   begin
      Validate_Borrow (Image, Row);

      if Length /= Image.Columns then
         Raise_Invalid_Access
           ("typed Mat row access requires one value per Mat column");
      end if;
   end Validate;

   procedure Read_Row (Image : Mat; Row : Natural; Data : out Row_Array) is
      Buffer :
        OpenCV.Core.Internal.Typed_Access.UInt8_Row_Buffer (1 .. Data'Length);
   begin
      Validate (Image, Row, Data'Length);
      OpenCV.Core.Internal.Typed_Access.Read_UInt8_Row
        (Image, Integer (Row), Buffer);

      for Index in Data'Range loop
         Data (Index) :=
           UInt8_Value (Buffer (Index - Data'First + Buffer'First));
      end loop;
   end Read_Row;

   procedure Write_Row (Image : in out Mat; Row : Natural; Data : Row_Array) is
      Buffer :
        OpenCV.Core.Internal.Typed_Access.UInt8_Row_Buffer (1 .. Data'Length);
   begin
      Validate (Image, Row, Data'Length);

      for Index in Data'Range loop
         Buffer (Index - Data'First + Buffer'First) :=
           OpenCV.Internal.C_API.C_UInt8 (Data (Index));
      end loop;

      OpenCV.Core.Internal.Typed_Access.Write_UInt8_Row
        (Image, Integer (Row), Buffer);
   end Write_Row;

   function Expected_Logical_Row_Bytes
     (Column_Count : Natural) return OpenCV.Internal.C_API.C_UInt64
   is
      Element_Bytes : constant OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64 (UInt8_Value'Size / 8);
      Columns       : constant OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64 (Column_Count);
   begin
      pragma Assert (Element_Bytes = 1);
      return Columns * Element_Bytes;
   end Expected_Logical_Row_Bytes;

   procedure Check_Borrowed_Row
     (Borrowed     : OpenCV.Core.Internal.Row_Data.Borrowed_Row;
      Column_Count : Natural)
   is
      use type System.Address;
   begin
      if Borrowed.Byte_Count /= Expected_Logical_Row_Bytes (Column_Count) then
         Raise_Invalid_Access
           ("borrowed UInt8 row byte count does not match Mat columns");
      end if;

      if Column_Count /= 0 and then Borrowed.Address = System.Null_Address then
         Raise_Invalid_Access ("borrowed UInt8 row has no storage");
      end if;
   end Check_Borrowed_Row;

   procedure With_Read_Only_Row
     (Image   : Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased Row_Array))
   is
      Lease : constant Mat := Image;
   begin
      Validate_Borrow (Lease, Row);

      declare
         Column_Count : constant Natural := Lease.Columns;
         Borrowed     : constant OpenCV.Core.Internal.Row_Data.Borrowed_Row :=
           OpenCV.Core.Internal.Row_Data.Borrow_Row (Lease, Row);
      begin
         Check_Borrowed_Row (Borrowed, Column_Count);

         if Column_Count = 0 then
            declare
               Empty : aliased constant Row_Array := (1 .. 0 => 0);
            begin
               Process (Empty);
            end;
            return;
         end if;

         declare
            subtype Current_Row is Row_Array (0 .. Column_Count - 1);
            package Row_Conversions is new
              System.Address_To_Access_Conversions (Current_Row);
            use type Row_Conversions.Object_Pointer;

            Data : constant Row_Conversions.Object_Pointer :=
              Row_Conversions.To_Pointer (Borrowed.Address);
         begin
            if Data = null then
               Raise_Invalid_Access ("borrowed UInt8 row has no storage");
            end if;

            declare
               View : constant access constant Row_Array :=
                 Data.all'Unrestricted_Access;
            begin
               Process (View.all);
            end;
         end;
      end;
   end With_Read_Only_Row;

   procedure With_Writable_Row
     (Image   : in out Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased in out Row_Array))
   is
      Lease : constant Mat := Image;
   begin
      Validate_Borrow (Lease, Row);

      declare
         Column_Count : constant Natural := Lease.Columns;
         Borrowed     : constant OpenCV.Core.Internal.Row_Data.Borrowed_Row :=
           OpenCV.Core.Internal.Row_Data.Borrow_Row (Lease, Row);
      begin
         Check_Borrowed_Row (Borrowed, Column_Count);

         if Column_Count = 0 then
            declare
               Empty : aliased Row_Array := (1 .. 0 => 0);
            begin
               Process (Empty);
            end;
            return;
         end if;

         declare
            subtype Current_Row is Row_Array (0 .. Column_Count - 1);
            package Row_Conversions is new
              System.Address_To_Access_Conversions (Current_Row);
            use type Row_Conversions.Object_Pointer;
            Data : constant Row_Conversions.Object_Pointer :=
              Row_Conversions.To_Pointer (Borrowed.Address);
         begin
            if Data = null then
               Raise_Invalid_Access ("borrowed UInt8 row has no storage");
            end if;

            declare
               View : constant access Row_Array :=
                 Data.all'Unrestricted_Access;
            begin
               Process (View.all);
            end;
         end;
      end;
   end With_Writable_Row;

end OpenCV.Core.UInt8_Row_Access;
