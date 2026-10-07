with AUnit.Assertions;
with Interfaces;
with Module_Bridge_Probe;
with OpenCV.Internal.C_API;

package body Mask_Destination_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use AUnit.Assertions;
   use type C.Status;
   use type C.C_Int32;
   use type C.C_UInt8;
   procedure Copy_Special
     (Source        : OpenCV.Core.Mat;
      Source_Column : Natural;
      Destination   : in out OpenCV.Core.Mat;
      Column        : Natural)
   is
      From : constant OpenCV.Core.Mat :=
        Source.Region ((OpenCV.Point_Coordinate (Source_Column), 0, 1, 1));
      Into : OpenCV.Core.Mat :=
        Destination.Region ((OpenCV.Point_Coordinate (Column), 0, 1, 1));
   begin
      From.Copy_To (Into);
   end Copy_Special;
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
      Assert (Status = C.Success, "raw: " & C.Last_Error_Message);
   end OK;
   generic
      type Handle is private;
      Null_Handle : Handle;
      with
        function Compare
          (A, B : Handle; Kind : C.C_Int32; D : Handle) return C.Status;
      with
        function In_Range
          (A : Handle; L, U : access constant C.Scalar; D : Handle)
           return C.Status;
      with
        function Dimensions (H : Handle; V : access C.C_Int32) return C.Status;
      with
        function Extent
          (H : Handle; Axis : C.C_Int32; V : access C.C_Int32) return C.Status;
      with function Depth (H : Handle; V : access C.C_Int32) return C.Status;
      with
        function Channels (H : Handle; V : access C.C_Int32) return C.Status;
      with
        function Host_Copy
          (H : Handle; V : access C.Mat_Handle) return C.Status;
   package Checks is
      procedure Unchanged (D : Handle);
      procedure Run (A, D : Handle; Temporary : Boolean := False);
      procedure Half (A, D : Handle);
   end Checks;
   package body Checks is
      Bounds : aliased C.Scalar := (0.0, 0.0, 0.0, 0.0);
      procedure Unchanged (D : Handle) is
         Rank, Rows, Cols, Dep, Ch : aliased C.C_Int32;
         Host                      : aliased C.Mat_Handle := C.Null_Mat_Handle;
         Byte                      : aliased C.C_UInt8;
      begin
         OK (Dimensions (D, Rank'Access));
         OK (Extent (D, 0, Rows'Access));
         OK (Extent (D, 1, Cols'Access));
         OK (Depth (D, Dep'Access));
         OK (Channels (D, Ch'Access));
         Assert
           (Rank = 2
            and then Rows = 2
            and then Cols = 3
            and then Dep = 0
            and then Ch = 1,
            "raw unchanged layout");
         OK (Host_Copy (D, Host'Access));
         for R in C.C_Int32 range 0 .. 1 loop
            for Col in C.C_Int32 range 0 .. 2 loop
               OK (C.Mat_Get_UInt8 (Host, R, Col, Byte'Access));
               Assert (Byte = 91, "every raw failure byte");
            end loop;
         end loop;
         C.Mat_Destroy (Host);
      exception
         when others =>
            C.Mat_Destroy (Host);
            raise;
      end Unchanged;
      procedure Run (A, D : Handle; Temporary : Boolean := False) is
         Status : C.Status;
      begin
         for Mode in 0 .. 3 loop
            Status :=
              Compare
                ((if Mode = 0 then Null_Handle else A),
                 (if Mode = 1 then Null_Handle else A),
                 (if Mode = 3 then 99 else 0),
                 (if Mode = 2 then Null_Handle else D));
            Assert
              (Status = C.Error_Invalid_Argument, "compare ABI validation");
            Unchanged (D);
         end loop;
         for Mode in 0 .. 3 loop
            Status :=
              In_Range
                ((if Mode = 0 then Null_Handle else A),
                 (if Mode = 1 then null else Bounds'Access),
                 (if Mode = 2 then null else Bounds'Access),
                 (if Mode = 3 then Null_Handle else D));
            Assert (Status = C.Error_Invalid_Argument, "range ABI validation");
            Unchanged (D);
         end loop;
         if Temporary then
            Assert
              (Compare (A, A, 0, D) = C.Error_Invalid_Argument,
               "temporary compare raw destination");
            Unchanged (D);
            Assert
              (In_Range (A, Bounds'Access, Bounds'Access, D)
               = C.Error_Invalid_Argument,
               "temporary range raw destination");
            Unchanged (D);
         end if;
      end Run;
      procedure Half (A, D : Handle) is
      begin
         if Module_Bridge_Probe.OpenCV_Major_Version < 5 then
            Assert
              (Compare (A, A, 0, D) = C.Error_OpenCV,
               "Float16 compare translated raw error");
            Unchanged (D);
            Assert
              (In_Range (A, Bounds'Access, Bounds'Access, D) = C.Error_OpenCV,
               "Float16 range translated raw error");
            Unchanged (D);
         end if;
      end Half;
   end Checks;
   package Mat_Checks is new
     Checks
       (C.Mat_Handle,
        C.Null_Mat_Handle,
        C.Mat_Compare_Into,
        C.Mat_In_Range_Scalar_Into,
        C.Mat_Dimension_Count,
        C.Mat_Extent,
        C.Mat_Depth,
        C.Mat_Channels,
        C.Mat_Clone);
   package UMat_Checks is new
     Checks
       (C.UMat_Handle,
        C.Null_UMat_Handle,
        C.UMat_Compare_Into,
        C.UMat_In_Range_Scalar_Into,
        C.UMat_Dimension_Count,
        C.UMat_Extent,
        C.UMat_Depth,
        C.UMat_Channels,
        C.UMat_To_Mat);
   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source, Half_Source, D, Parent, Region, External, Selected, Volume :
        aliased C.Mat_Handle := C.Null_Mat_Handle;
      Value                                                              :
        aliased C.Scalar := (91.0, 0.0, 0.0, 0.0);
      Data                                                               :
        aliased C.C_UInt8_Array := (0 .. 9 => 91);
      Shape                                                              :
        C.C_Int32_Array := (2, 2, 3);
      Drops                                                              :
        C.C_UInt8_Array := (1, 0, 0);
      Starts                                                             :
        C.C_Int32_Array := (1, 0, 0);
      Stops                                                              :
        C.C_Int32_Array := (2, 2, 3);
      procedure Cleanup is
      begin
         C.Mat_Destroy (Selected);
         C.Mat_Destroy (Volume);
         C.Mat_Destroy (External);
         C.Mat_Destroy (Region);
         C.Mat_Destroy (Parent);
         C.Mat_Destroy (D);
         C.Mat_Destroy (Half_Source);
         C.Mat_Destroy (Source);
      end Cleanup;
   begin
      OK (C.Mat_Create_2D (2, 3, 0, 1, Source'Access));
      OK (C.Mat_Create_2D (1, 1, 7, 1, Half_Source'Access));
      OK (C.Mat_Create_2D (2, 3, 0, 1, D'Access));
      OK (C.Mat_Set_To (D, Value'Access));
      Mat_Checks.Run (Source, D);
      Mat_Checks.Half (Half_Source, D);
      OK (C.Mat_Create_2D (4, 6, 0, 1, Parent'Access));
      OK (C.Mat_Set_To (Parent, Value'Access));
      OK (C.Mat_Region (Parent, 1, 1, 3, 2, Region'Access));
      Mat_Checks.Run (Source, Region);
      Mat_Checks.Half (Half_Source, Region);
      declare
         Byte : aliased C.C_UInt8;
      begin
         for R in C.C_Int32 range 0 .. 3 loop
            for Col in C.C_Int32 range 0 .. 5 loop
               OK (C.Mat_Get_UInt8 (Parent, R, Col, Byte'Access));
               Assert (Byte = 91, "raw Region Parent unchanged");
            end loop;
         end loop;
      end;
      OK
        (C.Mat_Create_External_2D_Strided
           (2, 3, 0, 1, Data'Address, 10, 5, External'Access));
      Mat_Checks.Run (Source, External, True);
      --  Incompatible source/output layout is rejected independently too.
      Mat_Checks.Run (Half_Source, External, True);
      Mat_Checks.Half (Half_Source, D);
      for Byte of Data loop
         Assert (Byte = 91, "external padding preserved");
      end loop;
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
      Mat_Checks.Run (Source, Selected, True);
      Mat_Checks.Run (Half_Source, Selected, True);
      declare
         Idx  : C.C_Int32_Array := (0, 0, 0);
         Byte : aliased C.C_UInt8;
      begin
         for I in C.C_Int32 range 0 .. 1 loop
            for J in C.C_Int32 range 0 .. 1 loop
               for K in C.C_Int32 range 0 .. 2 loop
                  Idx := (I, J, K);
                  OK
                    (C.Mat_Get_UInt8_ND
                       (Volume, 3, Idx (0)'Access, Byte'Access));
                  Assert (Byte = 91, "raw selected Parent unchanged");
               end loop;
            end loop;
         end loop;
      end;
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end Mat_Check;
   procedure UMat_Exact_Aliases
     (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      A, B, Alias_A, Alias_B : aliased C.UMat_Handle := C.Null_UMat_Handle;
      Value                  : aliased C.Scalar := (2.0, 12.0, 22.0, 32.0);
      Lower                  : aliased C.Scalar := (0.0, 0.0, 0.0, 0.0);
      Upper                  : aliased C.Scalar :=
        (100.0, 100.0, 100.0, 100.0);
      type Depth_List is array (Positive range <>) of C.C_Int32;
      use type C.C_Float64;
      procedure Cleanup is
      begin
         C.UMat_Destroy (Alias_B);
         Alias_B := C.Null_UMat_Handle;
         C.UMat_Destroy (Alias_A);
         Alias_A := C.Null_UMat_Handle;
         C.UMat_Destroy (B);
         B := C.Null_UMat_Handle;
         C.UMat_Destroy (A);
         A := C.Null_UMat_Handle;
      end Cleanup;
      procedure Unchanged (H : C.UMat_Handle; D, Ch : C.C_Int32) is
         Rank, Rows, Cols, Dep, Channels : aliased C.C_Int32;
         Wide                            : aliased C.UMat_Handle :=
           C.Null_UMat_Handle;
         Host, Plane                     : aliased C.Mat_Handle :=
           C.Null_Mat_Handle;
         Pixel                           : aliased C.C_Float64;
         procedure Release_Observation is
         begin
            C.Mat_Destroy (Plane);
            C.Mat_Destroy (Host);
            C.UMat_Destroy (Wide);
         end Release_Observation;
      begin
         OK (C.UMat_Dimension_Count (H, Rank'Access));
         OK (C.UMat_Extent (H, 0, Rows'Access));
         OK (C.UMat_Extent (H, 1, Cols'Access));
         OK (C.UMat_Depth (H, Dep'Access));
         OK (C.UMat_Channels (H, Channels'Access));
         Assert
           (Rank = 2
            and then Rows = 2
            and then Cols = 257
            and then Dep = D
            and then Channels = Ch,
            "raw exact alias preserves rank/shape/depth/channels");
         OK (C.UMat_Convert_To (H, 6, 1.0, 0.0, Wide'Access));
         OK (C.UMat_To_Mat (Wide, Host'Access));
         for Channel in 0 .. Ch - 1 loop
            OK (C.Mat_Extract_Channel (Host, Channel, Plane'Access));
            for R in C.C_Int32 range 0 .. 1 loop
               for Col in C.C_Int32 range 0 .. 256 loop
                  OK (C.Mat_Get_Float64 (Plane, R, Col, Pixel'Access));
                  Assert
                    (Pixel = C.C_Float64 (2 + 10 * Channel),
                     "every raw source/retained-alias value unchanged");
               end loop;
            end loop;
            C.Mat_Destroy (Plane);
            Plane := C.Null_Mat_Handle;
         end loop;
         Release_Observation;
      exception
         when others =>
            Release_Observation;
            raise;
      end Unchanged;
      procedure Prepare (D, Ch : C.C_Int32) is
      begin
         OK (C.UMat_Create_2D (2, 257, D, Ch, A'Access));
         OK (C.UMat_Create_2D (2, 257, D, Ch, B'Access));
         OK (C.UMat_Set_To (A, Value'Access));
         OK (C.UMat_Set_To (B, Value'Access));
         OK (C.UMat_Copy (A, Alias_A'Access));
         OK (C.UMat_Copy (B, Alias_B'Access));
      end Prepare;
   begin
      for D of Depth_List'(3, 5, 6, 7) loop
         for Into_Right in Boolean loop
            Prepare (D, 1);
            Assert
              (C.UMat_Compare_Into (A, B, 0, (if Into_Right then B else A))
               = C.Error_OpenCV,
               "raw exact Compare translated rejection");
            Unchanged (A, D, 1);
            Unchanged (B, D, 1);
            Unchanged (Alias_A, D, 1);
            Unchanged (Alias_B, D, 1);
            Cleanup;
         end loop;
      end loop;
      for D of Depth_List'(0, 3, 5, 7) loop
         for Ch in C.C_Int32 range 1 .. 3 loop
            if Ch = 1 or else (D = 0 and then Ch = 3) then
               Prepare (D, Ch);
               Assert
                 (C.UMat_In_Range_Scalar_Into
                    (A, Lower'Access, Upper'Access, A)
                  = C.Error_OpenCV,
                  "raw exact range translated rejection");
               Unchanged (A, D, Ch);
               Unchanged (Alias_A, D, Ch);
               Cleanup;
            end if;
         end loop;
      end loop;
      --  Raw ABI keeps native multichannel Compare: no public C1 duplication.
      for Into_Right in Boolean loop
         Prepare (0, 3);
         OK (C.UMat_Compare_Into (A, B, 0, (if Into_Right then B else A)));
         declare
            Host, Plane : aliased C.Mat_Handle := C.Null_Mat_Handle;
            Byte        : aliased C.C_UInt8;
         begin
            OK (C.UMat_To_Mat ((if Into_Right then B else A), Host'Access));
            for Ch in C.C_Int32 range 0 .. 2 loop
               OK (C.Mat_Extract_Channel (Host, Ch, Plane'Access));
               for R in C.C_Int32 range 0 .. 1 loop
                  for Col in C.C_Int32 range 0 .. 256 loop
                     OK (C.Mat_Get_UInt8 (Plane, R, Col, Byte'Access));
                     Assert (Byte = 255, "raw UInt8 C3 exact Compare allowed");
                  end loop;
               end loop;
               C.Mat_Destroy (Plane);
               Plane := C.Null_Mat_Handle;
            end loop;
            C.Mat_Destroy (Host);
         exception
            when others =>
               C.Mat_Destroy (Plane);
               C.Mat_Destroy (Host);
               raise;
         end;
         Cleanup;
      end loop;
   exception
      when others =>
         Cleanup;
         raise;
   end UMat_Exact_Aliases;

   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source, Half_Source, D, Parent, Region : aliased C.UMat_Handle :=
        C.Null_UMat_Handle;
      Value                                  : aliased C.Scalar :=
        (91.0, 0.0, 0.0, 0.0);
      procedure Cleanup is
      begin
         C.UMat_Destroy (Region);
         C.UMat_Destroy (Parent);
         C.UMat_Destroy (D);
         C.UMat_Destroy (Half_Source);
         C.UMat_Destroy (Source);
      end Cleanup;
   begin
      OK (C.UMat_Create_2D (2, 3, 0, 1, Source'Access));
      OK (C.UMat_Create_2D (1, 1, 7, 1, Half_Source'Access));
      OK (C.UMat_Create_2D (2, 3, 0, 1, D'Access));
      OK (C.UMat_Set_To (D, Value'Access));
      UMat_Checks.Run (Source, D);
      UMat_Checks.Half (Half_Source, D);
      OK (C.UMat_Create_2D (4, 6, 0, 1, Parent'Access));
      OK (C.UMat_Set_To (Parent, Value'Access));
      OK (C.UMat_Region (Parent, 1, 1, 3, 2, Region'Access));
      UMat_Checks.Run (Source, Region);
      UMat_Checks.Half (Half_Source, Region);
      declare
         Host : aliased C.Mat_Handle := C.Null_Mat_Handle;
         Byte : aliased C.C_UInt8;
      begin
         OK (C.UMat_To_Mat (Parent, Host'Access));
         for R in C.C_Int32 range 0 .. 3 loop
            for Col in C.C_Int32 range 0 .. 5 loop
               OK (C.Mat_Get_UInt8 (Host, R, Col, Byte'Access));
               Assert (Byte = 91, "raw UMat Region Parent unchanged");
            end loop;
         end loop;
         C.Mat_Destroy (Host);
      exception
         when others =>
            C.Mat_Destroy (Host);
            raise;
      end;
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end UMat_Check;
end Mask_Destination_Tests.Raw_ABI;
