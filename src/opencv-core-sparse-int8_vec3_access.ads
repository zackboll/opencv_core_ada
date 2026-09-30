with OpenCV.Core.Int8_Vec3;

--  Typed access to one complete CV_8SC3 SparseMat element. Components are
--  OpenCV channel indices 0 .. 2; no semantic meaning is assigned.
package OpenCV.Core.Sparse.Int8_Vec3_Access is
   --  Missing nodes read as an all-zero vector and are not created.
   function Get
     (Image : Sparse_Mat; Indices : Index_Array)
      return OpenCV.Core.Int8_Vec3.Vector;
   --  Inserts the node if absent; an all-zero vector is still stored.
   procedure Set
     (Image   : in out Sparse_Mat;
      Indices : Index_Array;
      Value   : OpenCV.Core.Int8_Vec3.Vector);
   --  Stored nodes only; unspecified order; values are copies.
   --  Do not structurally mutate Image or aliases during callbacks.
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure
          (Indices : Index_Array; Value : OpenCV.Core.Int8_Vec3.Vector));
end OpenCV.Core.Sparse.Int8_Vec3_Access;
