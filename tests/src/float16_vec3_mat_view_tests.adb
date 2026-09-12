with Ada.Exceptions;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV.Core;
with OpenCV.Core.Float16_Vec3;
with OpenCV.Core.Float16_Vec3_Access;
with OpenCV.Core.Float16_Vec3_Buffer_Access;
with OpenCV.Core.Float16_Vec3_Mat_View;
with OpenCV.Core.Float16_Vec3_Row_Access;

package body Float16_Vec3_Mat_View_Tests is

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

   function Pixel
     (C0, C1, C2 : Interfaces.Unsigned_16)
      return OpenCV.Core.Float16_Vec3.Vector
   is ((0 => Value_Of (C0), 1 => Value_Of (C1), 2 => Value_Of (C2)));

   procedure Assert_Component_Bits
     (Value    : OpenCV.Core.Float16_Vec3.Vector;
      Expected : OpenCV.Core.Float16_Vec3.Vector;
      Message  : String) is
   begin
      for Component in OpenCV.Core.Float16_Vec3.Component_Index loop
         declare
            Stored   : constant Interfaces.Unsigned_16 :=
              Bits_Of (Value (Component));
            Wanted   : constant Interfaces.Unsigned_16 :=
              Bits_Of (Expected (Component));
            Position : constant String := Integer'Image (Component);
         begin
            AUnit.Assertions.Assert
              (Stored = Wanted,
               Message
               & " component"
               & Position
               & " (got"
               & Interfaces.Unsigned_16'Image (Stored)
               & ", expected"
               & Interfaces.Unsigned_16'Image (Wanted)
               & ")");
         end;
      end loop;
   end Assert_Component_Bits;

   procedure Assert_Stored_Pixel
     (Image    : OpenCV.Core.Mat;
      Row      : Integer;
      Column   : Integer;
      Expected : OpenCV.Core.Float16_Vec3.Vector;
      Message  : String) is
   begin
      Assert_Component_Bits
        (OpenCV.Core.Float16_Vec3_Access.Get (Image, Row, Column),
         Expected,
         Message);
   end Assert_Stored_Pixel;

   function Observed_Size (Value : Natural) return Natural is
   begin
      return Value;
   end Observed_Size;

   procedure Packed_View_Is_Zero_Copy_At_Arbitrary_Bound
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (37 => Pixel (16#0000#, 16#8000#, 16#0001#),
         38 => Pixel (16#03FF#, 16#0400#, 16#3C00#),
         39 => Pixel (16#BC00#, 16#7BFF#, 16#FBFF#),
         40 => Pixel (16#7C00#, 16#FC00#, 16#7C01#),
         41 => Pixel (16#7E00#, 16#FC01#, 16#7E55#),
         42 => Pixel (16#0001#, 16#03FF#, 16#0400#),
         43 => Pixel (16#3C00#, 16#BC00#, 16#7BFF#),
         44 => Pixel (16#FBFF#, 16#7C00#, 16#FC00#));

      procedure Process (Image : in out OpenCV.Core.Mat) is
         Copied : OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (10 .. 13);

         procedure Inspect_Row
           (Values : aliased OpenCV.Core.Float16_Vec3_Row_Access.Row_Array) is
         begin
            AUnit.Assertions.Assert
              (Values'First = 0
               and then Values'Last = 3
               and then Values'Length = 4,
               "Borrowed packed-view rows must use zero-based columns");
            Assert_Component_Bits
              (Values (0),
               Data (41),
               "Borrowed row start must alias caller Data");
            Assert_Component_Bits
              (Values (3),
               Data (44),
               "Borrowed row end must alias caller Data");
         end Inspect_Row;

         procedure Mutate_Row
           (Values :
              aliased in out OpenCV.Core.Float16_Vec3_Row_Access.Row_Array) is
         begin
            Values (2) := Pixel (16#7C00#, 16#0000#, 16#8000#);
         end Mutate_Row;

         procedure Inspect_Buffer
           (Values :
              aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array) is
         begin
            AUnit.Assertions.Assert
              (Values'First = 0 and then Values'Length = 8,
               "Packed-view buffer must span Rows * Columns pixels");
            Assert_Component_Bits
              (Values (0), Data (37), "Borrowed buffer first element");
            Assert_Component_Bits
              (Values (7), Data (44), "Borrowed buffer last element");
         end Inspect_Buffer;

         procedure Mutate_Buffer
           (Values :
              aliased in out OpenCV
                               .Core
                               .Float16_Vec3_Buffer_Access
                               .Buffer_Array) is
         begin
            Values (7) := Pixel (16#FC00#, 16#7C01#, 16#7E00#);
         end Mutate_Buffer;
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 2
            and then Image.Columns = 4
            and then Image.Depth = OpenCV.Core.Float16
            and then Image.Channels = 3
            and then Image.Element_Size = 6
            and then Image.Is_Continuous,
            "Packed view metadata must describe contiguous CV_16FC3 storage");
         Assert_Stored_Pixel
           (Image, 0, 0, Data (37), "Image (0, 0) must be Data'First");
         Assert_Stored_Pixel
           (Image, 0, 3, Data (40), "first-row last column mapping");
         Assert_Stored_Pixel
           (Image, 1, 0, Data (41), "second-row first column mapping");
         Assert_Stored_Pixel (Image, 1, 3, Data (44), "last element mapping");
         Data (39) := Pixel (16#7C01#, 16#7E00#, 16#FC01#);
         Assert_Stored_Pixel
           (Image,
            0,
            2,
            Pixel (16#7C01#, 16#7E00#, 16#FC01#),
            "Caller writes must be immediately visible through the Mat");
         OpenCV.Core.Float16_Vec3_Access.Set
           (Image, 0, 3, Pixel (16#7E00#, 16#FC01#, 16#7E55#));
         Assert_Component_Bits
           (Data (40),
            Pixel (16#7E00#, 16#FC01#, 16#7E55#),
            "Float16 Vec3 Set must immediately update caller-owned storage");
         OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (Image, 0, Copied);
         Assert_Component_Bits
           (Copied (10), Data (37), "copied first-row start");
         Assert_Component_Bits
           (Copied (13), Data (40), "copied first-row last");
         OpenCV.Core.Float16_Vec3_Row_Access.Write_Row
           (Image,
            1,
            (Pixel (16#0400#, 16#3C00#, 16#BC00#),
             Pixel (16#7BFF#, 16#FBFF#, 16#7C00#),
             Pixel (16#FC00#, 16#7C01#, 16#7E00#),
             Pixel (16#FC01#, 16#7E55#, 16#0000#)));

         Assert_Component_Bits
           (Data (41),
            Pixel (16#0400#, 16#3C00#, 16#BC00#),
            "copied Write_Row first");
         Assert_Component_Bits
           (Data (44),
            Pixel (16#FC01#, 16#7E55#, 16#0000#),
            "copied Write_Row last");
         OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
           (Image, 1, Inspect_Row'Access);
         OpenCV.Core.Float16_Vec3_Row_Access.With_Writable_Row
           (Image, 1, Mutate_Row'Access);
         Assert_Component_Bits
           (Data (43),
            Pixel (16#7C00#, 16#0000#, 16#8000#),
            "Borrowed writable row must mutate caller storage");
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect_Buffer'Access);
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Writable_Buffer
           (Image, Mutate_Buffer'Access);
         Assert_Component_Bits
           (Data (44),
            Pixel (16#FC00#, 16#7C01#, 16#7E00#),
            "Writable whole-buffer borrowing must update caller storage");
      end Process;
   begin
      OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Mat_View
        (Data, Rows => 2, Columns => 4, Process => Process'Access);
      Assert_Component_Bits
        (Data (40),
         Pixel (16#7E00#, 16#FC01#, 16#7E55#),
         "completed packed Set must remain after view");
      Assert_Component_Bits
        (Data (44),
         Pixel (16#FC00#, 16#7C01#, 16#7E00#),
         "View finalization must preserve completed writes");
      Data (37) := Pixel (16#0001#, 16#03FF#, 16#0400#);
      Assert_Component_Bits
        (Data (37),
         Pixel (16#0001#, 16#03FF#, 16#0400#),
         "Caller storage must remain usable after Mat header finalization");
   end Packed_View_Is_Zero_Copy_At_Arbitrary_Bound;

   procedure Packed_View_Preserves_Special_Encodings (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (5 => Pixel (16#0000#, 16#8000#, 16#0001#),
         6 => Pixel (16#03FF#, 16#0400#, 16#3C00#),
         7 => Pixel (16#BC00#, 16#7BFF#, 16#FBFF#),
         8 => Pixel (16#7C00#, 16#FC00#, 16#7C01#),
         9 => Pixel (16#7E00#, 16#FC01#, 16#7E55#));

      procedure Inspect (Image : in out OpenCV.Core.Mat) is
      begin
         Assert_Stored_Pixel
           (Image, 0, 0, Pixel (16#0000#, 16#8000#, 16#0001#), "+0/-0/sub");
         Assert_Stored_Pixel
           (Image,
            0,
            1,
            Pixel (16#03FF#, 16#0400#, 16#3C00#),
            "sub/normal/+1");
         Assert_Stored_Pixel
           (Image,
            0,
            2,
            Pixel (16#BC00#, 16#7BFF#, 16#FBFF#),
            "-1/max/negmax");
         Assert_Stored_Pixel
           (Image,
            0,
            3,
            Pixel (16#7C00#, 16#FC00#, 16#7C01#),
            "+Inf/-Inf/NaN");
         Assert_Stored_Pixel
           (Image,
            0,
            4,
            Pixel (16#7E00#, 16#FC01#, 16#7E55#),
            "qNaN/nNaN/pay");
      end Inspect;
   begin
      OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Mat_View
        (Data, 1, 5, Inspect'Access);
   end Packed_View_Preserves_Special_Encodings;

   procedure Packed_View_Preserves_All_Binary16_Encodings
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data     : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (37 .. 37 + 21_845 => Pixel (0, 0, 0));
      Mismatch : Natural := 0;
      Bits     : Interfaces.Unsigned_16 := 0;

      procedure Process (Image : in out OpenCV.Core.Mat) is
         Observed : Interfaces.Unsigned_16 := 0;
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 2
            and then Image.Columns = 10_923
            and then Image.Is_Continuous,
            "Exhaustive packed view must be a continuous 2x10923 Mat");
         for Row in 0 .. Image.Rows - 1 loop
            for Column in 0 .. Image.Columns - 1 loop
               declare
                  Value : constant OpenCV.Core.Float16_Vec3.Vector :=
                    OpenCV.Core.Float16_Vec3_Access.Get (Image, Row, Column);
               begin
                  for Component in OpenCV.Core.Float16_Vec3.Component_Index
                  loop
                     if Bits_Of (Value (Component)) /= Observed then
                        Mismatch := Mismatch + 1;
                     end if;
                     Observed := Observed + 1;
                  end loop;
                  OpenCV.Core.Float16_Vec3_Access.Set
                    (Image,
                     Row,
                     Column,
                     Pixel (Observed - 1, Observed - 2, Observed - 3));
               end;
            end loop;
         end loop;
      end Process;
   begin
      for Index in Data'Range loop
         Data (Index) := Pixel (Bits, Bits + 1, Bits + 2);
         Bits := Bits + 3;
      end loop;
      OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Mat_View
        (Data, 2, 10_923, Process'Access);
      AUnit.Assertions.Assert
        (Mismatch = 0,
         "Packed Float16 Vec3 view must observe every binary16 encoding");
      Bits := 0;
      for Index in Data'Range loop
         Bits := Bits + 3;
         if Bits_Of (Data (Index) (0)) /= Bits - 1
           or else Bits_Of (Data (Index) (1)) /= Bits - 2
           or else Bits_Of (Data (Index) (2)) /= Bits - 3
         then
            Mismatch := Mismatch + 1;
         end if;
      end loop;
      AUnit.Assertions.Assert
        (Mismatch = 0,
         "Packed Float16 Vec3 view writes must reverse encodings in Data");
   end Packed_View_Preserves_All_Binary16_Encodings;

   procedure Packed_View_Clone_Isolates_And_Shallow_Escape_Is_Rejected
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data  : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (11 => Pixel (16#3C00#, 16#BC00#, 16#0400#),
         12 => Pixel (16#7BFF#, 16#FBFF#, 16#7C00#),
         13 => Pixel (16#FC00#, 16#7C01#, 16#7E00#),
         14 => Pixel (16#FC01#, 16#7E55#, 16#0000#));
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
            "Temporary Float16 Vec3 external views must reject aliases");
         Assert_Raises_OpenCV_Error
           (Take_Region'Access,
            "Temporary Float16 Vec3 external views must reject Region");
         OpenCV.Core.Float16_Vec3_Access.Set
           (Image, 0, 0, Pixel (16#7C00#, 16#0000#, 16#8000#));
         Saved := Image.Clone;
      end Process;
   begin
      OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Mat_View
        (Data, 2, 2, Process'Access);
      Data (11) := Pixel (16#8000#, 16#0001#, 16#03FF#);
      Assert_Stored_Pixel
        (Saved,
         0,
         0,
         Pixel (16#7C00#, 16#0000#, 16#8000#),
         "Clone must not observe later caller-buffer mutations");
      OpenCV.Core.Float16_Vec3_Access.Set
        (Saved, 0, 0, Pixel (16#FC00#, 16#7C01#, 16#7E00#));
      Assert_Component_Bits
        (Data (11),
         Pixel (16#8000#, 16#0001#, 16#03FF#),
         "Writes to Clone must not affect external caller storage");
   end Packed_View_Clone_Isolates_And_Shallow_Escape_Is_Rejected;

   procedure Packed_View_Callback_Exception_Preserves_Writes
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data     : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (1 => Pixel (16#3C00#, 16#3C00#, 16#3C00#),
         2 => Pixel (16#3C00#, 16#3C00#, 16#3C00#));
      Raised   : Boolean := False;
      Identity : Ada.Exceptions.Exception_Id := Ada.Exceptions.Null_Id;

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.Float16_Vec3_Access.Set
           (Image, 0, 1, Pixel (16#7C01#, 16#7E00#, 16#FC01#));
         raise View_Callback_Error;
      end Process;
   begin
      begin
         OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Mat_View
           (Data, 1, 2, Process'Access);
      exception
         when Error : View_Callback_Error =>
            Raised := True;
            Identity := Ada.Exceptions.Exception_Identity (Error);
      end;
      AUnit.Assertions.Assert
        (Raised and then Identity = View_Callback_Error'Identity,
         "A Float16 Vec3 view callback exception must propagate unchanged");
      Assert_Component_Bits
        (Data (2),
         Pixel (16#7C01#, 16#7E00#, 16#FC01#),
         "Writes before a callback exception remain");
      Assert_Component_Bits
        (Data (1),
         Pixel (16#3C00#, 16#3C00#, 16#3C00#),
         "Unwritten elements must remain unchanged");
      Data (1) := Pixel (16#0400#, 16#3C00#, 16#BC00#);
      Assert_Component_Bits
        (Data (1),
         Pixel (16#0400#, 16#3C00#, 16#BC00#),
         "caller storage must remain usable afterward");
   end Packed_View_Callback_Exception_Preserves_Writes;

   procedure Invalid_Packed_Geometry_Does_Not_Invoke_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (1 .. 5 => Pixel (16#3C00#, 16#3C00#, 16#3C00#));
      Invoked : Boolean := False;

      procedure Mark (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Mark;

      procedure Wrong_Length is
      begin
         OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Mat_View
           (Data, 2, 3, Mark'Access);
      end Wrong_Length;

      procedure Oversized_Geometry is
      begin
         OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Mat_View
           (Data, Positive'Last, Positive'Last, Mark'Access);
      end Oversized_Geometry;
   begin
      Assert_Raises_OpenCV_Error
        (Wrong_Length'Access, "Float16 Vec3 view length");
      Assert_Raises_OpenCV_Error
        (Oversized_Geometry'Access, "Float16 Vec3 view geometry range");
      AUnit.Assertions.Assert
        (not Invoked,
         "Invalid Float16 Vec3 packed view construction must not invoke");
      Assert_Component_Bits
        (Data (1),
         Pixel (16#3C00#, 16#3C00#, 16#3C00#),
         "Failed packed construction must leave caller storage unchanged");
   end Invalid_Packed_Geometry_Does_Not_Invoke_Callback;

   procedure Strided_View_Maps_Logical_Elements_And_Preserves_Padding
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Sentinel : constant OpenCV.Core.Float16_Vec3.Vector :=
        Pixel (16#DEAD#, 16#BEEF#, 16#CAFE#);
      Data     : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (37 .. 49 => Sentinel);
      Clone    : OpenCV.Core.Mat;

      function Padding_Is_Intact return Boolean
      is (Bits_Of (Data (40) (0)) = 16#DEAD#
          and then Bits_Of (Data (40) (1)) = 16#BEEF#
          and then Bits_Of (Data (40) (2)) = 16#CAFE#
          and then Bits_Of (Data (41) (0)) = 16#DEAD#
          and then Bits_Of (Data (41) (1)) = 16#BEEF#
          and then Bits_Of (Data (41) (2)) = 16#CAFE#
          and then Bits_Of (Data (45) (0)) = 16#DEAD#
          and then Bits_Of (Data (45) (1)) = 16#BEEF#
          and then Bits_Of (Data (45) (2)) = 16#CAFE#
          and then Bits_Of (Data (46) (0)) = 16#DEAD#
          and then Bits_Of (Data (46) (1)) = 16#BEEF#
          and then Bits_Of (Data (46) (2)) = 16#CAFE#);

      procedure Process (Image : in out OpenCV.Core.Mat) is
         Readback       :
           OpenCV.Core.Float16_Vec3_Row_Access.Row_Array (8 .. 10);
         Buffer_Invoked : Boolean := False;

         procedure Inspect_Row
           (Values : aliased OpenCV.Core.Float16_Vec3_Row_Access.Row_Array) is
         begin
            AUnit.Assertions.Assert
              (Values'First = 0
               and then Values'Last = 2
               and then Values'Length = 3,
               "Borrowed strided row must expose logical columns only");
            Assert_Component_Bits (Values (0), Data (42), "row 1 col 0");
            Assert_Component_Bits (Values (2), Data (44), "row 1 col 2");
         end Inspect_Row;

         procedure Mutate_Row
           (Values :
              aliased in out OpenCV.Core.Float16_Vec3_Row_Access.Row_Array) is
         begin
            Values (1) := Pixel (16#0400#, 16#3C00#, 16#BC00#);
         end Mutate_Row;

         procedure Mark_Buffer
           (Values :
              aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array)
         is
            pragma Unreferenced (Values);
         begin
            Buffer_Invoked := True;
         end Mark_Buffer;

         procedure Borrow_Buffer is
         begin
            OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
              (Image, Mark_Buffer'Access);
         end Borrow_Buffer;
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 3
            and then Image.Columns = 3
            and then Image.Depth = OpenCV.Core.Float16
            and then Image.Channels = 3
            and then Image.Element_Size = 6
            and then not Image.Is_Continuous,
            "Padded multirow view must report strided CV_16FC3 metadata");
         Assert_Stored_Pixel (Image, 0, 0, Data (37), "row 0 start");
         Assert_Stored_Pixel (Image, 0, 2, Data (39), "row 0 end");
         Assert_Stored_Pixel (Image, 1, 0, Data (42), "row 1 start");
         Assert_Stored_Pixel (Image, 1, 2, Data (44), "row 1 end");
         Assert_Stored_Pixel (Image, 2, 0, Data (47), "row 2 start");
         Assert_Stored_Pixel (Image, 2, 2, Data (49), "row 2 end");

         OpenCV.Core.Float16_Vec3_Access.Set
           (Image, 2, 2, Pixel (16#FC00#, 16#7C01#, 16#7E00#));
         OpenCV.Core.Float16_Vec3_Row_Access.Read_Row (Image, 1, Readback);
         Assert_Component_Bits
           (Data (49),
            Pixel (16#FC00#, 16#7C01#, 16#7E00#),
            "scalar write last logical element");
         Assert_Component_Bits (Readback (8), Data (42), "copied row 1 start");
         Assert_Component_Bits (Readback (10), Data (44), "copied row 1 end");
         OpenCV.Core.Float16_Vec3_Row_Access.Write_Row
           (Image,
            2,
            (Pixel (16#7C00#, 16#FC00#, 16#7C01#),
             Pixel (16#7E00#, 16#FC01#, 16#7E55#),
             Pixel (16#0000#, 16#8000#, 16#0001#)));
         OpenCV.Core.Float16_Vec3_Row_Access.With_Read_Only_Row
           (Image, 1, Inspect_Row'Access);
         OpenCV.Core.Float16_Vec3_Row_Access.With_Writable_Row
           (Image, 1, Mutate_Row'Access);
         Assert_Component_Bits
           (Data (43),
            Pixel (16#0400#, 16#3C00#, 16#BC00#),
            "borrowed row write");
         Assert_Component_Bits
           (Data (47),
            Pixel (16#7C00#, 16#FC00#, 16#7C01#),
            "copied row 2 start");
         Assert_Component_Bits
           (Data (49),
            Pixel (16#0000#, 16#8000#, 16#0001#),
            "copied row 2 last");
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
         Assert_Stored_Pixel
           (Clone,
            1,
            1,
            Pixel (16#0400#, 16#3C00#, 16#BC00#),
            "clone observes row write");
         Assert_Stored_Pixel
           (Clone,
            2,
            2,
            Pixel (16#0000#, 16#8000#, 16#0001#),
            "clone observes last write");
      end Process;
   begin
      Data (37) := Pixel (16#0000#, 16#8000#, 16#0001#);
      Data (38) := Pixel (16#03FF#, 16#0400#, 16#3C00#);
      Data (39) := Pixel (16#BC00#, 16#7BFF#, 16#FBFF#);
      Data (42) := Pixel (16#7C00#, 16#FC00#, 16#7C01#);
      Data (43) := Pixel (16#7E00#, 16#FC01#, 16#7E55#);
      Data (44) := Pixel (16#0001#, 16#03FF#, 16#0400#);
      Data (47) := Pixel (16#3C00#, 16#BC00#, 16#7BFF#);
      Data (48) := Pixel (16#FBFF#, 16#7C00#, 16#FC00#);
      Data (49) := Pixel (16#7C01#, 16#7E00#, 16#FC01#);

      OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Strided_Mat_View
        (Data,
         Rows       => 3,
         Columns    => 3,
         Row_Stride => 5,
         Process    => Process'Access);
      AUnit.Assertions.Assert
        (Padding_Is_Intact, "View finalization must preserve padding");
      Data (37) := Pixel (16#0001#, 16#03FF#, 16#0400#);
      Assert_Stored_Pixel
        (Clone,
         0,
         0,
         Pixel (16#0000#, 16#8000#, 16#0001#),
         "Backing mutation after callback must not affect Clone");
      OpenCV.Core.Float16_Vec3_Access.Set
        (Clone, 0, 0, Pixel (16#8000#, 16#0001#, 16#03FF#));
      Assert_Component_Bits
        (Data (37),
         Pixel (16#0001#, 16#03FF#, 16#0400#),
         "Clone mutation must not affect caller-owned backing storage");
   end Strided_View_Maps_Logical_Elements_And_Preserves_Padding;

   procedure Strided_View_Handles_Special_Shapes_And_Minimum_Storage
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      One_Row    : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (10 => Pixel (16#0000#, 16#8000#, 16#0001#),
         11 => Pixel (16#03FF#, 16#0400#, 16#3C00#),
         12 => Pixel (16#BC00#, 16#7BFF#, 16#FBFF#),
         13 => Pixel (16#7C00#, 16#FC00#, 16#7C01#),
         14 => Pixel (16#DEAD#, 16#BEEF#, 16#CAFE#));
      One_Column : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (20 => Pixel (16#3C00#, 16#BC00#, 16#7BFF#),
         21 => Pixel (16#DEAD#, 16#BEEF#, 16#CAFE#),
         22 => Pixel (16#DEAD#, 16#BEEF#, 16#CAFE#),
         23 => Pixel (16#FBFF#, 16#7C00#, 16#FC00#),
         24 => Pixel (16#DEAD#, 16#BEEF#, 16#CAFE#),
         25 => Pixel (16#DEAD#, 16#BEEF#, 16#CAFE#),
         26 => Pixel (16#7C01#, 16#7E00#, 16#FC01#));
      Tight      : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (1 => Pixel (16#0000#, 16#8000#, 16#0001#),
         2 => Pixel (16#03FF#, 16#0400#, 16#3C00#),
         3 => Pixel (16#BC00#, 16#7BFF#, 16#FBFF#),
         4 => Pixel (16#7C00#, 16#FC00#, 16#7C01#),
         5 => Pixel (16#7E00#, 16#FC01#, 16#7E55#),
         6 => Pixel (16#0001#, 16#03FF#, 16#0400#));
      Minimum    : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (1 .. 13 => Pixel (16#DEAD#, 16#BEEF#, 16#CAFE#));

      procedure Check_One_Row (Image : in out OpenCV.Core.Mat) is
         procedure Inspect_Buffer
           (Values :
              aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array) is
         begin
            AUnit.Assertions.Assert
              (Values'Length = 4, "one-row logical buffer length");
            Assert_Component_Bits
              (Values (3), One_Row (13), "one-row last logical");
         end Inspect_Buffer;
      begin
         AUnit.Assertions.Assert
           (Image.Is_Continuous
            and then Image.Rows = 1
            and then Image.Columns = 4,
            "OpenCV must classify a one-row padded-step Mat as continuous");
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect_Buffer'Access);
         OpenCV.Core.Float16_Vec3_Access.Set
           (Image, 0, 3, Pixel (16#7C00#, 16#0000#, 16#8000#));
      end Check_One_Row;

      procedure Check_One_Column (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (not Image.Is_Continuous
            and then Bits_Of
                       (OpenCV.Core.Float16_Vec3_Access.Get (Image, 2, 0) (0))
                     = 16#7C01#,
            "A padded single-column view must preserve its row stride");
         OpenCV.Core.Float16_Vec3_Access.Set
           (Image, 1, 0, Pixel (16#0400#, 16#3C00#, 16#BC00#));
      end Check_One_Column;
      procedure Check_Tight (Image : in out OpenCV.Core.Mat) is
         procedure Mutate_Buffer
           (Values :
              aliased in out OpenCV
                               .Core
                               .Float16_Vec3_Buffer_Access
                               .Buffer_Array) is
         begin
            Values (5) := Pixel (16#BC00#, 16#7BFF#, 16#FBFF#);
         end Mutate_Buffer;
      begin
         AUnit.Assertions.Assert
           (Image.Is_Continuous,
            "Row_Stride equal to Columns must be equivalent to packed layout");
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Writable_Buffer
           (Image, Mutate_Buffer'Access);
      end Check_Tight;

      procedure Check_Minimum (Image : in out OpenCV.Core.Mat) is
      begin
         AUnit.Assertions.Assert
           (Image.Rows = 3
            and then Image.Columns = 3
            and then not Image.Is_Continuous,
            "Minimum backing storage must still describe a 3x3 strided Mat");
         OpenCV.Core.Float16_Vec3_Access.Set
           (Image, 2, 2, Pixel (16#7C01#, 16#7E00#, 16#FC01#));
      end Check_Minimum;
   begin
      Minimum (1) := Pixel (16#0000#, 16#8000#, 16#0001#);
      Minimum (3) := Pixel (16#03FF#, 16#0400#, 16#3C00#);
      Minimum (6) := Pixel (16#BC00#, 16#7BFF#, 16#FBFF#);
      Minimum (8) := Pixel (16#7C00#, 16#FC00#, 16#7C01#);
      Minimum (11) := Pixel (16#7E00#, 16#FC01#, 16#7E55#);
      Minimum (13) := Pixel (16#0001#, 16#03FF#, 16#0400#);

      OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Strided_Mat_View
        (One_Row, 1, 4, 6, Check_One_Row'Access);
      OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Strided_Mat_View
        (One_Column, 3, 1, 3, Check_One_Column'Access);
      OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Strided_Mat_View
        (Tight, 2, 3, 3, Check_Tight'Access);
      OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Strided_Mat_View
        (Minimum, 3, 3, 5, Check_Minimum'Access);

      Assert_Component_Bits
        (One_Row (13),
         Pixel (16#7C00#, 16#0000#, 16#8000#),
         "one-row last write");
      Assert_Component_Bits
        (One_Row (14),
         Pixel (16#DEAD#, 16#BEEF#, 16#CAFE#),
         "one-row unused padding");
      Assert_Component_Bits
        (One_Column (23),
         Pixel (16#0400#, 16#3C00#, 16#BC00#),
         "one-column middle write");
      Assert_Component_Bits
        (One_Column (21),
         Pixel (16#DEAD#, 16#BEEF#, 16#CAFE#),
         "one-column unused padding");
      Assert_Component_Bits
        (Tight (6),
         Pixel (16#BC00#, 16#7BFF#, 16#FBFF#),
         "tight stride last write");
      Assert_Component_Bits
        (Minimum (13),
         Pixel (16#7C01#, 16#7E00#, 16#FC01#),
         "minimum storage last logical element write");
      Assert_Component_Bits
        (Minimum (4),
         Pixel (16#DEAD#, 16#BEEF#, 16#CAFE#),
         "minimum storage first-row padding");
      Assert_Component_Bits
        (Minimum (9),
         Pixel (16#DEAD#, 16#BEEF#, 16#CAFE#),
         "minimum storage second-row padding");
   end Strided_View_Handles_Special_Shapes_And_Minimum_Storage;

   procedure Invalid_Strided_Layouts_Do_Not_Invoke_Callback
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (1 .. 15 => Pixel (16#3C00#, 16#3C00#, 16#3C00#));
      Invoked : Boolean := False;

      procedure Mark (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Mark;

      procedure Short_Stride is
      begin
         OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Strided_Mat_View
           (Data, 3, 4, 3, Mark'Access);
      end Short_Stride;

      procedure Short_Buffer is
      begin
         OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Strided_Mat_View
           (Data, 3, 4, 6, Mark'Access);
      end Short_Buffer;

      procedure Capacity_Overflow is
      begin
         OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Strided_Mat_View
           (Data, 2, 1, Positive'Last, Mark'Access);
      end Capacity_Overflow;
   begin
      Assert_Raises_OpenCV_Error
        (Short_Stride'Access, "Float16 Vec3 short stride");
      Assert_Raises_OpenCV_Error
        (Short_Buffer'Access, "Float16 Vec3 short buffer");
      Assert_Raises_OpenCV_Error
        (Capacity_Overflow'Access, "Float16 Vec3 strided capacity overflow");
      AUnit.Assertions.Assert
        (not Invoked,
         "Invalid strided layouts must be rejected before callback"
         & " invocation");
      Assert_Component_Bits
        (Data (1),
         Pixel (16#3C00#, 16#3C00#, 16#3C00#),
         "Failed strided construction must leave caller storage unchanged");
   end Invalid_Strided_Layouts_Do_Not_Invoke_Callback;

   procedure Reports_Enforced_Vec3_Representation (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Size           : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Vec3.Vector'Size);
      Object_Size    : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Vec3.Vector'Object_Size);
      Component_Size : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Vec3.Vector'Component_Size);
      Alignment      : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Vec3.Vector'Alignment);
      Value_Size     : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Value'Size);
      Value_Object   : constant Natural :=
        Observed_Size (OpenCV.Core.Float16_Value'Object_Size);
      Buffer_Comp    : constant Natural :=
        Observed_Size
          (OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array'Component_Size);
      Description    : constant String :=
        "Float16_Vec3'Size="
        & Natural'Image (Size)
        & " Object_Size="
        & Natural'Image (Object_Size)
        & " Component_Size="
        & Natural'Image (Component_Size)
        & " Alignment="
        & Natural'Image (Alignment)
        & " Value_Size="
        & Natural'Image (Value_Size)
        & " Value_Object_Size="
        & Natural'Image (Value_Object)
        & " Buffer_Component_Size="
        & Natural'Image (Buffer_Comp);
   begin
      AUnit.Assertions.Assert
        (Value_Size = 16, "Float16_Value'Size must be 16: " & Description);
      AUnit.Assertions.Assert
        (Value_Object = 16,
         "Float16_Value'Object_Size must be 16: " & Description);
      AUnit.Assertions.Assert
        (Component_Size = 16,
         "Float16 Vec3 Component_Size must be 16: " & Description);
      AUnit.Assertions.Assert
        (Size = 48, "Float16 Vec3'Size must be 48: " & Description);
      AUnit.Assertions.Assert
        (Object_Size = 48,
         "Float16 Vec3'Object_Size must be 48: " & Description);
      AUnit.Assertions.Assert
        (Buffer_Comp = 48,
         "Float16 Vec3 Buffer_Array Component_Size must be 48: "
         & Description);
      AUnit.Assertions.Assert
        (Alignment <= 2,
         "Float16 Vec3 alignment must not exceed 2: " & Description);
   end Reports_Enforced_Vec3_Representation;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 external view is zero-copy at arbitrary lower"
            & " bound",
            Packed_View_Is_Zero_Copy_At_Arbitrary_Bound'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 external view preserves special binary16 encodings",
            Packed_View_Preserves_Special_Encodings'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 packed view preserves all 65536 binary16 encodings",
            Packed_View_Preserves_All_Binary16_Encodings'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 external view clone isolates and shallow escape"
            & " rejects",
            Packed_View_Clone_Isolates_And_Shallow_Escape_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 view callback exception preserves completed writes",
            Packed_View_Callback_Exception_Preserves_Writes'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 packed view rejects invalid geometry before"
            & " callback",
            Invalid_Packed_Geometry_Does_Not_Invoke_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 strided view maps logical elements and preserves"
            & " padding",
            Strided_View_Maps_Logical_Elements_And_Preserves_Padding'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 strided view handles special shapes and minimum"
            & " storage",
            Strided_View_Handles_Special_Shapes_And_Minimum_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 strided view rejects invalid layouts before"
            & " callback",
            Invalid_Strided_Layouts_Do_Not_Invoke_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 Vec3 view reports enforced representation",
            Reports_Enforced_Vec3_Representation'Access));
      return Result'Access;
   end Suite;

end Float16_Vec3_Mat_View_Tests;
