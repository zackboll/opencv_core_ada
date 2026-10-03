with AUnit.Assertions;
with OpenCV.Internal.C_API;

package body ROI_Geometry_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use AUnit.Assertions;
   use type C.Status;
   use type C.C_Int32;
   use type C.C_Int32_Array;

   procedure OK (Status : C.Status) is
   begin
      Assert (Status = C.Success, "raw setup/query: " & C.Last_Error_Message);
   end OK;

   generic
      type Handle is private;
      Null_Handle : Handle;
      with
        function Locate
          (Source : Handle; Width, Height, X, Y : access C.C_Int32)
           return C.Status;
      with
        function Adjust
          (Self : Handle; Top, Bottom, Left, Right : C.C_Int32)
           return C.Status;
      with
        function Rows
          (Self : Handle; Value : access C.C_Int32) return C.Status;
      with
        function Columns
          (Self : Handle; Value : access C.C_Int32) return C.Status;
   package Checks is
      procedure Reject (Source : Handle);
      procedure Run (Whole, View, Empty, ND : Handle);
   end Checks;

   package body Checks is
      procedure Reject (Source : Handle) is
         Fields : C.C_Int32_Array (0 .. 3) := (others => 91);
      begin
         Assert
           (Locate
              (Source,
               Fields (0)'Access,
               Fields (1)'Access,
               Fields (2)'Access,
               Fields (3)'Access)
            = C.Error_Invalid_Argument,
            "raw invalid locate rejected");
         Assert (Fields = (0, 0, 0, 0), "all failure outputs cleared");
         Assert
           (Adjust (Source, 1, 1, 1, 1) = C.Error_Invalid_Argument,
            "raw invalid adjust rejected");
      end Reject;

      procedure Geometry
        (Source                          : Handle;
         Expected                        : C.C_Int32_Array;
         Expected_Rows, Expected_Columns : C.C_Int32)
      is
         Fields : C.C_Int32_Array (0 .. 3) := (others => -1);
         R, Col : aliased C.C_Int32 := -1;
      begin
         OK
           (Locate
              (Source,
               Fields (0)'Access,
               Fields (1)'Access,
               Fields (2)'Access,
               Fields (3)'Access));
         OK (Rows (Source, R'Access));
         OK (Columns (Source, Col'Access));
         Assert
           (Fields = Expected
            and then R = Expected_Rows
            and then Col = Expected_Columns,
            "raw exact header geometry");
      end Geometry;

      procedure Run (Whole, View, Empty, ND : Handle) is
         type Pointer is access all C.C_Int32;
         type Pointer_Array is array (Natural range 0 .. 3) of Pointer;
         Fields : C.C_Int32_Array (0 .. 3);
         P      : Pointer_Array;
         type Adjustments is array (Natural range 0 .. 3) of C.C_Int32;
         Args   : Adjustments;
      begin
         Reject (Null_Handle);
         Reject (Empty);
         Reject (ND);
         for Missing in P'Range loop
            Fields := (others => 91);
            for I in P'Range loop
               P (I) := Fields (I)'Access;
            end loop;
            P (Missing) := null;
            Assert
              (Locate (Whole, P (0), P (1), P (2), P (3))
               = C.Error_Invalid_Argument,
               "each output is required");
            for I in P'Range loop
               Assert
                 (Fields (I) = (if I = Missing then 91 else 0),
                  "every supplied output cleared on null-output failure");
            end loop;
         end loop;
         Geometry (Whole, (10, 8, 0, 0), 8, 10);
         Geometry (View, (10, 8, 2, 2), 3, 4);
         for Boundary in Args'Range loop
            Args := (others => 0);
            Args (Boundary) :=
              (if Boundary = 0 or else Boundary = 2
               then C.C_Int32'First
               else C.C_Int32'Last);
            Assert
              (Adjust (View, Args (0), Args (1), Args (2), Args (3))
               = C.Error_Invalid_Argument,
               "each native signed expression overflow is rejected");
            Geometry (View, (10, 8, 2, 2), 3, 4);
         end loop;
         OK (Adjust (View, 1, 1, 1, 1));
         Geometry (View, (10, 8, 1, 1), 5, 6);
         Geometry (Whole, (10, 8, 0, 0), 8, 10);
      end Run;
   end Checks;

   package Mat_Checks is new
     Checks
       (C.Mat_Handle,
        C.Null_Mat_Handle,
        C.Mat_Locate_ROI,
        C.Mat_Adjust_ROI,
        C.Mat_Rows,
        C.Mat_Columns);
   package UMat_Checks is new
     Checks
       (C.UMat_Handle,
        C.Null_UMat_Handle,
        C.UMat_Locate_ROI,
        C.UMat_Adjust_ROI,
        C.UMat_Rows,
        C.UMat_Columns);

   procedure Mat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Whole, View, Empty, ND, Temporary, Typed : aliased C.Mat_Handle :=
        C.Null_Mat_Handle;
      Shape                                    : C.C_Int32_Array := (2, 3, 4);
      Data                                     : aliased String (1 .. 20) :=
        (others => 'x');
      R, Col                                   : aliased C.C_Int32 := -1;
      procedure Cleanup is
      begin
         C.Mat_Destroy (Whole);
         C.Mat_Destroy (View);
         C.Mat_Destroy (Empty);
         C.Mat_Destroy (ND);
         C.Mat_Destroy (Temporary);
         C.Mat_Destroy (Typed);
      end Cleanup;
   begin
      OK (C.Mat_Create_2D (8, 10, 0, 1, Whole'Access));
      OK (C.Mat_Region (Whole, 2, 2, 4, 3, View'Access));
      OK (C.Mat_Create (Empty'Access));
      OK (C.Mat_Create_2D (0, 0, 2, 3, Typed'Access));
      OK (C.Mat_Create_ND (3, Shape (0)'Access, 0, 1, ND'Access));
      Mat_Checks.Run (Whole, View, Empty, ND);
      Mat_Checks.Reject (Typed);
      --  Collapsing at the bottom with X > 0 would form a Mat data pointer
      --  past one-past the allocation, even though rows would become zero.
      Assert
        (C.Mat_Adjust_ROI (View, -100, 100, 0, 0) = C.Error_Invalid_Argument,
         "unsafe empty data pointer rejected");
      declare
         W, H, X, Y : aliased C.C_Int32 := -1;
      begin
         OK (C.Mat_Locate_ROI (View, W'Access, H'Access, X'Access, Y'Access));
         Assert
           (W = 10 and then H = 8 and then X = 1 and then Y = 1,
            "unsafe empty-pointer failure leaves header unchanged");
      end;
      OK
        (C.Mat_Create_External_2D_Strided
           (4, 3, 0, 1, Data'Address, 20, 5, Temporary'Access));
      Mat_Checks.Reject (Temporary);
      OK (C.Mat_Rows (Temporary, R'Access));
      OK (C.Mat_Columns (Temporary, Col'Access));
      Assert
        (R = 4 and then Col = 3 and then Data = (1 .. 20 => 'x'),
         "raw temporary rejection preserves logical header and data");
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end Mat_Check;

   procedure UMat_Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Whole, View, Empty, ND, Typed : aliased C.UMat_Handle :=
        C.Null_UMat_Handle;
      Shape                         : C.C_Int32_Array := (2, 3, 4);
      procedure Cleanup is
      begin
         C.UMat_Destroy (Whole);
         C.UMat_Destroy (View);
         C.UMat_Destroy (Empty);
         C.UMat_Destroy (ND);
         C.UMat_Destroy (Typed);
      end Cleanup;
   begin
      OK (C.UMat_Create_2D (8, 10, 0, 1, Whole'Access));
      OK (C.UMat_Region (Whole, 2, 2, 4, 3, View'Access));
      OK (C.UMat_Create (Empty'Access));
      OK (C.UMat_Create_2D (0, 0, 2, 3, Typed'Access));
      OK (C.UMat_Create_ND (3, Shape (0)'Access, 0, 1, ND'Access));
      UMat_Checks.Run (Whole, View, Empty, ND);
      UMat_Checks.Reject (Typed);
      Cleanup;
   exception
      when others =>
         Cleanup;
         raise;
   end UMat_Check;
end ROI_Geometry_Tests.Raw_ABI;
