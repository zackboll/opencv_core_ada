with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;
with Add_Subtract_Destination_Tests.Raw_ABI;

package body Add_Subtract_Destination_Tests is
   use OpenCV;
   use OpenCV.Core;
   use Mat_Test_Support;
   use AUnit.Assertions;
   use type Float32_Value;
   use type UInt8_Value;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   type Depths is array (Positive range <>) of Depth_Type;

   function Identity (Self : Mat) return Mat
   is (Self);

   function Component (Value : Scalar; Channel : Natural) return Long_Float
   is (if Channel = 0
       then Value.Component_0
       elsif Channel = 1
       then Value.Component_1
       else Value.Component_2);

   procedure Check (Actual, Expected : Long_Float; Message : String) is
   begin
      Assert (Approximately_Equal (Actual, Expected, 0.000_01), Message);
   end Check;

   --  Transfers below are test setup/observation, not production staging.
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
        procedure Add (Left, Right : Image; Destination : in out Image) is <>;
      with
        procedure Subtract (Left, Right : Image; Destination : in out Image)
        is <>;
      with function Add (Left, Right : Image) return Image is <>;
      with function Subtract (Left, Right : Image) return Image is <>;
      with function Region (Self : Image; Area : Rect) return Image is <>;
      with procedure Set_To (Self : in out Image; Value : Scalar) is <>;
      with function Shape (Self : Image) return Dimension_Array is <>;
      with function Depth (Self : Image) return Depth_Type is <>;
      with function Channels (Self : Image) return Channel_Count is <>;
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
      procedure Empty (Test : in out Fixture);
      procedure Failures (Test : in out Fixture);
   end Cases;

   package body Cases is
      procedure Apply (A, B : Image; D : in out Image; Sub : Boolean) is
      begin
         if Sub then
            Subtract (A, B, D);
         else
            Add (A, B, D);
         end if;
      end Apply;

      function Calculate (A, B : Image; Sub : Boolean) return Image
      is (if Sub then Subtract (A, B) else Add (A, B));

      function Values (Self : Image; Channel : Natural := 0) return Mat is
         Host : constant Mat := Observe (Self);
      begin
         if Host.Channels = 1 then
            return Host.Convert_To (Float64);
         else
            return Host.Extract_Channel (Channel).Convert_To (Float64);
         end if;
      end Values;

      procedure All_Values (Self : Image; Expected : Long_Float) is
         Host : constant Mat := Values (Self);
      begin
         for R in 0 .. Host.Rows - 1 loop
            for Col in 0 .. Host.Columns - 1 loop
               Check
                 (Long_Float (Float64_Access.Get (Host, R, Col)),
                  Expected,
                  "every pixel");
            end loop;
         end loop;
      end All_Values;

      function Vector (D : Depth_Type; Left : Boolean) return Image is
         Host : Mat := Create (1, 257, (Float32, 1));
      begin
         for Col in 0 .. 256 loop
            Float32_Access.Set
              (Host,
               0,
               Col,
               Float32_Value
                 (if Left
                  then (Integer (Col mod 31) - 15) * 2
                  else Integer (Col mod 17) - 8));
         end loop;
         return From_Mat (Host.Convert_To (D));
      end Vector;

      procedure Equal (Actual, Expected : Image) is
         A : constant Mat := Values (Actual);
         E : constant Mat := Values (Expected);
      begin
         Assert
           (Shape (Actual) = Shape (Expected)
            and then Depth (Actual) = Depth (Expected)
            and then Channels (Actual) = Channels (Expected),
            "procedure/function shape and type parity");
         for Col in 0 .. 256 loop
            Check
              (Long_Float (Float64_Access.Get (A, 0, Col)),
               Long_Float (Float64_Access.Get (E, 0, Col)),
               "all 257 elements including SIMD tail");
         end loop;
      end Equal;

      procedure Whole (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depths'(Float32, Float64, Float16) loop
            for Sub in Boolean loop
               declare
                  A           : constant Image := Vector (D, True);
                  B           : constant Image := Vector (D, False);
                  Destination : Image := New_Image (1, 257, (D, 1));
                  Alias       : Image := Destination;
                  Expected    : constant Image := Calculate (A, B, Sub);
               begin
                  Apply (A, B, Destination, Sub);
                  Equal (Destination, Expected);
                  Equal (Alias, Expected);
                  Set_To (Alias, Make_Scalar (17.0));
                  All_Values (Destination, 17.0);
                  Set_To (Destination, Make_Scalar (-19.0));
                  All_Values (Alias, -19.0);
               end;
            end loop;
         end loop;
      end Whole;

      procedure Interior (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depths'(Float32, Float16) loop
            for Sub in Boolean loop
               declare
                  AH          : Mat := Create (2, 3, (Float32, 1));
                  BH          : Mat := Create (2, 3, (Float32, 1));
                  A, B        : Image;
                  Parent      : Image := New_Image (5, 7, (D, 1));
                  Destination : Image := Region (Parent, (2, 1, 3, 2));
                  Alias       : Image := Destination;
                  Geometry    : constant Region_Location :=
                    Locate_Region (Destination);
               begin
                  Set_To (Parent, Make_Scalar (91.0));
                  for R in 0 .. 1 loop
                     for Col in 0 .. 2 loop
                        Float32_Access.Set
                          (AH, R, Col, Float32_Value (R * 3 + Col) - 4.0);
                        Float32_Access.Set
                          (BH, R, Col, Float32_Value (R + Col) + 2.0);
                     end loop;
                  end loop;
                  A := From_Mat (AH.Convert_To (D));
                  B := From_Mat (BH.Convert_To (D));
                  Apply (A, B, Destination, Sub);
                  Assert
                    (Shape (Destination) = (2, 3)
                     and then Locate_Region (Destination) = Geometry,
                     "Region shape/offset/whole geometry unchanged");
                  declare
                     P : constant Mat := Values (Parent);
                     V : constant Mat := Values (Alias);
                  begin
                     for R in 0 .. 4 loop
                        for Col in 0 .. 6 loop
                           if R in 1 .. 2 and then Col in 2 .. 4 then
                              declare
                                 X : constant Long_Float :=
                                   Long_Float ((R - 1) * 3 + Col - 2) - 4.0;
                                 Y : constant Long_Float :=
                                   Long_Float (R - 1 + Col - 2) + 2.0;
                                 E : constant Long_Float :=
                                   (if Sub then X - Y else X + Y);
                              begin
                                 Check
                                   (Long_Float
                                      (Float64_Access.Get (P, R, Col)),
                                    E,
                                    "intended parent pixel");
                                 Check
                                   (Long_Float
                                      (Float64_Access.Get (V, R - 1, Col - 2)),
                                    E,
                                    "preexisting Region alias");
                              end;
                           else
                              Check
                                (Long_Float (Float64_Access.Get (P, R, Col)),
                                 91.0,
                                 "every outside guard");
                           end if;
                        end loop;
                     end loop;
                  end;
                  Set_To (Alias, Make_Scalar (23.0));
                  All_Values (Destination, 23.0);
                  Check
                    (Long_Float (Float64_Access.Get (Values (Parent), 1, 2)),
                     23.0,
                     "alias remains attached to parent");
                  Set_To (Destination, Make_Scalar (25.0));
                  All_Values (Alias, 25.0);
                  Check
                    (Long_Float (Float64_Access.Get (Values (Parent), 2, 4)),
                     25.0,
                     "destination remains attached to parent");
               end;
            end loop;
         end loop;
      end Interior;

      procedure Reallocate (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for Sub in Boolean loop
            for Mismatch in 1 .. 4 loop
               declare
                  --  Pin the old-Float32/byte subtraction dispatch hazard.
                  Source_Depth : constant Depth_Type :=
                    (if Mismatch = 4 then UInt8 else Float32);
                  Format       : constant Mat_Type :=
                    (if Mismatch = 2
                     then (Int16, 1)
                     elsif Mismatch = 3
                     then (Float32, 2)
                     else (Float32, 1));
                  A            : Image := New_Image (2, 3, (Source_Depth, 1));
                  B            : Image := New_Image (2, 3, (Source_Depth, 1));
                  Parent       : Image := New_Image (5, 7, Format);
                  Destination  : Image :=
                    Region
                      (Parent, (2, 1, (if Mismatch = 1 then 2 else 3), 2));
                  Alias        : Image := Destination;
                  Before       : constant Dimension_Array := Shape (Alias);
               begin
                  Set_To (A, Make_Scalar (13.0));
                  Set_To (B, Make_Scalar (5.0));
                  Set_To (Parent, Make_Scalar (91.0, 92.0));
                  Apply (A, B, Destination, Sub);
                  Assert
                    (Shape (Destination) = (2, 3)
                     and then Depth (Destination) = Source_Depth
                     and then Channels (Destination) = 1,
                     "native mismatch shape/type reallocation");
                  All_Values (Destination, (if Sub then 8.0 else 18.0));
                  All_Values (Parent, 91.0);
                  All_Values (Alias, 91.0);
                  if Mismatch = 3 then
                     declare
                        P : constant Mat := Values (Parent, 1);
                     begin
                        for R in 0 .. 4 loop
                           for Col in 0 .. 6 loop
                              Check
                                (Long_Float (Float64_Access.Get (P, R, Col)),
                                 92.0,
                                 "every old second-channel pixel");
                           end loop;
                        end loop;
                     end;
                  end if;
                  Assert (Shape (Alias) = Before, "old alias geometry");
                  Set_To (Destination, Make_Scalar (27.0));
                  All_Values (Parent, 91.0);
                  Set_To (Alias, Make_Scalar (31.0, 32.0));
                  All_Values (Destination, 27.0);
                  Check
                    (Long_Float (Float64_Access.Get (Values (Parent), 1, 2)),
                     31.0,
                     "old alias still reaches parent, not new output");
               end;
            end loop;
         end loop;
      end Reallocate;

      procedure Aliases (Mode : Positive) is
      begin
         for D of Depths'(Int16, Int32, Float32, Float64, Float16) loop
            for Sub in Boolean loop
               declare
                  A           : Image := Vector (D, True);
                  B           : Image := Vector (D, False);
                  Destination : Image;
               begin
                  if Mode = 5 then
                     B := A;
                  end if;
                  declare
                     Expected : constant Image := Calculate (A, B, Sub);
                  begin
                     if Mode = 1 then
                        Apply (A, B, A, Sub);
                        Equal (A, Expected);
                     elsif Mode = 2 then
                        Apply (A, B, B, Sub);
                        Equal (B, Expected);
                     else
                        Destination := (if Mode = 4 then B else A);
                        Apply (A, B, Destination, Sub);
                        Equal (Destination, Expected);
                        Equal ((if Mode = 4 then B else A), Expected);
                     end if;
                     declare
                        V : constant Mat :=
                          Values
                            ((if Mode = 1
                              then A
                              elsif Mode = 2
                              then B
                              else Destination));
                     begin
                        for Col in 0 .. 256 loop
                           declare
                              X : constant Long_Float :=
                                Long_Float ((Integer (Col mod 31) - 15) * 2);
                              Y : constant Long_Float :=
                                (if Mode = 5
                                 then X
                                 else Long_Float (Integer (Col mod 17) - 8));
                           begin
                              Check
                                (Long_Float (Float64_Access.Get (V, 0, Col)),
                                 (if Sub then X - Y else X + Y),
                                 "old operand values and subtraction order");
                           end;
                        end loop;
                     end;
                     if Mode = 5 then
                        declare
                           V : constant Mat := Values (Destination);
                        begin
                           for Col in 0 .. 256 loop
                              Check
                                (Long_Float (Float64_Access.Get (V, 0, Col)),
                                 (if Sub
                                  then 0.0
                                  else
                                    Long_Float
                                      ((Integer (Col mod 31) - 15) * 4)),
                                 "A+A=2*A; A-A=0 with shared output");
                           end loop;
                        end;
                     end if;
                  end;
               end;
            end loop;
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
         for Sub in Boolean loop
            declare
               A        : Image := Vector (Float32, True);
               Expected : constant Image := Calculate (A, A, Sub);
            begin
               Apply (A, A, A, Sub);
               Equal (A, Expected);
            end;
         end loop;
      end Same_Operands;

      procedure Numbers (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depths'(UInt8, Int16, Int32, Float32, Float64) loop
            for Sub in Boolean loop
               declare
                  A           : Image := New_Image (2, 3, (D, 3));
                  B           : Image := New_Image (2, 3, (D, 3));
                  Destination : Image := New_Image (2, 3, (D, 3));
                  Alias       : constant Image := Destination;
                  X           : constant Scalar :=
                    (if D = UInt8
                     then Make_Scalar (250.0, 3.0, 19.0)
                     elsif D = Int32
                     then
                       Make_Scalar (2_000_000_000.0, -2_000_000_000.0, -19.0)
                     else Make_Scalar (30000.0, -30000.0, -19.0));
                  Y           : constant Scalar :=
                    (if D = UInt8
                     then Make_Scalar (10.0, 10.0, 5.0)
                     elsif D = Int32
                     then Make_Scalar (100_000_000.0, -100_000_000.0, 5.0)
                     else Make_Scalar (10000.0, -10000.0, 5.0));
               begin
                  Set_To (A, X);
                  Set_To (B, Y);
                  Apply (A, B, Destination, Sub);
                  for Channel in 0 .. 2 loop
                     declare
                        V : constant Mat := Values (Alias, Channel);
                        E : Long_Float :=
                          (if Sub
                           then Component (X, Channel) - Component (Y, Channel)
                           else
                             Component (X, Channel) + Component (Y, Channel));
                     begin
                        if D = UInt8 then
                           E :=
                             Long_Float'Max (0.0, Long_Float'Min (255.0, E));
                        elsif D = Int16 then
                           E :=
                             Long_Float'Max
                               (-32768.0, Long_Float'Min (32767.0, E));
                        end if;
                        for R in 0 .. 1 loop
                           for Col in 0 .. 2 loop
                              Check
                                (Long_Float (Float64_Access.Get (V, R, Col)),
                                 E,
                                 "native C3 signed/saturating arithmetic");
                           end loop;
                        end loop;
                     end;
                  end loop;
               end;
            end loop;
         end loop;
      end Numbers;

      procedure Empty (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Major : constant Natural := Module_Bridge_Probe.OpenCV_Major_Version;
      begin
         for D of Depths'(UInt8, Float32, Float16) loop
            for Mode in 0 .. 3 loop
               if Mode <= 1 or else D = UInt8 then
                  for Sub in Boolean loop
                     declare
                        A, B        : Image;
                        Destination : Image := New_Image (2, 3, (Int16, 2));
                        Alias       : Image := Destination;
                        Typed       : constant Boolean :=
                          Mode = 1
                          or else Mode = 3
                          or else (Is_UMat and then Mode = 2);
                        Released    : constant Boolean :=
                          not Typed
                          or else (not Is_UMat
                                   and then (D = Float16 or else Major >= 5));
                        Ch          : constant Channel_Count :=
                          (if Mode = 1 then 3 else 1);
                     begin
                        if Mode = 1 or else Mode = 3 then
                           A := New_Image (0, 0, (D, Ch));
                        end if;
                        if Mode = 1 or else Mode = 2 then
                           B := New_Image (0, 0, (D, Ch));
                        end if;
                        Set_To (Destination, Make_Scalar (91.0, 92.0));
                        declare
                           Expected : constant Image := Calculate (A, B, Sub);
                        begin
                           Apply (A, B, Destination, Sub);
                           Assert
                             (Is_Empty (Expected)
                              and then Is_Empty (Destination),
                              "both APIs empty");
                           Assert
                             (Shape (Destination)'Length
                              = (if Released and then Major >= 5
                                 then 0
                                 else 2),
                              "native release/create dimension difference");
                           if Shape (Destination)'Length = 2 then
                              Assert
                                (Shape (Destination) = (0, 0),
                                 "released/created zero extents");
                           end if;
                           Assert
                             (Depth (Destination)
                              = (if Released then Int16 else D)
                              and then Channels (Destination)
                                       = (if Released then 2 else Ch),
                              "release retains old type; create takes type");
                           if not Released then
                              Assert
                                (Shape (Destination) = Shape (Expected)
                                 and then Depth (Destination)
                                          = Depth (Expected)
                                 and then Channels (Destination)
                                          = Channels (Expected),
                                 "empty create exact function parity");
                           else
                              Assert
                                (Depth (Expected) = UInt8
                                 and then Channels (Expected) = 1,
                                 "released function retains default type");
                           end if;
                        end;
                        All_Values (Alias, 91.0);
                        declare
                           Old : constant Mat := Values (Alias, 1);
                        begin
                           for R in 0 .. 1 loop
                              for Col in 0 .. 2 loop
                                 Check
                                   (Long_Float
                                      (Float64_Access.Get (Old, R, Col)),
                                    92.0,
                                    "empty old alias second channel");
                              end loop;
                           end loop;
                        end;
                        Set_To (Alias, Make_Scalar (33.0, 34.0));
                        Assert
                          (Is_Empty (Destination), "old alias independent");
                     end;
                  end loop;
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
         for Sub in Boolean loop
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
                     Apply
                       ((if Mode = 4 then Volume else A), B, Destination, Sub);
                  end Attempt;
                  procedure Function_Attempt is
                     Unused : constant Image :=
                       Calculate ((if Mode = 4 then Volume else A), B, Sub);
                     pragma Unreferenced (Unused);
                  begin
                     null;
                  end Function_Attempt;
               begin
                  Assert_Raises_OpenCV_Error
                    (Attempt'Access, "operand policy");
                  Assert_Raises_OpenCV_Error
                    (Function_Attempt'Access, "unchanged function policy");
                  Assert
                    (Shape (Destination) = (2, 3)
                     and then Depth (Destination) = Float32
                     and then Channels (Destination) = 1,
                     "pre-native metadata unchanged");
                  All_Values (Destination, 91.0);
                  All_Values (Alias, 91.0);
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
      Source      : Mat := Create (View.Rows, View.Columns, (UInt8, 1));
      Other       : Mat := Create (1, 2, (Float32, 1));
      Destination : Mat;
      Before      : constant Dimension_Array := View.Shape;
      procedure Unchanged is
      begin
         Assert
           (View.Shape = Before
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
      Source.Set_To (Make_Scalar (5.0));
      Other.Set_To (Make_Scalar (3.0));
      for Sub in Boolean loop
         for Mismatch in Boolean loop
            declare
               procedure Attempt is
               begin
                  if Sub then
                     Subtract
                       ((if Mismatch then Other else Source),
                        (if Mismatch then Other else Source),
                        View);
                  else
                     Add
                       ((if Mismatch then Other else Source),
                        (if Mismatch then Other else Source),
                        View);
                  end if;
               end Attempt;
            begin
               Unchanged;
               Assert_Raises_OpenCV_Error (Attempt'Access, "temporary output");
               Unchanged;
            end;
         end loop;
         for Left_View in Boolean loop
            if Sub then
               Subtract
                 ((if Left_View then View else Source),
                  (if Left_View then Source else View),
                  Destination);
            else
               Add
                 ((if Left_View then View else Source),
                  (if Left_View then Source else View),
                  Destination);
            end if;
            for R in 0 .. View.Rows - 1 loop
               for Col in 0 .. View.Columns - 1 loop
                  Assert
                    (UInt8_Access.Get (Destination, R, Col)
                     = (if not Sub then 42 elsif Left_View then 32 else 0),
                     "temporary Left/Right sources permitted");
               end loop;
            end loop;
            Destination.Set_To (Make_Scalar (99.0));
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
      Assert (Data = Before, "external pixels and row padding unchanged");
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
                  "all selected parent pixels unchanged");
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
         UMat_Cases.Empty (Test);
      end Run;
   begin
      Raw_ABI.With_OpenCL_Disabled (Run'Access);
   end UMat_CPU;

   procedure Register
     (Prefix   : String;
      Whole,
      Interior,
      Reallocate,
      Into_Left,
      Into_Right,
      Shallow,
      Same_Operands,
      Numbers,
      Empty,
      Failures : Caller.Test_Method) is
   begin
      Result.Add_Test
        (Caller.Create (Prefix & "whole/float/half reuse", Whole));
      Result.Add_Test (Caller.Create (Prefix & "Region reuse", Interior));
      Result.Add_Test
        (Caller.Create (Prefix & "mismatch detachment", Reallocate));
      Result.Add_Test (Caller.Create (Prefix & "into Left", Into_Left));
      Result.Add_Test
        (Caller.Create (Prefix & "into Right order/tail", Into_Right));
      Result.Add_Test
        (Caller.Create (Prefix & "same-layout aliases", Shallow));
      Result.Add_Test (Caller.Create (Prefix & "A+A/A-A", Same_Operands));
      Result.Add_Test
        (Caller.Create (Prefix & "integer/C3 semantics", Numbers));
      Result.Add_Test (Caller.Create (Prefix & "empty parity", Empty));
      Result.Add_Test
        (Caller.Create (Prefix & "operand failures/N-D", Failures));
   end Register;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Register
        ("Add/Subtract destination Mat ",
         Mat_Cases.Whole'Access,
         Mat_Cases.Interior'Access,
         Mat_Cases.Reallocate'Access,
         Mat_Cases.Into_Left'Access,
         Mat_Cases.Into_Right'Access,
         Mat_Cases.Shallow'Access,
         Mat_Cases.Same_Operands'Access,
         Mat_Cases.Numbers'Access,
         Mat_Cases.Empty'Access,
         Mat_Cases.Failures'Access);
      Register
        ("Add/Subtract destination UMat ",
         UMat_Cases.Whole'Access,
         UMat_Cases.Interior'Access,
         UMat_Cases.Reallocate'Access,
         UMat_Cases.Into_Left'Access,
         UMat_Cases.Into_Right'Access,
         UMat_Cases.Shallow'Access,
         UMat_Cases.Same_Operands'Access,
         UMat_Cases.Numbers'Access,
         UMat_Cases.Empty'Access,
         UMat_Cases.Failures'Access);
      Result.Add_Test
        (Caller.Create ("Add/Subtract external", External'Access));
      Result.Add_Test
        (Caller.Create ("Add/Subtract selected", Selected'Access));
      Result.Add_Test
        (Caller.Create ("Add/Subtract raw Mat", Raw_ABI.Mat_Check'Access));
      Result.Add_Test
        (Caller.Create ("Add/Subtract raw UMat", Raw_ABI.UMat_Check'Access));
      Result.Add_Test
        (Caller.Create ("Add/Subtract UMat CPU", UMat_CPU'Access));
      return Result'Access;
   end Suite;
end Add_Subtract_Destination_Tests;
