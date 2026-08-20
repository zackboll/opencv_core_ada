with Ada.Finalization;
private with OpenCV.Internal.C_API;

--  OpenCV XML/YAML/JSON persistence for named values.
--
--  File_Storage reads or writes named Mat, Integer, Long_Float, and
--  String values. Disk Open selects the format from the filename
--  extension: .xml, .yml, .yaml, or .json. Create_Memory writes to an
--  in-memory buffer in an explicit XML, YAML, or JSON format.
--  Open_Memory reads a previously serialized document and lets OpenCV
--  auto-detect the format from the text. Gzip, append, explicit disk
--  format flags, maps, sequences, comments, and a public FileNode API
--  are not part of this slice.
--
--  File_Storage is limited and not copyable. Exactly one Ada object
--  owns the underlying OpenCV FileStorage, which is released when the
--  Ada object is finalized.
--
--  Write borrows the source value for the duration of the call and does
--  not modify it. Read operations return independently owned Ada values
--  that remain valid after the storage is finalized. A missing name
--  raises OpenCV_Error. Stored 0, 0.0, empty String, and empty Mat
--  values are present nodes and remain distinguishable from absence.
--
--  Integer persistence uses OpenCV's signed 32-bit integer file node.
--  Write rejects an Ada Integer outside that domain with OpenCV_Error
--  rather than leaking Constraint_Error from a narrowing conversion.
--  With OpenCV 4.10, Write cannot persist -2_147_483_648 because
--  OpenCV's integer formatter uses abs(int); the supported write range
--  is -2_147_483_647 .. 2_147_483_647. This is an OpenCV 4.10 writer
--  limitation, not an Ada or file-format limitation.
--  Read_Integer requires an actual integer node and does not round a
--  real node.
--
--  Long_Float is persisted through OpenCV double. Read_Real accepts a
--  real node or safely widens an integer node to Long_Float. Other
--  node types are rejected.
--
--  Read_String requires an actual string node and does not stringify
--  numeric values. OpenCV 4.10 persistence emitters measure string
--  values with strlen, so Write rejects an embedded NUL in a String
--  value. Node names, filenames, and memory-read text also reject
--  embedded NUL because they cross a NUL-terminated ABI. OpenCV 4.10
--  memory-read measures the document with strlen.
--
--  Close_And_Get_Text finalizes a memory Write_Only storage and
--  returns the complete serialized document as an independently owned
--  Ada String. The storage is then closed. Disk storage and memory
--  readers reject Close_And_Get_Text.
--
--  Non-contiguous Mats are supported.

package OpenCV.Core.Persistence is

   type Storage_Mode is (Read_Only, Write_Only);

   type Storage_Format is (XML, YAML, JSON);

   type File_Storage is new Ada.Finalization.Limited_Controlled with private;

   --  Opens Filename for reading or writing. Format is selected from
   --  the filename extension. Raises OpenCV_Error if Filename is empty,
   --  contains an embedded NUL, or cannot be opened.
   function Open (Filename : String; Mode : Storage_Mode) return File_Storage;

   --  Creates an open Write_Only memory-backed File_Storage that
   --  serializes to Format. No file is created. Existing Write
   --  operations work unchanged. Close_And_Get_Text returns the
   --  serialized document and closes the storage.
   function Create_Memory (Format : Storage_Format) return File_Storage;

   --  Opens Text as a Read_Only memory-backed File_Storage. OpenCV
   --  4.10 auto-detects XML, YAML, or JSON from the contents. Raises
   --  OpenCV_Error if Text is empty, contains an embedded NUL, or
   --  cannot be parsed.
   function Open_Memory (Text : String) return File_Storage;

   --  Finalizes an open memory Write_Only File_Storage, releases the
   --  OpenCV writer, and returns the complete serialized document.
   --  Self becomes closed on a successful first finish even if a later
   --  Ada conversion fails. Subsequent Write, Read, and
   --  Close_And_Get_Text calls raise OpenCV_Error. Disk storage and
   --  memory readers raise OpenCV_Error. The returned String does not
   --  depend on Self.
   function Close_And_Get_Text (Self : in out File_Storage) return String;

   --  Writes Value under Name. Self must be an open Write_Only storage.
   --  Value is borrowed and is not modified. Empty and non-contiguous
   --  Mats are accepted. Raises OpenCV_Error if Self is not open for
   --  writing or if Name is empty or contains an embedded NUL.
   procedure Write (Self : in out File_Storage; Name : String; Value : Mat);

   --  Writes Value as an OpenCV signed 32-bit integer node. With
   --  OpenCV 4.10, Value must be in -2_147_483_647 .. 2_147_483_647
   --  because OpenCV formats integers with abs(int). Raises
   --  OpenCV_Error if Value is outside that write domain, if Self is
   --  not open for writing, or if Name is empty or contains an
   --  embedded NUL.
   procedure Write
     (Self : in out File_Storage; Name : String; Value : Integer);

   --  Writes Value as an OpenCV double node. Raises OpenCV_Error if
   --  Self is not open for writing or if Name is empty or contains an
   --  embedded NUL.
   procedure Write
     (Self : in out File_Storage; Name : String; Value : Long_Float);

   --  Writes Value as an OpenCV string node. Raises OpenCV_Error if
   --  Value contains an embedded NUL, if Self is not open for writing,
   --  or if Name is empty or contains an embedded NUL.
   procedure Write (Self : in out File_Storage; Name : String; Value : String);

   --  Reads the named Mat. Self must be an open Read_Only storage. The
   --  result owns independent storage and does not depend on Self.
   --  A missing name raises OpenCV_Error. A present empty Mat returns
   --  an empty Mat. A node that cannot be converted to Mat raises
   --  OpenCV_Error.
   function Read_Mat (Self : File_Storage; Name : String) return Mat;

   --  Reads the named signed 32-bit integer node. A real, string, Mat,
   --  or missing node raises OpenCV_Error. The exact stored integer is
   --  returned.
   function Read_Integer (Self : File_Storage; Name : String) return Integer;

   --  Reads the named real node, or widens a named integer node to
   --  Long_Float. A string, Mat, or missing node raises OpenCV_Error.
   function Read_Real (Self : File_Storage; Name : String) return Long_Float;

   --  Reads the named string node. Numeric, Mat, and missing nodes
   --  raise OpenCV_Error. An actually stored empty string is returned
   --  as "".
   function Read_String (Self : File_Storage; Name : String) return String;

private

   type Storage_Backend is (Disk, Memory);

   type File_Storage is new Ada.Finalization.Limited_Controlled with record
      Handle  : OpenCV.Internal.C_API.File_Storage_Handle :=
        OpenCV.Internal.C_API.Null_File_Storage_Handle;
      Mode    : Storage_Mode := Read_Only;
      Backend : Storage_Backend := Disk;
      Opened  : Boolean := False;
   end record;

   overriding
   procedure Finalize (Self : in out File_Storage);

end OpenCV.Core.Persistence;
