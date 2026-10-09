with Ada.Numerics.Long_Elementary_Functions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float64_Mat_View;
with OpenCV.Core.Int32_Access;
with Unary_Math_Destination_Tests.Raw_ABI;

package body Unary_Math_Destination_Tests is
   use OpenCV;
   use OpenCV.Core;
   use AUnit.Assertions;
   use Mat_Test_Support;
   use type Float64_Value;
   use type Int32_Value;
   use type Float64_Access.Float64_Classification;
   package Math renames Ada.Numerics.Long_Elementary_Functions;
   package F renames Float64_Access;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   type Powers is array (Positive range <>) of Long_Float;
   type Channel_List is array (Positive range <>) of Channel_Count;
   function Identity (Self : Mat) return Mat
   is (Self);

   procedure Equal (A, B : Mat) is
      X : constant Mat := A.Convert_To (Float64);
      Y : constant Mat := B.Convert_To (Float64);
   begin
      Assert
        (A.Shape = B.Shape
         and then A.Depth = B.Depth
         and then A.Channels = B.Channels,
         "output metadata");
      for Ch in 0 .. Natural (A.Channels) - 1 loop
         declare
            P : constant Mat := X.Extract_Channel (Ch);
            Q : constant Mat := Y.Extract_Channel (Ch);
         begin
            if A.Dimension_Count = 3 then
               for I in Size_Coordinate range 0 .. 1 loop
                  for J in Size_Coordinate range 0 .. 2 loop
                     for K in Size_Coordinate range 0 .. 4 loop
                        Assert
                          (abs (F.Get (P, (I, J, K)) - F.Get (Q, (I, J, K)))
                           < 0.000_01,
                           "every N-D element");
                     end loop;
                  end loop;
               end loop;
            else
               for R in 0 .. P.Rows - 1 loop
                  for C in 0 .. P.Columns - 1 loop
                     Assert
                       (abs (F.Get (P, R, C) - F.Get (Q, R, C)) < 0.000_01,
                        "every element including tail");
                  end loop;
               end loop;
            end if;
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
      with procedure Sqrt (Self : Image; Destination : in out Image) is <>;
      with procedure Exp (Self : Image; Destination : in out Image) is <>;
      with procedure Log (Self : Image; Destination : in out Image) is <>;
      with
        procedure Pow
          (Self : Image; Power : Long_Float; Destination : in out Image) is <>;
      with function Sqrt (Self : Image) return Image is <>;
      with function Exp (Self : Image) return Image is <>;
      with function Log (Self : Image) return Image is <>;
      with function Pow (Self : Image; Power : Long_Float) return Image is <>;
      with function Region (Self : Image; Area : Rect) return Image is <>;
      with procedure Set_To (Self : in out Image; Value : Scalar) is <>;
      with function Locate_Region (Self : Image) return Region_Location is <>;
      with function Depth (Self : Image) return Depth_Type is <>;
      with function Channels (Self : Image) return Channel_Count is <>;
      with function Shape (Self : Image) return Dimension_Array is <>;
      with function Dimension_Count (Self : Image) return Natural is <>;
      Op : Operation;
   package Cases is
      procedure Whole (Test : in out Fixture);
      procedure Interior (Test : in out Fixture);
      procedure Mismatch (Test : in out Fixture);
      procedure Aliases (Test : in out Fixture);
      procedure ND (Test : in out Fixture);
      procedure Numbers (Test : in out Fixture);
      procedure Empty (Test : in out Fixture);
      procedure Failures (Test : in out Fixture);
      procedure CPU (Test : in out Fixture);
   end Cases;

   package body Cases is
      procedure Into (A : Image; D : in out Image; Power : Long_Float := 2.0)
      is
      begin
         case Op is
            when Square_Root     =>
               Sqrt (A, D);

            when Exponential     =>
               Exp (A, D);

            when Logarithm       =>
               Log (A, D);

            when Power_Operation =>
               Pow (A, Power, D);
         end case;
      end Into;
      function Fresh (A : Image; Power : Long_Float := 2.0) return Image is
      begin
         case Op is
            when Square_Root     =>
               return Sqrt (A);

            when Exponential     =>
               return Exp (A);

            when Logarithm       =>
               return Log (A);

            when Power_Operation =>
               return Pow (A, Power);
         end case;
      end Fresh;
      procedure All_Values (A : Image; Value : Long_Float) is
         H : constant Mat := Observe (A);
         E : Mat := Create (H.Shape, (H.Depth, H.Channels));
      begin
         E.Set_To (Make_Scalar (Value, Value, Value));
         Equal (H, E);
      end All_Values;
      function Source (D : Depth_Type; Ch : Channel_Count) return Image is
         H : constant Mat := Create (2, 257, (Float64, Ch));
      begin
         for R in 0 .. 1 loop
            for C in 0 .. 256 loop
               declare
                  Pixel : Mat :=
                    H.Region
                      ((Point_Coordinate (C), Point_Coordinate (R), 1, 1));
                  V     : constant Long_Float :=
                    0.25 + Long_Float (C mod 17) / 8.0;
               begin
                  Pixel.Set_To (Make_Scalar (V, V + 0.125, V + 0.25));
               end;
            end loop;
         end loop;
         return From_Mat (H.Convert_To (D));
      end Source;
      procedure Whole (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D in Float32 .. Float64 loop
            for Ch of Channel_List'(1, 3) loop
               declare
                  A     : constant Image := Source (D, Ch);
                  Dest  : Image := New_Image (2, 257, (D, Ch));
                  Alias : Image := Dest;
               begin
                  Set_To (Dest, Make_Scalar (91.0, 91.0, 91.0));
                  Into (A, Dest);
                  Equal (Observe (Dest), Observe (Fresh (A)));
                  Equal (Observe (Alias), Observe (Dest));
                  Set_To (Alias, Make_Scalar (7.0, 7.0, 7.0));
                  All_Values (Dest, 7.0);
                  Set_To (Dest, Make_Scalar (9.0, 9.0, 9.0));
                  All_Values (Alias, 9.0);
               end;
            end loop;
         end loop;
      end Whole;
      procedure Interior (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D in Float32 .. Float64 loop
            for Power of Powers'(0.0, 1.0, 2.0, 3.0) loop
               declare
                  A        : constant Image := Source (D, 1);
                  Parent   : Image := New_Image (5, 260, (D, 1));
                  Dest     : Image := Region (Parent, (1, 1, 257, 2));
                  Alias    : Image := Dest;
                  Location : constant Region_Location := Locate_Region (Dest);
               begin
                  Set_To (Parent, Make_Scalar (91.0));
                  Into (A, Dest, Power);
                  Equal (Observe (Dest), Observe (Fresh (A, Power)));
                  Equal (Observe (Alias), Observe (Dest));
                  Assert (Locate_Region (Dest) = Location, "Region geometry");
                  declare
                     H : constant Mat := Observe (Parent).Convert_To (Float64);
                  begin
                     for R in 0 .. 4 loop
                        for C in 0 .. 259 loop
                           if R < 1 or else R > 2 or else C < 1 or else C > 257
                           then
                              Assert (F.Get (H, R, C) = 91.0, "outside guard");
                           end if;
                        end loop;
                     end loop;
                  end;
                  Set_To (Alias, Make_Scalar (7.0));
                  All_Values (Dest, 7.0);
                  Set_To (Dest, Make_Scalar (9.0));
                  All_Values (Alias, 9.0);
               end;
            end loop;
         end loop;
      end Interior;
      procedure Mismatch (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for Mode in 1 .. 3 loop
            declare
               A      : constant Image := Source (Float32, 1);
               Parent : Image :=
                 New_Image
                   (5,
                    260,
                    ((if Mode = 2 then Float64 else Float32),
                     (if Mode = 3 then 3 else 1)));
               Dest   : Image :=
                 Region (Parent, (1, 1, (if Mode = 1 then 256 else 257), 2));
               Alias  : Image := Dest;
            begin
               Set_To (Parent, Make_Scalar (91.0, 91.0, 91.0));
               Into (A, Dest);
               Equal (Observe (Dest), Observe (Fresh (A)));
               All_Values (Parent, 91.0);
               All_Values (Alias, 91.0);
               Set_To (Dest, Make_Scalar (7.0));
               All_Values (Alias, 91.0);
               Set_To (Alias, Make_Scalar (9.0, 9.0, 9.0));
               All_Values (Dest, 7.0);
            end;
         end loop;
      end Mismatch;
      procedure Aliases (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D in Float32 .. Float64 loop
            for Ch of Channel_List'(1, 3) loop
               for Power of Powers'(0.0, 1.0, 2.0, 3.0, -1.0, 0.5, 1.3) loop
                  declare
                     A     : Image := Source (D, Ch);
                     E     : constant Image := Fresh (A, Power);
                     Alias : Image := A;
                  begin
                     Into (A, A, Power);
                     Equal (Observe (A), Observe (E));
                     Equal (Observe (Alias), Observe (A));
                     A := Source (D, Ch);
                     Alias := A;
                     Into (A, Alias, Power);
                     Equal (Observe (Alias), Observe (E));
                  end;
               end loop;
            end loop;
         end loop;
      end Aliases;
      procedure ND (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D in Float32 .. Float64 loop
            for Ch of Channel_List'(1, 3) loop
               declare
                  A     : Image := New_ND ((2, 3, 5), (D, Ch));
                  Dest  : Image := New_ND ((2, 3, 5), (D, Ch));
                  Alias : constant Image := Dest;
               begin
                  Set_To (A, Make_Scalar (1.5, 1.75, 2.0));
                  Into (A, Dest);
                  Equal (Observe (Dest), Observe (Fresh (A)));
                  Equal (Observe (Alias), Observe (Dest));
                  Dest := New_ND ((3, 2, 5), (D, Ch));
                  Into (A, Dest);
                  Equal (Observe (Dest), Observe (Fresh (A)));
                  Into (A, A);
                  Equal (Observe (A), Observe (Dest));
               end;
            end loop;
         end loop;
      end ND;
      procedure Numbers (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D in Float32 .. Float64 loop
            for Power of
              Powers'(0.0, 1.0, 2.0, 3.0, -1.0, -2.0, 0.5, -0.5, 1.3)
            loop
               declare
                  H : Mat := Create (1, 257, (Float64, 1));
               begin
                  for C in 0 .. 256 loop
                     F.Set
                       (H,
                        0,
                        C,
                        Float64_Value (0.25 + Long_Float (C mod 17) / 8.0));
                  end loop;
                  declare
                     A    : constant Image := From_Mat (H.Convert_To (D));
                     Dest : Image := New_Image (1, 257, (D, 1));
                  begin
                     Into (A, Dest, Power);
                     Equal (Observe (Dest), Observe (Fresh (A, Power)));
                     declare
                        Values : constant Mat :=
                          Observe (Dest).Convert_To (Float64);
                     begin
                        for C in 0 .. 256 loop
                           declare
                              V : constant Long_Float :=
                                Long_Float (F.Get (H, 0, C));
                              E : constant Long_Float :=
                                (case Op is
                                   when Square_Root     => Math.Sqrt (V),
                                   when Exponential     => Math.Exp (V),
                                   when Logarithm       => Math.Log (V),
                                   when Power_Operation =>
                                     Math."**" (V, Power));
                           begin
                              Assert
                                (abs (Long_Float (F.Get (Values, 0, C)) - E)
                                 <= 0.000_02 * Long_Float'Max (1.0, abs E),
                                 "independent finite expectation");
                           end;
                        end loop;
                     end;
                  end;
               end;
            end loop;
         end loop;
         if Op = Power_Operation then
            for D in UInt8 .. Int32 loop
               for Power of Powers'(0.0, 1.0, 2.0, 3.0, 4.0) loop
                  declare
                     A    : Image := New_Image (2, 257, (D, 1));
                     Dest : Image :=
                       New_Image
                         (2,
                          257,
                          ((if D = UInt8
                            then UInt16
                            elsif D = Int8
                            then Int16
                            else D),
                           1));
                  begin
                     Set_To (A, Make_Scalar (3.0));
                     Into (A, Dest, Power);
                     All_Values (Dest, 3.0**Natural (Power));
                  end;
               end loop;
            end loop;
            for D in UInt8 .. Int32 loop
               declare
                  A        : Image := New_Image (2, 257, (D, 1));
                  Parent   : Image := New_Image (5, 260, (D, 1));
                  Dest     : Image := Region (Parent, (1, 1, 257, 2));
                  Alias    : Image := Dest;
                  Position : constant Region_Location := Locate_Region (Dest);
               begin
                  Set_To (A, Make_Scalar (3.0));
                  for Power of Powers'(0.0, 1.0, 2.0, 3.0) loop
                     Set_To (Parent, Make_Scalar (91.0));
                     Into (A, Dest, Power);
                     All_Values (Alias, 3.0**Natural (Power));
                     Assert
                       (Locate_Region (Dest) = Position,
                        "integer specialized Region reuse");
                     Set_To (Alias, Make_Scalar (7.0));
                     All_Values (Dest, 7.0);
                     Set_To (Dest, Make_Scalar (9.0));
                     All_Values (Alias, 9.0);
                     declare
                        H : constant Mat :=
                          Observe (Parent).Convert_To (Float64);
                     begin
                        for R in 0 .. 4 loop
                           for C in 0 .. 259 loop
                              if R < 1
                                or else R > 2
                                or else C < 1
                                or else C > 257
                              then
                                 Assert
                                   (F.Get (H, R, C) = 91.0,
                                    "integer Parent guard");
                              end if;
                           end loop;
                        end loop;
                     end;
                  end loop;
               end;
               declare
                  A     : Image := New_ND ((2, 3, 5), (D, 1));
                  Dest  : Image := New_ND ((2, 3, 5), (D, 1));
                  Alias : constant Image := Dest;
               begin
                  Set_To (A, Make_Scalar (3.0));
                  Into (A, Dest, 3.0);
                  All_Values (Alias, 27.0);
                  Equal (Observe (Dest), Observe (Fresh (A, 3.0)));
               end;
            end loop;
         end if;
      end Numbers;
      procedure Empty (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D in Float32 .. Float64 loop
            for Power of Powers'(0.0, 1.0, 2.0, 3.0, 1.3) loop
               declare
                  A     : constant Image := New_Image (0, 0, (D, 1));
                  Dest  : Image := New_Image (2, 257, (Float64, 1));
                  Alias : constant Image := Dest;
                  E     : constant Image := Fresh (A, Power);
               begin
                  Set_To (Dest, Make_Scalar (91.0));
                  Into (A, Dest, Power);
                  Assert
                    (Observe (Dest).Is_Empty
                     and then Observe (E).Is_Empty
                     and then Depth (Dest) = Depth (E)
                     and then Channels (Dest) = Channels (E)
                     and then Shape (Dest) = Shape (E)
                     and then Dimension_Count (Dest) = Dimension_Count (E),
                     "typed-empty fresh/reused representation");
                  All_Values (Alias, 91.0);
               end;
            end loop;
         end loop;
         if Op = Power_Operation then
            for Power of Powers'(0.0, 1.0, 2.0, 3.0) loop
               declare
                  H     : Mat;
                  A     : constant Image := From_Mat (H);
                  Dest  : Image := New_Image (2, 257, (Float64, 1));
                  Alias : constant Image := Dest;
               begin
                  Set_To (Dest, Make_Scalar (91.0));
                  Into (A, Dest, Power);
                  Assert (Observe (Dest).Is_Empty, "default empty Pow");
                  All_Values (Alias, 91.0);
               end;
               declare
                  A     : constant Image := New_Image (0, 0, (UInt16, 3));
                  Dest  : Image := New_Image (2, 257, (Float64, 1));
                  Alias : constant Image := Dest;
               begin
                  Set_To (Dest, Make_Scalar (91.0));
                  Into (A, Dest, Power);
                  Assert
                    (Observe (Dest).Is_Empty
                     and then Depth (Dest) = UInt16
                     and then Channels (Dest) = 3,
                     "typed integer empty Pow");
                  All_Values (Alias, 91.0);
               end;
            end loop;
         end if;
      end Empty;
      procedure Failures (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D in UInt8 .. Float16 loop
            if D /= Float32 and then D /= Float64 then
               declare
                  A     : constant Image := New_Image (2, 257, (D, 1));
                  Dest  : Image := New_Image (2, 257, (Float64, 1));
                  Alias : constant Image := Dest;
                  procedure Attempt is
                  begin
                     Into (A, Dest, (if D = Float16 then 2.0 else 1.3));
                  end Attempt;
               begin
                  Set_To (Dest, Make_Scalar (91.0));
                  Assert_Raises_OpenCV_Error (Attempt'Access, "source policy");
                  All_Values (Dest, 91.0);
                  All_Values (Alias, 91.0);
               end;
            end if;
         end loop;
         declare
            H    : Mat;
            A    : constant Image := From_Mat (H);
            Dest : Image := New_Image (2, 257, (Float64, 1));
            procedure Attempt is
            begin
               Into (A, Dest, -1.0);
            end Attempt;
         begin
            Set_To (Dest, Make_Scalar (91.0));
            Assert_Raises_OpenCV_Error
              (Attempt'Access, "default empty policy");
            All_Values (Dest, 91.0);
         end;
         if Op = Power_Operation then
            declare
               A    : constant Image := New_Image (2, 257, (Int16, 1));
               Dest : Image := New_Image (2, 257, (Float64, 1));
               procedure Attempt is
               begin
                  Into (A, Dest, -2.0);
               end Attempt;
            begin
               Set_To (Dest, Make_Scalar (91.0));
               Assert_Raises_OpenCV_Error (Attempt'Access, "negative integer");
               All_Values (Dest, 91.0);
            end;
         end if;
      end Failures;
      procedure CPU (Test : in out Fixture) is
         procedure Run is
         begin
            Whole (Test);
            Interior (Test);
            Mismatch (Test);
            Aliases (Test);
            ND (Test);
            Numbers (Test);
            Empty (Test);
         end Run;
      begin
         Raw_ABI.With_OpenCL_Disabled (Run'Access);
      end CPU;
   end Cases;

   package MS is new
     Cases (Mat, Identity, Identity, Create, Create, Op => Square_Root);
   package ME is new
     Cases (Mat, Identity, Identity, Create, Create, Op => Exponential);
   package ML is new
     Cases (Mat, Identity, Identity, Create, Create, Op => Logarithm);
   package MP is new
     Cases (Mat, Identity, Identity, Create, Create, Op => Power_Operation);
   package US is new
     Cases
       (UMat,
        Transfers.To_UMat,
        Transfers.To_Mat,
        Create_UMat,
        Create_UMat,
        Op => Square_Root);
   package UE is new
     Cases
       (UMat,
        Transfers.To_UMat,
        Transfers.To_Mat,
        Create_UMat,
        Create_UMat,
        Op => Exponential);
   package UL is new
     Cases
       (UMat,
        Transfers.To_UMat,
        Transfers.To_Mat,
        Create_UMat,
        Create_UMat,
        Op => Logarithm);
   package UP is new
     Cases
       (UMat,
        Transfers.To_UMat,
        Transfers.To_Mat,
        Create_UMat,
        Create_UMat,
        Op => Power_Operation);

   procedure Temporary (View : in out Mat) is
      Source      : Mat := Create (View.Shape, (Float64, 1));
      Destination : Mat;
      procedure Into (Op : Operation; A : Mat; D : in out Mat) is
      begin
         case Op is
            when Square_Root     =>
               Sqrt (A, D);

            when Exponential     =>
               Exp (A, D);

            when Logarithm       =>
               Log (A, D);

            when Power_Operation =>
               Pow (A, 2.0, D);
         end case;
      end Into;
   begin
      Source.Set_To (Make_Scalar (4.0));
      for Op in Operation loop
         for Compatible in Boolean loop
            declare
               A      : constant Mat :=
                 (if Compatible then Source else Create (1, 1, (Float32, 3)));
               Before : constant Mat := View.Clone;
               procedure Attempt is
               begin
                  Into (Op, A, View);
               end Attempt;
            begin
               Assert_Raises_OpenCV_Error
                 (Attempt'Access, "temporary destination prohibited");
               Equal (View, Before);
            end;
         end loop;
         Into (Op, View, Destination);
         declare
            E : constant Mat :=
              (case Op is
                 when Square_Root     => Sqrt (View),
                 when Exponential     => Exp (View),
                 when Logarithm       => Log (View),
                 when Power_Operation => Pow (View, 2.0));
         begin
            Equal (Destination, E);
         end;
      end loop;
   end Temporary;
   procedure External (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data   : aliased Float64_Mat_View.Buffer_Array := (0 .. 9 => 4.0);
      Before : constant Float64_Mat_View.Buffer_Array := Data;
      use type Float64_Mat_View.Buffer_Array;
   begin
      Float64_Mat_View.With_Writable_Strided_Mat_View
        (Data, 2, 3, 5, Temporary'Access);
      Assert (Data = Before, "external backing and padding preserved");
   end External;
   procedure Selected (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Parent : Mat := Create (Dimension_Array'(2, 2, 3), (Float64, 1));
      Before : Mat;
   begin
      Parent.Set_To (Make_Scalar (4.0));
      Before := Parent.Clone;
      Parent.With_Selected_View
        (((Kind => Fix_Index, Index => 1),
          (Kind => Keep_Range, Bounds => (0, 2)),
          (Kind => Keep_Range, Bounds => (0, 3))),
         Temporary'Access);
      --  Use typed N-D access: this parent is not the standard (2,3,5) case.
      for I in Size_Coordinate range 0 .. 1 loop
         for J in Size_Coordinate range 0 .. 1 loop
            for K in Size_Coordinate range 0 .. 2 loop
               Assert
                 (F.Get (Parent, (I, J, K)) = F.Get (Before, (I, J, K)),
                  "selected Parent preserved");
            end loop;
         end loop;
      end loop;
   end Selected;
   procedure Integer_Boundaries (Test : in out Fixture) is
      pragma Unreferenced (Test);
      A    : Mat := Create (1, 257, (Int32, 1));
      D    : Mat := Create (1, 257, (Int32, 1));
      U, V : UMat;
   begin
      for C in 0 .. 256 loop
         Int32_Access.Set
           (A,
            0,
            C,
            (if C mod 2 = 0 then Int32_Value'Last else Int32_Value'First));
      end loop;
      Pow (A, 1.0, D);
      U := Transfers.To_UMat (A);
      Pow (U, 1.0, V);
      declare
         H : constant Mat := Transfers.To_Mat (V);
      begin
         for C in 0 .. 256 loop
            Assert
              (Int32_Access.Get (A, 0, C) = Int32_Access.Get (D, 0, C)
               and then Int32_Access.Get (A, 0, C)
                        = Int32_Access.Get (H, 0, C),
               "exact Int32 copy path");
         end loop;
      end;
      for Depth in UInt8 .. Int16 loop
         declare
            X        : Mat := Create (1, 257, (Depth, 1));
            Y        : Mat;
            Expected : constant Long_Float :=
              (case Depth is
                 when UInt8  => 255.0,
                 when Int8   => 127.0,
                 when UInt16 => 65_535.0,
                 when others => 32_767.0);
         begin
            X.Set_To (Make_Scalar (100.0));
            Pow (X, 4.0, Y);
            U := Transfers.To_UMat (X);
            Pow (U, 4.0, V);
            declare
               H  : constant Mat := Y.Convert_To (Float64);
               UH : constant Mat := Transfers.To_Mat (V).Convert_To (Float64);
            begin
               for C in 0 .. 256 loop
                  Assert
                    (F.Get (H, 0, C) = Float64_Value (Expected)
                     and then F.Get (UH, 0, C) = Float64_Value (Expected),
                     "integer saturation");
               end loop;
            end;
         end;
      end loop;
   end Integer_Boundaries;

   procedure Floating_Boundaries (Test : in out Fixture) is
      pragma Unreferenced (Test);
      type Values is array (Natural range <>) of Long_Float;
      procedure Check (Actual : Mat; Expected : Long_Float; C : Natural) is
         H : constant Mat := Actual.Convert_To (Float64);
      begin
         Assert
           (abs (Long_Float (F.Get (H, 0, C)) - Expected)
            <= 0.000_02 * Long_Float'Max (abs Expected, 1.0e-30),
            "finite boundary accuracy");
      end Check;
      A    : Mat := Create (1, 7, (Float64, 1));
      D    : Mat;
      U, V : UMat;
   begin
      for Depth in Float32 .. Float64 loop
         for Op in Square_Root .. Logarithm loop
            declare
               Data : constant Values :=
                 (case Op is
                    when Square_Root =>
                      (0.0, 1.0, 4.0, 2.0, 1.0e-20, 1.0e20, 0.125),
                    when Exponential =>
                      (-10.0, -1.0, 0.0, 1.0, 0.001, -0.001, 10.0),
                    when others      =>
                      (1.0, 0.125, 0.5, 2.0, 10.0, 1.0e-10, 1.0e10));
               X    : Mat;
            begin
               for C in Data'Range loop
                  F.Set (A, 0, C, Float64_Value (Data (C)));
               end loop;
               X := A.Convert_To (Depth);
               U := Transfers.To_UMat (X);
               case Op is
                  when Square_Root =>
                     Sqrt (X, D);
                     Sqrt (U, V);

                  when Exponential =>
                     Exp (X, D);
                     Exp (U, V);

                  when others      =>
                     Log (X, D);
                     Log (U, V);
               end case;
               for C in Data'Range loop
                  declare
                     E : constant Long_Float :=
                       (case Op is
                          when Square_Root => Math.Sqrt (Data (C)),
                          when Exponential => Math.Exp (Data (C)),
                          when others      => Math.Log (Data (C)));
                  begin
                     Check (D, E, C);
                     Check (Transfers.To_Mat (V), E, C);
                  end;
               end loop;
            end;
         end loop;
      end loop;
      --  Negative bases remain native: compare classification, not a new
      --  universal fractional-power or NaN-payload contract.
      A.Set_To (Make_Scalar (-4.0));
      Pow (A, 1.3, D);
      declare
         E : constant Mat := Pow (A, 1.3);
      begin
         for C in 0 .. 6 loop
            Assert
              (F.Classify (D, 0, C) = F.Classify (E, 0, C),
               "native negative fractional base classification");
         end loop;
      end;
   end Floating_Boundaries;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      procedure Add (Name : String; Process : Caller.Test_Method) is
      begin
         Result.Add_Test (Caller.Create (Name, Process));
      end Add;
   begin
      Add ("Mat Sqrt whole reuse", MS.Whole'Access);
      Add ("Mat Exp whole reuse", ME.Whole'Access);
      Add ("Mat Log whole reuse", ML.Whole'Access);
      Add ("Mat Pow whole reuse", MP.Whole'Access);
      Add ("UMat Sqrt whole reuse", US.Whole'Access);
      Add ("UMat Exp whole reuse", UE.Whole'Access);
      Add ("UMat Log whole reuse", UL.Whole'Access);
      Add ("UMat Pow whole reuse", UP.Whole'Access);
      Add ("Mat Sqrt Region", MS.Interior'Access);
      Add ("Mat Exp Region", ME.Interior'Access);
      Add ("Mat Log Region", ML.Interior'Access);
      Add ("Mat Pow Region", MP.Interior'Access);
      Add ("UMat Sqrt Region", US.Interior'Access);
      Add ("UMat Exp Region", UE.Interior'Access);
      Add ("UMat Log Region", UL.Interior'Access);
      Add ("UMat Pow Region", UP.Interior'Access);
      Add ("Mat Sqrt mismatch", MS.Mismatch'Access);
      Add ("Mat Exp mismatch", ME.Mismatch'Access);
      Add ("Mat Log mismatch", ML.Mismatch'Access);
      Add ("Mat Pow mismatch", MP.Mismatch'Access);
      Add ("UMat Sqrt mismatch", US.Mismatch'Access);
      Add ("UMat Exp mismatch", UE.Mismatch'Access);
      Add ("UMat Log mismatch", UL.Mismatch'Access);
      Add ("UMat Pow mismatch", UP.Mismatch'Access);
      Add ("Mat Sqrt aliases", MS.Aliases'Access);
      Add ("Mat Exp aliases", ME.Aliases'Access);
      Add ("Mat Log aliases", ML.Aliases'Access);
      Add ("Mat Pow aliases", MP.Aliases'Access);
      Add ("UMat Sqrt aliases", US.Aliases'Access);
      Add ("UMat Exp aliases", UE.Aliases'Access);
      Add ("UMat Log aliases", UL.Aliases'Access);
      Add ("UMat Pow aliases", UP.Aliases'Access);
      Add ("Mat Sqrt N-D", MS.ND'Access);
      Add ("Mat Exp N-D", ME.ND'Access);
      Add ("Mat Log N-D", ML.ND'Access);
      Add ("Mat Pow N-D", MP.ND'Access);
      Add ("UMat Sqrt N-D", US.ND'Access);
      Add ("UMat Exp N-D", UE.ND'Access);
      Add ("UMat Log N-D", UL.ND'Access);
      Add ("UMat Pow N-D", UP.ND'Access);
      Add ("Mat Sqrt numbers", MS.Numbers'Access);
      Add ("Mat Exp numbers", ME.Numbers'Access);
      Add ("Mat Log numbers", ML.Numbers'Access);
      Add ("Mat Pow numbers", MP.Numbers'Access);
      Add ("UMat Sqrt numbers", US.Numbers'Access);
      Add ("UMat Exp numbers", UE.Numbers'Access);
      Add ("UMat Log numbers", UL.Numbers'Access);
      Add ("UMat Pow numbers", UP.Numbers'Access);
      Add ("Mat Sqrt empty", MS.Empty'Access);
      Add ("Mat Exp empty", ME.Empty'Access);
      Add ("Mat Log empty", ML.Empty'Access);
      Add ("Mat Pow empty", MP.Empty'Access);
      Add ("UMat Sqrt empty", US.Empty'Access);
      Add ("UMat Exp empty", UE.Empty'Access);
      Add ("UMat Log empty", UL.Empty'Access);
      Add ("UMat Pow empty", UP.Empty'Access);
      Add ("Mat Sqrt validation", MS.Failures'Access);
      Add ("Mat Exp validation", ME.Failures'Access);
      Add ("Mat Log validation", ML.Failures'Access);
      Add ("Mat Pow validation", MP.Failures'Access);
      Add ("UMat Sqrt validation", US.Failures'Access);
      Add ("UMat Exp validation", UE.Failures'Access);
      Add ("UMat Log validation", UL.Failures'Access);
      Add ("UMat Pow validation", UP.Failures'Access);
      Add ("UMat Sqrt CPU", US.CPU'Access);
      Add ("UMat Exp CPU", UE.CPU'Access);
      Add ("UMat Log CPU", UL.CPU'Access);
      Add ("UMat Pow CPU", UP.CPU'Access);
      Add ("Unary Mat raw ABI", Raw_ABI.Mat_Check'Access);
      Add ("Unary UMat raw ABI", Raw_ABI.UMat_Check'Access);
      Add ("Unary temporary external", External'Access);
      Add ("Unary temporary selected", Selected'Access);
      Add ("Pow integer boundaries", Integer_Boundaries'Access);
      Add ("Unary floating boundaries", Floating_Boundaries'Access);
      return Result'Access;
   end Suite;
end Unary_Math_Destination_Tests;
