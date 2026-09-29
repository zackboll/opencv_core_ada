with Ada.Finalization;
private with OpenCV.Internal.C_API;

package OpenCV.Core.Sparse is
   type Sparse_Mat is tagged private;

   function Create
     (Shape : Dimension_Array; Element_Type : Mat_Type) return Sparse_Mat;
   function From_Dense (Source : Mat) return Sparse_Mat;
   function To_Dense (Self : Sparse_Mat) return Mat;
   function Clone (Self : Sparse_Mat) return Sparse_Mat;
   procedure Clear (Self : in out Sparse_Mat);
   function Is_Allocated (Self : Sparse_Mat) return Boolean;
   function Dimension_Count (Self : Sparse_Mat) return Natural;
   function Shape (Self : Sparse_Mat) return Dimension_Array;
   function Extent (Self : Sparse_Mat; Axis : Positive) return Size_Coordinate;
   function Depth (Self : Sparse_Mat) return Depth_Type;
   function Channels (Self : Sparse_Mat) return Channel_Count;
   function Element_Size (Self : Sparse_Mat) return Mat_Size;
   function Channel_Size (Self : Sparse_Mat) return Mat_Size;
   function Stored_Element_Count (Self : Sparse_Mat) return Mat_Size;
   function Contains (Self : Sparse_Mat; Indices : Index_Array) return Boolean;
   procedure Erase (Self : in out Sparse_Mat; Indices : Index_Array);

private
   type Sparse_Mat is new Ada.Finalization.Controlled with record
      Handle : OpenCV.Internal.C_API.Sparse_Mat_Handle :=
        OpenCV.Internal.C_API.Null_Sparse_Mat_Handle;
   end record;
   overriding
   procedure Initialize (Self : in out Sparse_Mat);
   overriding
   procedure Adjust (Self : in out Sparse_Mat);
   overriding
   procedure Finalize (Self : in out Sparse_Mat);

   procedure Check_Indices (Self : Sparse_Mat; Indices : Index_Array);
   procedure Check_Layout
     (Self : Sparse_Mat; Indices : Index_Array; Expected : Depth_Type);
   function C_Indices
     (Indices : Index_Array) return OpenCV.Internal.C_API.C_Int32_Array;
   procedure Check (Status : OpenCV.Internal.C_API.Status; Operation : String);
end OpenCV.Core.Sparse;
