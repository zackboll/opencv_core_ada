package OpenCV.Internal.Safe_Arithmetic
  with SPARK_Mode => On
is

   Signed_Int32_Max : constant := 2_147_483_647;

   function Product_Exceeds_Signed_Int32 (Left, Right : Natural) return Boolean
   with
     Global => null,
     Post   =>
       Product_Exceeds_Signed_Int32'Result
       = (Long_Long_Integer (Left) * Long_Long_Integer (Right)
          > Long_Long_Integer (Signed_Int32_Max));

end OpenCV.Internal.Safe_Arithmetic;
