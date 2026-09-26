with AUnit.Assertions;
with Mat_Test_Support;
with OpenCV;
with System;

package body ND_Mat_View_Checks is

   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Dimension_Array;
   use type OpenCV.Core.Mat_Size;
   use type System.Address;

   --  Deliberately nonzero caller lower bound; the Mat must not see it.
   First : constant := 11;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      AUnit.Assertions.Assert (Condition, Name & " " & Message);
   end Check;

   function Offset (I, J, K : Natural) return Natural
   is (((I * 3) + J) * 4 + K);

   function Index (I, J, K : Natural) return OpenCV.Core.Index_Array
   is (OpenCV.Size_Coordinate (I),
       OpenCV.Size_Coordinate (J),
       OpenCV.Size_Coordinate (K));

   function Index (Row, Column : Natural) return OpenCV.Core.Index_Array
   is (OpenCV.Size_Coordinate (Row), OpenCV.Size_Coordinate (Column));

   procedure Fill (Data : out View_Array) is
   begin
      for Position in Data'Range loop
         Data (Position) := Value_At (Position - Data'First);
      end loop;
   end Fill;

   procedure Check_Type (Image : OpenCV.Core.Mat; Label : String) is
   begin
      Check
        (Image.Depth = Element_Type.Depth
         and then Image.Channels = Element_Type.Channels
         and then Image.Is_Continuous,
         Label & " must have the expected type and be continuous");
   end Check_Type;

   procedure Check_Volume is
      Shape         : constant OpenCV.Core.Dimension_Array (7 .. 9) :=
        (2, 3, 4);
      Data          : aliased View_Array :=
        (First .. First + 23 => Value_At (0));
      Invoked       : Boolean := False;
      Read_Invoked  : Boolean := False;
      Write_Invoked : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is

         procedure Inspect (Buffer : aliased Borrow_Array) is
         begin
            Read_Invoked := True;
            Check
              (Buffer'First = 0 and then Buffer'Length = 24,
               "nested read-only borrow must expose 24 elements from 0");
            Check
              (Buffer (0)'Address = Data (First)'Address,
               "nested read-only borrow must alias caller Data (no copy)");
            for Position in 0 .. 23 loop
               Check
                 (Buffer (Position) = Data (First + Position),
                  "nested read-only borrow must match caller Data");
            end loop;
         end Inspect;

         procedure Mutate (Buffer : aliased in out Borrow_Array) is
         begin
            Write_Invoked := True;
            Check
              (Buffer (0)'Address = Data (First)'Address
               and then Buffer'Length = 24,
               "nested writable borrow must alias caller Data (no copy)");
            Buffer (Offset (1, 0, 0)) := Value_At (102);
            Check
              (Data (First + 12) = Value_At (102)
               and then Get (Image, Index (1, 0, 0)) = Value_At (102),
               "nested buffer write must be visible in Data and N-D Get");
         end Mutate;
      begin
         Invoked := True;
         Check
           (Image.Dimension_Count = 3
            and then Image.Shape = OpenCV.Core.Dimension_Array'(2, 3, 4)
            and then Image.Shape = Shape
            and then Image.Total = 24,
            "N-D view must report a 2 x 3 x 4 shape with 24 elements");
         Check_Type (Image, "N-D view");

         for I in 0 .. 1 loop
            for J in 0 .. 2 loop
               for K in 0 .. 3 loop
                  Check
                    (Get (Image, Index (I, J, K))
                     = Data (First + Offset (I, J, K))
                     and then Get (Image, Index (I, J, K))
                              = Value_At (Offset (I, J, K)),
                     "N-D Get must read Data (First + ((I*3)+J)*4+K)");
               end loop;
            end loop;
         end loop;

         Check
           (Get (Image, Index (0, 0, 0)) = Data (11)
            and then Get (Image, Index (0, 1, 2)) = Data (17)
            and then Get (Image, Index (1, 0, 0)) = Data (23)
            and then Get (Image, Index (1, 2, 3)) = Data (34),
            "coordinates must map to caller offsets 0, 6, 12, and 23");

         Set (Image, Index (1, 2, 3), Value_At (100));
         Check
           (Data (First + 23) = Value_At (100),
            "N-D Set must be immediately visible in caller Data");

         Data (First + 6) := Value_At (101);
         Check
           (Get (Image, Index (0, 1, 2)) = Value_At (101),
            "caller Data writes must be immediately visible to N-D Get");

         With_Read_Only_Buffer (Image, Inspect'Access);
         With_Writable_Buffer (Image, Mutate'Access);
      end Process;
   begin
      Fill (Data);
      With_Shape_View (Data, Shape, Process'Access);
      Check
        (Invoked and then Read_Invoked and then Write_Invoked,
         "N-D view and nested buffer callbacks must be invoked");
      Check
        (Data (First + 23) = Value_At (100)
         and then Data (First + 6) = Value_At (101)
         and then Data (First + 12) = Value_At (102)
         and then Data (First) = Value_At (0),
         "caller Data must retain every write after the view ends");
   end Check_Volume;

   procedure Check_Two_Dimensional_Shape is
      Data          : aliased View_Array :=
        (First .. First + 5 => Value_At (0));
      Shape_Invoked : Boolean := False;
      Pair_Invoked  : Boolean := False;

      procedure Verify (Image : OpenCV.Core.Mat; Label : String) is
      begin
         Check
           (Image.Dimension_Count = 2
            and then Image.Rows = 2
            and then Image.Columns = 3
            and then Image.Shape = OpenCV.Core.Dimension_Array'(2, 3)
            and then Image.Total = 6,
            Label & " must be a 2 x 3 Mat");
         Check_Type (Image, Label);
         for Row in 0 .. 1 loop
            for Column in 0 .. 2 loop
               Check
                 (Get (Image, Index (Row, Column))
                  = Data (First + Row * 3 + Column),
                  Label & " must map (Row, Column) to Row * 3 + Column");
            end loop;
         end loop;
      end Verify;

      procedure By_Shape (Image : in out OpenCV.Core.Mat) is
      begin
         Shape_Invoked := True;
         Verify (Image, "Shape => (2, 3) view");
         Set (Image, Index (1, 2), Value_At (100));
      end By_Shape;

      procedure By_Rows_Columns (Image : in out OpenCV.Core.Mat) is
      begin
         Pair_Invoked := True;
         Verify (Image, "Rows => 2, Columns => 3 view");
         Check
           (Get (Image, Index (1, 2)) = Value_At (100),
            "the Rows/Columns view must see the Shape view's write");
      end By_Rows_Columns;
   begin
      Fill (Data);
      With_Shape_View (Data, (2, 3), By_Shape'Access);
      Check
        (Data (First + 5) = Value_At (100),
         "a 2-D Shape view write must reach caller Data");
      With_Rows_Columns_View (Data, 2, 3, By_Rows_Columns'Access);
      Check
        (Shape_Invoked and then Pair_Invoked,
         "both 2-D overload callbacks must be invoked");
   end Check_Two_Dimensional_Shape;

   procedure Check_No_Escape_And_Clone is
      Data    : aliased View_Array := (First .. First + 23 => Value_At (0));
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
      begin
         Invoked := True;
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Slice'Access,
            Name & " N-D external view Slice must be rejected");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Reshape'Access,
            Name & " N-D external view Reshape must be rejected");
         Copy := Image.Clone;
      end Process;
   begin
      Fill (Data);
      With_Shape_View (Data, (2, 3, 4), Process'Access);
      Check (Invoked, "no-escape callback must be invoked");
      Check
        (Data (First) = Value_At (0)
         and then Data (First + 23) = Value_At (23),
         "rejected Slice and Reshape must leave caller Data unchanged");

      Check
        (Copy.Dimension_Count = 3
         and then Copy.Shape = OpenCV.Core.Dimension_Array'(2, 3, 4),
         "Clone must preserve the N-D shape");
      Check_Type (Copy, "Clone");

      Data (First) := Value_At (100);
      Check
        (Get (Copy, Index (0, 0, 0)) = Value_At (0),
         "caller Data writes after the callback must not affect Clone");

      Set (Copy, Index (1, 2, 3), Value_At (101));
      Check
        (Data (First + 23) = Value_At (23),
         "Clone writes must not affect caller Data");

      declare
         Tail : constant OpenCV.Core.Mat :=
           Copy.Slice (((1, 2), (0, 3), (0, 4)));
         Flat : constant OpenCV.Core.Mat := Copy.Reshape (Shape => (6, 4));
      begin
         Check
           (Tail.Total = 12
            and then Get (Tail, Index (0, 0, 0)) = Value_At (12)
            and then Get (Tail, Index (0, 2, 3)) = Value_At (101),
            "an owned Clone must Slice normally");
         Check
           (Flat.Dimension_Count = 2
            and then Get (Flat, Index (0, 0)) = Value_At (0)
            and then Get (Flat, Index (5, 3)) = Value_At (101),
            "an owned Clone must Reshape normally");
      end;
   end Check_No_Escape_And_Clone;

end ND_Mat_View_Checks;
