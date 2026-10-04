with Mat_Test_Support;

private package Add_Subtract_Destination_Tests.Raw_ABI is
   procedure With_OpenCL_Disabled (Process : not null access procedure);
   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture);
end Add_Subtract_Destination_Tests.Raw_ABI;
