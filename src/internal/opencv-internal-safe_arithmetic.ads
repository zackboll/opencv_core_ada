with Interfaces;

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

   function Fits_Signed_Int32 (Value : Long_Long_Integer) return Boolean
   with
     Global => null,
     Post   =>
       Fits_Signed_Int32'Result
       = (Value >= Long_Long_Integer (Interfaces.Integer_32'First)
          and then Value <= Long_Long_Integer (Interfaces.Integer_32'Last));

   function To_Signed_Int32
     (Value : Long_Long_Integer) return Interfaces.Integer_32
   with
     Global => null,
     Pre    => Fits_Signed_Int32 (Value),
     Post   => Long_Long_Integer (To_Signed_Int32'Result) = Value;

end OpenCV.Internal.Safe_Arithmetic;
