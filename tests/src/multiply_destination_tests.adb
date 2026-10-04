with AUnit.Assertions;
with AUnit.Test_Caller;
with Ada.Exceptions;
with Ada.Strings.Fixed;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;
with Multiply_Destination_Tests.Raw_ABI;

package body Multiply_Destination_Tests is
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

   procedure Check (Actual, Expected : Long_Float) is
   begin
      Assert
        (Approximately_Equal (Actual, Expected, 0.000_01),
         "every multiplication pixel");
   end Check;

   function Saturated (Value : Long_Float; D : Depth_Type) return Long_Float
   is (if D = UInt8
       then Long_Float'Max (0.0, Long_Float'Min (255.0, Value))
       elsif D = Int8
       then Long_Float'Max (-128.0, Long_Float'Min (127.0, Value))
       elsif D = Int16
       then Long_Float'Max (-32768.0, Long_Float'Min (32767.0, Value))
       else Value);

   --  Transfers are test setup/observation only, not production staging.
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
        procedure Multiply (Left, Right : Image; Destination : in out Image)
        is <>;
      with function Multiply (Left, Right : Image) return Image is <>;
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
      begin
         for Channel in 0 .. Natural (Channels (Self)) - 1 loop
            declare
               Host : constant Mat := Values (Self, Channel);
            begin
               for R in 0 .. Host.Rows - 1 loop
                  for Col in 0 .. Host.Columns - 1 loop
                     Check
                       (Long_Float (Float64_Access.Get (Host, R, Col)),
                        Expected);
                  end loop;
               end loop;
            end;
         end loop;
      end All_Values;

      function X (Col : Natural; D : Depth_Type) return Long_Float
      is (if D = UInt8
          then Long_Float (Col mod 23 + 1)
          elsif D = Int16
          then Long_Float ((Integer (Col mod 31) - 15) * 40)
          else Long_Float (Integer (Col mod 31) - 15) * 0.5);

      function Y (Col : Natural; D : Depth_Type) return Long_Float
      is (if D = UInt8
          then Long_Float (Col mod 17 + 2)
          elsif D = Int16
          then Long_Float (Integer (Col mod 17) - 8)
          else Long_Float (Integer (Col mod 17) - 8) * 0.25);

      function Vector (D : Depth_Type; Left : Boolean) return Image is
         Host : Mat := Create (1, 257, (Float32, 1));
      begin
         for Col in 0 .. 256 loop
            Float32_Access.Set
              (Host,
               0,
               Col,
               Float32_Value (if Left then X (Col, D) else Y (Col, D)));
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
            "procedure/function shape/type parity");
         for Col in 0 .. 256 loop
            Check
              (Long_Float (Float64_Access.Get (A, 0, Col)),
               Long_Float (Float64_Access.Get (E, 0, Col)));
         end loop;
      end Equal;

      procedure Whole (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depths'(Float32, Float64, Float16) loop
            declare
               A           : Image := Vector (D, True);
               B           : constant Image := Vector (D, False);
               Destination : Image := New_Image (1, 257, (D, 1));
               Alias       : Image := Destination;
               Expected    : constant Image := Multiply (A, B);
            begin
               Multiply (A, B, Destination);
               Equal (Destination, Expected);
               Equal (Alias, Expected);
               Set_To (Alias, Make_Scalar (17.0));
               All_Values (Destination, 17.0);
               Set_To (Destination, Make_Scalar (-19.0));
               All_Values (Alias, -19.0);
               --  The allocating function still owns independent results.
               Set_To (A, Make_Scalar (29.0));
               declare
                  V : constant Mat := Values (Expected);
               begin
                  for Col in 0 .. 256 loop
                     Check
                       (Long_Float (Float64_Access.Get (V, 0, Col)),
                        X (Col, D) * Y (Col, D));
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
               Multiply (A, B, Destination);
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
                              E : constant Long_Float :=
                                (Long_Float ((R - 1) * 3 + Col - 2) - 4.0)
                                * (Long_Float (R - 1 + Col - 2) + 2.0);
                           begin
                              Check
                                (Long_Float (Float64_Access.Get (P, R, Col)),
                                 E);
                              Check
                                (Long_Float
                                   (Float64_Access.Get (V, R - 1, Col - 2)),
                                 E);
                           end;
                        else
                           Check
                             (Long_Float (Float64_Access.Get (P, R, Col)),
                              91.0);
                        end if;
                     end loop;
                  end loop;
               end;
               Set_To (Alias, Make_Scalar (23.0));
               All_Values (Destination, 23.0);
               Set_To (Destination, Make_Scalar (25.0));
               All_Values (Alias, 25.0);
               declare
                  P : constant Mat := Values (Parent);
               begin
                  for R in 0 .. 4 loop
                     for Col in 0 .. 6 loop
                        Check
                          (Long_Float (Float64_Access.Get (P, R, Col)),
                           (if R in 1 .. 2 and then Col in 2 .. 4
                            then 25.0
                            else 91.0));
                     end loop;
                  end loop;
               end;
            end;
         end loop;
      end Interior;

      procedure Reallocate (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         --  Independent shape, depth, channel mismatches, then both hazardous
         --  byte/old-word-depth pairs at a width exposing vector/tail writes.
         for Mode in 1 .. 5 loop
            declare
               D           : constant Depth_Type :=
                 (if Mode = 4
                  then UInt8
                  elsif Mode = 5
                  then Int8
                  else Float32);
               Old_D       : constant Depth_Type :=
                 (if Mode = 4
                  then UInt16
                  elsif Mode = 5
                  then Int16
                  elsif Mode = 2
                  then Float64
                  else D);
               Ch          : constant Channel_Count :=
                 (if Mode = 3 then 2 else 1);
               A           : Image := New_Image (2, 257, (D, 1));
               B           : Image := New_Image (2, 257, (D, 1));
               Parent      : Image := New_Image (5, 260, (Old_D, Ch));
               Destination : Image :=
                 Region (Parent, (1, 1, (if Mode = 1 then 256 else 257), 2));
               Alias       : Image := Destination;
               Old_Shape   : constant Dimension_Array := Shape (Alias);
            begin
               Set_To (A, Make_Scalar (if Mode = 5 then -11.0 else 20.0));
               Set_To (B, Make_Scalar (20.0));
               Set_To (Parent, Make_Scalar (91.0, 91.0));
               Multiply (A, B, Destination);
               Assert
                 (Shape (Destination) = (2, 257)
                  and then Depth (Destination) = D
                  and then Channels (Destination) = 1,
                  "native mismatch output shape/type");
               All_Values
                 (Destination,
                  (if Mode = 4
                   then 255.0
                   elsif Mode = 5
                   then -128.0
                   else 400.0));
               All_Values (Parent, 91.0);
               All_Values (Alias, 91.0);
               Assert (Shape (Alias) = Old_Shape, "old alias geometry");
               Set_To (Destination, Make_Scalar (27.0));
               All_Values (Parent, 91.0);
               Set_To (Alias, Make_Scalar (31.0, 31.0));
               All_Values (Destination, 27.0);
               declare
                  P : constant Mat := Values (Parent);
               begin
                  for R in 0 .. 4 loop
                     for Col in 0 .. 259 loop
                        Check
                          (Long_Float (Float64_Access.Get (P, R, Col)),
                           (if R in 1 .. 2
                              and then Col
                                       in 1 .. (if Mode = 1 then 256 else 257)
                            then 31.0
                            else 91.0));
                     end loop;
                  end loop;
               end;
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
            begin
               if Mode >= 5 then
                  B := A;
               end if;
               declare
                  Expected : constant Image := Multiply (A, B);
               begin
                  if Mode = 1 then
                     Multiply (A, B, A);
                     Destination := A;
                  elsif Mode = 2 then
                     Multiply (A, B, B);
                     Destination := B;
                  elsif Mode = 6 then
                     Multiply (A, A, Destination);
                  elsif Mode = 7 then
                     Multiply (A, A, A);
                     Destination := A;
                  elsif Mode = 8 then
                     Multiply (A, B, Destination);
                  else
                     Destination := (if Mode = 4 then B else A);
                     Multiply (A, B, Destination);
                     Equal ((if Mode = 4 then B else A), Expected);
                  end if;
                  Equal (Destination, Expected);
                  declare
                     V  : constant Mat := Values (Destination);
                     AH : constant Mat := Values (Vector (D, True));
                     BH : constant Mat := Values (Vector (D, False));
                  begin
                     for Col in 0 .. 256 loop
                        declare
                           X0 : constant Long_Float :=
                             Long_Float (Float64_Access.Get (AH, 0, Col));
                           Y0 : constant Long_Float :=
                             (if Mode >= 5
                              then X0
                              else
                                Long_Float (Float64_Access.Get (BH, 0, Col)));
                        begin
                           Check
                             (Long_Float (Float64_Access.Get (V, 0, Col)),
                              Saturated (X0 * Y0, D));
                        end;
                     end loop;
                  end;
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
         Aliases (8);
      end Same_Operands;

      procedure Numbers (Test : in out Fixture) is
         pragma Unreferenced (Test);
         type Components is array (0 .. 2) of Long_Float;
      begin
         for D of Depths'(UInt8, Int16, Int32, Float32, Float64) loop
            declare
               X           : constant Components :=
                 (if D = UInt8
                  then (20.0, 3.0, 19.0)
                  elsif D = Int16
                  then (300.0, -300.0, -19.0)
                  else (20000.0, -20000.0, -19.0));
               Y           : constant Components :=
                 (if D = UInt8
                  then (20.0, 10.0, 5.0)
                  elsif D = Int16
                  then (300.0, 300.0, -5.0)
                  else (100.0, 100.0, -5.0));
               A           : Image := New_Image (2, 257, (D, 3));
               B           : Image := New_Image (2, 257, (D, 3));
               Destination : Image := New_Image (2, 257, (D, 3));
               Alias       : constant Image := Destination;
            begin
               Set_To (A, Make_Scalar (X (0), X (1), X (2)));
               Set_To (B, Make_Scalar (Y (0), Y (1), Y (2)));
               Multiply (A, B, Destination);
               for Channel in 0 .. 2 loop
                  declare
                     V : constant Mat := Values (Alias, Channel);
                  begin
                     for R in 0 .. 1 loop
                        for Col in 0 .. 256 loop
                           Check
                             (Long_Float (Float64_Access.Get (V, R, Col)),
                              Saturated (X (Channel) * Y (Channel), D));
                        end loop;
                     end loop;
                  end;
               end loop;
            end;
         end loop;
      end Numbers;

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
                     Typed       : constant Boolean := Mode /= 0;
                     Released    : constant Boolean :=
                       (if Is_UMat
                        then not Typed
                        else
                          Mode /= 1 or else (D = Float16 and then Major < 5));
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
                        Expected                          : Image;
                        Function_Failed, Procedure_Failed : Boolean := False;

                        procedure Check_Empty_HAL_Error
                          (Error : Ada.Exceptions.Exception_Occurrence)
                        is
                           Message : constant String :=
                             Ada.Exceptions.Exception_Message (Error);
                        begin
                           --  OpenCV 5.0's KleidiCV mul8u can reject typed
                           --  empty Mat pointers after native output creation.
                           --  Preserve that existing function behavior; do not
                           --  accept unrelated errors or normalize the helper.
                           Assert
                             (not Is_UMat
                              and then Major = 5
                              and then Mode = 1
                              and then D = UInt8
                              and then Ada.Strings.Fixed.Index
                                         (Message,
                                          "kleidicv_mul8u_with_fallback")
                                       > 0
                              and then Ada.Strings.Fixed.Index
                                         (Message, "returned -1")
                                       > 0,
                              "only observed typed-empty KleidiCV rejection");
                        end Check_Empty_HAL_Error;
                     begin
                        begin
                           Expected := Multiply (A, B);
                        exception
                           when Error : OpenCV_Error =>
                              Check_Empty_HAL_Error (Error);
                              Function_Failed := True;
                        end;
                        begin
                           Multiply (A, B, Destination);
                        exception
                           when Error : OpenCV_Error =>
                              Check_Empty_HAL_Error (Error);
                              Procedure_Failed := True;
                        end;
                        Assert
                          (Function_Failed = Procedure_Failed,
                           "empty native success/error parity");
                        Assert
                          (Is_Empty (Expected) and then Is_Empty (Destination),
                           "both APIs empty");
                        Assert
                          (Shape (Destination)'Length
                           = (if Released and then Major >= 5 then 0 else 2),
                           "native dimension count after release/create");
                        if Shape (Destination)'Length = 2 then
                           Assert (Shape (Destination) = (0, 0), "zero shape");
                        end if;
                        Assert
                          (Depth (Destination)
                           = (if Released then Int16 else D)
                           and then Channels (Destination)
                                    = (if Released then 2 else Ch),
                           "old type survives release, create takes type");
                        if Function_Failed then
                           Assert
                             (Is_Empty (Expected),
                              "failed function retains no result storage");
                        elsif Released then
                           Assert
                             (Shape (Expected)'Length = 0
                              and then Depth (Expected) = UInt8
                              and then Channels (Expected) = 1,
                              "fresh function release default metadata");
                        else
                           Assert
                             (Shape (Destination) = Shape (Expected)
                              and then Depth (Destination) = Depth (Expected)
                              and then Channels (Destination)
                                       = Channels (Expected),
                              "empty function parity");
                        end if;
                     end;
                     for Channel in 0 .. 1 loop
                        declare
                           V : constant Mat := Values (Alias, Channel);
                        begin
                           for R in 0 .. 1 loop
                              for Col in 0 .. 2 loop
                                 Check
                                   (Long_Float
                                      (Float64_Access.Get (V, R, Col)),
                                    (if Channel = 0 then 91.0 else 92.0));
                              end loop;
                           end loop;
                        end;
                     end loop;
                     Set_To (Alias, Make_Scalar (33.0, 34.0));
                     Assert (Is_Empty (Destination), "old alias independent");
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
                  Multiply ((if Mode = 5 then Volume else A), B, Destination);
               end Attempt;
               procedure Function_Attempt is
                  Unused : constant Image :=
                    Multiply ((if Mode = 5 then Volume else A), B);
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
                  and then Depth (Destination) = Float32
                  and then Channels (Destination) = 1,
                  "pre-native metadata unchanged");
               All_Values (Destination, 91.0);
               All_Values (Alias, 91.0);
            end;
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
      Before      : constant Dimension_Array := View.Shape;
      Source      : Mat := Create (View.Rows, View.Columns, (UInt8, 1));
      Other       : Mat := Create (1, 2, (Float32, 1));
      Destination : Mat;
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
      for Mismatch in Boolean loop
         declare
            procedure Attempt is
            begin
               Multiply
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
         Multiply
           ((if Left_View then View else Source),
            (if Left_View then Source else View),
            Destination);
         for R in 0 .. View.Rows - 1 loop
            for Col in 0 .. View.Columns - 1 loop
               Assert
                 (UInt8_Access.Get (Destination, R, Col) = 185,
                  "temporary Left/Right source permitted");
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
      Result.Add_Test (Caller.Create (Prefix & "whole reuse", Whole));
      Result.Add_Test (Caller.Create (Prefix & "Region reuse", Interior));
      Result.Add_Test
        (Caller.Create (Prefix & "mismatch detachment", Reallocate));
      Result.Add_Test (Caller.Create (Prefix & "into Left", Into_Left));
      Result.Add_Test (Caller.Create (Prefix & "into Right", Into_Right));
      Result.Add_Test (Caller.Create (Prefix & "shallow aliases", Shallow));
      Result.Add_Test (Caller.Create (Prefix & "A*A", Same_Operands));
      Result.Add_Test (Caller.Create (Prefix & "integer/C3", Numbers));
      Result.Add_Test (Caller.Create (Prefix & "empty parity", Empty));
      Result.Add_Test
        (Caller.Create (Prefix & "operand failures/N-D", Failures));
   end Register;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Register
        ("Multiply destination Mat ",
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
        ("Multiply destination UMat ",
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
        (Caller.Create ("Multiply temporary external", External'Access));
      Result.Add_Test
        (Caller.Create ("Multiply temporary selected", Selected'Access));
      Result.Add_Test
        (Caller.Create ("Multiply raw Mat", Raw_ABI.Mat_Check'Access));
      Result.Add_Test
        (Caller.Create ("Multiply raw UMat", Raw_ABI.UMat_Check'Access));
      Result.Add_Test
        (Caller.Create ("Multiply UMat CPU fallback", UMat_CPU'Access));
      return Result'Access;
   end Suite;
end Multiply_Destination_Tests;
