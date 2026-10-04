with Mat_Test_Support;
with OpenCV.Core;

private package Weighted_Destination_Tests.Raw_ABI is
   procedure With_OpenCL_Disabled (Process : not null access procedure);
   function OpenCL_Enabled return Boolean;
   function Native_Expected
     (Left, Right        : OpenCV.Core.Mat;
      Op                 : Operation_Kind;
      Alias_Mode         : Natural;
      Is_UMat            : Boolean;
      Alpha, Beta, Gamma : Long_Float) return OpenCV.Core.Mat;
   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
end Weighted_Destination_Tests.Raw_ABI;
