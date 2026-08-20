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

   function To_C_Format
     (Format : Storage_Format) return OpenCV.Internal.C_API.C_Int32
   is (case Format is
         when XML  => OpenCV.Internal.C_API.Storage_Format_XML,
         when YAML => OpenCV.Internal.C_API.Storage_Format_YAML,
         when JSON => OpenCV.Internal.C_API.Storage_Format_JSON);

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

   procedure Validate_Memory_Text (Text : String) is
   begin
      if Text'Length = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "File_Storage memory text must not be empty");
      end if;

      if Contains_NUL (Text) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "File_Storage memory text must not contain an embedded NUL");
      end if;
   end Validate_Memory_Text;

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
        -Long_Long_Integer (Interfaces.Integer_32'Last);
      Highest : constant Long_Long_Integer :=
        Long_Long_Integer (Interfaces.Integer_32'Last);
      Wide    : constant Long_Long_Integer := Long_Long_Integer (Value);
   begin
      if Wide = Long_Long_Integer (Interfaces.Integer_32'First) then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "File_Storage cannot write -2147483648 with OpenCV 4.10");
      end if;

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
         Result.Backend := Disk;
         Result.Opened := True;
      end return;
   end Open;

   function Create_Memory (Format : Storage_Format) return File_Storage is
      New_Handle : aliased OpenCV.Internal.C_API.File_Storage_Handle :=
        OpenCV.Internal.C_API.Null_File_Storage_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Status :=
        OpenCV.Internal.C_API.File_Storage_Open_Memory_Write
          (Format => To_C_Format (Format), Result => New_Handle'Access);
      Raise_On_Error (Status, "File_Storage create memory");

      return Result : File_Storage do
         Result.Handle := New_Handle;
         Result.Mode := Write_Only;
         Result.Backend := Memory;
         Result.Opened := True;
      end return;
   end Create_Memory;

   function Open_Memory (Text : String) return File_Storage is
      New_Handle : aliased OpenCV.Internal.C_API.File_Storage_Handle :=
        OpenCV.Internal.C_API.Null_File_Storage_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Validate_Memory_Text (Text);

      declare
         C_Text : constant Interfaces.C.char_array := Interfaces.C.To_C (Text);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Open_Memory_Read
             (Text => C_Text, Result => New_Handle'Access);
      end;

      Raise_On_Error (Status, "File_Storage open memory");

      return Result : File_Storage do
         Result.Handle := New_Handle;
         Result.Mode := Read_Only;
         Result.Backend := Memory;
         Result.Opened := True;
      end return;
   end Open_Memory;

   function Close_And_Get_Text (Self : in out File_Storage) return String is
      Length : aliased OpenCV.Internal.C_API.C_UInt64 := 0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Write_Only, "File_Storage close and get text");

      if Self.Backend /= Memory then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity,
            "File_Storage close and get text requires memory-backed storage");
      end if;

      Status :=
        OpenCV.Internal.C_API.File_Storage_Finish_Memory_Write
          (Self       => Self.Handle,
           Buffer     => System.Null_Address,
           Capacity   => 0,
           Out_Length => Length'Access);
      Raise_On_Error (Status, "File_Storage close and get text");

      --  The first successful finish call has already invoked
      --  releaseAndGetString, so OpenCV storage is closed even if a
      --  later Ada allocation or copy fails.
      Self.Opened := False;

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
         begin
            Status :=
              OpenCV.Internal.C_API.File_Storage_Finish_Memory_Write
                (Self       => Self.Handle,
                 Buffer     => Buffer (Buffer'First)'Address,
                 Capacity   => OpenCV.Internal.C_API.C_UInt64 (Ada_Length),
                 Out_Length => Copied'Access);
            Raise_On_Error (Status, "File_Storage close and get text");

            if Copied /= Length then
               Ada.Exceptions.Raise_Exception
                 (OpenCV_Error'Identity,
                  "File_Storage close and get text failed: length changed");
            end if;

            return Interfaces.C.To_Ada (Buffer, Trim_Nul => False);
         end;
      end;
   end Close_And_Get_Text;

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

   procedure Begin_Named_Structure
     (Self : in out File_Storage;
      Name : String;
      Kind : OpenCV.Internal.C_API.C_Int32)
   is
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Write_Only, "File_Storage begin structure");
      Validate_Node_Name (Name);

      declare
         C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C (Name);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Begin_Structure
             (Self => Self.Handle, Name => C_Name, Kind => Kind);
      end;

      Raise_On_Error (Status, "File_Storage begin structure");
   end Begin_Named_Structure;

   procedure Begin_Unnamed_Structure
     (Self : in out File_Storage; Kind : OpenCV.Internal.C_API.C_Int32)
   is
      Status : OpenCV.Internal.C_API.Status;
      C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C ("");
   begin
      Require_Open (Self, Write_Only, "File_Storage begin structure");
      Status :=
        OpenCV.Internal.C_API.File_Storage_Begin_Structure
          (Self => Self.Handle, Name => C_Name, Kind => Kind);
      Raise_On_Error (Status, "File_Storage begin structure");
   end Begin_Unnamed_Structure;

   procedure Begin_Map (Self : in out File_Storage; Name : String) is
   begin
      Begin_Named_Structure
        (Self, Name, OpenCV.Internal.C_API.Storage_Structure_Map);
   end Begin_Map;

   procedure Begin_Map (Self : in out File_Storage) is
   begin
      Begin_Unnamed_Structure
        (Self, OpenCV.Internal.C_API.Storage_Structure_Map);
   end Begin_Map;

   procedure Begin_Sequence (Self : in out File_Storage; Name : String) is
   begin
      Begin_Named_Structure
        (Self, Name, OpenCV.Internal.C_API.Storage_Structure_Sequence);
   end Begin_Sequence;

   procedure Begin_Sequence (Self : in out File_Storage) is
   begin
      Begin_Unnamed_Structure
        (Self, OpenCV.Internal.C_API.Storage_Structure_Sequence);
   end Begin_Sequence;

   procedure End_Structure (Self : in out File_Storage) is
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Write_Only, "File_Storage end structure");
      Status := OpenCV.Internal.C_API.File_Storage_End_Structure (Self.Handle);
      Raise_On_Error (Status, "File_Storage end structure");
   end End_Structure;

   procedure Append (Self : in out File_Storage; Value : Mat) is
      Status : OpenCV.Internal.C_API.Status;
      C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C ("");
   begin
      Require_Open (Self, Write_Only, "File_Storage append");
      Status :=
        OpenCV.Internal.C_API.File_Storage_Write_Mat
          (Self => Self.Handle, Name => C_Name, Value => Value.Handle);
      Raise_On_Error (Status, "File_Storage append");
   end Append;

   procedure Append (Self : in out File_Storage; Value : Integer) is
      Status : OpenCV.Internal.C_API.Status;
      Stored : constant OpenCV.Internal.C_API.C_Int32 :=
        To_OpenCV_Int32 (Value);
      C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C ("");
   begin
      Require_Open (Self, Write_Only, "File_Storage append");
      Status :=
        OpenCV.Internal.C_API.File_Storage_Write_Int
          (Self => Self.Handle, Name => C_Name, Value => Stored);
      Raise_On_Error (Status, "File_Storage append");
   end Append;

   procedure Append (Self : in out File_Storage; Value : Long_Float) is
      Status : OpenCV.Internal.C_API.Status;
      C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C ("");
   begin
      Require_Open (Self, Write_Only, "File_Storage append");
      Status :=
        OpenCV.Internal.C_API.File_Storage_Write_Double
          (Self  => Self.Handle,
           Name  => C_Name,
           Value => OpenCV.Internal.C_API.C_Double (Value));
      Raise_On_Error (Status, "File_Storage append");
   end Append;

   procedure Append (Self : in out File_Storage; Value : String) is
      Status  : OpenCV.Internal.C_API.Status;
      C_Name  : constant Interfaces.C.char_array := Interfaces.C.To_C ("");
      C_Value : constant Interfaces.C.char_array := Interfaces.C.To_C (Value);
   begin
      Require_Open (Self, Write_Only, "File_Storage append");
      Validate_String_Value (Value);
      Status :=
        OpenCV.Internal.C_API.File_Storage_Write_String
          (Self => Self.Handle, Name => C_Name, Value => C_Value);
      Raise_On_Error (Status, "File_Storage append");
   end Append;

   procedure Enter_Named_Structure
     (Self : in out File_Storage;
      Name : String;
      Kind : OpenCV.Internal.C_API.C_Int32)
   is
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage enter structure");
      Validate_Node_Name (Name);

      declare
         C_Name : constant Interfaces.C.char_array := Interfaces.C.To_C (Name);
      begin
         Status :=
           OpenCV.Internal.C_API.File_Storage_Enter_Named_Structure
             (Self => Self.Handle, Name => C_Name, Kind => Kind);
      end;

      Raise_On_Error (Status, "File_Storage enter structure");
   end Enter_Named_Structure;

   procedure Enter_Indexed_Structure
     (Self  : in out File_Storage;
      Index : Natural;
      Kind  : OpenCV.Internal.C_API.C_Int32)
   is
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage enter structure");
      Status :=
        OpenCV.Internal.C_API.File_Storage_Enter_Indexed_Structure
          (Self  => Self.Handle,
           Index => OpenCV.Internal.C_API.C_UInt64 (Index),
           Kind  => Kind);
      Raise_On_Error (Status, "File_Storage enter structure");
   end Enter_Indexed_Structure;

   procedure Enter_Map (Self : in out File_Storage; Name : String) is
   begin
      Enter_Named_Structure
        (Self, Name, OpenCV.Internal.C_API.Storage_Structure_Map);
   end Enter_Map;

   procedure Enter_Map (Self : in out File_Storage; Index : Natural) is
   begin
      Enter_Indexed_Structure
        (Self, Index, OpenCV.Internal.C_API.Storage_Structure_Map);
   end Enter_Map;

   procedure Enter_Sequence (Self : in out File_Storage; Name : String) is
   begin
      Enter_Named_Structure
        (Self, Name, OpenCV.Internal.C_API.Storage_Structure_Sequence);
   end Enter_Sequence;

   procedure Enter_Sequence (Self : in out File_Storage; Index : Natural) is
   begin
      Enter_Indexed_Structure
        (Self, Index, OpenCV.Internal.C_API.Storage_Structure_Sequence);
   end Enter_Sequence;

   procedure Leave_Structure (Self : in out File_Storage) is
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage leave structure");
      Status :=
        OpenCV.Internal.C_API.File_Storage_Leave_Structure (Self.Handle);
      Raise_On_Error (Status, "File_Storage leave structure");
   end Leave_Structure;

   function Sequence_Length (Self : File_Storage) return Natural is
      Length : aliased OpenCV.Internal.C_API.C_UInt64 := 0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage sequence length");
      Status :=
        OpenCV.Internal.C_API.File_Storage_Sequence_Length
          (Self => Self.Handle, Out_Length => Length'Access);
      Raise_On_Error (Status, "File_Storage sequence length");
      return To_Ada_String_Length (Length);
   end Sequence_Length;

   function Read_Mat (Self : File_Storage; Index : Natural) return Mat is
      Result     : Mat;
      New_Handle : aliased OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
      Status     : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage read");
      Status :=
        OpenCV.Internal.C_API.File_Storage_Read_Mat_At
          (Self   => Self.Handle,
           Index  => OpenCV.Internal.C_API.C_UInt64 (Index),
           Result => New_Handle'Access);
      Raise_On_Error (Status, "File_Storage read");
      OpenCV.Internal.C_API.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Read_Mat;

   function Read_Integer (Self : File_Storage; Index : Natural) return Integer
   is
      Stored : aliased OpenCV.Internal.C_API.C_Int32 := 0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage read");
      Status :=
        OpenCV.Internal.C_API.File_Storage_Read_Int_At
          (Self   => Self.Handle,
           Index  => OpenCV.Internal.C_API.C_UInt64 (Index),
           Result => Stored'Access);
      Raise_On_Error (Status, "File_Storage read");
      return From_OpenCV_Int32 (Stored);
   end Read_Integer;

   function Read_Real (Self : File_Storage; Index : Natural) return Long_Float
   is
      Stored : aliased OpenCV.Internal.C_API.C_Double := 0.0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage read");
      Status :=
        OpenCV.Internal.C_API.File_Storage_Read_Double_At
          (Self   => Self.Handle,
           Index  => OpenCV.Internal.C_API.C_UInt64 (Index),
           Result => Stored'Access);
      Raise_On_Error (Status, "File_Storage read");
      return Long_Float (Stored);
   end Read_Real;

   function Read_String (Self : File_Storage; Index : Natural) return String is
      Length : aliased OpenCV.Internal.C_API.C_UInt64 := 0;
      Status : OpenCV.Internal.C_API.Status;
   begin
      Require_Open (Self, Read_Only, "File_Storage read");
      Status :=
        OpenCV.Internal.C_API.File_Storage_Read_String_At
          (Self       => Self.Handle,
           Index      => OpenCV.Internal.C_API.C_UInt64 (Index),
           Buffer     => System.Null_Address,
           Capacity   => 0,
           Out_Length => Length'Access);
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
         begin
            Status :=
              OpenCV.Internal.C_API.File_Storage_Read_String_At
                (Self       => Self.Handle,
                 Index      => OpenCV.Internal.C_API.C_UInt64 (Index),
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
