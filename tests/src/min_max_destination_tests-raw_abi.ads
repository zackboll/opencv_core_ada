with Mat_Test_Support;
with OpenCV.Core;

private package Min_Max_Destination_Tests.Raw_ABI is
   procedure With_OpenCL_Disabled (Process : not null access procedure);
   procedure Copy_Special
     (Source        : OpenCV.Core.Mat;
      Source_Column : Natural;
      Destination   : in out OpenCV.Core.Mat;
      Column        : Natural);
   function Negative_Zero
     (Source : OpenCV.Core.Mat; Row, Column : Natural) return Boolean;
   function Native_Expected
     (Left, Right          : OpenCV.Core.Mat;
      Op                   : Operation_Kind;
      Right_Alias, Is_UMat : Boolean) return OpenCV.Core.Mat;
   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
end Min_Max_Destination_Tests.Raw_ABI;
