with AUnit.Assertions;
with OpenCV.Internal.C_API;

package body Polar_Destination_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use AUnit.Assertions;
   use type C.Status;
   use type C.C_Float64;
   procedure OK (Status : C.Status) is
   begin
      Assert (Status = C.Success, C.Last_Error_Message);
   end OK;

   procedure Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      A, B, X, Y, E  : aliased C.Mat_Handle := C.Null_Mat_Handle;
      UA, UB, UX, UY : aliased C.UMat_Handle := C.Null_UMat_Handle;
      Data           : aliased array (0 .. 9) of C.C_Float64 :=
        (others => 93.0);
      Value          : aliased C.C_Float64;
      Scalar         : aliased C.Scalar;
      procedure Fill (H : C.Mat_Handle; V : C.C_Float64) is
      begin
         Scalar := (others => C.C_Double (V));
         OK (C.Mat_Set_To (H, Scalar'Access));
      end Fill;
      procedure Fill (H : C.UMat_Handle; V : C.C_Float64) is
      begin
         Scalar := (others => C.C_Double (V));
         OK (C.UMat_Set_To (H, Scalar'Access));
      end Fill;
      procedure Check_Value (H : C.UMat_Handle; Expected : C.C_Float64) is
         M : aliased C.Mat_Handle := C.Null_Mat_Handle;
      begin
         OK (C.UMat_To_Mat (H, M'Access));
         for R in C.C_Int32 range 0 .. 1 loop
            for Col in C.C_Int32 range 0 .. 2 loop
               OK (C.Mat_Get_Float64 (M, R, Col, Value'Access));
               Assert (Value = Expected, "UMat raw preflight preservation");
            end loop;
         end loop;
         C.Mat_Destroy (M);
      exception
         when others =>
            C.Mat_Destroy (M);
            raise;
      end Check_Value;
      procedure Preserved is
      begin
         for R in C.C_Int32 range 0 .. 1 loop
            for Col in C.C_Int32 range 0 .. 2 loop
               OK (C.Mat_Get_Float64 (A, R, Col, Value'Access));
               Assert (Value = 3.0, "first source preserved");
               OK (C.Mat_Get_Float64 (B, R, Col, Value'Access));
               Assert (Value = 4.0, "second source preserved");
               OK (C.Mat_Get_Float64 (X, R, Col, Value'Access));
               Assert (Value = 91.0, "first output preserved");
               OK (C.Mat_Get_Float64 (Y, R, Col, Value'Access));
               Assert (Value = 92.0, "second output preserved");
            end loop;
         end loop;
         for V of Data loop
            Assert (V = 93.0, "temporary data and padding preserved");
         end loop;
      end Preserved;
      function Into
        (Polar : Boolean; P, Q, R, S : C.Mat_Handle; Flag : C.C_Boolean := 0)
         return C.Status is
      begin
         if Polar then
            return C.Mat_Polar_To_Cart_Into (P, Q, Flag, R, S);
         else
            return C.Mat_Cart_To_Polar_Into (P, Q, Flag, R, S);
         end if;
      end Into;
      function Into
        (Polar : Boolean; P, Q, R, S : C.UMat_Handle; Flag : C.C_Boolean := 0)
         return C.Status is
      begin
         if Polar then
            return C.UMat_Polar_To_Cart_Into (P, Q, Flag, R, S);
         else
            return C.UMat_Cart_To_Polar_Into (P, Q, Flag, R, S);
         end if;
      end Into;
      procedure Cleanup is
      begin
         C.Mat_Destroy (A);
         C.Mat_Destroy (B);
         C.Mat_Destroy (X);
         C.Mat_Destroy (Y);
         C.Mat_Destroy (E);
         C.UMat_Destroy (UA);
         C.UMat_Destroy (UB);
         C.UMat_Destroy (UX);
         C.UMat_Destroy (UY);
      end Cleanup;
   begin
      OK (C.Mat_Create_2D (2, 3, 6, 1, A'Access));
      OK (C.Mat_Create_2D (2, 3, 6, 1, B'Access));
      OK (C.Mat_Create_2D (2, 3, 6, 1, X'Access));
      OK (C.Mat_Create_2D (2, 3, 6, 1, Y'Access));
      OK
        (C.Mat_Create_External_2D_Strided
           (2, 3, 6, 1, Data'Address, 80, 40, E'Access));
      Fill (A, 3.0);
      Fill (B, 4.0);
      Fill (X, 91.0);
      Fill (Y, 92.0);
      for Polar in Boolean loop
         for Kind in 0 .. 12 loop
            declare
               Status : C.Status;
            begin
               case Kind is
                  when 0      =>
                     Status := Into (Polar, C.Null_Mat_Handle, B, X, Y);

                  when 1      =>
                     Status := Into (Polar, A, C.Null_Mat_Handle, X, Y);

                  when 2      =>
                     Status := Into (Polar, A, B, C.Null_Mat_Handle, Y);

                  when 3      =>
                     Status := Into (Polar, A, B, X, C.Null_Mat_Handle);

                  when 4      =>
                     Status := Into (Polar, A, B, X, X);

                  when 5      =>
                     Status := Into (Polar, A, B, A, Y);

                  when 6      =>
                     Status := Into (Polar, A, B, B, Y);

                  when 7      =>
                     Status := Into (Polar, A, B, X, A);

                  when 8      =>
                     Status := Into (Polar, A, B, X, B);

                  when 9      =>
                     Status := Into (Polar, A, B, E, Y);

                  when 10     =>
                     Status := Into (Polar, A, B, X, E);

                  when 11     =>
                     Status := Into (Polar, A, B, X, Y, 2);

                  when others =>
                     Status := Into (Polar, A, B, X, Y, 255);
               end case;
               Assert
                 (Status = C.Error_Invalid_Argument, "Mat paired preflight");
               Preserved;
            end;
         end loop;
      end loop;
      OK (C.UMat_Create_2D (2, 3, 6, 1, UA'Access));
      OK (C.UMat_Create_2D (2, 3, 6, 1, UB'Access));
      OK (C.UMat_Create_2D (2, 3, 6, 1, UX'Access));
      OK (C.UMat_Create_2D (2, 3, 6, 1, UY'Access));
      Fill (UA, 3.0);
      Fill (UB, 4.0);
      Fill (UX, 91.0);
      Fill (UY, 92.0);
      for Polar in Boolean loop
         for Kind in 0 .. 10 loop
            declare
               Status : C.Status;
            begin
               case Kind is
                  when 0      =>
                     Status := Into (Polar, C.Null_UMat_Handle, UB, UX, UY);

                  when 1      =>
                     Status := Into (Polar, UA, C.Null_UMat_Handle, UX, UY);

                  when 2      =>
                     Status := Into (Polar, UA, UB, C.Null_UMat_Handle, UY);

                  when 3      =>
                     Status := Into (Polar, UA, UB, UX, C.Null_UMat_Handle);

                  when 4      =>
                     Status := Into (Polar, UA, UB, UX, UX);

                  when 5      =>
                     Status := Into (Polar, UA, UB, UA, UY);

                  when 6      =>
                     Status := Into (Polar, UA, UB, UB, UY);

                  when 7      =>
                     Status := Into (Polar, UA, UB, UX, UA);

                  when 8      =>
                     Status := Into (Polar, UA, UB, UX, UB);

                  when 9      =>
                     Status := Into (Polar, UA, UB, UX, UY, 2);

                  when others =>
                     Status := Into (Polar, UA, UB, UX, UY, 255);
               end case;
               Assert
                 (Status = C.Error_Invalid_Argument, "UMat paired preflight");
               Check_Value (UA, 3.0);
               Check_Value (UB, 4.0);
               Check_Value (UX, 91.0);
               Check_Value (UY, 92.0);
            end;
         end loop;
      end loop;
      OK (C.Mat_Polar_To_Cart_Into (A, A, 0, X, Y));
      OK (C.Mat_Cart_To_Polar_Into (B, B, 0, X, Y));
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end Check;
end Polar_Destination_Tests.Raw_ABI;
