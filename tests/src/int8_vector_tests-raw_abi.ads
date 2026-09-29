with Mat_Test_Support;

package Int8_Vector_Tests.Raw_ABI is
   --  Same-byte wrong-layout rejection (2-, 3- and 4-byte look-alikes) and
   --  same-depth wrong-channel rejection for the raw Int8 C2/C3/C4 ABI.
   procedure Check_Wrong_Layouts
     (Test : in out Mat_Test_Support.Mat_Test_Fixture);
   --  Null pointer and geometry rejection on exactly matching Int8 C2/C3/C4
   --  Mats, plus exact signed raw record and int8_t row round trips.
   procedure Check_Geometry (Test : in out Mat_Test_Support.Mat_Test_Fixture);
end Int8_Vector_Tests.Raw_ABI;
