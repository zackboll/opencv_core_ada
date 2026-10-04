with AUnit.Assertions;
with Interfaces;
with OpenCV.Internal.C_API;

package body Add_Subtract_Destination_Tests.Raw_ABI is
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
      Assert (Success = 1, "disable OpenCL for explicit CPU evidence");
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
      with function Add (Left, Right, Destination : Handle) return C.Status;
      with
        function Subtract (Left, Right, Destination : Handle) return C.Status;
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
      function Apply
        (A, B, Destination : Handle; Sub : Boolean) return C.Status;
      procedure Unchanged (Destination : Handle);
      procedure Run
        (Source, Destination : Handle; Inspect : access procedure := null);
   end Checks;

   package body Checks is
      function Apply
        (A, B, Destination : Handle; Sub : Boolean) return C.Status
      is (if Sub
          then Subtract (A, B, Destination)
          else Add (A, B, Destination));

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
            "pre-native shape/depth/channels unchanged");
         OK (Host_Copy (Destination, Host'Access));
         for Row in 0 .. 1 loop
            for Column in 0 .. 2 loop
               OK
                 (C.Mat_Get_UInt8
                    (Host, C.C_Int32 (Row), C.C_Int32 (Column), Pixel'Access));
               Assert (Pixel = 91, "every pre-native destination pixel");
            end loop;
         end loop;
         C.Mat_Destroy (Host);
      exception
         when others =>
            C.Mat_Destroy (Host);
            raise;
      end Unchanged;

      procedure Run
        (Source, Destination : Handle; Inspect : access procedure := null)
      is
         procedure Snapshot is
         begin
            Unchanged (Destination);
            if Inspect /= null then
               Inspect.all;
            end if;
         end Snapshot;
      begin
         for Sub in Boolean loop
            Snapshot;
            Assert
              (Apply (Null_Handle, Source, Destination, Sub)
               = C.Error_Invalid_Argument,
               "null Left");
            Snapshot;
            Assert
              (Apply (Source, Null_Handle, Destination, Sub)
               = C.Error_Invalid_Argument,
               "null Right");
            Snapshot;
            Assert
              (Apply (Source, Source, Null_Handle, Sub)
               = C.Error_Invalid_Argument,
               "null Destination");
            Snapshot;
         end loop;
      end Run;
   end Checks;

   package Mat_Checks is new
     Checks
       (C.Mat_Handle,
        C.Null_Mat_Handle,
        C.Mat_Add_Into,
        C.Mat_Subtract_Into,
        C.Mat_Rows,
        C.Mat_Columns,
        C.Mat_Depth,
        C.Mat_Channels,
        C.Mat_Clone);
   package UMat_Checks is new
     Checks
       (C.UMat_Handle,
        C.Null_UMat_Handle,
        C.UMat_Add_Into,
        C.UMat_Subtract_Into,
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
      procedure Padding is
      begin
         Assert
           (Data = (1 .. 10 => Character'Val (91)),
            "raw external pixels/padding unchanged after each failure");
      end Padding;
      procedure Parent_Pixels is
         Indices : C.C_Int32_Array := (0, 0, 0);
         Pixel   : aliased C.C_UInt8;
      begin
         for A in C.C_Int32 range 0 .. 1 loop
            for B in C.C_Int32 range 0 .. 1 loop
               for Col in C.C_Int32 range 0 .. 2 loop
                  Indices := (A, B, Col);
                  OK
                    (C.Mat_Get_UInt8_ND
                       (Volume, 3, Indices (0)'Access, Pixel'Access));
                  Assert (Pixel = 91, "every raw selected parent pixel");
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
      procedure Reject_Temporary (View : C.Mat_Handle) is
      begin
         for Sub in Boolean loop
            for Mismatch in Boolean loop
               Mat_Checks.Unchanged (View);
               Padding;
               Assert
                 (Mat_Checks.Apply
                    ((if Mismatch then Other else Source),
                     (if Mismatch then Other else Source),
                     View,
                     Sub)
                  = C.Error_Invalid_Argument,
                  "raw compatible/incompatible temporary destination");
               Mat_Checks.Unchanged (View);
               Padding;
            end loop;
         end loop;
      end Reject_Temporary;
   begin
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
      Reject_Temporary (External);
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
      Parent_Pixels;
      Mat_Checks.Run (Source, Selected, Parent_Pixels'Access);
      Reject_Temporary (Selected);
      Parent_Pixels;
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
end Add_Subtract_Destination_Tests.Raw_ABI;
