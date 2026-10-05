with AUnit.Assertions;
with Interfaces;
with OpenCV.Core.Module_Interop;
with OpenCV.Core.Int32_Access;
with OpenCV.Internal.C_API;

package body Weighted_Destination_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   package M renames OpenCV.Core.Module_Interop;
   use AUnit.Assertions;
   use type C.Status;
   use type C.C_Int32;
   use type C.C_UInt8;
   use type C.C_Double;
   function Oracle
     (Left, Right              : M.Input_Mat_Handle;
      Output                   : M.Output_Mat_Handle;
      Scaled, Alias_Mode, UMat : Interfaces.Unsigned_8;
      Alpha, Beta, Gamma       : C.C_Double) return Interfaces.Integer_32
   with Import, Convention => C, External_Name => "weighted_native_expected";
   function Native_Expected
     (Left, Right        : OpenCV.Core.Mat;
      Op                 : Operation_Kind;
      Alias_Mode         : Natural;
      Is_UMat            : Boolean;
      Alpha, Beta, Gamma : Long_Float) return OpenCV.Core.Mat
   is
      Result : OpenCV.Core.Mat;
      procedure L (LH : M.Input_Mat_Handle) is
         procedure R (RH : M.Input_Mat_Handle) is
            procedure Output (OH : M.Output_Mat_Handle) is
            begin
               Assert
                 (Oracle
                    (LH,
                     RH,
                     OH,
                     Boolean'Pos (Op = Scaled),
                     Interfaces.Unsigned_8 (Alias_Mode),
                     Boolean'Pos (Is_UMat),
                     C.C_Double (Alpha),
                     C.C_Double (Beta),
                     C.C_Double (Gamma))
                  = 1,
                  "separately constructed direct-native oracle");
            end Output;
         begin
            M.With_Output_Handle (Result, Output'Access);
         end R;
      begin
         M.With_Input_Handle (Right, R'Access);
      end L;
   begin
      M.With_Input_Handle (Left, L'Access);
      return Result;
   end Native_Expected;
   function Use_OpenCL return Interfaces.Unsigned_8
   with Import, Convention => C, External_Name => "umat_probe_use_opencl";
   function OpenCL_Enabled return Boolean
   is (Use_OpenCL /= 0);
   procedure Report_Int32_Backend (Result : OpenCV.Core.Mat) is
      procedure Build_Information
      with
        Import,
        Convention    => C,
        External_Name => "weighted_report_build_information";
   begin
      if OpenCV.Core.Int32_Access.Get (Result, 0, 0) /= 200000002 then
         Build_Information;
      end if;
   end Report_Int32_Backend;
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
      with
        function Weighted_Into
          (Left        : Handle;
           Alpha       : C.C_Double;
           Right       : Handle;
           Beta, Gamma : C.C_Double;
           Destination : Handle) return C.Status;
      with
        function Scaled_Into
          (Left        : Handle;
           Scale       : C.C_Double;
           Right       : Handle;
           Destination : Handle) return C.Status;
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
      function Into (A, B, D : Handle; Op : Operation_Kind) return C.Status;
      procedure Unchanged (Destination : Handle);
      procedure Run
        (Source, Destination : Handle; Inspect : access procedure := null);
   end Checks;
   package body Checks is
      function Into (A, B, D : Handle; Op : Operation_Kind) return C.Status
      is (if Op = Weighted
          then Weighted_Into (A, 2.0, B, -3.0, 5.0, D)
          else Scaled_Into (A, 2.5, B, D));
      procedure Unchanged (Destination : Handle) is
         Dim, R, Col, D, Ch : aliased C.C_Int32;
         Host               : aliased C.Mat_Handle := C.Null_Mat_Handle;
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
            "raw pre-native metadata preserved");
         OK (Host_Copy (Destination, Host'Access));
         for Row in C.C_Int32 range 0 .. 1 loop
            for Column in C.C_Int32 range 0 .. 2 loop
               OK (C.Mat_Get_UInt8 (Host, Row, Column, Pixel'Access));
               Assert (Pixel = 91, "every raw failure pixel");
            end loop;
         end loop;
         C.Mat_Destroy (Host);
      exception
         when others =>
            C.Mat_Destroy (Host);
            raise;
      end Unchanged;
      procedure Run
        (Source, Destination : Handle; Inspect : access procedure := null) is
      begin
         for Op in Operation_Kind loop
            for Mode in 0 .. 2 loop
               Assert
                 (Into
                    ((if Mode = 0 then Null_Handle else Source),
                     (if Mode = 1 then Null_Handle else Source),
                     (if Mode = 2 then Null_Handle else Destination),
                     Op)
                  = C.Error_Invalid_Argument,
                  "each null handle rejected");
               Unchanged (Destination);
               if Inspect /= null then
                  Inspect.all;
               end if;
            end loop;
         end loop;
      end Run;
   end Checks;
   package Mat_Checks is new
     Checks
       (C.Mat_Handle,
        C.Null_Mat_Handle,
        C.Mat_Add_Weighted_Into,
        C.Mat_Scale_Add_Into,
        C.Mat_Dimension_Count,
        C.Mat_Extent,
        C.Mat_Depth,
        C.Mat_Channels,
        C.Mat_Clone);
   package UMat_Checks is new
     Checks
       (C.UMat_Handle,
        C.Null_UMat_Handle,
        C.UMat_Add_Weighted_Into,
        C.UMat_Scale_Add_Into,
        C.UMat_Dimension_Count,
        C.UMat_Extent,
        C.UMat_Depth,
        C.UMat_Channels,
        C.UMat_To_Mat);
   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      function Special_Coefficients return C.C_Int32
      with
        Import,
        Convention    => C,
        External_Name => "weighted_special_coefficients";
      Source, Other, Destination, External, Volume, Selected :
        aliased C.Mat_Handle := C.Null_Mat_Handle;
      Value                                                  :
        aliased C.Scalar := (91.0, 0.0, 0.0, 0.0);
      Data                                                   :
        aliased C.C_UInt8_Array := (0 .. 9 => 91);
      Shape                                                  :
        C.C_Int32_Array := (2, 2, 3);
      Drops                                                  :
        C.C_UInt8_Array := (1, 0, 0);
      Starts                                                 :
        C.C_Int32_Array := (1, 0, 0);
      Stops                                                  :
        C.C_Int32_Array := (2, 2, 3);
      procedure Padding is
      begin
         for Pixel of Data loop
            Assert (Pixel = 91, "external pixels/padding preserved");
         end loop;
      end Padding;
      procedure Parent_Pixels is
         Indices : C.C_Int32_Array := (0, 0, 0);
         Pixel   : aliased C.C_UInt8;
      begin
         for I in C.C_Int32 range 0 .. 1 loop
            for J in C.C_Int32 range 0 .. 1 loop
               for K in C.C_Int32 range 0 .. 2 loop
                  Indices := (I, J, K);
                  OK
                    (C.Mat_Get_UInt8_ND
                       (Volume, 3, Indices (0)'Access, Pixel'Access));
                  Assert (Pixel = 91, "every selected Parent pixel");
               end loop;
            end loop;
         end loop;
      end Parent_Pixels;
      procedure Cleanup is
      begin
         C.Mat_Destroy (Selected);
         C.Mat_Destroy (Volume);
         C.Mat_Destroy (External);
         C.Mat_Destroy (Destination);
         C.Mat_Destroy (Other);
         C.Mat_Destroy (Source);
      end Cleanup;
      procedure Reject_Temporary
        (View : C.Mat_Handle; Inspect : not null access procedure) is
      begin
         for Op in Operation_Kind loop
            for Mismatch in Boolean loop
               Mat_Checks.Unchanged (View);
               Inspect.all;
               Assert
                 (Mat_Checks.Into
                    ((if Mismatch then Other else Source),
                     (if Mismatch then Other else Source),
                     View,
                     Op)
                  = C.Error_Invalid_Argument,
                  "raw capability rejection");
               Mat_Checks.Unchanged (View);
               Inspect.all;
            end loop;
         end loop;
      end Reject_Temporary;
   begin
      Assert (Special_Coefficients = 1, "raw nonfinite coefficient parity");
      OK (C.Mat_Create_2D (2, 3, 0, 1, Source'Access));
      OK (C.Mat_Create_2D (1, 2, 5, 1, Other'Access));
      OK (C.Mat_Create_2D (2, 3, 0, 1, Destination'Access));
      OK (C.Mat_Set_To (Source, Value'Access));
      OK (C.Mat_Set_To (Destination, Value'Access));
      Mat_Checks.Run (Source, Destination);
      OK
        (C.Mat_Create_External_2D_Strided
           (2, 3, 0, 1, Data'Address, 10, 5, External'Access));
      Mat_Checks.Run (Source, External, Padding'Access);
      Reject_Temporary (External, Padding'Access);
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
      Mat_Checks.Run (Source, Selected, Parent_Pixels'Access);
      Reject_Temporary (Selected, Parent_Pixels'Access);
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end Mat_Check;
   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source, Destination : aliased C.UMat_Handle := C.Null_UMat_Handle;
      Value               : aliased C.Scalar := (91.0, 0.0, 0.0, 0.0);
      procedure Cleanup is
      begin
         C.UMat_Destroy (Destination);
         C.UMat_Destroy (Source);
      end Cleanup;
   begin
      OK (C.UMat_Create_2D (2, 3, 0, 1, Source'Access));
      OK (C.UMat_Create_2D (2, 3, 0, 1, Destination'Access));
      OK (C.UMat_Set_To (Source, Value'Access));
      OK (C.UMat_Set_To (Destination, Value'Access));
      UMat_Checks.Run (Source, Destination);
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end UMat_Check;
end Weighted_Destination_Tests.Raw_ABI;
