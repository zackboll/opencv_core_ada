with AUnit.Assertions;
with Interfaces;
with OpenCV.Internal.C_API;

package body Unary_Math_Destination_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use AUnit.Assertions;
   use type C.Status;
   use type C.C_Float64;
   use type Interfaces.Unsigned_8;
   function Use_OpenCL return Interfaces.Unsigned_8
   with Import, Convention => C, External_Name => "umat_probe_use_opencl";
   function Set_OpenCL
     (Enabled : Interfaces.Unsigned_8) return Interfaces.Unsigned_8
   with Import, Convention => C, External_Name => "umat_probe_set_opencl";
   procedure With_OpenCL_Disabled (Process : not null access procedure) is
      Previous : constant Interfaces.Unsigned_8 := Use_OpenCL;
      Success  : Interfaces.Unsigned_8;
   begin
      Success := Set_OpenCL (0);
      Assert (Success = 1, "disable OpenCL");
      Process.all;
      Success := Set_OpenCL (Previous);
      Assert (Success = 1, "restore OpenCL");
   exception
      when others =>
         Success := Set_OpenCL (Previous);
         raise;
   end With_OpenCL_Disabled;
   procedure OK (Status : C.Status) is
   begin
      Assert (Status = C.Success, C.Last_Error_Message);
   end OK;
   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      A, D, External : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Value          : aliased C.Scalar := (91.0, 91.0, 91.0, 91.0);
      Data           : aliased array (0 .. 9) of C.C_Float64 :=
        (others => 91.0);
      Pixel          : aliased C.C_Float64;
      function Into (Op : Operation; S, Dest : C.Mat_Handle) return C.Status is
      begin
         case Op is
            when Square_Root     =>
               return C.Mat_Sqrt_Into (S, Dest);

            when Exponential     =>
               return C.Mat_Exp_Into (S, Dest);

            when Logarithm       =>
               return C.Mat_Log_Into (S, Dest);

            when Power_Operation =>
               return C.Mat_Pow_Into (S, 2.0, Dest);
         end case;
      end Into;
      procedure Cleanup is
      begin
         C.Mat_Destroy (External);
         C.Mat_Destroy (D);
         C.Mat_Destroy (A);
      end Cleanup;
   begin
      OK (C.Mat_Create_2D (2, 3, 6, 1, A'Access));
      OK (C.Mat_Create_2D (2, 3, 6, 1, D'Access));
      OK (C.Mat_Set_To (D, Value'Access));
      OK
        (C.Mat_Create_External_2D_Strided
           (2, 3, 6, 1, Data'Address, 80, 40, External'Access));
      for Op in Operation loop
         Assert
           (Into (Op, C.Null_Mat_Handle, D) = C.Error_Invalid_Argument,
            "raw null source");
         Assert
           (Into (Op, A, C.Null_Mat_Handle) = C.Error_Invalid_Argument,
            "raw null destination");
         Assert
           (Into (Op, A, External) = C.Error_Invalid_Argument,
            "raw temporary destination");
         for R in C.C_Int32 range 0 .. 1 loop
            for Col in C.C_Int32 range 0 .. 2 loop
               OK (C.Mat_Get_Float64 (D, R, Col, Pixel'Access));
               Assert (Pixel = 91.0, "raw pre-native preservation");
            end loop;
         end loop;
         for V of Data loop
            Assert (V = 91.0, "external logical data and padding");
         end loop;
      end loop;
      C.Mat_Destroy (A);
      OK (C.Mat_Create_2D (2, 3, 0, 1, A'Access));
      Assert
        (C.Mat_Exp_Into (A, D) = C.Error_OpenCV,
         "native exception translated to status");
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end Mat_Check;
   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      A, D  : aliased C.UMat_Handle := C.Null_UMat_Handle;
      H     : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Value : aliased C.Scalar := (91.0, 91.0, 91.0, 91.0);
      Pixel : aliased C.C_Float64;
      function Into (Op : Operation; S, Dest : C.UMat_Handle) return C.Status
      is
      begin
         case Op is
            when Square_Root     =>
               return C.UMat_Sqrt_Into (S, Dest);

            when Exponential     =>
               return C.UMat_Exp_Into (S, Dest);

            when Logarithm       =>
               return C.UMat_Log_Into (S, Dest);

            when Power_Operation =>
               return C.UMat_Pow_Into (S, 2.0, Dest);
         end case;
      end Into;
      procedure Cleanup is
      begin
         C.Mat_Destroy (H);
         C.UMat_Destroy (D);
         C.UMat_Destroy (A);
      end Cleanup;
   begin
      OK (C.UMat_Create_2D (2, 3, 6, 1, A'Access));
      OK (C.UMat_Create_2D (2, 3, 6, 1, D'Access));
      OK (C.UMat_Set_To (D, Value'Access));
      for Op in Operation loop
         Assert
           (Into (Op, C.Null_UMat_Handle, D) = C.Error_Invalid_Argument,
            "raw null source");
         Assert
           (Into (Op, A, C.Null_UMat_Handle) = C.Error_Invalid_Argument,
            "raw null destination");
      end loop;
      OK (C.UMat_To_Mat (D, H'Access));
      for R in C.C_Int32 range 0 .. 1 loop
         for Col in C.C_Int32 range 0 .. 2 loop
            OK (C.Mat_Get_Float64 (H, R, Col, Pixel'Access));
            Assert (Pixel = 91.0, "raw UMat preservation");
         end loop;
      end loop;
      C.UMat_Destroy (A);
      OK (C.UMat_Create_2D (2, 3, 0, 1, A'Access));
      Assert
        (C.UMat_Log_Into (A, D) = C.Error_OpenCV,
         "native UMat exception translated to status");
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end UMat_Check;
end Unary_Math_Destination_Tests.Raw_ABI;
