with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Unchecked_Conversion;
with Interfaces;
with Interfaces.C;
with Mat_Test_Support; use Mat_Test_Support;
with OpenCV;           use OpenCV;
with OpenCV.Core;      use OpenCV.Core;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.UInt8_Mat_View;
with OpenCV.Core.Module_Interop;
with Scalar_Modes_Tests.Raw_ABI;

package body Scalar_Modes_Tests is
   use type Float64_Value;
   use type UInt8_Value;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   type Operation is
     (Plus, Minus, Product, Quotient, Reverse_Sub, Reverse_Div);
   type Depth_List is array (Positive range <>) of Depth_Type;
   Depths : constant Depth_List :=
     (UInt8, Int8, UInt16, Int16, Int32, Float32, Float64);

   function Native_Reference
     (Depth, Channels, Op, Channel, Row, Column : Interfaces.C.int;
      Actual, Destination, Intermediate, Oracle : Interfaces.C.double)
      return Interfaces.C.double
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_scalar_numeric_reference";

   function Calculate (A : Mat; V : Scalar; Op : Operation) return Mat is
   begin
      case Op is
         when Plus        =>
            return Add (A, V);

         when Minus       =>
            return Subtract (A, V);

         when Product     =>
            return Multiply (A, V);

         when Quotient    =>
            return Divide (A, V);

         when Reverse_Sub =>
            return Subtract_From (V, A);

         when Reverse_Div =>
            return Divide_Into (V, A);
      end case;
   end Calculate;

   procedure Apply (A : Mat; V : Scalar; Op : Operation; D : in out Mat) is
   begin
      case Op is
         when Plus        =>
            Add (A, V, D);

         when Minus       =>
            Subtract (A, V, D);

         when Product     =>
            Multiply (A, V, D);

         when Quotient    =>
            Divide (A, V, D);

         when Reverse_Sub =>
            Subtract_From (V, A, D);

         when Reverse_Div =>
            Divide_Into (V, A, D);
      end case;
   end Apply;

   function Pixel
     (A       : Mat;
      Channel : Natural := 0;
      Row     : Natural := 0;
      Column  : Natural := 0) return Long_Float
   is
      Single : constant Mat :=
        (if A.Channels = 1 then A else A.Extract_Channel (Channel));
      Values : constant Mat := Single.Convert_To (Float64);
   begin
      return Long_Float (Float64_Access.Get (Values, Row, Column));
   end Pixel;

   procedure Same (A, B : Mat; Message : String) is
   begin
      Assert
        (A.Shape = B.Shape
         and then A.Depth = B.Depth
         and then A.Channels = B.Channels,
         Message & " metadata");
      Assert (A.Abs_Diff (B).Norm < 0.000_001, Message & " values");
   end Same;

   procedure Depth_Channels (Test : in out Fixture) is
      pragma Unreferenced (Test);
      V : constant Scalar := Make_Scalar (2.0, 4.0, 8.0, 16.0);
   begin
      for Depth of Depths loop
         for Channels in Channel_Count range 1 .. 4 loop
            for Op in Operation loop
               declare
                  A : Mat := Create (2, 257, (Depth, Channels));
                  D : Mat;
               begin
                  A.Set_To (Make_Scalar (8.0, 8.0, 8.0, 8.0));
                  declare
                     F : constant Mat := Calculate (A, V, Op);
                  begin
                     Apply (A, V, Op, D);
                     Same (D, F, "depth/channel forms");
                     for Channel in 0 .. Natural (Channels) - 1 loop
                        declare
                           Coefficient : constant Long_Float :=
                             2.0**(Channel + 1);
                           Expected    : Long_Float;
                           Reference   : Mat := Create (1, 1, (Float64, 1));
                        begin
                           case Op is
                              when Plus        =>
                                 Expected := 8.0 + Coefficient;

                              when Minus       =>
                                 Expected := 8.0 - Coefficient;

                              when Product     =>
                                 Expected := 8.0 * Coefficient;

                              when Quotient    =>
                                 Expected := 8.0 / Coefficient;

                              when Reverse_Sub =>
                                 Expected := Coefficient - 8.0;

                              when Reverse_Div =>
                                 Expected := Coefficient / 8.0;
                           end case;
                           Float64_Access.Set
                             (Reference, 0, 0, Float64_Value (Expected));
                           declare
                              Native : constant Long_Float :=
                                Long_Float
                                  (Native_Reference
                                     (Interfaces.C.int
                                        (Depth_Type'Pos (Depth)),
                                      Interfaces.C.int (Channels),
                                      Interfaces.C.int (Operation'Pos (Op)),
                                      Interfaces.C.int (Channel),
                                      0,
                                      0,
                                      Interfaces.C.double (Pixel (F, Channel)),
                                      Interfaces.C.double (Pixel (D, Channel)),
                                      Interfaces.C.double (Expected),
                                      Interfaces.C.double
                                        (Pixel
                                           (Reference.Convert_To (Depth)))));
                           begin
                              Assert
                                (abs (Pixel (F, Channel) - Native) < 0.001,
                                 "independent native scalar result");
                           end;
                           --  Conversion of a one-pixel double is not an
                           --  oracle for arithmetic SIMD rounding at ties.
                           --  Keep mathematical checks at integral results.
                           if Expected = Long_Float'Floor (Expected) then
                              Assert
                                (abs (Pixel (F, Channel)
                                      - Pixel (Reference.Convert_To (Depth)))
                                 < 0.001,
                                 "integral channel and direction");
                           end if;
                           declare
                              Native_Tail : constant Long_Float :=
                                Long_Float
                                  (Native_Reference
                                     (Interfaces.C.int
                                        (Depth_Type'Pos (Depth)),
                                      Interfaces.C.int (Channels),
                                      Interfaces.C.int (Operation'Pos (Op)),
                                      Interfaces.C.int (Channel),
                                      1,
                                      256,
                                      Interfaces.C.double
                                        (Pixel (F, Channel, 1, 256)),
                                      Interfaces.C.double
                                        (Pixel (D, Channel, 1, 256)),
                                      Interfaces.C.double (Expected),
                                      Interfaces.C.double
                                        (Pixel
                                           (Reference.Convert_To (Depth)))));
                           begin
                              Assert
                                (abs (Pixel (F, Channel, 1, 256) - Native_Tail)
                                 < 0.001,
                                 "independent native SIMD tail");
                           end;
                        end;
                     end loop;
                     Assert (Pixel (A) = 8.0, "source unchanged");
                  end;
               end;
            end loop;
         end loop;
      end loop;
   end Depth_Channels;

   procedure Mapping (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A : Mat := Create (1, 1, (Float64, 4));
   begin
      A.Set_To (Make_Scalar (2.0, 3.0, 4.0, 5.0));
      declare
         B : constant Mat := Add (A, Make_Scalar (5.0));
         C : constant Mat := Multiply (A, Make_Scalar (2.0));
      begin
         Assert
           (Pixel (B) = 7.0
            and then Pixel (B, 1) = 3.0
            and then Pixel (B, 3) = 5.0,
            "scalar not repeated");
         Assert
           (Pixel (C) = 4.0 and then Pixel (C, 1) = 0.0,
            "unused components zero");
      end;
   end Mapping;

   procedure Reuse (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      for Op in Operation loop
         for Depth of Depths loop
            declare
               P     : Mat := Create (5, 263, (Depth, 3));
               A     : Mat := P.Region ((2, 1, 257, 3));
               DP    : Mat := Create (5, 263, (Depth, 3));
               D     : Mat := DP.Region ((2, 1, 257, 3));
               Alias : constant Mat := D;
               V     : constant Scalar := Make_Scalar (2.0, 4.0, 8.0);
            begin
               P.Set_To (Make_Scalar (8.0, 8.0, 8.0));
               DP.Set_To (Make_Scalar (91.0, 91.0, 91.0));
               declare
                  Expected : constant Mat := Calculate (A, V, Op);
                  Saved    : constant Mat := A.Clone;
               begin
                  Apply (A, V, Op, D);
                  Same (D, Expected, "ROI output");
                  Same (Alias, Expected, "destination sharing");
                  Same (A, Saved, "source unchanged");
                  Assert (Pixel (DP) = 91.0, "parent guard");
                  Apply (A, V, Op, A);
                  Same (A, Expected, "exact alias");
                  Assert (Pixel (Saved) = 8.0, "clone independent");
               end;
            end;
         end loop;
      end loop;
   end Reuse;

   procedure Detach (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      for Op in Operation loop
         declare
            A   : Mat := Create (2, 257, (UInt8, 1));
            D   : Mat := Create (1, 1, (Float32, 1));
            Old : constant Mat := D;
         begin
            A.Set_To (Make_Scalar (8.0));
            D.Set_To (Make_Scalar (91.0));
            Apply (A, Make_Scalar (2.0), Op, D);
            Same (D, Calculate (A, Make_Scalar (2.0), Op), "detach");
            Assert (Pixel (Old) = 91.0, "old allocation retained");
         end;
      end loop;
   end Detach;

   procedure Shallow (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      for Op in Operation loop
         declare
            A     : Mat := Create (2, 257, (Float64, 4));
            Alias : Mat := A;
         begin
            A.Set_To (Make_Scalar (8.0, 8.0, 8.0, 8.0));
            declare
               Expected : constant Mat :=
                 Calculate (A, Make_Scalar (2.0, 4.0, 8.0, 16.0), Op);
            begin
               Apply (A, Make_Scalar (2.0, 4.0, 8.0, 16.0), Op, Alias);
               Same (A, Expected, "shallow alias sees write");
            end;
         end;
      end loop;
   end Shallow;

   procedure Comparisons (Test : in out Fixture) is
      pragma Unreferenced (Test);
      type Values is array (Positive range <>) of Float64_Value;
   begin
      for Depth of Depths loop
         for Value of Values'(-1.0E100, -0.5, 1.5, 2.0, 2.5, 1.0E100) loop
            for Kind in Comparison_Kind loop
               declare
                  A        : Mat := Create (2, 257, (Depth, 1));
                  D        : Mat := Create (3, 4, (Float32, 1));
                  Selected : Boolean;
               begin
                  A.Set_To (Make_Scalar (2.0));
                  case Kind is
                     when Equal            =>
                        Selected := 2.0 = Value;

                     when Not_Equal        =>
                        Selected := 2.0 /= Value;

                     when Less_Than        =>
                        Selected := 2.0 < Value;

                     when Less_Or_Equal    =>
                        Selected := 2.0 <= Value;

                     when Greater_Than     =>
                        Selected := 2.0 > Value;

                     when Greater_Or_Equal =>
                        Selected := 2.0 >= Value;
                  end case;
                  Compare (A, Value, Kind, D);
                  Assert
                    (D.Depth = UInt8 and then D.Channels = 1, "mask type");
                  Assert
                    (D.Count_Non_Zero = (if Selected then 514 else 0),
                     "scalar relations fraction/range");
                  Same (D, Compare (A, Value, Kind), "mask forms");
                  declare
                     Parent : Mat := Create (4, 263, (UInt8, 1));
                     Region : Mat := Parent.Region ((2, 1, 257, 2));
                     Alias  : constant Mat := Region;
                  begin
                     Parent.Set_To (Make_Scalar (91.0));
                     Compare (A, Value, Kind, Region);
                     Same (Region, D, "comparison Region values");
                     Same (Alias, D, "comparison retained shallow sharing");
                     Assert
                       (Pixel (Parent) = 91.0
                        and then Pixel (Parent, 0, 1, 2)
                                 = (if Selected then 255.0 else 0.0),
                        "comparison writes parent logical Region only");
                     if Depth = UInt8 then
                        declare
                           Source : Mat := Create (2, 257, (UInt8, 1));
                           Shared : Mat := Source;
                        begin
                           Source.Set_To (Make_Scalar (2.0));
                           Compare (Source, Value, Kind, Shared);
                           Same (Source, D, "comparison shallow alias values");
                           Shared.Set_To (Make_Scalar (17.0));
                           Assert
                             (Pixel (Source) = 17.0,
                              "comparison retains same-layout allocation");
                        end;
                     end if;
                  end;
               end;
            end loop;
         end loop;
      end loop;
   end Comparisons;

   procedure Invalid (Test : in out Fixture) is
      pragma Unreferenced (Test);
      D       : Mat := Create (2, 3, (UInt8, 1));
      Default : Mat;
      Empty   : constant Mat := Create (0, 3, (UInt8, 1));
      ND      : constant Mat :=
        Create (Shape => (2, 3, 4), Element_Type => (UInt8, 1));
      Half    : constant Mat := Create (2, 3, (Float16, 1));
      Five    : constant Mat := Create (2, 3, (UInt8, 5));
      Two     : constant Mat := Create (2, 3, (UInt8, 2));
      procedure Reject (A : Mat; Comparison : Boolean := False) is
         procedure Attempt is
         begin
            if Comparison then
               Compare (A, 1.5, Equal, D);
            else
               Add (A, Make_Scalar (1.0), D);
            end if;
         end Attempt;
      begin
         Assert_Raises_OpenCV_Error (Attempt'Access, "invalid scalar input");
         Assert (Pixel (D) = 91.0, "preflight preserves destination");
      end Reject;
   begin
      D.Set_To (Make_Scalar (91.0));
      Reject (Default);
      Reject (Empty);
      Reject (ND);
      Reject (Half);
      Reject (Five);
      Reject (Two, True);
   end Invalid;

   procedure Overlap (Test : in out Fixture) is
      pragma Unreferenced (Test);
      P : Mat := Create (3, 10, (UInt8, 1));
      A : Mat := P.Region ((0, 0, 8, 3));
      D : Mat := P.Region ((1, 0, 8, 3));
      procedure Attempt is
      begin
         Add (A, Make_Scalar (2.0), D);
      end Attempt;
      F : Mat := Create (2, 3, (Float64, 1));
      procedure Mask_Alias is
      begin
         Compare (F, 2.0, Equal, F);
      end Mask_Alias;
   begin
      P.Set_To (Make_Scalar (8.0));
      F.Set_To (Make_Scalar (8.0));
      Assert_Raises_OpenCV_Error (Attempt'Access, "partial overlap");
      Assert_Raises_OpenCV_Error (Mask_Alias'Access, "depth-changing alias");
      Assert
        (Pixel (P) = 8.0 and then Pixel (F) = 8.0,
         "alias rejection unchanged");
      Compare (A, 2.0, Greater_Than, A);
      Assert (Pixel (A) = 255.0, "UInt8 exact comparison alias");
   end Overlap;

   procedure Temporary (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data : aliased UInt8_Mat_View.Buffer_Array := (11 .. 16 => 8);
      procedure Process (A : in out Mat) is
         D : constant Mat := Add (A, Make_Scalar (2.0));
         procedure Attempt is
         begin
            Add (D, Make_Scalar (2.0), A);
         end Attempt;
      begin
         Assert (Pixel (D) = 10.0, "scoped input");
         Assert_Raises_OpenCV_Error (Attempt'Access, "temporary output");
      end Process;
   begin
      UInt8_Mat_View.With_Writable_Mat_View (Data, 2, 3, Process'Access);
      Assert (Data (11) = 8, "external data preserved");
   end Temporary;

   procedure Numbers (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A : Mat := Create (1, 257, (Float64, 1));
   begin
      A.Set_To (Make_Scalar (-3.0));
      Assert (Pixel (Add (A, Make_Scalar (0.5))) = -2.5, "fractional add");
      Assert
        (Pixel (Subtract_From (Make_Scalar (2.0), A)) = 5.0,
         "negative reverse subtraction");
      for Depth of Depths loop
         if Depth not in Float32 | Float64 then
            declare
               P     : Mat := Create (4, 263, (Depth, 4));
               I     : constant Mat := P.Region ((2, 1, 257, 2));
               D     : Mat := Create (2, 257, (Depth, 4));
               Alias : constant Mat := D;
               V     : constant Scalar := Make_Scalar (2.0, 4.0, 8.0, 0.0);
               procedure Scalar_Zero is
               begin
                  Divide (I, V, D);
               end Scalar_Zero;
               procedure Mat_Zero is
               begin
                  Divide_Into (Make_Scalar (2.0, 4.0, 8.0, 16.0), I, D);
               end Mat_Zero;
               procedure Function_Scalar_Zero is
                  F : constant Mat := Divide (I, V);
                  pragma Unreferenced (F);
               begin
                  null;
               end Function_Scalar_Zero;
               procedure Function_Mat_Zero is
                  F : constant Mat :=
                    Divide_Into (Make_Scalar (2.0, 4.0, 8.0, 16.0), I);
                  pragma Unreferenced (F);
               begin
                  null;
               end Function_Mat_Zero;
            begin
               P.Set_To (Make_Scalar (8.0, 8.0, 8.0, 8.0));
               D.Set_To (Make_Scalar (91.0, 91.0, 91.0, 91.0));
               Assert_Raises_OpenCV_Error
                 (Scalar_Zero'Access, "C4 zero scalar");
               Assert_Raises_OpenCV_Error
                 (Function_Scalar_Zero'Access, "function zero scalar");
               --  Only the last channel of the last logical ROI pixel is zero.
               declare
                  Last : Mat := I.Region ((256, 1, 1, 1));
               begin
                  Last.Set_To (Make_Scalar (8.0, 8.0, 8.0, 0.0));
               end;
               Assert_Raises_OpenCV_Error
                 (Mat_Zero'Access, "strided Mat zero");
               Assert_Raises_OpenCV_Error
                 (Function_Mat_Zero'Access, "function Mat zero");
               Assert
                 (Pixel (D) = 91.0
                  and then Pixel (Alias, 3) = 91.0
                  and then Pixel (I) = 8.0,
                  "preflight preserves values and shallow storage");
               D.Set_To (Make_Scalar (90.0));
               Assert (Pixel (Alias) = 90.0, "preflight retains sharing");
            end;
         end if;
      end loop;
      declare
         B : Mat := Create (1, 1, (UInt8, 1));
         I : Mat := Create (1, 1, (Int32, 1));
      begin
         B.Set_To (Make_Scalar (250.0));
         Assert (Pixel (Add (B, Make_Scalar (10.0))) = 255.0, "saturation");
         I.Set_To (Make_Scalar (2_147_483_646.0));
         Assert
           (Pixel (Add (I, Make_Scalar (1.0))) = 2_147_483_647.0,
            "well-defined Int32 upper boundary");
         I.Set_To (Make_Scalar (-2_147_483_647.0));
         Assert
           (Pixel (Subtract (I, Make_Scalar (1.0))) = -2_147_483_648.0,
            "well-defined Int32 lower boundary");
      end;
   end Numbers;

   procedure Specials (Test : in out Fixture) is
      pragma Unreferenced (Test);
      --  Only the NaN coefficient fixture crosses an Ada floating boundary.
      --  Classify native results as IEEE bits, never via typed Get/conversion.
      pragma Suppress (Validity_Check);
      function From_Bits is new
        Ada.Unchecked_Conversion (Interfaces.Unsigned_64, Long_Float);
      use type Interfaces.Unsigned_64;
      use type Interfaces.C.int;
      package M renames OpenCV.Core.Module_Interop;
      function Read_Bits
        (Handle : M.Input_Mat_Handle) return Interfaces.Unsigned_64
      with
        Import,
        Convention    => C,
        External_Name => "opencv_core_scalar_read_bits";
      function Write_Bits
        (Handle : M.Output_Mat_Handle; Bits : Interfaces.Unsigned_64)
         return Interfaces.C.int
      with
        Import,
        Convention    => C,
        External_Name => "opencv_core_scalar_write_bits";
      function Bits (Image : Mat) return Interfaces.Unsigned_64 is
         Value : Interfaces.Unsigned_64 := 0;
         procedure Read (Handle : M.Input_Mat_Handle) is
         begin
            Value := Read_Bits (Handle);
         end Read;
      begin
         M.With_Input_Handle (Image, Read'Access);
         return Value;
      end Bits;
      procedure Set_Bits (Image : in out Mat; Value : Interfaces.Unsigned_64)
      is
         procedure Write (Handle : M.Output_Mat_Handle) is
         begin
            Assert (Write_Bits (Handle, Value) = 0, "IEEE fixture write");
         end Write;
      begin
         M.With_Output_Handle (Image, Write'Access);
      end Set_Bits;
      NaN : constant Long_Float := From_Bits (16#7FF8_0000_0000_0001#);
      A   : Mat := Create (1, 1, (Float64, 1));
      procedure Reject_Add is
      begin
         Add (A, (NaN, 0.0, 0.0, 0.0), A);
      end Reject_Add;
   begin
      for Depth in Depth_Type range Float32 .. Float64 loop
         A := Create (1, 1, (Depth, 1));
         declare
            Inf      : constant Interfaces.Unsigned_64 :=
              (if Depth = Float64
               then 16#7FF0_0000_0000_0000#
               else 16#7F80_0000#);
            Sign     : constant Interfaces.Unsigned_64 :=
              (if Depth = Float64
               then 16#8000_0000_0000_0000#
               else 16#8000_0000#);
            Fraction : constant Interfaces.Unsigned_64 :=
              (if Depth = Float64
               then 16#000F_FFFF_FFFF_FFFF#
               else 16#007F_FFFF#);
         begin
            A.Set_To (Make_Scalar (2.0));
            Assert
              (Bits (Divide (A, Make_Scalar (0.0))) = Inf,
               "float division produces infinity");
            declare
               D : constant Mat := Multiply (A, (NaN, 0.0, 0.0, 0.0));
               B : constant Interfaces.Unsigned_64 := Bits (D);
            begin
               Assert
                 ((B and Inf) = Inf and then (B and Fraction) /= 0,
                  "floating NaN coefficient");
            end;
            Assert_Raises_OpenCV_Error
              (Reject_Add'Access, "unsafe NaN rounding");
            Set_Bits (A, Inf);
            Assert
              (Bits (Add (A, Make_Scalar (1.0))) = Inf, "nonfinite source");
            Set_Bits (A, Sign);
            Assert
              ((Bits (Multiply (A, Make_Scalar (2.0))) and not Sign) = 0,
               "signed zero magnitude");
         end;
      end loop;
   end Specials;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create ("Scalar seven depths C1..C4", Depth_Channels'Access));
      Result.Add_Test (Caller.Create ("Scalar mapping", Mapping'Access));
      Result.Add_Test (Caller.Create ("Scalar ROI aliases", Reuse'Access));
      Result.Add_Test (Caller.Create ("Scalar detach", Detach'Access));
      Result.Add_Test (Caller.Create ("Scalar shallow", Shallow'Access));
      Result.Add_Test (Caller.Create ("Scalar compare", Comparisons'Access));
      Result.Add_Test (Caller.Create ("Scalar invalid", Invalid'Access));
      Result.Add_Test (Caller.Create ("Scalar overlap", Overlap'Access));
      Result.Add_Test (Caller.Create ("Scalar temporary", Temporary'Access));
      Result.Add_Test (Caller.Create ("Scalar ABI", Raw_ABI.Run'Access));
      Result.Add_Test
        (Caller.Create ("Scalar numeric boundaries", Numbers'Access));
      Result.Add_Test (Caller.Create ("Scalar IEEE values", Specials'Access));
      return Result'Access;
   end Suite;
end Scalar_Modes_Tests;
