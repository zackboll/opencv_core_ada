--  Fixed-length, value-semantic vector with a compile-time length.
--
--  Instantiating this package fixes the element type and the number of
--  components. Vector is an ordinary Ada array: it is copied by assignment
--  and involves no allocation, ownership, or native handle.
--
--  Element_Type is the type of each component. Length is the number of
--  components and must be positive; component indices therefore range from
--  zero through Length - 1.
--  @formal Element_Type Type of each vector component.
--  @formal Length Number of components. Must be positive.

generic
   type Element_Type is private;
   Length : Positive;
package OpenCV.Core.Vectors is

   --  Zero-based component index, from 0 through Length - 1.
   subtype Component_Index is Natural range 0 .. Length - 1;

   --  Vector of Length components, indexed from zero through Length - 1.
   type Vector is array (Component_Index) of Element_Type;

end OpenCV.Core.Vectors;
