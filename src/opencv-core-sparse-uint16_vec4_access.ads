with OpenCV.Core.UInt16_Vec4;

--  Typed access to one complete CV_16UC4 SparseMat element. Components are
--  OpenCV channel indices 0 .. 3; no semantic meaning is assigned.
package OpenCV.Core.Sparse.UInt16_Vec4_Access is
   --  Missing nodes read as an all-zero vector and are not created.
   function Get
     (Image : Sparse_Mat; Indices : Index_Array)
      return OpenCV.Core.UInt16_Vec4.Vector;
   --  Inserts the node if absent; an all-zero vector is still stored.
   procedure Set
     (Image   : in out Sparse_Mat;
      Indices : Index_Array;
      Value   : OpenCV.Core.UInt16_Vec4.Vector);
   --  Stored nodes only; unspecified order; values are copies.
   --  Do not structurally mutate Image or aliases during callbacks.
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure
          (Indices : Index_Array; Value : OpenCV.Core.UInt16_Vec4.Vector));
end OpenCV.Core.Sparse.UInt16_Vec4_Access;
