with Ada.Finalization;
private with OpenCV.Internal.C_API;

package OpenCV.Core is

   type Depth_Type is
     (UInt8, Int8, UInt16, Int16, Int32, Float32, Float64, Float16);

   subtype Channel_Count is Positive range 1 .. 512;

   type Mat_Type is record
      Depth    : Depth_Type;
      Channels : Channel_Count;
   end record;

   type Mat is tagged private;

   function Create
     (Rows, Columns : Natural; Element_Type : Mat_Type) return Mat
   with Pre => Rows <= 2_147_483_647 and then Columns <= 2_147_483_647;

   function Is_Empty (Self : Mat) return Boolean;
   function Rows (Self : Mat) return Natural;
   function Columns (Self : Mat) return Natural;
   function Channels (Self : Mat) return Channel_Count;
   function Depth (Self : Mat) return Depth_Type;

private

   type Mat is new Ada.Finalization.Controlled with record
      Handle : OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
   end record;

   overriding
   procedure Initialize (Self : in out Mat);
   overriding
   procedure Adjust (Self : in out Mat);
   overriding
   procedure Finalize (Self : in out Mat);

end OpenCV.Core;
