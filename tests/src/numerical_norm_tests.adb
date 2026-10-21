with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support; use Mat_Test_Support;
with OpenCV;           use OpenCV;
with OpenCV.Core;      use OpenCV.Core;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.UInt8_Mat_View;
with OpenCV.Core.Module_Interop;
with Interfaces.C;
with Numerical_Norm_Tests.Raw_ABI;
with Ada.Unchecked_Conversion;
with Interfaces;

package body Numerical_Norm_Tests is
   use type Float64_Value;
   use type UInt8_Mat_View.Buffer_Array;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   type Depth_List is array (Positive range <>) of Depth_Type;
   Depths : constant Depth_List :=
     (UInt8, Int8, UInt16, Int16, Float32, Float64);

   procedure Close (Actual, Expected : Long_Float);

   function Reference
     (Left, Right, Mask  : OpenCV.Core.Module_Interop.Input_Mat_Handle;
      Selector, Relative : Interfaces.C.int;
      Value              : access Interfaces.C.double) return Interfaces.C.int
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_numerical_norm_reference";

   function Special
     (Handle : OpenCV.Core.Module_Interop.Output_Mat_Handle;
      Kind   : Interfaces.C.int) return Interfaces.C.int
   with Import, Convention => C, External_Name => "opencv_core_norm_special";

   function Native_Same
     (Actual, Expected : Interfaces.C.double) return Interfaces.C.int
   with Import, Convention => C, External_Name => "opencv_core_norm_same";

   procedure Nonfinite_Parity (Test : in out Fixture) is
      pragma Unreferenced (Test);
      pragma Suppress (Validity_Check);
      use OpenCV.Core.Module_Interop;
      use type Interfaces.C.int;
      A : Mat := Create (1, 17, (Float64, 1));
      B : Mat := Create (1, 17, (Float64, 1));
      M : Mat := Create (1, 17, (UInt8, 1));
   begin
      B.Set_To (Make_Scalar (0.0));
      M.Set_To (Make_Scalar (2.0));
      for Kind in Interfaces.C.int range 0 .. 3 loop
         declare
            procedure Fill (Handle : Output_Mat_Handle) is
            begin
               Assert (Special (Handle, Kind) = 0, "native IEEE fixture");
            end Fill;
            procedure LH (Left : Input_Mat_Handle) is
               procedure RH (Right : Input_Mat_Handle) is
                  procedure MH (Mask : Input_Mat_Handle) is
                     Expected : aliased Interfaces.C.double := 0.0;
                  begin
                     for Norm in Norm_Kind loop
                        for Relative in Boolean loop
                           Assert
                             (Reference
                                (Left,
                                 Right,
                                 Mask,
                                 Norm_Kind'Pos (Norm) + 1,
                                 Boolean'Pos (Relative),
                                 Expected'Access)
                              = 0,
                              "nonfinite native reference");
                           Assert
                             (Native_Same
                                (Interfaces.C.double
                                   (Difference_Norm (A, B, M, Norm, Relative)),
                                 Expected)
                              = 1,
                              "nonfinite classification parity");
                        end loop;
                     end loop;
                     Assert
                       (Reference (Left, Right, Mask, 4, 0, Expected'Access)
                        = 0,
                        "squared IEEE oracle");
                     Assert
                       (Native_Same
                          (Interfaces.C.double
                             (Squared_L2_Difference_Norm (A, B, M)),
                           Expected)
                        = 1,
                        "squared IEEE parity");
                  end MH;
               begin
                  With_Input_Handle (M, MH'Access);
               end RH;
            begin
               With_Input_Handle (B, RH'Access);
            end LH;
         begin
            With_Output_Handle (A, Fill'Access);
            With_Input_Handle (A, LH'Access);
         end;
      end loop;
   end Nonfinite_Parity;

   procedure Native_Parity (Test : in out Fixture) is
      pragma Unreferenced (Test);
      use OpenCV.Core.Module_Interop;
      use type Interfaces.C.int;
      procedure Check
        (Left, Right, Mask : Mat;
         Selector          : Interfaces.C.int;
         Relative          : Boolean;
         Actual            : Long_Float)
      is
         Expected : aliased Interfaces.C.double := 0.0;
         procedure Left_Handle (LH : Input_Mat_Handle) is
            procedure Right_Handle (RH : Input_Mat_Handle) is
               procedure Mask_Handle (MH : Input_Mat_Handle) is
               begin
                  Assert
                    (Reference
                       (LH,
                        RH,
                        MH,
                        Selector,
                        Boolean'Pos (Relative),
                        Expected'Access)
                     = 0,
                     "independent native oracle succeeds");
               end Mask_Handle;
            begin
               With_Input_Handle (Mask, Mask_Handle'Access);
            end Right_Handle;
         begin
            With_Input_Handle (Right, Right_Handle'Access);
         end Left_Handle;
      begin
         With_Input_Handle (Left, Left_Handle'Access);
         Close (Actual, Long_Float (Expected));
      end Check;
      Empty_Mask : Mat;
   begin
      for Depth of Depths loop
         for Channels in Channel_Count range 1 .. 4 loop
            declare
               A : Mat := Create (2, 19, (Depth, Channels));
               B : Mat := Create (2, 19, (Depth, Channels));
               M : Mat := Create (2, 19, (UInt8, 1));
            begin
               A.Set_To (Make_Scalar (7.0, 5.0, 3.0, 1.0));
               B.Set_To (Make_Scalar (1.0, 2.0, 3.0, 4.0));
               M.Set_To (Make_Scalar (127.0));
               for Kind in Norm_Kind loop
                  for Relative in Boolean loop
                     Check
                       (A,
                        B,
                        Empty_Mask,
                        Norm_Kind'Pos (Kind) + 1,
                        Relative,
                        Difference_Norm (A, B, Kind, Relative));
                     Check
                       (A,
                        B,
                        M,
                        Norm_Kind'Pos (Kind) + 1,
                        Relative,
                        Difference_Norm (A, B, M, Kind, Relative));
                  end loop;
               end loop;
               Check (A, B, M, 4, False, Squared_L2_Difference_Norm (A, B, M));
               Check (A, A, M, -4, False, Squared_L2_Norm (A, M));
               Check (A, A, Empty_Mask, -4, False, Squared_L2_Norm (A));
               if Depth = UInt8 and then Channels = 1 then
                  for Cell in Binary_Norm_Kind loop
                     Check
                       (A,
                        B,
                        Empty_Mask,
                        Binary_Norm_Kind'Pos (Cell) + 5,
                        False,
                        Hamming_Pairwise_Norm (A, B, Cell));
                     Check
                       (A,
                        A,
                        Empty_Mask,
                        -(Binary_Norm_Kind'Pos (Cell) + 5),
                        False,
                        Hamming_Norm (A, Cell));
                  end loop;
               end if;
               Check
                 (A,
                  B,
                  Empty_Mask,
                  4,
                  False,
                  Squared_L2_Difference_Norm (A, B));
            end;
         end loop;
      end loop;
   end Native_Parity;

   procedure Close (Actual, Expected : Long_Float) is
   begin
      Assert
        (abs (Actual - Expected)
         <= 1.0E-6 * Long_Float'Max (1.0, abs Expected),
         "numeric result");
   end Close;

   procedure Numeric_Depths (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      for Depth of Depths loop
         for Channels in Channel_Count range 1 .. 4 loop
            declare
               A : Mat := Create (2, 17, (Depth, Channels));
               B : Mat := Create (2, 17, (Depth, Channels));
               N : constant Long_Float := 34.0 * Long_Float (Channels);
            begin
               A.Set_To (Make_Scalar (3.0, 3.0, 3.0, 3.0));
               B.Set_To (Make_Scalar (1.0, 1.0, 1.0, 1.0));
               Close (Squared_L2_Norm (A), 9.0 * N);
               Close (Squared_L2_Difference_Norm (A, B), 4.0 * N);
               Close (Difference_Norm (A, B, L1), 2.0 * N);
               Close (Difference_Norm (A, B, L2)**2, 4.0 * N);
               Close (Difference_Norm (A, B, Infinity), 2.0);
               for Kind in Norm_Kind loop
                  Close (Difference_Norm (A, B, Kind, Relative => True), 2.0);
               end loop;
            end;
         end loop;
      end loop;
   end Numeric_Depths;

   procedure Masks (Test : in out Fixture) is
      pragma Unreferenced (Test);
      --  Native IPP relative empty-selection results can be NaN. Keep IEEE
      --  handling local to this oracle comparison, not a global test option.
      pragma Suppress (Validity_Check);
      use OpenCV.Core.Module_Interop;
      use type Interfaces.C.int;
      procedure Relative_Matches_Native (A, B, M : Mat; Kind : Norm_Kind) is
         Expected : aliased Interfaces.C.double := 0.0;
         procedure LH (Left : Input_Mat_Handle) is
            procedure RH (Right : Input_Mat_Handle) is
               procedure MH (Mask : Input_Mat_Handle) is
               begin
                  Assert
                    (Reference
                       (Left,
                        Right,
                        Mask,
                        Norm_Kind'Pos (Kind) + 1,
                        1,
                        Expected'Access)
                     = 0,
                     "masked relative native oracle");
                  Assert
                    (Native_Same
                       (Interfaces.C.double
                          (Difference_Norm (A, B, M, Kind, True)),
                        Expected)
                     = 1,
                     "masked relative finite/nonfinite native parity");
               end MH;
            begin
               With_Input_Handle (M, MH'Access);
            end RH;
         begin
            With_Input_Handle (B, RH'Access);
         end LH;
      begin
         With_Input_Handle (A, LH'Access);
      end Relative_Matches_Native;
      Values : constant array (Natural range 0 .. 4) of UInt8_Value :=
        (0, 1, 2, 127, 255);
   begin
      for Depth of Depths loop
         for Channels in Channel_Count range 1 .. 4 loop
            declare
               A : Mat := Create (1, 5, (Depth, Channels));
               B : Mat := Create (1, 5, (Depth, Channels));
               M : Mat := Create (1, 5, (UInt8, 1));
               N : constant Long_Float := 4.0 * Long_Float (Channels);
            begin
               A.Set_To (Make_Scalar (3.0, 3.0, 3.0, 3.0));
               B.Set_To (Make_Scalar (1.0, 1.0, 1.0, 1.0));
               for Column in Values'Range loop
                  UInt8_Access.Set (M, 0, Column, Values (Column));
               end loop;
               Close (Squared_L2_Norm (A, M), N * 9.0);
               Close (Squared_L2_Difference_Norm (A, B, M), N * 4.0);
               Close (Difference_Norm (A, B, M, L1), N * 2.0);
               Close (Difference_Norm (A, B, M, L2)**2, N * 4.0);
               Close (Difference_Norm (A, B, M, Infinity), 2.0);
               for Kind in Norm_Kind loop
                  Close (Difference_Norm (A, B, M, Kind, True), 2.0);
               end loop;
               M.Set_To (Make_Scalar (0.0));
               Close (Squared_L2_Norm (A, M), 0.0);
               Close (Squared_L2_Difference_Norm (A, B, M), 0.0);
               for Kind in Norm_Kind loop
                  Relative_Matches_Native (A, B, M, Kind);
                  Relative_Matches_Native
                    (A => B, B => A, M => M, Kind => Kind);
               end loop;
            end;
         end loop;
      end loop;
   end Masks;

   procedure Extrema (Test : in out Fixture) is
      pragma Unreferenced (Test);
      type Bounds is record
         Low, High : Long_Float;
      end record;
      Limits : constant array (UInt8 .. Int16) of Bounds :=
        ((0.0, 255.0),
         (-128.0, 127.0),
         (0.0, 65_535.0),
         (-32_768.0, 32_767.0));
   begin
      for Depth in UInt8 .. Int16 loop
         declare
            A : Mat := Create (1, 9, (Depth, 1));
            B : Mat := Create (1, 9, (Depth, 1));
            D : constant Long_Float :=
              Limits (Depth).High - Limits (Depth).Low;
         begin
            A.Set_To (Make_Scalar (Limits (Depth).Low));
            B.Set_To (Make_Scalar (Limits (Depth).High));
            Close (Difference_Norm (A, B, Infinity), D);
            Close (Difference_Norm (A, B, L1), 9.0 * D);
            Close (Squared_L2_Difference_Norm (A, B), 9.0 * D * D);
            Close (Squared_L2_Norm (A), 9.0 * Limits (Depth).Low**2);
         end;
      end loop;
   end Extrema;

   procedure ND_And_ROI (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A : Mat := Create (Shape => (2, 3, 4), Element_Type => (Float64, 3));
      B : Mat := Create (Shape => (2, 3, 4), Element_Type => (Float64, 3));
      M : Mat := Create (Shape => (2, 3, 4), Element_Type => (UInt8, 1));
      P : Mat := Create (4, 9, (Float64, 1));
      Q : Mat := Create (4, 9, (Float64, 1));
      R : Mat := Create (4, 9, (UInt8, 1));
   begin
      A.Set_To (Make_Scalar (3.0, 3.0, 3.0));
      B.Set_To (Make_Scalar (1.0, 1.0, 1.0));
      M.Set_To (Make_Scalar (2.0));
      Close (Difference_Norm (A, B, M, L1), 144.0);
      Close (Squared_L2_Norm (A, M), 648.0);
      Close (Squared_L2_Difference_Norm (A, B, M), 288.0);
      P.Set_To (Make_Scalar (3.0));
      Q.Set_To (Make_Scalar (1.0));
      R.Set_To (Make_Scalar (127.0));
      declare
         Left  : constant Mat := P.Region ((1, 1, 5, 2));
         Right : constant Mat := Q.Region ((1, 1, 5, 2));
         Mask  : constant Mat := R.Region ((1, 1, 5, 2));
      begin
         Assert (not Left.Is_Continuous, "ROI noncontiguous");
         Close (Difference_Norm (Left, Right, Mask, L1), 20.0);
         Close (Squared_L2_Difference_Norm (Left, Right), 40.0);
      end;
   end ND_And_ROI;

   procedure Binary_Patterns (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A   : Mat := Create (1, 3, (UInt8, 1));
      B   : Mat := Create (1, 3, (UInt8, 1));
      Old : constant Batch_Distance_Kind := Hamming_Distance;
   begin
      A.Set_To (Make_Scalar (3.0));
      B.Set_To (Make_Scalar (0.0));
      declare
         Neighbors : constant Nearest_Neighbor_Result :=
           K_Nearest_Neighbors
             (Queries => A, Candidates => B, Neighbor_Count => 1, Kind => Old);
      begin
         Assert
           (Neighbors.Distances.Total = 1, "existing named calls compile");
      end;
      Close (Hamming_Norm (A), 6.0);
      Close (Hamming_Norm (A, Two_Bits), 3.0);
      Close (Hamming_Pairwise_Norm (A, B), 6.0);
      Close (Hamming_Pairwise_Norm (A, B, Two_Bits), 3.0);
      A.Set_To (Make_Scalar (255.0));
      B.Set_To (Make_Scalar (85.0));
      Close (Hamming_Pairwise_Norm (A, B), 12.0);
      Close (Hamming_Pairwise_Norm (A, B, Two_Bits), 12.0);
      Close (Hamming_Norm (A), 24.0);
      Close (Hamming_Norm (A, Two_Bits), 12.0);
   end Binary_Patterns;

   procedure Borrowed_Strides (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data : aliased constant UInt8_Mat_View.Buffer_Array := (0 .. 19 => 3);
      procedure Check (Image : Mat) is
      begin
         Close (Squared_L2_Norm (Image, Image), 90.0);
         Close (Squared_L2_Difference_Norm (Image, Image, Image), 0.0);
         Close (Difference_Norm (Image, Image, Image, L1), 0.0);
         Close (Hamming_Norm (Image), 20.0);
         Close (Hamming_Norm (Image, Two_Bits), 10.0);
         Close (Hamming_Pairwise_Norm (Image, Image), 0.0);
         Close (Hamming_Pairwise_Norm (Image, Image, Two_Bits), 0.0);
      end Check;
   begin
      UInt8_Mat_View.With_Read_Only_Strided_Mat_View
        (Data, 2, 5, 10, Check'Access);
      Assert
        (Data = UInt8_Mat_View.Buffer_Array'(0 .. 19 => 3),
         "borrowed storage and padding unchanged");
   end Borrowed_Strides;

   procedure Rejections (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A : constant Mat := Create (2, 3, (UInt8, 1));
      procedure Reject (B : Mat; Is_Mask : Boolean := False) is
         procedure Attempt is
            Value : Long_Float;
         begin
            Value :=
              (if Is_Mask
               then Difference_Norm (A, A, B)
               else Difference_Norm (A, B));
            Close (Value, -1.0);
         end Attempt;
      begin
         Assert_Raises_OpenCV_Error (Attempt'Access, "invalid norm input");
      end Reject;
      procedure Excluded (D : Depth_Type) is
         B : constant Mat := Create (2, 3, (D, 1));
         procedure Unary is
         begin
            Close (Squared_L2_Norm (B), -1.0);
         end Unary;
         procedure Pair is
         begin
            Close (Squared_L2_Difference_Norm (B, B), -1.0);
         end Pair;
         procedure Binary is
         begin
            Close (Hamming_Norm (B), -1.0);
         end Binary;
      begin
         Reject (B);
         Assert_Raises_OpenCV_Error (Unary'Access, "excluded unary depth");
         Assert_Raises_OpenCV_Error (Pair'Access, "excluded squared depth");
         Assert_Raises_OpenCV_Error (Binary'Access, "binary depth");
      end Excluded;
   begin
      Excluded (Int32);
      Excluded (Float16);
      Reject (Create (3, 2, (UInt8, 1)));
      Reject (Create (2, 3, (UInt8, 2)));
      Reject (Create (2, 3, (Float32, 1)));
      Reject (Create (Shape => (2, 1, 3), Element_Type => (UInt8, 1)));
      Reject (Create (2, 3, (Int8, 1)), True);
      Reject (Create (2, 3, (UInt8, 2)), True);
      Reject (Create (3, 2, (UInt8, 1)), True);
      Reject (Create (Shape => (2, 1, 3), Element_Type => (UInt8, 1)), True);
      declare
         Left  : constant Mat :=
           Create (Shape => (2, 3, 4), Element_Type => (Float64, 1));
         Right : constant Mat :=
           Create (Shape => (2, 4, 3), Element_Type => (Float64, 1));
         procedure Attempt is
         begin
            Close (Difference_Norm (Left, Right), -1.0);
         end Attempt;
         procedure Binary is
            Multi : constant Mat := Create (2, 3, (UInt8, 2));
         begin
            Close (Hamming_Pairwise_Norm (Multi, Multi), -1.0);
         end Binary;
      begin
         Assert_Raises_OpenCV_Error (Attempt'Access, "N-D extent mismatch");
         Assert_Raises_OpenCV_Error (Binary'Access, "binary multichannel");
      end;
   end Rejections;

   procedure Empty_Inputs (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Empty : Mat;
   begin
      Close (Squared_L2_Norm (Empty), 0.0);
      Close (Squared_L2_Norm (Empty, Empty), 0.0);
      Close (Squared_L2_Difference_Norm (Empty, Empty, Empty), 0.0);
      Close (Difference_Norm (Empty, Empty, Relative => True), 0.0);
      Close (Hamming_Norm (Empty), 0.0);
      Close (Hamming_Pairwise_Norm (Empty, Empty), 0.0);
      for Depth of Depths loop
         declare
            A : constant Mat := Create (0, 3, (Depth, 1));
            B : constant Mat := Create (0, 3, (Depth, 1));
            M : constant Mat := Create (0, 3, (UInt8, 1));
            procedure Mixed is
            begin
               Close (Difference_Norm (Empty, A), -1.0);
            end Mixed;
         begin
            Close (Squared_L2_Norm (A, M), 0.0);
            Close (Difference_Norm (A, B, M, Relative => True), 0.0);
            Assert_Raises_OpenCV_Error
              (Mixed'Access, "empty shape/type checked");
         end;
      end loop;
   end Empty_Inputs;

   procedure Conversion_Precision (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A : Mat := Create (1, 1, (Int32, 1));
      B : Mat := Create (1, 1, (Int32, 1));
      F : Mat := Create (1, 1, (Float64, 1));
      Z : Mat := Create (1, 1, (Float64, 1));
   begin
      Int32_Access.Set (A, 0, 0, Int32_Value'First);
      Int32_Access.Set (B, 0, 0, Int32_Value'Last);
      Close
        (Difference_Norm
           (A.Convert_To (Float64), B.Convert_To (Float64), Infinity),
         4_294_967_295.0);
      Float64_Access.Set (F, 0, 0, 1.0 + 2.0**(-40));
      Float64_Access.Set (Z, 0, 0, 1.0);
      Assert
        (Difference_Norm (F, Z, Infinity) = 2.0**(-40),
         "Float64 small residual preserved");
      Float64_Access.Set (F, 0, 0, 1.0 + 2.0**(-20));
      Assert
        (Difference_Norm
           (F.Convert_To (Float32), Z.Convert_To (Float32), Infinity)
         = 2.0**(-20),
         "Float32 representable small residual preserved");
      Z.Set_To (Make_Scalar (0.0));
      Float64_Access.Set (F, 0, 0, 1.0);
      Close (Difference_Norm (F, Z, L1, True), 2.0**52);
      Float64_Access.Set (Z, 0, 0, 1.0E-300);
      Close (Difference_Norm (F, Z, L2, True), 2.0**52);
   end Conversion_Precision;

   procedure Aliases_And_Repetition (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A : Mat := Create (2, 3, (Float64, 1));
      B : Mat := Create (2, 3, (Float64, 1));
   begin
      A.Set_To (Make_Scalar (3.0));
      B.Set_To (Make_Scalar (1.0));
      declare
         Alias : constant Mat := A;
         Copy  : constant Mat := A.Clone;
         First : constant Long_Float := Difference_Norm (A, B, L1);
      begin
         for Repeat in 1 .. 25 loop
            Close (Difference_Norm (A, B, L1), First);
            Close (Squared_L2_Norm (A), 54.0);
            Close (Difference_Norm (Alias, Copy), 0.0);
            Close (Squared_L2_Norm (B), 6.0);
         end loop;
         Close (First, 12.0);
      end;
   end Aliases_And_Repetition;

   procedure ND_Strided_Masks (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data : aliased constant UInt8_Mat_View.Buffer_Array := (0 .. 47 => 3);
      procedure Check (Image : Mat) is
         procedure Check_Mask (Mask : Mat) is
         begin
            Close (Squared_L2_Norm (Image, Mask), 216.0);
            Close (Difference_Norm (Image, Image, Mask, L1), 0.0);
            Close (Squared_L2_Difference_Norm (Image, Image, Mask), 0.0);
            Close (Hamming_Norm (Image), 48.0);
            Close (Hamming_Norm (Image, Two_Bits), 24.0);
            Close (Hamming_Pairwise_Norm (Image, Image), 0.0);
            Close (Hamming_Pairwise_Norm (Image, Image, Two_Bits), 0.0);
         end Check_Mask;
      begin
         UInt8_Mat_View.With_Read_Only_Strided_Mat_View
           (Data,
            Shape   => (2, 3, 4),
            Strides => (24, 8, 1),
            Process => Check_Mask'Access);
      end Check;
   begin
      UInt8_Mat_View.With_Read_Only_Strided_Mat_View
        (Data,
         Shape   => (2, 3, 4),
         Strides => (24, 8, 1),
         Process => Check'Access);
   end ND_Strided_Masks;

   procedure Invalid_Binary_Selector (Test : in out Fixture) is
      pragma Unreferenced (Test);
      pragma Suppress (Validity_Check);
      --  Deliberately corrupt the enum's object representation, not its
      --  one-bit value representation, to exercise the explicit guard.
      pragma
        Warnings (Off, "types for unchecked conversion have different sizes");
      function Invalid is new
        Ada.Unchecked_Conversion (Interfaces.Unsigned_8, Binary_Norm_Kind);
      pragma
        Warnings (On, "types for unchecked conversion have different sizes");
      A : constant Mat := Create (1, 1, (UInt8, 1));
      procedure Unary is
      begin
         Close (Hamming_Norm (A, Invalid (99)), -1.0);
      end Unary;
      procedure Pair is
      begin
         Close (Hamming_Pairwise_Norm (A, A, Invalid (99)), -1.0);
      end Pair;
   begin
      Assert_Raises_OpenCV_Error
        (Unary'Access, "invalid binary unary selector");
      Assert_Raises_OpenCV_Error (Pair'Access, "invalid binary pair selector");
   end Invalid_Binary_Selector;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create ("Norm N-D strided masks", ND_Strided_Masks'Access));
      Result.Add_Test
        (Caller.Create
           ("Norm invalid binary selectors", Invalid_Binary_Selector'Access));
      Result.Add_Test
        (Caller.Create
           ("Norm independent native parity", Native_Parity'Access));
      Result.Add_Test
        (Caller.Create
           ("Norm nonfinite native parity", Nonfinite_Parity'Access));
      Result.Add_Test
        (Caller.Create ("Norm raw ABI negative controls", Raw_ABI.Run'Access));
      Result.Add_Test
        (Caller.Create ("Numerical norms six depths", Numeric_Depths'Access));
      Result.Add_Test
        (Caller.Create ("Numerical selector masks", Masks'Access));
      Result.Add_Test
        (Caller.Create ("Numerical integer extrema", Extrema'Access));
      Result.Add_Test
        (Caller.Create ("Numerical N-D and ROI", ND_And_ROI'Access));
      Result.Add_Test
        (Caller.Create ("Binary bit/cell patterns", Binary_Patterns'Access));
      Result.Add_Test
        (Caller.Create
           ("Norm borrowed strided aliases", Borrowed_Strides'Access));
      Result.Add_Test
        (Caller.Create ("Numerical norm rejections", Rejections'Access));
      Result.Add_Test
        (Caller.Create ("Norm empty input contracts", Empty_Inputs'Access));
      Result.Add_Test
        (Caller.Create
           ("Norm conversion and precision", Conversion_Precision'Access));
      Result.Add_Test
        (Caller.Create
           ("Norm aliases and repetition", Aliases_And_Repetition'Access));
      return Result'Access;
   end Suite;
end Numerical_Norm_Tests;
