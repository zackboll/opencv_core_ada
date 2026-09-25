with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float16_Vec3;
with OpenCV.Core.Float16_Vec3_Access;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with Vec3_ND_Access_Tests.Raw_ABI;

package body Vec3_ND_Access_Tests is

   use type OpenCV.Float32_Value;
   use type Interfaces.Unsigned_16;
   use type OpenCV.Core.UInt8_Vec3.Vector;
   use type OpenCV.Core.Float32_Vec3.Vector;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   function UInt8_Pixel
     (First, Second, Third : OpenCV.UInt8_Value)
      return OpenCV.Core.UInt8_Vec3.Vector
   is ((0 => First, 1 => Second, 2 => Third));

   procedure UInt8_Three_Dimensional_Round_Trip (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Volume  : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Shifted : constant OpenCV.Core.Index_Array (5 .. 7) := (1, 2, 3);
      Alias   : OpenCV.Core.Mat;
      Copy    : OpenCV.Core.Mat;
   begin
      Volume.Set_To (OpenCV.Make_Scalar (7.0, 8.0, 9.0));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Volume, Indices => (0, 0, 0), Value => UInt8_Pixel (0, 1, 255));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Volume, Indices => Shifted, Value => UInt8_Pixel (255, 0, 12));

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Volume, Indices => (0, 0, 0))
         = UInt8_Pixel (0, 1, 255)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Volume, Indices => (1, 2, 3))
                  = UInt8_Pixel (255, 0, 12)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Volume, Indices => (0, 0, 1))
                  = UInt8_Pixel (7, 8, 9)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Volume, Indices => (1, 2, 2))
                  = UInt8_Pixel (7, 8, 9),
         "UInt8 Vec3 N-D access must preserve components and neighbors");

      Alias := Volume;
      Copy := Volume.Clone;
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Alias, Indices => (0, 0, 0), Value => UInt8_Pixel (4, 5, 6));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Volume, Indices => (0, 0, 0))
         = UInt8_Pixel (4, 5, 6)
         and then OpenCV.Core.UInt8_Vec3_Access.Get
                    (Copy, Indices => (0, 0, 0))
                  = UInt8_Pixel (0, 1, 255),
         "UInt8 Vec3 N-D assignment shares storage and Clone isolates it");
   end UInt8_Three_Dimensional_Round_Trip;

   procedure UInt8_Two_Dimensional_Overloads_Agree (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 3,
           Columns      => 4,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Shifted : constant OpenCV.Core.Index_Array (8 .. 9) := (2, 3);
   begin
      Image.Set_To (OpenCV.Make_Scalar (1.0, 2.0, 3.0));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, 1, 2, UInt8_Pixel (10, 20, 30));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, Indices => (1, 2))
         = UInt8_Pixel (10, 20, 30),
         "UInt8 Vec3 Index_Array Get must match Row/Column Get");

      OpenCV.Core.UInt8_Vec3_Access.Set
        (Image, Indices => Shifted, Value => UInt8_Pixel (40, 50, 60));
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, 2, 3)
         = UInt8_Pixel (40, 50, 60)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Image, 2, 2)
                  = UInt8_Pixel (1, 2, 3),
         "UInt8 Vec3 Index_Array Set is visible through Row/Column Get");
   end UInt8_Two_Dimensional_Overloads_Agree;

   procedure UInt8_ND_Rejects_Count_Range_And_Layout (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Volume         : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Wrong_Depth    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Wrong_Channels : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));

      procedure Read_Short is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get (Volume, Indices => (0, 0))
            = UInt8_Pixel (0, 0, 0),
            "A short UInt8 Vec3 index list unexpectedly succeeded");
      end Read_Short;
      procedure Write_Long is
      begin
         OpenCV.Core.UInt8_Vec3_Access.Set
           (Volume, Indices => (0, 0, 0, 0), Value => UInt8_Pixel (1, 2, 3));
      end Write_Long;
      procedure Read_Past is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get (Volume, Indices => (0, 3, 0))
            = UInt8_Pixel (0, 0, 0),
            "An out-of-range UInt8 Vec3 index unexpectedly succeeded");
      end Read_Past;
      procedure Write_Past is
      begin
         OpenCV.Core.UInt8_Vec3_Access.Set
           (Volume, Indices => (2, 0, 0), Value => UInt8_Pixel (1, 2, 3));
      end Write_Past;
      procedure Read_Wrong_Depth is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get
              (Wrong_Depth, Indices => (0, 0, 0))
            = UInt8_Pixel (0, 0, 0),
            "A wrong-depth UInt8 Vec3 read unexpectedly succeeded");
      end Read_Wrong_Depth;
      procedure Read_Wrong_Channels is
      begin
         AUnit.Assertions.Assert
           (OpenCV.Core.UInt8_Vec3_Access.Get
              (Wrong_Channels, Indices => (0, 0, 0))
            = UInt8_Pixel (0, 0, 0),
            "A wrong-channel UInt8 Vec3 read unexpectedly succeeded");
      end Read_Wrong_Channels;
      procedure Write_Wrong_Depth is
      begin
         OpenCV.Core.UInt8_Vec3_Access.Set
           (Wrong_Depth, Indices => (0, 0, 0), Value => UInt8_Pixel (1, 2, 3));
      end Write_Wrong_Depth;
      procedure Write_Wrong_Channels is
      begin
         OpenCV.Core.UInt8_Vec3_Access.Set
           (Wrong_Channels,
            Indices => (0, 0, 0),
            Value   => UInt8_Pixel (1, 2, 3));
      end Write_Wrong_Channels;
   begin
      --  Volume stays UInt8 C3 (2, 3, 4), so index-count and axis-range
      --  checks are not masked by an earlier depth or channel rejection.
      Assert_Raises_OpenCV_Error (Read_Short'Access, "UInt8 Vec3 index count");
      Assert_Raises_OpenCV_Error
        (Write_Long'Access, "UInt8 Vec3 Set index count");
      Assert_Raises_OpenCV_Error (Read_Past'Access, "UInt8 Vec3 axis range");
      Assert_Raises_OpenCV_Error
        (Write_Past'Access, "UInt8 Vec3 Set axis range");
      Assert_Raises_OpenCV_Error
        (Read_Wrong_Depth'Access, "UInt8 Vec3 N-D depth");
      Assert_Raises_OpenCV_Error
        (Write_Wrong_Depth'Access, "UInt8 Vec3 Set N-D depth");
      Assert_Raises_OpenCV_Error
        (Read_Wrong_Channels'Access, "UInt8 Vec3 N-D channels");
      Assert_Raises_OpenCV_Error
        (Write_Wrong_Channels'Access, "UInt8 Vec3 Set N-D channels");
   end UInt8_ND_Rejects_Count_Range_And_Layout;

   function Float32_Pixel
     (First, Second, Third : OpenCV.Float32_Value)
      return OpenCV.Core.Float32_Vec3.Vector
   is ((0 => First, 1 => Second, 2 => Third));

   procedure Float32_Indexing_Ownership_And_Rejection (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Volume         : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Plane          : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 3));
      Wrong_Depth    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Wrong_Channels : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
      Shifted        : constant OpenCV.Core.Index_Array (10 .. 12) :=
        (1, 0, 3);
      Alias          : OpenCV.Core.Mat;
      Copy           : OpenCV.Core.Mat;
   begin
      Volume.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Volume,
         Indices => (0, 1, 2),
         Value   => Float32_Pixel (0.5, -1.25, 0.0));
      OpenCV.Core.Float32_Vec3_Access.Set
        (Volume, Indices => Shifted, Value => Float32_Pixel (-0.5, 2.0, 4.0));
      Alias := Volume;
      Copy := Volume.Clone;
      OpenCV.Core.Float32_Vec3_Access.Set
        (Alias, Indices => (0, 1, 2), Value => Float32_Pixel (9.0, 8.0, 7.0));
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec3_Access.Get (Volume, Indices => (1, 0, 3))
         = Float32_Pixel (-0.5, 2.0, 4.0)
         and then OpenCV.Core.Float32_Vec3_Access.Get
                    (Volume, Indices => (0, 1, 2))
                  = Float32_Pixel (9.0, 8.0, 7.0)
         and then OpenCV.Core.Float32_Vec3_Access.Get
                    (Copy, Indices => (0, 1, 2))
                  = Float32_Pixel (0.5, -1.25, 0.0)
         and then OpenCV.Core.Float32_Vec3_Access.Get
                    (Volume, Indices => (0, 1, 1))
                  = Float32_Pixel (0.0, 0.0, 0.0),
         "Float32 Vec3 N-D access preserves order, aliases, and clones");

      OpenCV.Core.Float32_Vec3_Access.Set
        (Plane, 0, 1, Float32_Pixel (1.5, -2.5, 3.0));
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec3_Access.Get
           (Plane, Indices => OpenCV.Core.Index_Array'(4 => 0, 5 => 1))
         = Float32_Pixel (1.5, -2.5, 3.0),
         "Float32 Vec3 Index_Array Get must match Row/Column Get");
      OpenCV.Core.Float32_Vec3_Access.Set
        (Plane,
         Indices => OpenCV.Core.Index_Array'(10 => 1, 11 => 2),
         Value   => Float32_Pixel (0.25, 0.0, -0.75));
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Vec3_Access.Get (Plane, 1, 2)
         = Float32_Pixel (0.25, 0.0, -0.75),
         "Float32 Vec3 Index_Array Set is visible through Row/Column Get");

      declare
         procedure Read_Short is
         begin
            AUnit.Assertions.Assert
              (OpenCV.Core.Float32_Vec3_Access.Get (Volume, Indices => (0, 0))
               = Float32_Pixel (0.0, 0.0, 0.0),
               "A short Float32 Vec3 index list unexpectedly succeeded");
         end Read_Short;
         procedure Write_Long is
         begin
            OpenCV.Core.Float32_Vec3_Access.Set
              (Volume,
               Indices => (0, 0, 0, 0),
               Value   => Float32_Pixel (1.0, 2.0, 3.0));
         end Write_Long;
         procedure Read_Past is
         begin
            AUnit.Assertions.Assert
              (OpenCV.Core.Float32_Vec3_Access.Get
                 (Volume, Indices => (0, 0, 4))
               = Float32_Pixel (0.0, 0.0, 0.0),
               "An out-of-range Float32 Vec3 index unexpectedly succeeded");
         end Read_Past;
         procedure Write_Past is
         begin
            OpenCV.Core.Float32_Vec3_Access.Set
              (Volume,
               Indices => (0, 3, 0),
               Value   => Float32_Pixel (1.0, 2.0, 3.0));
         end Write_Past;
         procedure Read_Wrong_Depth is
         begin
            AUnit.Assertions.Assert
              (OpenCV.Core.Float32_Vec3_Access.Get
                 (Wrong_Depth, Indices => (0, 0, 0))
               = Float32_Pixel (0.0, 0.0, 0.0),
               "A wrong-depth Float32 Vec3 read unexpectedly succeeded");
         end Read_Wrong_Depth;
         procedure Read_Wrong_Channels is
         begin
            AUnit.Assertions.Assert
              (OpenCV.Core.Float32_Vec3_Access.Get
                 (Wrong_Channels, Indices => (0, 0, 0))
               = Float32_Pixel (0.0, 0.0, 0.0),
               "A wrong-channel Float32 Vec3 read unexpectedly succeeded");
         end Read_Wrong_Channels;
         procedure Write_Wrong_Depth is
         begin
            OpenCV.Core.Float32_Vec3_Access.Set
              (Wrong_Depth,
               Indices => (0, 0, 0),
               Value   => Float32_Pixel (1.0, 2.0, 3.0));
         end Write_Wrong_Depth;
         procedure Write_Wrong_Channels is
         begin
            OpenCV.Core.Float32_Vec3_Access.Set
              (Wrong_Channels,
               Indices => (0, 0, 0),
               Value   => Float32_Pixel (1.0, 2.0, 3.0));
         end Write_Wrong_Channels;
      begin
         --  Volume stays Float32 C3 (2, 3, 4), so index-count and axis-range
         --  checks are not masked by an earlier depth or channel rejection.
         Assert_Raises_OpenCV_Error
           (Read_Short'Access, "Float32 Vec3 index count");
         Assert_Raises_OpenCV_Error
           (Write_Long'Access, "Float32 Vec3 Set index count");
         Assert_Raises_OpenCV_Error
           (Read_Past'Access, "Float32 Vec3 axis range");
         Assert_Raises_OpenCV_Error
           (Write_Past'Access, "Float32 Vec3 Set axis range");
         Assert_Raises_OpenCV_Error
           (Read_Wrong_Depth'Access, "Float32 Vec3 N-D depth");
         Assert_Raises_OpenCV_Error
           (Write_Wrong_Depth'Access, "Float32 Vec3 Set N-D depth");
         Assert_Raises_OpenCV_Error
           (Read_Wrong_Channels'Access, "Float32 Vec3 N-D channels");
         Assert_Raises_OpenCV_Error
           (Write_Wrong_Channels'Access, "Float32 Vec3 Set N-D channels");
      end;
   end Float32_Indexing_Ownership_And_Rejection;

   function Float16_Pixel
     (First, Second, Third : Interfaces.Unsigned_16)
      return OpenCV.Core.Float16_Vec3.Vector
   is ((0 => OpenCV.Core.Float16_From_Bits (First),
        1 => OpenCV.Core.Float16_From_Bits (Second),
        2 => OpenCV.Core.Float16_From_Bits (Third)));

   function Bits_Of
     (Value : OpenCV.Core.Float16_Vec3.Vector; Index : Natural)
      return Interfaces.Unsigned_16
   is (OpenCV.Core.Float16_Bits (Value (Index)));

   procedure Float16_Preserves_Component_Encodings (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Volume   : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 3));
      Target   : constant OpenCV.Core.Float16_Vec3.Vector :=
        Float16_Pixel (16#0000#, 16#8000#, 16#0001#);
      Neighbor : constant OpenCV.Core.Float16_Vec3.Vector :=
        Float16_Pixel (16#03FF#, 16#0400#, 16#3C00#);
      Far      : constant OpenCV.Core.Float16_Vec3.Vector :=
        Float16_Pixel (16#BC00#, 16#7BFF#, 16#7C00#);
      Shifted  : constant OpenCV.Core.Index_Array (2 .. 4) := (1, 2, 3);
      Read     : OpenCV.Core.Float16_Vec3.Vector;
   begin
      Volume.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Volume, Indices => (0, 1, 2), Value => Target);
      OpenCV.Core.Float16_Vec3_Access.Set
        (Volume, Indices => (0, 1, 3), Value => Neighbor);
      OpenCV.Core.Float16_Vec3_Access.Set
        (Volume, Indices => Shifted, Value => Far);
      Read :=
        OpenCV.Core.Float16_Vec3_Access.Get (Volume, Indices => (0, 1, 2));
      AUnit.Assertions.Assert
        (Bits_Of (Read, 0) = 16#0000#
         and then Bits_Of (Read, 1) = 16#8000#
         and then Bits_Of (Read, 2) = 16#0001#,
         "Float16 Vec3 N-D access must preserve +0, -0, and a subnormal");
      Read :=
        OpenCV.Core.Float16_Vec3_Access.Get (Volume, Indices => (0, 1, 3));
      AUnit.Assertions.Assert
        (Bits_Of (Read, 0) = 16#03FF#
         and then Bits_Of (Read, 1) = 16#0400#
         and then Bits_Of (Read, 2) = 16#3C00#,
         "Float16 Vec3 neighbors must keep subnormal, normal, and +1 bits");
      Read :=
        OpenCV.Core.Float16_Vec3_Access.Get (Volume, Indices => (1, 2, 3));
      AUnit.Assertions.Assert
        (Bits_Of (Read, 0) = 16#BC00#
         and then Bits_Of (Read, 1) = 16#7BFF#
         and then Bits_Of (Read, 2) = 16#7C00#,
         "Float16 Vec3 N-D access must preserve -1, max finite, and +Inf");
   end Float16_Preserves_Component_Encodings;

   procedure Float16_Preserves_Infinities_And_NaN_Payloads
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Volume       : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 2, 2),
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 3));
      Special      : constant OpenCV.Core.Float16_Vec3.Vector :=
        Float16_Pixel (16#FC00#, 16#7E00#, 16#7E01#);
      Negative_NaN : constant OpenCV.Core.Float16_Vec3.Vector :=
        Float16_Pixel (16#FE00#, 16#0000#, 16#8000#);
      Plane        : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (2, 2, (Depth => OpenCV.Core.Float16, Channels => 3));
      Read         : OpenCV.Core.Float16_Vec3.Vector;
   begin
      OpenCV.Core.Float16_Vec3_Access.Set
        (Volume, Indices => (1, 0, 1), Value => Special);
      OpenCV.Core.Float16_Vec3_Access.Set
        (Volume,
         Indices => OpenCV.Core.Index_Array'(7 => 1, 8 => 1, 9 => 0),
         Value   => Negative_NaN);
      Read :=
        OpenCV.Core.Float16_Vec3_Access.Get (Volume, Indices => (1, 0, 1));
      AUnit.Assertions.Assert
        (Bits_Of (Read, 0) = 16#FC00#
         and then Bits_Of (Read, 1) = 16#7E00#
         and then Bits_Of (Read, 2) = 16#7E01#,
         "Float16 Vec3 N-D access must preserve -Inf and distinct NaN"
         & " payloads");
      Read :=
        OpenCV.Core.Float16_Vec3_Access.Get (Volume, Indices => (1, 1, 0));
      AUnit.Assertions.Assert
        (Bits_Of (Read, 0) = 16#FE00#
         and then Bits_Of (Read, 1) = 16#0000#
         and then Bits_Of (Read, 2) = 16#8000#,
         "Float16 Vec3 N-D access must preserve a negative NaN payload");

      OpenCV.Core.Float16_Vec3_Access.Set
        (Plane, 0, 1, Float16_Pixel (16#7E01#, 16#FC00#, 16#0001#));
      Read := OpenCV.Core.Float16_Vec3_Access.Get (Plane, Indices => (0, 1));
      AUnit.Assertions.Assert
        (Bits_Of (Read, 0) = 16#7E01#
         and then Bits_Of (Read, 1) = 16#FC00#
         and then Bits_Of (Read, 2) = 16#0001#,
         "Float16 Vec3 Index_Array Get must match Row/Column encodings");
      OpenCV.Core.Float16_Vec3_Access.Set
        (Plane,
         Indices => OpenCV.Core.Index_Array'(3 => 1, 4 => 0),
         Value   => Float16_Pixel (16#8000#, 16#7C00#, 16#FE00#));
      Read := OpenCV.Core.Float16_Vec3_Access.Get (Plane, 1, 0);
      AUnit.Assertions.Assert
        (Bits_Of (Read, 0) = 16#8000#
         and then Bits_Of (Read, 1) = 16#7C00#
         and then Bits_Of (Read, 2) = 16#FE00#,
         "Float16 Vec3 Index_Array Set must be visible through Row/Column"
         & " Get");
   end Float16_Preserves_Infinities_And_NaN_Payloads;

   procedure Float16_ND_Rejects_Count_Range_And_Layout (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Volume         : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 3));
      Wrong_Depth    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.UInt16, Channels => 3));
      Wrong_Channels : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 1));

      procedure Read_Short is
      begin
         AUnit.Assertions.Assert
           (Bits_Of
              (OpenCV.Core.Float16_Vec3_Access.Get (Volume, Indices => (0, 0)),
               0)
            = 0,
            "A short Float16 Vec3 index list unexpectedly succeeded");
      end Read_Short;
      procedure Write_Long is
      begin
         OpenCV.Core.Float16_Vec3_Access.Set
           (Volume, Indices => (0, 0, 0, 0), Value => Float16_Pixel (1, 2, 3));
      end Write_Long;
      procedure Read_Past is
      begin
         AUnit.Assertions.Assert
           (Bits_Of
              (OpenCV.Core.Float16_Vec3_Access.Get
                 (Volume, Indices => (0, 0, 4)),
               0)
            = 0,
            "An out-of-range Float16 Vec3 index unexpectedly succeeded");
      end Read_Past;
      procedure Write_Past is
      begin
         OpenCV.Core.Float16_Vec3_Access.Set
           (Volume, Indices => (2, 0, 0), Value => Float16_Pixel (1, 2, 3));
      end Write_Past;
      procedure Read_Wrong_Depth is
      begin
         AUnit.Assertions.Assert
           (Bits_Of
              (OpenCV.Core.Float16_Vec3_Access.Get
                 (Wrong_Depth, Indices => (0, 0, 0)),
               0)
            = 0,
            "A wrong-depth Float16 Vec3 read unexpectedly succeeded");
      end Read_Wrong_Depth;
      procedure Read_Wrong_Channels is
      begin
         AUnit.Assertions.Assert
           (Bits_Of
              (OpenCV.Core.Float16_Vec3_Access.Get
                 (Wrong_Channels, Indices => (0, 0, 0)),
               0)
            = 0,
            "A wrong-channel Float16 Vec3 read unexpectedly succeeded");
      end Read_Wrong_Channels;
      procedure Write_Wrong_Depth is
      begin
         OpenCV.Core.Float16_Vec3_Access.Set
           (Wrong_Depth,
            Indices => (0, 0, 0),
            Value   => Float16_Pixel (1, 2, 3));
      end Write_Wrong_Depth;
      procedure Write_Wrong_Channels is
      begin
         OpenCV.Core.Float16_Vec3_Access.Set
           (Wrong_Channels,
            Indices => (0, 0, 0),
            Value   => Float16_Pixel (1, 2, 3));
      end Write_Wrong_Channels;
   begin
      --  Volume stays Float16 C3 (2, 3, 4), so index-count and axis-range
      --  checks are not masked by an earlier depth or channel rejection.
      Assert_Raises_OpenCV_Error
        (Read_Short'Access, "Float16 Vec3 index count");
      Assert_Raises_OpenCV_Error
        (Write_Long'Access, "Float16 Vec3 Set index count");
      Assert_Raises_OpenCV_Error (Read_Past'Access, "Float16 Vec3 axis range");
      Assert_Raises_OpenCV_Error
        (Write_Past'Access, "Float16 Vec3 Set axis range");
      Assert_Raises_OpenCV_Error
        (Read_Wrong_Depth'Access, "Float16 Vec3 N-D depth");
      Assert_Raises_OpenCV_Error
        (Write_Wrong_Depth'Access, "Float16 Vec3 Set N-D depth");
      Assert_Raises_OpenCV_Error
        (Read_Wrong_Channels'Access, "Float16 Vec3 N-D channels");
      Assert_Raises_OpenCV_Error
        (Write_Wrong_Channels'Access, "Float16 Vec3 Set N-D channels");
   end Float16_ND_Rejects_Count_Range_And_Layout;

   procedure Raw_ABI_Rejects_Unsafe_Vec3_ND_Calls (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Rejects_Unsafe_Calls;
   end Raw_ABI_Rejects_Unsafe_Vec3_ND_Calls;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 3-D access preserves components aliases and clones",
            UInt8_Three_Dimensional_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 Index_Array access agrees with Row/Column access",
            UInt8_Two_Dimensional_Overloads_Agree'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 Vec3 N-D access rejects count range and layout",
            UInt8_ND_Rejects_Count_Range_And_Layout'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 Vec3 N-D access preserves values ownership and bounds",
            Float32_Indexing_Ownership_And_Rejection'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 N-D access preserves finite component encodings",
            Float16_Preserves_Component_Encodings'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 N-D access preserves infinities and NaN payloads",
            Float16_Preserves_Infinities_And_NaN_Payloads'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 N-D access rejects count range and layout",
            Float16_ND_Rejects_Count_Range_And_Layout'Access));
      Result.Add_Test
        (Caller.Create
           ("Raw Vec3 N-D ABI rejects unsafe calls and preserves Float16 bits",
            Raw_ABI_Rejects_Unsafe_Vec3_ND_Calls'Access));
      return Result'Access;
   end Suite;

end Vec3_ND_Access_Tests;
