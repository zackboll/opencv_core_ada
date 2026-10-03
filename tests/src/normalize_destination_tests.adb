with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.UInt8_Mat_View;
with Normalize_Destination_Tests.Raw_ABI;

package body Normalize_Destination_Tests is
   use OpenCV;
   use OpenCV.Core;
   use Mat_Test_Support;
   use AUnit.Assertions;
   use type Float32_Value;
   use type UInt8_Value;
   use type Int16_Value;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;
   type Normalize_Kind_Array is array (Positive range <>) of Normalize_Kind;

   function To_Long_Float (Value : Float16_Value) return Long_Float
   is (Long_Float (To_Float32 (Value)));

   function Identity (Self : Mat) return Mat
   is (Self);

   procedure Check (Actual, Expected : Long_Float; Message : String) is
   begin
      Assert (Approximately_Equal (Actual, Expected, 0.000_01), Message);
   end Check;

   --  Transfers are test setup/observation only, never production staging.
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
        procedure Normalize
          (Self        : Image;
           Destination : in out Image;
           Kind        : Normalize_Kind := L2;
           Alpha       : Long_Float := 1.0;
           Beta        : Long_Float := 0.0) is <>;
      with
        function Normalize
          (Self  : Image;
           Kind  : Normalize_Kind := L2;
           Alpha : Long_Float := 1.0;
           Beta  : Long_Float := 0.0) return Image is <>;
      with function Region (Self : Image; Area : Rect) return Image is <>;
      with procedure Set_To (Self : in out Image; Value : Scalar) is <>;
      with function Shape (Self : Image) return Dimension_Array is <>;
      with function Depth (Self : Image) return Depth_Type is <>;
      with function Channels (Self : Image) return Channel_Count is <>;
      with function Is_Empty (Self : Image) return Boolean is <>;
      with function Locate_Region (Self : Image) return Region_Location is <>;
      Is_UMat : Boolean;
   package Cases is
      procedure Kinds (Test : in out Fixture);
      procedure Whole (Test : in out Fixture);
      procedure Interior (Test : in out Fixture);
      procedure Reallocate (Test : in out Fixture);
      procedure Integer_Values (Test : in out Fixture);
      procedure Multichannel (Test : in out Fixture);
      procedure Zero_Constant (Test : in out Fixture);
      procedure Self_Normalization (Test : in out Fixture);
      procedure Shallow_Aliases (Test : in out Fixture);
      procedure ND (Test : in out Fixture);
      procedure Empty (Test : in out Fixture);
      procedure Half (Test : in out Fixture);
   end Cases;

   package body Cases is
      function Pixel (Self : Image; R, Col : Natural) return Long_Float
      is (Long_Float (Float32_Access.Get (Observe (Self), R, Col)));

      procedure Kinds (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Host                : Mat := Create (1, 3, (Float32, 1));
         Source, Destination : Image;
      begin
         Float32_Access.Set (Host, 0, 0, -3.0);
         Float32_Access.Set (Host, 0, 1, 0.0);
         Float32_Access.Set (Host, 0, 2, 4.0);
         Source := From_Mat (Host);
         for Kind in Normalize_Kind loop
            Normalize (Source, Destination, Kind, 10.0, 2.0);
            case Kind is
               when L1       =>
                  Check (Pixel (Destination, 0, 0), -30.0 / 7.0, "L1 abs");
                  Check
                    (Pixel (Destination, 0, 2), 40.0 / 7.0, "L1 beta ignored");

               when L2       =>
                  Check (Pixel (Destination, 0, 0), -6.0, "L2 negative");
                  Check (Pixel (Destination, 0, 2), 8.0, "L2 beta ignored");

               when Infinity =>
                  Check (Pixel (Destination, 0, 0), -7.5, "Infinity abs");
                  Check (Pixel (Destination, 0, 2), 10.0, "Infinity target");

               when Min_Max  =>
                  Check
                    (Pixel (Destination, 0, 0), 2.0, "reversed bounds min");
                  Check (Pixel (Destination, 0, 1), 38.0 / 7.0, "scale/shift");
                  Check
                    (Pixel (Destination, 0, 2), 10.0, "reversed bounds max");
            end case;
         end loop;
      end Kinds;

      procedure Whole (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Host        : Mat := Create (1, 2, (Float32, 1));
         Source      : Image;
         Destination : Image := New_Image (1, 2, (Float32, 1));
         Alias       : Image := Destination;
      begin
         Float32_Access.Set (Host, 0, 0, 3.0);
         Float32_Access.Set (Host, 0, 1, 4.0);
         Source := From_Mat (Host);
         Normalize (Source, Destination, L2, 10.0);
         Check (Pixel (Alias, 0, 0), 6.0, "whole alias sees first");
         Check (Pixel (Alias, 0, 1), 8.0, "whole alias sees second");
         Set_To (Alias, Make_Scalar (17.0));
         Check (Pixel (Destination, 0, 1), 17.0, "alias still attached");
         Set_To (Destination, Make_Scalar (19.0));
         Check (Pixel (Alias, 0, 0), 19.0, "destination still attached");
         Check (Pixel (Source, 0, 0), 3.0, "ordinary source unchanged");
      end Whole;

      procedure Interior (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Host        : Mat := Create (2, 3, (Float32, 1));
         Parent      : Image := New_Image (5, 7, (Float32, 1));
         Destination : Image := Region (Parent, (2, 1, 3, 2));
         Alias       : Image := Destination;
         Geometry    : constant Region_Location := Locate_Region (Destination);
         Source      : Image;
      begin
         Set_To (Parent, Make_Scalar (91.0));
         for R in 0 .. 1 loop
            for Col in 0 .. 2 loop
               Float32_Access.Set (Host, R, Col, Float32_Value (R * 3 + Col));
            end loop;
         end loop;
         Source := From_Mat (Host);
         Normalize (Source, Destination, Min_Max, -2.0, 8.0);
         Assert
           (Shape (Destination) = (2, 3)
            and then Locate_Region (Destination) = Geometry,
            "Region geometry retained");
         for R in 0 .. 4 loop
            for Col in 0 .. 6 loop
               if R in 1 .. 2 and then Col in 2 .. 4 then
                  Check
                    (Pixel (Parent, R, Col),
                     Long_Float (((R - 1) * 3 + Col - 2) * 2) - 2.0,
                     "only intended parent Region normalized");
               else
                  Check (Pixel (Parent, R, Col), 91.0, "every guard intact");
               end if;
            end loop;
         end loop;
         Check (Pixel (Alias, 1, 2), 8.0, "Region alias sees normalization");
         Set_To (Alias, Make_Scalar (23.0));
         Check (Pixel (Destination, 0, 0), 23.0, "alias reaches destination");
         Check (Pixel (Parent, 1, 2), 23.0, "alias reaches parent");
         Set_To (Destination, Make_Scalar (25.0));
         Check (Pixel (Parent, 2, 4), 25.0, "destination reaches parent");
         Check (Pixel (Alias, 1, 2), 25.0, "destination reaches alias");
      end Interior;

      procedure Reallocate (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Source : Image := New_Image (2, 3, (Float32, 1));
      begin
         Set_To (Source, Make_Scalar (4.0));
         for Mismatch in 1 .. 3 loop
            declare
               Format      : constant Mat_Type :=
                 (if Mismatch = 2
                  then (Int16, 1)
                  elsif Mismatch = 3
                  then (Float32, 2)
                  else (Float32, 1));
               Parent      : Image := New_Image (5, 7, Format);
               Destination : Image :=
                 Region (Parent, (2, 1, (if Mismatch = 1 then 2 else 3), 2));
               Alias       : Image := Destination;
               Old_Shape   : constant Dimension_Array := Shape (Alias);
            begin
               Set_To (Parent, Make_Scalar (91.0, 92.0));
               Normalize (Source, Destination, Infinity, 8.0);
               Assert
                 (Shape (Destination) = (2, 3)
                  and then Depth (Destination) = Float32
                  and then Channels (Destination) = 1,
                  "shape/depth/channel mismatch reallocates source type");
               Check
                 (Pixel (Destination, 1, 2), 8.0, "new normalized storage");
               declare
                  Before : constant Mat := Observe (Parent);
               begin
                  for R in 0 .. 4 loop
                     for Col in 0 .. 6 loop
                        if Mismatch = 2 then
                           Assert
                             (Int16_Access.Get (Before, R, Col) = 91,
                              "every old integer parent pixel intact");
                        elsif Mismatch = 1 then
                           Check
                             (Long_Float (Float32_Access.Get (Before, R, Col)),
                              91.0,
                              "every parent guard intact");
                        else
                           for Channel in 0 .. 1 loop
                              Check
                                (Long_Float
                                   (Float32_Access.Get
                                      (Before.Extract_Channel (Channel),
                                       R,
                                       Col)),
                                 (if Channel = 0 then 91.0 else 92.0),
                                 "every old multichannel parent pixel intact");
                           end loop;
                        end if;
                     end loop;
                  end loop;
               end;
               Assert (Shape (Alias) = Old_Shape, "old alias layout retained");
               Set_To (Alias, Make_Scalar (37.0, 38.0));
               declare
                  Patch       : constant Mat :=
                    Observe
                      (Region
                         (Parent, (2, 1, (if Mismatch = 1 then 2 else 3), 2)));
                  Float_Patch : constant Mat := Patch.Convert_To (Float32);
                  Minima      : constant Scalar := Float_Patch.Sum;
               begin
                  Check
                    (Minima.Component_0,
                     37.0 * Long_Float (2 * Old_Shape (2)),
                     "old alias still reaches old parent");
                  if Mismatch = 3 then
                     Check
                       (Minima.Component_1,
                        38.0 * 6.0,
                        "old second channel shared");
                  end if;
               end;
               Check (Pixel (Destination, 0, 0), 8.0, "new storage detached");
               Set_To (Destination, Make_Scalar (41.0));
               Check (Pixel (Destination, 1, 2), 41.0, "new storage writable");
               declare
                  Old : constant Mat := Observe (Alias).Convert_To (Float32);
               begin
                  Check
                    (Old.Sum.Component_0,
                     37.0 * Long_Float (2 * Old_Shape (2)),
                     "new destination writes do not reach old allocation");
               end;
            end;
         end loop;
      end Reallocate;

      procedure Integer_Values (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Host                : Mat := Create (1, 3, (UInt8, 1));
         Source, Destination : Image;
      begin
         UInt8_Access.Set (Host, 0, 0, 0);
         UInt8_Access.Set (Host, 0, 1, 5);
         UInt8_Access.Set (Host, 0, 2, 10);
         Source := From_Mat (Host);
         Normalize (Source, Destination, Min_Max, -100.0, 400.0);
         declare
            Values : constant Mat := Observe (Destination);
         begin
            Assert
              (UInt8_Access.Get (Values, 0, 0) = 0
               and then UInt8_Access.Get (Values, 0, 1) = 150
               and then UInt8_Access.Get (Values, 0, 2) = 255,
               "integer depth retained with native saturation");
         end;
      end Integer_Values;

      procedure Multichannel (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Source      : Image := New_Image (2, 3, (Float32, 3));
         Destination : Image := New_Image (2, 3, (Float32, 3));
         Alias       : constant Image := Destination;
      begin
         Set_To (Source, Make_Scalar (-3.0, 0.0, 4.0));
         Normalize (Source, Destination, Infinity, 8.0);
         declare
            Values : constant Scalar := Observe (Alias).Sum;
         begin
            Check (Values.Component_0, -36.0, "channels reduced together");
            Check (Values.Component_1, 0.0, "zero channel");
            Check (Values.Component_2, 48.0, "channel alias reuse");
         end;
         Normalize (Source, Destination, Min_Max, 2.0, 9.0);
         declare
            Values : constant Scalar := Observe (Alias).Sum;
         begin
            Check
              (Values.Component_0, 12.0, "unmasked multichannel MinMax min");
            Check
              (Values.Component_1, 30.0, "unmasked multichannel MinMax shift");
            Check
              (Values.Component_2, 54.0, "unmasked multichannel MinMax max");
         end;
      end Multichannel;

      procedure Zero_Constant (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Source      : Image := New_Image (2, 3, (Float32, 1));
         Destination : Image;
      begin
         Set_To (Source, Make_Scalar (0.0));
         for Kind of Normalize_Kind_Array'(L1, L2, Infinity) loop
            Normalize (Source, Destination, Kind, 10.0, 99.0);
            Check (Pixel (Destination, 1, 2), 0.0, "zero norm stays zero");
         end loop;
         Set_To (Source, Make_Scalar (-7.0));
         Normalize (Source, Destination, Min_Max, 9.0, 2.0);
         Check
           (Pixel (Destination, 1, 2), 2.0, "constant maps to lower bound");
         Normalize (Source, Destination, Min_Max, 5.0, 5.0);
         Check (Pixel (Destination, 0, 0), 5.0, "equal bounds give constant");
         Set_To (Source, Make_Scalar (4.0));
         Normalize (Source, Destination);
         Check
           (Pixel (Destination, 0, 0),
            1.0 / 2.449_489_743,
            "default kind and coefficients");
      end Zero_Constant;

      procedure In_Place (Aliased_Headers : Boolean) is
         Host                : Mat := Create (1, 257, (Float32, 1));
         Source, Destination : Image;
      begin
         for Kind of Normalize_Kind_Array'(L1, Min_Max) loop
            for Col in 0 .. 256 loop
               Float32_Access.Set (Host, 0, Col, Float32_Value (Col) - 100.0);
            end loop;
            Source := From_Mat (Host);
            if Aliased_Headers then
               Destination := Source;
               Normalize (Source, Destination, Kind, 100.0, 2.0);
            else
               Normalize (Source, Source, Kind, 100.0, 2.0);
            end if;
            for Col in 0 .. 256 loop
               Check
                 (Pixel (Source, 0, Col),
                  (if Kind = L1
                   then Long_Float (Col - 100) * 100.0 / 17_296.0
                   else 2.0 + Long_Float (Col) * 98.0 / 256.0),
                  "in-place numerical vector/tail result");
            end loop;
         end loop;
      end In_Place;

      procedure Self_Normalization (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         In_Place (False);
      end Self_Normalization;

      procedure Shallow_Aliases (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         In_Place (True);
      end Shallow_Aliases;

      procedure ND (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Host        : Mat := Create (Dimension_Array'(2, 3, 4), (Float32, 1));
         Source      : Image;
         Destination : Image := New_ND ((2, 3, 4), (Float32, 1));
         Alias       : Image := Destination;
      begin
         for A in Size_Coordinate range 0 .. 1 loop
            for B in Size_Coordinate range 0 .. 2 loop
               for C in Size_Coordinate range 0 .. 3 loop
                  Float32_Access.Set
                    (Host,
                     Index_Array'(A, B, C),
                     Float32_Value (A * 12 + B * 4 + C));
               end loop;
            end loop;
         end loop;
         Source := From_Mat (Host);
         for Kind of Normalize_Kind_Array'(Infinity, Min_Max) loop
            Normalize (Source, Destination, Kind, 46.0, 0.0);
            Assert
              (Shape (Destination) = (2, 3, 4), "real N-D shape retained");
            declare
               Values : constant Mat := Observe (Alias);
            begin
               for A in Size_Coordinate range 0 .. 1 loop
                  for B in Size_Coordinate range 0 .. 2 loop
                     for C in Size_Coordinate range 0 .. 3 loop
                        Check
                          (Long_Float
                             (Float32_Access.Get
                                (Values, Index_Array'(A, B, C))),
                           Long_Float ((A * 12 + B * 4 + C) * 2),
                           "N-D numerical result through preexisting alias");
                     end loop;
                  end loop;
               end loop;
            end;
         end loop;
         Set_To (Alias, Make_Scalar (17.0));
         Check
           (Long_Float
              (Float32_Access.Get
                 (Observe (Destination), Index_Array'(1, 2, 3))),
            17.0,
            "N-D reuse remains attached");
      end ND;

      procedure Empty (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for Typed in Boolean loop
            for Kind in Normalize_Kind loop
               declare
                  Source      : Image;
                  Destination : Image := New_Image (2, 3, (Int16, 1));
                  Alias       : Image := Destination;
               begin
                  if Typed then
                     Source := New_Image (0, 0, (Float32, 3));
                  end if;
                  Set_To (Alias, Make_Scalar (91.0));
                  Normalize (Source, Destination, Kind);
                  Assert (Is_Empty (Destination), "empty releases storage");
                  if Is_UMat
                    or else Module_Bridge_Probe.OpenCV_Major_Version < 5
                  then
                     Assert
                       (Depth (Destination) = Int16
                        and then Channels (Destination) = 1,
                        "release retains old type metadata");
                  else
                     Assert
                       (Depth (Destination)
                        = (if Typed then Float32 else UInt8)
                        and then Channels (Destination)
                                 = (if Typed then 3 else 1),
                        "5.0 Mat recreates source empty type");
                  end if;
                  if Is_UMat
                    and then Module_Bridge_Probe.OpenCV_Major_Version >= 5
                  then
                     Assert
                       (Shape (Destination)'Length = 0,
                        "5.0 UMat release resets dimension count");
                  else
                     Assert (Shape (Destination) = (0, 0), "empty geometry");
                  end if;
                  Assert
                    (Int16_Access.Get (Observe (Alias), 1, 2) = 91,
                     "old alias pixels survive release");
               end;
            end loop;
         end loop;
      end Empty;

      procedure Native_Half (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Host   : Mat := Create (1, 2, (Float16, 1));
         Source : Image;
      begin
         Float16_Access.Set (Host, 0, 0, To_Float16 (3.0));
         Float16_Access.Set (Host, 0, 1, To_Float16 (4.0));
         Source := From_Mat (Host);
         for Empty_Source in Boolean loop
            if Empty_Source then
               Source := New_Image (0, 0, (Float16, 1));
            end if;
            for Kind in Normalize_Kind loop
               declare
                  Destination     : Image :=
                    New_Image
                      (1, 2, ((if Empty_Source then Int16 else Float16), 1));
                  Alias           : Image := Destination;
                  Function_Result : Image;
                  procedure Attempt is
                  begin
                     Normalize (Source, Destination, Kind, 10.0, 2.0);
                  end Attempt;
                  procedure Function_Attempt is
                  begin
                     Function_Result := Normalize (Source, Kind, 10.0, 2.0);
                  end Function_Attempt;
               begin
                  Set_To (Alias, Make_Scalar (91.0));
                  if Kind = Min_Max
                    and then Module_Bridge_Probe.OpenCV_Major_Version < 5
                  then
                     Assert_Raises_OpenCV_Error
                       (Attempt'Access, "native 4.x half MinMax");
                     Assert_Raises_OpenCV_Error
                       (Function_Attempt'Access, "same function failure");
                  else
                     Attempt;
                     Function_Attempt;
                     if Empty_Source then
                        Assert (Is_Empty (Destination), "half empty released");
                        Assert
                          (Depth (Destination)
                           = (if (Is_UMat and then Kind /= Min_Max)
                                or else Module_Bridge_Probe
                                          .OpenCV_Major_Version
                                        < 5
                              then Int16
                              else Float16)
                           and then Channels (Destination) = 1,
                           "half empty metadata from native/helper release");
                        if Is_UMat
                          and then Kind /= Min_Max
                          and then Module_Bridge_Probe.OpenCV_Major_Version
                                   >= 5
                        then
                           Assert
                             (Shape (Destination)'Length = 0,
                              "5.0 half UMat helper release geometry");
                        else
                           Assert
                             (Shape (Destination) = (0, 0),
                              "native half empty conversion geometry");
                        end if;
                        Assert
                          (Int16_Access.Get (Observe (Alias), 0, 1) = 91,
                           "half empty old allocation survives");
                     else
                        Assert
                          (Depth (Destination) = Float16,
                           "no half widening policy");
                        for Col in 0 .. 1 loop
                           Check
                             (To_Long_Float
                                (Float16_Access.Get (Observe (Alias), 0, Col)),
                              To_Long_Float
                                (Float16_Access.Get
                                   (Observe (Function_Result), 0, Col)),
                              "half reuse exactly matches existing function");
                        end loop;
                        if Kind = L2 then
                           Check
                             (To_Long_Float
                                (Float16_Access.Get (Observe (Alias), 0, 1)),
                              8.0,
                              "native half L2");
                        end if;
                     end if;
                  end if;
               end;
            end loop;
         end loop;
      end Native_Half;

      procedure Half (Test : in out Fixture) is
         procedure Run is
         begin
            Native_Half (Test);
         end Run;
      begin
         --  Empty half MinMax intentionally stays native; avoid entering the
         --  known upstream empty OpenCL hazard in this isolated CPU audit.
         Raw_ABI.With_OpenCL_Disabled (Run'Access);
      end Half;
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

   procedure UMat_CPU (Test : in out Fixture) is
      procedure Run is
      begin
         UMat_Cases.Whole (Test);
         UMat_Cases.Interior (Test);
         UMat_Cases.Self_Normalization (Test);
         UMat_Cases.Shallow_Aliases (Test);
         UMat_Cases.Empty (Test);
      end Run;
   begin
      Raw_ABI.With_OpenCL_Disabled (Run'Access);
   end UMat_CPU;

   procedure Temporary (View : in out Mat) is
      Source      : Mat := Create (View.Rows, View.Columns, (UInt8, 1));
      Other       : constant Mat := Create (1, 2, (Float32, 1));
      Destination : Mat;
      Before      : constant Dimension_Array := View.Shape;
      procedure Matching is
      begin
         Source.Normalize (View, Infinity, 8.0);
      end Matching;
      procedure Mismatch is
      begin
         Other.Normalize (View);
      end Mismatch;
   begin
      Source.Set_To (Make_Scalar (4.0));
      Assert_Raises_OpenCV_Error (Matching'Access, "compatible temporary");
      Assert_Raises_OpenCV_Error (Mismatch'Access, "incompatible temporary");
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
      View.Normalize (Destination, Infinity, 74.0);
      Assert
        (UInt8_Access.Get (Destination, 0, 0) = 74,
         "temporary source remains permitted");
   end Temporary;

   procedure External (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data   : aliased UInt8_Mat_View.Buffer_Array := (0 .. 19 => 37);
      Before : constant UInt8_Mat_View.Buffer_Array := Data;
      use type UInt8_Mat_View.Buffer_Array;
   begin
      UInt8_Mat_View.With_Writable_Strided_Mat_View
        (Data, 4, 3, 5, Temporary'Access);
      Assert (Data = Before, "external storage and padding intact");
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
      Assert
        (UInt8_Access.Get (Volume, Index_Array'(1, 2, 3)) = 37,
         "selected source/destination storage intact");
   end Selected;

   procedure Register
     (Prefix : String;
      Kinds,
      Whole,
      Interior,
      Reallocate,
      Integer_Values,
      Multichannel,
      Zero_Constant,
      Self_Normalization,
      Shallow_Aliases,
      ND,
      Empty,
      Half   : Caller.Test_Method) is
   begin
      Result.Add_Test (Caller.Create (Prefix & "kinds", Kinds));
      Result.Add_Test (Caller.Create (Prefix & "whole reuse", Whole));
      Result.Add_Test
        (Caller.Create (Prefix & "Region guards/reuse", Interior));
      Result.Add_Test
        (Caller.Create (Prefix & "mismatch detachment", Reallocate));
      Result.Add_Test
        (Caller.Create (Prefix & "integer saturation", Integer_Values));
      Result.Add_Test (Caller.Create (Prefix & "multichannel", Multichannel));
      Result.Add_Test
        (Caller.Create (Prefix & "zero/constant", Zero_Constant));
      Result.Add_Test
        (Caller.Create (Prefix & "exact self tail", Self_Normalization));
      Result.Add_Test
        (Caller.Create (Prefix & "shallow aliases", Shallow_Aliases));
      Result.Add_Test (Caller.Create (Prefix & "N-D reuse", ND));
      Result.Add_Test (Caller.Create (Prefix & "empty metadata", Empty));
      Result.Add_Test (Caller.Create (Prefix & "Float16 compatibility", Half));
   end Register;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Register
        ("Normalize destination Mat ",
         Mat_Cases.Kinds'Access,
         Mat_Cases.Whole'Access,
         Mat_Cases.Interior'Access,
         Mat_Cases.Reallocate'Access,
         Mat_Cases.Integer_Values'Access,
         Mat_Cases.Multichannel'Access,
         Mat_Cases.Zero_Constant'Access,
         Mat_Cases.Self_Normalization'Access,
         Mat_Cases.Shallow_Aliases'Access,
         Mat_Cases.ND'Access,
         Mat_Cases.Empty'Access,
         Mat_Cases.Half'Access);
      Register
        ("Normalize destination UMat ",
         UMat_Cases.Kinds'Access,
         UMat_Cases.Whole'Access,
         UMat_Cases.Interior'Access,
         UMat_Cases.Reallocate'Access,
         UMat_Cases.Integer_Values'Access,
         UMat_Cases.Multichannel'Access,
         UMat_Cases.Zero_Constant'Access,
         UMat_Cases.Self_Normalization'Access,
         UMat_Cases.Shallow_Aliases'Access,
         UMat_Cases.ND'Access,
         UMat_Cases.Empty'Access,
         UMat_Cases.Half'Access);
      Result.Add_Test
        (Caller.Create ("Normalize temporary external", External'Access));
      Result.Add_Test
        (Caller.Create ("Normalize temporary selected", Selected'Access));
      Result.Add_Test
        (Caller.Create ("Normalize Mat raw ABI", Raw_ABI.Mat_Check'Access));
      Result.Add_Test
        (Caller.Create ("Normalize UMat raw ABI", Raw_ABI.UMat_Check'Access));
      Result.Add_Test
        (Caller.Create
           ("Normalize UMat explicit CPU fallback", UMat_CPU'Access));
      return Result'Access;
   end Suite;
end Normalize_Destination_Tests;
