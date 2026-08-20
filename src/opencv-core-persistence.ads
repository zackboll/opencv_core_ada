with Ada.Finalization;
private with OpenCV.Internal.C_API;

--  OpenCV XML/YAML/JSON persistence for disk-backed named values.
--
--  File_Storage opens a file and reads or writes named Mat, Integer,
--  Long_Float, and String values. The filename extension selects the
--  format: .xml, .yml, .yaml, or .json. Gzip, memory mode, append,
--  explicit format flags, maps, sequences, comments, and a public
--  FileNode API are not part of this slice.
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
--  value. Node names and filenames also reject embedded NUL because
--  they cross the NUL-terminated path/name ABI.
--
--  Non-contiguous Mats are supported.

package OpenCV.Core.Persistence is

   type Storage_Mode is (Read_Only, Write_Only);

   type File_Storage is new Ada.Finalization.Limited_Controlled with private;

   --  Opens Filename for reading or writing. Format is selected from
   --  the filename extension. Raises OpenCV_Error if Filename is empty,
   --  contains an embedded NUL, or cannot be opened.
   function Open (Filename : String; Mode : Storage_Mode) return File_Storage;

   --  Writes Value under Name. Self must be an open Write_Only storage.
   --  Value is borrowed and is not modified. Empty and non-contiguous
   --  Mats are accepted. Raises OpenCV_Error if Self is not open for
   --  writing or if Name is empty or contains an embedded NUL.
   procedure Write (Self : in out File_Storage; Name : String; Value : Mat);

   --  Writes Value as an OpenCV signed 32-bit integer node. Raises
   --  OpenCV_Error if Value is outside that domain, if Self is not
   --  open for writing, or if Name is empty or contains an embedded
   --  NUL.
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

   type File_Storage is new Ada.Finalization.Limited_Controlled with record
      Handle : OpenCV.Internal.C_API.File_Storage_Handle :=
        OpenCV.Internal.C_API.Null_File_Storage_Handle;
      Mode   : Storage_Mode := Read_Only;
      Opened : Boolean := False;
   end record;

   overriding
   procedure Finalize (Self : in out File_Storage);

end OpenCV.Core.Persistence;
