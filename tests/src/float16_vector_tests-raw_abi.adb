with Ada.Unchecked_Conversion;
with AUnit.Assertions;
with Interfaces;
with System;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;

package body Float16_Vector_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Integer_32;

   function Convert is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        C.Mat_Handle);

   type Word_Array is array (Natural range <>) of aliased C.C_UInt16
   with Convention => C;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      AUnit.Assertions.Assert (Condition, Message);
   end Assert;

   --  Shared raw probes. Sample is a record of special binary16 encodings
   --  and Sample_Words lists the same encodings in component order.
   generic
      type Rec is private;
      Width : Positive;
      Zero, Sentinel, Sample : Rec;
      Sample_Words : Word_Array;
      with
        function Get
          (Self : C.Mat_Handle; Row, Column : C.C_Int32; Result : access Rec)
           return C.Status;
      with
        function Set
          (Self        : C.Mat_Handle;
           Row, Column : C.C_Int32;
           Value       : access constant Rec) return C.Status;
      with
        function Get_ND
          (Self            : C.Mat_Handle;
           Dimension_Count : C.C_Int32;
           Indices         : access C.C_Int32;
           Result          : access Rec) return C.Status;
      with
        function Set_ND
          (Self            : C.Mat_Handle;
           Dimension_Count : C.C_Int32;
           Indices         : access C.C_Int32;
           Value           : access constant Rec) return C.Status;
      with
        function Read_Row
          (Self          : C.Mat_Handle;
           Row           : C.C_Int32;
           Data          : System.Address;
           Element_Count : C.C_UInt64) return C.Status;
      with
        function Write_Row
          (Self          : C.Mat_Handle;
           Row           : C.C_Int32;
           Data          : System.Address;
           Element_Count : C.C_UInt64) return C.Status;
   package Probes is
      procedure Wrong_Layout
        (Depth : OpenCV.Core.Depth_Type; Channels : Positive);
      procedure Geometry;
   end Probes;

   package body Probes is
      Name : constant String := "Float16 C" & Positive'Image (Width);

      function Channel_Count
        (Value : Positive) return OpenCV.Core.Channel_Count
      is (OpenCV.Core.Channel_Count (Value));

      procedure Wrong_Layout
        (Depth : OpenCV.Core.Depth_Type; Channels : Positive)
      is
         Label  : constant String :=
           Name
           & " vs "
           & OpenCV.Core.Depth_Type'Image (Depth)
           & " C"
           & Positive'Image (Channels);
         Plain  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 3, (Depth, Channel_Count (Channels)));
         Volume : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Shape        => (2, 3, 4),
              Element_Type => (Depth, Channel_Count (Channels)));

         procedure Inspect_Plain
           (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
         is
            Raw      : constant C.Mat_Handle := Convert (H);
            Output   : aliased Rec := Sentinel;
            Input    : aliased constant Rec := Sample;
            Row_Data : Word_Array (0 .. 3 * Width - 1) := (others => 16#1234#);
         begin
            Assert
              (Get (Raw, 1, 2, Output'Access) = C.Error_Invalid_Argument
               and then Output = Zero,
               Label & ": 2-D Get must reject and zero the full record");
            Assert
              (Set (Raw, 1, 2, Input'Access) = C.Error_Invalid_Argument,
               Label & ": 2-D Set must reject");
            Assert
              (Read_Row (Raw, 1, Row_Data (0)'Address, 3)
               = C.Error_Invalid_Argument,
               Label & ": row read must reject");
            Assert
              (Write_Row (Raw, 1, Row_Data (0)'Address, 3)
               = C.Error_Invalid_Argument,
               Label & ": row write must reject");
         end Inspect_Plain;

         procedure Inspect_Volume
           (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
         is
            Raw     : constant C.Mat_Handle := Convert (H);
            Output  : aliased Rec := Sentinel;
            Input   : aliased constant Rec := Sample;
            Indices : aliased C.C_Int32_Array (0 .. 2) := (1, 2, 3);
         begin
            Assert
              (Get_ND (Raw, 3, Indices (0)'Access, Output'Access)
               = C.Error_Invalid_Argument
               and then Output = Zero,
               Label & ": N-D Get must reject and zero the full record");
            Assert
              (Set_ND (Raw, 3, Indices (0)'Access, Input'Access)
               = C.Error_Invalid_Argument,
               Label & ": N-D Set must reject");
         end Inspect_Volume;
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle
           (Plain, Inspect_Plain'Access);
         OpenCV.Core.Module_Interop.With_Input_Handle
           (Volume, Inspect_Volume'Access);
      end Wrong_Layout;

      --  Geometry fixtures are exactly matching Float16 C2/C4 Mats so each
      --  rejection is caused by the tested coordinate or pointer alone.
      procedure Geometry is
         Plain  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (2, 3, (OpenCV.Core.Float16, Channel_Count (Width)));
         Volume : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Shape        => (2, 3, 4),
              Element_Type => (OpenCV.Core.Float16, Channel_Count (Width)));
         Input  : aliased constant Rec := Sample;
         Output : aliased Rec := Sentinel;

         procedure Inspect_Plain
           (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
         is
            Raw  : constant C.Mat_Handle := Convert (H);
            Row  : Word_Array (0 .. 3 * Width - 1);
            Back : Word_Array (0 .. 3 * Width - 1) := (others => 0);

            procedure Reject (Label : String; R, Column : C.C_Int32) is
            begin
               Output := Sentinel;
               Assert
                 (Get (Raw, R, Column, Output'Access)
                  = C.Error_Invalid_Argument
                  and then Output = Zero,
                  Name & " 2-D " & Label & " must reject and zero Get");
               Assert
                 (Set (Raw, R, Column, Input'Access)
                  = C.Error_Invalid_Argument,
                  Name & " 2-D " & Label & " must reject Set");
            end Reject;
         begin
            Assert
              (Set (Raw, 1, 2, Input'Access) = C.Success,
               Name & " raw 2-D Set must succeed on a matching Mat");
            Assert
              (Get (Raw, 1, 2, Output'Access) = C.Success
               and then Output = Sample,
               Name & " raw 2-D record must round-trip exact bits");
            Assert
              (Get (Raw, 0, 0, null) = C.Error_Invalid_Argument,
               Name & " 2-D Get must reject a null output");
            Assert
              (Set (Raw, 0, 0, null) = C.Error_Invalid_Argument,
               Name & " 2-D Set must reject a null input");
            Reject ("negative row", -1, 0);
            Reject ("row extent", 2, 0);
            Reject ("negative column", 0, -1);
            Reject ("column extent", 0, 3);

            --  uint16_t row ABI: component order is channel order.
            for Index in Row'Range loop
               Row (Index) := 16#7E00# + C.C_UInt16 (Index);
            end loop;
            Row (0 .. Width - 1) := Sample_Words;
            Assert
              (Write_Row (Raw, 0, Row (0)'Address, 3) = C.Success,
               Name & " raw row write must succeed");
            Assert
              (Read_Row (Raw, 0, Back (0)'Address, 3) = C.Success
               and then Back = Row,
               Name & " raw row must round-trip exact uint16_t bits");
            Output := Sentinel;
            Assert
              (Get (Raw, 0, 0, Output'Access) = C.Success
               and then Output = Sample,
               Name & " row words must map to record components in order");
            Assert
              (Read_Row (Raw, 1, Back (0)'Address, 3) = C.Success
               and then Back (2 * Width .. 3 * Width - 1) = Sample_Words,
               Name & " record components must map to row words in order");
            Assert
              (Read_Row (Raw, 0, Back (0)'Address, 2)
               = C.Error_Invalid_Argument,
               Name & " row read must reject a column-count mismatch");
            Assert
              (Read_Row (Raw, 0, System.Null_Address, 3)
               = C.Error_Invalid_Argument
               and then Write_Row (Raw, 0, System.Null_Address, 3)
                        = C.Error_Invalid_Argument,
               Name & " row copies must reject null data");
            Assert
              (Read_Row (Raw, 2, Back (0)'Address, 3)
               = C.Error_Invalid_Argument
               and then Read_Row (Raw, -1, Back (0)'Address, 3)
                        = C.Error_Invalid_Argument,
               Name & " row copies must reject rows outside the Mat");
         end Inspect_Plain;

         procedure Inspect_Volume
           (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
         is
            Raw     : constant C.Mat_Handle := Convert (H);
            Indices : aliased C.C_Int32_Array (0 .. 2);
            Back    : Word_Array (0 .. 3 * Width - 1) := (others => 0);

            procedure Reject
              (Label      : String;
               Count      : C.C_Int32 := 3;
               Null_Index : Boolean := False) is
            begin
               Output := Sentinel;
               Assert
                 (Get_ND
                    (Raw,
                     Count,
                     (if Null_Index then null else Indices (0)'Access),
                     Output'Access)
                  = C.Error_Invalid_Argument
                  and then Output = Zero,
                  Name & " N-D " & Label & " must reject and zero Get");
               Assert
                 (Set_ND
                    (Raw,
                     Count,
                     (if Null_Index then null else Indices (0)'Access),
                     Input'Access)
                  = C.Error_Invalid_Argument,
                  Name & " N-D " & Label & " must reject Set");
            end Reject;
         begin
            Indices := (1, 2, 3);
            Assert
              (Set_ND (Raw, 3, Indices (0)'Access, Input'Access) = C.Success,
               Name & " raw N-D Set must succeed on a matching Mat");
            Output := Sentinel;
            Assert
              (Get_ND (Raw, 3, Indices (0)'Access, Output'Access) = C.Success
               and then Output = Sample,
               Name & " raw N-D record must round-trip exact bits");
            Assert
              (Get_ND (Raw, 3, Indices (0)'Access, null)
               = C.Error_Invalid_Argument,
               Name & " N-D Get must reject a null output");
            Assert
              (Set_ND (Raw, 3, Indices (0)'Access, null)
               = C.Error_Invalid_Argument,
               Name & " N-D Set must reject a null input");
            Reject ("null indices", Null_Index => True);
            Reject ("dimension count", Count => 2);
            Indices := (-1, 0, 0);
            Reject ("negative coordinate");
            Indices := (0, 0, 4);
            Reject ("inner past extent");
            Indices := (2, 0, 0);
            Reject ("outer past extent");

            Output := Sentinel;
            Assert
              (Get (Raw, 0, 0, Output'Access) = C.Error_Invalid_Argument
               and then Output = Zero,
               Name & " 2-D Get must reject a genuine N-D Mat");
            Assert
              (Read_Row (Raw, 0, Back (0)'Address, 3)
               = C.Error_Invalid_Argument,
               Name & " row read must reject a genuine N-D Mat");
         end Inspect_Volume;

         Null_Indices : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
         Words        : Word_Array (0 .. 3 * Width - 1) := (others => 0);
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle
           (Plain, Inspect_Plain'Access);
         OpenCV.Core.Module_Interop.With_Input_Handle
           (Volume, Inspect_Volume'Access);

         Output := Sentinel;
         Assert
           (Get (C.Null_Mat_Handle, 0, 0, Output'Access)
            = C.Error_Invalid_Argument
            and then Output = Zero,
            Name & " 2-D Get must reject a null Mat and zero output");
         Assert
           (Set (C.Null_Mat_Handle, 0, 0, Input'Access)
            = C.Error_Invalid_Argument,
            Name & " 2-D Set must reject a null Mat");
         Output := Sentinel;
         Assert
           (Get_ND
              (C.Null_Mat_Handle, 3, Null_Indices (0)'Access, Output'Access)
            = C.Error_Invalid_Argument
            and then Output = Zero,
            Name & " N-D Get must reject a null Mat and zero output");
         Assert
           (Set_ND
              (C.Null_Mat_Handle, 3, Null_Indices (0)'Access, Input'Access)
            = C.Error_Invalid_Argument,
            Name & " N-D Set must reject a null Mat");
         Assert
           (Read_Row (C.Null_Mat_Handle, 0, Words (0)'Address, 3)
            = C.Error_Invalid_Argument
            and then Write_Row (C.Null_Mat_Handle, 0, Words (0)'Address, 3)
                     = C.Error_Invalid_Argument,
            Name & " row copies must reject a null Mat");
      end Geometry;
   end Probes;

   --  Sample encodings: signaling-NaN payload, -0, smallest subnormal and
   --  negative NaN payload, so any float conversion would be detected.
   package Vec2_Probes is new
     Probes
       (Rec          => C.Float16_Vec2,
        Width        => 2,
        Zero         => (0, 0),
        Sentinel     => (16#AAAA#, 16#5555#),
        Sample       => (16#7C01#, 16#8000#),
        Sample_Words => (16#7C01#, 16#8000#),
        Get          => C.Mat_Get_Float16_Vec2,
        Set          => C.Mat_Set_Float16_Vec2,
        Get_ND       => C.Mat_Get_Float16_Vec2_ND,
        Set_ND       => C.Mat_Set_Float16_Vec2_ND,
        Read_Row     => C.Mat_Read_Float16_Vec2_Row,
        Write_Row    => C.Mat_Write_Float16_Vec2_Row);

   package Vec4_Probes is new
     Probes
       (Rec          => C.Float16_Vec4,
        Width        => 4,
        Zero         => (0, 0, 0, 0),
        Sentinel     => (16#AAAA#, 16#5555#, 16#AAAA#, 16#5555#),
        Sample       => (16#7C01#, 16#8000#, 16#0001#, 16#FC01#),
        Sample_Words => (16#7C01#, 16#8000#, 16#0001#, 16#FC01#),
        Get          => C.Mat_Get_Float16_Vec4,
        Set          => C.Mat_Set_Float16_Vec4,
        Get_ND       => C.Mat_Get_Float16_Vec4_ND,
        Set_ND       => C.Mat_Set_Float16_Vec4_ND,
        Read_Row     => C.Mat_Read_Float16_Vec4_Row,
        Write_Row    => C.Mat_Write_Float16_Vec4_Row);

   procedure Check_Wrong_Layouts
     (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
   begin
      --  Float16 C2 is 4 bytes; an equal byte count is never type identity.
      Vec2_Probes.Wrong_Layout (OpenCV.Core.UInt16, 2);
      Vec2_Probes.Wrong_Layout (OpenCV.Core.Int16, 2);
      Vec2_Probes.Wrong_Layout (OpenCV.Core.UInt8, 4);
      Vec2_Probes.Wrong_Layout (OpenCV.Core.Float32, 1);
      Vec2_Probes.Wrong_Layout (OpenCV.Core.Int32, 1);
      --  Same depth, wrong channel count.
      Vec2_Probes.Wrong_Layout (OpenCV.Core.Float16, 1);
      Vec2_Probes.Wrong_Layout (OpenCV.Core.Float16, 3);
      Vec2_Probes.Wrong_Layout (OpenCV.Core.Float16, 4);

      --  Float16 C4 is 8 bytes.
      Vec4_Probes.Wrong_Layout (OpenCV.Core.UInt16, 4);
      Vec4_Probes.Wrong_Layout (OpenCV.Core.Int16, 4);
      Vec4_Probes.Wrong_Layout (OpenCV.Core.Int32, 2);
      Vec4_Probes.Wrong_Layout (OpenCV.Core.Float32, 2);
      Vec4_Probes.Wrong_Layout (OpenCV.Core.Float64, 1);
      Vec4_Probes.Wrong_Layout (OpenCV.Core.UInt8, 8);
      Vec4_Probes.Wrong_Layout (OpenCV.Core.Float16, 2);
      Vec4_Probes.Wrong_Layout (OpenCV.Core.Float16, 3);
   end Check_Wrong_Layouts;

   procedure Check_Geometry (Test : in out Mat_Test_Support.Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
   begin
      Vec2_Probes.Geometry;
      Vec4_Probes.Geometry;
   end Check_Geometry;
end Float16_Vector_Tests.Raw_ABI;
