with AUnit.Assertions;
with Interfaces;
with OpenCV.Internal.C_API;

package body Normalize_Destination_Tests.Raw_ABI is
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
      Assert (Success = 1, "disable OpenCL for CPU compatibility evidence");
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
      Assert (Status = C.Success, "raw query: " & C.Last_Error_Message);
   end OK;

   generic
      type Handle is private;
      Null_Handle : Handle;
      with
        function Normalize
          (Source, Destination : Handle;
           Kind                : C.C_Int32;
           Alpha, Beta         : C.C_Double) return C.Status;
      with
        function Rows
          (Self : Handle; Value : access C.C_Int32) return C.Status;
      with
        function Columns
          (Self : Handle; Value : access C.C_Int32) return C.Status;
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
      procedure Run (Source, Destination : Handle);
      procedure Unchanged (Destination : Handle);
   end Checks;

   package body Checks is
      procedure Unchanged (Destination : Handle) is
         R, Col, D, Ch : aliased C.C_Int32;
         Host          : aliased C.Mat_Handle := C.Null_Mat_Handle;
         Pixel         : aliased C.C_UInt8;
      begin
         OK (Rows (Destination, R'Access));
         OK (Columns (Destination, Col'Access));
         OK (Depth (Destination, D'Access));
         OK (Channels (Destination, Ch'Access));
         Assert
           (R = 2 and then Col = 3 and then D = 0 and then Ch = 1,
            "pre-native failure retains geometry/type");
         OK (Host_Copy (Destination, Host'Access));
         for Row in 0 .. 1 loop
            for Column in 0 .. 2 loop
               OK
                 (C.Mat_Get_UInt8
                    (Host, C.C_Int32 (Row), C.C_Int32 (Column), Pixel'Access));
               Assert (Pixel = 91, "pre-native failure retains every pixel");
            end loop;
         end loop;
         C.Mat_Destroy (Host);
      exception
         when others =>
            C.Mat_Destroy (Host);
            raise;
      end Unchanged;

      procedure Run (Source, Destination : Handle) is
      begin
         Assert
           (Normalize (Null_Handle, Destination, C.Normalize_L2, 10.0, 2.0)
            = C.Error_Invalid_Argument,
            "null source rejects");
         Unchanged (Destination);
         Assert
           (Normalize (Source, Null_Handle, C.Normalize_L2, 10.0, 2.0)
            = C.Error_Invalid_Argument,
            "null destination rejects");
         Unchanged (Destination);
         Unchanged (Source);
         for Invalid of C.C_Int32_Array'(-1, 0, 5, C.C_Int32'Last) loop
            Assert
              (Normalize (Source, Destination, Invalid, 10.0, 2.0)
               = C.Error_Invalid_Argument,
               "invalid raw kind rejects");
            Unchanged (Destination);
         end loop;
      end Run;
   end Checks;

   package Mat_Checks is new
     Checks
       (C.Mat_Handle,
        C.Null_Mat_Handle,
        C.Mat_Normalize_Into,
        C.Mat_Rows,
        C.Mat_Columns,
        C.Mat_Depth,
        C.Mat_Channels,
        C.Mat_Clone);
   package UMat_Checks is new
     Checks
       (C.UMat_Handle,
        C.Null_UMat_Handle,
        C.UMat_Normalize_Into,
        C.UMat_Rows,
        C.UMat_Columns,
        C.UMat_Depth,
        C.UMat_Channels,
        C.UMat_To_Mat);

   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Source, Other, Destination, External, Volume, Selected :
        aliased C.Mat_Handle := C.Null_Mat_Handle;
      Value                                                  :
        aliased C.Scalar := (91.0, 0.0, 0.0, 0.0);
      Data                                                   :
        aliased String (1 .. 10) := (others => Character'Val (91));
      Shape                                                  :
        C.C_Int32_Array := (2, 2, 3);
      Drops                                                  :
        aliased C.C_UInt8_Array := (1, 0, 0);
      Starts                                                 :
        C.C_Int32_Array := (1, 0, 0);
      Stops                                                  :
        C.C_Int32_Array := (2, 2, 3);
      procedure Cleanup is
      begin
         C.Mat_Destroy (Selected);
         C.Mat_Destroy (Volume);
         C.Mat_Destroy (External);
         C.Mat_Destroy (Destination);
         C.Mat_Destroy (Other);
         C.Mat_Destroy (Source);
      end Cleanup;
      procedure Reject_Temporary (View : C.Mat_Handle) is
      begin
         Assert
           (C.Mat_Normalize_Into (Source, View, C.Normalize_Inf, 8.0, 0.0)
            = C.Error_Invalid_Argument,
            "compatible temporary rejects");
         Mat_Checks.Unchanged (View);
         Assert
           (C.Mat_Normalize_Into (Other, View, C.Normalize_L2, 10.0, 0.0)
            = C.Error_Invalid_Argument,
            "incompatible temporary rejects");
         Mat_Checks.Unchanged (View);
         OK
           (C.Mat_Normalize_Into
              (View, Destination, C.Normalize_Inf, 91.0, 0.0));
         Mat_Checks.Unchanged (Destination);
      end Reject_Temporary;
   begin
      OK (C.Mat_Create_2D (2, 3, 0, 1, Source'Access));
      OK (C.Mat_Create_2D (1, 2, 5, 1, Other'Access));
      OK (C.Mat_Set_To (Other, Value'Access));
      OK (C.Mat_Create_2D (2, 3, 0, 1, Destination'Access));
      OK (C.Mat_Set_To (Source, Value'Access));
      OK (C.Mat_Set_To (Destination, Value'Access));
      Mat_Checks.Run (Source, Destination);
      OK
        (C.Mat_Create_External_2D_Strided
           (2, 3, 0, 1, Data'Address, 10, 5, External'Access));
      Reject_Temporary (External);
      Assert
        (Data = (1 .. 10 => Character'Val (91)),
         "raw external pixels and padding unchanged");
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
      Reject_Temporary (Selected);
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
end Normalize_Destination_Tests.Raw_ABI;
