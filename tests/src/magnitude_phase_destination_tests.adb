with Ada.Numerics;
with Ada.Unchecked_Conversion;
with Interfaces;
with Ada.Numerics.Long_Elementary_Functions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float64_Mat_View;
with Magnitude_Phase_Destination_Tests.Raw_ABI;

package body Magnitude_Phase_Destination_Tests is
   use OpenCV;
   use OpenCV.Core;
   use AUnit.Assertions;
   use Mat_Test_Support;
   use type Float64_Value;
   package F renames Float64_Access;
   package Math renames Ada.Numerics.Long_Elementary_Functions;
   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   type Channels_List is array (Positive range <>) of Channel_Count;
   function Identity (A : Mat) return Mat
   is (A);

   procedure Equal (A, B : Mat) is
      X : constant Mat := A.Convert_To (Float64);
      Y : constant Mat := B.Convert_To (Float64);
   begin
      Assert
        (A.Shape = B.Shape
         and then A.Depth = B.Depth
         and then A.Channels = B.Channels,
         "result metadata");
      for Ch in 0 .. Natural (A.Channels) - 1 loop
         declare
            P : constant Mat := X.Extract_Channel (Ch);
            Q : constant Mat := Y.Extract_Channel (Ch);
         begin
            for R in 0 .. P.Rows - 1 loop
               for C in 0 .. P.Columns - 1 loop
                  Assert
                    (abs (F.Get (P, R, C) - F.Get (Q, R, C)) < 0.000_01,
                     "every output element");
               end loop;
            end loop;
         end;
      end loop;
   end Equal;

   generic
      type Image is tagged private;
      with function From_Mat (A : Mat) return Image;
      with function Observe (A : Image) return Mat;
      with
        function New_Image
          (Rows, Columns : Natural; Element_Type : Mat_Type) return Image;
      with
        function New_ND
          (Shape : Dimension_Array; Element_Type : Mat_Type) return Image;
      with
        procedure Magnitude (X, Y : Image; Destination : in out Image) is <>;
      with
        procedure Phase
          (X, Y        : Image;
           Destination : in out Image;
           Units       : Angle_Unit := Radians) is <>;
      with function Magnitude (X, Y : Image) return Image is <>;
      with
        function Phase
          (X, Y : Image; Units : Angle_Unit := Radians) return Image is <>;
      with function Region (Self : Image; Area : Rect) return Image is <>;
      with function Locate_Region (Self : Image) return Region_Location is <>;
      with function Is_Empty (Self : Image) return Boolean is <>;
      with function Depth (Self : Image) return Depth_Type is <>;
      with function Channels (Self : Image) return Channel_Count is <>;
      with function Shape (Self : Image) return Dimension_Array is <>;
      with function Dimension_Count (Self : Image) return Natural is <>;
      with procedure Set_To (Self : in out Image; Value : Scalar) is <>;
      Is_Phase : Boolean;
   package Cases is
      procedure Whole (Test : in out Mat_Test_Fixture);
      procedure Interior (Test : in out Mat_Test_Fixture);
      procedure Mismatch (Test : in out Mat_Test_Fixture);
      procedure Aliases (Test : in out Mat_Test_Fixture);
      procedure Numbers (Test : in out Mat_Test_Fixture);
      procedure Validation (Test : in out Mat_Test_Fixture);
      procedure Empty (Test : in out Mat_Test_Fixture);
   end Cases;

   package body Cases is
      procedure Into
        (X, Y : Image; D : in out Image; U : Angle_Unit := Radians) is
      begin
         if Is_Phase then
            Phase (X, Y, D, U);
         else
            Magnitude (X, Y, D);
         end if;
      end Into;
      function Fresh (X, Y : Image; U : Angle_Unit := Radians) return Image is
      begin
         if Is_Phase then
            return Phase (X, Y, U);
         else
            return Magnitude (X, Y);
         end if;
      end Fresh;
      function Source
        (Depth : Depth_Type; Ch : Channel_Count; Second : Boolean) return Image
      is
         H : constant Mat := Create (2, 257, (Float64, Ch));
      begin
         for R in 0 .. 1 loop
            for C in 0 .. 256 loop
               declare
                  P : Mat :=
                    H.Region
                      ((Point_Coordinate (C), Point_Coordinate (R), 1, 1));
                  V : constant Long_Float :=
                    (if C mod 2 = 0 then 1.0 else -1.0)
                    * (0.25 + Long_Float (C mod 17) / 8.0);
                  W : constant Long_Float := (if Second then -2.0 * V else V);
               begin
                  P.Set_To (Make_Scalar (W, W / 2.0, W * 3.0));
               end;
            end loop;
         end loop;
         return From_Mat (H.Convert_To (Depth));
      end Source;
      procedure All_Values (A : Image; V : Long_Float) is
         H : constant Mat := Observe (A);
         E : Mat := Create (H.Shape, (H.Depth, H.Channels));
      begin
         E.Set_To (Make_Scalar (V, V, V));
         Equal (H, E);
      end All_Values;
      procedure Whole (Test : in out Mat_Test_Fixture) is
         pragma Unreferenced (Test);
      begin
         for Depth in Float32 .. Float64 loop
            for Ch of Channels_List'(1, 3) loop
               for U in Angle_Unit loop
                  declare
                     X : constant Image := Source (Depth, Ch, False);
                     Y : constant Image := Source (Depth, Ch, True);
                     D : Image := New_Image (2, 257, (Depth, Ch));
                     A : Image := D;
                  begin
                     Set_To (D, Make_Scalar (91.0, 91.0, 91.0));
                     Into (X, Y, D, U);
                     Equal (Observe (D), Observe (Fresh (X, Y, U)));
                     Equal (Observe (A), Observe (D));
                     Set_To (A, Make_Scalar (7.0, 7.0, 7.0));
                     All_Values (D, 7.0);
                     Set_To (D, Make_Scalar (9.0, 9.0, 9.0));
                     All_Values (A, 9.0);
                  end;
               end loop;
            end loop;
         end loop;
      end Whole;
      procedure Interior (Test : in out Mat_Test_Fixture) is
         pragma Unreferenced (Test);
      begin
         for Depth in Float32 .. Float64 loop
            for Ch of Channels_List'(1, 3) loop
               for U in Angle_Unit loop
                  declare
                     X        : constant Image := Source (Depth, Ch, False);
                     Y        : constant Image := Source (Depth, Ch, True);
                     P        : Image := New_Image (5, 261, (Depth, Ch));
                     D        : Image := Region (P, (2, 1, 257, 2));
                     A        : Image := D;
                     L        : constant Region_Location := Locate_Region (D);
                     Expected : Mat := Create (5, 261, (Depth, Ch));
                     E        : Mat := Expected.Region ((2, 1, 257, 2));
                  begin
                     Set_To (P, Make_Scalar (91.0, 91.0, 91.0));
                     Expected.Set_To (Make_Scalar (91.0, 91.0, 91.0));
                     Observe (Fresh (X, Y, U)).Copy_To (E);
                     Into (X, Y, D, U);
                     Equal (Observe (P), Expected);
                     Equal (Observe (A), Observe (D));
                     Assert (Locate_Region (D) = L, "Region geometry");
                     Set_To (A, Make_Scalar (7.0, 7.0, 7.0));
                     All_Values (D, 7.0);
                     All_Values (Region (P, (2, 1, 257, 2)), 7.0);
                     Set_To (D, Make_Scalar (9.0, 9.0, 9.0));
                     All_Values (A, 9.0);
                     All_Values (Region (P, (2, 1, 257, 2)), 9.0);
                  end;
               end loop;
            end loop;
         end loop;
      end Interior;
      procedure Mismatch (Test : in out Mat_Test_Fixture) is
         pragma Unreferenced (Test);
      begin
         for Kind in 0 .. 2 loop
            declare
               X : constant Image := Source (Float32, 1, False);
               Y : constant Image := Source (Float32, 1, True);
               T : constant Mat_Type :=
                 (if Kind = 1
                  then (Float64, 1)
                  elsif Kind = 2
                  then (Float32, 3)
                  else (Float32, 1));
               P : Image := New_Image (5, 261, T);
               D : Image :=
                 Region (P, (2, 1, (if Kind = 0 then 17 else 257), 2));
               A : Image := D;
            begin
               Set_To (P, Make_Scalar (91.0, 91.0, 91.0));
               Into (X, Y, D);
               Equal (Observe (D), Observe (Fresh (X, Y)));
               All_Values (P, 91.0);
               All_Values (A, 91.0);
               Set_To (D, Make_Scalar (7.0));
               All_Values (P, 91.0);
               Set_To (A, Make_Scalar (9.0, 9.0, 9.0));
               All_Values (D, 7.0);
               All_Values
                 (Region (P, (2, 1, (if Kind = 0 then 17 else 257), 2)), 9.0);
            end;
         end loop;
      end Mismatch;
      procedure Aliases (Test : in out Mat_Test_Fixture) is
         pragma Unreferenced (Test);
      begin
         for Depth in Float32 .. Float64 loop
            for Ch of Channels_List'(1, 3) loop
               for U in Angle_Unit loop
                  for Mode in 0 .. 6 loop
                     declare
                        X : Image := Source (Depth, Ch, False);
                        Y : Image := Source (Depth, Ch, True);
                        D : Image;
                        E : Image;
                     begin
                        if Mode >= 4 then
                           Y := X;
                        end if;
                        E := Fresh (X, Y, U);
                        case Mode is
                           when 0 | 5  =>
                              Into (X, Y, X, U);
                              Equal (Observe (X), Observe (E));

                           when 1      =>
                              Into (X, Y, Y, U);
                              Equal (Observe (Y), Observe (E));

                           when 2 | 6  =>
                              D := X;
                              Into (X, Y, D, U);
                              Equal (Observe (D), Observe (E));

                           when 3      =>
                              D := Y;
                              Into (X, Y, D, U);
                              Equal (Observe (D), Observe (E));

                           when others =>
                              Into (X, Y, D, U);
                              Equal (Observe (D), Observe (E));
                        end case;
                     end;
                  end loop;
               end loop;
            end loop;
         end loop;
      end Aliases;
      procedure Numbers (Test : in out Mat_Test_Fixture) is
         pragma Unreferenced (Test);
         type Values is array (Natural range <>) of Long_Float;
         Xs : constant Values :=
           (3.0,
            5.0,
            -3.0,
            0.0,
            0.0,
            1.0,
            0.0,
            -1.0,
            0.0,
            1.0,
            -1.0,
            -1.0,
            1.0,
            0.3,
            -0.000_3,
            300_000.0);
         Ys : constant Values :=
           (4.0,
            12.0,
            4.0,
            0.0,
            -7.0,
            0.0,
            1.0,
            0.0,
            -1.0,
            1.0,
            1.0,
            -1.0,
            -1.0,
            0.4,
            0.000_4,
            400_000.0);
      begin
         for Depth in Float32 .. Float64 loop
            for U in Angle_Unit loop
               declare
                  H : Mat := Create (1, Xs'Length, (Float64, 1));
                  K : Mat := Create (1, Xs'Length, (Float64, 1));
                  D : Image;
               begin
                  for C in Xs'Range loop
                     F.Set (H, 0, C, Float64_Value (Xs (C)));
                     F.Set (K, 0, C, Float64_Value (Ys (C)));
                  end loop;
                  Into
                    (From_Mat (H.Convert_To (Depth)),
                     From_Mat (K.Convert_To (Depth)),
                     D,
                     U);
                  declare
                     O : constant Mat := Observe (D).Convert_To (Float64);
                  begin
                     for C in Xs'Range loop
                        declare
                           E        : Long_Float;
                           V        : constant Long_Float :=
                             Long_Float (F.Get (O, 0, C));
                           Period   : constant Long_Float :=
                             (if U = Degrees
                              then 360.0
                              else 2.0 * Ada.Numerics.Pi);
                           Distance : Long_Float;
                        begin
                           if Is_Phase then
                              E :=
                                (if Xs (C) = 0.0 and then Ys (C) = 0.0
                                 then 0.0
                                 else Math.Arctan (Ys (C), Xs (C), Period));
                              if E < 0.0 then
                                 E := E + Period;
                              end if;
                              Distance := abs (E - V);
                              Distance :=
                                Long_Float'Min
                                  (Distance, abs (Period - Distance));
                              Assert
                                (Distance < Period * 0.3 / 360.0,
                                 "native fast-angle accuracy");
                           else
                              E := Math.Sqrt (Xs (C)**2 + Ys (C)**2);
                              Assert
                                (abs (E - V)
                                 <= 0.000_01 * Long_Float'Max (1.0, E),
                                 "independent finite magnitude");
                           end if;
                        end;
                     end loop;
                  end;
                  if Is_Phase then
                     Phase
                       (From_Mat (H.Convert_To (Depth)),
                        From_Mat (K.Convert_To (Depth)),
                        D);
                     Equal
                       (Observe (D),
                        Observe
                          (Fresh
                             (From_Mat (H.Convert_To (Depth)),
                              From_Mat (K.Convert_To (Depth)),
                              Radians)));
                  end if;
               end;
            end loop;
         end loop;
      end Numbers;
      procedure Validation (Test : in out Mat_Test_Fixture) is
         pragma Unreferenced (Test);
      begin
         for Kind in 0 .. 5 loop
            declare
               X : Image := New_Image (2, 3, (Float32, 1));
               Y : Image := X;
               D : Image := New_Image (2, 3, (Float64, 1));
               A : constant Image := D;
               procedure Attempt is
               begin
                  Into (X, Y, D);
               end Attempt;
               procedure Function_Attempt is
                  E : constant Image := Fresh (X, Y);
                  pragma Unreferenced (E);
               begin
                  null;
               end Function_Attempt;
            begin
               case Kind is
                  when 0      =>
                     X := New_ND ((2, 3, 5), (Float32, 1));
                     Y := X;

                  when 1      =>
                     Y := New_Image (1, 3, (Float32, 1));

                  when 2      =>
                     Y := New_Image (2, 4, (Float32, 1));

                  when 3      =>
                     Y := New_Image (2, 3, (Float64, 1));

                  when 4      =>
                     Y := New_Image (2, 3, (Float32, 3));

                  when others =>
                     X := New_Image (2, 3, (Int32, 1));
                     Y := X;
               end case;
               Set_To (D, Make_Scalar (91.0));
               Assert_Raises_OpenCV_Error
                 (Attempt'Access, "source validation before mutation");
               Assert_Raises_OpenCV_Error
                 (Function_Attempt'Access, "unchanged function source policy");
               All_Values (D, 91.0);
               All_Values (A, 91.0);
            end;
         end loop;
         declare
            X : Image;
            D : Image := New_Image (2, 3, (Float64, 1));
            A : constant Image := D;
            procedure Attempt is
            begin
               Into (X, X, D);
            end Attempt;
         begin
            Set_To (D, Make_Scalar (91.0));
            Assert_Raises_OpenCV_Error
              (Attempt'Access, "default empty rejected");
            All_Values (D, 91.0);
            All_Values (A, 91.0);
         end;
      end Validation;
      procedure Empty (Test : in out Mat_Test_Fixture) is
         pragma Unreferenced (Test);
      begin
         for Dpth in Float32 .. Float64 loop
            for U in Angle_Unit loop
               declare
                  X : constant Image := New_Image (0, 0, (Dpth, 1));
                  D : Image := New_Image (2, 3, (Int16, 3));
                  A : constant Image := D;
                  E : constant Image := Fresh (X, X, U);
               begin
                  Set_To (D, Make_Scalar (91.0, 91.0, 91.0));
                  Into (X, X, D, U);
                  Assert
                    (Is_Empty (D) and then Is_Empty (E),
                     "typed empty accepted");
                  Assert
                    (Depth (D) = Dpth and then Channels (D) = 1,
                     "typed empty source format");
                  Assert
                    (Dimension_Count (D) = Dimension_Count (E)
                     and then Shape (D) = Shape (E),
                     "native empty metadata parity");
                  All_Values (A, 91.0);
               end;
            end loop;
         end loop;
      end Empty;
   end Cases;
   package MM is new
     Cases (Mat, Identity, Identity, Create, Create, Is_Phase => False);
   package MP is new
     Cases (Mat, Identity, Identity, Create, Create, Is_Phase => True);
   package UM is new
     Cases
       (UMat,
        Transfers.To_UMat,
        Transfers.To_Mat,
        Create_UMat,
        Create_UMat,
        Is_Phase => False);
   package UP is new
     Cases
       (UMat,
        Transfers.To_UMat,
        Transfers.To_Mat,
        Create_UMat,
        Create_UMat,
        Is_Phase => True);

   procedure Temporary (View : in out Mat) is
      Source : Mat := Create (View.Shape, (Float64, 1));
      D      : Mat;
   begin
      Source.Set_To (Make_Scalar (4.0));
      for Is_Phase in Boolean loop
         for Compatible in Boolean loop
            declare
               X      : constant Mat :=
                 (if Compatible then Source else Create (1, 1, (Float32, 3)));
               Before : constant Mat := View.Clone;
               procedure Attempt is
               begin
                  if Is_Phase then
                     Phase (X, X, View);
                  else
                     Magnitude (X, X, View);
                  end if;
               end Attempt;
            begin
               Assert_Raises_OpenCV_Error
                 (Attempt'Access, "temporary output prohibited");
               Equal (View, Before);
               Assert
                 (View.Dimension_Count = Before.Dimension_Count,
                  "temporary rank preserved");
            end;
         end loop;
         if Is_Phase then
            Phase (View, Source, D, Degrees);
            Equal (D, Phase (View, Source, Degrees));
            Phase (Source, View, D);
            Equal (D, Phase (Source, View));
         else
            Magnitude (View, Source, D);
            Equal (D, Magnitude (View, Source));
            Magnitude (Source, View, D);
            Equal (D, Magnitude (Source, View));
         end if;
      end loop;
   end Temporary;
   procedure External (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Data   : aliased Float64_Mat_View.Buffer_Array := (0 .. 9 => 4.0);
      Before : constant Float64_Mat_View.Buffer_Array := Data;
      use type Float64_Mat_View.Buffer_Array;
   begin
      Float64_Mat_View.With_Writable_Strided_Mat_View
        (Data, 2, 3, 5, Temporary'Access);
      Assert (Data = Before, "external data and padding preserved");
   end External;
   procedure Selected (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Parent : Mat := Create (Dimension_Array'(2, 2, 3), (Float64, 1));
   begin
      Parent.Set_To (Make_Scalar (4.0));
      Parent.With_Selected_View
        (((Kind => Fix_Index, Index => 1),
          (Kind => Keep_Range, Bounds => (0, 2)),
          (Kind => Keep_Range, Bounds => (0, 3))),
         Temporary'Access);
      for I in Size_Coordinate range 0 .. 1 loop
         for J in Size_Coordinate range 0 .. 1 loop
            for K in Size_Coordinate range 0 .. 2 loop
               Assert
                 (F.Get (Parent, (I, J, K)) = 4.0,
                  "selected Parent unchanged");
            end loop;
         end loop;
      end loop;
   end Selected;
   procedure CPU (Test : in out Mat_Test_Fixture) is
      procedure Run is
      begin
         UM.Whole (Test);
         UP.Whole (Test);
         UM.Interior (Test);
         UP.Interior (Test);
         UM.Aliases (Test);
         UP.Aliases (Test);
      end Run;
   begin
      Raw_ABI.With_OpenCL_Disabled (Run'Access);
   end CPU;
   procedure Special (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      --  Deliberate IEEE operands, following existing special-value tests.
      pragma Suppress (Validity_Check);
      function IEEE is new
        Ada.Unchecked_Conversion (Interfaces.Unsigned_64, Float64_Value);
      type Values is array (Natural range <>) of Float64_Value;
      Xs : constant Values :=
        (0.0,
         IEEE (16#8000_0000_0000_0000#),
         IEEE (16#7FF0_0000_0000_0000#),
         IEEE (16#FFF0_0000_0000_0000#),
         IEEE (16#7FF8_0000_0000_0000#),
         1.0);
      Ys : constant Values :=
        (0.0, 0.0, 1.0, -1.0, 2.0, IEEE (16#7FF8_0000_0000_0000#));
      X  : Mat := Create (1, 6, (Float64, 1));
      Y  : Mat := Create (1, 6, (Float64, 1));
      use type F.Float64_Classification;
   begin
      for C in Xs'Range loop
         F.Set (X, 0, C, Xs (C));
         F.Set (Y, 0, C, Ys (C));
      end loop;
      for Dpth in Float32 .. Float64 loop
         for Is_Phase in Boolean loop
            for U in Angle_Unit loop
               declare
                  A  : constant Mat := X.Convert_To (Dpth);
                  B  : constant Mat := Y.Convert_To (Dpth);
                  E  : constant Mat :=
                    (if Is_Phase then Phase (A, B, U) else Magnitude (A, B));
                  D  : Mat;
                  UA : constant UMat := Transfers.To_UMat (A);
                  UB : constant UMat := Transfers.To_UMat (B);
                  UE : constant UMat :=
                    (if Is_Phase
                     then Phase (UA, UB, U)
                     else Magnitude (UA, UB));
                  UD : UMat;
               begin
                  if Is_Phase then
                     Phase (A, B, D, U);
                     Phase (UA, UB, UD, U);
                  else
                     Magnitude (A, B, D);
                     Magnitude (UA, UB, UD);
                  end if;
                  declare
                     H  : constant Mat := D.Convert_To (Float64);
                     K  : constant Mat := E.Convert_To (Float64);
                     UH : constant Mat :=
                       Transfers.To_Mat (UD).Convert_To (Float64);
                     UK : constant Mat :=
                       Transfers.To_Mat (UE).Convert_To (Float64);
                  begin
                     for C in Xs'Range loop
                        Assert
                          (F.Classify (H, 0, C) = F.Classify (K, 0, C),
                           "native Mat special classification");
                        Assert
                          (F.Classify (UH, 0, C) = F.Classify (UK, 0, C),
                           "native UMat special classification");
                     end loop;
                  end;
               end;
            end loop;
         end loop;
      end loop;
   end Special;
   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      procedure Add (Name : String; Process : Caller.Test_Method) is
      begin
         Result.Add_Test (Caller.Create (Name, Process));
      end Add;
   begin
      Add ("Mat Magnitude whole reuse", MM.Whole'Access);
      Add ("Mat Phase whole reuse", MP.Whole'Access);
      Add ("UMat Magnitude whole reuse", UM.Whole'Access);
      Add ("UMat Phase whole reuse", UP.Whole'Access);
      Add ("Mat Magnitude Region reuse", MM.Interior'Access);
      Add ("Mat Phase Region reuse", MP.Interior'Access);
      Add ("UMat Magnitude Region reuse", UM.Interior'Access);
      Add ("UMat Phase Region reuse", UP.Interior'Access);
      Add ("Mat Magnitude detachment", MM.Mismatch'Access);
      Add ("Mat Phase detachment", MP.Mismatch'Access);
      Add ("UMat Magnitude detachment", UM.Mismatch'Access);
      Add ("UMat Phase detachment", UP.Mismatch'Access);
      Add ("Mat Magnitude aliases", MM.Aliases'Access);
      Add ("Mat Phase aliases", MP.Aliases'Access);
      Add ("UMat Magnitude aliases", UM.Aliases'Access);
      Add ("UMat Phase aliases", UP.Aliases'Access);
      Add ("Mat Magnitude finite numbers", MM.Numbers'Access);
      Add ("Mat Phase quadrants and units", MP.Numbers'Access);
      Add ("UMat Magnitude finite numbers", UM.Numbers'Access);
      Add ("UMat Phase quadrants and units", UP.Numbers'Access);
      Add ("Mat Magnitude validation", MM.Validation'Access);
      Add ("Mat Phase validation", MP.Validation'Access);
      Add ("UMat Magnitude validation", UM.Validation'Access);
      Add ("UMat Phase validation", UP.Validation'Access);
      Add ("Mat Magnitude typed empty", MM.Empty'Access);
      Add ("Mat Phase typed empty", MP.Empty'Access);
      Add ("UMat Magnitude typed empty", UM.Empty'Access);
      Add ("UMat Phase typed empty", UP.Empty'Access);
      Add ("Magnitude Phase temporary external", External'Access);
      Add ("Magnitude Phase temporary selected", Selected'Access);
      Add ("Magnitude Phase UMat CPU fallback", CPU'Access);
      Add ("Magnitude Phase Mat raw ABI", Raw_ABI.Mat_Check'Access);
      Add ("Magnitude Phase UMat raw ABI", Raw_ABI.UMat_Check'Access);
      Add ("Magnitude Phase special classifications", Special'Access);
      return Result'Access;
   end Suite;
end Magnitude_Phase_Destination_Tests;
