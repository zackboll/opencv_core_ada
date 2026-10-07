with Mat_Test_Support;
with OpenCV.Core;

private package Mask_Destination_Tests.Raw_ABI is
   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
   procedure UMat_Exact_Aliases
     (Test : in out Mat_Test_Support.Mat_Test_Fixture);
   procedure With_OpenCL_Disabled (Process : not null access procedure);
   procedure Copy_Special
     (Source        : OpenCV.Core.Mat;
      Source_Column : Natural;
      Destination   : in out OpenCV.Core.Mat;
      Column        : Natural);
end Mask_Destination_Tests.Raw_ABI;
