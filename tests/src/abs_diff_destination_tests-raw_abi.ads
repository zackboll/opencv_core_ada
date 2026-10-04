with Mat_Test_Support;
with OpenCV.Core;

private package Abs_Diff_Destination_Tests.Raw_ABI is
   procedure With_OpenCL_Disabled (Process : not null access procedure);
   procedure Copy_Special
     (Source        : OpenCV.Core.Mat;
      Source_Column : Natural;
      Destination   : in out OpenCV.Core.Mat;
      Column        : Natural);
   function Negative_Zero
     (Source : OpenCV.Core.Mat; Column : Natural) return Boolean;
   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
end Abs_Diff_Destination_Tests.Raw_ABI;
