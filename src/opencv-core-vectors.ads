generic
   type Element_Type is private;
   Length : Positive;
package OpenCV.Core.Vectors is

   subtype Component_Index is Natural range 0 .. Length - 1;

   type Vector is array (Component_Index) of Element_Type;

end OpenCV.Core.Vectors;
