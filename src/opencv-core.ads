with Ada.Finalization;
private with OpenCV.Internal.C_API;

package OpenCV.Core is

   type Mat is tagged private;

   function Is_Empty (Self : Mat) return Boolean;

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
