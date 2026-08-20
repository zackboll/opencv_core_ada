with Ada.Finalization;
private with OpenCV.Internal.C_API;

--  OpenCV XML/YAML/JSON persistence for disk-backed named Mat values.
--
--  This first Persistence API opens a file as File_Storage and reads or
--  writes Mats by name. The filename extension selects the format:
--  .xml, .yml, .yaml, or .json. Gzip, memory mode, append, explicit
--  format flags, and a public FileNode API are not part of this slice.
--
--  File_Storage is limited and not copyable. Exactly one Ada object
--  owns the underlying OpenCV FileStorage, which is released when the
--  Ada object is finalized.
--
--  Write borrows the source Mat for the duration of the call and does
--  not modify it. Read_Mat returns a normal independently owned Mat
--  that remains valid after the storage is finalized. A missing name
--  raises OpenCV_Error; it is not treated as an empty Mat. An actually
--  serialized empty Mat is a present node and reads back as empty.
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

   --  Reads the named Mat. Self must be an open Read_Only storage. The
   --  result owns independent storage and does not depend on Self.
   --  A missing name raises OpenCV_Error. A present empty Mat returns
   --  an empty Mat. A node that cannot be converted to Mat raises
   --  OpenCV_Error.
   function Read_Mat (Self : File_Storage; Name : String) return Mat;

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
