with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;
with Abs_Diff_Destination_Tests.Raw_ABI;

package body Abs_Diff_Destination_Tests is
   use OpenCV;
   use OpenCV.Core;
   use Mat_Test_Support;
   use AUnit.Assertions;
   use type UInt8_Value;
   use type Float64_Value;
   use type Float64_Access.Float64_Classification;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   type Depths is array (Positive range <>) of Depth_Type;
   type Channel_Count_Array is array (Positive range <>) of Channel_Count;

   function Identity (Self : Mat) return Mat
   is (Self);

   procedure Check (Actual, Expected : Long_Float) is
   begin
      Assert (Approximately_Equal (Actual, Expected), "every absdiff pixel");
   end Check;

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
        procedure Abs_Diff (Left, Right : Image; Destination : in out Image)
        is <>;
      with function Abs_Diff (Left, Right : Image) return Image is <>;
      with function Region (Self : Image; Area : Rect) return Image is <>;
      with procedure Set_To (Self : in out Image; Value : Scalar) is <>;
      with function Shape (Self : Image) return Dimension_Array is <>;
      with function Depth (Self : Image) return Depth_Type is <>;
      with function Channels (Self : Image) return Channel_Count is <>;
      with function Dimension_Count (Self : Image) return Natural is <>;
      with function Is_Empty (Self : Image) return Boolean is <>;
      with function Locate_Region (Self : Image) return Region_Location is <>;
      Is_UMat : Boolean;
   package Cases is
      procedure Whole (Test : in out Fixture);
      procedure Interior (Test : in out Fixture);
      procedure Reallocate (Test : in out Fixture);
      procedure Into_Left (Test : in out Fixture);
      procedure Into_Right (Test : in out Fixture);
      procedure Shallow (Test : in out Fixture);
      procedure Same_Operands (Test : in out Fixture);
      procedure Numbers (Test : in out Fixture);
      procedure Specials (Test : in out Fixture);
      procedure Empty (Test : in out Fixture);
      procedure Failures (Test : in out Fixture);
      procedure Small (Test : in out Fixture);
   end Cases;

   package body Cases is
      function Values (Self : Image; Channel : Natural := 0) return Mat is
         Host : constant Mat := Observe (Self).Convert_To (Float64);
      begin
         if Host.Channels = 1 then
            return Host;
         else
            return Host.Extract_Channel (Channel);
         end if;
      end Values;

      procedure All_Values (Self : Image; Expected : Long_Float) is
      begin
         for Ch in 0 .. Natural (Channels (Self)) - 1 loop
            declare
               V : constant Mat := Values (Self, Ch);
            begin
               for R in 0 .. V.Rows - 1 loop
                  for Col in 0 .. V.Columns - 1 loop
                     Check
                       (Long_Float (Float64_Access.Get (V, R, Col)), Expected);
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

      function Difference (Col : Natural; D : Depth_Type) return Long_Float
      is (abs (Input (Col, D, True) - Input (Col, D, False)));

      function Vector (D : Depth_Type; Left : Boolean) return Image is
         Host : Mat := Create (1, 257, (Float64, 1));
      begin
         for Col in 0 .. 256 loop
            Float64_Access.Set
              (Host, 0, Col, Float64_Value (Input (Col, D, Left)));
         end loop;
         return From_Mat (Host.Convert_To (D));
      end Vector;

      procedure Equal (Actual, Expected : Image) is
      begin
         Assert
           (Shape (Actual) = Shape (Expected)
            and then Depth (Actual) = Depth (Expected)
            and then Channels (Actual) = Channels (Expected),
            "procedure/function shape/type parity");
         for Ch in 0 .. Natural (Channels (Actual)) - 1 loop
            declare
               A : constant Mat := Values (Actual, Ch);
               E : constant Mat := Values (Expected, Ch);
            begin
               for R in 0 .. A.Rows - 1 loop
                  for Col in 0 .. A.Columns - 1 loop
                     Assert
                       (Float64_Access.Classify (A, R, Col)
                        = Float64_Access.Classify (E, R, Col),
                        "function/procedure classification parity");
                     if Float64_Access.Classify (A, R, Col)
                       = Float64_Access.Finite
                     then
                        Check
                          (Long_Float (Float64_Access.Get (A, R, Col)),
                           Long_Float (Float64_Access.Get (E, R, Col)));
                     end if;
                  end loop;
               end loop;
            end;
         end loop;
      end Equal;

      procedure Whole (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depths'(UInt8, Int16, Float32, Float64, Float16) loop
            declare
               A           : Image := Vector (D, True);
               B           : constant Image := Vector (D, False);
               Destination : Image := New_Image (1, 257, (D, 1));
               Alias       : Image := Destination;
               Expected    : constant Image := Abs_Diff (A, B);
            begin
               Abs_Diff (A, B, Destination);
               Equal (Destination, Expected);
               Equal (Alias, Expected);
               Set_To (Alias, Make_Scalar (17.0));
               All_Values (Destination, 17.0);
               Set_To (Destination, Make_Scalar (19.0));
               All_Values (Alias, 19.0);
               Set_To (A, Make_Scalar (29.0));
               declare
                  V : constant Mat := Values (Expected);
               begin
                  for Col in 0 .. 256 loop
                     Check
                       (Long_Float (Float64_Access.Get (V, 0, Col)),
                        Difference (Col, D));
                  end loop;
               end;
            end;
         end loop;
      end Whole;

      procedure Interior (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depths'(Float32, Float64, Float16) loop
            declare
               A           : Image := New_Image (2, 257, (D, 1));
               B           : Image := New_Image (2, 257, (D, 1));
               Parent      : Image := New_Image (5, 260, (D, 1));
               Destination : Image := Region (Parent, (1, 1, 257, 2));
               Alias       : Image := Destination;
               Before      : constant Region_Location :=
                 Locate_Region (Destination);
               procedure Guards (Inside : Long_Float) is
                  V : constant Mat := Values (Parent);
               begin
                  for R in 0 .. 4 loop
                     for Col in 0 .. 259 loop
                        Check
                          (Long_Float (Float64_Access.Get (V, R, Col)),
                           (if R in 1 .. 2 and then Col in 1 .. 257
                            then Inside
                            else 91.0));
                     end loop;
                  end loop;
               end Guards;
            begin
               Set_To (A, Make_Scalar (-21.0));
               Set_To (B, Make_Scalar (2.0));
               Set_To (Parent, Make_Scalar (91.0));
               Abs_Diff (A, B, Destination);
               All_Values (Destination, 23.0);
               All_Values (Alias, 23.0);
               Assert
                 (Locate_Region (Destination) = Before
                  and then Shape (Destination) = (2, 257),
                  "Region parent geometry retained");
               Guards (23.0);
               Set_To (Alias, Make_Scalar (17.0));
               Guards (17.0);
               All_Values (Destination, 17.0);
               Set_To (Destination, Make_Scalar (-19.0));
               Guards (-19.0);
               All_Values (Alias, -19.0);
            end;
         end loop;
      end Interior;

      procedure Reallocate (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for Mode in 1 .. 3 loop
            declare
               Old_Type    : constant Mat_Type :=
                 (if Mode = 2
                  then (Int16, 1)
                  elsif Mode = 3
                  then (Float32, 2)
                  else (Float32, 1));
               A           : Image := New_Image (2, 257, (Float32, 1));
               B           : Image := New_Image (2, 257, (Float32, 1));
               Parent      : Image := New_Image (5, 260, Old_Type);
               Width       : constant Natural :=
                 (if Mode = 1 then 256 else 257);
               Destination : Image :=
                 Region (Parent, (1, 1, Size_Coordinate (Width), 2));
               Alias       : Image := Destination;
               Old_Shape   : constant Dimension_Array := Shape (Alias);
            begin
               Set_To (A, Make_Scalar (-21.0));
               Set_To (B, Make_Scalar (2.0));
               Set_To (Parent, Make_Scalar (91.0, 91.0));
               Abs_Diff (A, B, Destination);
               Assert
                 (Shape (Destination) = (2, 257)
                  and then Depth (Destination) = Float32
                  and then Channels (Destination) = 1,
                  "native output creation follows operands, not destination");
               All_Values (Destination, 23.0);
               All_Values (Parent, 91.0);
               All_Values (Alias, 91.0);
               Assert (Shape (Alias) = Old_Shape, "old alias geometry");
               Set_To (Destination, Make_Scalar (27.0));
               All_Values (Parent, 91.0);
               Set_To (Alias, Make_Scalar (31.0, 31.0));
               All_Values (Destination, 27.0);
               for Ch in 0 .. Natural (Channels (Parent)) - 1 loop
                  declare
                     V : constant Mat := Values (Parent, Ch);
                  begin
                     for R in 0 .. 4 loop
                        for Col in 0 .. 259 loop
                           Check
                             (Long_Float (Float64_Access.Get (V, R, Col)),
                              (if R in 1 .. 2 and then Col in 1 .. Width
                               then 31.0
                               else 91.0));
                        end loop;
                     end loop;
                  end;
               end loop;
            end;
         end loop;
      end Reallocate;

      procedure Aliases (Mode : Positive) is
      begin
         for D of Depths'(UInt8, Int16, Int32, Float32, Float64, Float16) loop
            declare
               A           : Image := Vector (D, True);
               B           : Image := Vector (D, False);
               Destination : Image;
               Expected    : constant Image :=
                 (if Mode >= 5 then Abs_Diff (A, A) else Abs_Diff (A, B));
            begin
               case Mode is
                  when 1      =>
                     Abs_Diff (A, B, A);
                     Destination := A;

                  when 2      =>
                     Abs_Diff (A, B, B);
                     Destination := B;

                  when 5      =>
                     Abs_Diff (A, A, Destination);

                  when 6      =>
                     Abs_Diff (A, A, A);
                     Destination := A;

                  when others =>
                     Destination := (if Mode = 4 then B else A);
                     Abs_Diff (A, (if Mode = 7 then A else B), Destination);
                     Equal ((if Mode = 4 then B else A), Expected);
               end case;
               Equal (Destination, Expected);
               declare
                  V : constant Mat := Values (Destination);
               begin
                  for Col in 0 .. 256 loop
                     Check
                       (Long_Float (Float64_Access.Get (V, 0, Col)),
                        (if Mode >= 5 then 0.0 else Difference (Col, D)));
                  end loop;
               end;
            end;
         end loop;
      end Aliases;

      procedure Into_Left (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         Aliases (1);
      end Into_Left;
      procedure Into_Right (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         Aliases (2);
      end Into_Right;
      procedure Shallow (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         Aliases (3);
         Aliases (4);
      end Shallow;
      procedure Same_Operands (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         Aliases (5);
         Aliases (6);
         Aliases (7);
      end Same_Operands;

      procedure Numbers (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depths'(UInt8, Int16, Int32) loop
            for Ch of Channel_Count_Array'(1, 3) loop
               declare
                  A           : Image := New_Image (2, 257, (D, Ch));
                  B           : Image := New_Image (2, 257, (D, Ch));
                  Destination : Image := New_Image (2, 257, (D, Ch));
                  Alias       : constant Image := Destination;
               begin
                  Set_To
                    (A,
                     (if D = UInt8
                      then Make_Scalar (10.0, 250.0, 50.0)
                      else Make_Scalar (-32768.0, -7.0, 50.0)));
                  Set_To
                    (B,
                     (if D = UInt8
                      then Make_Scalar (200.0, 20.0, 80.0)
                      else Make_Scalar (0.0, 9.0, -80.0)));
                  Abs_Diff (A, B, Destination);
                  for C in 0 .. Natural (Ch) - 1 loop
                     declare
                        V : constant Mat := Values (Alias, C);
                        E : constant Long_Float :=
                          (if D = UInt8
                           then
                             (case C is
                                when 0      => 190.0,
                                when 1      => 230.0,
                                when others => 30.0)
                           elsif C = 0
                           then (if D = Int16 then 32767.0 else 32768.0)
                           elsif C = 1
                           then 16.0
                           else 130.0);
                     begin
                        for R in 0 .. 1 loop
                           for Col in 0 .. 256 loop
                              Check
                                (Long_Float (Float64_Access.Get (V, R, Col)),
                                 E);
                           end loop;
                        end loop;
                     end;
                  end loop;
               end;
            end loop;
         end loop;
      end Numbers;

      procedure Specials (Test : in out Fixture) is
         pragma Unreferenced (Test);
         --  Produce nonfinite sources using the public native Divide API,
         --  never by narrowing nonfinite values into Ada numeric subtypes.
         X : Mat := Create (1, 257, (Float64, 1));
         Z : Mat := Create (1, 257, (Float64, 1));
      begin
         for Col in 0 .. 256 loop
            Float64_Access.Set
              (X,
               0,
               Col,
               (case Col mod 8 is
                  when 0 | 2  => 1.0,
                  when 1 | 3  => -1.0,
                  when others => 0.0));
         end loop;
         Z.Set_To (Make_Scalar (0.0));
         declare
            Nonfinite : constant Mat := Divide (X, Z);
         begin
            for D of Depths'(Float32, Float64, Float16) loop
               for Mode in 0 .. 3 loop
                  declare
                     AH : Mat := X.Clone;
                     BH : Mat := Z.Clone;
                  begin
                     for Col in 0 .. 256 loop
                        if Mode > 0 then
                           Raw_ABI.Copy_Special (Nonfinite, Col, AH, Col);
                           Raw_ABI.Copy_Special (Nonfinite, Col, BH, Col);
                        elsif Col mod 8 <= 1 then
                           Raw_ABI.Copy_Special (Nonfinite, Col, BH, Col);
                        elsif Col mod 8 <= 3 then
                           Raw_ABI.Copy_Special (Nonfinite, Col, AH, Col);
                           Raw_ABI.Copy_Special (Nonfinite, Col, BH, Col);
                        elsif Col mod 8 = 4 then
                           Raw_ABI.Copy_Special (Nonfinite, Col, AH, Col);
                        elsif Col mod 8 = 5 then
                           Raw_ABI.Copy_Special (Nonfinite, Col, BH, Col);
                        else
                           Float64_Access.Set
                             (AH,
                              0,
                              Col,
                              (if Col mod 8 = 6 then 0.0 else -0.0));
                           Float64_Access.Set
                             (BH,
                              0,
                              Col,
                              (if Col mod 8 = 6 then -0.0 else 0.0));
                        end if;
                     end loop;
                     declare
                        A           : Image := From_Mat (AH.Convert_To (D));
                        B           : constant Image :=
                          From_Mat (BH.Convert_To (D));
                        Destination : Image := New_Image (1, 257, (D, 1));
                        Expected    : constant Image := Abs_Diff (A, B);
                     begin
                        case Mode is
                           when 1      =>
                              Abs_Diff (A, A, Destination);

                           when 2      =>
                              Abs_Diff (A, A, A);
                              Destination := A;

                           when 3      =>
                              Destination := A;
                              Abs_Diff (A, A, Destination);

                           when others =>
                              Abs_Diff (A, B, Destination);
                        end case;
                        Equal (Destination, Expected);
                        declare
                           V : constant Mat := Values (Destination);
                        begin
                           for Col in 0 .. 256 loop
                              Assert
                                (Float64_Access.Classify (V, 0, Col)
                                 = (if Mode > 0 or else Col mod 8 in 2 .. 5
                                    then Float64_Access.Not_A_Number
                                    elsif Col mod 8 <= 1
                                    then Float64_Access.Positive_Infinity
                                    else Float64_Access.Finite),
                                 "native infinity/NaN/zero classification");
                              if Mode = 0 and then Col mod 8 >= 6 then
                                 Check
                                   (Long_Float
                                      (Float64_Access.Get (V, 0, Col)),
                                    0.0);
                                 Assert
                                   (not Raw_ABI.Negative_Zero (V, Col),
                                    "native absdiff produces positive zero");
                              end if;
                           end loop;
                        end;
                     end;
                  end;
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
                     A, B        : Image;
                     Destination : Image := New_Image (2, 3, (Int16, 2));
                     Alias       : Image := Destination;
                     Released    : constant Boolean :=
                       (if Is_UMat
                        then Mode = 0
                        else
                          Mode in 0 | 2
                          or else Major >= 5
                          or else D = Float16);
                     Expected    : Image;
                  begin
                     if Mode in 1 | 3 then
                        A := New_Image (0, 0, (D, 1));
                     end if;
                     if Mode in 1 | 2 then
                        B := New_Image (0, 0, (D, 1));
                     end if;
                     Set_To (Destination, Make_Scalar (91.0, 91.0));
                     Expected := Abs_Diff (A, B);
                     Abs_Diff (A, B, Destination);
                     Assert
                       (Is_Empty (Expected) and then Is_Empty (Destination),
                        "accepted empty function/procedure success parity");
                     Assert
                       (Dimension_Count (Destination)
                        = (if Released and then Major >= 5 then 0 else 2)
                        and then Dimension_Count (Destination)
                                 = Shape (Destination)'Length,
                        "version-native empty dimensionality");
                     if Dimension_Count (Destination) = 2 then
                        Assert (Shape (Destination) = (0, 0), "empty shape");
                     end if;
                     Assert
                       (Depth (Destination) = (if Released then Int16 else D)
                        and then Channels (Destination)
                                 = (if Released then 2 else 1),
                        "release retains old type; create uses operand type");
                     if Released then
                        Assert
                          (Dimension_Count (Expected) = 0
                           and then Shape (Expected)'Length = 0
                           and then Depth (Expected) = UInt8
                           and then Channels (Expected) = 1,
                           "independent function empty default metadata");
                     else
                        Assert
                          (Shape (Expected) = Shape (Destination)
                           and then Depth (Expected) = D
                           and then Channels (Expected) = 1,
                           "typed empty function/procedure parity");
                     end if;
                     All_Values (Alias, 91.0);
                     Set_To (Alias, Make_Scalar (31.0, 31.0));
                     All_Values (Alias, 31.0);
                     Assert (Is_Empty (Destination), "old alias survives");
                  end;
               end if;
            end loop;
         end loop;
      end Empty;

      procedure Failures (Test : in out Fixture) is
         pragma Unreferenced (Test);
         A           : Image := New_Image (2, 3, (Float32, 1));
         Destination : Image := New_Image (2, 3, (Float32, 1));
         Alias       : constant Image := Destination;
         Volume      : constant Image := New_ND ((2, 3, 4), (Float32, 1));
      begin
         Set_To (A, Make_Scalar (4.0));
         Set_To (Destination, Make_Scalar (91.0));
         for Mode in 1 .. 5 loop
            declare
               B : constant Image :=
                 (if Mode = 1
                  then New_Image (1, 3, (Float32, 1))
                  elsif Mode = 2
                  then New_Image (2, 4, (Float32, 1))
                  elsif Mode = 3
                  then New_Image (2, 3, (Int16, 1))
                  elsif Mode = 4
                  then New_Image (2, 3, (Float32, 2))
                  else Volume);
               procedure Attempt is
               begin
                  Abs_Diff ((if Mode = 5 then Volume else A), B, Destination);
               end Attempt;
               procedure Function_Attempt is
                  Unused : constant Image :=
                    Abs_Diff ((if Mode = 5 then Volume else A), B);
                  pragma Unreferenced (Unused);
               begin
                  null;
               end Function_Attempt;
            begin
               Assert_Raises_OpenCV_Error (Attempt'Access, "operand policy");
               Assert_Raises_OpenCV_Error
                 (Function_Attempt'Access, "unchanged function policy");
               Assert
                 (Shape (Destination) = (2, 3)
                  and then Dimension_Count (Destination) = 2
                  and then Depth (Destination) = Float32
                  and then Channels (Destination) = 1,
                  "pre-native metadata unchanged");
               All_Values (Destination, 91.0);
               All_Values (Alias, 91.0);
            end;
         end loop;
      end Failures;

      procedure Small (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depths'(UInt8, Int32, Float32, Float64, Float16) loop
            for Layout in 1 .. 3 loop
               for Mode in 0 .. 3 loop
                  declare
                     Ch          : constant Channel_Count :=
                       (if Layout = 3 then 4 else 1);
                     Width       : constant Natural :=
                       (if Layout = 2 then 4 else 1);
                     A           : Image := New_Image (1, Width, (D, Ch));
                     B           : Image := New_Image (1, Width, (D, Ch));
                     Destination : Image :=
                       New_Image
                         (1,
                          Width,
                          (if Mode = 1 then (Int16, Ch) else (D, Ch)));
                  begin
                     Set_To (A, Make_Scalar (10.0, 20.0, 30.0, 40.0));
                     Set_To (B, Make_Scalar (50.0, 60.0, 70.0, 80.0));
                     case Mode is
                        when 2      =>
                           Abs_Diff (A, B, A);
                           Destination := A;

                        when 3      =>
                           Abs_Diff (A, B, B);
                           Destination := B;

                        when others =>
                           Abs_Diff (A, B, Destination);
                     end case;
                     Assert
                       (Shape (Destination) = (1, Size_Coordinate (Width))
                        and then Depth (Destination) = D
                        and then Channels (Destination) = Ch,
                        "scalar-like layouts use operand output type");
                     All_Values (Destination, 40.0);
                  end;
               end loop;
            end loop;
         end loop;
      end Small;
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
      Before      : constant Dimension_Array := View.Shape;
      Source      : Mat := Create (View.Rows, View.Columns, (UInt8, 1));
      Other       : Mat := Create (1, 2, (Float32, 1));
      Destination : Mat;
      procedure Unchanged is
      begin
         Assert
           (View.Shape = Before
            and then View.Dimension_Count = 2
            and then View.Depth = UInt8
            and then View.Channels = 1,
            "temporary metadata unchanged");
         for R in 0 .. View.Rows - 1 loop
            for Col in 0 .. View.Columns - 1 loop
               Assert
                 (UInt8_Access.Get (View, R, Col) = 37,
                  "every temporary pixel unchanged");
            end loop;
         end loop;
      end Unchanged;
   begin
      Source.Set_To (Make_Scalar (74.0));
      Other.Set_To (Make_Scalar (3.0));
      for Mismatch in Boolean loop
         declare
            procedure Attempt is
            begin
               Abs_Diff
                 ((if Mismatch then Other else Source),
                  (if Mismatch then Other else Source),
                  View);
            end Attempt;
         begin
            Unchanged;
            Assert_Raises_OpenCV_Error (Attempt'Access, "temporary output");
            Unchanged;
         end;
      end loop;
      for Left_View in Boolean loop
         Abs_Diff
           ((if Left_View then View else Source),
            (if Left_View then Source else View),
            Destination);
         for R in 0 .. View.Rows - 1 loop
            for Col in 0 .. View.Columns - 1 loop
               Assert
                 (UInt8_Access.Get (Destination, R, Col) = 37,
                  "temporary sources allowed, ordinary output");
               Assert
                 (UInt8_Access.Get (Source, R, Col) = 74,
                  "ordinary source also unchanged");
            end loop;
         end loop;
         Destination.Set_To (Make_Scalar (99.0));
         Unchanged;
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
      Assert (Data = Before, "external pixels and padding unchanged");
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
                  "every selected parent pixel unchanged");
            end loop;
         end loop;
      end loop;
   end Selected;

   procedure UMat_CPU (Test : in out Fixture) is
      procedure Run is
      begin
         UMat_Cases.Whole (Test);
         UMat_Cases.Interior (Test);
         UMat_Cases.Reallocate (Test);
         UMat_Cases.Into_Left (Test);
         UMat_Cases.Into_Right (Test);
         UMat_Cases.Shallow (Test);
         UMat_Cases.Same_Operands (Test);
         UMat_Cases.Numbers (Test);
         UMat_Cases.Specials (Test);
         UMat_Cases.Empty (Test);
         UMat_Cases.Small (Test);
      end Run;
   begin
      Raw_ABI.With_OpenCL_Disabled (Run'Access);
   end UMat_CPU;

   procedure Register
     (Prefix : String;
      Whole,
      Interior,
      Reallocate,
      Into_Left,
      Into_Right,
      Shallow,
      Same_Operands,
      Numbers,
      Specials,
      Empty,
      Failures,
      Small  : Caller.Test_Method) is
   begin
      Result.Add_Test (Caller.Create (Prefix & "whole reuse", Whole));
      Result.Add_Test (Caller.Create (Prefix & "Region reuse", Interior));
      Result.Add_Test
        (Caller.Create (Prefix & "mismatch detachment", Reallocate));
      Result.Add_Test (Caller.Create (Prefix & "into Left 257", Into_Left));
      Result.Add_Test (Caller.Create (Prefix & "into Right 257", Into_Right));
      Result.Add_Test (Caller.Create (Prefix & "shallow aliases", Shallow));
      Result.Add_Test (Caller.Create (Prefix & "A/A finite", Same_Operands));
      Result.Add_Test (Caller.Create (Prefix & "integer/C3", Numbers));
      Result.Add_Test
        (Caller.Create (Prefix & "floating specials/A/A", Specials));
      Result.Add_Test (Caller.Create (Prefix & "empty parity", Empty));
      Result.Add_Test (Caller.Create (Prefix & "failures/N-D", Failures));
      Result.Add_Test (Caller.Create (Prefix & "scalar-like layouts", Small));
   end Register;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Register
        ("Abs_Diff destination Mat ",
         Mat_Cases.Whole'Access,
         Mat_Cases.Interior'Access,
         Mat_Cases.Reallocate'Access,
         Mat_Cases.Into_Left'Access,
         Mat_Cases.Into_Right'Access,
         Mat_Cases.Shallow'Access,
         Mat_Cases.Same_Operands'Access,
         Mat_Cases.Numbers'Access,
         Mat_Cases.Specials'Access,
         Mat_Cases.Empty'Access,
         Mat_Cases.Failures'Access,
         Mat_Cases.Small'Access);
      Register
        ("Abs_Diff destination UMat ",
         UMat_Cases.Whole'Access,
         UMat_Cases.Interior'Access,
         UMat_Cases.Reallocate'Access,
         UMat_Cases.Into_Left'Access,
         UMat_Cases.Into_Right'Access,
         UMat_Cases.Shallow'Access,
         UMat_Cases.Same_Operands'Access,
         UMat_Cases.Numbers'Access,
         UMat_Cases.Specials'Access,
         UMat_Cases.Empty'Access,
         UMat_Cases.Failures'Access,
         UMat_Cases.Small'Access);
      Result.Add_Test
        (Caller.Create ("Abs_Diff external temporary", External'Access));
      Result.Add_Test
        (Caller.Create ("Abs_Diff selected temporary", Selected'Access));
      Result.Add_Test
        (Caller.Create ("Abs_Diff raw Mat", Raw_ABI.Mat_Check'Access));
      Result.Add_Test
        (Caller.Create ("Abs_Diff raw UMat", Raw_ABI.UMat_Check'Access));
      Result.Add_Test
        (Caller.Create ("Abs_Diff UMat CPU fallback", UMat_CPU'Access));
      return Result'Access;
   end Suite;
end Abs_Diff_Destination_Tests;
