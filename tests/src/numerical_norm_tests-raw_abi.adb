with AUnit.Assertions; use AUnit.Assertions;
with OpenCV.Internal.C_API;

package body Numerical_Norm_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type C.C_Double;
   use type C.C_Int32;
   procedure Run (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      A, B  : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Value : aliased C.C_Double := 91.0;
      procedure Bad (Status : C.Status) is
      begin
         Assert (Status /= C.Success, "invalid raw ABI rejected");
         Assert (Value = 0.0, "failure initializes result");
         Assert (C.Last_Error_Message'Length > 0, "useful raw diagnostic");
         Value := 91.0;
      end Bad;
   begin
      Assert (C.Mat_Create_2D (2, 3, 0, 1, A'Access) = C.Success, "raw A");
      Assert (C.Mat_Create_2D (3, 2, 0, 1, B'Access) = C.Success, "raw B");
      Bad
        (C.Mat_Numeric_Norm
           (C.Null_Mat_Handle, C.Null_Mat_Handle, 4, Value'Access));
      Bad (C.Mat_Numeric_Norm (A, C.Null_Mat_Handle, 99, Value'Access));
      Assert
        (C.Mat_Numeric_Norm (A, C.Null_Mat_Handle, 4, null)
         = C.Error_Invalid_Argument,
         "null output status");
      Bad
        (C.Mat_Difference_Norm
           (A, C.Null_Mat_Handle, C.Null_Mat_Handle, 2, 0, Value'Access));
      Bad
        (C.Mat_Difference_Norm (A, A, C.Null_Mat_Handle, -1, 0, Value'Access));
      Bad
        (C.Mat_Difference_Norm (A, A, C.Null_Mat_Handle, 2, 2, Value'Access));
      Bad
        (C.Mat_Difference_Norm (A, A, C.Null_Mat_Handle, 4, 1, Value'Access));
      Bad
        (C.Mat_Difference_Norm (A, B, C.Null_Mat_Handle, 2, 0, Value'Access));
      Bad (C.Mat_Numeric_Norm (A, B, 4, Value'Access));
      Bad (C.Mat_Binary_Norm (A, 3, Value'Access));
      Bad (C.Mat_Binary_Difference_Norm (A, B, 0, Value'Access));
      Assert
        (C.Mat_Binary_Norm (A, 1, null) = C.Error_Invalid_Argument,
         "null binary output");
      Assert
        (C.Mat_Difference_Norm (A, A, C.Null_Mat_Handle, 2, 0, Value'Access)
         = C.Success,
         "success after errors");
      Assert (C.Last_Error_Message'Length = 0, "error cleared on success");
      C.Mat_Destroy (A);
      C.Mat_Destroy (B);
   exception
      when others =>
         C.Mat_Destroy (A);
         C.Mat_Destroy (B);
         raise;
   end Run;
end Numerical_Norm_Tests.Raw_ABI;
