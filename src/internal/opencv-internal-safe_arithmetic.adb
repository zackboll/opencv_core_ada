package body OpenCV.Internal.Safe_Arithmetic
  with SPARK_Mode => On
is

   function Product_Exceeds_Signed_Int32 (Left, Right : Natural) return Boolean
   is (Left > 0 and then Right > 0 and then Left > Signed_Int32_Max / Right);

end OpenCV.Internal.Safe_Arithmetic;
