with AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Unchecked_Conversion;
with Interfaces;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.UInt8_Mat_View;
with Bitwise_Destination_Tests.Raw_ABI;

package body Bitwise_Destination_Tests is
   use OpenCV;
   use OpenCV.Core;
   use AUnit.Assertions;
   use Mat_Test_Support;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   type Channel_Count_Array is array (Positive range <>) of Channel_Count;
   type Depth_Type_Array is array (Positive range <>) of Depth_Type;
   function Identity (Self : Mat) return Mat
   is (Self);
   function Bits32 is new
     Ada.Unchecked_Conversion (Float32_Value, Interfaces.Unsigned_32);
   function Bits64 is new
     Ada.Unchecked_Conversion (Float64_Value, Interfaces.Unsigned_64);
   function Bits16 is new
     Ada.Unchecked_Conversion (Int16_Value, Interfaces.Unsigned_16);
   function Int_Bits32 is new
     Ada.Unchecked_Conversion (Int32_Value, Interfaces.Unsigned_32);
   function Expected
     (A, B : Interfaces.Unsigned_16; Op : Bitwise_Operation)
      return Interfaces.Unsigned_16
   is (case Op is
         when And_Operation => A and B,
         when Or_Operation  => A or B,
         when Xor_Operation => A xor B,
         when Not_Operation => not A);
   function Pattern (C : Natural) return UInt8_Value
   is (UInt8_Value ((C * 37 + 170) mod 256));
   function Other (C : Natural) return UInt8_Value
   is (UInt8_Value ((C * 19 + 204) mod 256));
   function Mask_Byte (C : Natural) return UInt8_Value
   is (case C mod 5 is
         when 0      => 0,
         when 1      => 1,
         when 2      => 2,
         when 3      => 127,
         when others => 255);
   function Input
     (Channels : Channel_Count := 1; Right : Boolean := False) return Mat
   is
      A : Mat := Create (2, 257, (UInt8, Channels));
   begin
      for R in 0 .. 1 loop
         for C in 0 .. 256 loop
            if Channels = 1 then
               UInt8_Access.Set
                 (A, R, C, (if Right then Other (C + R) else Pattern (C + R)));
            else
               UInt8_Vec3_Access.Set
                 (A,
                  R,
                  C,
                  (0 => (if Right then Other (C + R) else Pattern (C + R)),
                   1 => 16#AA#,
                   2 => 16#CC#));
            end if;
         end loop;
      end loop;
      return A;
   end Input;
   function Mask_Image return Mat is
      M : Mat := Create (2, 257, (UInt8, 1));
   begin
      for R in 0 .. 1 loop
         for C in 0 .. 256 loop
            UInt8_Access.Set (M, R, C, Mask_Byte (C));
         end loop;
      end loop;
      return M;
   end Mask_Image;
   function Empty_Destination return Mat is
      D : Mat := Create (2, 257, (Int16, 2));
   begin
      D.Set_To (Make_Scalar (91.0, 91.0));
      return D;
   end Empty_Destination;
   procedure Equal (A, B : Mat) is
   begin
      Assert
        (A.Shape = B.Shape
         and then A.Dimension_Count = B.Dimension_Count
         and then A.Depth = B.Depth
         and then A.Channels = B.Channels,
         "layout parity");
      if A.Is_Empty then
         return;
      end if;
      if A.Channels /= 1 then
         for Ch in 0 .. Natural (A.Channels) - 1 loop
            Equal (A.Extract_Channel (Ch), B.Extract_Channel (Ch));
         end loop;
         return;
      end if;
      for R in 0 .. A.Rows - 1 loop
         for C in 0 .. A.Columns - 1 loop
            case A.Depth is
               when Float16 =>
                  Assert
                    (Float16_Bits (Float16_Access.Get (A, R, C))
                     = Float16_Bits (Float16_Access.Get (B, R, C)),
                     "exact binary16 payload");

               when Float32 =>
                  Assert
                    (Bits32 (Float32_Access.Get (A, R, C))
                     = Bits32 (Float32_Access.Get (B, R, C)),
                     "exact binary32 payload");

               when Float64 =>
                  Assert
                    (Bits64 (Float64_Access.Get (A, R, C))
                     = Bits64 (Float64_Access.Get (B, R, C)),
                     "exact binary64 payload");

               when Int16   =>
                  Assert
                    (Bits16 (Int16_Access.Get (A, R, C))
                     = Bits16 (Int16_Access.Get (B, R, C)),
                     "Int16 bits");

               when Int32   =>
                  Assert
                    (Int_Bits32 (Int32_Access.Get (A, R, C))
                     = Int_Bits32 (Int32_Access.Get (B, R, C)),
                     "Int32 bits");

               when others  =>
                  if A.Channels = 1 then
                     Assert
                       (UInt8_Access.Get (A, R, C)
                        = UInt8_Access.Get (B, R, C),
                        "every UInt8 element");
                  else
                     declare
                        X : constant UInt8_Vec3.Vector :=
                          UInt8_Vec3_Access.Get (A, R, C);
                        Y : constant UInt8_Vec3.Vector :=
                          UInt8_Vec3_Access.Get (B, R, C);
                     begin
                        for Ch in 0 .. 2 loop
                           Assert (X (Ch) = Y (Ch), "all C3 channels");
                        end loop;
                     end;
                  end if;
            end case;
         end loop;
      end loop;
   end Equal;
   generic
      type Image is tagged private;
      with function Wrap (Self : Mat) return Image;
      with function Observe (Self : Image) return Mat;
      with
        function New_Image
          (Rows, Columns : Natural; Element_Type : Mat_Type) return Image;
      with
        function New_Image
          (Shape : Dimension_Array; Element_Type : Mat_Type) return Image;
      with function Region (Self : Image; Bounds : Rect) return Image is <>;
      with function Locate_Region (Self : Image) return Region_Location is <>;
      with function Shape (Self : Image) return Dimension_Array is <>;
      with function Depth (Self : Image) return Depth_Type is <>;
      with function Channels (Self : Image) return Channel_Count is <>;
      with function Dimension_Count (Self : Image) return Natural is <>;
      with function Is_Empty (Self : Image) return Boolean is <>;
      with procedure Set_To (Self : in out Image; Value : Scalar) is <>;
      with function Bitwise_And (Left, Right : Image) return Image is <>;
      with function Bitwise_Or (Left, Right : Image) return Image is <>;
      with function Bitwise_Xor (Left, Right : Image) return Image is <>;
      with function Bitwise_Not (Self : Image) return Image is <>;
      with function Bitwise_And (Left, Right, Mask : Image) return Image is <>;
      with function Bitwise_Or (Left, Right, Mask : Image) return Image is <>;
      with function Bitwise_Xor (Left, Right, Mask : Image) return Image is <>;
      with function Bitwise_Not (Self, Mask : Image) return Image is <>;
      with
        procedure Bitwise_And (Left, Right : Image; Destination : in out Image)
        is <>;
      with
        procedure Bitwise_Or (Left, Right : Image; Destination : in out Image)
        is <>;
      with
        procedure Bitwise_Xor (Left, Right : Image; Destination : in out Image)
        is <>;
      with
        procedure Bitwise_Not (Self : Image; Destination : in out Image) is <>;
      with
        procedure Bitwise_And
          (Left, Right, Mask : Image; Destination : in out Image) is <>;
      with
        procedure Bitwise_Or
          (Left, Right, Mask : Image; Destination : in out Image) is <>;
      with
        procedure Bitwise_Xor
          (Left, Right, Mask : Image; Destination : in out Image) is <>;
      with
        procedure Bitwise_Not (Self, Mask : Image; Destination : in out Image)
        is <>;
      Is_UMat : Boolean;
   package Cases is
      function Fresh
        (A, B, M : Image; Op : Bitwise_Operation; Masked : Boolean)
         return Image;
      procedure Into
        (A, B, M : Image;
         D       : in out Image;
         Op      : Bitwise_Operation;
         Masked  : Boolean);
      procedure Storage (Test : in out Fixture);
      procedure Aliases (Test : in out Fixture);
      procedure Bits (Test : in out Fixture);
      procedure Dimensions (Test : in out Fixture);
      procedure Empty (Test : in out Fixture);
      procedure Failures (Test : in out Fixture);
   end Cases;
   package body Cases is
      procedure Into
        (A, B, M : Image;
         D       : in out Image;
         Op      : Bitwise_Operation;
         Masked  : Boolean) is
      begin
         case Op is
            when And_Operation =>
               if Masked then
                  Bitwise_And (A, B, M, D);
               else
                  Bitwise_And (A, B, D);
               end if;

            when Or_Operation  =>
               if Masked then
                  Bitwise_Or (A, B, M, D);
               else
                  Bitwise_Or (A, B, D);
               end if;

            when Xor_Operation =>
               if Masked then
                  Bitwise_Xor (A, B, M, D);
               else
                  Bitwise_Xor (A, B, D);
               end if;

            when Not_Operation =>
               if Masked then
                  Bitwise_Not (A, M, D);
               else
                  Bitwise_Not (A, D);
               end if;
         end case;
      end Into;
      function Fresh
        (A, B, M : Image; Op : Bitwise_Operation; Masked : Boolean)
         return Image is
      begin
         case Op is
            when And_Operation =>
               return
                 (if Masked
                  then Bitwise_And (A, B, M)
                  else Bitwise_And (A, B));

            when Or_Operation  =>
               return
                 (if Masked then Bitwise_Or (A, B, M) else Bitwise_Or (A, B));

            when Xor_Operation =>
               return
                 (if Masked
                  then Bitwise_Xor (A, B, M)
                  else Bitwise_Xor (A, B));

            when Not_Operation =>
               return (if Masked then Bitwise_Not (A, M) else Bitwise_Not (A));
         end case;
      end Fresh;
      function Oracle
        (A, B, Old, M : Mat; Op : Bitwise_Operation; Masked : Boolean)
         return Mat
      is
         E : Mat := Old.Clone;
      begin
         for R in 0 .. 1 loop
            for C in 0 .. 256 loop
               if not Masked or else UInt8_Access.Get (M, R, C) /= 0 then
                  if A.Channels = 1 then
                     UInt8_Access.Set
                       (E,
                        R,
                        C,
                        UInt8_Value
                          (Expected
                             (Interfaces.Unsigned_16
                                (UInt8_Access.Get (A, R, C)),
                              Interfaces.Unsigned_16
                                (UInt8_Access.Get (B, R, C)),
                              Op)
                           and 255));
                  else
                     declare
                        X : UInt8_Vec3.Vector :=
                          UInt8_Vec3_Access.Get (A, R, C);
                        Y : constant UInt8_Vec3.Vector :=
                          UInt8_Vec3_Access.Get (B, R, C);
                     begin
                        for Ch in 0 .. 2 loop
                           X (Ch) :=
                             UInt8_Value
                               (Expected
                                  (Interfaces.Unsigned_16 (X (Ch)),
                                   Interfaces.Unsigned_16 (Y (Ch)),
                                   Op)
                                and 255);
                        end loop;
                        UInt8_Vec3_Access.Set (E, R, C, X);
                     end;
                  end if;
               end if;
            end loop;
         end loop;
         return E;
      end Oracle;
      procedure Storage (Test : in out Fixture) is
         pragma Unreferenced (Test);
         HM : constant Mat := Mask_Image;
         M  : Image := Wrap (HM.Clone);
      begin
         for Op in Bitwise_Operation loop
            for Masked in Boolean loop
               for Ch of Channel_Count_Array'(1, 3) loop
                  for Layout in 0 .. 4 loop
                     declare
                        HA       : constant Mat := Input (Ch);
                        HB       : constant Mat := Input (Ch, True);
                        A        : constant Image := Wrap (HA);
                        B        : constant Image := Wrap (HB);
                        Parent   : Image :=
                          New_Image
                            (4,
                             260,
                             (if Layout = 3
                              then (Int16, Ch)
                              elsif Layout = 4
                              then (UInt8, 4)
                              else (UInt8, Ch)));
                        D        : Image :=
                          (if Layout = 0
                           then New_Image (2, 257, (UInt8, Ch))
                           elsif Layout = 2
                           then Region (Parent, (1, 1, 256, 2))
                           else Region (Parent, (1, 1, 257, 2)));
                        Alias    : Image := D;
                        Location : constant Region_Location :=
                          Locate_Region (D);
                        Old      : Mat := Create (2, 257, (UInt8, Ch));
                     begin
                        Set_To (Parent, Make_Scalar (91.0, 91.0, 91.0, 91.0));
                        Set_To (D, Make_Scalar (37.0, 37.0, 37.0, 37.0));
                        Old.Set_To
                          (Make_Scalar
                             ((if Layout >= 2 then 0.0 else 37.0),
                              (if Layout >= 2 then 0.0 else 37.0),
                              (if Layout >= 2 then 0.0 else 37.0)));
                        declare
                           E      : constant Mat :=
                             Oracle (HA, HB, Old, HM, Op, Masked);
                           Before : constant Mat := Observe (Parent).Clone;
                        begin
                           Into (A, B, M, D, Op, Masked);
                           Equal (Observe (D), E);
                           if Layout <= 1 then
                              Equal (Observe (Alias), E);
                              Assert
                                (Locate_Region (D) = Location,
                                 "compatible geometry unchanged");
                              if Layout = 1 then
                                 declare
                                    P : constant Mat := Before.Clone;
                                    R : Mat := P.Region ((1, 1, 257, 2));
                                 begin
                                    E.Copy_To (R);
                                    Equal (Observe (Parent), P);
                                 end;
                              end if;
                              Set_To (Alias, Make_Scalar (23.0, 23.0, 23.0));
                              Equal (Observe (Alias), Observe (D));
                              Set_To (D, Make_Scalar (25.0, 25.0, 25.0));
                              Equal (Observe (Alias), Observe (D));
                              if Layout = 1 then
                                 declare
                                    P : constant Mat := Observe (Parent);
                                    G : constant Mat := Before;
                                 begin
                                    for R in Point_Coordinate range 0 .. 3 loop
                                       for C in Point_Coordinate range 0 .. 259
                                       loop
                                          if R = 0
                                            or else R = 3
                                            or else C = 0
                                            or else C >= 258
                                          then
                                             Equal
                                               (P.Region ((C, R, 1, 1)),
                                                G.Region ((C, R, 1, 1)));
                                          else
                                             Equal
                                               (P.Region ((C, R, 1, 1)),
                                                Observe (D).Region
                                                  ((C - 1, R - 1, 1, 1)));
                                          end if;
                                       end loop;
                                    end loop;
                                 end;
                              end if;
                           else
                              Equal (Observe (Parent), Before);
                              Set_To (D, Make_Scalar (25.0, 25.0, 25.0));
                              Equal (Observe (Parent), Before);
                              Set_To
                                (Alias, Make_Scalar (31.0, 31.0, 31.0, 31.0));
                              declare
                                 P : constant Mat := Before.Clone;
                                 R : Mat :=
                                   P.Region
                                     ((1,
                                       1,
                                       (if Layout = 2 then 256 else 257),
                                       2));
                              begin
                                 R.Set_To
                                   (Make_Scalar (31.0, 31.0, 31.0, 31.0));
                                 Equal (Observe (Parent), P);
                              end;
                              Assert
                                (Depth (D) = UInt8 and then Channels (D) = Ch,
                                 "new output follows source type");
                           end if;
                        end;
                     end;
                  end loop;
               end loop;
            end loop;
            --  All-zero and all-selected masks; functions remain independent.
            for Selected in Boolean loop
               declare
                  A   : constant Image := Wrap (Input);
                  B   : constant Image := Wrap (Input (Right => True));
                  D   : Image := New_Image (2, 257, (UInt8, 1));
                  Old : constant Mat := Input;
                  Z   : Image := Wrap (Old);
               begin
                  Set_To (M, Make_Scalar ((if Selected then 1.0 else 0.0)));
                  Set_To (D, Make_Scalar (37.0));
                  Into (A, B, M, D, Op, True);
                  if Selected then
                     Equal (Observe (D), Observe (Fresh (A, B, M, Op, False)));
                  else
                     declare
                        E : Mat := Create (2, 257, (UInt8, 1));
                     begin
                        E.Set_To (Make_Scalar (37.0));
                        Equal (Observe (D), E);
                        Into (A, B, M, Z, Op, True);
                        Equal (Observe (Z), Old);
                        D := New_Image (1, 3, (Int16, 1));
                        Into (A, B, M, D, Op, True);
                        E.Set_To (Make_Scalar (0.0));
                        Equal (Observe (D), E);
                        Equal (Observe (Fresh (A, B, M, Op, True)), E);
                     end;
                  end if;
               end;
            end loop;
            M := Wrap (HM.Clone);
         end loop;
      end Storage;
      procedure Aliases (Test : in out Fixture) is
         pragma Unreferenced (Test);
         HM : constant Mat := Mask_Image;
         M  : constant Image := Wrap (HM);
      begin
         for Op in Bitwise_Operation loop
            for Masked in Boolean loop
               for Same in Boolean loop
                  for Mode in 0 .. 4 loop
                     declare
                        HA  : constant Mat := Input;
                        HB  : constant Mat :=
                          (if Same then HA else Input (Right => True));
                        A   : Image := Wrap (HA);
                        B   : Image := (if Same then A else Wrap (HB));
                        D   : Image :=
                          (if Mode = 0
                           then Wrap (HA.Clone)
                           elsif Mode <= 2
                           then A
                           else B);
                        Old : constant Mat := (if Mode <= 2 then HA else HB);
                        E   : constant Mat :=
                          Oracle (HA, HB, Old, HM, Op, Masked);
                     begin
                        if Mode = 1 then
                           Into (A, B, M, A, Op, Masked);
                           Equal (Observe (A), E);
                        elsif Mode = 3 and then Op /= Not_Operation then
                           Into (A, B, M, B, Op, Masked);
                           Equal (Observe (B), E);
                        else
                           Into (A, B, M, D, Op, Masked);
                           Equal (Observe (D), E);
                        end if;
                     end;
                  end loop;
               end loop;
            end loop;
         end loop;
      end Aliases;
      procedure Bits (Test : in out Fixture) is
         pragma Unreferenced (Test);
         type Half_List is array (Natural range <>) of Interfaces.Unsigned_16;
         Values : constant Half_List :=
           (0, 16#8000#, 16#3C00#, 16#7C00#, 16#7E35#, 16#FE71#);
         M      : constant Image := Wrap (Mask_Image);
      begin
         for Op in Bitwise_Operation loop
            for Ch of Channel_Count_Array'(1, 3) loop
               declare
                  H     : Mat := Create (2, 257, (UInt8, Ch));
                  J     : Mat := Create (2, 257, (UInt8, Ch));
                  D     : Image := New_Image (2, 257, (UInt8, Ch));
                  E     : Mat := Create (2, 257, (UInt8, Ch));
                  Value : constant Long_Float :=
                    (case Op is
                       when And_Operation => 136.0,
                       when Or_Operation  => 238.0,
                       when Xor_Operation => 102.0,
                       when Not_Operation => 85.0);
               begin
                  H.Set_To (Make_Scalar (170.0, 170.0, 170.0));
                  J.Set_To (Make_Scalar (204.0, 204.0, 204.0));
                  E.Set_To (Make_Scalar (Value, Value, Value));
                  Into (Wrap (H), Wrap (J), M, D, Op, False);
                  Equal (Observe (D), E);
               end;
            end loop;
            for Dpth of
              Depth_Type_Array'(Int16, Int32, Float16, Float32, Float64)
            loop
               declare
                  H : Mat := Create (2, 257, (Dpth, 1));
                  J : Mat := Create (2, 257, (Dpth, 1));
               begin
                  H.Set_To (Make_Scalar (170.0));
                  J.Set_To (Make_Scalar (204.0));
                  if Dpth = Float16 then
                     for R in 0 .. 1 loop
                        for C in 0 .. 256 loop
                           Float16_Access.Set
                             (H, R, C, Float16_From_Bits (Values (C mod 6)));
                           Float16_Access.Set
                             (J,
                              R,
                              C,
                              Float16_From_Bits (Values ((C + 2) mod 6)));
                        end loop;
                     end loop;
                  end if;
                  for Masked in Boolean loop
                     declare
                        A      : constant Image := Wrap (H);
                        B      : constant Image := Wrap (J);
                        Parent : Image := New_Image (4, 260, (Dpth, 1));
                        D      : Image := Region (Parent, (1, 1, 257, 2));
                        Alias  : Image := D;
                        F      : constant Image := Fresh (A, B, M, Op, Masked);
                     begin
                        Set_To (Parent, Make_Scalar (0.0));
                        Into (A, B, M, D, Op, Masked);
                        Equal (Observe (D), Observe (F));
                        Equal (Observe (Alias), Observe (F));
                        if Dpth = Float16 and then Masked then
                           --  A nonzero old binary16 Region must survive zeros
                           --  in the mask, unlike a freshly allocated result.
                           Set_To (D, Make_Scalar (1.0));
                           Into (A, B, M, D, Op, True);
                           Equal (Observe (D), Observe (Alias));
                        end if;
                        for R in 0 .. 1 loop
                           for C in 0 .. 256 loop
                              if Dpth = Float16 then
                                 Assert
                                   (Float16_Bits
                                      (Float16_Access.Get (Observe (D), R, C))
                                    = (if Masked and then C mod 5 = 0
                                       then 16#3C00#
                                       else
                                         Expected
                                           (Values (C mod 6),
                                            Values ((C + 2) mod 6),
                                            Op)),
                                    "independent raw binary16 expectation");
                              elsif Dpth = Int16 then
                                 Assert
                                   (Bits16
                                      (Int16_Access.Get (Observe (D), R, C))
                                    = (if Masked and then C mod 5 = 0
                                       then 0
                                       else Expected (16#AA#, 16#CC#, Op)),
                                    "independent wider integer bits");
                              elsif Dpth = Int32 then
                                 declare
                                    X : constant Interfaces.Unsigned_32 :=
                                      (case Op is
                                         when And_Operation => 16#88#,
                                         when Or_Operation  => 16#EE#,
                                         when Xor_Operation => 16#66#,
                                         when Not_Operation => 16#FFFF_FF55#);
                                 begin
                                    Assert
                                      (Int_Bits32
                                         (Int32_Access.Get (Observe (D), R, C))
                                       = (if Masked and then C mod 5 = 0
                                          then 0
                                          else X),
                                       "independent Int32 bits");
                                 end;
                              end if;
                           end loop;
                        end loop;
                        declare
                           P : constant Mat := Observe (Parent);
                        begin
                           for R in 0 .. 3 loop
                              for C in 0 .. 259 loop
                                 if R = 0
                                   or else R = 3
                                   or else C = 0
                                   or else C >= 258
                                 then
                                    case Dpth is
                                       when Float16 =>
                                          Assert
                                            (Float16_Bits
                                               (Float16_Access.Get (P, R, C))
                                             = 0,
                                             "half Parent guard bits");

                                       when others  =>
                                          null;
                                    end case;
                                 end if;
                              end loop;
                           end loop;
                        end;
                        Set_To (Alias, Make_Scalar (23.0));
                        Equal (Observe (D), Observe (Alias));
                        --  Allocation-returning results are independent.
                        Equal
                          (Observe (F), Observe (Fresh (A, B, M, Op, Masked)));
                        Set_To (D, Make_Scalar (25.0));
                        Equal (Observe (D), Observe (Alias));
                     end;
                  end loop;
               end;
            end loop;
         end loop;
      end Bits;
      procedure Dimensions (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for Dpth of Depth_Type_Array'(UInt8, Float16) loop
            declare
               A : Image := New_Image (Dimension_Array'(2, 3, 5), (Dpth, 1));
               B : constant Image := A;
               M : constant Image :=
                 New_Image (Dimension_Array'(2, 3, 5), (UInt8, 1));
               D : Image := New_Image (2, 257, (UInt8, 1));
            begin
               Set_To (A, Make_Scalar (0.0));
               for Layout in 0 .. 2 loop
                  D :=
                    (if Layout = 0
                     then New_Image (Dimension_Array'(2, 3, 5), (Dpth, 1))
                     elsif Layout = 1
                     then New_Image (Dimension_Array'(3, 2, 5), (Int16, 3))
                     else A);
                  declare
                     Alias : Image := D;
                     F     : constant Image := Bitwise_Not (A);
                  begin
                     Bitwise_Not (A, D);
                     Assert
                       (Dimension_Count (D) = 3
                        and then Shape (D) = Dimension_Array'(2, 3, 5)
                        and then Depth (D) = Dpth
                        and then Channels (D) = 1,
                        "genuine N-D Not output");
                     for I in Size_Coordinate range 0 .. 1 loop
                        for J in Size_Coordinate range 0 .. 2 loop
                           for K in Size_Coordinate range 0 .. 4 loop
                              declare
                                 Idx : constant Index_Array := (I, J, K);
                              begin
                                 if Dpth = UInt8 then
                                    Assert
                                      (UInt8_Access.Get (Observe (D), Idx)
                                       = UInt8_Access.Get (Observe (F), Idx),
                                       "N-D UInt8 every element");
                                    if Layout = 0 then
                                       Assert
                                         (UInt8_Access.Get
                                            (Observe (Alias), Idx)
                                          = 255,
                                          "N-D reuse alias");
                                    end if;
                                 else
                                    Assert
                                      (Float16_Bits
                                         (Float16_Access.Get
                                            (Observe (D), Idx))
                                       = Float16_Bits
                                           (Float16_Access.Get
                                              (Observe (F), Idx)),
                                       "N-D binary16 exact bits");
                                 end if;
                              end;
                           end loop;
                        end loop;
                     end loop;
                     if Layout /= 1 then
                        Set_To (Alias, Make_Scalar (23.0));
                        Assert
                          ((if Dpth = UInt8
                            then
                              UInt8_Access.Get
                                (Observe (D), Index_Array'(1, 2, 4))
                              = 23
                            else
                              Float16_Bits
                                (Float16_Access.Get
                                   (Observe (D), Index_Array'(1, 2, 4)))
                              = Float16_Bits (To_Float16 (23.0))),
                           "N-D reciprocal alias write");
                        Set_To (D, Make_Scalar (25.0));
                        Assert
                          ((if Dpth = UInt8
                            then
                              UInt8_Access.Get
                                (Observe (Alias), Index_Array'(1, 2, 4))
                              = 25
                            else
                              Float16_Bits
                                (Float16_Access.Get
                                   (Observe (Alias), Index_Array'(1, 2, 4)))
                              = Float16_Bits (To_Float16 (25.0))),
                           "N-D reciprocal destination write");
                     end if;
                  end;
               end loop;
               --  Actual same native header, not merely a shallow copy.
               declare
                  F : constant Image := Bitwise_Not (A);
               begin
                  Bitwise_Not (A, A);
                  for I in Size_Coordinate range 0 .. 1 loop
                     for J in Size_Coordinate range 0 .. 2 loop
                        for K in Size_Coordinate range 0 .. 4 loop
                           declare
                              Idx : constant Index_Array := (I, J, K);
                           begin
                              if Dpth = UInt8 then
                                 Assert
                                   (UInt8_Access.Get (Observe (A), Idx)
                                    = UInt8_Access.Get (Observe (F), Idx),
                                    "N-D exact Self destination");
                              else
                                 Assert
                                   (Float16_Bits
                                      (Float16_Access.Get (Observe (A), Idx))
                                    = Float16_Bits
                                        (Float16_Access.Get
                                           (Observe (F), Idx)),
                                    "N-D exact Self binary16 bits");
                              end if;
                           end;
                        end loop;
                     end loop;
                  end loop;
               end;
               for Op in Bitwise_Operation loop
                  for Masked in Boolean loop
                     if Op /= Not_Operation or else Masked then
                        D := Wrap (Input);
                        declare
                           Before : constant Mat := Observe (D).Clone;
                           procedure Reject is
                           begin
                              Into (A, B, M, D, Op, Masked);
                           end Reject;
                           procedure Reject_Function is
                              F : constant Image :=
                                Fresh (A, B, M, Op, Masked);
                              pragma Unreferenced (F);
                           begin
                              null;
                           end Reject_Function;
                        begin
                           Assert_Raises_OpenCV_Error
                             (Reject'Access, "N-D boundary");
                           Assert_Raises_OpenCV_Error
                             (Reject_Function'Access, "function N-D boundary");
                           Equal (Observe (D), Before);
                        end;
                     end if;
                  end loop;
               end loop;
            end;
         end loop;
      end Dimensions;
      procedure Empty (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for Op in Bitwise_Operation loop
            for Masked in Boolean loop
               for Dpth of Depth_Type_Array'(UInt8, Float16) loop
                  for Form in 0 .. 3 loop
                     for Typed_Mask in Boolean loop
                        declare
                           Default      : Image;
                           A            : constant Image :=
                             (if Form mod 2 = 0
                              then Default
                              else New_Image (0, 0, (Dpth, 1)));
                           B            : constant Image :=
                             (if Form < 2
                              then Default
                              else New_Image (0, 0, (Dpth, 1)));
                           M            : constant Image :=
                             (if Typed_Mask
                              then New_Image (0, 0, (UInt8, 1))
                              else Default);
                           D            : Image := Wrap (Empty_Destination);
                           Alias        : constant Image := D;
                           Before       : constant Mat := Observe (D).Clone;
                           Typed_Source : constant Boolean := Form mod 2 = 1;
                           Released     : constant Boolean :=
                             (if Op = Not_Operation or else Masked
                              then not Typed_Source
                              elsif Is_UMat
                              then Form = 0
                              else Form /= 3);
                        begin
                           if Op = Not_Operation
                             or else Dpth = UInt8
                             or else Form = 0
                             or else Form = 3
                           then
                              Into (A, B, M, D, Op, Masked);
                              Assert
                                (Is_Empty (D), "empty destination result");
                              Assert
                                (Is_Empty (Fresh (A, B, M, Op, Masked)),
                                 "empty allocation result");
                              Assert
                                (Shape (D)'Length = Dimension_Count (D),
                                 "empty metadata readable");
                              Assert
                                (Dimension_Count (D)
                                 = (if Released
                                      and then Module_Bridge_Probe
                                                 .OpenCV_Major_Version
                                               >= 5
                                    then 0
                                    else 2),
                                 "empty release/create rank boundary");
                              Assert
                                (Depth (D) = (if Released then Int16 else Dpth)
                                 and then Channels (D)
                                          = (if Released then 2 else 1),
                                 "empty old-type/source-type boundary");
                              for Extent of Shape (D) loop
                                 Assert (Extent = 0, "every empty extent");
                              end loop;
                              Equal (Observe (Alias), Before);
                           end if;
                        end;
                     end loop;
                  end loop;
               end loop;
            end loop;
         end loop;
      end Empty;
      procedure Failures (Test : in out Fixture) is
         pragma Unreferenced (Test);
         A      : constant Image := Wrap (Input);
         D      : Image := Wrap (Input);
         Alias  : constant Image := D;
         Before : constant Mat := Observe (D).Clone;
      begin
         for Op in Bitwise_Operation loop
            for Kind in 0 .. 4 loop
               declare
                  B : constant Image :=
                    (if Kind = 0
                     then New_Image (1, 2, (UInt8, 1))
                     elsif Kind = 1
                     then New_Image (2, 257, (Int16, 1))
                     else New_Image (2, 257, (UInt8, 3)));
                  M : constant Image :=
                    (if Kind = 0
                     then New_Image (1, 2, (UInt8, 1))
                     elsif Kind = 1
                     then New_Image (2, 257, (Int16, 1))
                     else New_Image (2, 257, (UInt8, 3)));
                  procedure Reject is
                  begin
                     Into
                       (A,
                        (if Kind <= 2 then B else A),
                        M,
                        D,
                        Op,
                        Op = Not_Operation or else Kind >= 3);
                  end Reject;
               begin
                  Assert_Raises_OpenCV_Error
                    (Reject'Access, "operand/mask validation");
                  Equal (Observe (D), Before);
                  Equal (Observe (Alias), Before);
               end;
            end loop;
         end loop;
      end Failures;
   end Cases;
   package Mat_Cases is new
     Cases (Mat, Identity, Identity, Create, Create, Is_UMat => False);
   package UMat_Cases is new
     Cases
       (UMat,
        Transfers.To_UMat,
        Transfers.To_Mat,
        Create_UMat,
        Create_UMat,
        Is_UMat => True);
   procedure Temporary (View : in out Mat) is
      Before : constant Mat := View.Clone;
      A      : Mat := Create (View.Rows, View.Columns, (UInt8, 1));
      M      : Mat := A;
      D      : Mat;
   begin
      A.Set_To (Make_Scalar (170.0));
      for Op in Bitwise_Operation loop
         for Masked in Boolean loop
            for Mismatch in Boolean loop
               declare
                  Source : constant Mat :=
                    (if Mismatch then Create (1, 2, (Float32, 1)) else A);
                  Mask   : constant Mat :=
                    (if Mismatch then Create (1, 2, (UInt8, 1)) else M);
                  procedure Reject is
                  begin
                     Mat_Cases.Into (Source, Source, Mask, View, Op, Masked);
                  end Reject;
               begin
                  Assert_Raises_OpenCV_Error
                    (Reject'Access, "temporary output");
                  Equal (View, Before);
               end;
            end loop;
            for Position in 0 .. 3 loop
               declare
                  E : constant Mat :=
                    Mat_Cases.Fresh
                      ((if Position = 0 then View else A),
                       (if Position = 1 then View else A),
                       (if Position = 2 then View else M),
                       Op,
                       Masked);
               begin
                  D := Create (0, 0, (UInt8, 1));
                  Mat_Cases.Into
                    ((if Position = 0 then View else A),
                     (if Position = 1 then View else A),
                     (if Position = 2 then View else M),
                     D,
                     Op,
                     Masked);
                  Assert (not D.Is_Empty, "temporary source/mask permitted");
                  Equal (D, E);
                  D.Set_To (Make_Scalar (99.0));
                  Equal (View, Before);
               end;
            end loop;
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
      Assert (Data = Before, "external pixels and padding unchanged");
   end External;
   procedure Selected (Test : in out Fixture) is
      pragma Unreferenced (Test);
      P : Mat := Create (Dimension_Array'(2, 3, 4), (UInt8, 1));
   begin
      P.Set_To (Make_Scalar (37.0));
      P.With_Selected_View
        (((Kind => Fix_Index, Index => 1),
          (Kind => Keep_Range, Bounds => (0, 3)),
          (Kind => Keep_Range, Bounds => (0, 4))),
         Temporary'Access);
      for I in Size_Coordinate range 0 .. 1 loop
         for J in Size_Coordinate range 0 .. 2 loop
            for K in Size_Coordinate range 0 .. 3 loop
               Assert
                 (UInt8_Access.Get (P, Index_Array'(I, J, K)) = 37,
                  "selected Parent untouched");
            end loop;
         end loop;
      end loop;
   end Selected;
   procedure CPU (Test : in out Fixture) is
      procedure Run is
      begin
         UMat_Cases.Storage (Test);
         UMat_Cases.Aliases (Test);
         UMat_Cases.Bits (Test);
         UMat_Cases.Dimensions (Test);
         UMat_Cases.Empty (Test);
      end Run;
   begin
      Raw_ABI.With_OpenCL_Disabled (Run'Access);
   end CPU;
   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      procedure Add (Name : String; Method : Caller.Test_Method) is
      begin
         Result.Add_Test
           (Caller.Create ("Bitwise destination " & Name, Method));
      end Add;
   begin
      Add ("Mat whole/Region/mismatch/masks", Mat_Cases.Storage'Access);
      Add ("UMat whole/Region/mismatch/masks", UMat_Cases.Storage'Access);
      Add ("Mat source aliases/identities", Mat_Cases.Aliases'Access);
      Add ("UMat source aliases/identities", UMat_Cases.Aliases'Access);
      Add ("Mat integer/floating bits", Mat_Cases.Bits'Access);
      Add ("UMat integer/floating bits", UMat_Cases.Bits'Access);
      Add ("Mat N-D Not/boundaries", Mat_Cases.Dimensions'Access);
      Add ("UMat N-D Not/boundaries", UMat_Cases.Dimensions'Access);
      Add ("Mat empty", Mat_Cases.Empty'Access);
      Add ("UMat empty", UMat_Cases.Empty'Access);
      Add ("Mat validation failures", Mat_Cases.Failures'Access);
      Add ("UMat validation failures", UMat_Cases.Failures'Access);
      Add ("temporary external", External'Access);
      Add ("temporary selected", Selected'Access);
      Add ("raw Mat", Raw_ABI.Mat_Check'Access);
      Add ("raw UMat", Raw_ABI.UMat_Check'Access);
      Add ("UMat CPU fallback", CPU'Access);
      return Result'Access;
   end Suite;
end Bitwise_Destination_Tests;
