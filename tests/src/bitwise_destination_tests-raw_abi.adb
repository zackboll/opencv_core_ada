with AUnit.Assertions;
with Interfaces;
with OpenCV.Internal.C_API;

package body Bitwise_Destination_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use AUnit.Assertions;
   use type C.Status;
   use type C.C_Int32;
   use type C.C_UInt8;
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
      Assert (Status = C.Success, "raw setup/observation");
   end OK;
   generic
      type Handle is private;
      Null_Handle : Handle;
      with function And_Into (A, B, D : Handle) return C.Status;
      with function Or_Into (A, B, D : Handle) return C.Status;
      with function Xor_Into (A, B, D : Handle) return C.Status;
      with function Not_Into (A, D : Handle) return C.Status;
      with function And_Masked (A, B, M, D : Handle) return C.Status;
      with function Or_Masked (A, B, M, D : Handle) return C.Status;
      with function Xor_Masked (A, B, M, D : Handle) return C.Status;
      with function Not_Masked (A, M, D : Handle) return C.Status;
      with
        function Dimensions
          (Self : Handle; Value : access C.C_Int32) return C.Status;
      with
        function Extent
          (Self : Handle; Axis : C.C_Int32; Value : access C.C_Int32)
           return C.Status;
      with
        function Depth
          (Self : Handle; Value : access C.C_Int32) return C.Status;
      with
        function Channels
          (Self : Handle; Value : access C.C_Int32) return C.Status;
      with
        function Host_Copy
          (Self : Handle; Value : access C.Mat_Handle) return C.Status;
   package Checks is
      procedure Run
        (Source, Other, Destination : Handle;
         Temporary                  : Boolean := False;
         Inspect                    : access procedure := null);
   end Checks;
   package body Checks is
      function Into
        (A, B, M, D : Handle; Op : Bitwise_Operation; Masked : Boolean)
         return C.Status is
      begin
         case Op is
            when And_Operation =>
               return
                 (if Masked
                  then And_Masked (A, B, M, D)
                  else And_Into (A, B, D));

            when Or_Operation  =>
               return
                 (if Masked
                  then Or_Masked (A, B, M, D)
                  else Or_Into (A, B, D));

            when Xor_Operation =>
               return
                 (if Masked
                  then Xor_Masked (A, B, M, D)
                  else Xor_Into (A, B, D));

            when Not_Operation =>
               return
                 (if Masked then Not_Masked (A, M, D) else Not_Into (A, D));
         end case;
      end Into;
      procedure Unchanged (Destination : Handle) is
         Dim, R, Col, D, Ch : aliased C.C_Int32;
         H                  : aliased C.Mat_Handle := C.Null_Mat_Handle;
         Pixel              : aliased C.C_UInt8;
      begin
         OK (Dimensions (Destination, Dim'Access));
         OK (Extent (Destination, 0, R'Access));
         OK (Extent (Destination, 1, Col'Access));
         OK (Depth (Destination, D'Access));
         OK (Channels (Destination, Ch'Access));
         Assert
           (Dim = 2
            and then R = 2
            and then Col = 3
            and then D = 0
            and then Ch = 1,
            "rank/shape/depth/channels unchanged");
         OK (Host_Copy (Destination, H'Access));
         for Row in C.C_Int32 range 0 .. 1 loop
            for Column in C.C_Int32 range 0 .. 2 loop
               OK (C.Mat_Get_UInt8 (H, Row, Column, Pixel'Access));
               Assert (Pixel = 91, "every raw destination pixel unchanged");
            end loop;
         end loop;
         C.Mat_Destroy (H);
      exception
         when others =>
            C.Mat_Destroy (H);
            raise;
      end Unchanged;
      procedure Run
        (Source, Other, Destination : Handle;
         Temporary                  : Boolean := False;
         Inspect                    : access procedure := null) is
      begin
         for Op in Bitwise_Operation loop
            for Masked in Boolean loop
               for Mode in 0 .. 3 loop
                  if (Mode /= 1 or else Op /= Not_Operation)
                    and then (Mode /= 2 or else Masked)
                  then
                     Assert
                       (Into
                          ((if Mode = 0 then Null_Handle else Source),
                           (if Mode = 1 then Null_Handle else Source),
                           (if Mode = 2 then Null_Handle else Source),
                           (if Mode = 3 then Null_Handle else Destination),
                           Op,
                           Masked)
                        = C.Error_Invalid_Argument,
                        "each required null independently rejected");
                     Unchanged (Destination);
                     if Inspect /= null then
                        Inspect.all;
                     end if;
                  end if;
               end loop;
               if Temporary then
                  for Mismatch in Boolean loop
                     Assert
                       (Into
                          ((if Mismatch then Other else Source),
                           (if Mismatch then Other else Source),
                           (if Mismatch then Other else Source),
                           Destination,
                           Op,
                           Masked)
                        = C.Error_Invalid_Argument,
                        "raw temporary destination rejected before native");
                     Unchanged (Destination);
                     if Inspect /= null then
                        Inspect.all;
                     end if;
                  end loop;
               end if;
            end loop;
         end loop;
      end Run;
   end Checks;
   package Mat_Checks is new
     Checks
       (C.Mat_Handle,
        C.Null_Mat_Handle,
        C.Mat_Bitwise_And_Into,
        C.Mat_Bitwise_Or_Into,
        C.Mat_Bitwise_Xor_Into,
        C.Mat_Bitwise_Not_Into,
        C.Mat_Bitwise_And_Masked_Into,
        C.Mat_Bitwise_Or_Masked_Into,
        C.Mat_Bitwise_Xor_Masked_Into,
        C.Mat_Bitwise_Not_Masked_Into,
        C.Mat_Dimension_Count,
        C.Mat_Extent,
        C.Mat_Depth,
        C.Mat_Channels,
        C.Mat_Clone);
   package UMat_Checks is new
     Checks
       (C.UMat_Handle,
        C.Null_UMat_Handle,
        C.UMat_Bitwise_And_Into,
        C.UMat_Bitwise_Or_Into,
        C.UMat_Bitwise_Xor_Into,
        C.UMat_Bitwise_Not_Into,
        C.UMat_Bitwise_And_Masked_Into,
        C.UMat_Bitwise_Or_Masked_Into,
        C.UMat_Bitwise_Xor_Masked_Into,
        C.UMat_Bitwise_Not_Masked_Into,
        C.UMat_Dimension_Count,
        C.UMat_Extent,
        C.UMat_Depth,
        C.UMat_Channels,
        C.UMat_To_Mat);
   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source, Other, D, External, Volume, Selected : aliased C.Mat_Handle :=
        C.Null_Mat_Handle;
      Value                                        : aliased C.Scalar :=
        (91.0, 0.0, 0.0, 0.0);
      Data                                         : aliased C.C_UInt8_Array :=
        (0 .. 9 => 91);
      Shape                                        : C.C_Int32_Array :=
        (2, 2, 3);
      Drops                                        : C.C_UInt8_Array :=
        (1, 0, 0);
      Starts                                       : C.C_Int32_Array :=
        (1, 0, 0);
      Stops                                        : C.C_Int32_Array :=
        (2, 2, 3);
      procedure Padding is
      begin
         for Pixel of Data loop
            Assert (Pixel = 91, "external storage and padding unchanged");
         end loop;
      end Padding;
      procedure Parent_Pixels is
         Idx   : C.C_Int32_Array := (0, 0, 0);
         Pixel : aliased C.C_UInt8;
      begin
         for I in C.C_Int32 range 0 .. 1 loop
            for J in C.C_Int32 range 0 .. 1 loop
               for K in C.C_Int32 range 0 .. 2 loop
                  Idx := (I, J, K);
                  OK
                    (C.Mat_Get_UInt8_ND
                       (Volume, 3, Idx (0)'Access, Pixel'Access));
                  Assert (Pixel = 91, "selected Parent unchanged");
               end loop;
            end loop;
         end loop;
      end Parent_Pixels;
      procedure Cleanup is
      begin
         C.Mat_Destroy (Selected);
         C.Mat_Destroy (Volume);
         C.Mat_Destroy (External);
         C.Mat_Destroy (D);
         C.Mat_Destroy (Other);
         C.Mat_Destroy (Source);
      end Cleanup;
   begin
      OK (C.Mat_Create_2D (2, 3, 0, 1, Source'Access));
      OK (C.Mat_Create_2D (1, 2, 5, 1, Other'Access));
      OK (C.Mat_Create_2D (2, 3, 0, 1, D'Access));
      OK (C.Mat_Set_To (Source, Value'Access));
      OK (C.Mat_Set_To (D, Value'Access));
      Mat_Checks.Run (Source, Other, D);
      OK
        (C.Mat_Create_External_2D_Strided
           (2, 3, 0, 1, Data'Address, 10, 5, External'Access));
      Mat_Checks.Run (Source, Other, External, True, Padding'Access);
      OK (C.Mat_Create_ND (3, Shape (0)'Access, 0, 1, Volume'Access));
      OK (C.Mat_Set_To (Volume, Value'Access));
      OK
        (C.Mat_Select_ND_View
           (Volume,
            3,
            Drops (0)'Access,
            Starts (0)'Access,
            Stops (0)'Access,
            Selected'Access));
      Mat_Checks.Run (Source, Other, Selected, True, Parent_Pixels'Access);
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end Mat_Check;
   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source, D : aliased C.UMat_Handle := C.Null_UMat_Handle;
      Value     : aliased C.Scalar := (91.0, 0.0, 0.0, 0.0);
      procedure Cleanup is
      begin
         C.UMat_Destroy (D);
         C.UMat_Destroy (Source);
      end Cleanup;
   begin
      OK (C.UMat_Create_2D (2, 3, 0, 1, Source'Access));
      OK (C.UMat_Create_2D (2, 3, 0, 1, D'Access));
      OK (C.UMat_Set_To (Source, Value'Access));
      OK (C.UMat_Set_To (D, Value'Access));
      UMat_Checks.Run (Source, Source, D);
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end UMat_Check;
end Bitwise_Destination_Tests.Raw_ABI;
