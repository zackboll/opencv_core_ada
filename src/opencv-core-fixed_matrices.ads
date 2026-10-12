--  Fixed-size, value-semantic matrix with compile-time dimensions.
--
--  Instantiating this package fixes the element type and both dimensions.
--  Matrix is an ordinary Ada array: it is copied by assignment and involves
--  no allocation, ownership, or native handle. Indices are zero-based and
--  elements are addressed as (Row, Column). This describes logical indexing
--  only; no native memory layout is implied.
--
--  Element_Type is the type of each element. Row_Count and Column_Count are
--  the dimensions and must be positive; valid row indices are 0 through
--  Row_Count - 1 and valid column indices are 0 through Column_Count - 1.
--  @formal Element_Type Type of each matrix element.
--  @formal Row_Count Number of rows. Must be positive.
--  @formal Column_Count Number of columns. Must be positive.

generic
   type Element_Type is private;
   Row_Count : Positive;
   Column_Count : Positive;
package OpenCV.Core.Fixed_Matrices is

   --  Zero-based row index, from 0 through Row_Count - 1.
   subtype Row_Index is Natural range 0 .. Row_Count - 1;

   --  Zero-based column index, from 0 through Column_Count - 1.
   subtype Column_Index is Natural range 0 .. Column_Count - 1;

   --  Matrix of Row_Count rows and Column_Count columns. Element (Row,
   --  Column) is addressed with zero-based indices in the ranges Row_Index
   --  and Column_Index. Row_Index'Range and Column_Index'Range are the
   --  array bounds.
   type Matrix is array (Row_Index, Column_Index) of Element_Type;

end OpenCV.Core.Fixed_Matrices;
