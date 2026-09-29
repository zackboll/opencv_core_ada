with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float16_Vec2;
with OpenCV.Core.Float16_Vec4;
with OpenCV.Core.Float16_Vec2_Access;
with OpenCV.Core.Float16_Vec4_Access;
with OpenCV.Core.Float16_Vec2_Row_Access;
with OpenCV.Core.Float16_Vec4_Row_Access;
with OpenCV.Core.Float16_Vec2_Buffer_Access;
with OpenCV.Core.Float16_Vec4_Buffer_Access;
with OpenCV.Core.Float16_Vec2_Mat_View;
with OpenCV.Core.Float16_Vec4_Mat_View;
with OpenCV.Core.Float32_Vec2;
with OpenCV.Core.Float32_Vec4;
with OpenCV.Core.Float32_Vec2_Access;
with OpenCV.Core.Float32_Vec4_Access;
with Float16_Vector_Tests.Raw_ABI;

package body Float16_Vector_Tests is
   use Mat_Test_Support;
   use type Interfaces.Unsigned_16;
   use type Interfaces.IEEE_Float_32;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   subtype Word is Interfaces.Unsigned_16;
   subtype V2 is OpenCV.Core.Float16_Vec2.Vector;
   subtype V4 is OpenCV.Core.Float16_Vec4.Vector;

   --  Special binary16 encodings. All comparisons are on stored bits.
   Pos_Zero       : constant Word := 16#0000#;
   Neg_Zero       : constant Word := 16#8000#;
   Min_Subnormal  : constant Word := 16#0001#;
   Max_Subnormal  : constant Word := 16#03FF#;
   Min_Normal     : constant Word := 16#0400#;
   Pos_One        : constant Word := 16#3C00#;
   Neg_One        : constant Word := 16#BC00#;
   Max_Finite     : constant Word := 16#7BFF#;
   Neg_Max_Finite : constant Word := 16#FBFF#;
   Pos_Inf        : constant Word := 16#7C00#;
   Neg_Inf        : constant Word := 16#FC00#;
   Signaling_NaN  : constant Word := 16#7C01#;
   Quiet_NaN      : constant Word := 16#7E00#;
   Neg_NaN        : constant Word := 16#FC01#;
   Alt_Payload    : constant Word := 16#7E55#;

   Specials : constant array (Positive range <>) of Word :=
     (Pos_Zero,
      Neg_Zero,
      Min_Subnormal,
      Max_Subnormal,
      Min_Normal,
      Pos_One,
      Neg_One,
      Max_Finite,
      Neg_Max_Finite,
      Pos_Inf,
      Neg_Inf,
      Signaling_NaN,
      Quiet_NaN,
      Neg_NaN,
      Alt_Payload);

   function F (Bits : Word) return OpenCV.Core.Float16_Value
   renames OpenCV.Core.Float16_From_Bits;
   function B (Value : OpenCV.Core.Float16_Value) return Word
   renames OpenCV.Core.Float16_Bits;

   function Make2 (C0, C1 : Word) return V2
   is ((0 => F (C0), 1 => F (C1)));
   function Make4 (C0, C1, C2, C3 : Word) return V4
   is ((0 => F (C0), 1 => F (C1), 2 => F (C2), 3 => F (C3)));

   --  Bit-level vector identity; never uses Float16 numeric equality.
   function Same (Left, Right : V2) return Boolean
   is (B (Left (0)) = B (Right (0)) and then B (Left (1)) = B (Right (1)));
   function Same (Left, Right : V4) return Boolean
   is (for all I in V4'Range => B (Left (I)) = B (Right (I)));

   --  Rotating patterns of special encodings, distinct per offset.
   function Pattern2 (Offset : Natural) return V2
   is (Make2
         (Specials (Specials'First + Offset mod Specials'Length),
          Specials (Specials'First + (Offset + 7) mod Specials'Length)));
   function Pattern4 (Offset : Natural) return V4
   is (Make4
         (Specials (Specials'First + Offset mod Specials'Length),
          Specials (Specials'First + (Offset + 4) mod Specials'Length),
          Specials (Specials'First + (Offset + 9) mod Specials'Length),
          Specials (Specials'First + (Offset + 13) mod Specials'Length)));

   function C2_Mat (Rows, Columns : Positive) return OpenCV.Core.Mat
   is (OpenCV.Core.Create (Rows, Columns, (OpenCV.Core.Float16, 2)));
   function C4_Mat (Rows, Columns : Positive) return OpenCV.Core.Mat
   is (OpenCV.Core.Create (Rows, Columns, (OpenCV.Core.Float16, 4)));

   --  2-D and N-D Get/Set of every special encoding in every component,
   --  with neighbours kept at distinct sentinels to detect overwrites.
   procedure Special_Encodings_Round_Trip (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2     : OpenCV.Core.Mat := C2_Mat (3, 3);
      M4     : OpenCV.Core.Mat := C4_Mat (3, 3);
      N2     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float16, 2));
      N4     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float16, 4));
      Guard2 : constant V2 := Make2 (16#1111#, 16#2222#);
      Guard4 : constant V4 := Make4 (16#1111#, 16#2222#, 16#3333#, 16#4444#);
      --  Shifted Ada bounds exercise logical iteration order.
      Centre : constant OpenCV.Core.Index_Array (11 .. 13) := (1, 1, 2);
      Next   : constant OpenCV.Core.Index_Array (40 .. 42) := (1, 1, 3);
      Before : constant OpenCV.Core.Index_Array := (1, 1, 1);

      procedure Check_Neighbours (Id : String) is
      begin
         AUnit.Assertions.Assert
           (Same (OpenCV.Core.Float16_Vec2_Access.Get (M2, 1, 0), Guard2)
            and then Same
                       (OpenCV.Core.Float16_Vec2_Access.Get (M2, 1, 2), Guard2)
            and then Same
                       (OpenCV.Core.Float16_Vec2_Access.Get (M2, 0, 1), Guard2)
            and then Same
                       (OpenCV.Core.Float16_Vec4_Access.Get (M4, 1, 0), Guard4)
            and then Same
                       (OpenCV.Core.Float16_Vec4_Access.Get (M4, 1, 2), Guard4)
            and then Same
                       (OpenCV.Core.Float16_Vec4_Access.Get (M4, 2, 1),
                        Guard4),
            "2-D writes must not touch neighbouring elements" & Id);
         AUnit.Assertions.Assert
           (Same (OpenCV.Core.Float16_Vec2_Access.Get (N2, Before), Guard2)
            and then Same
                       (OpenCV.Core.Float16_Vec2_Access.Get (N2, Next), Guard2)
            and then Same
                       (OpenCV.Core.Float16_Vec4_Access.Get (N4, Before),
                        Guard4)
            and then Same
                       (OpenCV.Core.Float16_Vec4_Access.Get (N4, Next),
                        Guard4),
            "N-D writes must not touch neighbouring elements" & Id);
      end Check_Neighbours;
   begin
      for Row in 0 .. 2 loop
         for Column in 0 .. 2 loop
            OpenCV.Core.Float16_Vec2_Access.Set (M2, Row, Column, Guard2);
            OpenCV.Core.Float16_Vec4_Access.Set (M4, Row, Column, Guard4);
         end loop;
      end loop;
      OpenCV.Core.Float16_Vec2_Access.Set (N2, Before, Guard2);
      OpenCV.Core.Float16_Vec2_Access.Set (N2, Next, Guard2);
      OpenCV.Core.Float16_Vec4_Access.Set (N4, Before, Guard4);
      OpenCV.Core.Float16_Vec4_Access.Set (N4, Next, Guard4);

      for Offset in 0 .. Specials'Length - 1 loop
         declare
            P2 : constant V2 := Pattern2 (Offset);
            P4 : constant V4 := Pattern4 (Offset);
            Id : constant String := Natural'Image (Offset);
         begin
            OpenCV.Core.Float16_Vec2_Access.Set (M2, 1, 1, P2);
            OpenCV.Core.Float16_Vec4_Access.Set (M4, 1, 1, P4);
            AUnit.Assertions.Assert
              (Same (OpenCV.Core.Float16_Vec2_Access.Get (M2, 1, 1), P2)
               and then Same
                          (OpenCV.Core.Float16_Vec4_Access.Get (M4, 1, 1), P4),
               "2-D exact binary16 round trip, pattern" & Id);
            OpenCV.Core.Float16_Vec2_Access.Set (N2, Centre, P2);
            OpenCV.Core.Float16_Vec4_Access.Set (N4, Centre, P4);
            AUnit.Assertions.Assert
              (Same (OpenCV.Core.Float16_Vec2_Access.Get (N2, (1, 1, 2)), P2)
               and then Same
                          (OpenCV.Core.Float16_Vec4_Access.Get (N4, Centre),
                           P4),
               "N-D exact binary16 round trip, pattern" & Id);
            Check_Neighbours (Id);
         end;
      end loop;
   end Special_Encodings_Round_Trip;

   --  Component k is OpenCV channel k: verified through Split.
   procedure Component_Order_Is_Channel_Order (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2 : OpenCV.Core.Mat := C2_Mat (1, 2);
      M4 : OpenCV.Core.Mat := C4_Mat (1, 2);
   begin
      OpenCV.Core.Float16_Vec2_Access.Set
        (M2, 0, 1, Make2 (Signaling_NaN, Neg_Zero));
      OpenCV.Core.Float16_Vec4_Access.Set
        (M4, 0, 1, Make4 (Min_Subnormal, Neg_Inf, Alt_Payload, Max_Finite));
      declare
         P2 : constant OpenCV.Core.Mat_Array := M2.Split;
         P4 : constant OpenCV.Core.Mat_Array := M4.Split;
         function Channel
           (Parts : OpenCV.Core.Mat_Array; K : Natural) return Word
         is (B
               (OpenCV.Core.Float16_Access.Get
                  (Parts (Parts'First + K), 0, 1)));
      begin
         AUnit.Assertions.Assert
           (Channel (P2, 0) = Signaling_NaN
            and then Channel (P2, 1) = Neg_Zero,
            "Float16 Vec2 component order must be channel order");
         AUnit.Assertions.Assert
           (Channel (P4, 0) = Min_Subnormal
            and then Channel (P4, 1) = Neg_Inf
            and then Channel (P4, 2) = Alt_Payload
            and then Channel (P4, 3) = Max_Finite,
            "Float16 Vec4 component order must be channel order");
      end;
   end Component_Order_Is_Channel_Order;

   procedure Assignment_Clone_And_Region (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2      : OpenCV.Core.Mat := C2_Mat (3, 4);
      M4      : OpenCV.Core.Mat := C4_Mat (3, 4);
      A2      : constant V2 := Make2 (Neg_NaN, Min_Normal);
      A4      : constant V4 := Make4 (Neg_NaN, Min_Normal, Neg_Zero, Pos_Inf);
      W2      : constant V2 := Make2 (Quiet_NaN, Max_Subnormal);
      W4      : constant V4 :=
        Make4 (Quiet_NaN, Max_Subnormal, Neg_One, Neg_Max_Finite);
      Alias2  : OpenCV.Core.Mat;
      Alias4  : OpenCV.Core.Mat;
      Copy2   : OpenCV.Core.Mat;
      Copy4   : OpenCV.Core.Mat;
      Region2 : OpenCV.Core.Mat;
      Region4 : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float16_Vec2_Access.Set (M2, 2, 3, A2);
      OpenCV.Core.Float16_Vec4_Access.Set (M4, 2, 3, A4);
      Alias2 := M2;
      Alias4 := M4;
      Copy2 := M2.Clone;
      Copy4 := M4.Clone;
      OpenCV.Core.Float16_Vec2_Access.Set (Alias2, 2, 3, W2);
      OpenCV.Core.Float16_Vec4_Access.Set (Alias4, 2, 3, W4);
      AUnit.Assertions.Assert
        (Same (OpenCV.Core.Float16_Vec2_Access.Get (M2, 2, 3), W2)
         and then Same (OpenCV.Core.Float16_Vec4_Access.Get (M4, 2, 3), W4),
         "shallow assignment must share Float16 C2/C4 storage");
      AUnit.Assertions.Assert
        (Same (OpenCV.Core.Float16_Vec2_Access.Get (Copy2, 2, 3), A2)
         and then Same (OpenCV.Core.Float16_Vec4_Access.Get (Copy4, 2, 3), A4),
         "Clone must isolate exact Float16 C2/C4 bits");

      Region2 := M2.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Region4 := M4.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      OpenCV.Core.Float16_Vec2_Access.Set (Region2, 0, 0, A2);
      OpenCV.Core.Float16_Vec4_Access.Set (Region4, 0, 0, A4);
      AUnit.Assertions.Assert
        (Same (OpenCV.Core.Float16_Vec2_Access.Get (M2, 1, 1), A2)
         and then Same (OpenCV.Core.Float16_Vec4_Access.Get (M4, 1, 1), A4)
         and then Same
                    (OpenCV.Core.Float16_Vec2_Access.Get (Region2, 1, 2), W2)
         and then Same
                    (OpenCV.Core.Float16_Vec4_Access.Get (Region4, 1, 2), W4),
         "Region must share parent Float16 C2/C4 storage");
   end Assignment_Clone_And_Region;

   procedure Reports_Ada_Representation (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      AUnit.Assertions.Assert
        (V2'Size = 32
         and then OpenCV.Core.Float16_Vec2.Vector'Object_Size = 32
         and then OpenCV.Core.Float16_Vec2.Vector'Component_Size = 16
         and then OpenCV.Core.Float16_Vec2.Vector'Alignment <= 2
         and then V4'Size = 64
         and then OpenCV.Core.Float16_Vec4.Vector'Object_Size = 64
         and then OpenCV.Core.Float16_Vec4.Vector'Component_Size = 16
         and then OpenCV.Core.Float16_Vec4.Vector'Alignment <= 2,
         "Float16 Vec2/Vec4 must be 32/64-bit packed, alignment <= 2");
   end Reports_Ada_Representation;

   procedure Typed_Access_Rejects_Invalid_Requests (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2    : OpenCV.Core.Mat := C2_Mat (2, 3);
      M4    : constant OpenCV.Core.Mat := C4_Mat (2, 3);
      M3    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float16, 3));
      U16   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 2));
      F64   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 1));
      N2    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float16, 2));
      Empty : OpenCV.Core.Mat;
      Probe : V2 := Make2 (0, 0);
      Wide  : V4 := Make4 (0, 0, 0, 0);

      procedure Wrong_Channels is
      begin
         Probe := OpenCV.Core.Float16_Vec2_Access.Get (M3, 0, 0);
      end Wrong_Channels;
      procedure Same_Bytes_Wrong_Depth is
      begin
         Probe := OpenCV.Core.Float16_Vec2_Access.Get (U16, 0, 0);
      end Same_Bytes_Wrong_Depth;
      procedure C4_Same_Bytes_Wrong_Depth is
      begin
         Wide := OpenCV.Core.Float16_Vec4_Access.Get (F64, 0, 0);
      end C4_Same_Bytes_Wrong_Depth;
      procedure C4_Accessor_On_C2 is
      begin
         Wide := OpenCV.Core.Float16_Vec4_Access.Get (M2, 0, 0);
      end C4_Accessor_On_C2;
      procedure Negative_Row is
      begin
         OpenCV.Core.Float16_Vec2_Access.Set (M2, -1, 0, Probe);
      end Negative_Row;
      procedure Row_Extent is
      begin
         Wide := OpenCV.Core.Float16_Vec4_Access.Get (M4, 2, 0);
      end Row_Extent;
      procedure Negative_Column is
      begin
         Probe := OpenCV.Core.Float16_Vec2_Access.Get (M2, 0, -1);
      end Negative_Column;
      procedure Column_Extent is
      begin
         Wide := OpenCV.Core.Float16_Vec4_Access.Get (M4, 0, 3);
      end Column_Extent;
      procedure Two_D_On_Volume is
      begin
         Probe := OpenCV.Core.Float16_Vec2_Access.Get (N2, 0, 0);
      end Two_D_On_Volume;
      procedure Index_Count is
      begin
         Probe := OpenCV.Core.Float16_Vec2_Access.Get (N2, (0, 0));
      end Index_Count;
      procedure Index_Extent is
      begin
         Probe := OpenCV.Core.Float16_Vec2_Access.Get (N2, (1, 2, 4));
      end Index_Extent;
      procedure Default_Mat is
      begin
         Probe := OpenCV.Core.Float16_Vec2_Access.Get (Empty, 0, 0);
      end Default_Mat;
   begin
      Assert_Raises_OpenCV_Error
        (Wrong_Channels'Access, "Vec2 must reject a Float16 C3 Mat");
      Assert_Raises_OpenCV_Error
        (Same_Bytes_Wrong_Depth'Access, "Vec2 must reject UInt16 C2");
      Assert_Raises_OpenCV_Error
        (C4_Same_Bytes_Wrong_Depth'Access, "Vec4 must reject Float64 C1");
      Assert_Raises_OpenCV_Error
        (C4_Accessor_On_C2'Access, "Vec4 must reject a Float16 C2 Mat");
      Assert_Raises_OpenCV_Error (Negative_Row'Access, "negative row");
      Assert_Raises_OpenCV_Error (Row_Extent'Access, "row extent");
      Assert_Raises_OpenCV_Error (Negative_Column'Access, "negative column");
      Assert_Raises_OpenCV_Error (Column_Extent'Access, "column extent");
      Assert_Raises_OpenCV_Error
        (Two_D_On_Volume'Access, "Row/Column access requires a 2-D Mat");
      Assert_Raises_OpenCV_Error
        (Index_Count'Access, "N-D access requires one index per dimension");
      Assert_Raises_OpenCV_Error
        (Index_Extent'Access, "N-D access rejects a coordinate past extent");
      Assert_Raises_OpenCV_Error
        (Default_Mat'Access, "typed access rejects a default Mat");
      AUnit.Assertions.Assert
        (B (Probe (0)) = 0
         and then B (Probe (1)) = 0
         and then (for all I in V4'Range => B (Wide (I)) = 0),
         "rejected requests must not produce a value");
   end Typed_Access_Rejects_Invalid_Requests;

   Lease_Error : exception;

   --  Copied rows with shifted Ada bounds, then callback-scoped borrowed
   --  rows that survive rebinding of the Mat and a Region's parent.
   procedure Rows_And_Leases (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2        : OpenCV.Core.Mat := C2_Mat (2, 3);
      M4        : OpenCV.Core.Mat := C4_Mat (2, 3);
      Parent    : OpenCV.Core.Mat := C4_Mat (3, 5);
      Region    : OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      Survivor2 : constant OpenCV.Core.Mat := M2;
      Survivor4 : constant OpenCV.Core.Mat := M4;
      Kept      : constant OpenCV.Core.Mat := Region;
      In2       : OpenCV.Core.Float16_Vec2_Row_Access.Row_Array (7 .. 9);
      In4       : OpenCV.Core.Float16_Vec4_Row_Access.Row_Array (7 .. 9);
      Out2      : OpenCV.Core.Float16_Vec2_Row_Access.Row_Array (40 .. 42);
      Out4      : OpenCV.Core.Float16_Vec4_Row_Access.Row_Array (40 .. 42);
      Short2    : OpenCV.Core.Float16_Vec2_Row_Access.Row_Array (0 .. 1);

      procedure Read2
        (Data : aliased OpenCV.Core.Float16_Vec2_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0
            and then Data'Length = 3
            and then (for all I in 0 .. 2 => Same (Data (I), In2 (7 + I))),
            "borrowed Vec2 row must expose exact stored bits");
      end Read2;
      procedure Read4
        (Data : aliased OpenCV.Core.Float16_Vec4_Row_Access.Row_Array) is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0
            and then Data'Length = 3
            and then (for all I in 0 .. 2 => Same (Data (I), In4 (7 + I))),
            "borrowed Vec4 row must expose exact stored bits");
      end Read4;
      procedure Edit2
        (Data : aliased in out OpenCV.Core.Float16_Vec2_Row_Access.Row_Array)
      is
      begin
         M2 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (2) := Make2 (Neg_NaN, Signaling_NaN);
         raise Lease_Error;
      end Edit2;
      procedure Edit4
        (Data : aliased in out OpenCV.Core.Float16_Vec4_Row_Access.Row_Array)
      is
      begin
         M4 := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (2) := Make4 (Neg_NaN, Signaling_NaN, Neg_Zero, Min_Subnormal);
         raise Lease_Error;
      end Edit4;
      procedure Edit_Region
        (Data : aliased in out OpenCV.Core.Float16_Vec4_Row_Access.Row_Array)
      is
      begin
         Parent := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Region := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
         Data (1) := Make4 (Alt_Payload, Quiet_NaN, Neg_Inf, Max_Finite);
      end Edit_Region;
      procedure Bad_Length is
      begin
         OpenCV.Core.Float16_Vec2_Row_Access.Read_Row (Survivor2, 0, Short2);
      end Bad_Length;
      procedure Bad_Row is
      begin
         OpenCV.Core.Float16_Vec4_Row_Access.Read_Row (Survivor4, 2, Out4);
      end Bad_Row;
   begin
      for I in 0 .. 2 loop
         In2 (7 + I) := Pattern2 (I * 5);
         In4 (7 + I) := Pattern4 (I * 5);
      end loop;
      OpenCV.Core.Float16_Vec2_Row_Access.Write_Row (M2, 1, In2);
      OpenCV.Core.Float16_Vec4_Row_Access.Write_Row (M4, 1, In4);
      OpenCV.Core.Float16_Vec2_Row_Access.Read_Row (M2, 1, Out2);
      OpenCV.Core.Float16_Vec4_Row_Access.Read_Row (M4, 1, Out4);
      AUnit.Assertions.Assert
        ((for all I in 0 .. 2 => Same (Out2 (40 + I), In2 (7 + I)))
         and then (for all I in 0 .. 2 => Same (Out4 (40 + I), In4 (7 + I))),
         "copied rows with shifted bounds must preserve exact bits");
      AUnit.Assertions.Assert
        (Same (OpenCV.Core.Float16_Vec2_Access.Get (M2, 1, 2), In2 (9))
         and then Same
                    (OpenCV.Core.Float16_Vec4_Access.Get (M4, 1, 0), In4 (7)),
         "copied rows must map array order to column order");

      OpenCV.Core.Float16_Vec2_Row_Access.With_Read_Only_Row
        (M2, 1, Read2'Access);
      OpenCV.Core.Float16_Vec4_Row_Access.With_Read_Only_Row
        (M4, 1, Read4'Access);
      begin
         OpenCV.Core.Float16_Vec2_Row_Access.With_Writable_Row
           (M2, 1, Edit2'Access);
         AUnit.Assertions.Assert (False, "Vec2 row exception must propagate");
      exception
         when Lease_Error =>
            null;
      end;
      begin
         OpenCV.Core.Float16_Vec4_Row_Access.With_Writable_Row
           (M4, 1, Edit4'Access);
         AUnit.Assertions.Assert (False, "Vec4 row exception must propagate");
      exception
         when Lease_Error =>
            null;
      end;
      AUnit.Assertions.Assert
        (Same
           (OpenCV.Core.Float16_Vec2_Access.Get (Survivor2, 1, 2),
            Make2 (Neg_NaN, Signaling_NaN))
         and then Same
                    (OpenCV.Core.Float16_Vec4_Access.Get (Survivor4, 1, 2),
                     Make4 (Neg_NaN, Signaling_NaN, Neg_Zero, Min_Subnormal)),
         "leased rows survive rebinding; completed writes remain visible");

      OpenCV.Core.Float16_Vec4_Row_Access.With_Writable_Row
        (Region, 1, Edit_Region'Access);
      AUnit.Assertions.Assert
        (Same
           (OpenCV.Core.Float16_Vec4_Access.Get (Kept, 1, 1),
            Make4 (Alt_Payload, Quiet_NaN, Neg_Inf, Max_Finite)),
         "Region row lease survives parent and Region rebinding");
      Assert_Raises_OpenCV_Error
        (Bad_Length'Access, "copied row length must equal columns");
      Assert_Raises_OpenCV_Error
        (Bad_Row'Access, "copied row index must be inside the Mat");
   end Rows_And_Leases;

   procedure Buffers_Borrow_Exact_Elements (Test : in out Fixture) is
      pragma Unreferenced (Test);
      N2     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float16, 2));
      M4     : OpenCV.Core.Mat := C4_Mat (2, 3);
      Parent : constant OpenCV.Core.Mat := C2_Mat (3, 4);
      Gapped : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      Called : Boolean := False;

      procedure Fill2
        (Data :
           aliased in out OpenCV.Core.Float16_Vec2_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 24,
            "N-D C2 buffer must expose 24 complete Vec2 elements");
         for I in Data'Range loop
            Data (I) := Pattern2 (I);
         end loop;
      end Fill2;
      procedure Fill4
        (Data :
           aliased in out OpenCV.Core.Float16_Vec4_Buffer_Access.Buffer_Array)
      is
      begin
         AUnit.Assertions.Assert
           (Data'Length = 6, "2-D C4 buffer must expose 6 Vec4 elements");
         for I in Data'Range loop
            Data (I) := Pattern4 (I);
         end loop;
      end Fill4;
      procedure Read4
        (Data : aliased OpenCV.Core.Float16_Vec4_Buffer_Access.Buffer_Array) is
      begin
         AUnit.Assertions.Assert
           ((for all I in Data'Range => Same (Data (I), Pattern4 (I))),
            "read-only C4 buffer must expose exact stored bits");
      end Read4;
      procedure Never
        (Data : aliased OpenCV.Core.Float16_Vec2_Buffer_Access.Buffer_Array)
      is
         pragma Unreferenced (Data);
      begin
         Called := True;
      end Never;
      procedure Bad_Buffer is
      begin
         OpenCV.Core.Float16_Vec2_Buffer_Access.With_Read_Only_Buffer
           (Gapped, Never'Access);
      end Bad_Buffer;
   begin
      OpenCV.Core.Float16_Vec2_Buffer_Access.With_Writable_Buffer
        (N2, Fill2'Access);
      AUnit.Assertions.Assert
        (Same
           (OpenCV.Core.Float16_Vec2_Access.Get (N2, (0, 0, 0)), Pattern2 (0))
         and then Same
                    (OpenCV.Core.Float16_Vec2_Access.Get (N2, (1, 2, 3)),
                     Pattern2 (23))
         and then Same
                    (OpenCV.Core.Float16_Vec2_Access.Get (N2, (1, 0, 2)),
                     Pattern2 (14)),
         "N-D C2 buffer order must be OpenCV element order");
      OpenCV.Core.Float16_Vec4_Buffer_Access.With_Writable_Buffer
        (M4, Fill4'Access);
      OpenCV.Core.Float16_Vec4_Buffer_Access.With_Read_Only_Buffer
        (M4, Read4'Access);
      AUnit.Assertions.Assert
        (Same (OpenCV.Core.Float16_Vec4_Access.Get (M4, 1, 2), Pattern4 (5)),
         "2-D C4 buffer element Row * Columns + Column");
      Assert_Raises_OpenCV_Error
        (Bad_Buffer'Access, "gapped C2 Region buffer must be rejected");
      AUnit.Assertions.Assert
        (not Called, "rejected buffer must not invoke Process");
   end Buffers_Borrow_Exact_Elements;

   --  Caller-owned views: strides count complete vectors; padding and
   --  trailing storage stay untouched; Clone escapes independently.
   procedure Caller_Views_Preserve_Bits_And_Padding (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Pad2    : constant V2 := Make2 (16#DEAD#, 16#BEEF#);
      Pad4    : constant V4 := Make4 (16#DEAD#, 16#BEEF#, 16#CAFE#, 16#F00D#);
      --  2 x 2 logical elements, row stride 3 complete vectors.
      S2      : aliased OpenCV.Core.Float16_Vec2_Mat_View.Buffer_Array :=
        (10 .. 15 => Pad2);
      S4      : aliased OpenCV.Core.Float16_Vec4_Mat_View.Buffer_Array :=
        (10 .. 15 => Pad4);
      --  (2, 2, 2) logical elements with strides (6, 3, 1).
      G4      : aliased OpenCV.Core.Float16_Vec4_Mat_View.Buffer_Array :=
        (0 .. 11 => Pad4);
      P2      : aliased OpenCV.Core.Float16_Vec2_Mat_View.Buffer_Array :=
        (5 .. 8 => Make2 (0, 0));
      Escaped : OpenCV.Core.Mat;

      procedure Strided2 (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (not Image.Is_Continuous, "padded C2 view is non-continuous");
         OpenCV.Core.Float16_Vec2_Access.Set (Image, 1, 1, Pattern2 (3));
         Escaped := Image.Clone;
      end Strided2;
      procedure Strided4 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Float16_Vec4_Access.Set (Image, 1, 0, Pattern4 (2));
      end Strided4;
      procedure Strided_ND4 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Float16_Vec4_Access.Set (Image, (1, 1, 1), Pattern4 (6));
         OpenCV.Core.Float16_Vec4_Access.Set (Image, (0, 1, 0), Pattern4 (8));
      end Strided_ND4;
      procedure Packed_ND2 (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Float16_Vec2_Access.Set (Image, (1, 0, 1), Pattern2 (11));
      end Packed_ND2;
      procedure Read_Only4 (Image : OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Same
              (OpenCV.Core.Float16_Vec4_Access.Get (Image, (1, 1, 1)),
               Pattern4 (6)),
            "read-only strided N-D C4 view must observe exact bits");
      end Read_Only4;
      procedure Read_Only2 (Image : OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Same
              (OpenCV.Core.Float16_Vec2_Access.Get (Image, 1, 1),
               Pattern2 (3)),
            "read-only strided 2-D C2 view must observe exact bits");
      end Read_Only2;
   begin
      OpenCV.Core.Float16_Vec2_Mat_View.With_Writable_Strided_Mat_View
        (S2, 2, 2, 3, Strided2'Access);
      AUnit.Assertions.Assert
        (Same (S2 (14), Pattern2 (3))
         and then Same (S2 (12), Pad2)
         and then Same (S2 (15), Pad2),
         "C2 row stride counts complete vectors; padding untouched");
      OpenCV.Core.Float16_Vec2_Mat_View.With_Read_Only_Strided_Mat_View
        (S2, 2, 2, 3, Read_Only2'Access);
      OpenCV.Core.Float16_Vec2_Access.Set (Escaped, 1, 1, Pattern2 (4));
      AUnit.Assertions.Assert
        (Same (S2 (14), Pattern2 (3)),
         "Clone of a caller view must own independent storage");

      OpenCV.Core.Float16_Vec4_Mat_View.With_Writable_Strided_Mat_View
        (S4, 2, 2, 3, Strided4'Access);
      AUnit.Assertions.Assert
        (Same (S4 (13), Pattern4 (2))
         and then Same (S4 (12), Pad4)
         and then Same (S4 (15), Pad4),
         "C4 row stride counts complete vectors; padding untouched");

      OpenCV.Core.Float16_Vec4_Mat_View.With_Writable_Strided_Mat_View
        (G4, (2, 2, 2), (6, 3, 1), Strided_ND4'Access);
      AUnit.Assertions.Assert
        (Same (G4 (10), Pattern4 (6))
         and then Same (G4 (3), Pattern4 (8))
         and then Same (G4 (2), Pad4)
         and then Same (G4 (11), Pad4),
         "C4 N-D strides count complete vectors; padding untouched");
      OpenCV.Core.Float16_Vec4_Mat_View.With_Read_Only_Strided_Mat_View
        (G4, (2, 2, 2), (6, 3, 1), Read_Only4'Access);

      OpenCV.Core.Float16_Vec2_Mat_View.With_Writable_Mat_View
        (P2, (2, 1, 2), Packed_ND2'Access);
      AUnit.Assertions.Assert
        (Same (P2 (8), Pattern2 (11)),
         "packed N-D C2 view must alias caller element order");
   end Caller_Views_Preserve_Bits_And_Padding;

   --  Exhaustive evidence: every one of the 65,536 binary16 encodings is
   --  carried in every component offset. Element I holds encoding
   --  (I + K * Step) mod 2**16 in component K, so each component column is
   --  a permutation of all encodings and neighbouring components differ.
   --  Each encoding crosses (1) a zero-copy caller view, (2) shim 2-D
   --  Get/Set, (3) copied uint16_t rows and (4) whole-buffer borrowing.
   Encodings : constant := 65_536;

   function Encoding (I, K, Step : Natural) return Word
   is (Word ((I + K * Step) mod Encodings));

   procedure All_Encodings_Vec2 (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data     : aliased OpenCV.Core.Float16_Vec2_Mat_View.Buffer_Array :=
        (3 .. 3 + Encodings - 1 => Make2 (0, 0));
      Mismatch : Natural := 0;
      Copy     : OpenCV.Core.Mat;

      function Expected (I : Natural; Reverse_Order : Boolean) return V2
      is (if Reverse_Order
          then Make2 (Encoding (I, 1, 32_768), Encoding (I, 0, 0))
          else Make2 (Encoding (I, 0, 0), Encoding (I, 1, 32_768)));

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         for Row in 0 .. 255 loop
            for Column in 0 .. 255 loop
               declare
                  I : constant Natural := Row * 256 + Column;
               begin
                  if not Same
                           (OpenCV.Core.Float16_Vec2_Access.Get
                              (Image, Row, Column),
                            Expected (I, False))
                  then
                     Mismatch := Mismatch + 1;
                  end if;
                  OpenCV.Core.Float16_Vec2_Access.Set
                    (Image, Row, Column, Expected (I, True));
               end;
            end loop;
         end loop;
         Copy := Image.Clone;
      end Process;

      procedure Check_Rows is
         Line : OpenCV.Core.Float16_Vec2_Row_Access.Row_Array (100 .. 355);
      begin
         for Row in 0 .. 255 loop
            OpenCV.Core.Float16_Vec2_Row_Access.Read_Row (Copy, Row, Line);
            OpenCV.Core.Float16_Vec2_Row_Access.Write_Row (Copy, Row, Line);
            for Column in 0 .. 255 loop
               if not Same
                        (Line (100 + Column),
                         Expected (Row * 256 + Column, True))
               then
                  Mismatch := Mismatch + 1;
               end if;
            end loop;
         end loop;
      end Check_Rows;

      procedure Check_Buffer
        (Buffer : aliased OpenCV.Core.Float16_Vec2_Buffer_Access.Buffer_Array)
      is
      begin
         for I in Buffer'Range loop
            if not Same (Buffer (I), Expected (I, True)) then
               Mismatch := Mismatch + 1;
            end if;
         end loop;
      end Check_Buffer;
   begin
      for I in 0 .. Encodings - 1 loop
         Data (Data'First + I) := Expected (I, False);
      end loop;
      OpenCV.Core.Float16_Vec2_Mat_View.With_Writable_Mat_View
        (Data, 256, 256, Process'Access);
      AUnit.Assertions.Assert
        (Mismatch = 0, "shim Get must observe all 65536 encodings in C2");
      for I in 0 .. Encodings - 1 loop
         if not Same (Data (Data'First + I), Expected (I, True)) then
            Mismatch := Mismatch + 1;
         end if;
      end loop;
      AUnit.Assertions.Assert
        (Mismatch = 0, "shim Set must store all 65536 encodings in C2");
      Check_Rows;
      AUnit.Assertions.Assert
        (Mismatch = 0, "C2 copied rows must preserve all 65536 encodings");
      OpenCV.Core.Float16_Vec2_Buffer_Access.With_Read_Only_Buffer
        (Copy, Check_Buffer'Access);
      AUnit.Assertions.Assert
        (Mismatch = 0, "C2 buffer borrow must preserve all 65536 encodings");
   end All_Encodings_Vec2;

   --  Vec4: components use steps 0, 16_411, 32_768 and 49_157 so the four
   --  encodings of one element always differ and every component offset
   --  carries every encoding. Encodings cross a padded row-strided caller
   --  view, shim 2-D Get and Index_Array Set (rotating the component
   --  offset), copied rows (rotating again) and whole-buffer borrowing.
   procedure All_Encodings_Vec4 (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Steps    : constant array (0 .. 3) of Natural :=
        (0, 16_411, 32_768, 49_157);
      Pad      : constant V4 := Make4 (16#DEAD#, 16#BEEF#, 16#CAFE#, 16#F00D#);
      --  (256, 256) logical elements, row stride 257: one padding element.
      Data     : aliased OpenCV.Core.Float16_Vec4_Mat_View.Buffer_Array :=
        (1 .. 256 * 257 => Pad);
      Mismatch : Natural := 0;
      Copy     : OpenCV.Core.Mat;

      function Expected (I : Natural; Rotate : Natural) return V4
      is (Make4
            (Encoding (I, 1, Steps ((0 + Rotate) mod 4)),
             Encoding (I, 1, Steps ((1 + Rotate) mod 4)),
             Encoding (I, 1, Steps ((2 + Rotate) mod 4)),
             Encoding (I, 1, Steps ((3 + Rotate) mod 4))));

      function Slot (I : Natural) return Positive
      is (Data'First + (I / 256) * 257 + I mod 256);

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         for Row in 0 .. 255 loop
            for Column in 0 .. 255 loop
               declare
                  I : constant Natural := Row * 256 + Column;
               begin
                  if not Same
                           (OpenCV.Core.Float16_Vec4_Access.Get
                              (Image, Row, Column),
                            Expected (I, 0))
                  then
                     Mismatch := Mismatch + 1;
                  end if;
                  --  Rotating components moves each encoding to a new
                  --  component offset on the way back.
                  OpenCV.Core.Float16_Vec4_Access.Set
                    (Image,
                     OpenCV.Core.Index_Array'
                       (OpenCV.Size_Coordinate (Row),
                        OpenCV.Size_Coordinate (Column)),
                     Expected (I, 1));
               end;
            end loop;
         end loop;
         Copy := Image.Clone;
      end Process;

      procedure Check_Rows is
         Line : OpenCV.Core.Float16_Vec4_Row_Access.Row_Array (9 .. 264);
      begin
         for Row in 0 .. 255 loop
            OpenCV.Core.Float16_Vec4_Row_Access.Read_Row (Copy, Row, Line);
            for Column in 0 .. 255 loop
               if not Same
                        (Line (9 + Column), Expected (Row * 256 + Column, 1))
               then
                  Mismatch := Mismatch + 1;
               end if;
               Line (9 + Column) := Expected (Row * 256 + Column, 2);
            end loop;
            OpenCV.Core.Float16_Vec4_Row_Access.Write_Row (Copy, Row, Line);
         end loop;
      end Check_Rows;

      procedure Check_Buffer
        (Buffer : aliased OpenCV.Core.Float16_Vec4_Buffer_Access.Buffer_Array)
      is
      begin
         for I in Buffer'Range loop
            if not Same (Buffer (I), Expected (I, 2)) then
               Mismatch := Mismatch + 1;
            end if;
         end loop;
      end Check_Buffer;
   begin
      for I in 0 .. Encodings - 1 loop
         Data (Slot (I)) := Expected (I, 0);
      end loop;
      OpenCV.Core.Float16_Vec4_Mat_View.With_Writable_Strided_Mat_View
        (Data, 256, 256, 257, Process'Access);
      AUnit.Assertions.Assert
        (Mismatch = 0, "shim Get must observe all 65536 encodings in C4");
      for I in 0 .. Encodings - 1 loop
         if not Same (Data (Slot (I)), Expected (I, 1)) then
            Mismatch := Mismatch + 1;
         end if;
      end loop;
      for Row in 0 .. 255 loop
         if not Same (Data (Data'First + Row * 257 + 256), Pad) then
            Mismatch := Mismatch + 1;
         end if;
      end loop;
      AUnit.Assertions.Assert
        (Mismatch = 0,
         "C4 N-D Set must store all 65536 encodings; padding untouched");
      Check_Rows;
      AUnit.Assertions.Assert
        (Mismatch = 0, "C4 copied rows must preserve all 65536 encodings");
      OpenCV.Core.Float16_Vec4_Buffer_Access.With_Read_Only_Buffer
        (Copy, Check_Buffer'Access);
      AUnit.Assertions.Assert
        (Mismatch = 0, "C4 buffer borrow must preserve all 65536 encodings");
   end All_Encodings_Vec4;

   --  Merge of Float16 C1 channels into C2/C4 and Split back: channel
   --  manipulation moves storage bits, it does not convert numerically.
   procedure Merge_Split_Preserve_Exact_Bits (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Words : constant array (0 .. 3) of Word :=
        (Neg_Zero, Min_Subnormal, Neg_Inf, Signaling_NaN);
      Other : constant array (0 .. 3) of Word :=
        (Alt_Payload, Neg_NaN, Max_Subnormal, Pos_Zero);
      Parts : OpenCV.Core.Mat_Array (1 .. 4) :=
        (others => OpenCV.Core.Create (1, 2, (OpenCV.Core.Float16, 1)));

      procedure Check (Width : Positive) is
         Merged : constant OpenCV.Core.Mat :=
           OpenCV.Core.Merge (Parts (1 .. Width));
         Split  : constant OpenCV.Core.Mat_Array := Merged.Split;
      begin
         AUnit.Assertions.Assert
           (Merged.Depth = OpenCV.Core.Float16
            and then Merged.Channels = OpenCV.Core.Channel_Count (Width),
            "Merge must produce Float16 C" & Positive'Image (Width));
         if Width = 2 then
            AUnit.Assertions.Assert
              (Same
                 (OpenCV.Core.Float16_Vec2_Access.Get (Merged, 0, 0),
                  Make2 (Words (0), Words (1)))
               and then Same
                          (OpenCV.Core.Float16_Vec2_Access.Get (Merged, 0, 1),
                           Make2 (Other (0), Other (1))),
               "Merge into C2 must preserve exact component bits");
         else
            AUnit.Assertions.Assert
              (Same
                 (OpenCV.Core.Float16_Vec4_Access.Get (Merged, 0, 0),
                  Make4 (Words (0), Words (1), Words (2), Words (3)))
               and then Same
                          (OpenCV.Core.Float16_Vec4_Access.Get (Merged, 0, 1),
                           Make4 (Other (0), Other (1), Other (2), Other (3))),
               "Merge into C4 must preserve exact component bits");
         end if;
         AUnit.Assertions.Assert
           (Split'Length = Width, "Split must return one Mat per channel");
         for K in 0 .. Width - 1 loop
            AUnit.Assertions.Assert
              (B
                 (OpenCV.Core.Float16_Access.Get
                    (Split (Split'First + K), 0, 0))
               = Words (K)
               and then B
                          (OpenCV.Core.Float16_Access.Get
                             (Split (Split'First + K), 0, 1))
                        = Other (K),
               "Split must restore exact channel bits" & Natural'Image (K));
         end loop;
      end Check;
   begin
      for K in 0 .. 3 loop
         OpenCV.Core.Float16_Access.Set (Parts (K + 1), 0, 0, F (Words (K)));
         OpenCV.Core.Float16_Access.Set (Parts (K + 1), 0, 1, F (Other (K)));
      end loop;
      Check (2);
      Check (4);
   end Merge_Split_Preserve_Exact_Bits;

   --  Set_To with finite representable values confirms channel order only;
   --  it is not evidence of NaN-payload preservation.
   procedure Set_To_Fills_Channels_In_Order (Test : in out Fixture) is
      pragma Unreferenced (Test);
      M2 : OpenCV.Core.Mat := C2_Mat (2, 2);
      M4 : OpenCV.Core.Mat := C4_Mat (2, 2);
   begin
      M2.Set_To (OpenCV.Make_Scalar (1.0, -2.0));
      M4.Set_To (OpenCV.Make_Scalar (0.5, -1.0, 65_504.0, 0.0));
      AUnit.Assertions.Assert
        (Same
           (OpenCV.Core.Float16_Vec2_Access.Get (M2, 1, 1),
            Make2 (Pos_One, 16#C000#)),
         "Set_To must fill Float16 C2 channels in order");
      AUnit.Assertions.Assert
        (Same
           (OpenCV.Core.Float16_Vec4_Access.Get (M4, 1, 0),
            Make4 (16#3800#, Neg_One, Max_Finite, Pos_Zero)),
         "Set_To must fill Float16 C4 channels in order");
   end Set_To_Fills_Channels_In_Order;

   --  Numeric interoperability (not the raw-bit data plane): values that
   --  binary16 represents exactly convert Float32 -> Float16 -> Float32.
   procedure Convert_To_Round_Trips_Representable_Values
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      S2   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 2));
      S4   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 4));
      A    : constant OpenCV.Core.Float32_Vec2.Vector := (0.5, 1.0);
      Bv   : constant OpenCV.Core.Float32_Vec2.Vector :=
        (-2.0, 5.960_464_48E-08);
      C    : constant OpenCV.Core.Float32_Vec4.Vector :=
        (65_504.0, -2.0, 0.5, 5.960_464_48E-08);
      H2   : OpenCV.Core.Mat;
      H4   : OpenCV.Core.Mat;
      Back : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Vec2_Access.Set (S2, 0, 0, A);
      OpenCV.Core.Float32_Vec2_Access.Set (S2, 0, 1, Bv);
      OpenCV.Core.Float32_Vec4_Access.Set (S4, 0, 0, C);
      H2 := S2.Convert_To (Depth => OpenCV.Core.Float16);
      H4 := S4.Convert_To (Depth => OpenCV.Core.Float16);
      AUnit.Assertions.Assert
        (H2.Depth = OpenCV.Core.Float16
         and then H2.Channels = 2
         and then H4.Channels = 4,
         "Convert_To Float16 must keep the channel count");
      AUnit.Assertions.Assert
        (Same
           (OpenCV.Core.Float16_Vec2_Access.Get (H2, 0, 0),
            Make2 (16#3800#, Pos_One))
         and then Same
                    (OpenCV.Core.Float16_Vec2_Access.Get (H2, 0, 1),
                     Make2 (16#C000#, Min_Subnormal)),
         "Float32 C2 must convert to exact binary16 encodings in order");
      AUnit.Assertions.Assert
        (Same
           (OpenCV.Core.Float16_Vec4_Access.Get (H4, 0, 0),
            Make4 (Max_Finite, 16#C000#, 16#3800#, Min_Subnormal)),
         "Float32 C4 must convert to exact binary16 encodings in order");

      Back := H2.Convert_To (Depth => OpenCV.Core.Float32);
      declare
         R0 : constant OpenCV.Core.Float32_Vec2.Vector :=
           OpenCV.Core.Float32_Vec2_Access.Get (Back, 0, 0);
         R1 : constant OpenCV.Core.Float32_Vec2.Vector :=
           OpenCV.Core.Float32_Vec2_Access.Get (Back, 0, 1);
      begin
         AUnit.Assertions.Assert
           (R0 (0) = 0.5
            and then R0 (1) = 1.0
            and then R1 (0) = -2.0
            and then R1 (1) = 5.960_464_48E-08,
            "C2 Float16 -> Float32 must restore the original values");
      end;
      Back := H4.Convert_To (Depth => OpenCV.Core.Float32);
      declare
         R : constant OpenCV.Core.Float32_Vec4.Vector :=
           OpenCV.Core.Float32_Vec4_Access.Get (Back, 0, 0);
      begin
         AUnit.Assertions.Assert
           (R (0) = 65_504.0
            and then R (1) = -2.0
            and then R (2) = 0.5
            and then R (3) = 5.960_464_48E-08,
            "C4 Float16 -> Float32 must restore the original values");
      end;
   end Convert_To_Round_Trips_Representable_Values;

   --  Regression only: the existing channel-agnostic Float16 arithmetic path
   --  (native on OpenCV 5.x, Float32 fallback on 4.x) with exact finite
   --  results. Not evidence of raw-bit preservation.
   procedure Existing_Arithmetic_Accepts_C2_C4 (Test : in out Fixture) is
      pragma Unreferenced (Test);
      L2 : OpenCV.Core.Mat := C2_Mat (1, 2);
      R2 : OpenCV.Core.Mat := C2_Mat (1, 2);
      L4 : OpenCV.Core.Mat := C4_Mat (1, 1);
      R4 : OpenCV.Core.Mat := C4_Mat (1, 1);
   begin
      L2.Set_To (OpenCV.Make_Scalar (1.0, -2.0));
      R2.Set_To (OpenCV.Make_Scalar (0.5, 4.0));
      L4.Set_To (OpenCV.Make_Scalar (1.0, -2.0, 0.5, 8.0));
      R4.Set_To (OpenCV.Make_Scalar (1.0, 0.5, 2.0, -0.5));
      AUnit.Assertions.Assert
        (Same
           (OpenCV.Core.Float16_Vec2_Access.Get
              (OpenCV.Core.Add (L2, R2), 0, 1),
            Make2 (16#3E00#, 16#4000#)),
         "Float16 C2 Add must produce 1.5 and 2.0 per channel");
      AUnit.Assertions.Assert
        (Same
           (OpenCV.Core.Float16_Vec4_Access.Get
              (OpenCV.Core.Multiply (L4, R4), 0, 0),
            Make4 (Pos_One, Neg_One, Pos_One, 16#C400#)),
         "Float16 C4 Multiply must produce 1, -1, 1, -4 per channel");
   end Existing_Arithmetic_Accepts_C2_C4;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec2/Vec4 2-D and N-D special encodings round-trip",
            Special_Encodings_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec2/Vec4 component order is channel order",
            Component_Order_Is_Channel_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec2/Vec4 assignment shares, Clone isolates, Region",
            Assignment_Clone_And_Region'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec2/Vec4 Ada representation is packed 32/64-bit",
            Reports_Ada_Representation'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec2/Vec4 typed access rejects invalid requests",
            Typed_Access_Rejects_Invalid_Requests'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec2/Vec4 copied rows and borrowed row leases",
            Rows_And_Leases'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec2/Vec4 whole buffers borrow exact elements",
            Buffers_Borrow_Exact_Elements'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec2/Vec4 caller views preserve bits and padding",
            Caller_Views_Preserve_Bits_And_Padding'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec2 preserves all 65536 binary16 encodings",
            All_Encodings_Vec2'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec4 preserves all 65536 encodings in every component",
            All_Encodings_Vec4'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 C2/C4 Merge and Split preserve exact bits",
            Merge_Split_Preserve_Exact_Bits'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 C2/C4 Set_To fills channels in order",
            Set_To_Fills_Channels_In_Order'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 C2/C4 Convert_To round-trips representable Float32",
            Convert_To_Round_Trips_Representable_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 C2/C4 existing arithmetic regression",
            Existing_Arithmetic_Accepts_C2_C4'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec2/Vec4 raw ABI rejects same-byte wrong layouts",
            Raw_ABI.Check_Wrong_Layouts'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec2/Vec4 raw ABI geometry on matching layouts",
            Raw_ABI.Check_Geometry'Access));
      return Result'Access;
   end Suite;

end Float16_Vector_Tests;
