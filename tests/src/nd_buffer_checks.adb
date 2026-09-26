with AUnit.Assertions;
with Mat_Test_Support;
with OpenCV;

package body ND_Buffer_Checks is

   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Size_Coordinate;

   function Offset (I, J, K : Natural) return Natural
   is (((I * 3) + J) * 4 + K);

   function Index (I, J, K : Natural) return OpenCV.Core.Index_Array
   is (OpenCV.Size_Coordinate (I),
       OpenCV.Size_Coordinate (J),
       OpenCV.Size_Coordinate (K));

   function Filled_Volume return OpenCV.Core.Mat is
      Volume : OpenCV.Core.Mat :=
        OpenCV.Core.Create (Shape => (2, 3, 4), Element_Type => Element_Type);
   begin
      for I in 0 .. 1 loop
         for J in 0 .. 2 loop
            for K in 0 .. 3 loop
               Set (Volume, Index (I, J, K), Value_At (Offset (I, J, K)));
            end loop;
         end loop;
      end loop;
      return Volume;
   end Filled_Volume;

   procedure Check_Volume is
      Volume        : OpenCV.Core.Mat := Filled_Volume;
      Alias         : OpenCV.Core.Mat := Volume;
      Read_Invoked  : Boolean := False;
      Write_Invoked : Boolean := False;

      procedure Inspect (Data : aliased Buffer_Array) is
      begin
         Read_Invoked := True;
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 24,
            Name & " N-D buffer must expose 24 complete elements from 0");
         for I in 0 .. 1 loop
            for J in 0 .. 2 loop
               for K in 0 .. 3 loop
                  AUnit.Assertions.Assert
                    (Data (Offset (I, J, K)) = Get (Volume, Index (I, J, K))
                     and then Data (Offset (I, J, K))
                              = Value_At (Offset (I, J, K)),
                     Name
                     & " flat offset ((I * 3) + J) * 4 + K must match"
                     & " N-D Get");
               end loop;
            end loop;
         end loop;
         AUnit.Assertions.Assert
           (Data (Data'Last) = Get (Volume, Index (1, 2, 3)),
            Name & " last flat element must be index (1, 2, 3)");
      end Inspect;

      procedure Mutate (Data : aliased in out Buffer_Array) is
      begin
         Write_Invoked := True;
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 24,
            Name & " writable N-D buffer must expose 24 elements");
         Data (Offset (1, 2, 3)) := Value_At (100);
         AUnit.Assertions.Assert
           (Get (Alias, Index (1, 2, 3)) = Value_At (100),
            Name & " buffer write must be immediately visible to N-D Get");
         Set (Alias, Index (0, 1, 2), Value_At (101));
         AUnit.Assertions.Assert
           (Data (Offset (0, 1, 2)) = Value_At (101),
            Name & " alias N-D Set must be immediately visible in Data");
      end Mutate;
   begin
      AUnit.Assertions.Assert
        (Volume.Dimension_Count = 3
         and then Volume.Is_Continuous
         and then Volume.Total = 24,
         Name & " fixture must be a continuous 2 x 3 x 4 Mat");
      With_Read_Only_Buffer (Volume, Inspect'Access);
      With_Writable_Buffer (Volume, Mutate'Access);
      AUnit.Assertions.Assert
        (Read_Invoked and then Write_Invoked,
         Name & " N-D buffer callbacks must be invoked");
      AUnit.Assertions.Assert
        (Get (Volume, Index (1, 2, 3)) = Value_At (100)
         and then Get (Volume, Index (0, 1, 2)) = Value_At (101),
         Name & " completed buffer writes must remain visible");
   end Check_Volume;

   procedure Check_Continuous_Slice is
      Source  : constant OpenCV.Core.Mat := Filled_Volume;
      View    : OpenCV.Core.Mat := Source.Slice (((1, 2), (0, 3), (0, 4)));
      Invoked : Boolean := False;

      procedure Mutate (Data : aliased in out Buffer_Array) is
      begin
         Invoked := True;
         AUnit.Assertions.Assert
           (Data'First = 0 and then Data'Length = 12,
            Name & " continuous Slice must expose 12 elements");
         AUnit.Assertions.Assert
           (Data (0) = Value_At (Offset (1, 0, 0))
            and then Data (11) = Value_At (Offset (1, 2, 3)),
            Name & " Slice first/last must be source (1, 0, 0) and (1, 2, 3)");
         Data (5) := Value_At (102);
      end Mutate;
   begin
      AUnit.Assertions.Assert
        (View.Dimension_Count = 3
         and then View.Extent (1) = 1
         and then View.Total = 12
         and then View.Is_Continuous,
         Name & " leading-axis 1 x 3 x 4 Slice must be continuous");
      With_Writable_Buffer (View, Mutate'Access);
      AUnit.Assertions.Assert
        (Invoked, Name & " continuous Slice callback must be invoked");
      --  Slice offset 5 = (0, 1, 1) in the view = (1, 1, 1) in the source.
      AUnit.Assertions.Assert
        (Get (Source, Index (1, 1, 1)) = Value_At (102),
         Name & " Slice buffer write must be visible through the source");
   end Check_Continuous_Slice;

   procedure Check_Gapped_Slice is
      Source  : constant OpenCV.Core.Mat := Filled_Volume;
      View    : OpenCV.Core.Mat := Source.Slice (((0, 2), (1, 2), (0, 4)));
      Invoked : Boolean := False;

      procedure Inspect (Data : aliased Buffer_Array) is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Inspect;

      procedure Mutate (Data : aliased in out Buffer_Array) is
         pragma Unreferenced (Data);
      begin
         Invoked := True;
      end Mutate;

      procedure Read_Gapped is
      begin
         With_Read_Only_Buffer (View, Inspect'Access);
      end Read_Gapped;

      procedure Write_Gapped is
      begin
         With_Writable_Buffer (View, Mutate'Access);
      end Write_Gapped;
   begin
      AUnit.Assertions.Assert
        (View.Dimension_Count = 3
         and then View.Total = 8
         and then not View.Is_Continuous,
         Name & " middle-axis 2 x 1 x 4 Slice must be non-continuous");
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Read_Gapped'Access, Name & " read-only gapped N-D Slice");
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Write_Gapped'Access, Name & " writable gapped N-D Slice");
      AUnit.Assertions.Assert
        (not Invoked,
         Name & " gapped N-D Slice must be rejected before Process");
   end Check_Gapped_Slice;

end ND_Buffer_Checks;
