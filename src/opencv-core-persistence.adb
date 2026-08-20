with Ada.Exceptions;
with Interfaces;
with Interfaces.C;
with System;

package body OpenCV.Core.Persistence is

   use type OpenCV.Internal.C_API.File_Storage_Handle;
   use type OpenCV.Internal.C_API.Status;
   use type OpenCV.Internal.C_API.C_UInt64;

   function Contains_NUL (Item : String) return Boolean is
   begin
      for Character_Value of Item loop
         if Character_Value = Character'Val (0) then
            return True;
         end if;
      end loop;

      return False;
   end Contains_NUL;

   procedure Raise_On_Error
     (Result : OpenCV.Internal.C_API.Status; Operation : String)
   is
      Known_Error : constant Boolean :=
        Result = OpenCV.Internal.C_API.Error_OpenCV
        or else Result = OpenCV.Internal.C_API.Error_Standard_CPP
        or else Result = OpenCV.Internal.C_API.Error_Unknown
        or else Result = OpenCV.Internal.C_API.Error_Invalid_Argument;
   begin
      if Result = OpenCV.Internal.C_API.Success then
         return;
      end if;

      declare
         Diagnostic  : constant String :=
           OpenCV.Internal.C_API.Last_Error_Message;
         Status_Note : constant String :=
           (if Known_Error
            then ""
            else " (unrecognized shim status" & Result'Image & ")");
      begin
         if Diagnostic'Length = 0 then
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity, Operation & " failed" & Status_Note);
         else
            Ada.Exceptions.Raise_Exception
              (OpenCV_Error'Identity,
               Operation & " failed" & Status_Note & ": " & Diagnostic);
         end if;
      end;
   end Raise_On_Error;

   function To_C_Mode
     (Mode : Storage_Mode) return OpenCV.Internal.C_API.C_Int32
   is (case Mode is
         when Read_Only  => OpenCV.Internal.C_API.Storage_Mode_Read_Only,
         when Write_Only => OpenCV.Internal.C_API.Storage_Mode_Write_Only);

   procedure Validate_Filename (Filename : String) is
   begin
      if Filename'Length = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "File_Storage filename must not be empty");
      end if;

      if Contains_NUL (Filename) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "File_Storage filename must not contain an embedded NUL");
      end if;
   end Validate_Filename;

   procedure Validate_Node_Name (Name : String) is
   begin
      if Name'Length = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, "File_Storage node name must not be empty");
      end if;

      if Contains_NUL (Name) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "File_Storage node name must not contain an embedded NUL");
      end if;
   end Validate_Node_Name;

   procedure Validate_String_Value (Value : String) is
   begin
      if Contains_NUL (Value) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "File_Storage string value must not contain an embedded NUL");
      end if;
   end Validate_String_Value;

   function To_OpenCV_Int32
     (Value : Integer) return OpenCV.Internal.C_API.C_Int32
   is
      Lowest  : constant Long_Long_Integer :=
        Long_Long_Integer (Interfaces.Integer_32'First);
      Highest : constant Long_Long_Integer :=
        Long_Long_Integer (Interfaces.Integer_32'Last);
      Wide    : constant Long_Long_Integer := Long_Long_Integer (Value);
   begin
      if Wide < Lowest or else Wide > Highest then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "File_Storage integer must fit a signed 32-bit OpenCV node");
      end if;

      return OpenCV.Internal.C_API.C_Int32 (Wide);
   end To_OpenCV_Int32;

   function From_OpenCV_Int32
     (Value : OpenCV.Internal.C_API.C_Int32) return Integer
   is
      Wide : constant Long_Long_Integer := Long_Long_Integer (Value);
   begin
      if Wide < Long_Long_Integer (Integer'First)
        or else Wide > Long_Long_Integer (Integer'Last)
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "stored File_Storage integer does not fit Ada Integer");
      end if;

      return Integer (Wide);
   end From_OpenCV_Int32;

   function To_Ada_String_Length
     (Length : OpenCV.Internal.C_API.C_UInt64) return Natural
   is
      Highest : constant OpenCV.Internal.C_API.C_UInt64 :=
        OpenCV.Internal.C_API.C_UInt64 (Natural'Last);
   begin
      if Length > Highest then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "stored File_Storage string is longer than Ada String");
      end if;

      return Natural (Length);
   end To_Ada_String_Length;

   procedure Require_Open
     (Self : File_Storage; Expected : Storage_Mode; Operation : String) is
   begin
      if not Self.Opened
        or else Self.Handle = OpenCV.Internal.C_API.Null_File_Storage_Handle
      then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires an open File_Storage");
      end if;

      if Self.Mode /= Expected then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            Operation & " requires " & Expected'Image & " File_Storage");
      end if;
   end Require_Open;

   function Open (Filename : String; Mode : Storage_Mode) return File_Storage
   is
      New_Handle : aliased OpenCV.Internal.C_API.File_Storage_Handle :=
        OpenCV.Internal.C_API.Null_File_Storage_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Filename (Filename);

      declare
         C_Filename : constant Interfaces.C.char_array :=
           Interfaces.C.To_C (Filename);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Open
             (Filename => C_Filename,
              Mode     => To_C_Mode (Mode),
              Result   => New_Handle'Access);
      end;

      Raise_On_Error (Status, "File_Storage open");

      return Result : File_Storage do
         Result.Handle := New_Handle;
         Result.Mode := Mode;
         Result.Opened := True;
      end return;
   end Open;

   procedure Write (Self : in out File_Storage; Name : String; Value : Mat) is
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Write_Only, "File_Storage write");
      Validate_Node_Name (Name);

      declare
         C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C (Name);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Write_Mat
             (Self => Self.Handle, Name => C_Name, Value => Value.Handle);
      end;

      Raise_On_Error (Status, "File_Storage write");
   end Write;

   procedure Write (Self : in out File_Storage; Name : String; Value : Integer)
   is
      Status : OpenCV.Internal.C_API.Status;
      Stored : constant OpenCV.Internal.C_API.C_Int32 :=
        To_OpenCV_Int32 (Value);
   begin
      Require_Open (Self, Write_Only, "File_Storage write");
      Validate_Node_Name (Name);

      declare
         C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C (Name);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Write_Int
             (Self => Self.Handle, Name => C_Name, Value => Stored);
      end;

      Raise_On_Error (Status, "File_Storage write");
   end Write;

   procedure Write
     (Self : in out File_Storage; Name : String; Value : Long_Float)
   is
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Write_Only, "File_Storage write");
      Validate_Node_Name (Name);

      declare
         C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C (Name);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Write_Double
             (Self  => Self.Handle,
              Name  => C_Name,
              Value => OpenCV.Internal.C_API.C_Double (Value));
      end;

      Raise_On_Error (Status, "File_Storage write");
   end Write;

   procedure Write (Self : in out File_Storage; Name : String; Value : String)
   is
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Write_Only, "File_Storage write");
      Validate_Node_Name (Name);
      Validate_String_Value (Value);

      declare
         C_Name  : constant Interfaces.C.char_array :=
           Interfaces.C.To_C (Name);
         C_Value : constant Interfaces.C.char_array :=
           Interfaces.C.To_C (Value);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Write_String
             (Self => Self.Handle, Name => C_Name, Value => C_Value);
      end;

      Raise_On_Error (Status, "File_Storage write");
   end Write;

   function Read_Mat (Self : File_Storage; Name : String) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage read");
      Validate_Node_Name (Name);

      declare
         C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C (Name);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Read_Mat
             (Self   => Self.Handle,
              Name   => C_Name,
              Result => New_Handle'Access);
      end;

      Raise_On_Error (Status, "File_Storage read");
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Read_Mat;

   function Read_Integer (Self : File_Storage; Name : String) return Integer is
      Stored : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage read");
      Validate_Node_Name (Name);

      declare
         C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C (Name);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Read_Int
             (Self => Self.Handle, Name => C_Name, Result => Stored'Access);
      end;

      Raise_On_Error (Status, "File_Storage read");
      return From_OpenCV_Int32 (Stored);
   end Read_Integer;

   function Read_Real (Self : File_Storage; Name : String) return Long_Float is
      Stored : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage read");
      Validate_Node_Name (Name);

      declare
         C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C (Name);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Read_Double
             (Self => Self.Handle, Name => C_Name, Result => Stored'Access);
      end;

      Raise_On_Error (Status, "File_Storage read");
      return Long_Float (Stored);
   end Read_Real;

   function Read_String (Self : File_Storage; Name : String) return String is
      Length : aliased OpenCV.Internal.C_API.C_UInt64 := 0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage read");
      Validate_Node_Name (Name);

      declare
         C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C (Name);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Read_String
             (Self       => Self.Handle,
              Name       => C_Name,
              Buffer     => System.Null_Address,
              Capacity   => 0,
              Out_Length => Length'Access);
      end;

      Raise_On_Error (Status, "File_Storage read");

      declare
         Ada_Length : constant Natural := To_Ada_String_Length (Length);
      begin
         if Ada_Length = 0 then
            return "";
         end if;

         declare
            Buffer :
              Interfaces.C.char_array (1 .. Interfaces.C.size_t (Ada_Length));
            Copied : aliased OpenCV.Internal.C_API.C_UInt64 := 0;
            C_Name : constant Interfaces.C.char_array :=
              Interfaces.C.To_C (Name);
         begin
            Status :=
              OpenCV.Internal.C_API.File_Storage_Read_String
                (Self       => Self.Handle,
                 Name       => C_Name,
                 Buffer     => Buffer (Buffer'First)'Address,
                 Capacity   => OpenCV.Internal.C_API.C_UInt64 (Ada_Length),
                 Out_Length => Copied'Access);
            Raise_On_Error (Status, "File_Storage read");

            if Copied /= Length then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "File_Storage read failed: string length changed");
            end if;

            return Interfaces.C.To_Ada (Buffer, Trim_Nul => False);
         end;
      end;
   end Read_String;

   overriding
   procedure Finalize (Self : in out File_Storage) is
      Old_Handle : constant OpenCV.Internal.C_API.File_Storage_Handle :=
        Self.Handle;
   begin
      Self.Handle := OpenCV.Internal.C_API.Null_File_Storage_Handle;
      Self.Opened := False;
      OpenCV.Internal.C_API.File_Storage_Destroy (Old_Handle);
   end Finalize;

end OpenCV.Core.Persistence;
