with OpenCV.Core.UInt8_Vec2;

--  Typed access to one complete CV_8UC2 SparseMat element. Components are
--  OpenCV channel indices 0 .. 1; no semantic meaning is assigned.
package OpenCV.Core.Sparse.UInt8_Vec2_Access is
   --  Missing nodes read as an all-zero vector and are not created.
   function Get
     (Image : Sparse_Mat; Indices : Index_Array)
      return OpenCV.Core.UInt8_Vec2.Vector;
   --  Inserts the node if absent; an all-zero vector is still stored.
   procedure Set
     (Image   : in out Sparse_Mat;
      Indices : Index_Array;
      Value   : OpenCV.Core.UInt8_Vec2.Vector);
   --  Stored nodes only; unspecified order; values are copies.
   --  Do not structurally mutate Image or aliases during callbacks.
   procedure For_Each_Stored
     (Image   : Sparse_Mat;
      Process :
        not null access procedure
          (Indices : Index_Array; Value : OpenCV.Core.UInt8_Vec2.Vector));
end OpenCV.Core.Sparse.UInt8_Vec2_Access;
