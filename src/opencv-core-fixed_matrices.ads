generic
   type Element_Type is private;
   Row_Count : Positive;
   Column_Count : Positive;
package OpenCV.Core.Fixed_Matrices is

   subtype Row_Index is Natural range 0 .. Row_Count - 1;
   subtype Column_Index is Natural range 0 .. Column_Count - 1;

   type Matrix is array (Row_Index, Column_Index) of Element_Type;

end OpenCV.Core.Fixed_Matrices;
