with OpenCV;      use OpenCV;
with OpenCV.Core; use OpenCV.Core;

procedure Numerical_Norms_Example is
   Residual   : Mat := Create (1, 3, (Float64, 1));
   Reference  : Mat := Create (1, 3, (Float64, 1));
   Descriptor : Mat := Create (1, 32, (UInt8, 1));
   Candidate  : Mat := Create (1, 32, (UInt8, 1));
begin
   Residual.Set_To (Make_Scalar (3.0));
   Reference.Set_To (Make_Scalar (1.0));
   if Difference_Norm (Residual, Reference, L1) /= 6.0 then
      raise Program_Error with "unexpected numerical residual";
   end if;
   Descriptor.Set_To (Make_Scalar (3.0));
   Candidate.Set_To (Make_Scalar (0.0));
   if Hamming_Pairwise_Norm (Descriptor, Candidate) /= 64.0
     or else Hamming_Pairwise_Norm (Descriptor, Candidate, Two_Bits) /= 32.0
   then
      raise Program_Error with "unexpected binary descriptor distance";
   end if;
end Numerical_Norms_Example;
