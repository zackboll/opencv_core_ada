with Ada.Exceptions;
with OpenCV.Core.Internal.Row_Data;
with OpenCV.Internal.C_API;
with System;
with System.Address_To_Access_Conversions;

package body OpenCV.Core.Internal.Typed_Continuous_Borrowing is

   use type OpenCV.Internal.C_API.C_UInt64;
   use type OpenCV.Internal.C_API.Status;

   pragma
     Compile_Time_Error
       (Expected_Element_Bits rem System.Storage_Unit /= 0,
        "typed buffer element size must be an integral number of storage"
          & " bytes");
   pragma
     Compile_Time_Error
       (Element_Type'Size /= Expected_Element_Bits,
        "typed buffer element size does not match Expected_Element_Bits");
   pragma
     Compile_Time_Error
       (Buffer_Array'Component_Size /= Expected_Element_Bits,
        "typed buffer array component size does not match"
          & " Expected_Element_Bits");
   pragma
     Compile_Time_Error
       (Element_Type'Alignment > Native_Element_Alignment,
        "typed buffer element requires stricter alignment than native Mat "
          & "storage guarantees");

   Element_Bytes : constant OpenCV.Internal.C_API.C_UInt64 :=
     OpenCV.Internal.C_API.C_UInt64
       (Expected_Element_Bits / System.Storage_Unit);

   procedure Raise_Invalid_Access (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Access;

   procedure Acquire_Borrow_Lease (Image : Mat; Lease : in out Mat) is
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Acquire_Borrow_Lease
          (Image.Handle, New_Handle'Access);
   begin
      if Status /= OpenCV.Internal.C_API.Success then
         Raise_Invalid_Access
           (Type_Name & " buffer access could not retain Mat storage");
      end if;

      OpenCV.Internal.C_API.Mat_Destroy (Lease.Handle);
      Lease.Handle := New_Handle;
   end Acquire_Borrow_Lease;

   procedure Validate_Borrow (Image : Mat) is
   begin
      if Image.Depth /= Required_Depth then
         Raise_Invalid_Access
           (Type_Name & " buffer access requires a " & Type_Name & " Mat");

      elsif Image.Channels /= Required_Channels then
         if Required_Channels = 1 then
            Raise_Invalid_Access
              ("typed Mat buffer access requires exactly one channel");
         else
            Raise_Invalid_Access
              ("typed Mat buffer access requires exactly "
               & Channel_Count'Image (Required_Channels)
               & " channels");
         end if;

      elsif Image.Total /= 0 and then not Image.Is_Continuous then
         Raise_Invalid_Access
           (Type_Name & " buffer access requires a continuous Mat");
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

   function Element_Count (Image : Mat) return Natural is
      Total : constant Mat_Size := Image.Total;
   begin
      if Total > Mat_Size (Natural'Last) then
         Raise_Invalid_Access
           (Type_Name & " buffer length exceeds the representable range");
      end if;

      return Natural (Total);
   end Element_Count;

   procedure Check_Total_Bytes (Count : Natural) is
      Elements : constant OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64 (Count);
   begin
      if Count /= 0
        and then Elements > OpenCV.Internal.C_API.C_UInt64'Last / Element_Bytes
      then
         Raise_Invalid_Access
           (Type_Name & " buffer byte count exceeds the representable range");
      end if;
   end Check_Total_Bytes;

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
           ("borrowed " & Type_Name & " buffer has no storage");
      end if;
   end Check_Borrowed_Row;

   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array))
   is
      Lease : Mat;
   begin
      Acquire_Borrow_Lease (Image, Lease);
      Validate_Borrow (Lease);

      declare
         Count : constant Natural := Element_Count (Lease);
      begin
         Check_Total_Bytes (Count);

         if Count = 0 then
            declare
               Empty : aliased Buffer_Array (1 .. 0);
               View  : constant access constant Buffer_Array :=
                 Empty'Unrestricted_Access;
            begin
               Process (View.all);
            end;
            return;
         end if;

         declare
            Borrowed : constant OpenCV.Core.Internal.Row_Data.Borrowed_Row :=
              OpenCV.Core.Internal.Row_Data.Borrow_Row (Lease, 0);
         begin
            Check_Borrowed_Row (Borrowed, Lease.Columns);

            declare
               subtype Current_Buffer is Buffer_Array (0 .. Count - 1);
               package Buffer_Conversions is new
                 System.Address_To_Access_Conversions (Current_Buffer);
               use type Buffer_Conversions.Object_Pointer;

               Data : constant Buffer_Conversions.Object_Pointer :=
                 Buffer_Conversions.To_Pointer (Borrowed.Address);
            begin
               if Data = null then
                  Raise_Invalid_Access
                    ("borrowed " & Type_Name & " buffer has no storage");
               end if;

               declare
                  View : constant access constant Buffer_Array :=
                    Data.all'Unrestricted_Access;
               begin
                  Process (View.all);
               end;
            end;
         end;
      end;
   end With_Read_Only_Buffer;

   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process : not null access procedure (Data : aliased in out Buffer_Array))
   is
      Lease : Mat;
   begin
      Acquire_Borrow_Lease (Image, Lease);
      Validate_Borrow (Lease);

      declare
         Count : constant Natural := Element_Count (Lease);
      begin
         Check_Total_Bytes (Count);

         if Count = 0 then
            declare
               Empty : aliased Buffer_Array (1 .. 0);
               View  : constant access Buffer_Array :=
                 Empty'Unrestricted_Access;
            begin
               Process (View.all);
            end;
            return;
         end if;

         declare
            Borrowed : constant OpenCV.Core.Internal.Row_Data.Borrowed_Row :=
              OpenCV.Core.Internal.Row_Data.Borrow_Row (Lease, 0);
         begin
            Check_Borrowed_Row (Borrowed, Lease.Columns);

            declare
               subtype Current_Buffer is Buffer_Array (0 .. Count - 1);
               package Buffer_Conversions is new
                 System.Address_To_Access_Conversions (Current_Buffer);
               use type Buffer_Conversions.Object_Pointer;
               Data : constant Buffer_Conversions.Object_Pointer :=
                 Buffer_Conversions.To_Pointer (Borrowed.Address);
            begin
               if Data = null then
                  Raise_Invalid_Access
                    ("borrowed " & Type_Name & " buffer has no storage");
               end if;

               declare
                  View : constant access Buffer_Array :=
                    Data.all'Unrestricted_Access;
               begin
                  Process (View.all);
               end;
            end;
         end;
      end;
   end With_Writable_Buffer;

end OpenCV.Core.Internal.Typed_Continuous_Borrowing;
