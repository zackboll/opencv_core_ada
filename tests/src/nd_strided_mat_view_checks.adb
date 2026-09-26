with AUnit.Assertions;
with Mat_Test_Support;
with OpenCV;
with System;

package body ND_Strided_Mat_View_Checks is

   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Dimension_Array;
   use type OpenCV.Core.Mat_Size;
   use type System.Address;

   --  Deliberately nonzero caller lower bound; the Mat must not see it.
   First : constant := 17;

   Padding  : constant Natural := 50;
   Trailing : constant Natural := 60;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      AUnit.Assertions.Assert (Condition, Name & " " & Message);
   end Check;

   --  Packed (logical) ordinal of (I, J, K) in a 2 x 3 x 4 volume.
   function Ordinal (I, J, K : Natural) return Natural
   is (((I * 3) + J) * 4 + K);

   --  Caller offset of (I, J, K) under canonical strides (20, 6, 1).
   function Gapped (I, J, K : Natural) return Natural
   is (I * 20 + J * 6 + K);

   function Is_Logical (Offset : Natural) return Boolean
   is (Offset mod 20 < 18 and then (Offset mod 20) mod 6 < 4);

   function Index (I, J, K : Natural) return OpenCV.Core.Index_Array
   is (OpenCV.Size_Coordinate (I),
       OpenCV.Size_Coordinate (J),
       OpenCV.Size_Coordinate (K));

   function Index (Row, Column : Natural) return OpenCV.Core.Index_Array
   is (OpenCV.Size_Coordinate (Row), OpenCV.Size_Coordinate (Column));

   --  Canonical 40-element gapped fixture: every padding position holds the
   --  padding sentinel, every logical position its packed ordinal value.
   procedure Fill_Gapped (Data : out View_Array) is
   begin
      Data := (others => Value_At (Padding));
      for I in 0 .. 1 loop
         for J in 0 .. 2 loop
            for K in 0 .. 3 loop
               Data (Data'First + Gapped (I, J, K)) :=
                 Value_At (Ordinal (I, J, K));
            end loop;
         end loop;
      end loop;
   end Fill_Gapped;

   procedure Check_Padding (Data : View_Array; Label : String) is
   begin
      for Offset in 0 .. 39 loop
         if not Is_Logical (Offset) then
            Check
              (Data (Data'First + Offset) = Value_At (Padding),
               Label & ": padding offset" & Offset'Image & " was modified");
         end if;
      end loop;
   end Check_Padding;

   procedure Check_Type (Image : OpenCV.Core.Mat; Label : String) is
   begin
      Check
        (Image.Depth = Element_Type.Depth
         and then Image.Channels = Element_Type.Channels,
         Label & " must have the expected depth and channel count");
   end Check_Type;

   procedure Check_Gapped_Volume is
      Shape         : constant OpenCV.Core.Dimension_Array (7 .. 9) :=
        (2, 3, 4);
      Strides       : constant OpenCV.Core.Dimension_Stride_Array (11 .. 13) :=
        (20, 6, 1);
      Data          : aliased View_Array :=
        (First .. First + 39 => Value_At (Padding));
      Invoked       : Boolean := False;
      Read_Invoked  : Boolean := False;
      Write_Invoked : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is

         procedure Inspect (Buffer : aliased Borrow_Array) is
            pragma Unreferenced (Buffer);
         begin
            Read_Invoked := True;
         end Inspect;

         procedure Mutate (Buffer : aliased in out Borrow_Array) is
            pragma Unreferenced (Buffer);
         begin
            Write_Invoked := True;
         end Mutate;

         procedure Attempt_Read is
         begin
            With_Read_Only_Buffer (Image, Inspect'Access);
         end Attempt_Read;

         procedure Attempt_Write is
         begin
            With_Writable_Buffer (Image, Mutate'Access);
         end Attempt_Write;
      begin
         Invoked := True;
         Check
           (Image.Dimension_Count = 3
            and then Image.Shape = OpenCV.Core.Dimension_Array'(2, 3, 4)
            and then Image.Total = 24,
            "gapped view must report a 2 x 3 x 4 shape with 24 elements");
         Check_Type (Image, "gapped view");
         Check
           (not Image.Is_Continuous,
            "gapped (20, 6, 1) view must not be continuous");

         for I in 0 .. 1 loop
            for J in 0 .. 2 loop
               for K in 0 .. 3 loop
                  Check
                    (Get (Image, Index (I, J, K))
                     = Data (First + Gapped (I, J, K))
                     and then Get (Image, Index (I, J, K))
                              = Value_At (Ordinal (I, J, K)),
                     "N-D Get must read caller Data at I*20 + J*6 + K");
               end loop;
            end loop;
         end loop;

         --  Required spot offsets with the shifted Data'First = 17.
         Set (Image, Index (0, 0, 0), Value_At (100));
         Set (Image, Index (0, 1, 2), Value_At (101));
         Set (Image, Index (1, 0, 0), Value_At (102));
         Set (Image, Index (1, 2, 3), Value_At (103));
         Check
           (Data (17) = Value_At (100)
            and then Data (25) = Value_At (101)
            and then Data (37) = Value_At (102)
            and then Data (52) = Value_At (103),
            "N-D Set must write Data (17), (25), (37), and (52)");

         Data (First + Gapped (1, 1, 0)) := Value_At (100);
         Check
           (Get (Image, Index (1, 1, 0)) = Value_At (100),
            "a direct caller write must be visible to N-D Get");

         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Read'Access,
            Name & " gapped view read-only buffer borrow must be rejected");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Write'Access,
            Name & " gapped view writable buffer borrow must be rejected");
      end Process;
   begin
      Fill_Gapped (Data);
      With_Strided_View (Data, Shape, Strides, Process'Access);
      Check (Invoked, "gapped view callback must be invoked");
      Check
        (not Read_Invoked and then not Write_Invoked,
         "rejected buffer borrows must not run their callbacks");
      Check_Padding (Data, "gapped view");
      Check
        (Data (First + Gapped (0, 0, 1)) = Value_At (Ordinal (0, 0, 1))
         and then Data (First + Gapped (1, 2, 2))
                  = Value_At (Ordinal (1, 2, 2)),
         "untouched logical elements must keep their values");
   end Check_Gapped_Volume;

   procedure Check_Packed_Equivalent is
      --  24 required elements plus 4 trailing elements outside the header.
      Data          : aliased View_Array :=
        (First .. First + 27 => Value_At (Trailing));
      Packed        : aliased View_Array :=
        (First .. First + 23 => Value_At (Trailing));
      Invoked       : Boolean := False;
      Packed_Seen   : Boolean := False;
      Read_Invoked  : Boolean := False;
      Write_Invoked : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is

         procedure Inspect (Buffer : aliased Borrow_Array) is
         begin
            Read_Invoked := True;
            Check
              (Buffer'First = 0
               and then Buffer'Length = 24
               and then Buffer (0)'Address = Data (First)'Address,
               "packed-equivalent read-only borrow must alias caller Data");
            for Position in 0 .. 23 loop
               Check
                 (Buffer (Position) = Data (First + Position),
                  "packed-equivalent read-only borrow must match Data");
            end loop;
         end Inspect;

         procedure Mutate (Buffer : aliased in out Borrow_Array) is
         begin
            Write_Invoked := True;
            Check
              (Buffer'Length = 24
               and then Buffer (0)'Address = Data (First)'Address,
               "packed-equivalent writable borrow must alias caller Data");
            Buffer (Ordinal (1, 0, 0)) := Value_At (100);
         end Mutate;
      begin
         Invoked := True;
         Check
           (Image.Dimension_Count = 3
            and then Image.Shape = OpenCV.Core.Dimension_Array'(2, 3, 4)
            and then Image.Total = 24,
            "packed-equivalent view must report a 2 x 3 x 4 shape");
         Check_Type (Image, "packed-equivalent view");
         Check
           (Image.Is_Continuous,
            "strides (12, 4, 1) describe packed storage and must be"
            & " continuous");
         for I in 0 .. 1 loop
            for J in 0 .. 2 loop
               for K in 0 .. 3 loop
                  Check
                    (Get (Image, Index (I, J, K))
                     = Value_At (Ordinal (I, J, K)),
                     "packed-equivalent Get must use packed ordering");
               end loop;
            end loop;
         end loop;
         With_Read_Only_Buffer (Image, Inspect'Access);
         With_Writable_Buffer (Image, Mutate'Access);
         Check
           (Data (First + 12) = Value_At (100)
            and then Get (Image, Index (1, 0, 0)) = Value_At (100),
            "nested buffer write must reach caller Data and N-D Get");
         Set (Image, Index (1, 2, 3), Value_At (101));
      end Process;

      procedure Compare (Image : in out OpenCV.Core.Mat) is
      begin
         Packed_Seen := True;
         Check
           (Image.Is_Continuous and then Image.Total = 24,
            "packed Shape overload must be continuous");
         for I in 0 .. 1 loop
            for J in 0 .. 2 loop
               for K in 0 .. 3 loop
                  Check
                    (Get (Image, Index (I, J, K))
                     = Packed (First + Ordinal (I, J, K)),
                     "packed Shape and packed-equivalent strided views must"
                     & " share one logical ordering");
               end loop;
            end loop;
         end loop;
      end Compare;
   begin
      for Position in 0 .. 23 loop
         Data (First + Position) := Value_At (Position);
      end loop;
      for Position in 24 .. 27 loop
         Data (First + Position) := Value_At (Trailing);
      end loop;

      With_Strided_View (Data, (2, 3, 4), (12, 4, 1), Process'Access);
      Check
        (Invoked and then Read_Invoked and then Write_Invoked,
         "packed-equivalent callbacks and nested borrows must run");
      Check
        (Data (First + 23) = Value_At (101),
         "packed-equivalent N-D Set must reach the final caller element");
      for Position in 24 .. 27 loop
         Check
           (Data (First + Position) = Value_At (Trailing),
            "extra trailing storage must be untouched");
      end loop;

      Packed := Data (First .. First + 23);
      With_Shape_View (Packed, (2, 3, 4), Compare'Access);
      Check (Packed_Seen, "packed Shape callback must be invoked");
   end Check_Packed_Equivalent;

   procedure Check_Two_Dimensional_Equivalence is
      Data           : aliased View_Array :=
        (First .. First + 9 => Value_At (Padding));
      Strided_Seen   : Boolean := False;
      Row_Seen       : Boolean := False;
      Strided_Contig : Boolean := True;
      Row_Contig     : Boolean := True;

      procedure Verify (Image : OpenCV.Core.Mat; Label : String) is
      begin
         Check
           (Image.Dimension_Count = 2
            and then Image.Rows = 2
            and then Image.Columns = 3
            and then Image.Total = 6,
            Label & " must be a 2 x 3 Mat");
         Check_Type (Image, Label);
         for Row in 0 .. 1 loop
            for Column in 0 .. 2 loop
               Check
                 (Get (Image, Index (Row, Column))
                  = Data (First + Row * 5 + Column),
                  Label & " must map (Row, Column) to Row * 5 + Column");
            end loop;
         end loop;
      end Verify;

      procedure By_Strides (Image : in out OpenCV.Core.Mat) is
      begin
         Strided_Seen := True;
         Strided_Contig := Image.Is_Continuous;
         Verify (Image, "Shape (2, 3), Strides (5, 1) view");
         Set (Image, Index (1, 2), Value_At (100));
      end By_Strides;

      procedure By_Row_Stride (Image : in out OpenCV.Core.Mat) is
      begin
         Row_Seen := True;
         Row_Contig := Image.Is_Continuous;
         Verify (Image, "Rows 2, Columns 3, Row_Stride 5 view");
         Check
           (Get (Image, Index (1, 2)) = Value_At (100),
            "the row-strided view must see the N-D strided write");
         Set (Image, Index (0, 1), Value_At (101));
      end By_Row_Stride;
   begin
      Data := (others => Value_At (Padding));
      for Row in 0 .. 1 loop
         for Column in 0 .. 2 loop
            Data (First + Row * 5 + Column) := Value_At (Row * 3 + Column);
         end loop;
      end loop;

      With_Strided_View (Data, (2, 3), (5, 1), By_Strides'Access);
      With_Row_Strided_View (Data, 2, 3, 5, By_Row_Stride'Access);
      Check
        (Strided_Seen and then Row_Seen,
         "both 2-D strided callbacks must be invoked");
      Check
        (not Strided_Contig and then not Row_Contig,
         "both padded 2-D strided views must be non-continuous");
      Check
        (Data (First + 7) = Value_At (100)
         and then Data (First + 1) = Value_At (101),
         "both 2-D strided views must write the same caller offsets");
      for Offset in 0 .. 9 loop
         if Offset mod 5 >= 3 then
            Check
              (Data (First + Offset) = Value_At (Padding),
               "2-D strided padding must be untouched");
         end if;
      end loop;
   end Check_Two_Dimensional_Equivalence;

   procedure Check_No_Escape_And_Clone is
      Data    : aliased View_Array :=
        (First .. First + 39 => Value_At (Padding));
      Copy    : OpenCV.Core.Mat;
      Invoked : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is

         procedure Attempt_Slice is
            Ignored : constant OpenCV.Core.Mat :=
              Image.Slice (((0, 1), (0, 3), (0, 4)));
         begin
            null;
         end Attempt_Slice;

         procedure Attempt_Reshape is
            Ignored : constant OpenCV.Core.Mat :=
              Image.Reshape (Shape => (6, 4));
         begin
            null;
         end Attempt_Reshape;

         procedure Attempt_Copy is
            Alias : OpenCV.Core.Mat;
            pragma Unreferenced (Alias);
         begin
            Alias := Image;
         exception
            when Program_Error =>
               raise OpenCV.OpenCV_Error;
         end Attempt_Copy;
      begin
         Invoked := True;
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Slice'Access,
            Name & " strided N-D view Slice must be rejected");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Reshape'Access,
            Name & " strided N-D view Reshape must be rejected");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Copy'Access,
            Name & " strided N-D view shallow copy must be rejected");
         Copy := Image.Clone;
      end Process;
   begin
      Fill_Gapped (Data);
      With_Strided_View (Data, (2, 3, 4), (20, 6, 1), Process'Access);
      Check (Invoked, "no-escape callback must be invoked");
      Check_Padding (Data, "rejected escapes");

      --  Mutate caller logical data and padding after the callback.
      Data (First) := Value_At (100);
      Data (First + 4) := Value_At (101);
      Data (First + 39) := Value_At (102);

      Check
        (Copy.Dimension_Count = 3
         and then Copy.Shape = OpenCV.Core.Dimension_Array'(2, 3, 4)
         and then Copy.Total = 24
         and then Copy.Is_Continuous,
         "Clone must be a continuous owned 2 x 3 x 4 Mat");
      Check_Type (Copy, "Clone");
      for I in 0 .. 1 loop
         for J in 0 .. 2 loop
            for K in 0 .. 3 loop
               Check
                 (Get (Copy, Index (I, J, K)) = Value_At (Ordinal (I, J, K)),
                  "Clone must hold the original logical values only");
            end loop;
         end loop;
      end loop;

      Set (Copy, Index (1, 2, 3), Value_At (103));
      Check
        (Data (First + Gapped (1, 2, 3)) = Value_At (Ordinal (1, 2, 3)),
         "Clone writes must not affect caller Data");

      declare
         Tail : constant OpenCV.Core.Mat :=
           Copy.Slice (((1, 2), (0, 3), (0, 4)));
         Flat : constant OpenCV.Core.Mat := Copy.Reshape (Shape => (6, 4));
      begin
         Check
           (Tail.Total = 12
            and then Get (Tail, Index (0, 0, 0)) = Value_At (12)
            and then Get (Tail, Index (0, 2, 3)) = Value_At (103),
            "an owned Clone must Slice normally");
         Check
           (Flat.Dimension_Count = 2
            and then Get (Flat, Index (0, 0)) = Value_At (0)
            and then Get (Flat, Index (5, 3)) = Value_At (103),
            "an owned Clone must Reshape normally");
      end;
   end Check_No_Escape_And_Clone;

end ND_Strided_Mat_View_Checks;
