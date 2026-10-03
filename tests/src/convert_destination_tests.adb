with AUnit.Assertions;
with AUnit.Test_Caller;
with Mat_Test_Support;
with Interfaces;
with Module_Bridge_Probe;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Transfers;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.UInt8_Vec3_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.UInt8_Mat_View;
with Convert_Destination_Tests.Raw_ABI;

package body Convert_Destination_Tests is
   use OpenCV;
   use OpenCV.Core;
   use Mat_Test_Support;
   use AUnit.Assertions;
   use type UInt8_Value;
   use type Int16_Value;
   use type Float32_Value;
   use type UInt8_Vec3.Vector;
   use type Interfaces.Unsigned_16;
   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Identity (Self : Mat) return Mat
   is (Self);

   --  UMat transfers are solely for test setup/observation. The operations
   --  under test always invoke the public native destination overloads.
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
        procedure Convert_To
          (Self        : Image;
           Destination : in out Image;
           Depth       : Depth_Type;
           Scale       : Long_Float := 1.0;
           Offset      : Long_Float := 0.0) is <>;
      with
        function Convert_To
          (Self   : Image;
           Depth  : Depth_Type;
           Scale  : Long_Float := 1.0;
           Offset : Long_Float := 0.0) return Image is <>;
      with function Region (Self : Image; Area : Rect) return Image is <>;
      with procedure Set_To (Self : in out Image; Value : Scalar) is <>;
      with function Shape (Self : Image) return Dimension_Array is <>;
      with function Depth (Self : Image) return Depth_Type is <>;
      with function Channels (Self : Image) return Channel_Count is <>;
      with function Is_Empty (Self : Image) return Boolean is <>;
      with function Is_Submatrix (Self : Image) return Boolean is <>;
      with function Locate_Region (Self : Image) return Region_Location is <>;
      Is_UMat : Boolean;
   package Cases is
      procedure Whole (Test : in out Fixture);
      procedure Interior (Test : in out Fixture);
      procedure Multichannel (Test : in out Fixture);
      procedure Reallocate_Size (Test : in out Fixture);
      procedure Reallocate_Type (Test : in out Fixture);
      procedure Lifetime (Test : in out Fixture);
      procedure ND (Test : in out Fixture);
      procedure Empty (Test : in out Fixture);
      procedure Self_Conversion (Test : in out Fixture);
      procedure Shallow_Aliases (Test : in out Fixture);
      procedure Source_Region (Test : in out Fixture);
      procedure Half (Test : in out Fixture);
   end Cases;

   package body Cases is
      procedure Whole (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Host        : Mat := Create (2, 3, (Int16, 1));
         Destination : Image := New_Image (2, 3, (UInt8, 1));
         Alias       : Image := Destination;
      begin
         for R in 0 .. 1 loop
            Int16_Access.Set (Host, R, 0, -20);
            Int16_Access.Set (Host, R, 1, 12);
            Int16_Access.Set (Host, R, 2, 200);
         end loop;
         Convert_To (From_Mat (Host), Destination, UInt8, 2.0, 3.0);
         Assert (Shape (Destination) = (2, 3), "whole shape retained");
         for R in 0 .. 1 loop
            Assert
              (UInt8_Access.Get (Observe (Alias), R, 0) = 0
               and then UInt8_Access.Get (Observe (Alias), R, 1) = 27
               and then UInt8_Access.Get (Observe (Alias), R, 2) = 255,
               "alias observes conversion, scale/offset and saturation");
         end loop;
         Set_To (Alias, Make_Scalar (41.0));
         Assert
           (UInt8_Access.Get (Observe (Destination), 1, 2) = 41,
            "bidirectional whole sharing proves reuse");
      end Whole;

      procedure Interior (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Source      : Image := New_Image (2, 3, (Float32, 1));
         Parent      : Image := New_Image (5, 7, (UInt8, 1));
         Destination : Image := Region (Parent, (2, 1, 3, 2));
         Alias       : constant Image := Destination;
         Before      : constant Region_Location := Locate_Region (Destination);
      begin
         Set_To (Source, Make_Scalar (12.0));
         Set_To (Parent, Make_Scalar (91.0));
         Convert_To (Source, Destination, UInt8, 2.0, 3.0);
         Assert
           (Shape (Destination) = (2, 3)
            and then Depth (Destination) = UInt8
            and then Is_Submatrix (Destination)
            and then Locate_Region (Destination) = Before,
            "compatible Region geometry and parent attachment retained");
         for R in 0 .. 4 loop
            for Col in 0 .. 6 loop
               Assert
                 (UInt8_Access.Get (Observe (Parent), R, Col)
                  = (if R in 1 .. 2 and then Col in 2 .. 4 then 27 else 91),
                  "only interior destination pixels modified, guards intact");
            end loop;
         end loop;
         Assert
           (UInt8_Access.Get (Observe (Alias), 1, 2) = 27,
            "preexisting Region alias sees conversion");
         Set_To (Destination, Make_Scalar (42.0));
         Assert
           (UInt8_Access.Get (Observe (Parent), 2, 4) = 42,
            "subsequent writes still reach original parent");
      end Interior;

      procedure Multichannel (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Source      : Image := New_Image (2, 3, (Float32, 3));
         Destination : Image := New_Image (2, 3, (UInt8, 3));
         Alias       : constant Image := Destination;
      begin
         Set_To (Source, Make_Scalar (-20.0, 12.0, 200.0));
         Convert_To (Source, Destination, UInt8, 2.0, 3.0);
         Assert (Channels (Destination) = 3, "channels preserved");
         Assert
           (UInt8_Vec3_Access.Get (Observe (Alias), 1, 2) = (0, 27, 255),
            "every channel converted and compatible C3 storage reused");
      end Multichannel;

      procedure Reallocation (Size_Mismatch : Boolean) is
         Source      : Image := New_Image (2, 3, (Float32, 1));
         Parent      : Image := New_Image (5, 7, (UInt8, 1));
         Destination : Image := Region (Parent, (2, 1, 3, 2));
         Alias       : constant Image := Destination;
      begin
         Set_To (Parent, Make_Scalar (91.0));
         Set_To (Source, Make_Scalar (12.0));
         if Size_Mismatch then
            Source := New_Image (3, 4, (Float32, 1));
            Set_To (Source, Make_Scalar (12.0));
            Convert_To (Source, Destination, UInt8, 2.0, 3.0);
            Assert
              (Shape (Destination) = (3, 4)
               and then Depth (Destination) = UInt8
               and then Channels (Destination) = 1,
               "size reallocated with requested depth and source channels");
            Assert
              (UInt8_Access.Get (Observe (Destination), 2, 3) = 27,
               "new size receives converted pixels");
         else
            Convert_To (Source, Destination, Int16, 2.0, 3.0);
            Assert
              (Shape (Destination) = (2, 3)
               and then Depth (Destination) = Int16,
               "type reallocated at same size");
            Assert
              (Int16_Access.Get (Observe (Destination), 1, 2) = 27,
               "new depth receives converted pixels");
         end if;
         Assert
           (not Is_Submatrix (Destination), "incompatible Region detaches");
         Set_To (Destination, Make_Scalar (44.0));
         for R in 0 .. 4 loop
            for Col in 0 .. 6 loop
               Assert
                 (UInt8_Access.Get (Observe (Parent), R, Col) = 91,
                  "reallocation and later writes leave parent untouched");
            end loop;
         end loop;
         Assert
           (UInt8_Access.Get (Observe (Alias), 1, 2) = 91,
            "old alias retains original storage");
      end Reallocation;

      procedure Reallocate_Size (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         Reallocation (True);
      end Reallocate_Size;

      procedure Reallocate_Type (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         Reallocation (False);
      end Reallocate_Type;

      procedure Lifetime (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Destination : Image;
         Returned    : Image;
      begin
         declare
            Source : Image := New_Image (2, 3, (Float32, 1));
         begin
            Set_To (Source, Make_Scalar (12.0));
            Convert_To (Source, Destination, UInt8, 2.0, 3.0);
            Returned := Convert_To (Source, UInt8, 2.0, 3.0);
            Set_To (Source, Make_Scalar (99.0));
         end;
         Assert
           (UInt8_Access.Get (Observe (Destination), 1, 2) = 27,
            "converted destination survives source mutation/finalization");
         Set_To (Destination, Make_Scalar (44.0));
         Assert
           (UInt8_Access.Get (Observe (Returned), 1, 2) = 27,
            "return-value API still owns independent storage");
      end Lifetime;

      procedure ND (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Host        : Mat := Create (Dimension_Array'(2, 3, 4), (Float32, 1));
         Destination : Image := New_ND ((2, 3, 4), (Int16, 1));
         Alias       : constant Image := Destination;
      begin
         Host.Set_To (Make_Scalar (12.0));
         Float32_Access.Set (Host, Index_Array'(1, 2, 3), -9.0);
         Convert_To (From_Mat (Host), Destination, Int16, 2.0, 3.0);
         Assert (Shape (Destination) = (2, 3, 4), "N-D shape preserved");
         Assert
           (Int16_Access.Get (Observe (Alias), Index_Array'(0, 1, 2)) = 27
            and then Int16_Access.Get (Observe (Alias), Index_Array'(1, 2, 3))
                     = -15,
            "N-D conversion and alias-visible storage reuse");
      end ND;

      procedure Empty (Test : in out Fixture) is
         pragma Unreferenced (Test);
      begin
         for Typed in Boolean loop
            for Scaled in Boolean loop
               declare
                  Source      : Image;
                  Destination : Image := New_Image (2, 3, (Int16, 2));
                  Alias       : Image := Destination;
               begin
                  if Typed then
                     Source := New_Image (0, 0, (Float32, 3));
                  end if;
                  Set_To (Alias, Make_Scalar (91.0, 92.0));
                  Convert_To
                    (Source,
                     Destination,
                     UInt8,
                     (if Scaled then 2.0 else 1.0));
                  Assert
                    (Is_Empty (Destination)
                     and then Shape (Destination) = (0, 0),
                     "default/typed empty releases destination pixels");
                  if Module_Bridge_Probe.OpenCV_Major_Version >= 5 then
                     Assert
                       (Depth (Destination) = UInt8
                        and then Channels (Destination)
                                 = (if Typed and not Is_UMat then 3 else 1),
                        "5.0 native empty metadata recreation pinned");
                  else
                     Assert
                       (Depth (Destination) = Int16
                        and then Channels (Destination) = 2,
                        "4.x release retains destination type metadata");
                  end if;
                  Assert
                    (Shape (Alias) = (2, 3), "old allocation alias survives");
               end;
            end loop;
         end loop;
      end Empty;

      procedure Self_Conversion (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Host   : Mat := Create (2, 37, (Float32, 1));
         Source : Image;
      begin
         for R in 0 .. 1 loop
            for Col in 0 .. 36 loop
               Float32_Access.Set (Host, R, Col, Float32_Value (Col));
            end loop;
         end loop;
         Source := From_Mat (Host);
         Convert_To (Source, Destination => Source, Depth => Float32);
         Convert_To
           (Source,
            Destination => Source,
            Depth       => Float32,
            Scale       => 2.0,
            Offset      => 3.0);
         Convert_To (Source, Destination => Source, Depth => UInt8);
         Assert
           (Depth (Source) = UInt8 and then Shape (Source) = (2, 37),
            "exact self depth-changing conversion retains shape");
         for R in 0 .. 1 loop
            for Col in 0 .. 36 loop
               Assert
                 (UInt8_Access.Get (Observe (Source), R, Col)
                  = UInt8_Value (2 * Col + 3),
                  "identity, in-place scaling and depth change, SIMD tail");
            end loop;
         end loop;
      end Self_Conversion;

      procedure Shallow_Aliases (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Source      : Image := New_Image (2, 3, (Float32, 1));
         Destination : Image := Source;
      begin
         Set_To (Source, Make_Scalar (12.0));
         Convert_To (Source, Destination, Float32, 2.0, 3.0);
         Assert
           (Float32_Access.Get (Observe (Source), 1, 2) = 27.0,
            "same-layout shallow aliases share in-place scaling");
         Convert_To (Source, Destination, UInt8, 2.0, 3.0);
         Assert
           (Depth (Source) = Float32
            and then Float32_Access.Get (Observe (Source), 1, 2) = 27.0
            and then UInt8_Access.Get (Observe (Destination), 1, 2) = 57,
            "depth-changing shallow alias detaches without losing source");
      end Shallow_Aliases;

      procedure Source_Region (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Parent      : Image := New_Image (5, 7, (Float32, 1));
         Source      : Image := Region (Parent, (2, 1, 3, 2));
         Destination : Image;
      begin
         Set_To (Parent, Make_Scalar (99.0));
         Set_To (Source, Make_Scalar (12.0));
         Convert_To (Source, Destination, UInt8, 2.0, 3.0);
         Assert
           (Shape (Destination) = (2, 3)
            and then UInt8_Access.Get (Observe (Destination), 1, 2) = 27,
            "strided source Region converts only its logical pixels");
         Assert
           (Float32_Access.Get (Observe (Parent), 0, 0) = 99.0,
            "source guards untouched");
      end Source_Region;

      procedure Half (Test : in out Fixture) is
         pragma Unreferenced (Test);
         Source      : Image := New_Image (2, 3, (Float32, 1));
         Destination : Image := New_Image (2, 3, (Float16, 1));
         Alias       : constant Image := Destination;
      begin
         Set_To (Source, Make_Scalar (1.5));
         Convert_To (Source, Destination, Float16, 2.0, 1.0);
         Assert
           (Float16_Bits (Float16_Access.Get (Observe (Alias), 1, 2))
            = Float16_Bits (To_Float16 (4.0)),
            "native Float16 conversion reuses compatible destination");
         Convert_To (Destination, Destination, Float32);
         Assert
           (Float32_Access.Get (Observe (Destination), 1, 2) = 4.0,
            "Float16 exact-self widening uses existing native policy");
      end Half;

   end Cases;

   procedure Register
     (Prefix : String;
      Whole,
      Interior,
      Multichannel,
      Reallocate_Size,
      Reallocate_Type,
      Lifetime,
      ND,
      Empty,
      Self_Conversion,
      Shallow_Aliases,
      Source_Region,
      Half   : Caller.Test_Method) is
   begin
      Result.Add_Test (Caller.Create (Prefix & "whole reuse", Whole));
      Result.Add_Test (Caller.Create (Prefix & "Region reuse", Interior));
      Result.Add_Test (Caller.Create (Prefix & "channels", Multichannel));
      Result.Add_Test
        (Caller.Create (Prefix & "size reallocation", Reallocate_Size));
      Result.Add_Test
        (Caller.Create (Prefix & "type reallocation", Reallocate_Type));
      Result.Add_Test (Caller.Create (Prefix & "lifetime", Lifetime));
      Result.Add_Test (Caller.Create (Prefix & "N-D", ND));
      Result.Add_Test (Caller.Create (Prefix & "empty", Empty));
      Result.Add_Test (Caller.Create (Prefix & "exact self", Self_Conversion));
      Result.Add_Test
        (Caller.Create (Prefix & "shallow aliases", Shallow_Aliases));
      Result.Add_Test
        (Caller.Create (Prefix & "source Region", Source_Region));
      Result.Add_Test (Caller.Create (Prefix & "Float16", Half));
   end Register;

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
      Destination : Mat;
      Before      : constant Dimension_Array := View.Shape;
      procedure Convert is
      begin
         Source.Convert_To (View, Float32);
      end Convert;
      procedure Matching_Convert is
      begin
         Source.Convert_To (View, UInt8);
      end Matching_Convert;
   begin
      Source.Set_To (Make_Scalar (12.0));
      Assert_Raises_OpenCV_Error
        (Convert'Access, "temporary destination rejects");
      Assert_Raises_OpenCV_Error
        (Matching_Convert'Access, "compatible temporary destination rejects");
      Assert
        (View.Shape = Before
         and then View.Depth = UInt8
         and then UInt8_Access.Get (View, 0, 0) = 37,
         "temporary data/type unchanged");
      View.Convert_To (Destination, Int16, 2.0, 3.0);
      Assert
        (Int16_Access.Get (Destination, 0, 0) = 77,
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
      Assert (Data = Before, "caller storage/padding unchanged");
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
         "selected parent storage unchanged");
   end Selected;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Register
        ("Convert destination Mat ",
         Mat_Cases.Whole'Access,
         Mat_Cases.Interior'Access,
         Mat_Cases.Multichannel'Access,
         Mat_Cases.Reallocate_Size'Access,
         Mat_Cases.Reallocate_Type'Access,
         Mat_Cases.Lifetime'Access,
         Mat_Cases.ND'Access,
         Mat_Cases.Empty'Access,
         Mat_Cases.Self_Conversion'Access,
         Mat_Cases.Shallow_Aliases'Access,
         Mat_Cases.Source_Region'Access,
         Mat_Cases.Half'Access);
      Register
        ("Convert destination UMat ",
         UMat_Cases.Whole'Access,
         UMat_Cases.Interior'Access,
         UMat_Cases.Multichannel'Access,
         UMat_Cases.Reallocate_Size'Access,
         UMat_Cases.Reallocate_Type'Access,
         UMat_Cases.Lifetime'Access,
         UMat_Cases.ND'Access,
         UMat_Cases.Empty'Access,
         UMat_Cases.Self_Conversion'Access,
         UMat_Cases.Shallow_Aliases'Access,
         UMat_Cases.Source_Region'Access,
         UMat_Cases.Half'Access);
      Result.Add_Test
        (Caller.Create ("Convert temporary external", External'Access));
      Result.Add_Test
        (Caller.Create ("Convert temporary selected", Selected'Access));
      Result.Add_Test
        (Caller.Create ("Convert Mat raw ABI", Raw_ABI.Mat_Check'Access));
      Result.Add_Test
        (Caller.Create ("Convert UMat raw ABI", Raw_ABI.UMat_Check'Access));
      return Result'Access;
   end Suite;
end Convert_Destination_Tests;
