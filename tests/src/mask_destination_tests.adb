with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;
with Mask_Destination_Tests.Raw_ABI;

package body Mask_Destination_Tests is
   use OpenCV;
   use OpenCV.Core;
   use AUnit.Assertions;
   use type UInt8_Value;
   use type Float64_Value;
   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result        : aliased AUnit.Test_Suites.Test_Suite;
   type Depth_List is array (Positive range <>) of Depth_Type;
   Tested_Depths : constant Depth_List :=
     (UInt8, Int16, Int32, Float32, Float64, Float16);
   function Identity (Self : Mat) return Mat
   is (Self);
   function Compare_Expected
     (A, B : Integer; Kind : Comparison_Kind) return UInt8_Value
   is
      Selected : constant Boolean :=
        (case Kind is
           when Equal            => A = B,
           when Not_Equal        => A /= B,
           when Less_Than        => A < B,
           when Less_Or_Equal    => A <= B,
           when Greater_Than     => A > B,
           when Greater_Or_Equal => A >= B);
   begin
      return (if Selected then 255 else 0);
   end Compare_Expected;
   function Witness (Column : Natural; D : Depth_Type) return Integer
   is (if D = Int32 and then Column mod 13 = 0
       then Integer'Last
       elsif D = Int32 and then Column mod 13 = 1
       then Integer'First
       elsif D = UInt8
       then Integer (Column mod 7) + 1
       else Integer (Column mod 7) - 3);
   function Other (Column : Natural; D : Depth_Type) return Integer
   is (if D = Int32 and then Column mod 13 = 0
       then Integer'Last - 1
       elsif D = Int32 and then Column mod 13 = 1
       then Integer'First + 1
       else Witness (Column, D) + Integer (Column mod 3) - 1);
   procedure Mask_Parity (Actual, Expected : Mat) is
   begin
      Assert
        (Actual.Shape = Expected.Shape
         and then Actual.Depth = UInt8
         and then Actual.Channels = 1,
         "UInt8 C1 mask shape parity");
      if Actual.Dimension_Count = 3 then
         for I in Size_Coordinate range 0 .. 1 loop
            for J in Size_Coordinate range 0 .. 2 loop
               for K in Size_Coordinate range 0 .. 4 loop
                  declare
                     V : constant UInt8_Value :=
                       UInt8_Access.Get (Actual, (I, J, K));
                  begin
                     Assert
                       (V = UInt8_Access.Get (Expected, (I, J, K))
                        and then V in 0 | 255,
                        "exact N-D mask byte");
                  end;
               end loop;
            end loop;
         end loop;
      else
         for R in 0 .. Actual.Rows - 1 loop
            for C in 0 .. Actual.Columns - 1 loop
               declare
                  V : constant UInt8_Value := UInt8_Access.Get (Actual, R, C);
               begin
                  Assert
                    (V = UInt8_Access.Get (Expected, R, C)
                     and then V in 0 | 255,
                     "exact 0/255 mask byte");
               end;
            end loop;
         end loop;
      end if;
   end Mask_Parity;
   procedure Constant_Bytes (Self : Mat; Value : UInt8_Value) is
   begin
      Assert (Self.Depth = UInt8 and then Self.Channels = 1, "byte layout");
      for R in 0 .. Self.Rows - 1 loop
         for C in 0 .. Self.Columns - 1 loop
            Assert
              (UInt8_Access.Get (Self, R, C) = Value, "every retained byte");
         end loop;
      end loop;
   end Constant_Bytes;

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
        function Compare
          (Left, Right : Image; Kind : Comparison_Kind) return Image is <>;
      with
        procedure Compare
          (Left, Right : Image;
           Kind        : Comparison_Kind;
           Destination : in out Image) is <>;
      with
        function In_Range (Self : Image; Lower, Upper : Scalar) return Image
        is <>;
      with
        procedure In_Range
          (Self : Image; Lower, Upper : Scalar; Destination : in out Image)
        is <>;
      with procedure Set_To (Self : in out Image; Value : Scalar) is <>;
      with function Region (Self : Image; Area : Rect) return Image is <>;
      with function Locate_Region (Self : Image) return Region_Location is <>;
      with function Shape (Self : Image) return Dimension_Array is <>;
      with function Depth (Self : Image) return Depth_Type is <>;
      with function Channels (Self : Image) return Channel_Count is <>;
      with function Dimension_Count (Self : Image) return Natural is <>;
      with function Is_Empty (Self : Image) return Boolean is <>;
      Is_UMat : Boolean;
   package Cases is
      procedure Compare_Reuse (Test : in out Fixture);
      procedure Compare_Regions (Test : in out Fixture);
      procedure Compare_Numbers (Test : in out Fixture);
      procedure Compare_Boundaries (Test : in out Fixture);
      procedure Range_Reuse (Test : in out Fixture);
      procedure Range_Regions (Test : in out Fixture);
      procedure Range_Numbers (Test : in out Fixture);
      procedure Range_Boundaries (Test : in out Fixture);
      procedure Half (Test : in out Fixture);
      procedure Failures (Test : in out Fixture);
   end Cases;
   package body Cases is
      function Default_Image return Image is
         Empty : Image;
      begin
         return Empty;
      end Default_Image;
      function Input (D : Depth_Type; Right : Boolean := False) return Image is
         H : Mat := Create (1, 257, (Int32, 1));
      begin
         for C in 0 .. 256 loop
            Int32_Access.Set
              (H,
               0,
               C,
               Int32_Value (if Right then Other (C, D) else Witness (C, D)));
         end loop;
         return From_Mat (if D = Int32 then H else H.Convert_To (D));
      end Input;
      procedure Check_Compare
        (Self : Image; D : Depth_Type; Kind : Comparison_Kind)
      is
         H : constant Mat := Observe (Self);
      begin
         Assert
           (Shape (Self) = Dimension_Array'(1, 257)
            and then Depth (Self) = UInt8
            and then Channels (Self) = 1,
            "Compare fixed mask layout");
         for C in 0 .. 256 loop
            Assert
              (UInt8_Access.Get (H, 0, C)
               = Compare_Expected (Witness (C, D), Other (C, D), Kind),
               "comparison "
               & D'Image
               & " "
               & Kind'Image
               & " column"
               & C'Image);
         end loop;
      end Check_Compare;
      procedure Reuse (Range_Operation : Boolean) is
         A     : constant Image := Input (Int16);
         B     : constant Image := Input (Int16, True);
         D     : Image := New_Image (1, 257, (UInt8, 1));
         Alias : Image := D;
         E     : constant Image :=
           (if Range_Operation
            then In_Range (A, Make_Scalar (-1.0), Make_Scalar (1.0))
            else Compare (A, B, Less_Or_Equal));
      begin
         Set_To (D, Make_Scalar (91.0));
         if Range_Operation then
            In_Range (A, Make_Scalar (-1.0), Make_Scalar (1.0), D);
         else
            Compare (A, B, Less_Or_Equal, D);
         end if;
         Mask_Parity (Observe (D), Observe (E));
         Mask_Parity (Observe (Alias), Observe (E));
         if Range_Operation then
            declare
               H : constant Mat := Observe (D);
            begin
               for C in 0 .. 256 loop
                  Assert
                    (UInt8_Access.Get (H, 0, C)
                     = (if Witness (C, Int16) in -1 .. 1 then 255 else 0),
                     "independent inclusive range byte");
               end loop;
            end;
         else
            Check_Compare (D, Int16, Less_Or_Equal);
         end if;
         Set_To (Alias, Make_Scalar (17.0));
         Constant_Bytes (Observe (D), 17);
         Set_To (D, Make_Scalar (19.0));
         Constant_Bytes (Observe (Alias), 19);
         Assert
           (UInt8_Access.Get (Observe (E), 0, 0) in 0 | 255,
            "function output independent of reused storage");
      end Reuse;
      procedure Compare_Reuse (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         Reuse (False);
      end Compare_Reuse;
      procedure Range_Reuse (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         Reuse (True);
      end Range_Reuse;

      procedure Regions (Range_Operation : Boolean) is
         A : constant Image := Input (UInt8);
         B : constant Image := Input (UInt8, True);
         E : constant Image :=
           (if Range_Operation
            then In_Range (A, Make_Scalar (1.0), Make_Scalar (3.0))
            else Compare (A, B, Equal));
         procedure Execute (D : in out Image) is
         begin
            if Range_Operation then
               In_Range (A, Make_Scalar (1.0), Make_Scalar (3.0), D);
            else
               Compare (A, B, Equal, D);
            end if;
         end Execute;
      begin
         for Mode in 0 .. 3 loop
            declare
               T     : constant Mat_Type :=
                 (case Mode is
                    when 2      => (Int16, 1),
                    when 3      => (UInt8, 3),
                    when others => (UInt8, 1));
               P     : Image := New_Image (3, 260, T);
               D     : Image :=
                 Region (P, (1, 1, (if Mode = 1 then 256 else 257), 1));
               Alias : Image := D;
            begin
               Set_To (P, Make_Scalar (91.0, 91.0, 91.0));
               Execute (D);
               Mask_Parity (Observe (D), Observe (E));
               if Mode = 0 then
                  Assert
                    (Locate_Region (D) = Locate_Region (Alias),
                     "compatible Region location preserved");
                  Mask_Parity (Observe (Alias), Observe (E));
                  declare
                     Parent   : constant Mat := Observe (P);
                     Expected : constant Mat := Observe (E);
                  begin
                     for R in 0 .. 2 loop
                        for C in 0 .. 259 loop
                           Assert
                             (UInt8_Access.Get (Parent, R, C)
                              = (if R = 1 and then C in 1 .. 257
                                 then UInt8_Access.Get (Expected, 0, C - 1)
                                 else 91),
                              "every Parent guard and mask");
                        end loop;
                     end loop;
                  end;
                  Set_To (Alias, Make_Scalar (17.0));
                  Constant_Bytes (Observe (D), 17);
                  Set_To (D, Make_Scalar (19.0));
                  Constant_Bytes (Observe (Alias), 19);
               else
                  declare
                     Old : constant Mat := Observe (P).Convert_To (Float64);
                  begin
                     for Ch in 0 .. Natural (Old.Channels) - 1 loop
                        declare
                           Channel : constant Mat := Old.Extract_Channel (Ch);
                        begin
                           for R in 0 .. 2 loop
                              for C in 0 .. 259 loop
                                 Assert
                                   (Float64_Access.Get (Channel, R, C) = 91.0,
                                    "mismatch old Parent unchanged");
                              end loop;
                           end loop;
                        end;
                     end loop;
                  end;
                  Assert
                    (Depth (Alias) = T.Depth
                     and then Channels (Alias) = T.Channels,
                     "old alias retains old type");
                  Set_To (Alias, Make_Scalar (23.0, 23.0, 23.0));
                  Mask_Parity (Observe (D), Observe (E));
                  Set_To (D, Make_Scalar (29.0));
                  Assert
                    (Float64_Access.Get
                       (Observe (Alias).Extract_Channel (0).Convert_To
                          (Float64),
                        0,
                        0)
                     = 23.0,
                     "mismatch reciprocal detachment");
               end if;
            end;
         end loop;
      end Regions;
      procedure Compare_Regions (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         Regions (False);
      end Compare_Regions;
      procedure Range_Regions (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         Regions (True);
      end Range_Regions;

      procedure Compare_Numbers (Test : in out Fixture) is
         pragma Unreferenced (Test);
         X : Mat := Create (1, 3, (Float64, 1));
         Z : Mat := Create (1, 3, (Float64, 1));
      begin
         for D of Tested_Depths loop
            if D /= Float16
              or else Module_Bridge_Probe.OpenCV_Major_Version >= 5
            then
               for Kind in Comparison_Kind loop
                  declare
                     A    : constant Image := Input (D);
                     B    : constant Image := Input (D, True);
                     Dest : Image := New_Image (1, 257, (UInt8, 1));
                     E    : constant Image := Compare (A, B, Kind);
                  begin
                     Compare (A, B, Kind, Dest);
                     Check_Compare (Dest, D, Kind);
                     Check_Compare (E, D, Kind);
                     Mask_Parity (Observe (Dest), Observe (E));
                  end;
               end loop;
            end if;
         end loop;
         Float64_Access.Set (X, 0, 0, 0.0);
         Float64_Access.Set (X, 0, 1, 1.0);
         Float64_Access.Set (X, 0, 2, -1.0);
         Z.Set_To (Make_Scalar (0.0));
         declare
            Native_Specials : constant Mat := Divide (X, Z);
         begin
            for D of Depth_List'(Float32, Float64) loop
               for Special in 0 .. 4 loop
                  for Kind in Comparison_Kind loop
                     declare
                        H    : Mat := Create (1, 257, (Float64, 1));
                        B    : Image :=
                          From_Mat
                            (Create (1, 257, (Float64, 1)).Convert_To (D));
                        Dest : Image := New_Image (1, 257, (UInt8, 1));
                     begin
                        Set_To (B, Make_Scalar (0.0));
                        H.Set_To (Make_Scalar (0.0));
                        for C in 0 .. 256 loop
                           if Special <= 2 then
                              Raw_ABI.Copy_Special
                                (Native_Specials, Special, H, C);
                           elsif Special = 4 then
                              Float64_Access.Set (H, 0, C, -0.0);
                           end if;
                        end loop;
                        declare
                           A : constant Image := From_Mat (H.Convert_To (D));
                           E : constant Image := Compare (A, B, Kind);
                        begin
                           Compare (A, B, Kind, Dest);
                           Mask_Parity (Observe (Dest), Observe (E));
                        end;
                     end;
                  end loop;
               end loop;
            end loop;
         end;
      end Compare_Numbers;

      procedure Range_Numbers (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Lower : constant Scalar := Make_Scalar (1.0, 11.0, 21.0, 31.0);
         Upper : constant Scalar := Make_Scalar (3.0, 13.0, 23.0, 33.0);
      begin
         for D of Tested_Depths loop
            if D /= Float16
              or else Module_Bridge_Probe.OpenCV_Major_Version >= 5
            then
               for Ch in Channel_Count range 1 .. 4 loop
                  declare
                     H : Mat := Create (1, 257, (Int32, Ch));
                     E : Mat := Create (1, 257, (UInt8, 1));
                  begin
                     for Channel in 0 .. Natural (Ch) - 1 loop
                        declare
                           Plane : Mat := Create (1, 257, (Int32, 1));
                        begin
                           for C in 0 .. 256 loop
                              Int32_Access.Set
                                (Plane,
                                 0,
                                 C,
                                 Int32_Value
                                   (10
                                    * Channel
                                    + 1
                                    + C mod 3
                                    + (if C mod 7 = Channel + 1
                                       then -4
                                       elsif C mod 7 = 5
                                       then 4
                                       else 0)));
                           end loop;
                           H.Insert_Channel (Plane, Channel);
                        end;
                     end loop;
                     for C in 0 .. 256 loop
                        declare
                           Selected : Boolean := True;
                        begin
                           for Channel in 0 .. Natural (Ch) - 1 loop
                              Selected :=
                                Selected
                                and then C mod 7 /= Channel + 1
                                and then C mod 7 /= 5;
                           end loop;
                           UInt8_Access.Set
                             (E, 0, C, (if Selected then 255 else 0));
                        end;
                     end loop;
                     declare
                        A     : constant Image :=
                          From_Mat (if D = Int32 then H else H.Convert_To (D));
                        Fresh : constant Image := In_Range (A, Lower, Upper);
                        Dest  : Image := New_Image (1, 257, (UInt8, 1));
                     begin
                        In_Range (A, Lower, Upper, Dest);
                        Mask_Parity (Observe (Dest), E);
                        Mask_Parity (Observe (Fresh), E);
                     end;
                  end;
               end loop;
            end if;
         end loop;
         for D of Depth_List'(UInt8, Int16, Int32) loop
            declare
               A    : constant Image := Input (D);
               Dest : Image := New_Image (1, 257, (UInt8, 1));
               E    : constant Image :=
                 In_Range (A, Make_Scalar (1.2), Make_Scalar (2.8));
               H    : Mat;
            begin
               In_Range (A, Make_Scalar (1.2), Make_Scalar (2.8), Dest);
               Mask_Parity (Observe (Dest), Observe (E));
               H := Observe (Dest);
               for C in 0 .. 256 loop
                  Assert
                    (UInt8_Access.Get (H, 0, C)
                     = (if Witness (C, D) in 1 .. 3 then 255 else 0),
                     "native integer scalar conversion rounds 1.2/2.8");
               end loop;
            end;
         end loop;
      end Range_Numbers;

      procedure Compare_Boundaries (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depth_List'(UInt8, Int16, Float32) loop
            for Mode in 0 .. 3 loop
               --  Type-changing exact UMat aliases differ by backend and
               --  remain research-only, outside the supported contract.
               if not Is_UMat or else D = UInt8 or else Mode >= 2 then
                  declare
                     A    : Image := Input (D);
                     B    : Image := Input (D, True);
                     Dest : Image := (if Mode = 2 then A else B);
                  begin
                     if Mode = 0 then
                        Compare (A, B, Equal, A);
                     elsif Mode = 1 then
                        Compare (A, B, Equal, B);
                     else
                        Compare (A, B, Equal, Dest);
                     end if;
                     Check_Compare
                       ((if Mode = 0 then A elsif Mode = 1 then B else Dest),
                        D,
                        Equal);
                  end;
               end if;
            end loop;
         end loop;
         for Mode in 0 .. 3 loop
            declare
               A     : constant Image :=
                 (if Mode = 0 or else Mode = 3
                  then Default_Image
                  else
                    New_Image
                      (0, 0, ((if Mode = 2 then Float32 else UInt8), 1)));
               B     : constant Image :=
                 (if Mode = 3 then New_Image (0, 0, (UInt8, 1)) else A);
               Dest  : Image := New_Image (2, 3, (UInt8, 1));
               Alias : constant Image := Dest;
               E     : constant Image := Compare (A, B, Equal);
            begin
               Set_To (Dest, Make_Scalar (91.0));
               Compare (A, B, Equal, Dest);
               Assert (Is_Empty (Dest) and then Is_Empty (E), "empty Compare");
               Assert
                 (Dimension_Count (E) = 0
                  and then Shape (E) = Dimension_Array'(1 .. 0 => 0)
                  and then Depth (E) = UInt8
                  and then Channels (E) = 1,
                  "fresh Compare has independent default-empty metadata");
               Assert
                 (Depth (Dest) = UInt8 and then Channels (Dest) = 1,
                  "release retains old output type");
               Assert
                 (Dimension_Count (Dest)
                  = (if Module_Bridge_Probe.OpenCV_Major_Version >= 5
                     then 0
                     else 2),
                  "version-specific released rank");
               Assert
                 (Shape (Dest)
                  = (if Dimension_Count (Dest) = 0
                     then Dimension_Array'(1 .. 0 => 0)
                     else Dimension_Array'(0, 0)),
                  "released shape");
               Constant_Bytes (Observe (Alias), 91);
               Dest := New_Image (2, 3, (Float32, 3));
               Set_To (Dest, Make_Scalar (91.0, 91.0, 91.0));
               Compare (A, B, Equal, Dest);
               Assert
                 (Is_Empty (Dest)
                  and then Depth (Dest) = Float32
                  and then Channels (Dest) = 3
                  and then Dimension_Count (Dest)
                           = (if Module_Bridge_Probe.OpenCV_Major_Version >= 5
                              then 0
                              else 2),
                  "empty Compare release retains old nonmask type");
            end;
         end loop;
         declare
            A    : constant Image := New_ND ((2, 3, 5), (UInt8, 1));
            Dest : Image := New_Image (2, 3, (UInt8, 1));
         begin
            Set_To (Dest, Make_Scalar (91.0));
            begin
               declare
                  E : constant Image := Compare (A, A, Equal);
               begin
                  Assert (Is_Empty (E), "unexpected N-D Compare success");
                  Assert (False, "N-D function must reject");
               end;
            exception
               when OpenCV_Error =>
                  null;
            end;
            begin
               Compare (A, A, Equal, Dest);
               Assert (False, "N-D procedure must reject");
            exception
               when OpenCV_Error =>
                  null;
            end;
            Constant_Bytes (Observe (Dest), 91);
         end;
      end Compare_Boundaries;

      procedure Range_Boundaries (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for D of Depth_List'(UInt8, Float32, Float16) loop
            if D /= Float16
              or else Module_Bridge_Probe.OpenCV_Major_Version >= 5
            then
               for Ch in Channel_Count range 1 .. 3 loop
                  declare
                     A     : Image := New_ND ((2, 3, 5), (D, Ch));
                     Dest  : Image := New_ND ((2, 3, 5), (UInt8, 1));
                     Alias : Image := Dest;
                  begin
                     Set_To (A, Make_Scalar (2.0, 12.0, 22.0));
                     if Ch = 1 then
                        declare
                           Values : Mat :=
                             Create
                               (Shape        => (2, 3, 5),
                                Element_Type => (Int32, 1));
                        begin
                           for I in Size_Coordinate range 0 .. 1 loop
                              for J in Size_Coordinate range 0 .. 2 loop
                                 for K in Size_Coordinate range 0 .. 4 loop
                                    Int32_Access.Set
                                      (Values, (I, J, K), Int32_Value (K));
                                 end loop;
                              end loop;
                           end loop;
                           A := From_Mat (Values.Convert_To (D));
                        end;
                     end if;
                     declare
                        E : constant Image :=
                          In_Range
                            (A,
                             Make_Scalar (2.0, 11.0, 21.0),
                             Make_Scalar (3.0, 12.0, 23.0));
                     begin
                        In_Range
                          (A,
                           Make_Scalar (2.0, 11.0, 21.0),
                           Make_Scalar (3.0, 12.0, 23.0),
                           Dest);
                        Assert
                          (Dimension_Count (Dest) = 3
                           and then Shape (Dest) = Dimension_Array'(2, 3, 5),
                           "genuine N-D In_Range shape");
                        Mask_Parity (Observe (Dest), Observe (E));
                        Mask_Parity (Observe (Alias), Observe (E));
                        for I in Size_Coordinate range 0 .. 1 loop
                           for J in Size_Coordinate range 0 .. 2 loop
                              for K in Size_Coordinate range 0 .. 4 loop
                                 Assert
                                   (UInt8_Access.Get
                                      (Observe (Dest), (I, J, K))
                                    = (if Ch > 1 or else K in 2 .. 3
                                       then 255
                                       else 0),
                                    "inclusive N-D channel conjunction");
                              end loop;
                           end loop;
                        end loop;
                        Set_To (Alias, Make_Scalar (17.0));
                        Assert
                          (UInt8_Access.Get (Observe (Dest), (1, 2, 4)) = 17,
                           "N-D Alias write reaches Destination");
                        Set_To (Dest, Make_Scalar (19.0));
                        Assert
                          (UInt8_Access.Get (Observe (Alias), (1, 2, 4)) = 19,
                           "N-D Destination write reaches Alias");
                        Dest := New_Image (1, 1, (Float64, 3));
                        In_Range
                          (A,
                           Make_Scalar (2.0, 11.0, 21.0),
                           Make_Scalar (3.0, 12.0, 23.0),
                           Dest);
                        Mask_Parity (Observe (Dest), Observe (E));
                        Assert
                          (UInt8_Access.Get (Observe (Alias), (1, 2, 4)) = 19,
                           "N-D mismatch preserves old Alias storage");
                     end;
                  end;
               end loop;
            end if;
         end loop;
         for Typed in Boolean loop
            declare
               A     : Image;
               Dest  : Image := New_Image (2, 3, (UInt8, 1));
               Alias : constant Image := Dest;
            begin
               if Typed then
                  A := New_Image (0, 0, (Float32, 1));
               end if;
               Set_To (Dest, Make_Scalar (91.0));
               begin
                  declare
                     E : constant Image :=
                       In_Range (A, Make_Scalar (0.0), Make_Scalar (1.0));
                  begin
                     Assert (Is_Empty (E), "unexpected empty range");
                     Assert (False, "empty range function rejects");
                  end;
               exception
                  when OpenCV_Error =>
                     null;
               end;
               begin
                  In_Range (A, Make_Scalar (0.0), Make_Scalar (1.0), Dest);
                  Assert (False, "empty range procedure rejects");
               exception
                  when OpenCV_Error =>
                     null;
               end;
               Assert
                 (Dimension_Count (Dest) = 2
                  and then Shape (Dest) = Dimension_Array'(2, 3),
                  "empty rejection metadata unchanged");
               Constant_Bytes (Observe (Dest), 91);
               Constant_Bytes (Observe (Alias), 91);
            end;
         end loop;
      end Range_Boundaries;

      procedure Half (Test : in out Fixture) is
         pragma Unreferenced (Test);
         A      : constant Image := Input (Float16);
         B      : constant Image := Input (Float16, True);
         Parent : Image := New_Image (3, 260, (UInt8, 1));
         Dest   : Image := Region (Parent, (1, 1, 257, 1));
         Alias  : constant Image := Dest;
      begin
         Set_To (Parent, Make_Scalar (91.0));
         if Module_Bridge_Probe.OpenCV_Major_Version < 5 then
            for Range_Operation in Boolean loop
               begin
                  declare
                     E : constant Image :=
                       (if Range_Operation
                        then
                          In_Range (A, Make_Scalar (-1.0), Make_Scalar (1.0))
                        else Compare (A, B, Equal));
                  begin
                     Assert (Is_Empty (E), "unexpected Float16 output");
                     Assert (False, "Float16 function rejection");
                  end;
               exception
                  when OpenCV_Error =>
                     null;
               end;
               begin
                  if Range_Operation then
                     In_Range (A, Make_Scalar (-1.0), Make_Scalar (1.0), Dest);
                  else
                     Compare (A, B, Equal, Dest);
                  end if;
                  Assert (False, "Float16 procedure rejection");
               exception
                  when OpenCV_Error =>
                     null;
               end;
               Assert
                 (Dimension_Count (Dest) = 2
                  and then Shape (Dest) = Dimension_Array'(1, 257)
                  and then Locate_Region (Dest) = Locate_Region (Alias),
                  "Float16 pre-native failure metadata/location");
               Constant_Bytes (Observe (Dest), 91);
               Constant_Bytes (Observe (Alias), 91);
               Constant_Bytes (Observe (Parent), 91);
            end loop;
         else
            for Kind in Comparison_Kind loop
               Compare (A, B, Kind, Dest);
               Check_Compare (Dest, Float16, Kind);
               Mask_Parity (Observe (Alias), Observe (Dest));
            end loop;
            Dest := New_Image (2, 2, (Float64, 4));
            Compare (A, B, Equal, Dest);
            Check_Compare (Dest, Float16, Equal);
            In_Range (A, Make_Scalar (-1.0), Make_Scalar (1.0), Dest);
            Mask_Parity
              (Observe (Dest),
               Observe (In_Range (A, Make_Scalar (-1.0), Make_Scalar (1.0))));
            Dest := Region (Parent, (1, 1, 257, 1));
            In_Range (A, Make_Scalar (-1.0), Make_Scalar (1.0), Dest);
            Mask_Parity
              (Observe (Alias),
               Observe (In_Range (A, Make_Scalar (-1.0), Make_Scalar (1.0))));
            Dest := New_Image (1, 1, (Int16, 3));
            In_Range (A, Make_Scalar (-1.0), Make_Scalar (1.0), Dest);
            Mask_Parity
              (Observe (Dest),
               Observe (In_Range (A, Make_Scalar (-1.0), Make_Scalar (1.0))));
         end if;
      end Half;

      procedure Failures (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Dest  : Image := New_Image (2, 3, (UInt8, 1));
         Alias : constant Image := Dest;
         A     : constant Image := New_Image (2, 3, (UInt8, 1));
      begin
         Set_To (Dest, Make_Scalar (91.0));
         for Mode in 0 .. 3 loop
            declare
               B : constant Image :=
                 New_Image
                   ((if Mode = 0 then 1 else 2),
                    (if Mode = 1 then 2 else 3),
                    ((if Mode = 2 then Float32 else UInt8),
                     (if Mode = 3 then 2 else 1)));
            begin
               begin
                  Compare (A, B, Equal, Dest);
                  Assert (False, "Compare source contract rejects");
               exception
                  when OpenCV_Error =>
                     null;
               end;
               Assert
                 (Shape (Dest) = Dimension_Array'(2, 3)
                  and then Dimension_Count (Dest) = 2,
                  "Compare semantic rejection preserves shape/rank");
               Constant_Bytes (Observe (Dest), 91);
               Constant_Bytes (Observe (Alias), 91);
            end;
         end loop;
         declare
            Many : constant Image := New_Image (2, 3, (UInt8, 5));
         begin
            begin
               In_Range (Many, Make_Scalar (0.0), Make_Scalar (1.0), Dest);
               Assert (False, "range C5 restriction rejects");
            exception
               when OpenCV_Error =>
                  null;
            end;
            Constant_Bytes (Observe (Dest), 91);
            Constant_Bytes (Observe (Alias), 91);
         end;
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

   procedure Temporary (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data : aliased UInt8_Mat_View.Buffer_Array := (0 .. 9 => 2);
      procedure Process (View : in out Mat) is
         Other : Mat := Create (2, 3, (UInt8, 1));
         Dest  : Mat;
      begin
         Other.Set_To (Make_Scalar (2.0));
         Compare (View, Other, Equal, Dest);
         Constant_Bytes (Dest, 255);
         Compare (Other, View, Equal, Dest);
         Constant_Bytes (Dest, 255);
         In_Range (View, Make_Scalar (2.0), Make_Scalar (2.0), Dest);
         Constant_Bytes (Dest, 255);
         for Compatible in Boolean loop
            Other :=
              Create
                ((if Compatible then 2 else 1),
                 (if Compatible then 3 else 1),
                 (UInt8, 1));
            Other.Set_To (Make_Scalar (2.0));
            begin
               Compare (Other, Other, Equal, View);
               Assert (False, "temporary Compare destination rejection");
            exception
               when OpenCV_Error =>
                  null;
            end;
            begin
               In_Range (Other, Make_Scalar (0.0), Make_Scalar (3.0), View);
               Assert (False, "temporary range destination rejection");
            exception
               when OpenCV_Error =>
                  null;
            end;
            Constant_Bytes (View, 2);
         end loop;
      end Process;
   begin
      UInt8_Mat_View.With_Writable_Strided_Mat_View
        (Data, 2, 3, 5, Process'Access);
      for Byte of Data loop
         Assert (Byte = 2, "temporary input/backing/padding unchanged");
      end loop;
      declare
         Parent : Mat :=
           Create (Shape => (2, 2, 3), Element_Type => (UInt8, 1));
      begin
         Parent.Set_To (Make_Scalar (2.0));
         Parent.With_Selected_View
           ((1 => (Fix_Index, 1),
             2 => (Keep_Range, (0, 2)),
             3 => (Keep_Range, (0, 3))),
            Process'Access);
         for I in Size_Coordinate range 0 .. 1 loop
            for J in Size_Coordinate range 0 .. 1 loop
               for K in Size_Coordinate range 0 .. 2 loop
                  Assert
                    (UInt8_Access.Get (Parent, (I, J, K)) = 2,
                     "temporary selected Parent preserved");
               end loop;
            end loop;
         end loop;
      end;
   end Temporary;
   procedure CPU (Test : in out Fixture) is
      procedure Run is
      begin
         UMat_Cases.Compare_Reuse (Test);
         UMat_Cases.Compare_Regions (Test);
         UMat_Cases.Compare_Numbers (Test);
         UMat_Cases.Compare_Boundaries (Test);
         UMat_Cases.Range_Reuse (Test);
         UMat_Cases.Range_Regions (Test);
         UMat_Cases.Range_Numbers (Test);
         UMat_Cases.Range_Boundaries (Test);
         UMat_Cases.Half (Test);
         UMat_Cases.Failures (Test);
         Raw_ABI.UMat_Check (Test);
      end Run;
   begin
      Raw_ABI.With_OpenCL_Disabled (Run'Access);
   end CPU;
   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("mask Mat semantic failures", Mat_Cases.Failures'Access));
      Result.Add_Test
        (Caller.Create
           ("mask UMat semantic failures", UMat_Cases.Failures'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare destination Mat reuse", Mat_Cases.Compare_Reuse'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare destination Mat Region/mismatch",
            Mat_Cases.Compare_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare destination Mat modes/types/specials",
            Mat_Cases.Compare_Numbers'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare destination Mat aliases/empty/N-D",
            Mat_Cases.Compare_Boundaries'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare destination UMat reuse",
            UMat_Cases.Compare_Reuse'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare destination UMat Region/mismatch",
            UMat_Cases.Compare_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare destination UMat modes/types/specials",
            UMat_Cases.Compare_Numbers'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare destination UMat aliases/empty/N-D",
            UMat_Cases.Compare_Boundaries'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range destination Mat reuse", Mat_Cases.Range_Reuse'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range destination Mat Region/mismatch",
            Mat_Cases.Range_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range destination Mat scalar/channels",
            Mat_Cases.Range_Numbers'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range destination Mat N-D/empty",
            Mat_Cases.Range_Boundaries'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range destination UMat reuse", UMat_Cases.Range_Reuse'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range destination UMat Region/mismatch",
            UMat_Cases.Range_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range destination UMat scalar/channels",
            UMat_Cases.Range_Numbers'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range destination UMat N-D/empty",
            UMat_Cases.Range_Boundaries'Access));
      Result.Add_Test
        (Caller.Create
           ("mask destination Mat Float16 boundary", Mat_Cases.Half'Access));
      Result.Add_Test
        (Caller.Create
           ("mask destination UMat Float16 boundary", UMat_Cases.Half'Access));
      Result.Add_Test (Caller.Create ("mask temporary Mat", Temporary'Access));
      Result.Add_Test
        (Caller.Create ("mask raw Mat", Raw_ABI.Mat_Check'Access));
      Result.Add_Test
        (Caller.Create ("mask raw UMat", Raw_ABI.UMat_Check'Access));
      Result.Add_Test
        (Caller.Create ("mask UMat OpenCL disabled", CPU'Access));
      return Result'Access;
   end Suite;
end Mask_Destination_Tests;
