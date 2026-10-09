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
with Polar_Destination_Tests.Raw_ABI;

package body Polar_Destination_Tests is
   use OpenCV;
   use OpenCV.Core;
   use AUnit.Assertions;
   use Mat_Test_Support;
   use type Float64_Value;
   package F renames Float64_Access;
   package Math renames Ada.Numerics.Long_Elementary_Functions;
   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   type Channel_List is array (Positive range <>) of Channel_Count;
   function Identity (A : Mat) return Mat
   is (A);

   procedure Equal (A, B : Mat) is
      P : constant Mat := A.Convert_To (Float64);
      Q : constant Mat := B.Convert_To (Float64);
   begin
      Assert
        (A.Shape = B.Shape
         and then A.Depth = B.Depth
         and then A.Channels = B.Channels,
         "paired output metadata");
      for Ch in 0 .. Natural (A.Channels) - 1 loop
         declare
            X : constant Mat := P.Extract_Channel (Ch);
            Y : constant Mat := Q.Extract_Channel (Ch);
         begin
            for R in 0 .. A.Rows - 1 loop
               for C in 0 .. A.Columns - 1 loop
                  Assert
                    (abs (F.Get (X, R, C) - F.Get (Y, R, C)) < 0.000_01,
                     "each paired output value");
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
      with function Region (Self : Image; Area : Rect) return Image is <>;
      with function Locate_Region (Self : Image) return Region_Location is <>;
      with procedure Set_To (Self : in out Image; Value : Scalar) is <>;
      with
        procedure Cart_To_Polar
          (X, Y             : Image;
           Magnitude, Angle : in out Image;
           Units            : Angle_Unit := Radians) is <>;
      with
        procedure Polar_To_Cart
          (Magnitude, Angle : Image;
           X, Y             : in out Image;
           Units            : Angle_Unit := Radians) is <>;
      with
        procedure Polar_To_Cart
          (Angle : Image; X, Y : in out Image; Units : Angle_Unit := Radians)
        is <>;
   package Cases is
      procedure Storage (Test : in out Mat_Test_Fixture);
      procedure Numbers (Test : in out Mat_Test_Fixture);
      procedure Common_Parent (Test : in out Mat_Test_Fixture);
      procedure Reverse_Reconstruction (Test : in out Mat_Test_Fixture);
   end Cases;

   package body Cases is
      procedure Common_Parent (Test : in out Mat_Test_Fixture) is
         pragma Unreferenced (Test);
      begin
         for D in Float32 .. Float64 loop
            for Ch of Channel_List'(1, 3) loop
               for Unit in Angle_Unit loop
                  for Op in 0 .. 2 loop
                     declare
                        T        : constant Mat_Type := (D, Ch);
                        P        : Image := New_Image (5, 600, T);
                        A, B     : Image := New_Image (2, 257, T);
                        X        : Image := Region (P, (2, 1, 257, 2));
                        Y        : Image := Region (P, (300, 1, 257, 2));
                        AX       : Image := X;
                        AY       : Image := Y;
                        LX       : constant Region_Location :=
                          Locate_Region (X);
                        LY       : constant Region_Location :=
                          Locate_Region (Y);
                        EX, EY   : Image;
                        Expected : Mat := Create (5, 600, T);
                        RX       : Mat := Expected.Region ((2, 1, 257, 2));
                        RY       : Mat := Expected.Region ((300, 1, 257, 2));
                     begin
                        Set_To (P, Make_Scalar (91.0, 91.0, 91.0));
                        Expected.Set_To (Make_Scalar (91.0, 91.0, 91.0));
                        Set_To (A, Make_Scalar (3.0, 5.0, -3.0));
                        Set_To (B, Make_Scalar (4.0, 12.0, -4.0));
                        if Op = 0 then
                           Cart_To_Polar (A, B, EX, EY, Unit);
                           Cart_To_Polar (A, B, X, Y, Unit);
                        elsif Op = 1 then
                           Polar_To_Cart (A, B, EX, EY, Unit);
                           Polar_To_Cart (A, B, X, Y, Unit);
                        else
                           Polar_To_Cart (B, EX, EY, Unit);
                           Polar_To_Cart (B, X, Y, Unit);
                        end if;
                        Observe (EX).Copy_To (RX);
                        Observe (EY).Copy_To (RY);
                        Equal (Observe (P), Expected);
                        Equal (Observe (AX), Observe (EX));
                        Equal (Observe (AY), Observe (EY));
                        Assert
                          (Locate_Region (X) = LX
                           and then Locate_Region (Y) = LY,
                           "common Parent offsets");
                        Set_To (AX, Make_Scalar (7.0, 7.0, 7.0));
                        RX.Set_To (Make_Scalar (7.0, 7.0, 7.0));
                        Equal (Observe (P), Expected);
                        Set_To (Y, Make_Scalar (8.0, 8.0, 8.0));
                        RY.Set_To (Make_Scalar (8.0, 8.0, 8.0));
                        Equal (Observe (AY), RY);
                        Equal (Observe (P), Expected);
                        Set_To (X, Make_Scalar (9.0, 9.0, 9.0));
                        RX.Set_To (Make_Scalar (9.0, 9.0, 9.0));
                        Equal (Observe (AX), RX);
                        Set_To (AY, Make_Scalar (10.0, 10.0, 10.0));
                        RY.Set_To (Make_Scalar (10.0, 10.0, 10.0));
                        Equal (Observe (Y), RY);
                        Equal (Observe (P), Expected);
                     end;
                  end loop;
               end loop;
            end loop;
         end loop;
      end Common_Parent;

      procedure Reverse_Reconstruction (Test : in out Mat_Test_Fixture) is
         pragma Unreferenced (Test);
      begin
         for D in Float32 .. Float64 loop
            for Ch of Channel_List'(1, 3) loop
               for Unit in Angle_Unit loop
                  declare
                     T                              : constant Mat_Type :=
                       (D, Ch);
                     HM, HA                         : constant Mat :=
                       Create (2, 257, (Float64, Ch));
                     Magnitude, Angle, X, Y, RM, RA : Image;
                     Scale                          : constant Long_Float :=
                       (if Unit = Degrees
                        then 1.0
                        else Ada.Numerics.Pi / 180.0);
                  begin
                     for Row in 0 .. 1 loop
                        for Col in 0 .. 256 loop
                           declare
                              PM : Mat :=
                                HM.Region
                                  ((Point_Coordinate (Col),
                                    Point_Coordinate (Row),
                                    1,
                                    1));
                              PA : Mat :=
                                HA.Region
                                  ((Point_Coordinate (Col),
                                    Point_Coordinate (Row),
                                    1,
                                    1));
                              V  : constant Long_Float :=
                                Long_Float ((Col * 37 + Row * 19) mod 360);
                              M  : constant Long_Float :=
                                0.25 + Long_Float (Col mod 23);
                           begin
                              PM.Set_To (Make_Scalar (M, M, M));
                              PA.Set_To
                                (Make_Scalar
                                   (V * Scale, V * Scale, V * Scale));
                           end;
                        end loop;
                     end loop;
                     Magnitude := From_Mat (HM.Convert_To (D));
                     Angle := From_Mat (HA.Convert_To (D));
                     Polar_To_Cart (Magnitude, Angle, X, Y, Unit);
                     Assert
                       (Observe (X).Shape = HM.Shape
                        and then Observe (Y).Shape = HM.Shape
                        and then Observe (X).Depth = T.Depth
                        and then Observe (Y).Depth = T.Depth
                        and then Observe (X).Channels = T.Channels
                        and then Observe (Y).Channels = T.Channels,
                        "reverse coordinates metadata");
                     Cart_To_Polar (X, Y, RM, RA, Unit);
                     for Channel in 0 .. Natural (Ch) - 1 loop
                        declare
                           M : constant Mat :=
                             Observe (RM).Convert_To (Float64).Extract_Channel
                               (Channel);
                           A : constant Mat :=
                             Observe (RA).Convert_To (Float64).Extract_Channel
                               (Channel);
                        begin
                           for Row in 0 .. 1 loop
                              for Col in 0 .. 256 loop
                                 declare
                                    Expected_M : constant Float64_Value :=
                                      0.25 + Float64_Value (Col mod 23);
                                    Expected_A : constant Long_Float :=
                                      Long_Float
                                        ((Col * 37 + Row * 19) mod 360)
                                      * Scale;
                                    Distance   : constant Long_Float :=
                                      abs (Long_Float (F.Get (A, Row, Col))
                                           - Expected_A);
                                 begin
                                    Assert
                                      (abs (F.Get (M, Row, Col) - Expected_M)
                                       < 0.000_002 * Expected_M,
                                       "reverse original magnitude");
                                    Assert
                                      (Long_Float'Min
                                         (Distance,
                                          abs (360.0 * Scale - Distance))
                                       < 0.3 * Scale,
                                       "reverse original wrapped angle");
                                 end;
                              end loop;
                           end loop;
                        end;
                     end loop;
                  end;
               end loop;
            end loop;
         end loop;
      end Reverse_Reconstruction;

      procedure All_Values (A : Image; V : Long_Float) is
         H : constant Mat := Observe (A);
         E : Mat := Create (H.Shape, (H.Depth, H.Channels));
      begin
         E.Set_To (Make_Scalar (V, V, V));
         Equal (H, E);
      end All_Values;

      procedure Storage (Test : in out Mat_Test_Fixture) is
         pragma Unreferenced (Test);
      begin
         for D in Float32 .. Float64 loop
            for Ch of Channel_List'(1, 3) loop
               for U in Angle_Unit loop
                  for Operation in 0 .. 2 loop
                     for Layout in 0 .. 4 loop
                        for Bad in 0 .. 2 loop
                           declare
                              T      : constant Mat_Type := (D, Ch);
                              A, B   : Image := New_Image (2, 257, T);
                              P, Q   : Image := New_Image (5, 261, T);
                              DT     : constant Mat_Type :=
                                (if Bad = 1
                                 then (UInt8, Ch)
                                 elsif Bad = 2
                                 then (D, 2)
                                 else T);
                              DP, DQ : Image := New_Image (5, 261, DT);
                              Area   : constant Rect :=
                                (2, 1, (if Bad = 0 then 17 else 257), 2);
                              X      : Image :=
                                (if Layout = 0
                                 then New_Image (2, 257, T)
                                 elsif Layout = 2 or else Layout = 3
                                 then Region (DP, Area)
                                 else Region (P, (2, 1, 257, 2)));
                              Y      : Image :=
                                (if Layout = 0
                                 then New_Image (2, 257, T)
                                 elsif Layout = 1 or else Layout = 3
                                 then Region (DQ, Area)
                                 else Region (Q, (2, 1, 257, 2)));
                              AX     : Image := X;
                              AY     : Image := Y;
                              LX     : constant Region_Location :=
                                Locate_Region (X);
                              LY     : constant Region_Location :=
                                Locate_Region (Y);
                              EX, EY : Image;
                           begin
                              Set_To (A, Make_Scalar (3.0, 5.0, -3.0));
                              Set_To (B, Make_Scalar (4.0, 12.0, -4.0));
                              Set_To (P, Make_Scalar (91.0, 91.0, 91.0));
                              Set_To (Q, Make_Scalar (92.0, 92.0, 92.0));
                              Set_To (DP, Make_Scalar (81.0, 81.0, 81.0));
                              Set_To (DQ, Make_Scalar (82.0, 82.0, 82.0));
                              if Operation = 0 then
                                 Cart_To_Polar (A, B, EX, EY, U);
                                 Cart_To_Polar (A, B, X, Y, U);
                              elsif Operation = 1 then
                                 Polar_To_Cart (A, B, EX, EY, U);
                                 Polar_To_Cart (A, B, X, Y, U);
                              else
                                 Polar_To_Cart (B, EX, EY, U);
                                 Polar_To_Cart (B, X, Y, U);
                              end if;
                              Equal (Observe (X), Observe (EX));
                              Equal (Observe (Y), Observe (EY));
                              if Layout /= 0 then
                                 declare
                                    EP : Mat := Create (5, 261, T);
                                    EQ : Mat := Create (5, 261, T);
                                    RP : Mat := EP.Region ((2, 1, 257, 2));
                                    RQ : Mat := EQ.Region ((2, 1, 257, 2));
                                 begin
                                    EP.Set_To (Make_Scalar (91.0, 91.0, 91.0));
                                    EQ.Set_To (Make_Scalar (92.0, 92.0, 92.0));
                                    if Layout = 1 or else Layout = 4 then
                                       Observe (EX).Copy_To (RP);
                                    end if;
                                    if Layout = 2 or else Layout = 4 then
                                       Observe (EY).Copy_To (RQ);
                                    end if;
                                    Equal (Observe (P), EP);
                                    Equal (Observe (Q), EQ);
                                 end;
                              end if;
                              if Layout = 0
                                or else Layout = 1
                                or else Layout = 4
                              then
                                 Equal (Observe (AX), Observe (X));
                                 Assert
                                   (Locate_Region (X) = LX,
                                    "first attachment");
                              else
                                 All_Values (DP, 81.0);
                                 All_Values (AX, 81.0);
                              end if;
                              if Layout = 0
                                or else Layout = 2
                                or else Layout = 4
                              then
                                 Equal (Observe (AY), Observe (Y));
                                 Assert
                                   (Locate_Region (Y) = LY,
                                    "second attachment");
                              else
                                 All_Values (DQ, 82.0);
                                 All_Values (AY, 82.0);
                              end if;
                              Set_To (AX, Make_Scalar (7.0, 7.0, 7.0));
                              Equal (Observe (Y), Observe (EY));
                              if Layout = 0
                                or else Layout = 1
                                or else Layout = 4
                              then
                                 All_Values (X, 7.0);
                                 Set_To (X, Make_Scalar (9.0, 9.0, 9.0));
                                 All_Values (AX, 9.0);
                              else
                                 Equal (Observe (X), Observe (EX));
                              end if;
                              Set_To (AY, Make_Scalar (8.0, 8.0, 8.0));
                              if Layout = 0
                                or else Layout = 2
                                or else Layout = 4
                              then
                                 All_Values (Y, 8.0);
                                 Set_To (Y, Make_Scalar (10.0, 10.0, 10.0));
                                 All_Values (AY, 10.0);
                              else
                                 Equal (Observe (Y), Observe (EY));
                              end if;
                           end;
                        end loop;
                     end loop;
                  end loop;
               end loop;
            end loop;
         end loop;
      end Storage;

      procedure Numbers (Test : in out Mat_Test_Fixture) is
         pragma Unreferenced (Test);
         type Values is array (Natural range <>) of Long_Float;
         XS : constant Values :=
           (3.0,
            5.0,
            -3.0,
            -3.0,
            3.0,
            0.0,
            1.0,
            -1.0,
            0.0,
            0.0,
            1.0,
            0.000_1,
            1.0E10);
         YS : constant Values :=
           (4.0,
            12.0,
            4.0,
            -4.0,
            -4.0,
            0.0,
            0.0,
            0.0,
            1.0,
            -1.0,
            0.000_001,
            -0.000_1,
            1.0E10);
      begin
         for D in Float32 .. Float64 loop
            for Ch of Channel_List'(1, 3) loop
               for U in Angle_Unit loop
                  declare
                     H, K  : constant Mat := Create (1, 257, (Float64, Ch));
                     Scale : constant Long_Float :=
                       (if U = Degrees then 180.0 / Ada.Numerics.Pi else 1.0);
                  begin
                     for C in 0 .. 256 loop
                        declare
                           P : Mat :=
                             H.Region ((Point_Coordinate (C), 0, 1, 1));
                           Q : Mat :=
                             K.Region ((Point_Coordinate (C), 0, 1, 1));
                           I : constant Natural := C mod XS'Length;
                        begin
                           P.Set_To (Make_Scalar (XS (I), XS (I), XS (I)));
                           Q.Set_To (Make_Scalar (YS (I), YS (I), YS (I)));
                        end;
                     end loop;
                     declare
                        A              : constant Image :=
                          From_Mat (H.Convert_To (D));
                        B              : constant Image :=
                          From_Mat (K.Convert_To (D));
                        M, Angle, X, Y : Image;
                     begin
                        Cart_To_Polar (A, B, M, Angle, U);
                        declare
                           Expected : constant Polar_Coordinates :=
                             Cart_To_Polar (Observe (A), Observe (B), U);
                        begin
                           Equal (Observe (M), Expected.Magnitude);
                           Equal (Observe (Angle), Expected.Angle);
                        end;
                        Polar_To_Cart (M, Angle, X, Y, U);
                        for Channel in 0 .. Natural (Ch) - 1 loop
                           declare
                              Mag   : constant Mat :=
                                Observe (M).Convert_To (Float64)
                                  .Extract_Channel (Channel);
                              Phase : constant Mat :=
                                Observe (Angle).Convert_To (Float64)
                                  .Extract_Channel (Channel);
                              RX    : constant Mat :=
                                Observe (X).Convert_To (Float64)
                                  .Extract_Channel (Channel);
                              RY    : constant Mat :=
                                Observe (Y).Convert_To (Float64)
                                  .Extract_Channel (Channel);
                           begin
                              for C in 0 .. 256 loop
                                 declare
                                    I        : constant Natural :=
                                      C mod XS'Length;
                                    V        : constant Long_Float :=
                                      Math.Sqrt (XS (I)**2 + YS (I)**2);
                                    Expected : constant Long_Float :=
                                      (if V = 0.0
                                       then 0.0
                                       else
                                         Math.Arctan (YS (I), XS (I)) * Scale);
                                    Distance : constant Long_Float :=
                                      abs (Long_Float (F.Get (Phase, 0, C))
                                           - Expected);
                                    Turn     : constant Long_Float :=
                                      2.0 * Ada.Numerics.Pi * Scale;
                                 begin
                                    Assert
                                      (abs (Long_Float (F.Get (Mag, 0, C)) - V)
                                       <= 0.000_001 * Long_Float'Max (1.0, V),
                                       "independent finite magnitude");
                                    Assert
                                      (Long_Float'Min
                                         (Distance, abs (Turn - Distance))
                                       <= 0.3
                                          * Ada.Numerics.Pi
                                          / 180.0
                                          * Scale,
                                       "wrapped fast angle accuracy");
                                    Assert
                                      (abs (Long_Float (F.Get (RX, 0, C))
                                            - XS (I))
                                       <= 0.006 * Long_Float'Max (1.0, V),
                                       "Cartesian round trip X");
                                    Assert
                                      (abs (Long_Float (F.Get (RY, 0, C))
                                            - YS (I))
                                       <= 0.006 * Long_Float'Max (1.0, V),
                                       "Cartesian round trip Y");
                                 end;
                              end loop;
                           end;
                        end loop;
                     end;
                  end;
               end loop;
            end loop;
         end loop;
      end Numbers;
   end Cases;

   package M is new Cases (Mat, Identity, Identity, Create);
   package U is new
     Cases (UMat, Transfers.To_UMat, Transfers.To_Mat, Create_UMat);

   procedure Boundaries (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
   begin
      for D in Float32 .. Float64 loop
         declare
            A      : constant Mat := Create (0, 0, (D, 3));
            X, Y   : Mat := Create (2, 3, (Float64, 1));
            AX     : constant Mat := X;
            AY     : constant Mat := Y;
            UA     : constant UMat := Create_UMat (0, 0, (D, 3));
            UX, UY : UMat := Create_UMat (2, 3, (Float64, 1));
            function Same (P, Q : Mat) return Boolean
            is (P.Is_Empty = Q.Is_Empty
                and then P.Dimension_Count = Q.Dimension_Count
                and then P.Shape = Q.Shape
                and then P.Depth = Q.Depth
                and then P.Channels = Q.Channels);
            function Same (P, Q : UMat) return Boolean
            is (P.Is_Empty = Q.Is_Empty
                and then P.Dimension_Count = Q.Dimension_Count
                and then P.Shape = Q.Shape
                and then P.Depth = Q.Depth
                and then P.Channels = Q.Channels);
         begin
            X.Set_To (Make_Scalar (91.0));
            Y.Set_To (Make_Scalar (92.0));
            Cart_To_Polar (A, A, X, Y);
            declare
               E : constant Polar_Coordinates := Cart_To_Polar (A, A);
            begin
               Assert
                 (Same (X, E.Magnitude) and then Same (Y, E.Angle),
                  "Mat typed-empty pair metadata");
            end;
            Cart_To_Polar (UA, UA, UX, UY);
            declare
               E : constant UMat_Polar_Coordinates := Cart_To_Polar (UA, UA);
            begin
               Assert
                 (Same (UX, E.Magnitude) and then Same (UY, E.Angle),
                  "UMat direct typed-empty metadata");
            end;
            Polar_To_Cart (A, X, Y);
            Polar_To_Cart (UA, UX, UY);
            declare
               E  : constant Cartesian_Coordinates := Polar_To_Cart (A);
               UE : constant UMat_Cartesian_Coordinates := Polar_To_Cart (UA);
            begin
               Assert
                 (Same (X, E.X) and then Same (Y, E.Y), "Mat empty polar");
               Assert
                 (Same (UX, UE.X) and then Same (UY, UE.Y),
                  "UMat empty polar");
            end;
            Assert
              (F.Get (AX, 0, 0) = 91.0 and then F.Get (AY, 0, 0) = 92.0,
               "empty transforms preserve old aliases");
         end;
         declare
            A      : Mat := Create (Dimension_Array'(2, 3, 5), (D, 3));
            X, Y   : Mat;
            UX, UY : UMat;
         begin
            A.Set_To (Make_Scalar (0.0));
            Polar_To_Cart (A, X, Y);
            Polar_To_Cart (Transfers.To_UMat (A), UX, UY);
            Assert
              (X.Shape = A.Shape and then Y.Shape = A.Shape,
               "unit magnitude N-D Mat preserved");
            Assert
              (UX.Shape = A.Shape and then UY.Shape = A.Shape,
               "unit magnitude N-D UMat preserved");
            declare
               procedure Attempt is
               begin
                  Cart_To_Polar (A, A, X, Y);
               end Attempt;
            begin
               Assert_Raises_OpenCV_Error
                 (Attempt'Access, "Cartesian N-D policy");
            end;
         end;
      end loop;
      declare
         A, X, Y : Mat;
         procedure Attempt is
         begin
            Polar_To_Cart (A, X, Y);
         end Attempt;
      begin
         Assert_Raises_OpenCV_Error (Attempt'Access, "default empty Angle");
      end;
   end Boundaries;

   procedure Empty_Permutations (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      function Same (P, Q : Mat) return Boolean
      is (P.Is_Empty = Q.Is_Empty
          and then P.Dimension_Count = Q.Dimension_Count
          and then P.Shape = Q.Shape
          and then P.Depth = Q.Depth
          and then P.Channels = Q.Channels);
      function Same (P, Q : UMat) return Boolean
      is (P.Is_Empty = Q.Is_Empty
          and then P.Dimension_Count = Q.Dimension_Count
          and then P.Shape = Q.Shape
          and then P.Element_Type = Q.Element_Type);
   begin
      for D in Float32 .. Float64 loop
         for Reused in Boolean loop
            for Kind in 0 .. 12 loop
               declare
                  A, B   : Mat;
                  UA, UB : UMat;
                  X, Y   : Mat;
                  UX, UY : UMat;
                  Polar  : constant Boolean := Kind >= 5 and then Kind /= 12;
                  Reject : constant Boolean :=
                    Kind in 1 .. 4 or else Kind in 10 | 12;
                  procedure Attempt is
                  begin
                     if not Polar then
                        Cart_To_Polar (A, B, X, Y);
                     elsif Kind = 11 then
                        Polar_To_Cart (B, X, Y);
                     else
                        Polar_To_Cart (A, B, X, Y);
                     end if;
                  end Attempt;
                  procedure UAttempt is
                  begin
                     if not Polar then
                        Cart_To_Polar (UA, UB, UX, UY);
                     elsif Kind = 11 then
                        Polar_To_Cart (UB, UX, UY);
                     else
                        Polar_To_Cart (UA, UB, UX, UY);
                     end if;
                  end UAttempt;
               begin
                  if Kind /= 1 and then Kind /= 10 then
                     B :=
                       Create
                         ((if Kind in 2 .. 3 or else Kind in 5 .. 7
                           then 2
                           else 0),
                          3,
                          (D, 3));
                     UB :=
                       Create_UMat
                         ((if Kind in 2 .. 3 or else Kind in 5 .. 7
                           then 2
                           else 0),
                          3,
                          (D, 3));
                  end if;
                  if Kind in 0 | 2 | 4 | 6 | 9 | 12 then
                     A := Create (0, 3, (D, 3));
                     UA := Create_UMat (0, 3, (D, 3));
                  elsif Kind = 3 or else Kind = 7 then
                     A := Create (2, 3, (D, 3));
                     UA := Create_UMat (2, 3, (D, 3));
                  end if;
                  if Kind = 3 then
                     B := Create (0, 3, (D, 3));
                     UB := Create_UMat (0, 3, (D, 3));
                  elsif Kind = 4 then
                     B := Create (0, 3, (D, 1));
                     UB := Create_UMat (0, 3, (D, 1));
                  elsif Kind = 12 then
                     B :=
                       Create
                         (0,
                          3,
                          ((if D = Float32 then Float64 else Float32), 3));
                     UB :=
                       Create_UMat
                         (0,
                          3,
                          ((if D = Float32 then Float64 else Float32), 3));
                  end if;
                  if Kind in 6 | 9 then
                     A := Create (0, 17, (UInt8, 2));
                     UA := Create_UMat (0, 17, (UInt8, 2));
                  end if;
                  if not A.Is_Empty then
                     A.Set_To (Make_Scalar (3.0, 3.0, 3.0));
                     UA.Set_To (Make_Scalar (3.0, 3.0, 3.0));
                  end if;
                  if not B.Is_Empty then
                     B.Set_To (Make_Scalar (4.0, 4.0, 4.0));
                     UB.Set_To (Make_Scalar (4.0, 4.0, 4.0));
                  end if;
                  if Reused or else Reject then
                     X := Create (2, 3, (Float64, 1));
                     Y := Create (2, 3, (Float64, 1));
                     UX := Create_UMat (2, 3, (Float64, 1));
                     UY := Create_UMat (2, 3, (Float64, 1));
                     X.Set_To (Make_Scalar (91.0));
                     Y.Set_To (Make_Scalar (92.0));
                     UX.Set_To (Make_Scalar (91.0));
                     UY.Set_To (Make_Scalar (92.0));
                  end if;
                  declare
                     AX  : constant Mat := X;
                     AY  : constant Mat := Y;
                     AUX : constant UMat := UX;
                     AUY : constant UMat := UY;
                  begin
                     if Reject then
                        Assert_Raises_OpenCV_Error
                          (Attempt'Access, "empty Cartesian rejection");
                        Assert_Raises_OpenCV_Error
                          (UAttempt'Access, "empty UMat rejection");
                        Equal (X, AX);
                        Equal (Y, AY);
                        Equal (Transfers.To_Mat (UX), Transfers.To_Mat (AUX));
                        Equal (Transfers.To_Mat (UY), Transfers.To_Mat (AUY));
                        declare
                           EX, EY : Mat := Create (2, 3, (Float64, 1));
                        begin
                           EX.Set_To (Make_Scalar (91.0));
                           EY.Set_To (Make_Scalar (92.0));
                           Equal (X, EX);
                           Equal (Y, EY);
                           Equal (AX, EX);
                           Equal (AY, EY);
                           Equal (Transfers.To_Mat (UX), EX);
                           Equal (Transfers.To_Mat (UY), EY);
                           Equal (Transfers.To_Mat (AUX), EX);
                           Equal (Transfers.To_Mat (AUY), EY);
                        end;
                     else
                        Attempt;
                        UAttempt;
                        if Polar then
                           declare
                              E  : constant Cartesian_Coordinates :=
                                Polar_To_Cart (A, B);
                              UE : constant UMat_Cartesian_Coordinates :=
                                Polar_To_Cart (UA, UB);
                           begin
                              Assert
                                (Same (X, E.X) and then Same (Y, E.Y),
                                 "empty Mat polar metadata");
                              Assert
                                (Same (UX, UE.X) and then Same (UY, UE.Y),
                                 "empty UMat polar direct metadata");
                              if not X.Is_Empty then
                                 Equal (X, E.X);
                                 Equal (Y, E.Y);
                                 Equal
                                   (Transfers.To_Mat (UX),
                                    Transfers.To_Mat (UE.X));
                                 Equal
                                   (Transfers.To_Mat (UY),
                                    Transfers.To_Mat (UE.Y));
                              end if;
                           end;
                        else
                           declare
                              E  : constant Polar_Coordinates :=
                                Cart_To_Polar (A, B);
                              UE : constant UMat_Polar_Coordinates :=
                                Cart_To_Polar (UA, UB);
                           begin
                              Assert
                                (Same (X, E.Magnitude)
                                 and then Same (Y, E.Angle),
                                 "empty Mat metadata");
                              Assert
                                (Same (UX, UE.Magnitude)
                                 and then Same (UY, UE.Angle),
                                 "empty UMat metadata");
                           end;
                        end if;
                        if Reused and then X.Is_Empty then
                           Assert
                             (F.Get (AX, 0, 0) = 91.0
                              and then F.Get (AY, 0, 0) = 92.0,
                              "old Mat empty aliases survive");
                           Assert
                             (F.Get (Transfers.To_Mat (AUX), 0, 0) = 91.0
                              and then F.Get (Transfers.To_Mat (AUY), 0, 0)
                                       = 92.0,
                              "old UMat empty aliases survive");
                        end if;
                     end if;
                  end;
               end;
            end loop;
         end loop;
      end loop;
   end Empty_Permutations;

   procedure Temporary (View : in out Mat) is
      A    : Mat := Create (2, 3, (Float64, 1));
      X, Y : Mat;
   begin
      A.Set_To (Make_Scalar (3.0));
      for Op in 0 .. 1 loop
         for First in Boolean loop
            for Compatible in Boolean loop
               declare
                  S      : constant Mat :=
                    (if Compatible then A else Create (1, 1, (Float32, 3)));
                  Other  : Mat := Create (2, 3, (Float64, 1));
                  Before : constant Mat := View.Clone;
                  procedure Attempt is
                  begin
                     if Op = 0 then
                        if First then
                           Cart_To_Polar (S, S, View, Other);
                        else
                           Cart_To_Polar (S, S, Other, View);
                        end if;
                     else
                        if First then
                           Polar_To_Cart (S, S, View, Other);
                        else
                           Polar_To_Cart (S, S, Other, View);
                        end if;
                     end if;
                  end Attempt;
               begin
                  Other.Set_To (Make_Scalar (91.0));
                  Assert_Raises_OpenCV_Error
                    (Attempt'Access, "temporary paired output");
                  Equal (View, Before);
                  Assert
                    (F.Get (Other, 0, 0) = 91.0, "other output unchanged");
               end;
            end loop;
         end loop;
      end loop;
      Cart_To_Polar (View, A, X, Y);
      Cart_To_Polar (A, View, X, Y);
      Polar_To_Cart (View, A, X, Y);
      Polar_To_Cart (A, View, X, Y);
   end Temporary;

   procedure Capability (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Data   : aliased Float64_Mat_View.Buffer_Array := (0 .. 9 => 4.0);
      Before : constant Float64_Mat_View.Buffer_Array := Data;
      use type Float64_Mat_View.Buffer_Array;
      Parent : Mat := Create (Dimension_Array'(2, 2, 3), (Float64, 1));
   begin
      Float64_Mat_View.With_Writable_Strided_Mat_View
        (Data, 2, 3, 5, Temporary'Access);
      Assert (Data = Before, "external storage and padding preserved");
      Parent.Set_To (Make_Scalar (4.0));
      Parent.With_Selected_View
        (((Kind => Fix_Index, Index => 1),
          (Kind => Keep_Range, Bounds => (0, 2)),
          (Kind => Keep_Range, Bounds => (0, 3))),
         Temporary'Access);
      Assert (F.Get (Parent, (1, 1, 2)) = 4.0, "selected backing preserved");
   end Capability;

   procedure CPU (Test : in out Mat_Test_Fixture) is
      procedure Run is
      begin
         U.Storage (Test);
         U.Numbers (Test);
         Boundaries (Test);
      end Run;
   begin
      Magnitude_Phase_Destination_Tests.Raw_ABI.With_OpenCL_Disabled
        (Run'Access);
   end CPU;

   procedure Polar_Numbers (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      type Values is array (Natural range <>) of Long_Float;
      Angles     : constant Values :=
        (0.0, 90.0, 180.0, 270.0, 360.0, -90.0, -450.0, 720.0, 33.0);
      Magnitudes : constant Values := (0.0, 1.0, 3.0, -3.0, 100.0);
   begin
      for D in Float32 .. Float64 loop
         for Ch of Channel_List'(1, 3) loop
            for Unit in Angle_Unit loop
               for Unit_Magnitude in Boolean loop
                  declare
                     A, B : constant Mat := Create (1, 257, (Float64, Ch));
                  begin
                     for Col in 0 .. 256 loop
                        declare
                           P : Mat :=
                             A.Region ((Point_Coordinate (Col), 0, 1, 1));
                           Q : Mat :=
                             B.Region ((Point_Coordinate (Col), 0, 1, 1));
                           V : constant Long_Float :=
                             Angles (Col mod Angles'Length)
                             * (if Unit = Degrees
                                then 1.0
                                else Ada.Numerics.Pi / 180.0);
                           M : constant Long_Float :=
                             Magnitudes (Col mod Magnitudes'Length);
                        begin
                           P.Set_To (Make_Scalar (V, V, V));
                           Q.Set_To (Make_Scalar (M, M, M));
                        end;
                     end loop;
                     declare
                        Angle     : constant Mat := A.Convert_To (D);
                        Magnitude : constant Mat :=
                          (if Unit_Magnitude
                           then Identity (Create (0, 0, (UInt8, 2)))
                           else B.Convert_To (D));
                        E         : constant Cartesian_Coordinates :=
                          Polar_To_Cart (Magnitude, Angle, Unit);
                        UE        : constant UMat_Cartesian_Coordinates :=
                          Polar_To_Cart
                            (Transfers.To_UMat (Magnitude),
                             Transfers.To_UMat (Angle),
                             Unit);
                        X, Y      : Mat;
                        UX, UY    : UMat;
                     begin
                        if Unit_Magnitude then
                           Polar_To_Cart (Angle, X, Y, Unit);
                           Polar_To_Cart
                             (Transfers.To_UMat (Angle), UX, UY, Unit);
                        else
                           Polar_To_Cart (Magnitude, Angle, X, Y, Unit);
                           Polar_To_Cart
                             (Transfers.To_UMat (Magnitude),
                              Transfers.To_UMat (Angle),
                              UX,
                              UY,
                              Unit);
                        end if;
                        Equal (X, E.X);
                        Equal (Y, E.Y);
                        Equal (Transfers.To_Mat (UX), Transfers.To_Mat (UE.X));
                        Equal (Transfers.To_Mat (UY), Transfers.To_Mat (UE.Y));
                        for Channel in 0 .. Natural (Ch) - 1 loop
                           declare
                              RX : constant Mat :=
                                X.Convert_To (Float64).Extract_Channel
                                  (Channel);
                              RY : constant Mat :=
                                Y.Convert_To (Float64).Extract_Channel
                                  (Channel);
                           begin
                              for Col in 0 .. 256 loop
                                 declare
                                    V : constant Long_Float :=
                                      Angles (Col mod Angles'Length)
                                      * Ada.Numerics.Pi
                                      / 180.0;
                                    M : constant Long_Float :=
                                      (if Unit_Magnitude
                                       then 1.0
                                       else
                                         Magnitudes
                                           (Col mod Magnitudes'Length));
                                 begin
                                    Assert
                                      (abs (Long_Float (F.Get (RX, 0, Col))
                                            - M * Math.Cos (V))
                                       < 0.000_02
                                         * Long_Float'Max (1.0, abs M),
                                       "independent polar X");
                                    Assert
                                      (abs (Long_Float (F.Get (RY, 0, Col))
                                            - M * Math.Sin (V))
                                       < 0.000_02
                                         * Long_Float'Max (1.0, abs M),
                                       "independent polar Y");
                                 end;
                              end loop;
                           end;
                        end loop;
                     end;
                  end;
               end loop;
            end loop;
         end loop;
      end loop;
   end Polar_Numbers;

   procedure Special (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      pragma Suppress (Validity_Check);
      function IEEE is new
        Ada.Unchecked_Conversion (Interfaces.Unsigned_64, Float64_Value);
      type Values is array (Natural range <>) of Float64_Value;
      V    : constant Values :=
        (0.0,
         IEEE (16#8000_0000_0000_0000#),
         IEEE (16#7FF0_0000_0000_0000#),
         IEEE (16#FFF0_0000_0000_0000#),
         IEEE (16#7FF8_0000_0000_0000#));
      A, B : Mat := Create (1, 5, (Float64, 1));
      use type F.Float64_Classification;
   begin
      for Col in V'Range loop
         F.Set (A, 0, Col, V (Col));
         F.Set (B, 0, Col, V (Col));
      end loop;
      for D in Float32 .. Float64 loop
         for Unit in Angle_Unit loop
            for Polar in Boolean loop
               declare
                  P                : constant Mat := A.Convert_To (D);
                  Q                : constant Mat := B.Convert_To (D);
                  UP               : constant UMat := Transfers.To_UMat (P);
                  UQ               : constant UMat := Transfers.To_UMat (Q);
                  X, Y, EX, EY     : Mat;
                  UX, UY, UEX, UEY : UMat;
               begin
                  if Polar then
                     declare
                        E  : constant Cartesian_Coordinates :=
                          Polar_To_Cart (P, Q, Unit);
                        UE : constant UMat_Cartesian_Coordinates :=
                          Polar_To_Cart (UP, UQ, Unit);
                     begin
                        EX := E.X;
                        EY := E.Y;
                        UEX := UE.X;
                        UEY := UE.Y;
                     end;
                     Polar_To_Cart (P, Q, X, Y, Unit);
                     Polar_To_Cart (UP, UQ, UX, UY, Unit);
                  else
                     declare
                        E  : constant Polar_Coordinates :=
                          Cart_To_Polar (P, Q, Unit);
                        UE : constant UMat_Polar_Coordinates :=
                          Cart_To_Polar (UP, UQ, Unit);
                     begin
                        EX := E.Magnitude;
                        EY := E.Angle;
                        UEX := UE.Magnitude;
                        UEY := UE.Angle;
                     end;
                     Cart_To_Polar (P, Q, X, Y, Unit);
                     Cart_To_Polar (UP, UQ, UX, UY, Unit);
                  end if;
                  declare
                     HX   : constant Mat := X.Convert_To (Float64);
                     HY   : constant Mat := Y.Convert_To (Float64);
                     HEX  : constant Mat := EX.Convert_To (Float64);
                     HEY  : constant Mat := EY.Convert_To (Float64);
                     HUX  : constant Mat :=
                       Transfers.To_Mat (UX).Convert_To (Float64);
                     HUY  : constant Mat :=
                       Transfers.To_Mat (UY).Convert_To (Float64);
                     HUEX : constant Mat :=
                       Transfers.To_Mat (UEX).Convert_To (Float64);
                     HUEY : constant Mat :=
                       Transfers.To_Mat (UEY).Convert_To (Float64);
                  begin
                     for Col in V'Range loop
                        Assert
                          (F.Classify (HX, 0, Col) = F.Classify (HEX, 0, Col)
                           and then F.Classify (HY, 0, Col)
                                    = F.Classify (HEY, 0, Col),
                           "Mat special native classification");
                        Assert
                          (F.Classify (HUX, 0, Col) = F.Classify (HUEX, 0, Col)
                           and then F.Classify (HUY, 0, Col)
                                    = F.Classify (HUEY, 0, Col),
                           "UMat special native classification");
                     end loop;
                  end;
               end;
            end loop;
         end loop;
      end loop;
   end Special;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create ("Mat polar common Parent", M.Common_Parent'Access));
      Result.Add_Test
        (Caller.Create
           ("Polar empty permutations", Empty_Permutations'Access));
      Result.Add_Test
        (Caller.Create ("UMat polar common Parent", U.Common_Parent'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat reverse polar reconstruction",
            M.Reverse_Reconstruction'Access));
      Result.Add_Test
        (Caller.Create
           ("UMat reverse polar reconstruction",
            U.Reverse_Reconstruction'Access));
      Result.Add_Test
        (Caller.Create ("Polar special classifications", Special'Access));
      Result.Add_Test
        (Caller.Create ("Polar paired raw ABI", Raw_ABI.Check'Access));
      Result.Add_Test
        (Caller.Create
           ("Polar independent coordinates and function parity",
            Polar_Numbers'Access));
      Result.Add_Test
        (Caller.Create ("Mat polar paired storage", M.Storage'Access));
      Result.Add_Test
        (Caller.Create ("UMat polar paired storage", U.Storage'Access));
      Result.Add_Test
        (Caller.Create ("Mat polar finite round trips", M.Numbers'Access));
      Result.Add_Test
        (Caller.Create ("UMat polar finite round trips", U.Numbers'Access));
      Result.Add_Test
        (Caller.Create ("Polar empty and N-D boundaries", Boundaries'Access));
      Result.Add_Test
        (Caller.Create ("Polar temporary capabilities", Capability'Access));
      Result.Add_Test (Caller.Create ("Polar OpenCL disabled", CPU'Access));
      return Result'Access;
   end Suite;
end Polar_Destination_Tests;
