with Ada.Exceptions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float16_Buffer_Access;
with OpenCV.Core.Float16_Mat_View;
with OpenCV.Core.Float16_Row_Access;

package body Float16_Mat_View_Tests is

   use type Ada.Exceptions.Exception_Id;
   use type Interfaces.Unsigned_16;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Mat_Size;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   View_Callback_Error : exception;

   function Value_Of
     (Bits : Interfaces.Unsigned_16) return OpenCV.Core.Float16_Value
   is (OpenCV.Core.Float16_From_Bits (Bits));

   function Bits_Of
     (Value : OpenCV.Core.Float16_Value) return Interfaces.Unsigned_16
   is (OpenCV.Core.Float16_Bits (Value));

   procedure Assert_Bits
     (Value    : OpenCV.Core.Float16_Value;
      Expected : Interfaces.Unsigned_16;
      Message  : String)
   is
      Stored : constant Interfaces.Unsigned_16 := Bits_Of (Value);
   begin
      AUnit.Assertions.Assert
        (Stored = Expected,
         Message
         & " (got"
         & Interfaces.Unsigned_16'Image (Stored)
         & ", expected"
         & Interfaces.Unsigned_16'Image (Expected)
         & ")");
   end Assert_Bits;

   procedure Assert_Stored_Bits
     (Image    : OpenCV.Core.Mat;
      Row      : Integer;
      Column   : Integer;
      Expected : Interfaces.Unsigned_16;
      Message  : String) is
   begin
      Assert_Bits
        (OpenCV.Core.Float16_Access.Get (Image, Row, Column),
         Expected,
         Message);
   end Assert_Stored_Bits;

   procedure Packed_View_Is_Zero_Copy_At_Arbitrary_Bound
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (37 => Value_Of (16#0000#),
         38 => Value_Of (16#8000#),
         39 => Value_Of (16#0001#),
         40 => Value_Of (16#03FF#),
         41 => Value_Of (16#0400#),
         42 => Value_Of (16#3C00#),
         43 => Value_Of (16#BC00#),
         44 => Value_Of (16#7BFF#));

      procedure Process (Image : in out OpenCV.Core.Mat) is
         Copied : OpenCV.Core.Float16_Row_Access.Row_Array (10 .. 13);

         procedure Inspect_Row
           (Values : aliased OpenCV.Core.Float16_Row_Access.Row_Array) is
         begin
            AUnit.Assertions.Assert
              (Values'First = 0
               and then Values'Last = 3
               and then Values'Length = 4,
               "Borrowed packed-view rows must use zero-based columns");
            Assert_Bits
              (Values (0),
               Bits_Of (Data (41)),
               "Borrowed row start must alias caller Data");
            Assert_Bits
              (Values (3),
               Bits_Of (Data (44)),
               "Borrowed row end must alias caller Data");
         end Inspect_Row;

         procedure Mutate_Row
           (Values : aliased in out OpenCV.Core.Float16_Row_Access.Row_Array)
         is
         begin
            Values (2) := Value_Of (16#7C00#);
         end Mutate_Row;

         procedure Inspect_Buffer
           (Values : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
         begin
            AUnit.Assertions.Assert
              (Values'First = 0 and then Values'Length = Data'Length,
               "Borrowed packed buffer must span caller-owned storage");
            Assert_Bits
              (Values (0), Bits_Of (Data (37)), "buffer first element");
            Assert_Bits
              (Values (7), Bits_Of (Data (44)), "buffer last element");
         end Inspect_Buffer;

         procedure Mutate_Buffer
           (Values :
              aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
         begin
            Values (7) := Value_Of (16#FC00#);
         end Mutate_Buffer;
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 2
            and then Image.Columns = 4
            and then Image.Depth = OpenCV.Core.Float16
            and then Image.Channels = 1
            and then Image.Element_Size = 2
            and then Image.Is_Continuous,
            "Packed view metadata must describe contiguous CV_16FC1 storage");
         Assert_Stored_Bits
           (Image, 0, 0, 16#0000#, "Image (0, 0) must be Data'First");
         Assert_Stored_Bits
           (Image, 0, 1, 16#8000#, "Image (0, 1) must follow Data'First");
         Assert_Stored_Bits
           (Image, 0, 3, 16#03FF#, "first-row last column mapping");
         Assert_Stored_Bits
           (Image, 1, 0, 16#0400#, "second-row first column mapping");
         Assert_Stored_Bits (Image, 1, 3, 16#7BFF#, "last element mapping");
         Data (39) := Value_Of (16#7C01#);
         Assert_Stored_Bits
           (Image,
            0,
            2,
            16#7C01#,
            "Caller writes must be immediately visible through the Mat");
         OpenCV.Core.Float16_Access.Set (Image, 0, 3, Value_Of (16#7E00#));
         Assert_Bits
           (Data (40),
            16#7E00#,
            "Float16 Set must immediately update caller-owned storage");
         OpenCV.Core.Float16_Row_Access.Read_Row (Image, 0, Copied);
         Assert_Bits (Copied (10), 16#0000#, "copied first-row start");
         Assert_Bits (Copied (13), 16#7E00#, "copied first-row last");
         OpenCV.Core.Float16_Row_Access.Write_Row
           (Image,
            1,
            (Value_Of (16#0400#),
             Value_Of (16#3C00#),
             Value_Of (16#BC00#),
             Value_Of (16#FBFF#)));
         Assert_Bits (Data (41), 16#0400#, "copied Write_Row first");
         Assert_Bits (Data (44), 16#FBFF#, "copied Write_Row last");
         OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
           (Image, 1, Inspect_Row'Access);
         OpenCV.Core.Float16_Row_Access.With_Writable_Row
           (Image, 1, Mutate_Row'Access);
         Assert_Bits
           (Data (43),
            16#7C00#,
            "Borrowed writable row must mutate caller storage");
         OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect_Buffer'Access);
         OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
           (Image, Mutate_Buffer'Access);
         Assert_Bits
           (Data (44),
            16#FC00#,
            "Writable whole-buffer borrowing must update caller storage");
      end Process;
   begin
      OpenCV.Core.Float16_Mat_View.With_Writable_Mat_View
        (Data, Rows => 2, Columns => 4, Process => Process'Access);
      Assert_Bits
        (Data (40), 16#7E00#, "completed packed Set must remain after view");
      Assert_Bits
        (Data (44),
         16#FC00#,
         "View finalization must preserve completed writes");
      Data (37) := Value_Of (16#0001#);
      Assert_Bits
        (Data (37),
         16#0001#,
         "Caller storage must remain usable after Mat header finalization");
   end Packed_View_Is_Zero_Copy_At_Arbitrary_Bound;

   procedure Packed_View_Preserves_Special_Encodings (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (5  => Value_Of (16#0000#),
         6  => Value_Of (16#8000#),
         7  => Value_Of (16#0001#),
         8  => Value_Of (16#03FF#),
         9  => Value_Of (16#0400#),
         10 => Value_Of (16#3C00#),
         11 => Value_Of (16#BC00#),
         12 => Value_Of (16#7BFF#),
         13 => Value_Of (16#FBFF#),
         14 => Value_Of (16#7C00#),
         15 => Value_Of (16#FC00#),
         16 => Value_Of (16#7C01#),
         17 => Value_Of (16#7E00#),
         18 => Value_Of (16#FC01#));

      procedure Inspect (Image : in out OpenCV.Core.Mat) is
      begin
         Assert_Stored_Bits (Image, 0, 0, 16#0000#, "+0");
         Assert_Stored_Bits (Image, 0, 1, 16#8000#, "-0");
         Assert_Stored_Bits (Image, 0, 2, 16#0001#, "smallest subnormal");
         Assert_Stored_Bits (Image, 0, 3, 16#03FF#, "largest subnormal");
         Assert_Stored_Bits (Image, 0, 4, 16#0400#, "smallest normal");
         Assert_Stored_Bits (Image, 0, 5, 16#3C00#, "+1");
         Assert_Stored_Bits (Image, 0, 6, 16#BC00#, "-1");
         Assert_Stored_Bits (Image, 1, 0, 16#7BFF#, "max finite");
         Assert_Stored_Bits
           (Image, 1, 1, 16#FBFF#, "max-magnitude negative finite");
         Assert_Stored_Bits (Image, 1, 2, 16#7C00#, "+Inf");
         Assert_Stored_Bits (Image, 1, 3, 16#FC00#, "-Inf");
         Assert_Stored_Bits (Image, 1, 4, 16#7C01#, "NaN payload");
         Assert_Stored_Bits (Image, 1, 5, 16#7E00#, "quiet NaN");
         Assert_Stored_Bits (Image, 1, 6, 16#FC01#, "negative NaN payload");
      end Inspect;
   begin
      OpenCV.Core.Float16_Mat_View.With_Writable_Mat_View
        (Data, 2, 7, Inspect'Access);
   end Packed_View_Preserves_Special_Encodings;

   procedure Packed_View_Preserves_All_Binary16_Encodings
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data     : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (37 .. 37 + 65_535 => Value_Of (0));
      Mismatch : Natural := 0;

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 256
            and then Image.Columns = 256
            and then Image.Is_Continuous,
            "Exhaustive packed view must be a continuous 256x256 Mat");
         for Row in 0 .. 255 loop
            for Column in 0 .. 255 loop
               declare
                  Index : constant Natural := Row * 256 + Column;
               begin
                  if Bits_Of
                       (OpenCV.Core.Float16_Access.Get (Image, Row, Column))
                    /= Interfaces.Unsigned_16 (Index)
                  then
                     Mismatch := Mismatch + 1;
                  end if;
                  OpenCV.Core.Float16_Access.Set
                    (Image,
                     Row,
                     Column,
                     Value_Of (Interfaces.Unsigned_16 (65_535 - Index)));
               end;
            end loop;
         end loop;
      end Process;
   begin
      for Index in Data'Range loop
         Data (Index) :=
           Value_Of (Interfaces.Unsigned_16 (Index - Data'First));
      end loop;
      OpenCV.Core.Float16_Mat_View.With_Writable_Mat_View
        (Data, 256, 256, Process'Access);
      AUnit.Assertions.Assert
        (Mismatch = 0,
         "Packed Float16 view must observe every binary16 encoding");
      for Index in Data'Range loop
         if Bits_Of (Data (Index))
           /= Interfaces.Unsigned_16 (65_535 - (Index - Data'First))
         then
            Mismatch := Mismatch + 1;
         end if;
      end loop;
      AUnit.Assertions.Assert
        (Mismatch = 0,
         "Packed Float16 view writes must reverse every encoding in Data");
   end Packed_View_Preserves_All_Binary16_Encodings;

   procedure Packed_View_Clone_Isolates_And_Shallow_Escape_Is_Rejected
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data  : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (11 => Value_Of (16#3C00#),
         12 => Value_Of (16#BC00#),
         13 => Value_Of (16#0400#),
         14 => Value_Of (16#7BFF#));
      Saved : OpenCV.Core.Mat;

      procedure Process (Image : in out OpenCV.Core.Mat) is
         procedure Copy_Alias is
            Alias : OpenCV.Core.Mat;
            pragma Unreferenced (Alias);
         begin
            begin
               Alias := Image;
            exception
               when Program_Error =>
                  raise OpenCV.OpenCV_Error;
            end;
         end Copy_Alias;

         procedure Take_Region is
            View : OpenCV.Core.Mat;
            pragma Unreferenced (View);
         begin
            View := Image.Region ((X => 0, Y => 0, Width => 1, Height => 1));
         end Take_Region;
      begin
         Assert_Raises_OpenCV_Error
           (Copy_Alias'Access,
            "Temporary Float16 external views must reject shallow aliases");
         Assert_Raises_OpenCV_Error
           (Take_Region'Access,
            "Temporary Float16 external views must reject Region");
         OpenCV.Core.Float16_Access.Set (Image, 0, 0, Value_Of (16#7C00#));
         Saved := Image.Clone;
      end Process;
   begin
      OpenCV.Core.Float16_Mat_View.With_Writable_Mat_View
        (Data, 2, 2, Process'Access);
      Data (11) := Value_Of (16#8000#);
      Assert_Stored_Bits
        (Saved,
         0,
         0,
         16#7C00#,
         "Clone must not observe later caller-buffer mutations");
      OpenCV.Core.Float16_Access.Set (Saved, 0, 0, Value_Of (16#FC00#));
      Assert_Bits
        (Data (11),
         16#8000#,
         "Writes to Clone must not affect external caller storage");
   end Packed_View_Clone_Isolates_And_Shallow_Escape_Is_Rejected;

   procedure Packed_View_Callback_Exception_Preserves_Writes
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data     : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (1 => Value_Of (16#3C00#), 2 => Value_Of (16#3C00#));
      Raised   : Boolean := False;
      Identity : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Float16_Access.Set (Image, 0, 1, Value_Of (16#7C01#));
         raise View_Callback_Error;
      end Process;
   begin
      begin
         OpenCV.Core.Float16_Mat_View.With_Writable_Mat_View
           (Data, 1, 2, Process'Access);
      exception
         when Error : View_Callback_Error =>
            Raised := True;
            Identity := Ada.Exceptions.Exception_Identity (Error);
      end;
      AUnit.Assertions.Assert
        (Raised and then Identity = View_Callback_Error'Identity,
         "A Float16 view callback exception must propagate unchanged");
      Assert_Bits
        (Data (2), 16#7C01#, "Writes before a callback exception remain");
      Assert_Bits
        (Data (1), 16#3C00#, "Unwritten elements must remain unchanged");
      Data (1) := Value_Of (16#0400#);
      Assert_Bits
        (Data (1), 16#0400#, "caller storage must remain usable afterward");
   end Packed_View_Callback_Exception_Preserves_Writes;

   procedure Invalid_Packed_Geometry_Does_Not_Invoke_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (1 .. 5 => Value_Of (16#3C00#));
      Invoked : Boolean := False;

      procedure Mark (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Mark;

      procedure Wrong_Length is
      begin
         OpenCV.Core.Float16_Mat_View.With_Writable_Mat_View
           (Data, 2, 3, Mark'Access);
      end Wrong_Length;

      procedure Oversized_Geometry is
      begin
         OpenCV.Core.Float16_Mat_View.With_Writable_Mat_View
           (Data, Positive'Last, Positive'Last, Mark'Access);
      end Oversized_Geometry;
   begin
      Assert_Raises_OpenCV_Error (Wrong_Length'Access, "Float16 view length");
      Assert_Raises_OpenCV_Error
        (Oversized_Geometry'Access, "Float16 view geometry range");
      AUnit.Assertions.Assert
        (not Invoked,
         "Invalid Float16 packed view construction must not invoke callback");
      Assert_Bits
        (Data (1),
         16#3C00#,
         "Failed packed construction must leave caller storage unchanged");
   end Invalid_Packed_Geometry_Does_Not_Invoke_Callback;

   procedure Strided_View_Maps_Logical_Elements_And_Preserves_Padding
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Sentinel : constant OpenCV.Core.Float16_Value := Value_Of (16#DEAD#);
      Data     : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (37 .. 54 => Sentinel);
      Clone    : OpenCV.Core.Mat;

      function Padding_Is_Intact return Boolean
      is (Bits_Of (Data (41)) = 16#DEAD#
          and then Bits_Of (Data (42)) = 16#DEAD#
          and then Bits_Of (Data (47)) = 16#DEAD#
          and then Bits_Of (Data (48)) = 16#DEAD#
          and then Bits_Of (Data (53)) = 16#DEAD#
          and then Bits_Of (Data (54)) = 16#DEAD#);

      procedure Process (Image : in out OpenCV.Core.Mat) is
         Readback       : OpenCV.Core.Float16_Row_Access.Row_Array (8 .. 11);
         Buffer_Invoked : Boolean := False;

         procedure Inspect_Row
           (Values : aliased OpenCV.Core.Float16_Row_Access.Row_Array) is
         begin
            AUnit.Assertions.Assert
              (Values'First = 0
               and then Values'Last = 3
               and then Values'Length = 4,
               "Borrowed strided row must expose logical columns only");
            Assert_Bits (Values (0), 16#3C00#, "row 1 col 0");
            Assert_Bits (Values (3), 16#7BFF#, "row 1 col 3");
         end Inspect_Row;

         procedure Mutate_Row
           (Values : aliased in out OpenCV.Core.Float16_Row_Access.Row_Array)
         is
         begin
            Values (1) := Value_Of (16#0400#);
         end Mutate_Row;

         procedure Mark_Buffer
           (Values : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
         is
            pragma Unreferenced (Values);
         begin
            Buffer_Invoked := True;
         end Mark_Buffer;

         procedure Borrow_Buffer is
         begin
            OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
              (Image, Mark_Buffer'Access);
         end Borrow_Buffer;
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 3
            and then Image.Columns = 4
            and then Image.Depth = OpenCV.Core.Float16
            and then Image.Channels = 1
            and then Image.Element_Size = 2
            and then not Image.Is_Continuous,
            "Padded multirow view must report strided CV_16FC1 metadata");
         Assert_Stored_Bits (Image, 0, 0, 16#0000#, "row 0 start");
         Assert_Stored_Bits (Image, 0, 3, 16#03FF#, "row 0 end");
         Assert_Stored_Bits (Image, 1, 0, 16#3C00#, "row 1 start");
         Assert_Stored_Bits (Image, 1, 3, 16#7BFF#, "row 1 end");
         Assert_Stored_Bits (Image, 2, 0, 16#7C00#, "row 2 start");
         Assert_Stored_Bits (Image, 2, 3, 16#FC01#, "row 2 end");

         OpenCV.Core.Float16_Access.Set (Image, 2, 3, Value_Of (16#FC00#));
         OpenCV.Core.Float16_Row_Access.Read_Row (Image, 1, Readback);
         Assert_Bits
           (Data (52), 16#FC00#, "scalar write last logical element");
         Assert_Bits (Readback (8), 16#3C00#, "copied row 1 start");
         Assert_Bits (Readback (11), 16#7BFF#, "copied row 1 end");
         OpenCV.Core.Float16_Row_Access.Write_Row
           (Image,
            2,
            (Value_Of (16#7C00#),
             Value_Of (16#FC00#),
             Value_Of (16#7C01#),
             Value_Of (16#7E00#)));
         OpenCV.Core.Float16_Row_Access.With_Read_Only_Row
           (Image, 1, Inspect_Row'Access);
         OpenCV.Core.Float16_Row_Access.With_Writable_Row
           (Image, 1, Mutate_Row'Access);
         Assert_Bits (Data (44), 16#0400#, "borrowed row write");
         Assert_Bits (Data (49), 16#7C00#, "copied row 2 start");
         Assert_Bits (Data (52), 16#7E00#, "copied row 2 last");
         AUnit.Assertions.Assert
           (Padding_Is_Intact, "Row writes must not touch padding");

         Assert_Raises_OpenCV_Error
           (Borrow_Buffer'Access,
            "Whole-buffer borrowing must reject a non-contiguous view");
         AUnit.Assertions.Assert
           (not Buffer_Invoked,
            "Rejected whole-buffer borrowing must suppress its callback");

         Clone := Image.Clone;
         AUnit.Assertions.Assert
           (Clone.Is_Continuous,
            "Clone must copy logical values into continuous owned storage");
         Assert_Stored_Bits
           (Clone, 1, 1, 16#0400#, "clone observes row write");
         Assert_Stored_Bits
           (Clone, 2, 3, 16#7E00#, "clone observes last write");
      end Process;
   begin
      Data (37) := Value_Of (16#0000#);
      Data (38) := Value_Of (16#8000#);
      Data (39) := Value_Of (16#0001#);
      Data (40) := Value_Of (16#03FF#);
      Data (43) := Value_Of (16#3C00#);
      Data (44) := Value_Of (16#BC00#);
      Data (45) := Value_Of (16#0400#);
      Data (46) := Value_Of (16#7BFF#);
      Data (49) := Value_Of (16#7C00#);
      Data (50) := Value_Of (16#FC00#);
      Data (51) := Value_Of (16#7C01#);
      Data (52) := Value_Of (16#FC01#);

      OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View
        (Data,
         Rows       => 3,
         Columns    => 4,
         Row_Stride => 6,
         Process    => Process'Access);
      AUnit.Assertions.Assert
        (Padding_Is_Intact, "View finalization must preserve padding");
      Data (37) := Value_Of (16#0001#);
      Assert_Stored_Bits
        (Clone,
         0,
         0,
         16#0000#,
         "Backing mutation after callback must not affect Clone");
      OpenCV.Core.Float16_Access.Set (Clone, 0, 0, Value_Of (16#8000#));
      Assert_Bits
        (Data (37),
         16#0001#,
         "Clone mutation must not affect caller-owned backing storage");
   end Strided_View_Maps_Logical_Elements_And_Preserves_Padding;

   procedure Strided_View_Handles_Special_Shapes_And_Minimum_Storage
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      One_Row    : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (10 => Value_Of (16#0000#),
         11 => Value_Of (16#8000#),
         12 => Value_Of (16#0001#),
         13 => Value_Of (16#03FF#),
         14 => Value_Of (16#DEAD#),
         15 => Value_Of (16#DEAD#));
      One_Column : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (20 => Value_Of (16#3C00#),
         21 => Value_Of (16#DEAD#),
         22 => Value_Of (16#DEAD#),
         23 => Value_Of (16#BC00#),
         24 => Value_Of (16#DEAD#),
         25 => Value_Of (16#DEAD#),
         26 => Value_Of (16#7BFF#),
         27 => Value_Of (16#DEAD#),
         28 => Value_Of (16#DEAD#));
      Tight      : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (1 => Value_Of (16#0000#),
         2 => Value_Of (16#8000#),
         3 => Value_Of (16#0001#),
         4 => Value_Of (16#03FF#),
         5 => Value_Of (16#0400#),
         6 => Value_Of (16#3C00#));
      Minimum    : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (1 .. 18 => Value_Of (16#DEAD#));

      procedure Check_One_Row (Image : in out OpenCV.Core.Mat) is
         procedure Inspect_Buffer
           (Values : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
         begin
            AUnit.Assertions.Assert
              (Values'Length = 4, "one-row logical buffer length");
            Assert_Bits (Values (3), 16#03FF#, "one-row last logical");
         end Inspect_Buffer;
      begin
         AUnit.Assertions.Assert
           (Image.Is_Continuous
            and then Image.Rows = 1
            and then Image.Columns = 4,
            "OpenCV must classify a one-row padded-step Mat as continuous");
         OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect_Buffer'Access);
         OpenCV.Core.Float16_Access.Set (Image, 0, 3, Value_Of (16#7C00#));
      end Check_One_Row;

      procedure Check_One_Column (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (not Image.Is_Continuous
            and then OpenCV.Core.Float16_Bits
                       (OpenCV.Core.Float16_Access.Get (Image, 2, 0))
                     = 16#7BFF#,
            "A padded single-column view must preserve its row stride");
         OpenCV.Core.Float16_Access.Set (Image, 1, 0, Value_Of (16#0400#));
      end Check_One_Column;

      procedure Check_Tight (Image : in out OpenCV.Core.Mat) is
         procedure Mutate_Buffer
           (Values :
              aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
         begin
            Values (5) := Value_Of (16#BC00#);
         end Mutate_Buffer;
      begin
         AUnit.Assertions.Assert
           (Image.Is_Continuous,
            "Row_Stride equal to Columns must be equivalent to packed layout");
         OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
           (Image, Mutate_Buffer'Access);
      end Check_Tight;

      procedure Check_Minimum (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 3
            and then Image.Columns = 4
            and then not Image.Is_Continuous,
            "Minimum backing storage must still describe a 3x4 strided Mat");
         OpenCV.Core.Float16_Access.Set (Image, 2, 3, Value_Of (16#7C01#));
      end Check_Minimum;
   begin
      Minimum (1) := Value_Of (16#0000#);
      Minimum (4) := Value_Of (16#03FF#);
      Minimum (7) := Value_Of (16#3C00#);
      Minimum (10) := Value_Of (16#7BFF#);
      Minimum (13) := Value_Of (16#7C00#);
      Minimum (16) := Value_Of (16#FC00#);

      OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View
        (One_Row, 1, 4, 6, Check_One_Row'Access);
      OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View
        (One_Column, 3, 1, 3, Check_One_Column'Access);
      OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View
        (Tight, 2, 3, 3, Check_Tight'Access);
      OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View
        (Minimum, 3, 4, 6, Check_Minimum'Access);

      Assert_Bits (One_Row (13), 16#7C00#, "one-row last write");
      Assert_Bits (One_Row (14), 16#DEAD#, "one-row unused padding");
      Assert_Bits (One_Column (23), 16#0400#, "one-column middle write");
      Assert_Bits (One_Column (21), 16#DEAD#, "one-column unused padding");
      Assert_Bits (Tight (6), 16#BC00#, "tight stride last write");
      Assert_Bits
        (Minimum (16), 16#7C01#, "minimum storage last logical element write");
      Assert_Bits (Minimum (5), 16#DEAD#, "minimum storage first-row padding");
      Assert_Bits
        (Minimum (11), 16#DEAD#, "minimum storage second-row padding");
      Assert_Bits
        (Minimum (18),
         16#DEAD#,
         "complete final-row padding remains untouched");
   end Strided_View_Handles_Special_Shapes_And_Minimum_Storage;

   procedure Invalid_Strided_Layouts_Do_Not_Invoke_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (1 .. 16 => Value_Of (16#3C00#));
      Short   : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (1 .. 15 => Value_Of (16#3C00#));
      Invoked : Boolean := False;

      procedure Mark (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Mark;

      procedure Short_Stride is
      begin
         OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View
           (Data, 3, 4, 3, Mark'Access);
      end Short_Stride;

      procedure Short_Buffer is
      begin
         OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View
           (Short, 3, 4, 6, Mark'Access);
      end Short_Buffer;

      procedure Logical_End_Only is
      begin
         OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View
           (Data, 3, 4, 6, Mark'Access);
      end Logical_End_Only;

      procedure Capacity_Overflow is
      begin
         OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View
           (Data, 2, 1, Positive'Last, Mark'Access);
      end Capacity_Overflow;
   begin
      Assert_Raises_OpenCV_Error (Short_Stride'Access, "Float16 short stride");
      Assert_Raises_OpenCV_Error (Short_Buffer'Access, "Float16 short buffer");
      Assert_Raises_OpenCV_Error
        (Logical_End_Only'Access,
         "Float16 logical-end-only capacity omits final-row padding");
      Assert_Raises_OpenCV_Error
        (Capacity_Overflow'Access, "Float16 strided capacity overflow");
      AUnit.Assertions.Assert
        (not Invoked,
         "Invalid strided layouts must be rejected before callback"
         & " invocation");
      Assert_Bits
        (Data (1),
         16#3C00#,
         "Failed strided construction must leave caller storage unchanged");
   end Invalid_Strided_Layouts_Do_Not_Invoke_Callback;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float16 external view is zero-copy at arbitrary lower bound",
            Packed_View_Is_Zero_Copy_At_Arbitrary_Bound'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 external view preserves special binary16 encodings",
            Packed_View_Preserves_Special_Encodings'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 packed view preserves all 65536 binary16 encodings",
            Packed_View_Preserves_All_Binary16_Encodings'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 external view clone isolates and shallow escape rejects",
            Packed_View_Clone_Isolates_And_Shallow_Escape_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 view callback exception preserves completed writes",
            Packed_View_Callback_Exception_Preserves_Writes'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 packed view rejects invalid geometry before callback",
            Invalid_Packed_Geometry_Does_Not_Invoke_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 strided view maps logical elements and preserves padding",
            Strided_View_Maps_Logical_Elements_And_Preserves_Padding'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 strided view handles special shapes and minimum storage",
            Strided_View_Handles_Special_Shapes_And_Minimum_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 strided view rejects invalid layouts before callback",
            Invalid_Strided_Layouts_Do_Not_Invoke_Callback'Access));
      return Result'Access;
   end Suite;

end Float16_Mat_View_Tests;
