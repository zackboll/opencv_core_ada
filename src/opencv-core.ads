with Ada.Finalization;
with Interfaces;
private with OpenCV.Internal.C_API;

package OpenCV.Core is

   type Depth_Type is
     (UInt8, Int8, UInt16, Int16, Int32, Float32, Float64, Float16);

   subtype Channel_Count is Positive range 1 .. 512;

   --  CV_8U and CV_32F element value domains used by typed Mat accessors.
   subtype UInt8_Value is Interfaces.Unsigned_8;
   subtype Float32_Value is Interfaces.IEEE_Float_32;

   type Mat_Type is record
      Depth    : Depth_Type;
      Channels : Channel_Count;
   end record;

   type Scalar is record
      Component_0 : Long_Float := 0.0;
      Component_1 : Long_Float := 0.0;
      Component_2 : Long_Float := 0.0;
      Component_3 : Long_Float := 0.0;
   end record;

   function Make_Scalar
     (Component_0 : Long_Float;
      Component_1 : Long_Float := 0.0;
      Component_2 : Long_Float := 0.0;
      Component_3 : Long_Float := 0.0) return Scalar;

   type Mat is tagged private;

   function Create
     (Rows, Columns : Natural; Element_Type : Mat_Type) return Mat
   with Pre => Rows <= 2_147_483_647 and then Columns <= 2_147_483_647;

   function Clone (Self : Mat) return Mat;
   function Is_Empty (Self : Mat) return Boolean;
   function Rows (Self : Mat) return Natural;
   function Columns (Self : Mat) return Natural;
   function Channels (Self : Mat) return Channel_Count;
   function Depth (Self : Mat) return Depth_Type;
   procedure Set_To (Self : in out Mat; Value : Scalar);
   function Sum (Self : Mat) return Scalar;

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
