package body OpenCV.Internal.Safe_Arithmetic
  with SPARK_Mode => On
is

   function Product_Exceeds_Signed_Int32 (Left, Right : Natural) return Boolean
   is (Left > 0 and then Right > 0 and then Left > Signed_Int32_Max / Right);

   function Fits_Signed_Int32 (Value : Long_Long_Integer) return Boolean
   is (Value >= Long_Long_Integer (Interfaces.Integer_32'First)
       and then Value <= Long_Long_Integer (Interfaces.Integer_32'Last));

   function To_Signed_Int32
     (Value : Long_Long_Integer) return Interfaces.Integer_32
   is (Interfaces.Integer_32 (Value));

end OpenCV.Internal.Safe_Arithmetic;
