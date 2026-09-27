with AUnit.Assertions;
with OpenCV;

package body ND_Selected_View_Checks is

   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Dimension_Array;
   use type OpenCV.Core.Mat_Size;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      AUnit.Assertions.Assert (Condition, Name & " " & Message);
   end Check;

   --  Packed ordinal of (I, J, L, K) in a 2 x 3 x 2 x 4 volume.
   function Ordinal (I, J, L, K : Natural) return Natural
   is (((I * 3 + J) * 2 + L) * 4 + K);

   function Index (I, J, L, K : Natural) return OpenCV.Core.Index_Array
   is (OpenCV.Size_Coordinate (I),
       OpenCV.Size_Coordinate (J),
       OpenCV.Size_Coordinate (L),
       OpenCV.Size_Coordinate (K));

   function Index (Row, Column : Natural) return OpenCV.Core.Index_Array
   is (OpenCV.Size_Coordinate (Row), OpenCV.Size_Coordinate (Column));

   procedure Check_Middle_Drop is
      Source     : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 2, 4), Element_Type => Element_Type);
      Selections : constant OpenCV.Core.Dimension_Selection_Array (7 .. 10) :=
        ((Kind => OpenCV.Core.Fix_Index, Index => 1),
         (Kind => OpenCV.Core.Keep_Range, Bounds => (Start => 0, Stop => 3)),
         (Kind => OpenCV.Core.Fix_Index, Index => 1),
         (Kind => OpenCV.Core.Keep_Range, Bounds => (Start => 0, Stop => 4)));
      Invoked    : Boolean := False;

      procedure Process (View : in out OpenCV.Core.Mat) is
      begin
         Invoked := True;
         Check
           (View.Depth = Element_Type.Depth
            and then View.Channels = Element_Type.Channels,
            "selected view must preserve depth and channels");
         Check
           (View.Dimension_Count = 2
            and then View.Rows = 3
            and then View.Columns = 4
            and then View.Total = 12
            and then View.Shape = OpenCV.Core.Dimension_Array'(3, 4),
            "selected view must be a 3 x 4 Mat");
         Check
           (not View.Is_Continuous,
            "a middle-axis drop must keep the gapped outer stride");

         for J in 0 .. 2 loop
            for K in 0 .. 3 loop
               Check
                 (Get (View, Index (J, K)) = Value_At (Ordinal (1, J, 1, K)),
                  "View (J, K) must read Source (1, J, 1, K)");
            end loop;
         end loop;

         for J in 0 .. 2 loop
            for K in 0 .. 3 loop
               Set (View, Index (J, K), Value_At (100 + J * 4 + K));
               Check
                 (Get (Source, Index (1, J, 1, K))
                  = Value_At (100 + J * 4 + K),
                  "a View write must reach Source (1, J, 1, K)");
            end loop;
         end loop;

         Set (Source, Index (1, 2, 1, 3), Value_At (200));
         Check
           (Get (View, Index (2, 3)) = Value_At (200),
            "a source write must be visible through the View");
      end Process;
   begin
      for I in 0 .. 1 loop
         for J in 0 .. 2 loop
            for L in 0 .. 1 loop
               for K in 0 .. 3 loop
                  Set
                    (Source,
                     Index (I, J, L, K),
                     Value_At (Ordinal (I, J, L, K)));
               end loop;
            end loop;
         end loop;
      end loop;

      OpenCV.Core.With_Selected_View (Source, Selections, Process'Access);
      Check (Invoked, "selected view callback must run");

      for I in 0 .. 1 loop
         for J in 0 .. 2 loop
            for L in 0 .. 1 loop
               for K in 0 .. 3 loop
                  if I /= 1 or else L /= 1 then
                     Check
                       (Get (Source, Index (I, J, L, K))
                        = Value_At (Ordinal (I, J, L, K)),
                        "unselected source elements must be unchanged");
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
   end Check_Middle_Drop;

end ND_Selected_View_Checks;
