with AUnit.Assertions;
with Mat_Test_Support;
with OpenCV;
with System;

package body Read_Only_Mat_View_Checks is
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Dimension_Array;
   use type OpenCV.Core.Mat_Size;
   use type System.Address;

   procedure Check (OK : Boolean; Message : String) is
   begin
      AUnit.Assertions.Assert (OK, Name & ": " & Message);
   end Check;

   function Values (First, Count : Natural) return View_Array is
      Result : View_Array (First .. First + Count - 1);
   begin
      for I in Result'Range loop
         Result (I) := Value_At (I - First);
      end loop;
      return Result;
   end Values;

   procedure Check_Packed is
      Data    : aliased constant View_Array := Values (11, 24);
      Small   : aliased constant View_Array := Values (11, 6);
      Shape   : constant OpenCV.Core.Dimension_Array (7 .. 9) := (2, 3, 4);
      Invoked : Natural := 0;

      procedure Inspect_Buffer (Buffer : aliased Borrow_Array) is
      begin
         Check (Buffer'Length = 24, "packed buffer length");
         Check (Buffer (0)'Address = Data (11)'Address, "zero-copy address");
         for I in 0 .. 23 loop
            Check (Buffer (I) = Data (11 + I), "flat element mapping");
         end loop;
      end Inspect_Buffer;

      procedure Inspect_ND (Image : OpenCV.Core.Mat) is
      begin
         Invoked := Invoked + 1;
         Check
           (Image.Depth = Expected.Depth
            and then Image.Channels = Expected.Channels,
            "element type");
         Check
           (Image.Shape = OpenCV.Core.Dimension_Array'(2, 3, 4)
            and then Image.Total = 24
            and then Image.Is_Continuous,
            "packed shape/continuity");
         for I in 0 .. 1 loop
            for J in 0 .. 2 loop
               for K in 0 .. 3 loop
                  Check
                    (Get
                       (Image,
                        (OpenCV.Size_Coordinate (I),
                         OpenCV.Size_Coordinate (J),
                         OpenCV.Size_Coordinate (K)))
                     = Data (11 + (I * 3 + J) * 4 + K),
                     "N-D Get");
               end loop;
            end loop;
         end loop;
         Borrow (Image, Inspect_Buffer'Access);
      end Inspect_ND;

      procedure Inspect_2D (Image : OpenCV.Core.Mat) is
      begin
         Invoked := Invoked + 1;
         Check
           (Image.Depth = Expected.Depth
            and then Image.Channels = Expected.Channels,
            "2-D type");
         Check
           (Image.Rows = 2
            and then Image.Columns = 3
            and then Image.Shape = OpenCV.Core.Dimension_Array'(2, 3)
            and then Image.Is_Continuous,
            "2-D shape");
         for I in 0 .. 1 loop
            for J in 0 .. 2 loop
               Check
                 (Get
                    (Image,
                     (OpenCV.Size_Coordinate (I), OpenCV.Size_Coordinate (J)))
                  = Small (11 + I * 3 + J),
                  "2-D Get");
            end loop;
         end loop;
      end Inspect_2D;
   begin
      Packed_ND (Data, Shape, Inspect_ND'Access);
      Packed_2D (Small, 2, 3, Inspect_2D'Access);
      Packed_ND (Small, (2, 3), Inspect_2D'Access);
      Check (Invoked = 3, "all packed callbacks invoked");
   end Check_Packed;

   procedure Check_Strided is
      Data           : aliased constant View_Array := Values (17, 40);
      Small          : aliased constant View_Array := Values (17, 10);
      Packed         : aliased constant View_Array := Values (17, 24);
      Shape          : constant OpenCV.Core.Dimension_Array (7 .. 9) :=
        (2, 3, 4);
      Gaps           :
        constant OpenCV.Core.Dimension_Stride_Array (11 .. 13) := (20, 6, 1);
      Tight          :
        constant OpenCV.Core.Dimension_Stride_Array (11 .. 13) := (12, 4, 1);
      Invoked        : Natural := 0;
      Borrow_Invoked : Boolean := False;

      procedure Never (Buffer : aliased Borrow_Array) is
         pragma Unreferenced (Buffer);
      begin
         Borrow_Invoked := True;
      end Never;

      procedure Inspect_Gaps (Image : OpenCV.Core.Mat) is
         procedure Try_Borrow is
         begin
            Borrow (Image, Never'Access);
         end Try_Borrow;
      begin
         Invoked := Invoked + 1;
         Check
           (Image.Depth = Expected.Depth
            and then Image.Channels = Expected.Channels,
            "gapped element type");
         Check
           (Image.Shape = OpenCV.Core.Dimension_Array'(2, 3, 4)
            and then Image.Total = 24
            and then not Image.Is_Continuous,
            "gapped shape/continuity");
         for I in 0 .. 1 loop
            for J in 0 .. 2 loop
               for K in 0 .. 3 loop
                  Check
                    (Get
                       (Image,
                        (OpenCV.Size_Coordinate (I),
                         OpenCV.Size_Coordinate (J),
                         OpenCV.Size_Coordinate (K)))
                     = Data (17 + I * 20 + J * 6 + K),
                     "gapped Get");
               end loop;
            end loop;
         end loop;
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Try_Borrow'Access, Name & " gapped buffer must reject");
         Check (not Borrow_Invoked, "gapped borrow callback not invoked");
      end Inspect_Gaps;

      procedure Inspect_Row (Image : OpenCV.Core.Mat) is
         procedure Try_Borrow is
         begin
            Borrow (Image, Never'Access);
         end Try_Borrow;
      begin
         Invoked := Invoked + 1;
         Check
           (Image.Rows = 2
            and then Image.Columns = 3
            and then not Image.Is_Continuous,
            "row-strided geometry");
         for I in 0 .. 1 loop
            for J in 0 .. 2 loop
               Check
                 (Get
                    (Image,
                     (OpenCV.Size_Coordinate (I), OpenCV.Size_Coordinate (J)))
                  = Small (17 + I * 5 + J),
                  "row-strided Get");
            end loop;
         end loop;
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Try_Borrow'Access, Name & " row-strided buffer must reject");
         Check (not Borrow_Invoked, "row borrow callback not invoked");
      end Inspect_Row;

      procedure Inspect_Tight (Image : OpenCV.Core.Mat) is
         procedure Inspect_Buffer (Buffer : aliased Borrow_Array) is
         begin
            Check
              (Buffer'Length = 24
               and then Buffer (0)'Address = Packed (17)'Address,
               "tight strides borrow caller address");
         end Inspect_Buffer;
      begin
         Invoked := Invoked + 1;
         Check
           (Image.Is_Continuous and then Image.Total = 24,
            "packed-equivalent strides are continuous");
         for I in 0 .. 1 loop
            for J in 0 .. 2 loop
               for K in 0 .. 3 loop
                  Check
                    (Get
                       (Image,
                        (OpenCV.Size_Coordinate (I),
                         OpenCV.Size_Coordinate (J),
                         OpenCV.Size_Coordinate (K)))
                     = Packed (17 + (I * 3 + J) * 4 + K),
                     "packed-equivalent mapping");
               end loop;
            end loop;
         end loop;
         Borrow (Image, Inspect_Buffer'Access);
      end Inspect_Tight;
   begin
      Strided_ND (Data, Shape, Gaps, Inspect_Gaps'Access);
      Strided_2D (Small, 2, 3, 5, Inspect_Row'Access);
      Strided_ND (Packed, Shape, Tight, Inspect_Tight'Access);
      Check (Invoked = 3, "all strided callbacks invoked");
      for I in Data'Range loop
         Check
           (Data (I) = Value_At (I - Data'First),
            "caller storage/padding unchanged");
      end loop;
   end Check_Strided;
end Read_Only_Mat_View_Checks;
