with AUnit.Assertions;
with OpenCV.Internal.C_API;

package body Polar_Destination_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use AUnit.Assertions;
   use type C.Status;
   use type C.C_Float64;
   use type C.C_Int32;
   use type C.C_Double;
   procedure OK (Status : C.Status) is
   begin
      Assert (Status = C.Success, C.Last_Error_Message);
   end OK;

   procedure Unchanged (H, Before : C.Mat_Handle) is
      Diff       : aliased C.Mat_Handle := C.Null_Mat_Handle;
      P, Q, Rank : aliased C.C_Int32;
      Value      : aliased C.C_Double;
   begin
      OK (C.Mat_Dimension_Count (H, Rank'Access));
      OK (C.Mat_Dimension_Count (Before, Q'Access));
      Assert (Rank = Q, "raw rank preserved");
      for Axis in 0 .. Rank - 1 loop
         OK (C.Mat_Extent (H, Axis, P'Access));
         OK (C.Mat_Extent (Before, Axis, Q'Access));
         Assert (P = Q, "raw shape preserved");
      end loop;
      OK (C.Mat_Depth (H, P'Access));
      OK (C.Mat_Depth (Before, Q'Access));
      Assert (P = Q, "raw depth preserved");
      OK (C.Mat_Channels (H, P'Access));
      OK (C.Mat_Channels (Before, Q'Access));
      Assert (P = Q, "raw channels preserved");
      OK (C.Mat_Abs_Diff (H, Before, Diff'Access));
      OK (C.Mat_Norm (Diff, 1, Value'Access));
      Assert (Value = 0.0, "all raw pixels preserved");
      C.Mat_Destroy (Diff);
   exception
      when others =>
         C.Mat_Destroy (Diff);
         raise;
   end Unchanged;

   procedure Selected is
      type Ints is array (0 .. 2) of aliased C.C_Int32;
      type Flags is array (0 .. 2) of aliased C.C_UInt8;
      Sizes                                                            :
        Ints := (3, 5, 7);
      Starts                                                           :
        Ints := (1, 1, 2);
      Stops                                                            :
        Ints := (2, 3, 5);
      Drop                                                             :
        Flags := (1, 0, 0);
      Parent, View, Alias, Snapshot, PS, Other, OS, A, B, ASnap, BSnap :
        aliased C.Mat_Handle := C.Null_Mat_Handle;
      Scalar                                                           :
        aliased C.Scalar;
      procedure Cleanup is
      begin
         C.Mat_Destroy (View);
         C.Mat_Destroy (Alias);
         C.Mat_Destroy (Snapshot);
         C.Mat_Destroy (PS);
         C.Mat_Destroy (Parent);
         C.Mat_Destroy (Other);
         C.Mat_Destroy (OS);
         C.Mat_Destroy (A);
         C.Mat_Destroy (B);
         C.Mat_Destroy (ASnap);
         C.Mat_Destroy (BSnap);
         Parent := C.Null_Mat_Handle;
         View := C.Null_Mat_Handle;
         Alias := C.Null_Mat_Handle;
         Snapshot := C.Null_Mat_Handle;
         PS := C.Null_Mat_Handle;
         Other := C.Null_Mat_Handle;
         OS := C.Null_Mat_Handle;
         A := C.Null_Mat_Handle;
         B := C.Null_Mat_Handle;
         ASnap := C.Null_Mat_Handle;
         BSnap := C.Null_Mat_Handle;
      end Cleanup;
   begin
      for Layout in 0 .. 3 loop
         for Polar in Boolean loop
            for First in Boolean loop
               OK (C.Mat_Create_ND (3, Sizes (0)'Access, 6, 1, Parent'Access));
               Scalar := (others => 93.0);
               OK (C.Mat_Set_To (Parent, Scalar'Access));
               OK
                 (C.Mat_Select_ND_View
                    (Parent,
                     3,
                     Drop (0)'Access,
                     Starts (0)'Access,
                     Stops (0)'Access,
                     View'Access));
               --  Temporary capabilities deliberately cannot be copied.
               --  Retain an independently selected header over the same data.
               OK
                 (C.Mat_Select_ND_View
                    (Parent,
                     3,
                     Drop (0)'Access,
                     Starts (0)'Access,
                     Stops (0)'Access,
                     Alias'Access));
               OK (C.Mat_Clone (View, Snapshot'Access));
               OK (C.Mat_Clone (Parent, PS'Access));
               OK (C.Mat_Create_2D (2, 3, 6, 1, Other'Access));
               Scalar := (others => 92.0);
               OK (C.Mat_Set_To (Other, Scalar'Access));
               OK (C.Mat_Clone (Other, OS'Access));
               OK
                 (C.Mat_Create_2D
                    ((if Layout = 1 then 1 else 2),
                     3,
                     (if Layout = 2 then 5 else 6),
                     (if Layout = 3 then 3 else 1),
                     A'Access));
               Scalar := (others => 3.0);
               OK (C.Mat_Set_To (A, Scalar'Access));
               OK (C.Mat_Clone (A, B'Access));
               OK (C.Mat_Clone (A, ASnap'Access));
               OK (C.Mat_Clone (B, BSnap'Access));
               declare
                  Status : C.Status;
                  X      : constant C.Mat_Handle :=
                    (if First then View else Other);
                  Y      : constant C.Mat_Handle :=
                    (if First then Other else View);
               begin
                  Status :=
                    (if Polar
                     then C.Mat_Polar_To_Cart_Into (A, B, 0, X, Y)
                     else C.Mat_Cart_To_Polar_Into (A, B, 0, X, Y));
                  Assert
                    (Status = C.Error_Invalid_Argument,
                     "selected output rejected before dispatch");
                  Unchanged (View, Snapshot);
                  Unchanged (Alias, Snapshot);
                  Unchanged (Parent, PS);
                  Unchanged (Other, OS);
                  Unchanged (A, ASnap);
                  Unchanged (B, BSnap);
               end;
               Cleanup;
            end loop;
         end loop;
      end loop;
   exception
      when others =>
         Cleanup;
         raise;
   end Selected;

   procedure Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      A, B, X, Y, E                  : aliased C.Mat_Handle :=
        C.Null_Mat_Handle;
      UA, UB, UX, UY                 : aliased C.UMat_Handle :=
        C.Null_UMat_Handle;
      P, Q                           : aliased C.Mat_Handle :=
        C.Null_Mat_Handle;
      UP, UQ                         : aliased C.UMat_Handle :=
        C.Null_UMat_Handle;
      type Mats is array (0 .. 5) of aliased C.Mat_Handle;
      type UMats is array (0 .. 5) of aliased C.UMat_Handle;
      Aliases, Snapshots, USnapshots : Mats := (others => C.Null_Mat_Handle);
      UAliases                       : UMats := (others => C.Null_UMat_Handle);
      Data                           : aliased array (0 .. 9) of C.C_Float64 :=
        (others => 93.0);
      Value                          : aliased C.C_Float64;
      Scalar                         : aliased C.Scalar;
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
         for I in Aliases'Range loop
            Unchanged (Aliases (I), Snapshots (I));
         end loop;
         Unchanged (A, Snapshots (0));
         Unchanged (B, Snapshots (1));
         Unchanged (X, Snapshots (2));
         Unchanged (Y, Snapshots (3));
         Unchanged (P, Snapshots (4));
         Unchanged (Q, Snapshots (5));
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
         for I in Aliases'Range loop
            C.Mat_Destroy (Aliases (I));
            C.Mat_Destroy (Snapshots (I));
            C.Mat_Destroy (USnapshots (I));
            C.UMat_Destroy (UAliases (I));
         end loop;
         C.Mat_Destroy (P);
         C.Mat_Destroy (Q);
         C.UMat_Destroy (UP);
         C.UMat_Destroy (UQ);
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
      Selected;
      OK (C.Mat_Create_2D (2, 3, 6, 1, A'Access));
      OK (C.Mat_Create_2D (2, 3, 6, 1, B'Access));
      OK (C.Mat_Create_2D (5, 7, 6, 1, P'Access));
      OK (C.Mat_Create_2D (5, 7, 6, 1, Q'Access));
      Fill (P, 81.0);
      Fill (Q, 82.0);
      OK (C.Mat_Region (P, 2, 1, 3, 2, X'Access));
      OK (C.Mat_Region (Q, 2, 1, 3, 2, Y'Access));
      OK
        (C.Mat_Create_External_2D_Strided
           (2, 3, 6, 1, Data'Address, 80, 40, E'Access));
      Fill (A, 3.0);
      Fill (B, 4.0);
      Fill (X, 91.0);
      Fill (Y, 92.0);
      declare
         Handles : constant Mats := (A, B, X, Y, P, Q);
      begin
         for I in Handles'Range loop
            OK (C.Mat_Copy (Handles (I), Aliases (I)'Access));
            OK (C.Mat_Clone (Handles (I), Snapshots (I)'Access));
         end loop;
      end;
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
      OK (C.UMat_Create_2D (5, 7, 6, 1, UP'Access));
      OK (C.UMat_Create_2D (5, 7, 6, 1, UQ'Access));
      Fill (UP, 81.0);
      Fill (UQ, 82.0);
      OK (C.UMat_Region (UP, 2, 1, 3, 2, UX'Access));
      OK (C.UMat_Region (UQ, 2, 1, 3, 2, UY'Access));
      Fill (UA, 3.0);
      Fill (UB, 4.0);
      Fill (UX, 91.0);
      Fill (UY, 92.0);
      declare
         Handles : constant UMats := (UA, UB, UX, UY, UP, UQ);
      begin
         for I in Handles'Range loop
            declare
               H : aliased C.Mat_Handle := C.Null_Mat_Handle;
            begin
               OK (C.UMat_Copy (Handles (I), UAliases (I)'Access));
               OK (C.UMat_To_Mat (Handles (I), H'Access));
               OK (C.Mat_Clone (H, USnapshots (I)'Access));
               C.Mat_Destroy (H);
            end;
         end loop;
      end;
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
               declare
                  Handles : constant UMats := (UA, UB, UX, UY, UP, UQ);
               begin
                  for I in Handles'Range loop
                     for Is_Alias in Boolean loop
                        declare
                           H : aliased C.Mat_Handle := C.Null_Mat_Handle;
                        begin
                           OK
                             (C.UMat_To_Mat
                                ((if Is_Alias
                                  then UAliases (I)
                                  else Handles (I)),
                                 H'Access));
                           Unchanged (H, USnapshots (I));
                           C.Mat_Destroy (H);
                        end;
                     end loop;
                  end loop;
               end;
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
