with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Int32_Vec3;
with OpenCV.Core.Int32_Vec3_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;
with Min_Max_Destination_Tests.Raw_ABI;

package body Min_Max_Destination_Tests is
   use OpenCV;
   use OpenCV.Core;
   use Mat_Test_Support;
   use AUnit.Assertions;
   use type UInt8_Value;
   use type Float64_Value;
   use type Int32_Value;
   use type Int32_Vec3.Vector;
   use type Float64_Access.Float64_Classification;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   package F64 renames Float64_Access;
   Result : aliased AUnit.Test_Suites.Test_Suite;
   type Depths is array (Positive range <>) of Depth_Type;
   type Channel_List is array (Positive range <>) of Channel_Count;

   function Identity (Self : Mat) return Mat
   is (Self);
   function Select_Value
     (A, B : Long_Float; Op : Operation_Kind) return Long_Float
   is (if Op = Minimum_Operation
       then Long_Float'Min (A, B)
       else Long_Float'Max (A, B));

   procedure Check (Actual, Expected : Long_Float) is
   begin
      Assert (Actual = Expected, "every finite extrema element");
   end Check;

   procedure Equal (Actual, Expected : Mat) is
      A : constant Mat :=
        (if Actual.Depth = Int32 then Actual else Actual.Convert_To (Float64));
      E : constant Mat :=
        (if Expected.Depth = Int32
         then Expected
         else Expected.Convert_To (Float64));
   begin
      Assert
        (Actual.Shape = Expected.Shape
         and then Actual.Depth = Expected.Depth
         and then Actual.Channels = Expected.Channels,
         "result layout parity");
      for Ch in 0 .. Natural (A.Channels) - 1 loop
         declare
            X : constant Mat := A.Extract_Channel (Ch);
            Y : constant Mat := E.Extract_Channel (Ch);
         begin
            for R in 0 .. X.Rows - 1 loop
               for C in 0 .. X.Columns - 1 loop
                  if Actual.Depth = Int32 then
                     --  Native NEON widening can round INT_MAX via Float32.
                     Assert
                       (Int32_Access.Get (X, R, C)
                        = Int32_Access.Get (Y, R, C),
                        "exact Int32 fresh/reused/alias parity");
                  else
                     Assert
                       (Float64_Access.Classify (X, R, C)
                        = Float64_Access.Classify (Y, R, C),
                        "every native classification, including tail");
                     if Float64_Access.Classify (X, R, C)
                       = Float64_Access.Finite
                     then
                        Check
                          (Long_Float (Float64_Access.Get (X, R, C)),
                           Long_Float (Float64_Access.Get (Y, R, C)));
                        if Float64_Access.Get (X, R, C) = 0.0 then
                           Assert
                             (Raw_ABI.Negative_Zero (X, R, C)
                              = Raw_ABI.Negative_Zero (Y, R, C),
                              "native zero sign including alias/tail "
                              & "boundary");
                        end if;
                     end if;
                  end if;
               end loop;
            end loop;
         end;
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
        procedure Minimum (Left, Right : Image; Destination : in out Image)
        is <>;
      with
        procedure Maximum (Left, Right : Image; Destination : in out Image)
        is <>;
      with function Minimum (Left, Right : Image) return Image is <>;
      with function Maximum (Left, Right : Image) return Image is <>;
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
      procedure Specials (Test : in out Fixture);
      procedure Empty (Test : in out Fixture);
      procedure Failures (Test : in out Fixture);
      procedure Small (Test : in out Fixture);
      procedure CPU (Test : in out Fixture);
   end Cases;

   package body Cases is
      procedure Into (A, B : Image; D : in out Image) is
      begin
         if Op = Minimum_Operation then
            Minimum (A, B, D);
         else
            Maximum (A, B, D);
         end if;
      end Into;
      function Fresh (A, B : Image) return Image
      is (if Op = Minimum_Operation then Minimum (A, B) else Maximum (A, B));
      procedure All_Values (Self : Image; Value : Long_Float) is
         H : constant Mat := Observe (Self);
         V : constant Mat :=
           (if H.Depth = Int32 then H else H.Convert_To (Float64));
      begin
         for Ch in 0 .. Natural (V.Channels) - 1 loop
            declare
               C : constant Mat := V.Extract_Channel (Ch);
            begin
               for R in 0 .. C.Rows - 1 loop
                  for Col in 0 .. C.Columns - 1 loop
                     if V.Depth = Int32 then
                        Assert
                          (Int32_Access.Get (C, R, Col) = Int32_Value (Value),
                           "exact Int32 constant value");
                     else
                        Check
                          (Long_Float (Float64_Access.Get (C, R, Col)), Value);
                     end if;
                  end loop;
               end loop;
            end;
         end loop;
      end All_Values;
      function Input
        (Col : Natural; D : Depth_Type; Left : Boolean) return Long_Float
      is (if Left
          then Long_Float (Col mod 13 + 1)
          elsif D = UInt8
          then Long_Float (Col mod 7 + 3)
          else -Long_Float (Col mod 7 + 3));
      function Vector (D : Depth_Type; Left : Boolean) return Image is
         H : Mat := Create (1, 257, (Float64, 1));
      begin
         for C in 0 .. 256 loop
            Float64_Access.Set (H, 0, C, Float64_Value (Input (C, D, Left)));
         end loop;
         return From_Mat (H.Convert_To (D));
      end Vector;
      procedure Whole (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depths'(UInt8, Int16, Int32, Float32, Float64, Float16) loop
            declare
               A     : Image := Vector (D, True);
               B     : constant Image := Vector (D, False);
               Dest  : Image := New_Image (1, 257, (D, 1));
               Alias : Image := Dest;
               E     : constant Image := Fresh (A, B);
            begin
               Into (A, B, Dest);
               Equal (Observe (Dest), Observe (E));
               Equal (Observe (Alias), Observe (E));
               Set_To (Alias, Make_Scalar (17.0));
               All_Values (Dest, 17.0);
               Set_To (Dest, Make_Scalar (19.0));
               All_Values (Alias, 19.0);
               Set_To (A, Make_Scalar (29.0));
               declare
                  H : constant Mat := Observe (E);
                  V : constant Mat :=
                    (if D = Int32 then H else H.Convert_To (Float64));
               begin
                  for C in 0 .. 256 loop
                     if D = Int32 then
                        Assert
                          (Int32_Access.Get (V, 0, C)
                           = Int32_Value
                               (Select_Value
                                  (Input (C, D, True),
                                   Input (C, D, False),
                                   Op)),
                           "exact Int32 independent function result");
                     else
                        Check
                          (Long_Float (Float64_Access.Get (V, 0, C)),
                           Select_Value
                             (Input (C, D, True), Input (C, D, False), Op));
                     end if;
                  end loop;
               end;
            end;
         end loop;
      end Whole;
      procedure Interior (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depths'(Int16, Float32, Float16) loop
            declare
               A      : Image := New_Image (2, 257, (D, 1));
               B      : Image := New_Image (2, 257, (D, 1));
               Parent : Image := New_Image (5, 260, (D, 1));
               Dest   : Image := Region (Parent, (1, 1, 257, 2));
               Alias  : Image := Dest;
               Before : constant Region_Location := Locate_Region (Dest);
               procedure Guards (Inside : Long_Float) is
                  V : constant Mat := Observe (Parent).Convert_To (Float64);
               begin
                  for R in 0 .. 4 loop
                     for C in 0 .. 259 loop
                        Check
                          (Long_Float (Float64_Access.Get (V, R, C)),
                           (if R in 1 .. 2 and then C in 1 .. 257
                            then Inside
                            else 91.0));
                     end loop;
                  end loop;
               end Guards;
            begin
               Set_To (A, Make_Scalar (-21.0));
               Set_To (B, Make_Scalar (2.0));
               Set_To (Parent, Make_Scalar (91.0));
               Into (A, B, Dest);
               All_Values (Dest, Select_Value (-21.0, 2.0, Op));
               All_Values (Alias, Select_Value (-21.0, 2.0, Op));
               Guards (Select_Value (-21.0, 2.0, Op));
               Assert
                 (Shape (Dest) = (2, 257)
                  and then Locate_Region (Dest) = Before,
                  "Region geometry");
               Set_To (Alias, Make_Scalar (17.0));
               Guards (17.0);
               All_Values (Dest, 17.0);
               Set_To (Dest, Make_Scalar (-19.0));
               Guards (-19.0);
               All_Values (Alias, -19.0);
            end;
         end loop;
      end Interior;
      procedure Mismatch (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for Mode in 1 .. 3 loop
            declare
               Old    : constant Mat_Type :=
                 (if Mode = 2
                  then (Int16, 1)
                  elsif Mode = 3
                  then (Float32, 2)
                  else (Float32, 1));
               A      : Image := New_Image (2, 257, (Float32, 1));
               B      : Image := New_Image (2, 257, (Float32, 1));
               Parent : Image := New_Image (5, 260, Old);
               Width  : constant Size_Coordinate :=
                 (if Mode = 1 then 256 else 257);
               Dest   : Image := Region (Parent, (1, 1, Width, 2));
               Alias  : Image := Dest;
               Before : constant Region_Location := Locate_Region (Alias);
            begin
               Set_To (A, Make_Scalar (-21.0));
               Set_To (B, Make_Scalar (2.0));
               Set_To (Parent, Make_Scalar (91.0, 91.0));
               Into (A, B, Dest);
               Assert
                 (Shape (Dest) = (2, 257)
                  and then Depth (Dest) = Float32
                  and then Channels (Dest) = 1,
                  "operand output layout");
               All_Values (Dest, Select_Value (-21.0, 2.0, Op));
               All_Values (Parent, 91.0);
               All_Values (Alias, 91.0);
               Assert (Locate_Region (Alias) = Before, "old alias attached");
               Set_To (Dest, Make_Scalar (27.0));
               All_Values (Parent, 91.0);
               Set_To (Alias, Make_Scalar (31.0, 31.0));
               All_Values (Dest, 27.0);
               declare
                  H : constant Mat := Observe (Parent).Convert_To (Float64);
               begin
                  for Ch in 0 .. Natural (H.Channels) - 1 loop
                     declare
                        V : constant Mat := H.Extract_Channel (Ch);
                     begin
                        for R in 0 .. 4 loop
                           for C in 0 .. 259 loop
                              Check
                                (Long_Float (Float64_Access.Get (V, R, C)),
                                 (if R in 1 .. 2
                                    and then C in 1 .. Natural (Width)
                                  then 31.0
                                  else 91.0));
                           end loop;
                        end loop;
                     end;
                  end loop;
               end;
            end;
         end loop;
      end Mismatch;
      procedure Aliases (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depths'(UInt8, Int16, Int32, Float32, Float64, Float16) loop
            for Mode in 1 .. 7 loop
               declare
                  A    : Image := Vector (D, True);
                  B    : Image := Vector (D, False);
                  Dest : Image;
                  E    : constant Image :=
                    Fresh (A, (if Mode >= 5 then A else B));
               begin
                  case Mode is
                     when 1      =>
                        Into (A, B, A);
                        Dest := A;

                     when 2      =>
                        Into (A, B, B);
                        Dest := B;

                     when 5      =>
                        Into (A, A, Dest);

                     when 6      =>
                        Into (A, A, A);
                        Dest := A;

                     when others =>
                        Dest := (if Mode = 4 then B else A);
                        Into (A, (if Mode = 7 then A else B), Dest);
                  end case;
                  Equal (Observe (Dest), Observe (E));
                  declare
                     H : constant Mat := Observe (Dest);
                     V : constant Mat :=
                       (if D = Int32 then H else H.Convert_To (Float64));
                  begin
                     for C in 0 .. 256 loop
                        declare
                           Expected : constant Long_Float :=
                             (if Mode >= 5
                              then Input (C, D, True)
                              else
                                Select_Value
                                  (Input (C, D, True),
                                   Input (C, D, False),
                                   Op));
                        begin
                           if D = Int32 then
                              Assert
                                (Int32_Access.Get (V, 0, C)
                                 = Int32_Value (Expected),
                                 "exact Int32 mathematical alias result");
                           else
                              Check
                                (Long_Float (Float64_Access.Get (V, 0, C)),
                                 Expected);
                           end if;
                        end;
                     end loop;
                  end;
               end;
            end loop;
         end loop;
      end Aliases;
      procedure Numbers (Test : in out Fixture) is
         pragma Unreferenced (Test);
         type Triple is array (0 .. 2) of Long_Float;
         procedure Verify_Int32
           (Self : Image; Values : Int32_Vec3.Vector; Context : String)
         is
            H : constant Mat := Observe (Self);
         begin
            Assert
              (H.Shape = Dimension_Array'(2, 257)
               and then H.Depth = Int32
               and then H.Channels = 3,
               Context & " C3 layout");
            --  Inspect storage directly: Int32 -> Float64 on NEON can
            --  round INT_MAX through a Float32 intermediate.
            for Row in 0 .. 1 loop
               for C in 0 .. 256 loop
                  Assert
                    (Int32_Vec3_Access.Get (H, Row, C) = Values,
                     Context & " row=" & Row'Image & " column=" & C'Image);
               end loop;
            end loop;
         end Verify_Int32;
      begin
         for D of Depths'(UInt8, Int16, Int32, Float32, Float64, Float16) loop
            declare
               L     : constant Triple :=
                 (if D = UInt8
                  then (1.0, 8.0, 3.0)
                  elsif D = Int16
                  then (-32768.0, 32767.0, -7.0)
                  elsif D = Int32
                  then (-2147483648.0, 2147483647.0, -7.0)
                  elsif D = Float16
                  then (-65504.0, 65504.0, -1.0)
                  else (-3.5, 4.0, -1.0));
               R     : constant Triple :=
                 (if D = UInt8
                  then (4.0, 5.0, 6.0)
                  elsif D in Int16 | Int32
                  then (9.0, -9.0, 12.0)
                  else (-2.0, -5.0, 2.0));
               A     : Image := New_Image (2, 257, (D, 3));
               B     : Image := New_Image (2, 257, (D, 3));
               Dest  : Image := New_Image (2, 257, (D, 3));
               Alias : constant Image := Dest;
            begin
               Set_To (A, Make_Scalar (L (0), L (1), L (2)));
               Set_To (B, Make_Scalar (R (0), R (1), R (2)));
               if D = Int32 then
                  Verify_Int32
                    (A,
                     (Int32_Value'First, Int32_Value'Last, -7),
                     "stored Left before " & Op'Image);
                  Verify_Int32
                    (B, (9, -9, 12), "stored Right before " & Op'Image);
               end if;
               Into (A, B, Dest);
               declare
                  E : constant Image := Fresh (A, B);
               begin
                  Equal (Observe (Dest), Observe (E));
                  Equal (Observe (Alias), Observe (E));
                  if D = Int32 then
                     declare
                        Left     : constant Int32_Vec3.Vector :=
                          (Int32_Value'First, Int32_Value'Last, -7);
                        Right    : constant Int32_Vec3.Vector := (9, -9, 12);
                        Expected : Int32_Vec3.Vector;
                     begin
                        for Ch in Expected'Range loop
                           Expected (Ch) :=
                             (if Op = Minimum_Operation
                              then Int32_Value'Min (Left (Ch), Right (Ch))
                              else Int32_Value'Max (Left (Ch), Right (Ch)));
                        end loop;
                        Verify_Int32 (E, Expected, "function " & Op'Image);
                        Verify_Int32
                          (Dest, Expected, "destination " & Op'Image);
                        Verify_Int32
                          (Alias, Expected, "retained alias " & Op'Image);
                     end;
                  else
                     declare
                        H : constant Mat :=
                          Observe (Alias).Convert_To (Float64);
                     begin
                        for Ch in 0 .. 2 loop
                           declare
                              V : constant Mat := H.Extract_Channel (Ch);
                           begin
                              for Row in 0 .. 1 loop
                                 for C in 0 .. 256 loop
                                    Check
                                      (Long_Float
                                         (Float64_Access.Get (V, Row, C)),
                                       Select_Value (L (Ch), R (Ch), Op));
                                 end loop;
                              end loop;
                           end;
                        end loop;
                     end;
                  end if;
               end;
            end;
         end loop;
      end Numbers;
      procedure Specials (Test : in out Fixture) is
         pragma Unreferenced (Test);
         X : Mat := Create (1, 257, (Float64, 1));
         Z : Mat := Create (1, 257, (Float64, 1));
      begin
         --  Native Divide constructs specials without Ada nonfinite narrowing.
         for C in 0 .. 256 loop
            Float64_Access.Set
              (X,
               0,
               C,
               (case C mod 3 is
                  when 0      => 0.0,
                  when 1      => 1.0,
                  when others => -1.0));
         end loop;
         Z.Set_To (Make_Scalar (0.0));
         declare
            N : constant Mat := Divide (X, Z);
         begin
            for D of Depths'(Float32, Float64, Float16) loop
               for Ch of Channel_List'(1, 3) loop
                  for Pair in 0 .. 10 loop
                     for Mode in 0 .. 7 loop
                        declare
                           AH : Mat := Create (1, 257, (Float64, 1));
                           BH : Mat := Create (1, 257, (Float64, 1));
                        begin
                           AH.Set_To (Make_Scalar (3.0));
                           BH.Set_To (Make_Scalar (3.0));
                           for C in 0 .. 256 loop
                              if Pair in 0 | 2 | 4 | 6 | 7 | 8 then
                                 Raw_ABI.Copy_Special
                                   (N,
                                    (case Pair is
                                       when 2 | 7  => 1,
                                       when 4 | 8  => 2,
                                       when others => 0),
                                    AH,
                                    C);
                              end if;
                              if Pair in 1 | 3 | 5 | 6 | 7 | 8 then
                                 Raw_ABI.Copy_Special
                                   (N,
                                    (case Pair is
                                       when 3 | 7  => 1,
                                       when 5 | 8  => 2,
                                       when others => 0),
                                    BH,
                                    C);
                              end if;
                              if Pair >= 9 then
                                 Float64_Access.Set
                                   (AH,
                                    0,
                                    C,
                                    (if Pair = 9 then 0.0 else -0.0));
                                 Float64_Access.Set
                                   (BH,
                                    0,
                                    C,
                                    (if Pair = 9 then -0.0 else 0.0));
                              end if;
                           end loop;
                           if Ch = 3 then
                              AH := Merge (Mat_Array'(AH, AH, AH));
                              BH := Merge (Mat_Array'(BH, BH, BH));
                           end if;
                           AH := AH.Convert_To (D);
                           BH := BH.Convert_To (D);
                           declare
                              A    : Image := From_Mat (AH);
                              B    : Image := From_Mat (BH);
                              Dest : Image := New_Image (1, 257, (D, Ch));
                              E    : constant Mat :=
                                (if Mode in 0 | 5
                                 then
                                   Observe
                                     (Fresh (A, (if Mode = 5 then A else B)))
                                 else
                                   Raw_ABI.Native_Expected
                                     (AH,
                                      (if Mode >= 6 then AH else BH),
                                      Op,
                                      Mode in 2 | 4,
                                      Is_UMat));
                           begin
                              case Mode is
                                 when 0      =>
                                    Into (A, B, Dest);

                                 when 1      =>
                                    Into (A, B, A);
                                    Dest := A;

                                 when 2      =>
                                    Into (A, B, B);
                                    Dest := B;

                                 when 5      =>
                                    Into (A, A, Dest);

                                 when 6      =>
                                    Into (A, A, A);
                                    Dest := A;

                                 when others =>
                                    Dest := (if Mode = 4 then B else A);
                                    Into
                                      (A, (if Mode = 7 then A else B), Dest);
                              end case;
                              Equal (Observe (Dest), E);
                              --  Infinity and equal-input classification are
                              --  portable; NaN/finite and zero-sign follow the
                              --  native oracle's actual backend/alias/tail.
                              if Pair in 2 .. 8 then
                                 declare
                                    H     : constant Mat :=
                                      Observe (Dest).Convert_To (Float64);
                                    Class : F64.Float64_Classification;
                                 begin
                                    Class := F64.Finite;
                                    if Pair = 6 then
                                       Class := F64.Not_A_Number;
                                    elsif Pair = 7 then
                                       Class := F64.Positive_Infinity;
                                    elsif Pair = 8 then
                                       Class := F64.Negative_Infinity;
                                    elsif Pair in 2 | 3 then
                                       if Op = Maximum_Operation then
                                          Class := F64.Positive_Infinity;
                                       end if;
                                    elsif Op = Minimum_Operation then
                                       Class := F64.Negative_Infinity;
                                    end if;
                                    for Channel in 0 .. Natural (Ch) - 1 loop
                                       declare
                                          V : constant Mat :=
                                            H.Extract_Channel (Channel);
                                       begin
                                          for C in 0 .. 256 loop
                                             if Mode < 5 or else Pair >= 6 then
                                                Assert
                                                  (Float64_Access.Classify
                                                     (V, 0, C)
                                                   = Class,
                                                   "portable special class");
                                             end if;
                                          end loop;
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
         end;
      end Specials;
      procedure Empty (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Major : constant Natural := Module_Bridge_Probe.OpenCV_Major_Version;
      begin
         for D of Depths'(UInt8, Float32, Float16) loop
            for Mode in 0 .. 3 loop
               if Mode <= 1 or else D = UInt8 then
                  declare
                     A, B     : Image;
                     Dest     : Image := New_Image (2, 3, (Int16, 2));
                     Alias    : Image := Dest;
                     Released : constant Boolean :=
                       (if Is_UMat
                        then Mode = 0
                        else
                          Mode /= 1 or else (D = Float16 and then Major < 5));
                  begin
                     if Mode in 1 | 3 then
                        A := New_Image (0, 0, (D, 1));
                     end if;
                     if Mode in 1 | 2 then
                        B := New_Image (0, 0, (D, 1));
                     end if;
                     Set_To (Dest, Make_Scalar (91.0, 91.0));
                     declare
                        E : constant Image := Fresh (A, B);
                     begin
                        Into (A, B, Dest);
                        Assert
                          (Is_Empty (Dest) and then Is_Empty (E),
                           "accepted empty function/procedure");
                        Assert
                          (Dimension_Count (Dest)
                           = (if Released and then Major >= 5 then 0 else 2),
                           "version-native empty dimensions");
                        Assert
                          (Shape (Dest)'Length = Dimension_Count (Dest),
                           "empty shape rank");
                        if Dimension_Count (Dest) = 2 then
                           Assert (Shape (Dest) = (0, 0), "empty extents");
                        end if;
                        Assert
                          (Depth (Dest) = (if Released then Int16 else D)
                           and then Channels (Dest)
                                    = (if Released then 2 else 1),
                           "release retains old type, create follows operand");
                        Assert
                          (Depth (E) = (if Released then UInt8 else D)
                           and then Channels (E) = 1,
                           "fresh empty type");
                     end;
                     All_Values (Alias, 91.0);
                     Set_To (Alias, Make_Scalar (31.0, 31.0));
                     All_Values (Alias, 31.0);
                     Assert
                       (Is_Empty (Dest), "old allocation survives release");
                  end;
               end if;
            end loop;
         end loop;
      end Empty;
      procedure Failures (Test : in out Fixture) is
         pragma Unreferenced (Test);
         A      : constant Image := New_Image (2, 3, (Float32, 1));
         Dest   : Image := New_Image (2, 3, (Float32, 1));
         Alias  : constant Image := Dest;
         Volume : constant Image := New_ND ((2, 3, 4), (Float32, 1));
      begin
         Set_To (Dest, Make_Scalar (91.0));
         for Mode in 1 .. 4 loop
            declare
               B : constant Image :=
                 (if Mode = 1
                  then New_Image (1, 3, (Float32, 1))
                  elsif Mode = 2
                  then New_Image (2, 3, (Int16, 1))
                  elsif Mode = 3
                  then New_Image (2, 3, (Float32, 2))
                  else Volume);
               procedure Attempt is
               begin
                  Into ((if Mode = 4 then Volume else A), B, Dest);
               end Attempt;
               procedure Function_Attempt is
                  E : constant Image :=
                    Fresh ((if Mode = 4 then Volume else A), B);
                  pragma Unreferenced (E);
               begin
                  null;
               end Function_Attempt;
            begin
               Assert_Raises_OpenCV_Error (Attempt'Access, "operand policy");
               Assert_Raises_OpenCV_Error
                 (Function_Attempt'Access, "function policy");
               Assert
                 (Shape (Dest) = (2, 3)
                  and then Depth (Dest) = Float32
                  and then Channels (Dest) = 1
                  and then Dimension_Count (Dest) = 2,
                  "pre-native metadata unchanged");
               All_Values (Dest, 91.0);
               All_Values (Alias, 91.0);
            end;
         end loop;
      end Failures;
      procedure Small (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for Layout in 1 .. 3 loop
            for Mode in 0 .. 3 loop
               declare
                  Ch   : constant Channel_Count :=
                    (if Layout = 3 then 4 else 1);
                  W    : constant Natural := (if Layout = 2 then 4 else 1);
                  A    : Image := New_Image (1, W, (Float32, Ch));
                  B    : Image := New_Image (1, W, (Float32, Ch));
                  Dest : Image := New_Image (1, W, (Int16, Ch));
               begin
                  Set_To (A, Make_Scalar (10.0, 20.0, 30.0, 40.0));
                  Set_To (B, Make_Scalar (50.0, 60.0, 70.0, 80.0));
                  declare
                     E : constant Image := Fresh (A, B);
                  begin
                     case Mode is
                        when 0      =>
                           Dest := New_Image (1, W, (Float32, Ch));
                           Into (A, B, Dest);

                        when 2      =>
                           Into (A, B, A);
                           Dest := A;

                        when 3      =>
                           Into (A, B, B);
                           Dest := B;

                        when others =>
                           Into (A, B, Dest);
                     end case;
                     Equal (Observe (Dest), Observe (E));
                  end;
               end;
            end loop;
         end loop;
      end Small;
      procedure CPU (Test : in out Fixture) is
         procedure Run is
         begin
            Whole (Test);
            Interior (Test);
            Mismatch (Test);
            Aliases (Test);
            Numbers (Test);
            Specials (Test);
            Empty (Test);
            Small (Test);
         end Run;
      begin
         Raw_ABI.With_OpenCL_Disabled (Run'Access);
      end CPU;
   end Cases;

   package Mat_Min is new
     Cases
       (Mat,
        Identity,
        Identity,
        Create,
        Create,
        Op      => Minimum_Operation,
        Is_UMat => False);
   package Mat_Max is new
     Cases
       (Mat,
        Identity,
        Identity,
        Create,
        Create,
        Op      => Maximum_Operation,
        Is_UMat => False);
   package UMat_Min is new
     Cases
       (UMat,
        Transfers.To_UMat,
        Transfers.To_Mat,
        Create_UMat,
        Create_UMat,
        Op      => Minimum_Operation,
        Is_UMat => True);
   package UMat_Max is new
     Cases
       (UMat,
        Transfers.To_UMat,
        Transfers.To_Mat,
        Create_UMat,
        Create_UMat,
        Op      => Maximum_Operation,
        Is_UMat => True);

   procedure Temporary (View : in out Mat) is
      Before : constant Dimension_Array := View.Shape;
      Source : Mat := Create (View.Rows, View.Columns, (UInt8, 1));
      Other  : Mat := Create (1, 2, (Float32, 1));
      Dest   : Mat;
      procedure Unchanged is
      begin
         Assert
           (View.Shape = Before
            and then View.Dimension_Count = 2
            and then View.Depth = UInt8
            and then View.Channels = 1,
            "temporary metadata unchanged");
         for R in 0 .. View.Rows - 1 loop
            for C in 0 .. View.Columns - 1 loop
               Assert (UInt8_Access.Get (View, R, C) = 37, "temporary pixels");
            end loop;
         end loop;
      end Unchanged;
   begin
      Source.Set_To (Make_Scalar (74.0));
      for Op in Operation_Kind loop
         for Mismatch in Boolean loop
            declare
               procedure Attempt is
               begin
                  if Op = Minimum_Operation then
                     Minimum
                       ((if Mismatch then Other else Source),
                        (if Mismatch then Other else Source),
                        View);
                  else
                     Maximum
                       ((if Mismatch then Other else Source),
                        (if Mismatch then Other else Source),
                        View);
                  end if;
               end Attempt;
            begin
               Assert_Raises_OpenCV_Error (Attempt'Access, "temporary output");
               Unchanged;
            end;
         end loop;
         for Left_View in Boolean loop
            if Op = Minimum_Operation then
               Minimum
                 ((if Left_View then View else Source),
                  (if Left_View then Source else View),
                  Dest);
            else
               Maximum
                 ((if Left_View then View else Source),
                  (if Left_View then Source else View),
                  Dest);
            end if;
            for R in 0 .. View.Rows - 1 loop
               for C in 0 .. View.Columns - 1 loop
                  Assert
                    (UInt8_Access.Get (Dest, R, C)
                     = (if Op = Minimum_Operation then 37 else 74),
                     "temporary source");
                  Assert
                    (UInt8_Access.Get (Source, R, C) = 74, "source unchanged");
               end loop;
            end loop;
            Dest.Set_To (Make_Scalar (99.0));
            Unchanged;
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
        (Data, 4, 3, 5, Temporary'Access);
      Assert (Data = Before, "external pixels/padding");
   end External;
   procedure Selected (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Volume : Mat := Create (Dimension_Array'(2, 3, 4), (UInt8, 1));
   begin
      Volume.Set_To (Make_Scalar (37.0));
      Volume.With_Selected_View
        (((Kind => Fix_Index, Index => 1),
          (Kind => Keep_Range, Bounds => (0, 3)),
          (Kind => Keep_Range, Bounds => (0, 4))),
         Temporary'Access);
      for A in Size_Coordinate range 0 .. 1 loop
         for B in Size_Coordinate range 0 .. 2 loop
            for C in Size_Coordinate range 0 .. 3 loop
               Assert
                 (UInt8_Access.Get (Volume, Index_Array'(A, B, C)) = 37,
                  "selected parent unchanged");
            end loop;
         end loop;
      end loop;
   end Selected;
   procedure Register
     (Prefix : String;
      Whole,
      Interior,
      Mismatch,
      Aliases,
      Numbers,
      Specials,
      Empty,
      Failures,
      Small,
      CPU    : Caller.Test_Method) is
   begin
      Result.Add_Test (Caller.Create (Prefix & "whole reuse", Whole));
      Result.Add_Test (Caller.Create (Prefix & "Region reuse", Interior));
      Result.Add_Test
        (Caller.Create (Prefix & "mismatch detachment", Mismatch));
      Result.Add_Test
        (Caller.Create (Prefix & "Left/Right/shallow/A-A 257", Aliases));
      Result.Add_Test
        (Caller.Create (Prefix & "integer extrema/finite C3", Numbers));
      Result.Add_Test
        (Caller.Create (Prefix & "specials/order/alias/tail", Specials));
      Result.Add_Test (Caller.Create (Prefix & "empty parity", Empty));
      Result.Add_Test (Caller.Create (Prefix & "failures/N-D", Failures));
      Result.Add_Test (Caller.Create (Prefix & "scalar-like arrays", Small));
      Result.Add_Test (Caller.Create (Prefix & "OpenCL disabled", CPU));
   end Register;
   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Register
        ("Minimum destination Mat ",
         Mat_Min.Whole'Access,
         Mat_Min.Interior'Access,
         Mat_Min.Mismatch'Access,
         Mat_Min.Aliases'Access,
         Mat_Min.Numbers'Access,
         Mat_Min.Specials'Access,
         Mat_Min.Empty'Access,
         Mat_Min.Failures'Access,
         Mat_Min.Small'Access,
         Mat_Min.CPU'Access);
      Register
        ("Maximum destination Mat ",
         Mat_Max.Whole'Access,
         Mat_Max.Interior'Access,
         Mat_Max.Mismatch'Access,
         Mat_Max.Aliases'Access,
         Mat_Max.Numbers'Access,
         Mat_Max.Specials'Access,
         Mat_Max.Empty'Access,
         Mat_Max.Failures'Access,
         Mat_Max.Small'Access,
         Mat_Max.CPU'Access);
      Register
        ("Minimum destination UMat ",
         UMat_Min.Whole'Access,
         UMat_Min.Interior'Access,
         UMat_Min.Mismatch'Access,
         UMat_Min.Aliases'Access,
         UMat_Min.Numbers'Access,
         UMat_Min.Specials'Access,
         UMat_Min.Empty'Access,
         UMat_Min.Failures'Access,
         UMat_Min.Small'Access,
         UMat_Min.CPU'Access);
      Register
        ("Maximum destination UMat ",
         UMat_Max.Whole'Access,
         UMat_Max.Interior'Access,
         UMat_Max.Mismatch'Access,
         UMat_Max.Aliases'Access,
         UMat_Max.Numbers'Access,
         UMat_Max.Specials'Access,
         UMat_Max.Empty'Access,
         UMat_Max.Failures'Access,
         UMat_Max.Small'Access,
         UMat_Max.CPU'Access);
      Result.Add_Test
        (Caller.Create ("Min/max external temporary", External'Access));
      Result.Add_Test
        (Caller.Create ("Min/max selected temporary", Selected'Access));
      Result.Add_Test
        (Caller.Create ("Min/max raw Mat", Raw_ABI.Mat_Check'Access));
      Result.Add_Test
        (Caller.Create ("Min/max raw UMat", Raw_ABI.UMat_Check'Access));
      return Result'Access;
   end Suite;
end Min_Max_Destination_Tests;
