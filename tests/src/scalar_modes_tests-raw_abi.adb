with AUnit.Assertions; use AUnit.Assertions;
with OpenCV.Internal.C_API;

package body Scalar_Modes_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type C.Mat_Handle;
   use type C.C_Int32;
   procedure Run (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source, Destination, Output : aliased C.Mat_Handle := C.Null_Mat_Handle;
      V                           : aliased C.Scalar := (2.0, 3.0, 4.0, 5.0);
      procedure Bad (Status : C.Status) is
      begin
         Assert (Status /= C.Success, "raw invalid argument rejected");
         Assert (C.Last_Error_Message'Length > 0, "raw useful diagnostic");
      end Bad;
   begin
      Assert
        (C.Mat_Create_2D (2, 3, 0, 1, Source'Access) = C.Success,
         "raw source");
      Assert
        (C.Mat_Create (Destination'Access) = C.Success, "raw empty output");
      for Op in C.C_Int32 range 0 .. 5 loop
         Output := Source;
         Bad
           (C.Mat_Scalar_Arithmetic
              (C.Null_Mat_Handle, V'Access, Op, Output'Access));
         Assert (Output = C.Null_Mat_Handle, "failed output initialized");
         Bad (C.Mat_Scalar_Arithmetic (Source, null, Op, Output'Access));
         Bad (C.Mat_Scalar_Arithmetic (Source, V'Access, Op, null));
         Bad
           (C.Mat_Scalar_Arithmetic_Into
              (Source, V'Access, Op, C.Null_Mat_Handle));
         Bad (C.Mat_Scalar_Arithmetic_Into (Source, null, Op, Destination));
      end loop;
      Bad (C.Mat_Scalar_Arithmetic (Source, V'Access, -1, Output'Access));
      Bad (C.Mat_Scalar_Arithmetic_Into (Source, V'Access, 99, Destination));
      Bad (C.Mat_Compare_Scalar (Source, 1.5, 99, Output'Access));
      Assert (Output = C.Null_Mat_Handle, "compare output initialized");
      Bad (C.Mat_Compare_Scalar (C.Null_Mat_Handle, 1.5, 0, Output'Access));
      Bad (C.Mat_Compare_Scalar (Source, 1.5, 0, null));
      Bad (C.Mat_Compare_Scalar_Into (Source, 1.5, 0, C.Null_Mat_Handle));
      Assert
        (C.Mat_Scalar_Arithmetic_Into (Source, V'Access, 0, Destination)
         = C.Success,
         "default output is valid and reallocatable");
      declare
         Half : aliased C.Mat_Handle := C.Null_Mat_Handle;
      begin
         Assert
           (C.Mat_Create_2D (1, 1, 7, 1, Half'Access) = C.Success,
            "half storage exists");
         Bad (C.Mat_Scalar_Arithmetic (Half, V'Access, 0, Output'Access));
         Assert (Output = C.Null_Mat_Handle, "unsafe dispatch output reset");
         Bad (C.Mat_Compare_Scalar (Half, 2.0, 0, Output'Access));
         C.Mat_Destroy (Half);
      end;
      C.Mat_Destroy (Destination);
      C.Mat_Destroy (Source);
   exception
      when others =>
         C.Mat_Destroy (Destination);
         C.Mat_Destroy (Source);
         raise;
   end Run;
end Scalar_Modes_Tests.Raw_ABI;
