with AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Text_IO;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;
with Weighted_Destination_Tests.Raw_ABI;

package body Weighted_Destination_Tests is
   use OpenCV;
   use OpenCV.Core;
   use Mat_Test_Support;
   use AUnit.Assertions;
   use type Float64_Value;
   use type Int32_Value;
   use type UInt8_Value;
   use type Float64_Access.Float64_Classification;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result     : aliased AUnit.Test_Suites.Test_Suite;
   type Depth_List is array (Positive range <>) of Depth_Type;
   All_Depths : constant Depth_List :=
     (UInt8, Int16, Int32, Float32, Float64, Float16);
   function Identity (Self : Mat) return Mat
   is (Self);

   --  Exact integer observation never widens Int32 through Float64.
   --  Half is widened before channel extraction (4.x has no half extraction).
   procedure Equal (Actual, Expected : Mat) is
   begin
      Assert
        (Actual.Dimension_Count = Expected.Dimension_Count
         and then Actual.Shape = Expected.Shape
         and then Actual.Depth = Expected.Depth
         and then Actual.Channels = Expected.Channels,
         "shape/rank/type parity");
      if Actual.Is_Empty then
         return;
      end if;
      for Ch in 0 .. Natural (Actual.Channels) - 1 loop
         if Actual.Depth = Int32 then
            declare
               X : constant Mat := Actual.Extract_Channel (Ch);
               Y : constant Mat := Expected.Extract_Channel (Ch);
            begin
               if X.Dimension_Count = 3 then
                  for I in Size_Coordinate range 0 .. X.Shape (1) - 1 loop
                     for J in Size_Coordinate range 0 .. X.Shape (2) - 1 loop
                        for K in Size_Coordinate range 0 .. X.Shape (3) - 1
                        loop
                           Assert
                             (Int32_Access.Get (X, Index_Array'(I, J, K))
                              = Int32_Access.Get (Y, Index_Array'(I, J, K)),
                              "exact N-D Int32");
                        end loop;
                     end loop;
                  end loop;
               else
                  for R in 0 .. X.Rows - 1 loop
                     for C in 0 .. X.Columns - 1 loop
                        Assert
                          (Int32_Access.Get (X, R, C)
                           = Int32_Access.Get (Y, R, C),
                           "exact Int32 actual="
                           & Int32_Access.Get (X, R, C)'Image
                           & " expected="
                           & Int32_Access.Get (Y, R, C)'Image);
                     end loop;
                  end loop;
               end if;
            end;
         else
            declare
               X : constant Mat :=
                 Actual.Convert_To (Float64).Extract_Channel (Ch);
               Y : constant Mat :=
                 Expected.Convert_To (Float64).Extract_Channel (Ch);
            begin
               if X.Dimension_Count = 3 then
                  for I in Size_Coordinate range 0 .. X.Shape (1) - 1 loop
                     for J in Size_Coordinate range 0 .. X.Shape (2) - 1 loop
                        for K in Size_Coordinate range 0 .. X.Shape (3) - 1
                        loop
                           Assert
                             (Float64_Access.Get (X, Index_Array'(I, J, K))
                              = Float64_Access.Get (Y, Index_Array'(I, J, K)),
                              "every N-D result");
                        end loop;
                     end loop;
                  end loop;
               else
                  for R in 0 .. X.Rows - 1 loop
                     for C in 0 .. X.Columns - 1 loop
                        Assert
                          (Float64_Access.Classify (X, R, C)
                           = Float64_Access.Classify (Y, R, C),
                           "every special classification");
                        if Float64_Access.Classify (X, R, C)
                          = Float64_Access.Finite
                        then
                           Assert
                             (Float64_Access.Get (X, R, C)
                              = Float64_Access.Get (Y, R, C),
                              "every finite result including tail");
                        end if;
                     end loop;
                  end loop;
               end if;
            end;
         end if;
      end loop;
   end Equal;

   generic
      type Image is tagged private;
      with function From_Mat (Self : Mat) return Image;
      with function Observe (Self : Image) return Mat;
      with
        function New_Image
          (Rows, Columns : Natural; Element_Type : Mat_Type) return Image;
      with
        function New_ND
          (Shape : Dimension_Array; Element_Type : Mat_Type) return Image;
      with
        function Add_Weighted
          (Left  : Image;
           Alpha : Long_Float;
           Right : Image;
           Beta  : Long_Float;
           Gamma : Long_Float := 0.0) return Image is <>;
      with
        procedure Add_Weighted
          (Left        : Image;
           Alpha       : Long_Float;
           Right       : Image;
           Beta        : Long_Float;
           Destination : in out Image;
           Gamma       : Long_Float := 0.0) is <>;
      with
        function Scale_Add
          (Self : Image; Scale : Long_Float; Right : Image) return Image is <>;
      with
        procedure Scale_Add
          (Self        : Image;
           Scale       : Long_Float;
           Right       : Image;
           Destination : in out Image) is <>;
      with function Region (Self : Image; Area : Rect) return Image is <>;
      with procedure Set_To (Self : in out Image; Value : Scalar) is <>;
      with function Shape (Self : Image) return Dimension_Array is <>;
      with function Depth (Self : Image) return Depth_Type is <>;
      with function Channels (Self : Image) return Channel_Count is <>;
      with function Dimension_Count (Self : Image) return Natural is <>;
      with function Is_Empty (Self : Image) return Boolean is <>;
      with function Locate_Region (Self : Image) return Region_Location is <>;
      Op : Operation_Kind;
      Is_UMat : Boolean;
   package Cases is
      procedure Whole (Test : in out Fixture);
      procedure Interior (Test : in out Fixture);
      procedure Mismatch (Test : in out Fixture);
      procedure Aliases (Test : in out Fixture);
      procedure Numbers (Test : in out Fixture);
      procedure Floating (Test : in out Fixture);
      procedure ND (Test : in out Fixture);
      procedure Empty (Test : in out Fixture);
      procedure Failures (Test : in out Fixture);
   end Cases;

   package body Cases is
      function Fresh
        (A, B  : Image;
         Alpha : Long_Float := 2.5;
         Beta  : Long_Float := -3.0;
         Gamma : Long_Float := 5.0) return Image
      is (if Op = Weighted
          then Add_Weighted (A, Alpha, B, Beta, Gamma)
          else Scale_Add (A, Alpha, B));
      procedure Into
        (A, B  : Image;
         D     : in out Image;
         Alpha : Long_Float := 2.5;
         Beta  : Long_Float := -3.0;
         Gamma : Long_Float := 5.0) is
      begin
         if Op = Weighted then
            Add_Weighted (A, Alpha, B, Beta, D, Gamma);
         else
            Scale_Add (A, Alpha, B, D);
         end if;
      end Into;
      procedure Constant_Values (A : Image; Value : Long_Float) is
         H : constant Mat := Observe (A).Convert_To (Float64);
      begin
         for Ch in 0 .. Natural (H.Channels) - 1 loop
            declare
               V : constant Mat := H.Extract_Channel (Ch);
            begin
               for R in 0 .. V.Rows - 1 loop
                  for C in 0 .. V.Columns - 1 loop
                     Assert
                       (Long_Float (Float64_Access.Get (V, R, C)) = Value,
                        "every constant/guard pixel");
                  end loop;
               end loop;
            end;
         end loop;
      end Constant_Values;
      procedure Whole (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of All_Depths loop
            declare
               A     : Image := New_Image (2, 257, (D, 1));
               B     : Image := New_Image (2, 257, (D, 1));
               Dest  : Image := New_Image (2, 257, (D, 1));
               Alias : Image := Dest;
            begin
               Set_To (A, Make_Scalar (20.0));
               Set_To (B, Make_Scalar (7.0));
               declare
                  E : constant Image := Fresh (A, B);
               begin
                  Into (A, B, Dest);
                  Equal (Observe (Dest), Observe (E));
                  Equal (Observe (Alias), Observe (E));
                  Constant_Values
                    (Dest, (if Op = Weighted then 34.0 else 57.0));
                  Set_To (Alias, Make_Scalar (23.0));
                  Constant_Values (Dest, 23.0);
                  Set_To (Dest, Make_Scalar (25.0));
                  Constant_Values (Alias, 25.0);
                  Constant_Values (E, (if Op = Weighted then 34.0 else 57.0));
               end;
            end;
         end loop;
      end Whole;
      procedure Interior (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depth_List'(UInt8, Float32, Float16) loop
            declare
               A        : Image := New_Image (2, 3, (D, 1));
               B        : Image := New_Image (2, 3, (D, 1));
               Parent   : Image := New_Image (5, 7, (D, 1));
               Dest     : Image := Region (Parent, (2, 1, 3, 2));
               Alias    : Image := Dest;
               Geometry : constant Region_Location := Locate_Region (Dest);
               procedure Guards (Inside : Long_Float) is
                  P : constant Mat := Observe (Parent).Convert_To (Float64);
               begin
                  for R in 0 .. 4 loop
                     for C in 0 .. 6 loop
                        Assert
                          (Long_Float (Float64_Access.Get (P, R, C))
                           = (if R in 1 .. 2 and then C in 2 .. 4
                              then Inside
                              else 91.0),
                           "every Parent pixel");
                     end loop;
                  end loop;
               end Guards;
            begin
               Set_To (A, Make_Scalar (20.0));
               Set_To (B, Make_Scalar (7.0));
               Set_To (Parent, Make_Scalar (91.0));
               Into (A, B, Dest);
               Assert
                 (Shape (Dest) = (2, 3)
                  and then Locate_Region (Dest) = Geometry,
                  "Region and Locate_Region preserved");
               Equal (Observe (Alias), Observe (Fresh (A, B)));
               Guards ((if Op = Weighted then 34.0 else 57.0));
               Set_To (Alias, Make_Scalar (23.0));
               Guards (23.0);
               Set_To (Dest, Make_Scalar (25.0));
               Guards (25.0);
               Constant_Values (Alias, 25.0);
            end;
         end loop;
      end Interior;
      procedure Mismatch (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for Mode in 0 .. 2 loop
            declare
               A         : Image := New_Image (2, 3, (Float32, 1));
               B         : Image := New_Image (2, 3, (Float32, 1));
               Parent    : Image :=
                 New_Image
                   (5,
                    7,
                    ((if Mode = 1 then Int16 else Float32),
                     (if Mode = 2 then 3 else 1)));
               Dest      : Image :=
                 Region (Parent, (2, 1, (if Mode = 0 then 4 else 3), 2));
               Alias     : Image := Dest;
               Old_Shape : constant Dimension_Array := Shape (Alias);
            begin
               Set_To (A, Make_Scalar (20.0));
               Set_To (B, Make_Scalar (7.0));
               Set_To (Parent, Make_Scalar (91.0, 91.0, 91.0));
               Into (A, B, Dest);
               Equal (Observe (Dest), Observe (Fresh (A, B)));
               Assert (Shape (Alias) = Old_Shape, "old Region geometry");
               Constant_Values (Alias, 91.0);
               Constant_Values (Parent, 91.0);
               Set_To (Dest, Make_Scalar (25.0));
               Constant_Values (Parent, 91.0);
               Set_To (Alias, Make_Scalar (23.0, 23.0, 23.0));
               Constant_Values (Dest, 25.0);
            end;
         end loop;
      end Mismatch;
      procedure Aliases (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of All_Depths loop
            for Mode in 0 .. 6 loop
               declare
                  AH    : Mat := Create (1, 257, (Float64, 1));
                  BH    : Mat := Create (1, 257, (Float64, 1));
                  E     : Mat := Create (1, 257, (Float64, 1));
                  Alpha : constant Long_Float :=
                    (if Op = Weighted then 2.0 else 2.5);
               begin
                  for C in 0 .. 256 loop
                     declare
                        X : constant Long_Float :=
                          Long_Float (2 * (C mod 17 + 1));
                        Y : constant Long_Float :=
                          (if Mode >= 4 then X else Long_Float (C mod 7 + 3));
                        V : constant Long_Float :=
                          (if Op = Weighted
                           then X * Alpha - Y * 3.0 + 5.0
                           else X * Alpha + Y);
                     begin
                        Float64_Access.Set (AH, 0, C, Float64_Value (X));
                        Float64_Access.Set (BH, 0, C, Float64_Value (Y));
                        Float64_Access.Set
                          (E,
                           0,
                           C,
                           Float64_Value
                             (if D = UInt8
                              then Long_Float'Max (0.0, V)
                              else V));
                     end;
                  end loop;
                  declare
                     A    : Image := From_Mat (AH.Convert_To (D));
                     B    : Image := From_Mat (BH.Convert_To (D));
                     Dest : Image := New_Image (1, 257, (D, 1));
                  begin
                     case Mode is
                        when 0      =>
                           Into (A, B, A, Alpha);
                           Dest := A;

                        when 1      =>
                           Into (A, B, B, Alpha);
                           Dest := B;

                        when 2 | 3  =>
                           Dest := (if Mode = 2 then A else B);
                           Into (A, B, Dest, Alpha);

                        when 4      =>
                           Into (A, A, Dest, Alpha);

                        when 5      =>
                           Into (A, A, A, Alpha);
                           Dest := A;

                        when others =>
                           Dest := A;
                           Into (A, A, Dest, Alpha);
                     end case;
                     Equal (Observe (Dest), E.Convert_To (D));
                  end;
               end;
            end loop;
         end loop;
      end Aliases;
      procedure Numbers (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of All_Depths loop
            declare
               A    : Image := New_Image (1, 257, (D, 3));
               B    : Image := New_Image (1, 257, (D, 3));
               Dest : Image := New_Image (1, 257, (D, 3));
               X    : constant Long_Float :=
                 (if D = UInt8
                  then 200.0
                  elsif D = Int16
                  then 20000.0
                  else 20.0);
               Y    : constant Long_Float :=
                 (if D = UInt8
                  then 200.0
                  elsif D = Int16
                  then -20000.0
                  else -7.0);
               EH   : Mat := Create (1, 257, (Float64, 3));
               function Clamp (V : Long_Float) return Long_Float
               is (if D = UInt8
                   then Long_Float'Max (0.0, Long_Float'Min (255.0, V))
                   elsif D = Int16
                   then Long_Float'Max (-32768.0, Long_Float'Min (32767.0, V))
                   else V);
            begin
               Set_To (A, Make_Scalar (X, X, 4.0));
               Set_To (B, Make_Scalar (4.0, Y, 8.0));
               EH.Set_To
                 (Make_Scalar
                    (Clamp (X * 2.5 + (if Op = Weighted then -7.0 else 4.0)),
                     Clamp
                       (X
                        * 2.5
                        + (if Op = Weighted then Y * (-3.0) + 5.0 else Y)),
                     (if Op = Weighted then -9.0 else 18.0)));
               --  UInt8 channel 2 saturates below zero.
               if D = UInt8 and then Op = Weighted then
                  EH.Set_To (Make_Scalar (255.0, 0.0, 0.0));
               end if;
               Into (A, B, Dest);
               Equal (Observe (Dest), EH.Convert_To (D));
               Equal (Observe (Dest), Observe (Fresh (A, B)));
            end;
         end loop;
         --  Both Int16 endpoints and portable exact Int32 mathematics.
         for D of Depth_List'(Int16, Int32) loop
            declare
               A    : Image := New_Image (1, 2, (D, 1));
               B    : Image := New_Image (1, 2, (D, 1));
               Dest : Image;
               H    : Mat := Create (1, 2, (Int32, 1));
               V    : constant Int32_Value :=
                 (if D = Int16 then 20000 else 1000000);
            begin
               Int32_Access.Set (H, 0, 0, V);
               Int32_Access.Set (H, 0, 1, -V);
               A := From_Mat (H.Convert_To (D));
               Set_To (B, Make_Scalar (0.0));
               Into (A, B, Dest, 2.0, 0.0, 0.0);
               Int32_Access.Set
                 (H, 0, 0, (if D = Int16 then 32767 else V * 2));
               Int32_Access.Set
                 (H, 0, 1, (if D = Int16 then -32768 else (-V) * 2));
               Equal (Observe (Dest), H.Convert_To (D));
            end;
         end loop;
         --  This large witness is in range but not Float32-exact. HAL may
         --  preempt generic double work even with OpenCL disabled. Preserve
         --  exact native backend storage, not a universal mathematical answer.
         declare
            H : Mat := Create (1, 2, (Int32, 1));
            Z : Mat := Create (1, 2, (Int32, 1));
            procedure Source_Storage (A : Image) is
               Source : constant Mat := Observe (A);
            begin
               Assert
                 (Int32_Access.Get (Source, 0, 0) = 100000001
                  and then Int32_Access.Get (Source, 0, 1) = -100000001,
                  "large witness exact source storage");
            end Source_Storage;
         begin
            Int32_Access.Set (H, 0, 0, 100000001);
            Int32_Access.Set (H, 0, 1, -100000001);
            Int32_Access.Set (Z, 0, 0, 0);
            Int32_Access.Set (Z, 0, 1, 0);
            for Mode in 0 .. 4 loop
               declare
                  A     : Image := From_Mat (H.Clone);
                  B     : Image := From_Mat (Z.Clone);
                  Dest  : Image := New_Image (1, 2, (Int32, 1));
                  Alias : Image := Dest;
                  E     : constant Mat :=
                    Raw_ABI.Native_Expected
                      (H,
                       Z,
                       Op,
                       (if Mode = 0 then 0 elsif Mode in 1 | 3 then 1 else 2),
                       Is_UMat,
                       2.0,
                       0.0,
                       0.0);
               begin
                  Source_Storage (A);
                  Equal (Observe (B), Z);
                  if Mode = 0 then
                     declare
                        F : constant Image := Fresh (A, B, 2.0, 0.0, 0.0);
                     begin
                        Into (A, B, Dest, 2.0, 0.0, 0.0);
                        Equal (Observe (F), E);
                        Equal (Observe (Dest), Observe (F));
                        Equal (Observe (Dest), E);
                        Equal (Observe (Alias), E);
                        Source_Storage (A);
                        Equal (Observe (B), Z);
                        Ada.Text_IO.Put_Line
                          ("Weighted Int32 parity "
                           & Op'Image
                           & " UMat="
                           & Is_UMat'Image
                           & " OpenCL="
                           & Raw_ABI.OpenCL_Enabled'Image
                           & " source="
                           & Int32_Access.Get (H, 0, 0)'Image
                           & " function="
                           & Int32_Access.Get (Observe (F), 0, 0)'Image
                           & " procedure="
                           & Int32_Access.Get (Observe (Dest), 0, 0)'Image
                           & " alias="
                           & Int32_Access.Get (Observe (Alias), 0, 0)'Image
                           & " native="
                           & Int32_Access.Get (E, 0, 0)'Image);
                        Raw_ABI.Report_Int32_Backend (E);
                     end;
                  else
                     Alias := (if Mode in 1 | 3 then A else B);
                     if Mode = 1 then
                        Into (A, B, A, 2.0, 0.0, 0.0);
                        Dest := A;
                     elsif Mode = 2 then
                        Into (A, B, B, 2.0, 0.0, 0.0);
                        Dest := B;
                     else
                        Dest := Alias;
                        Into (A, B, Dest, 2.0, 0.0, 0.0);
                     end if;
                     Equal (Observe (Dest), E);
                     Equal (Observe (Alias), E);
                  end if;
               end;
            end loop;
         end;
         for D of Depth_List'(UInt8, Int16, Int32) loop
            declare
               A    : Image := New_Image (1, 257, (D, 1));
               B    : Image := New_Image (1, 257, (D, 1));
               Dest : Image;
               E    : Mat := Create (1, 257, (Int32, 1));
            begin
               Set_To (A, Make_Scalar (1.0));
               Set_To (B, Make_Scalar (0.0));
               Into (A, B, Dest, 1.499_999_99, 1.0, 0.0);
               for C in 0 .. 256 loop
                  Int32_Access.Set (E, 0, C, 2);
               end loop;
               if D = Int32 then
                  Equal
                    (Observe (Dest),
                     Raw_ABI.Native_Expected
                       (Observe (A),
                        Observe (B),
                        Op,
                        0,
                        Is_UMat,
                        1.499_999_99,
                        1.0,
                        0.0));
               else
                  Equal (Observe (Dest), E.Convert_To (D));
               end if;
               Equal
                 (Observe (Dest),
                  Observe (Fresh (A, B, 1.499_999_99, 1.0, 0.0)));
            end;
         end loop;
      end Numbers;
      procedure Floating (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Alpha : constant Long_Float := 1.000_000_06;
         Beta  : constant Long_Float := -0.333_333_333_333;
         Gamma : constant Long_Float := 0.000_000_07;
      begin
         for D of Depth_List'(Float32, Float64, Float16) loop
            for Special in Boolean loop
               for Coefficient in 0 .. 1 loop
                  for Mode in 0 .. 7 loop
                     declare
                        AH    : Mat := Create (1, 257, (Float64, 1));
                        BH    : Mat := Create (1, 257, (Float64, 1));
                        X     : Mat := Create (1, 3, (Float64, 1));
                        Z     : Mat := Create (1, 3, (Float64, 1));
                        Scale : constant Long_Float :=
                          (if Coefficient = 0 then Alpha else -0.0);
                     begin
                        Float64_Access.Set (X, 0, 0, 0.0);
                        Float64_Access.Set (X, 0, 1, 1.0);
                        Float64_Access.Set (X, 0, 2, -1.0);
                        Z.Set_To (Make_Scalar (0.0));
                        declare
                           Specials : constant Mat := Divide (X, Z);
                        begin
                           for C in 0 .. 256 loop
                              Float64_Access.Set
                                (AH,
                                 0,
                                 C,
                                 Float64_Value
                                   (1.000_000_119_209_289_6
                                    * Long_Float (C mod 17 + 1)));
                              Float64_Access.Set
                                (BH,
                                 0,
                                 C,
                                 Float64_Value
                                   (-1.000_000_238_418_579_1
                                    * Long_Float (C mod 11 + 1)));
                              if Special and then C mod 7 in 0 .. 2 then
                                 declare
                                    S : constant Mat :=
                                      Specials.Region
                                        ((Point_Coordinate (C mod 3),
                                          0,
                                          1,
                                          1));
                                    T : Mat :=
                                      AH.Region
                                        ((Point_Coordinate (C), 0, 1, 1));
                                 begin
                                    S.Copy_To (T);
                                 end;
                              elsif Special and then C mod 7 in 3 .. 4 then
                                 Float64_Access.Set
                                   (AH,
                                    0,
                                    C,
                                    (if C mod 7 = 3 then 0.0 else -0.0));
                              end if;
                           end loop;
                        end;
                        AH := AH.Convert_To (D);
                        BH := BH.Convert_To (D);
                        declare
                           A    : Image := From_Mat (AH.Clone);
                           B    : Image := From_Mat (BH.Clone);
                           Dest : Image := New_Image (1, 257, (D, 1));
                           E    : constant Mat :=
                             (if Mode in 0 | 5
                              then
                                Observe
                                  (Fresh
                                     (A,
                                      (if Mode = 5 then A else B),
                                      Scale,
                                      Beta,
                                      Gamma))
                              else
                                Raw_ABI.Native_Expected
                                  (AH,
                                   (if Mode >= 6 then AH else BH),
                                   Op,
                                   (if Mode >= 6
                                    then 3
                                    elsif Mode in 2 | 4
                                    then 2
                                    else 1),
                                   Is_UMat,
                                   Scale,
                                   Beta,
                                   Gamma));
                        begin
                           case Mode is
                              when 0      =>
                                 Into (A, B, Dest, Scale, Beta, Gamma);

                              when 1      =>
                                 Into (A, B, A, Scale, Beta, Gamma);
                                 Dest := A;

                              when 2      =>
                                 Into (A, B, B, Scale, Beta, Gamma);
                                 Dest := B;

                              when 3 | 4  =>
                                 Dest := (if Mode = 3 then A else B);
                                 Into (A, B, Dest, Scale, Beta, Gamma);

                              when 5      =>
                                 Into (A, A, Dest, Scale, Beta, Gamma);

                              when 6      =>
                                 Into (A, A, A, Scale, Beta, Gamma);
                                 Dest := A;

                              when others =>
                                 Dest := A;
                                 Into (A, A, Dest, Scale, Beta, Gamma);
                           end case;
                           Equal (Observe (Dest), E);
                           --  Finite aliases must also be numerically correct,
                           --  not merely agree with a native oracle.
                           if not Special and then Coefficient = 0 then
                              declare
                                 V : constant Mat :=
                                   Observe (Dest).Convert_To (Float64);
                                 L : constant Mat := AH.Convert_To (Float64);
                                 R : constant Mat :=
                                   (if Mode >= 5
                                    then L
                                    else BH.Convert_To (Float64));
                              begin
                                 for C in 0 .. 256 loop
                                    declare
                                       LV       : constant Long_Float :=
                                         Long_Float
                                           (Float64_Access.Get (L, 0, C));
                                       RV       : constant Long_Float :=
                                         Long_Float
                                           (Float64_Access.Get (R, 0, C));
                                       Expected : constant Long_Float :=
                                         LV
                                         * Scale
                                         + (if Op = Weighted
                                            then RV * Beta + Gamma
                                            else RV);
                                    begin
                                       Assert
                                         (abs (Long_Float
                                                 (Float64_Access.Get (V, 0, C))
                                               - Expected)
                                          <= (if D = Float16
                                              then
                                                0.001
                                                * Long_Float'Max
                                                    (1.0, abs Expected)
                                              else 0.000_01),
                                          "finite alias numerical result");
                                    end;
                                 end loop;
                              end;
                           end if;
                        end;
                     end;
                  end loop;
               end loop;
            end loop;
         end loop;
         --  A precision witness: Scale_Add Float32 narrows scale; Float64
         --  retains the double. Add_Weighted CPU Float32 on 4.x uses double
         --  scalar coefficients but float SIMD coefficients; 5.0 narrows both.
         for D of Depth_List'(Float32, Float64) loop
            declare
               A    : Image := New_Image (1, 257, (D, 1));
               B    : Image := New_Image (1, 257, (D, 1));
               Dest : Image;
               H    : Mat;
            begin
               Set_To (A, Make_Scalar (1.0));
               Set_To (B, Make_Scalar (-1.0));
               Into (A, B, Dest, 1.000_000_01, 1.0, 0.0);
               Equal
                 (Observe (Dest),
                  Observe (Fresh (A, B, 1.000_000_01, 1.0, 0.0)));
               H := Observe (Dest).Convert_To (Float64);
               Assert
                 (Approximately_Equal
                    (Long_Float (Float64_Access.Get (H, 0, 256)),
                     (if D = Float64
                      then 0.000_000_01
                      elsif Op = Scaled
                        or else (Is_UMat and then Raw_ABI.OpenCL_Enabled)
                        or else Module_Bridge_Probe.OpenCV_Major_Version >= 5
                      then 0.0
                      else 0.000_000_01),
                     1.0E-12)
                  or else (Is_UMat
                           and then D = Float32
                           and then Op = Weighted
                           and then Float64_Access.Get (H, 0, 256) = 0.0),
                  "coefficient precision at scalar tail");
            end;
         end loop;
      end Floating;

      procedure ND (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depth_List'(Int32, Float32, Float16) loop
            declare
               A     : Image := New_ND ((2, 3, 5), (D, 1));
               B     : Image := New_ND ((2, 3, 5), (D, 1));
               Dest  : Image := New_ND ((2, 3, 5), (D, 1));
               Alias : Image := Dest;
               procedure Attempt is
               begin
                  Into (A, B, Dest);
               end Attempt;
               procedure Function_Attempt is
                  Unused : constant Image := Fresh (A, B);
                  pragma Unreferenced (Unused);
               begin
                  null;
               end Function_Attempt;
            begin
               Set_To (A, Make_Scalar (20.0));
               Set_To (B, Make_Scalar (7.0));
               Set_To (Dest, Make_Scalar (91.0));
               if Op = Scaled then
                  declare
                     Before : constant Mat := Observe (Dest).Clone;
                  begin
                     Assert_Raises_OpenCV_Error
                       (Attempt'Access, "2-D procedure");
                     Assert_Raises_OpenCV_Error
                       (Function_Attempt'Access, "2-D function");
                     Equal (Observe (Dest), Before);
                     Equal (Observe (Alias), Before);
                  end;
               else
                  Into (A, B, Dest);
                  Equal (Observe (Dest), Observe (Fresh (A, B)));
                  Equal (Observe (Alias), Observe (Dest));
                  Assert
                    (Dimension_Count (Dest) = 3
                     and then Shape (Dest) = (2, 3, 5)
                     and then Depth (Dest) = D
                     and then Channels (Dest) = 1,
                     "N-D metadata follows sources");
                  Set_To (Alias, Make_Scalar (23.0));
                  Equal (Observe (Alias), Observe (Dest));
                  Set_To (Dest, Make_Scalar (25.0));
                  Equal (Observe (Alias), Observe (Dest));
                  for Rank in Boolean loop
                     Dest :=
                       (if Rank
                        then New_Image (2, 3, (D, 1))
                        else New_ND ((2, 4, 5), (D, 1)));
                     Set_To (Dest, Make_Scalar (91.0));
                     Alias := Dest;
                     declare
                        Old : constant Mat := Observe (Alias).Clone;
                     begin
                        Into (A, B, Dest);
                        Equal (Observe (Dest), Observe (Fresh (A, B)));
                        --  Old N-D shape may differ from the fixed test shape:
                        Equal (Observe (Alias), Old);
                        Assert
                          (Shape (Alias) = Old.Shape
                           and then Depth (Alias) = D,
                           "old N-D allocation retained");
                        Set_To (Dest, Make_Scalar (25.0));
                        Assert
                          (Observe (Alias).Convert_To (Float64).Norm (Infinity)
                           = 91.0,
                           "N-D destination detached from old alias");
                        Equal (Observe (Alias), Old);
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end ND;
      procedure Empty (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Major : constant Natural := Module_Bridge_Probe.OpenCV_Major_Version;
      begin
         for D of Depth_List'(UInt8, Float32, Float16) loop
            for Mode in 0 .. 3 loop
               declare
                  A, B     : Image;
                  Dest     : Image := New_Image (2, 3, (Int16, 2));
                  Alias    : constant Image := Dest;
                  E        : Image;
                  Rejected : constant Boolean :=
                    (Mode >= 2 and then (Op = Weighted or else D /= UInt8));
                  Released : constant Boolean :=
                    (if Is_UMat
                     then Mode = 0
                     elsif Op = Weighted
                     then
                       Major >= 5
                       or else Mode = 0
                       or else Mode = 2
                       or else D = Float16
                     else
                       (Mode = 2 and then Major < 5)
                       or else (Mode = 0 and then Major < 5)
                       or else (D = Float16 and then Mode /= 0));
                  procedure Attempt is
                  begin
                     Into (A, B, Dest);
                  end Attempt;
                  procedure Function_Attempt is
                  begin
                     E := Fresh (A, B);
                  end Function_Attempt;
               begin
                  if Mode in 1 | 3 then
                     A := New_Image (0, 0, (D, 1));
                  end if;
                  if Mode in 1 | 2 then
                     B := New_Image (0, 0, (D, 1));
                  end if;
                  Set_To (Dest, Make_Scalar (91.0, 91.0));
                  if Rejected then
                     Assert_Raises_OpenCV_Error
                       (Attempt'Access, "mixed empty policy");
                     Assert_Raises_OpenCV_Error
                       (Function_Attempt'Access, "function empty policy");
                     Constant_Values (Dest, 91.0);
                     Assert
                       (Shape (Dest) = (2, 3),
                        "rejected empty preserves shape");
                  else
                     E := Fresh (A, B);
                     Into (A, B, Dest);
                     Assert
                       (Is_Empty (Dest) and then Is_Empty (E),
                        "accepted empty");
                     Assert
                       (Dimension_Count (Dest)
                        = (if Released and then Major >= 5 then 0 else 2),
                        "version-specific empty rank");
                     if Dimension_Count (Dest) = 2 then
                        Assert (Shape (Dest) = (0, 0), "empty shape");
                     end if;
                     Assert
                       (Depth (Dest)
                        = (if Released
                           then Int16
                           elsif Mode = 0
                           then UInt8
                           else D)
                        and then Channels (Dest) = (if Released then 2 else 1),
                        "release retains old type; create adopts source type");
                     if Released then
                        Assert
                          (Dimension_Count (E) = 0
                           and then Depth (E) = UInt8
                           and then Channels (E) = 1,
                           "fresh empty release metadata");
                     else
                        Equal (Observe (Dest), Observe (E));
                     end if;
                  end if;
                  Constant_Values (Alias, 91.0);
               end;
            end loop;
         end loop;
      end Empty;
      procedure Failures (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for Mode in 0 .. 3 loop
            declare
               A     : constant Image := New_Image (2, 3, (Float32, 1));
               B     : constant Image :=
                 New_Image
                   ((if Mode = 0 then 3 else 2),
                    (if Mode = 1 then 4 else 3),
                    ((if Mode = 2 then Int16 else Float32),
                     (if Mode = 3 then 3 else 1)));
               Dest  : Image := New_Image (2, 3, (UInt8, 1));
               Alias : constant Image := Dest;
               procedure Attempt is
               begin
                  Into (A, B, Dest);
               end Attempt;
               procedure Function_Attempt is
                  Unused : constant Image := Fresh (A, B);
                  pragma Unreferenced (Unused);
               begin
                  null;
               end Function_Attempt;
            begin
               Set_To (Dest, Make_Scalar (91.0));
               Assert_Raises_OpenCV_Error
                 (Attempt'Access, "source compatibility");
               Assert_Raises_OpenCV_Error
                 (Function_Attempt'Access, "function compatibility");
               Assert
                 (Dimension_Count (Dest) = 2
                  and then Shape (Dest) = (2, 3)
                  and then Depth (Dest) = UInt8
                  and then Channels (Dest) = 1,
                  "pre-native failure metadata");
               Constant_Values (Dest, 91.0);
               Constant_Values (Alias, 91.0);
            end;
         end loop;
      end Failures;
   end Cases;

   package Mat_Weighted is new
     Cases
       (Mat,
        Identity,
        Identity,
        Create,
        Create,
        Op      => Weighted,
        Is_UMat => False);
   package Mat_Scaled is new
     Cases
       (Mat,
        Identity,
        Identity,
        Create,
        Create,
        Op      => Scaled,
        Is_UMat => False);
   package UMat_Weighted is new
     Cases
       (UMat,
        Transfers.To_UMat,
        Transfers.To_Mat,
        Create_UMat,
        Create_UMat,
        Op      => Weighted,
        Is_UMat => True);
   package UMat_Scaled is new
     Cases
       (UMat,
        Transfers.To_UMat,
        Transfers.To_Mat,
        Create_UMat,
        Create_UMat,
        Op      => Scaled,
        Is_UMat => True);

   procedure Temporary (View : in out Mat) is
      Before : constant Mat := View.Clone;
      A      : Mat := Create (View.Rows, View.Columns, (UInt8, 1));
      Other  : constant Mat := Create (1, 2, (Float32, 1));
      Dest   : Mat;
   begin
      A.Set_To (Make_Scalar (5.0));
      for Op in Operation_Kind loop
         for Mismatch in Boolean loop
            declare
               procedure Attempt is
                  Source : constant Mat := (if Mismatch then Other else A);
               begin
                  if Op = Weighted then
                     Add_Weighted (Source, 2.0, Source, -3.0, View, 5.0);
                  else
                     Scale_Add (Source, 2.5, Source, View);
                  end if;
               end Attempt;
            begin
               Assert_Raises_OpenCV_Error
                 (Attempt'Access, "temporary destination");
               Equal (View, Before);
            end;
         end loop;
         for Left_View in Boolean loop
            if Op = Weighted then
               Add_Weighted
                 ((if Left_View then View else A),
                  2.0,
                  (if Left_View then A else View),
                  -3.0,
                  Dest,
                  5.0);
            else
               Scale_Add
                 ((if Left_View then View else A),
                  2.0,
                  (if Left_View then A else View),
                  Dest);
            end if;
            for R in 0 .. View.Rows - 1 loop
               for C in 0 .. View.Columns - 1 loop
                  Assert
                    (UInt8_Access.Get (Dest, R, C)
                     = (if Op = Weighted
                        then (if Left_View then 64 else 0)
                        else (if Left_View then 79 else 47)),
                     "temporary Left/Right allowed, order preserved");
               end loop;
            end loop;
            Dest.Set_To (Make_Scalar (99.0));
            Equal (View, Before);
         end loop;
      end loop;
   end Temporary;
   procedure External (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data   : aliased UInt8_Mat_View.Buffer_Array := (0 .. 19 => 37);
      Before : constant UInt8_Mat_View.Buffer_Array := Data;
      use type UInt8_Mat_View.Buffer_Array;
   begin
      UInt8_Mat_View.With_Writable_Strided_Mat_View
        (Data, 2, 3, 10, Temporary'Access);
      Assert (Data = Before, "every external pixel and padding");
   end External;
   procedure Selected (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Volume : Mat := Create (Dimension_Array'(2, 3, 4), (UInt8, 1));
      Hyper  : Mat := Create (Dimension_Array'(2, 2, 3, 4), (UInt8, 1));
      procedure ND_Source (View : in out Mat) is
         B      : Mat := Create (Dimension_Array'(2, 3, 4), (UInt8, 1));
         Dest   : Mat;
         Before : constant Mat := View.Clone;
         procedure Reject is
         begin
            Add_Weighted (B, 2.0, B, -3.0, View, 5.0);
         end Reject;
      begin
         B.Set_To (Make_Scalar (5.0));
         for Left_View in Boolean loop
            Add_Weighted
              ((if Left_View then View else B),
               2.0,
               (if Left_View then B else View),
               -3.0,
               Dest,
               5.0);
            for I in Size_Coordinate range 0 .. 1 loop
               for J in Size_Coordinate range 0 .. 2 loop
                  for K in Size_Coordinate range 0 .. 3 loop
                     Assert
                       (UInt8_Access.Get (Dest, Index_Array'(I, J, K))
                        = (if Left_View then 64 else 0),
                        "temporary matching N-D source ordering");
                     Assert
                       (UInt8_Access.Get (View, Index_Array'(I, J, K))
                        = UInt8_Access.Get (Before, Index_Array'(I, J, K)),
                        "N-D temporary storage unchanged");
                  end loop;
               end loop;
            end loop;
         end loop;
         Assert_Raises_OpenCV_Error (Reject'Access, "N-D temporary output");
      end ND_Source;
   begin
      Volume.Set_To (Make_Scalar (37.0));
      Volume.With_Selected_View
        (((Kind => Fix_Index, Index => 1),
          (Kind => Keep_Range, Bounds => (0, 3)),
          (Kind => Keep_Range, Bounds => (0, 4))),
         Temporary'Access);
      Hyper.Set_To (Make_Scalar (37.0));
      Hyper.With_Selected_View
        (((Kind => Fix_Index, Index => 1),
          (Kind => Keep_Range, Bounds => (0, 2)),
          (Kind => Keep_Range, Bounds => (0, 3)),
          (Kind => Keep_Range, Bounds => (0, 4))),
         ND_Source'Access);
      for I in Size_Coordinate range 0 .. 1 loop
         for J in Size_Coordinate range 0 .. 2 loop
            for K in Size_Coordinate range 0 .. 3 loop
               Assert
                 (UInt8_Access.Get (Volume, Index_Array'(I, J, K)) = 37,
                  "selected Parent unchanged");
            end loop;
         end loop;
      end loop;
   end Selected;
   procedure CPU (Test : in out Fixture) is
      procedure Run is
      begin
         UMat_Weighted.Whole (Test);
         UMat_Scaled.Whole (Test);
         UMat_Weighted.Interior (Test);
         UMat_Scaled.Interior (Test);
         UMat_Weighted.Aliases (Test);
         UMat_Scaled.Aliases (Test);
         UMat_Weighted.Numbers (Test);
         UMat_Scaled.Numbers (Test);
         UMat_Weighted.Floating (Test);
         UMat_Scaled.Floating (Test);
         UMat_Weighted.ND (Test);
         UMat_Scaled.ND (Test);
         UMat_Weighted.Empty (Test);
         UMat_Scaled.Empty (Test);
      end Run;
   begin
      Raw_ABI.With_OpenCL_Disabled (Run'Access);
   end CPU;
   procedure Register
     (Prefix   : String;
      Whole,
      Interior,
      Mismatch,
      Aliases,
      Numbers,
      Floating,
      ND,
      Empty,
      Failures : Caller.Test_Method) is
   begin
      Result.Add_Test (Caller.Create (Prefix & "whole reuse", Whole));
      Result.Add_Test (Caller.Create (Prefix & "Region reuse", Interior));
      Result.Add_Test
        (Caller.Create (Prefix & "mismatch detachment", Mismatch));
      Result.Add_Test
        (Caller.Create (Prefix & "Left/Right/shallow/A-A", Aliases));
      Result.Add_Test (Caller.Create (Prefix & "integer/C3", Numbers));
      Result.Add_Test
        (Caller.Create (Prefix & "floating/coefficient/half", Floating));
      Result.Add_Test (Caller.Create (Prefix & "N-D policy/reuse", ND));
      Result.Add_Test (Caller.Create (Prefix & "empty parity", Empty));
      Result.Add_Test (Caller.Create (Prefix & "failures", Failures));
   end Register;
   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Register
        ("Add_Weighted destination Mat ",
         Mat_Weighted.Whole'Access,
         Mat_Weighted.Interior'Access,
         Mat_Weighted.Mismatch'Access,
         Mat_Weighted.Aliases'Access,
         Mat_Weighted.Numbers'Access,
         Mat_Weighted.Floating'Access,
         Mat_Weighted.ND'Access,
         Mat_Weighted.Empty'Access,
         Mat_Weighted.Failures'Access);
      Register
        ("Scale_Add destination Mat ",
         Mat_Scaled.Whole'Access,
         Mat_Scaled.Interior'Access,
         Mat_Scaled.Mismatch'Access,
         Mat_Scaled.Aliases'Access,
         Mat_Scaled.Numbers'Access,
         Mat_Scaled.Floating'Access,
         Mat_Scaled.ND'Access,
         Mat_Scaled.Empty'Access,
         Mat_Scaled.Failures'Access);
      Register
        ("Add_Weighted destination UMat ",
         UMat_Weighted.Whole'Access,
         UMat_Weighted.Interior'Access,
         UMat_Weighted.Mismatch'Access,
         UMat_Weighted.Aliases'Access,
         UMat_Weighted.Numbers'Access,
         UMat_Weighted.Floating'Access,
         UMat_Weighted.ND'Access,
         UMat_Weighted.Empty'Access,
         UMat_Weighted.Failures'Access);
      Register
        ("Scale_Add destination UMat ",
         UMat_Scaled.Whole'Access,
         UMat_Scaled.Interior'Access,
         UMat_Scaled.Mismatch'Access,
         UMat_Scaled.Aliases'Access,
         UMat_Scaled.Numbers'Access,
         UMat_Scaled.Floating'Access,
         UMat_Scaled.ND'Access,
         UMat_Scaled.Empty'Access,
         UMat_Scaled.Failures'Access);
      Result.Add_Test
        (Caller.Create ("Weighted temporary external", External'Access));
      Result.Add_Test
        (Caller.Create ("Weighted temporary selected", Selected'Access));
      Result.Add_Test
        (Caller.Create ("Weighted raw Mat", Raw_ABI.Mat_Check'Access));
      Result.Add_Test
        (Caller.Create ("Weighted raw UMat", Raw_ABI.UMat_Check'Access));
      Result.Add_Test
        (Caller.Create ("Weighted UMat CPU fallback", CPU'Access));
      return Result'Access;
   end Suite;
end Weighted_Destination_Tests;
