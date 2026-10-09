with AUnit.Assertions;
with Interfaces;
with OpenCV.Internal.C_API;

package body Magnitude_Phase_Destination_Tests.Raw_ABI is
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
      X, Y, P, D, E : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Guard         : aliased C.Scalar := (others => 91.0);
      Data          : aliased array (0 .. 9) of C.C_Float64 :=
        (others => 91.0);
      V             : aliased C.C_Float64;
      function Into
        (Phase : Boolean; A, B, Dest : C.Mat_Handle; Flag : C.C_Boolean := 0)
         return C.Status is
      begin
         if Phase then
            return C.Mat_Phase_Into (A, B, Flag, Dest);
         else
            return C.Mat_Magnitude_Into (A, B, Dest);
         end if;
      end Into;
      procedure Cleanup is
      begin
         C.Mat_Destroy (E);
         C.Mat_Destroy (D);
         C.Mat_Destroy (P);
         C.Mat_Destroy (Y);
         C.Mat_Destroy (X);
      end Cleanup;
   begin
      OK (C.Mat_Create_2D (2, 3, 6, 1, X'Access));
      OK (C.Mat_Create_2D (2, 3, 6, 1, Y'Access));
      OK (C.Mat_Create_2D (4, 5, 6, 1, P'Access));
      OK (C.Mat_Set_To (P, Guard'Access));
      OK (C.Mat_Region (P, 1, 1, 3, 2, D'Access));
      OK
        (C.Mat_Create_External_2D_Strided
           (2, 3, 6, 1, Data'Address, 80, 40, E'Access));
      for Phase in Boolean loop
         Assert
           (Into (Phase, C.Null_Mat_Handle, Y, D) = C.Error_Invalid_Argument,
            "null X");
         Assert
           (Into (Phase, X, C.Null_Mat_Handle, D) = C.Error_Invalid_Argument,
            "null Y");
         Assert
           (Into (Phase, X, Y, C.Null_Mat_Handle) = C.Error_Invalid_Argument,
            "null destination");
         Assert
           (Into (Phase, X, Y, E) = C.Error_Invalid_Argument,
            "temporary destination");
      end loop;
      Assert
        (C.Mat_Phase_Into (X, Y, 2, D) = C.Error_Invalid_Argument, "flag 2");
      Assert
        (C.Mat_Phase_Into (X, Y, 255, D) = C.Error_Invalid_Argument,
         "flag 255");
      for R in C.C_Int32 range 0 .. 3 loop
         for Col in C.C_Int32 range 0 .. 4 loop
            OK (C.Mat_Get_Float64 (P, R, Col, V'Access));
            Assert (V = 91.0, "raw Region and Parent preserved");
         end loop;
      end loop;
      for Item of Data loop
         Assert (Item = 91.0, "raw external data/padding preserved");
      end loop;
      --  Independently reject incompatible temporary output and preserve it.
      C.Mat_Destroy (X);
      OK (C.Mat_Create_2D (1, 1, 5, 3, X'Access));
      for Phase in Boolean loop
         Assert
           (Into (Phase, X, X, E) = C.Error_Invalid_Argument,
            "incompatible temporary output");
      end loop;
      for Item of Data loop
         Assert (Item = 91.0, "incompatible temporary backing preserved");
      end loop;
      C.Mat_Destroy (X);
      OK (C.Mat_Create_2D (2, 3, 6, 1, X'Access));
      --  Ordinary, non-Region output has the same pre-native guarantees.
      C.Mat_Destroy (D);
      OK (C.Mat_Create_2D (2, 3, 6, 1, D'Access));
      OK (C.Mat_Set_To (D, Guard'Access));
      for Phase in Boolean loop
         Assert
           (Into (Phase, C.Null_Mat_Handle, Y, D) = C.Error_Invalid_Argument,
            "ordinary null X");
         Assert
           (Into (Phase, X, C.Null_Mat_Handle, D) = C.Error_Invalid_Argument,
            "ordinary null Y");
      end loop;
      Assert
        (C.Mat_Phase_Into (X, Y, 2, D) = C.Error_Invalid_Argument,
         "ordinary flag 2");
      Assert
        (C.Mat_Phase_Into (X, Y, 255, D) = C.Error_Invalid_Argument,
         "ordinary flag 255");
      for R in C.C_Int32 range 0 .. 1 loop
         for Col in C.C_Int32 range 0 .. 2 loop
            OK (C.Mat_Get_Float64 (D, R, Col, V'Access));
            Assert (V = 91.0, "ordinary pre-native preservation");
         end loop;
      end loop;
      OK (C.Mat_Set_To (X, Guard'Access));
      OK (C.Mat_Set_To (Y, Guard'Access));
      OK (C.Mat_Magnitude_Into (X, Y, D));
      OK (C.Mat_Phase_Into (X, Y, 0, D));
      OK (C.Mat_Phase_Into (X, Y, 1, D));
      C.Mat_Destroy (X);
      OK (C.Mat_Create_2D (2, 3, 0, 1, X'Access));
      Assert
        (C.Mat_Magnitude_Into (X, Y, D) = C.Error_OpenCV,
         "Magnitude native exception contained");
      Assert
        (C.Mat_Phase_Into (X, Y, 0, D) = C.Error_OpenCV,
         "Phase native exception contained");
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end Mat_Check;
   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      X, Y, P, D : aliased C.UMat_Handle := C.Null_UMat_Handle;
      H          : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Guard      : aliased C.Scalar := (others => 91.0);
      V          : aliased C.C_Float64;
      function Into
        (Phase : Boolean; A, B, Dest : C.UMat_Handle) return C.Status is
      begin
         if Phase then
            return C.UMat_Phase_Into (A, B, 0, Dest);
         else
            return C.UMat_Magnitude_Into (A, B, Dest);
         end if;
      end Into;
      procedure Cleanup is
      begin
         C.Mat_Destroy (H);
         C.UMat_Destroy (D);
         C.UMat_Destroy (P);
         C.UMat_Destroy (Y);
         C.UMat_Destroy (X);
      end Cleanup;
   begin
      OK (C.UMat_Create_2D (2, 3, 6, 1, X'Access));
      OK (C.UMat_Create_2D (2, 3, 6, 1, Y'Access));
      OK (C.UMat_Create_2D (4, 5, 6, 1, P'Access));
      OK (C.UMat_Set_To (P, Guard'Access));
      OK (C.UMat_Region (P, 1, 1, 3, 2, D'Access));
      for Phase in Boolean loop
         Assert
           (Into (Phase, C.Null_UMat_Handle, Y, D) = C.Error_Invalid_Argument,
            "UMat null X");
         Assert
           (Into (Phase, X, C.Null_UMat_Handle, D) = C.Error_Invalid_Argument,
            "UMat null Y");
         Assert
           (Into (Phase, X, Y, C.Null_UMat_Handle) = C.Error_Invalid_Argument,
            "UMat null destination");
      end loop;
      Assert
        (C.UMat_Phase_Into (X, Y, 2, D) = C.Error_Invalid_Argument,
         "UMat flag 2");
      Assert
        (C.UMat_Phase_Into (X, Y, 255, D) = C.Error_Invalid_Argument,
         "UMat flag 255");
      OK (C.UMat_To_Mat (P, H'Access));
      for R in C.C_Int32 range 0 .. 3 loop
         for Col in C.C_Int32 range 0 .. 4 loop
            OK (C.Mat_Get_Float64 (H, R, Col, V'Access));
            Assert (V = 91.0, "UMat pre-native Parent preserved");
         end loop;
      end loop;
      OK (C.UMat_Set_To (X, Guard'Access));
      C.UMat_Destroy (D);
      OK (C.UMat_Create_2D (2, 3, 6, 1, D'Access));
      OK (C.UMat_Set_To (D, Guard'Access));
      for Phase in Boolean loop
         Assert
           (Into (Phase, C.Null_UMat_Handle, Y, D) = C.Error_Invalid_Argument,
            "ordinary UMat null X");
         Assert
           (Into (Phase, X, C.Null_UMat_Handle, D) = C.Error_Invalid_Argument,
            "ordinary UMat null Y");
      end loop;
      Assert
        (C.UMat_Phase_Into (X, Y, 2, D) = C.Error_Invalid_Argument,
         "ordinary UMat flag 2");
      Assert
        (C.UMat_Phase_Into (X, Y, 255, D) = C.Error_Invalid_Argument,
         "ordinary UMat flag 255");
      C.Mat_Destroy (H);
      OK (C.UMat_To_Mat (D, H'Access));
      for R in C.C_Int32 range 0 .. 1 loop
         for Col in C.C_Int32 range 0 .. 2 loop
            OK (C.Mat_Get_Float64 (H, R, Col, V'Access));
            Assert (V = 91.0, "ordinary UMat preserved");
         end loop;
      end loop;
      OK (C.UMat_Set_To (Y, Guard'Access));
      OK (C.UMat_Magnitude_Into (X, Y, D));
      OK (C.UMat_Phase_Into (X, Y, 0, D));
      OK (C.UMat_Phase_Into (X, Y, 1, D));
      C.UMat_Destroy (X);
      OK (C.UMat_Create_2D (2, 3, 0, 1, X'Access));
      Assert
        (C.UMat_Magnitude_Into (X, Y, D) = C.Error_OpenCV,
         "UMat Magnitude native exception contained");
      Assert
        (C.UMat_Phase_Into (X, Y, 0, D) = C.Error_OpenCV,
         "UMat Phase native exception contained");
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end UMat_Check;
end Magnitude_Phase_Destination_Tests.Raw_ABI;
