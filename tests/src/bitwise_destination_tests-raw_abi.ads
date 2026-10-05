with Mat_Test_Support;

private package Bitwise_Destination_Tests.Raw_ABI is
   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
   procedure With_OpenCL_Disabled (Process : not null access procedure);
end Bitwise_Destination_Tests.Raw_ABI;
