with AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Unchecked_Conversion;
with Interfaces;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Int8_Access;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt16_Access;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;

package body ND_Extrema_Tests is
   use OpenCV;
   use OpenCV.Core;
   use Mat_Test_Support;
   use AUnit.Assertions;
   use type Interfaces.IEEE_Float_32;
   use type Interfaces.IEEE_Float_64;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Integer_16;
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type C.C_Int32;
   use type C.C_Double;
   use type C.C_Int32_Array;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);

   Shape_5 : constant Dimension_Array := (2, 3, 2, 4, 2);
   Low_5   : constant Index_Array := (1, 2, 0, 3, 1);
   High_5  : constant Index_Array := (0, 1, 1, 2, 0);

   procedure Check
     (R                     : ND_Min_Max_Result;
      Low, High             : Long_Float;
      Low_Index, High_Index : Index_Array) is
   begin
      Assert
        (R.Has_Minimum
         and then R.Has_Maximum
         and then R.Minimum = Low
         and then R.Maximum = High
         and then R.Dimensions = Low_Index'Length
         and then R.Minimum_Location (1 .. R.Dimensions) = Low_Index
         and then R.Maximum_Location (1 .. R.Dimensions) = High_Index,
         "values and every native-order coordinate");
      Assert
        (R.Minimum_Location (R.Dimensions + 1 .. 32)
         = (R.Dimensions + 1 .. 32 => 0)
         and then R.Maximum_Location (R.Dimensions + 1 .. 32)
                  = (R.Dimensions + 1 .. 32 => 0),
         "unused coordinates remain zero");
   end Check;

   procedure Five_Dimensions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : Mat := Create (Shape_5, (Int32, 1));
      Alias  : constant Mat := Source;
   begin
      Source.Set_To (Make_Scalar (7.0));
      Int32_Access.Set (Source, Low_5, -30);
      Int32_Access.Set (Source, High_5, 90);
      Assert
        (Source.Dimension_Count = 5 and then Source.Is_Continuous,
         "continuous 5-D source exercises the 4.10 HAL compatibility bypass");
      Check (Source.Min_Max_Indices, -30.0, 90.0, Low_5, High_5);
      Check (Alias.Min_Max_Indices, -30.0, 90.0, Low_5, High_5);
      Assert
        (Source.Is_Continuous
         and then Alias.Is_Continuous
         and then Source.Shape = Shape_5
         and then Alias.Shape = Shape_5
         and then Int32_Access.Get (Source, Low_5) = -30
         and then Int32_Access.Get (Alias, High_5) = 90,
         "source and shallow alias metadata/storage unchanged and usable");
   end Five_Dimensions;

   procedure Masked_Five_Dimensions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : Mat := Create (Shape_5, (Float64, 1));
      Mask   : Mat := Create (Shape_5, (UInt8, 1));
      Alias  : constant Mat := Mask;
      R      : ND_Min_Max_Result;
   begin
      Source.Set_To (Make_Scalar (7.0));
      Mask.Set_To (Make_Scalar (0.0));
      Float64_Access.Set (Source, (0, 0, 0, 0, 0), -100.0);
      Float64_Access.Set (Source, (1, 2, 1, 3, 1), 100.0);
      Float64_Access.Set (Source, Low_5, -3.5);
      Float64_Access.Set (Source, High_5, 9.25);
      UInt8_Access.Set (Mask, Low_5, 1);
      UInt8_Access.Set (Mask, High_5, 255);
      Assert
        (Source.Is_Continuous and then Mask.Is_Continuous,
         "continuous 5-D source and mask exercise the 4.10 bypass");
      Check (Source.Min_Max_Indices (Mask), -3.5, 9.25, Low_5, High_5);
      Check
        (Source.Min_Max_Indices,
         -100.0,
         100.0,
         (0, 0, 0, 0, 0),
         (1, 2, 1, 3, 1));
      Assert
        (UInt8_Access.Get (Alias, Low_5) = 1
         and then UInt8_Access.Get (Mask, High_5) = 255
         and then Float64_Access.Get (Source, Low_5) = -3.5,
         "borrowed source/mask and aliases unchanged");
      Mask.Set_To (Make_Scalar (0.0));
      R := Source.Min_Max_Indices (Mask);
      Assert
        (not R.Has_Minimum
         and then not R.Has_Maximum
         and then R.Minimum = 0.0
         and then R.Maximum = 0.0
         and then R.Dimensions = 5
         and then R.Minimum_Location = (1 .. 32 => 0)
         and then R.Maximum_Location = (1 .. 32 => 0),
         "all-zero 5-D mask has no valid extrema and no sentinels");
   end Masked_Five_Dimensions;

   procedure Slices (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Parent : Mat :=
        Create (Shape => (3, 4, 5), Element_Type => (Float32, 1));
      View   : Mat := Parent.Slice (((1, 3), (1, 4), (1, 4)));
      M_Base : Mat := Create (Shape => (3, 4, 5), Element_Type => (UInt8, 1));
      Mask   : Mat := M_Base.Slice (((1, 3), (1, 4), (1, 4)));
      Packed : Mat :=
        Create (Shape => (2, 3, 3), Element_Type => (Float32, 1));
   begin
      Parent.Set_To (Make_Scalar (4.0));
      M_Base.Set_To (Make_Scalar (0.0));
      Float32_Access.Set (Parent, (0, 0, 0), -1000.0);
      Float32_Access.Set (View, (1, 2, 0), -8.0);
      Float32_Access.Set (View, (0, 1, 2), 12.0);
      Assert (not View.Is_Continuous, "genuine non-contiguous N-D Slice");
      Check (View.Min_Max_Indices, -8.0, 12.0, (1, 2, 0), (0, 1, 2));
      UInt8_Access.Set (Mask, (1, 2, 0), 1);
      UInt8_Access.Set (Mask, (0, 1, 2), 2);
      Check (View.Min_Max_Indices (Mask), -8.0, 12.0, (1, 2, 0), (0, 1, 2));
      Packed.Set_To (Make_Scalar (4.0));
      Float32_Access.Set (Packed, (1, 2, 0), -8.0);
      Float32_Access.Set (Packed, (0, 1, 2), 12.0);
      Assert
        (Packed.Is_Continuous and then not Mask.Is_Continuous,
         "continuous N-D source with genuinely strided mask");
      Check (Packed.Min_Max_Indices (Mask), -8.0, 12.0, (1, 2, 0), (0, 1, 2));
      Assert
        (Float32_Access.Get (Parent, (2, 3, 1)) = -8.0
         and then Float32_Access.Get (Parent, (0, 0, 0)) = -1000.0
         and then UInt8_Access.Get (M_Base, (1, 2, 3)) = 2,
         "parent offsets do not leak and input storage is unchanged");
   end Slices;

   procedure Depths_And_Ties (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      for D in UInt8 .. Float64 loop
         declare
            Source : Mat :=
              Create (Shape => (2, 3, 2), Element_Type => (D, 1));
            Low    : constant Index_Array := (0, 2, 1);
            High   : constant Index_Array := (1, 0, 1);
         begin
            Source.Set_To (Make_Scalar (7.0));
            case D is
               when UInt8   =>
                  UInt8_Access.Set (Source, Low, 2);
                  UInt8_Access.Set (Source, High, 19);

               when Int8    =>
                  Int8_Access.Set (Source, Low, 2);
                  Int8_Access.Set (Source, High, 19);

               when UInt16  =>
                  UInt16_Access.Set (Source, Low, 2);
                  UInt16_Access.Set (Source, High, 19);

               when Int16   =>
                  Int16_Access.Set (Source, Low, 2);
                  Int16_Access.Set (Source, High, 19);

               when Int32   =>
                  Int32_Access.Set (Source, Low, 2);
                  Int32_Access.Set (Source, High, 19);

               when Float32 =>
                  Float32_Access.Set (Source, Low, 2.0);
                  Float32_Access.Set (Source, High, 19.0);

               when Float64 =>
                  Float64_Access.Set (Source, Low, 2.0);
                  Float64_Access.Set (Source, High, 19.0);

            end case;
            Check (Source.Min_Max_Indices, 2.0, 19.0, Low, High);
            Source.Set_To (Make_Scalar (7.0));
            Check (Source.Min_Max_Indices, 7.0, 7.0, (0, 0, 0), (0, 0, 0));
         end;
      end loop;
   end Depths_And_Ties;

   procedure Parity (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : Mat := Create (3, 4, (Int16, 1));
      Mask   : Mat := Create (3, 4, (UInt8, 1));
      Old    : Min_Max_Result;
      ND     : ND_Min_Max_Result;
   begin
      Source.Set_To (Make_Scalar (6.0));
      Mask.Set_To (Make_Scalar (0.0));
      Int16_Access.Set (Source, 2, 1, -8);
      Int16_Access.Set (Source, 0, 3, 25);
      UInt8_Access.Set (Mask, 2, 1, 1);
      UInt8_Access.Set (Mask, 0, 3, 1);
      for Masked in Boolean loop
         if Masked then
            Old := Source.Min_Max_Loc (Mask);
            ND := Source.Min_Max_Indices (Mask);
         else
            Old := Source.Min_Max_Loc;
            ND := Source.Min_Max_Indices;
         end if;
         Assert
           (ND.Dimensions = 2
            and then ND.Minimum = Old.Minimum
            and then ND.Maximum = Old.Maximum
            and then ND.Minimum_Location (1)
                     = Size_Coordinate (Old.Minimum_Location.Y)
            and then ND.Minimum_Location (2)
                     = Size_Coordinate (Old.Minimum_Location.X)
            and then ND.Maximum_Location (1)
                     = Size_Coordinate (Old.Maximum_Location.Y)
            and then ND.Maximum_Location (2)
                     = Size_Coordinate (Old.Maximum_Location.X),
            "2-D parity uses row,column rather than Point X,Y");
      end loop;
   end Parity;

   procedure Invalid_Inputs (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : constant Mat := Create (Shape_5, (Int32, 1));
      R      : ND_Min_Max_Result;

      procedure Bad_Source (Image : Mat) is
         procedure Attempt is
         begin
            R := Image.Min_Max_Indices;
         end Attempt;
      begin
         Assert_Raises_OpenCV_Error (Attempt'Access, "invalid N-D source");
      end Bad_Source;

      procedure Bad_Mask (Mask : Mat) is
         procedure Attempt is
         begin
            R := Source.Min_Max_Indices (Mask);
         end Attempt;
      begin
         Assert_Raises_OpenCV_Error
           (Attempt'Access, "invalid full-shape mask");
      end Bad_Mask;
   begin
      declare
         Empty : Mat;
      begin
         Bad_Source (Empty);
      end;
      Bad_Source (Create (0, 0, (Float32, 1)));
      Bad_Source (Create (Shape_5, (Float16, 1)));
      Bad_Source (Create (Shape_5, (UInt8, 3)));
      declare
         Half : constant Mat := Create (Shape_5, (Float16, 1));
         Mask : constant Mat := Create (Shape_5, (UInt8, 1));
         procedure Attempt is
         begin
            R := Half.Min_Max_Indices (Mask);
         end Attempt;
      begin
         Assert_Raises_OpenCV_Error
           (Attempt'Access, "masked Float16 rejected on every version");
      end;
      Bad_Mask (Create (Shape_5, (Int8, 1)));
      Bad_Mask (Create (Shape_5, (UInt8, 2)));
      Bad_Mask (Create (Shape => (2, 3, 2, 8), Element_Type => (UInt8, 1)));
      Bad_Mask (Create (Shape => (2, 3, 2, 4, 3), Element_Type => (UInt8, 1)));
      Bad_Mask (Create (Shape => (2, 3, 3, 4, 2), Element_Type => (UInt8, 1)));
      Bad_Mask (Create (0, 0, (UInt8, 1)));
      Assert (R.Dimensions = 0, "no result published on validation error");
   end Invalid_Inputs;

   procedure Dimension_Boundaries (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Count  : constant Positive :=
        (if Module_Bridge_Probe.OpenCV_Major_Version >= 5 then 10 else 32);
      Source : Mat :=
        Create (Shape => (1 .. Count => 1), Element_Type => (UInt8, 1));
      Row    : Mat := Create (1, 4, (UInt8, 1));
      Column : Mat := Create (4, 1, (UInt8, 1));
   begin
      Source.Set_To (Make_Scalar (3.0));
      Check
        (Source.Min_Max_Indices,
         3.0,
         3.0,
         (1 .. Count => 0),
         (1 .. Count => 0));
      Row.Set_To (Make_Scalar (3.0));
      Column.Set_To (Make_Scalar (3.0));
      UInt8_Access.Set (Row, 0, 2, 0);
      UInt8_Access.Set (Row, 0, 3, 9);
      UInt8_Access.Set (Column, 2, 0, 0);
      UInt8_Access.Set (Column, 3, 0, 9);
      Check (Row.Min_Max_Indices, 0.0, 9.0, (0, 2), (0, 3));
      Check (Column.Min_Max_Indices, 0.0, 9.0, (2, 0), (3, 0));
   end Dimension_Boundaries;

   function Special (N, D : Float64_Value) return Float64_Value is
      pragma Suppress (Validity_Check);
   begin
      return N / D;
   end Special;

   procedure Floating_Specials (Test : in out Fixture) is
      pragma Unreferenced (Test);
      pragma Suppress (Validity_Check);
      Modern : constant Boolean :=
        Module_Bridge_Probe.OpenCV_Major_Version >= 5;
   begin
      for D in Float32 .. Float64 loop
         declare
            Source : Mat :=
              Create (Shape => (2, 1, 1, 1, 2), Element_Type => (D, 1));
            Mask   : Mat :=
              Create (Shape => (2, 1, 1, 1, 2), Element_Type => (UInt8, 1));
            R      : ND_Min_Max_Result;

            procedure Fill (Value : Float64_Value) is
            begin
               for I in Size_Coordinate range 0 .. 1 loop
                  for J in Size_Coordinate range 0 .. 1 loop
                     if D = Float32 then
                        Float32_Access.Set
                          (Source, (I, 0, 0, 0, J), Float32_Value (Value));
                     else
                        Float64_Access.Set (Source, (I, 0, 0, 0, J), Value);
                     end if;
                  end loop;
               end loop;
            end Fill;
         begin
            Mask.Set_To (Make_Scalar (0.0));
            UInt8_Access.Set (Mask, (1, 0, 0, 0, 0), 1);
            for Kind in 0 .. 2 loop
               Fill (Special (Float64_Value (Kind), 0.0));
               if Kind = 2 then
                  Fill (-Special (1.0, 0.0));
               end if;
               R := Source.Min_Max_Indices;
               Assert
                 (R.Has_Minimum and then R.Has_Maximum,
                  "native unmasked specials have defined indices");
               R := Source.Min_Max_Indices (Mask);
               Assert
                 (R.Has_Minimum = (Modern or else Kind = 2)
                  and then R.Has_Maximum = (Modern or else Kind = 1),
                  "independent special-value native index flags");
               if Modern then
                  Assert
                    (R.Minimum_Location (1 .. 5) = (1, 0, 0, 0, 0)
                     and then R.Maximum_Location (1 .. 5) = (1, 0, 0, 0, 0),
                     "5.0 initializes from selected element");
               else
                  if Kind < 2 then
                     Assert
                       (R.Minimum = 0.0
                        and then R.Maximum = 0.0
                        and then R.Minimum_Location = (1 .. 32 => 0),
                        "4.x undefined minimum preserves native zero values");
                  else
                     Assert
                       (R.Minimum < Long_Float'First
                        and then R.Maximum < Long_Float'First
                        and then R.Maximum_Location = (1 .. 32 => 0),
                        "4.x negative infinity leaves maximum undefined");
                  end if;
               end if;
               if Modern and then Kind = 0 then
                  Assert
                    (R.Minimum /= R.Minimum and then R.Maximum /= R.Maximum,
                     "5.0 preserves selected NaN");
               elsif Modern and then Kind = 1 then
                  Assert
                    (R.Minimum > Long_Float'Last
                     and then R.Maximum > Long_Float'Last,
                     "5.0 preserves selected positive infinity");
               elsif Modern then
                  Assert
                    (R.Minimum < Long_Float'First
                     and then R.Maximum < Long_Float'First,
                     "5.0 preserves selected negative infinity");
               end if;
            end loop;
            Fill (7.0);
            if D = Float32 then
               Float32_Access.Set
                 (Source, (0, 0, 0, 0, 0), Float32_Value (Special (0.0, 0.0)));
            else
               Float64_Access.Set
                 (Source, (0, 0, 0, 0, 0), Special (0.0, 0.0));
            end if;
            R := Source.Min_Max_Indices;
            if Modern then
               Assert (R.Minimum /= R.Minimum, "5.0 first NaN seeds minimum");
            else
               Check (R, 7.0, 7.0, (0, 0, 0, 0, 1), (0, 0, 0, 0, 1));
            end if;
            Fill (7.0);
            if D = Float32 then
               Float32_Access.Set
                 (Source, (1, 0, 0, 0, 1), Float32_Value (Special (0.0, 0.0)));
            else
               Float64_Access.Set
                 (Source, (1, 0, 0, 0, 1), Special (0.0, 0.0));
            end if;
            Check
              (Source.Min_Max_Indices,
               7.0,
               7.0,
               (0, 0, 0, 0, 0),
               (0, 0, 0, 0, 0));
         end;
      end loop;
   end Floating_Specials;

   procedure Raw_ABI (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : Mat := Create (Shape_5, (Int32, 1));
      Mask   : Mat := Create (Shape_5, (UInt8, 1));
      function Raw_Handle is new
        Ada.Unchecked_Conversion
          (Module_Interop.Input_Mat_Handle,
           C.Mat_Handle);

      procedure Probe (Input : Module_Interop.Input_Mat_Handle) is
         procedure With_Mask (M : Module_Interop.Input_Mat_Handle) is
            Low, High : aliased C.C_Double;
            Min_I     : C.C_Int32_Array (1 .. 32);
            Max_I     : C.C_Int32_Array (1 .. 32);
            Dims      : aliased C.C_Int32;
            Has_Low   : aliased C.C_UInt8;
            Has_High  : aliased C.C_UInt8;
            S         : C.Status;
         begin
            for Case_Id in 0 .. 15 loop
               Low := 99.0;
               High := 99.0;
               Min_I := (others => 99);
               Max_I := (others => 99);
               Dims := 99;
               Has_Low := 99;
               Has_High := 99;
               if Case_Id = 11 or else Case_Id = 12 then
                  S :=
                    C.Mat_Min_Max_Indices_Masked
                      (Raw_Handle (Input),
                       (if Case_Id = 12
                        then C.Null_Mat_Handle
                        else Raw_Handle (M)),
                       Low'Access,
                       High'Access,
                       Min_I (1)'Access,
                       Max_I (1)'Access,
                       32,
                       Dims'Access,
                       Has_Low'Access,
                       Has_High'Access);
               else
                  S :=
                    C.Mat_Min_Max_Indices
                      ((if Case_Id = 1
                        then C.Null_Mat_Handle
                        else Raw_Handle (Input)),
                       (if Case_Id = 2 then null else Low'Access),
                       (if Case_Id = 3 then null else High'Access),
                       (if Case_Id = 4 then null else Min_I (1)'Access),
                       (if Case_Id = 5 then null else Max_I (1)'Access),
                       (if Case_Id = 9
                        then 4
                        elsif Case_Id = 13
                        then 0
                        elsif Case_Id = 14
                        then 33
                        elsif Case_Id = 15
                        then -1
                        else 32),
                       (if Case_Id = 6 then null else Dims'Access),
                       (if Case_Id = 7 then null else Has_Low'Access),
                       (if Case_Id = 8 then null else Has_High'Access));
               end if;
               if Case_Id = 0 or else Case_Id = 10 or else Case_Id = 11 then
                  Assert
                    (S = C.Success
                     and then Dims = 5
                     and then Low = -30.0
                     and then High = 90.0
                     and then Has_Low = 1
                     and then Has_High = 1
                     and then Min_I (1 .. 5) = (1, 2, 0, 3, 1)
                     and then Max_I (1 .. 5) = (0, 1, 1, 2, 0)
                     and then Min_I (6 .. 32) = (6 .. 32 => 0)
                     and then Max_I (6 .. 32) = (6 .. 32 => 0),
                     "raw valid 5-D extrema");
               else
                  Assert
                    (S = C.Error_Invalid_Argument, "raw invalid argument");
                  Assert
                    ((Case_Id = 2 or else Low = 0.0)
                     and then (Case_Id = 3 or else High = 0.0)
                     and then (Case_Id = 6 or else Dims = 0)
                     and then (Case_Id = 7 or else Has_Low = 0)
                     and then (Case_Id = 8 or else Has_High = 0),
                     "all supplied scalar outputs reset on failure");
                  if Case_Id < 13 then
                     declare
                        Count : constant Natural :=
                          (if Case_Id = 9 then 4 else 32);
                     begin
                        Assert
                          ((Case_Id = 4
                            or else Min_I (1 .. Count) = (1 .. Count => 0))
                           and then (Case_Id = 5
                                     or else Max_I (1 .. Count)
                                             = (1 .. Count => 0)),
                           "accepted coordinate capacity cleared on failure");
                        if Case_Id = 9 then
                           Assert
                             (Min_I (5 .. 32) = (5 .. 32 => 99),
                              "short capacity does not access extra entries");
                        end if;
                     end;
                  else
                     Assert
                       (Min_I = (1 .. 32 => 99)
                        and then Max_I = (1 .. 32 => 99),
                        "invalid capacity never accesses buffers");
                  end if;
               end if;
            end loop;
         end With_Mask;
      begin
         Module_Interop.With_Input_Handle (Mask, With_Mask'Access);
      end Probe;

      procedure Native_Depth (D : Depth_Type; Channels : Channel_Count) is
         Image : Mat := Create (Shape_5, (D, Channels));
         procedure Run (Input : Module_Interop.Input_Mat_Handle) is
            Low, High : aliased C.C_Double := 99.0;
            Min_I     : C.C_Int32_Array (1 .. 32) := (others => 99);
            Max_I     : C.C_Int32_Array (1 .. 32) := (others => 99);
            Dims      : aliased C.C_Int32 := 99;
            Has_Low   : aliased C.C_UInt8 := 99;
            Has_High  : aliased C.C_UInt8 := 99;
            S         : constant C.Status :=
              C.Mat_Min_Max_Indices
                (Raw_Handle (Input),
                 Low'Access,
                 High'Access,
                 Min_I (1)'Access,
                 Max_I (1)'Access,
                 32,
                 Dims'Access,
                 Has_Low'Access,
                 Has_High'Access);
         begin
            if D = Float16
              and then Module_Bridge_Probe.OpenCV_Major_Version >= 5
            then
               Assert
                 (S = C.Success
                  and then Dims = 5
                  and then Low = 2.0
                  and then High = 2.0
                  and then Has_Low = 1
                  and then Has_High = 1
                  and then Min_I = (1 .. 32 => 0)
                  and then Max_I = (1 .. 32 => 0),
                  "raw 5.0 Float16 executes native dispatch");
            else
               Assert
                 (S = C.Error_OpenCV
                  and then Dims = 0
                  and then Low = 0.0
                  and then High = 0.0
                  and then Has_Low = 0
                  and then Has_High = 0
                  and then Min_I = (1 .. 32 => 0)
                  and then Max_I = (1 .. 32 => 0),
                  "raw unsupported input fails safely through OpenCV");
            end if;
         end Run;
      begin
         Image.Set_To (Make_Scalar (2.0, 2.0, 2.0));
         Module_Interop.With_Input_Handle (Image, Run'Access);
      end Native_Depth;
   begin
      Source.Set_To (Make_Scalar (7.0));
      Mask.Set_To (Make_Scalar (0.0));
      Int32_Access.Set (Source, Low_5, -30);
      Int32_Access.Set (Source, High_5, 90);
      UInt8_Access.Set (Mask, Low_5, 1);
      UInt8_Access.Set (Mask, High_5, 1);
      Module_Interop.With_Input_Handle (Source, Probe'Access);
      Native_Depth (Float16, 1);
      Native_Depth (UInt8, 3);
   end Raw_ABI;

   procedure Raw_Mask_Safety (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Source : constant Mat := Create (Shape_5, (Int32, 1));
      Mask   : constant Mat :=
        Create (Shape => (2, 3, 2, 4, 1), Element_Type => (UInt8, 1));
      function Raw_Handle is new
        Ada.Unchecked_Conversion
          (Module_Interop.Input_Mat_Handle,
           C.Mat_Handle);
      procedure With_Source (Input : Module_Interop.Input_Mat_Handle) is
         procedure With_Mask (M : Module_Interop.Input_Mat_Handle) is
            Low, High : aliased C.C_Double := 99.0;
            Min_I     : C.C_Int32_Array (1 .. 32) := (others => 99);
            Max_I     : C.C_Int32_Array (1 .. 32) := (others => 99);
            Dims      : aliased C.C_Int32 := 99;
            Has_Low   : aliased C.C_UInt8 := 99;
            Has_High  : aliased C.C_UInt8 := 99;
            S         : constant C.Status :=
              C.Mat_Min_Max_Indices_Masked
                (Raw_Handle (Input),
                 Raw_Handle (M),
                 Low'Access,
                 High'Access,
                 Min_I (1)'Access,
                 Max_I (1)'Access,
                 32,
                 Dims'Access,
                 Has_Low'Access,
                 Has_High'Access);
         begin
            Assert
              ((S = C.Error_Invalid_Argument or else S = C.Error_OpenCV)
               and then Low = 0.0
               and then High = 0.0
               and then Dims = 0
               and then Has_Low = 0
               and then Has_High = 0
               and then Min_I = (1 .. 32 => 0)
               and then Max_I = (1 .. 32 => 0),
               "raw undersized mask rejected before native pointer access");
         end With_Mask;
      begin
         Module_Interop.With_Input_Handle (Mask, With_Mask'Access);
      end With_Source;
   begin
      Module_Interop.With_Input_Handle (Source, With_Source'Access);
   end Raw_Mask_Safety;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite :=
        new AUnit.Test_Suites.Test_Suite;
   begin
      Result.Add_Test
        (Caller.Create ("N-D extrema genuine 5-D", Five_Dimensions'Access));
      Result.Add_Test
        (Caller.Create
           ("N-D extrema masked 5-D", Masked_Five_Dimensions'Access));
      Result.Add_Test
        (Caller.Create ("N-D extrema strided Slices", Slices'Access));
      Result.Add_Test
        (Caller.Create
           ("N-D extrema depths and ties", Depths_And_Ties'Access));
      Result.Add_Test
        (Caller.Create ("N-D extrema 2-D parity", Parity'Access));
      Result.Add_Test
        (Caller.Create ("N-D extrema invalid inputs", Invalid_Inputs'Access));
      Result.Add_Test
        (Caller.Create
           ("N-D extrema dimension boundaries", Dimension_Boundaries'Access));
      Result.Add_Test
        (Caller.Create
           ("N-D extrema native floating specials", Floating_Specials'Access));
      Result.Add_Test (Caller.Create ("N-D extrema raw ABI", Raw_ABI'Access));
      Result.Add_Test
        (Caller.Create
           ("N-D extrema raw mask safety", Raw_Mask_Safety'Access));
      return Result;
   end Suite;
end ND_Extrema_Tests;
