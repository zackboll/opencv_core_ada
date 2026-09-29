with Mat_Test_Support;

package Float16_Vector_Tests.Raw_ABI is
   --  Same-byte wrong-layout rejection (4-byte and 8-byte look-alikes).
   procedure Check_Wrong_Layouts
     (Test : in out Mat_Test_Support.Mat_Test_Fixture);
   --  Null pointer and geometry rejection on exactly matching Float16 C2/C4
   --  Mats, plus exact-bit raw record and uint16_t row round trips.
   procedure Check_Geometry (Test : in out Mat_Test_Support.Mat_Test_Fixture);
end Float16_Vector_Tests.Raw_ABI;
