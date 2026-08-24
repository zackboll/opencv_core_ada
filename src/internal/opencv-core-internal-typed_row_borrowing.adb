with Ada.Exceptions;
with OpenCV.Core.Internal.Row_Data;
with OpenCV.Internal.C_API;
with System;
with System.Address_To_Access_Conversions;

package body OpenCV.Core.Internal.Typed_Row_Borrowing is

   use type OpenCV.Internal.C_API.C_UInt64;

   pragma
     Compile_Time_Error
       (Expected_Element_Bits rem System.Storage_Unit /= 0,
        "typed row element size must be an integral number of storage bytes");
   pragma
     Compile_Time_Error
       (Element_Type'Size /= Expected_Element_Bits,
        "typed row element size does not match Expected_Element_Bits");
   pragma
     Compile_Time_Error
       (Row_Array'Component_Size /= Expected_Element_Bits,
        "typed row array component size does not match Expected_Element_Bits");

   Element_Bytes : constant OpenCV.Internal.C_API.C_UInt64 :=
     OpenCV.Internal.C_API.C_UInt64
       (Expected_Element_Bits / System.Storage_Unit);

   procedure Raise_Invalid_Access (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Access;

   procedure Validate_Borrow (Image : Mat; Row : Natural) is
   begin
      if Image.Depth /= Required_Depth then
         Raise_Invalid_Access
           (Type_Name & " row access requires a " & Type_Name & " Mat");

      elsif Image.Channels /= Required_Channels then
         if Required_Channels = 1 then
            Raise_Invalid_Access
              ("typed Mat row access requires exactly one channel");
         else
            Raise_Invalid_Access
              ("typed Mat row access requires exactly "
               & Channel_Count'Image (Required_Channels)
               & " channels");
         end if;

      elsif Row >= Image.Rows then
         Raise_Invalid_Access ("Mat row index is outside the valid range");
      end if;
   end Validate_Borrow;

   function Expected_Logical_Row_Bytes
     (Column_Count : Natural) return OpenCV.Internal.C_API.C_UInt64
   is
      Columns : constant OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64 (Column_Count);
   begin
      if Column_Count /= 0
        and then Columns > OpenCV.Internal.C_API.C_UInt64'Last / Element_Bytes
      then
         Raise_Invalid_Access
           (Type_Name & " row byte count exceeds the representable range");
      end if;

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
           ("borrowed "
            & Type_Name
            & " row byte count does not match Mat columns");
      end if;

      if Column_Count /= 0 and then Borrowed.Address = System.Null_Address then
         Raise_Invalid_Access
           ("borrowed " & Type_Name & " row has no storage");
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
               Empty : aliased Row_Array (1 .. 0);
               View  : constant access constant Row_Array :=
                 Empty'Unrestricted_Access;
            begin
               Process (View.all);
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
               Raise_Invalid_Access
                 ("borrowed " & Type_Name & " row has no storage");
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
               Empty : aliased Row_Array (1 .. 0);
               View  : constant access Row_Array := Empty'Unrestricted_Access;
            begin
               Process (View.all);
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
               Raise_Invalid_Access
                 ("borrowed " & Type_Name & " row has no storage");
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

end OpenCV.Core.Internal.Typed_Row_Borrowing;
