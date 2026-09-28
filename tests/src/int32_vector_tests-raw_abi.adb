with Ada.Unchecked_Conversion;
with AUnit.Assertions;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;

package body Int32_Vector_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type C.Int32_Vec2;
   use type C.Int32_Vec3;
   use type C.Int32_Vec4;
   use type Interfaces.Integer_32;
   function Convert is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        C.Mat_Handle);

   procedure Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      A2       : aliased constant C.Int32_Vec2 :=
        (C.C_Int32'First, C.C_Int32'Last);
      A3       : aliased constant C.Int32_Vec3 :=
        (-2_147_483_647, -1, 2_147_483_646);
      A4       : aliased constant C.Int32_Vec4 :=
        (C.C_Int32'First, 0, 1, C.C_Int32'Last);
      V2       : aliased C.Int32_Vec2 := (9, 8);
      V3       : aliased C.Int32_Vec3 := (9, 8, 7);
      V4       : aliased C.Int32_Vec4 := (9, 8, 7, 6);
      Indices  : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
      Row_Data : aliased C.C_Int32_Array (0 .. 11) := (others => 0);
      S        : C.Status;

      procedure Probe
        (H          : OpenCV.Core.Module_Interop.Input_Mat_Handle;
         Width      : Positive;
         Good, ND   : Boolean;
         Label_Text : String)
      is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         Indices := (0, 0, 0);
         case Width is
            when 2      =>
               V2 := (9, 8);
               S :=
                 (if ND
                  then
                    C.Mat_Get_Int32_Vec2_ND
                      (Raw, 3, Indices (0)'Access, V2'Access)
                  else C.Mat_Get_Int32_Vec2 (Raw, 0, 0, V2'Access));
               AUnit.Assertions.Assert
                 ((if Good
                   then S = C.Success
                   else S = C.Error_Invalid_Argument and then V2 = (0, 0)),
                  "Int32 C2 raw exact layout Get/zero");
               S :=
                 (if ND
                  then
                    C.Mat_Set_Int32_Vec2_ND
                      (Raw, 3, Indices (0)'Access, A2'Access)
                  else C.Mat_Set_Int32_Vec2 (Raw, 0, 0, A2'Access));
               AUnit.Assertions.Assert
                 (S = (if Good then C.Success else C.Error_Invalid_Argument),
                  "Int32 C2 raw exact layout Set");
               if Good then
                  S :=
                    (if ND
                     then
                       C.Mat_Get_Int32_Vec2_ND
                         (Raw, 3, Indices (0)'Access, V2'Access)
                     else C.Mat_Get_Int32_Vec2 (Raw, 0, 0, V2'Access));
                  AUnit.Assertions.Assert
                    (S = C.Success and then V2 = A2,
                     "C2 raw signed extrema round trip");
                  if not ND then
                     Row_Data (0) := A2.Component_0;
                     Row_Data (1) := A2.Component_1;
                     S :=
                       C.Mat_Write_Int32_Vec2_Row
                         (Raw, 1, Row_Data (0)'Address, 3);
                     AUnit.Assertions.Assert
                       (S = C.Success, "C2 raw row write");
                     Row_Data := (others => 0);
                     S :=
                       C.Mat_Read_Int32_Vec2_Row
                         (Raw, 1, Row_Data (0)'Address, 3);
                     AUnit.Assertions.Assert
                       (S = C.Success
                        and then Row_Data (0) = A2.Component_0
                        and then Row_Data (1) = A2.Component_1,
                        "C2 ABI int32_t row preserves extrema");
                  end if;
               end if;

            when 3      =>
               V3 := (9, 8, 7);
               S :=
                 (if ND
                  then
                    C.Mat_Get_Int32_Vec3_ND
                      (Raw, 3, Indices (0)'Access, V3'Access)
                  else C.Mat_Get_Int32_Vec3 (Raw, 0, 0, V3'Access));
               AUnit.Assertions.Assert
                 ((if Good
                   then S = C.Success
                   else S = C.Error_Invalid_Argument and then V3 = (0, 0, 0)),
                  "Int32 C3 raw exact layout Get/zero: " & Label_Text);
               S :=
                 (if ND
                  then
                    C.Mat_Set_Int32_Vec3_ND
                      (Raw, 3, Indices (0)'Access, A3'Access)
                  else C.Mat_Set_Int32_Vec3 (Raw, 0, 0, A3'Access));
               AUnit.Assertions.Assert
                 (S = (if Good then C.Success else C.Error_Invalid_Argument),
                  "Int32 C3 raw exact layout Set");
               if Good then
                  S :=
                    (if ND
                     then
                       C.Mat_Get_Int32_Vec3_ND
                         (Raw, 3, Indices (0)'Access, V3'Access)
                     else C.Mat_Get_Int32_Vec3 (Raw, 0, 0, V3'Access));
                  AUnit.Assertions.Assert
                    (S = C.Success and then V3 = A3,
                     "C3 raw signed values round trip");
                  if not ND then
                     Row_Data (0) := A3.Component_0;
                     Row_Data (1) := A3.Component_1;
                     Row_Data (2) := A3.Component_2;
                     S :=
                       C.Mat_Write_Int32_Vec3_Row
                         (Raw, 1, Row_Data (0)'Address, 3);
                     AUnit.Assertions.Assert
                       (S = C.Success, "C3 raw row write");
                     Row_Data := (others => 0);
                     S :=
                       C.Mat_Read_Int32_Vec3_Row
                         (Raw, 1, Row_Data (0)'Address, 3);
                     AUnit.Assertions.Assert
                       (S = C.Success
                        and then Row_Data (0) = A3.Component_0
                        and then Row_Data (1) = A3.Component_1
                        and then Row_Data (2) = A3.Component_2,
                        "C3 ABI int32_t row preserves signed values");
                  end if;
               end if;

            when 4      =>
               V4 := (9, 8, 7, 6);
               S :=
                 (if ND
                  then
                    C.Mat_Get_Int32_Vec4_ND
                      (Raw, 3, Indices (0)'Access, V4'Access)
                  else C.Mat_Get_Int32_Vec4 (Raw, 0, 0, V4'Access));
               AUnit.Assertions.Assert
                 ((if Good
                   then S = C.Success
                   else
                     S = C.Error_Invalid_Argument and then V4 = (0, 0, 0, 0)),
                  "Int32 C4 raw exact layout Get/zero");
               S :=
                 (if ND
                  then
                    C.Mat_Set_Int32_Vec4_ND
                      (Raw, 3, Indices (0)'Access, A4'Access)
                  else C.Mat_Set_Int32_Vec4 (Raw, 0, 0, A4'Access));
               AUnit.Assertions.Assert
                 (S = (if Good then C.Success else C.Error_Invalid_Argument),
                  "Int32 C4 raw exact layout Set");
               if Good then
                  S :=
                    (if ND
                     then
                       C.Mat_Get_Int32_Vec4_ND
                         (Raw, 3, Indices (0)'Access, V4'Access)
                     else C.Mat_Get_Int32_Vec4 (Raw, 0, 0, V4'Access));
                  AUnit.Assertions.Assert
                    (S = C.Success and then V4 = A4,
                     "C4 raw signed extrema round trip");
                  if not ND then
                     Row_Data (0) := A4.Component_0;
                     Row_Data (1) := A4.Component_1;
                     Row_Data (2) := A4.Component_2;
                     Row_Data (3) := A4.Component_3;
                     S :=
                       C.Mat_Write_Int32_Vec4_Row
                         (Raw, 1, Row_Data (0)'Address, 3);
                     AUnit.Assertions.Assert
                       (S = C.Success, "C4 raw row write");
                     Row_Data := (others => 0);
                     S :=
                       C.Mat_Read_Int32_Vec4_Row
                         (Raw, 1, Row_Data (0)'Address, 3);
                     AUnit.Assertions.Assert
                       (S = C.Success
                        and then Row_Data (0) = A4.Component_0
                        and then Row_Data (1) = A4.Component_1
                        and then Row_Data (2) = A4.Component_2
                        and then Row_Data (3) = A4.Component_3,
                        "C4 ABI int32_t row preserves extrema");
                  end if;
               end if;

            when others =>
               null;
         end case;
      end Probe;

      procedure Check_Mat
        (Depth           : OpenCV.Core.Depth_Type;
         Channels, Width : Positive;
         Good            : Boolean := False;
         ND              : Boolean := False)
      is
         Image : constant OpenCV.Core.Mat :=
           (if ND
            then
              OpenCV.Core.Create
                (Shape        => (2, 3, 4),
                 Element_Type => (Depth, OpenCV.Core.Channel_Count (Channels)))
            else
              OpenCV.Core.Create
                (2, 3, (Depth, OpenCV.Core.Channel_Count (Channels))));
         procedure Inspect (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         begin
            Probe
              (H,
               Width,
               Good,
               ND,
               OpenCV.Core.Depth_Type'Image (Depth)
               & Positive'Image (Channels)
               & Boolean'Image (ND));
         end Inspect;
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle (Image, Inspect'Access);
      end Check_Mat;

      procedure Check_Geometry (Width : Positive; ND : Boolean) is
         Image : constant OpenCV.Core.Mat :=
           (if ND
            then
              OpenCV.Core.Create
                (Shape        => (2, 3, 4),
                 Element_Type =>
                   (OpenCV.Core.Int32, OpenCV.Core.Channel_Count (Width)))
            else
              OpenCV.Core.Create
                (2,
                 3,
                 (OpenCV.Core.Int32, OpenCV.Core.Channel_Count (Width))));
         procedure Inspect (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
            Raw : constant C.Mat_Handle := Convert (H);
            procedure Reject
              (Label_Text : String;
               Row        : C.C_Int32 := 0;
               Col        : C.C_Int32 := 0;
               Count      : C.C_Int32 := 3;
               Index      : C.C_Int32 := 0;
               Null_Index : Boolean := False) is
            begin
               Indices (0) := Index;
               case Width is
                  when 2      =>
                     V2 := (9, 8);
                     S :=
                       (if ND
                        then
                          C.Mat_Get_Int32_Vec2_ND
                            (Raw,
                             Count,
                             (if Null_Index then null else Indices (0)'Access),
                             V2'Access)
                        else C.Mat_Get_Int32_Vec2 (Raw, Row, Col, V2'Access));
                     AUnit.Assertions.Assert
                       (S = C.Error_Invalid_Argument and then V2 = (0, 0),
                        "C2 " & Label_Text & " zeros Get");
                     S :=
                       (if ND
                        then
                          C.Mat_Set_Int32_Vec2_ND
                            (Raw,
                             Count,
                             (if Null_Index then null else Indices (0)'Access),
                             A2'Access)
                        else C.Mat_Set_Int32_Vec2 (Raw, Row, Col, A2'Access));

                  when 3      =>
                     V3 := (9, 8, 7);
                     S :=
                       (if ND
                        then
                          C.Mat_Get_Int32_Vec3_ND
                            (Raw,
                             Count,
                             (if Null_Index then null else Indices (0)'Access),
                             V3'Access)
                        else C.Mat_Get_Int32_Vec3 (Raw, Row, Col, V3'Access));
                     AUnit.Assertions.Assert
                       (S = C.Error_Invalid_Argument and then V3 = (0, 0, 0),
                        "C3 " & Label_Text & " zeros Get");
                     S :=
                       (if ND
                        then
                          C.Mat_Set_Int32_Vec3_ND
                            (Raw,
                             Count,
                             (if Null_Index then null else Indices (0)'Access),
                             A3'Access)
                        else C.Mat_Set_Int32_Vec3 (Raw, Row, Col, A3'Access));

                  when 4      =>
                     V4 := (9, 8, 7, 6);
                     S :=
                       (if ND
                        then
                          C.Mat_Get_Int32_Vec4_ND
                            (Raw,
                             Count,
                             (if Null_Index then null else Indices (0)'Access),
                             V4'Access)
                        else C.Mat_Get_Int32_Vec4 (Raw, Row, Col, V4'Access));
                     AUnit.Assertions.Assert
                       (S = C.Error_Invalid_Argument
                        and then V4 = (0, 0, 0, 0),
                        "C4 " & Label_Text & " zeros Get");
                     S :=
                       (if ND
                        then
                          C.Mat_Set_Int32_Vec4_ND
                            (Raw,
                             Count,
                             (if Null_Index then null else Indices (0)'Access),
                             A4'Access)
                        else C.Mat_Set_Int32_Vec4 (Raw, Row, Col, A4'Access));

                  when others =>
                     null;
               end case;
               AUnit.Assertions.Assert
                 (S = C.Error_Invalid_Argument,
                  "C"
                  & Positive'Image (Width)
                  & " "
                  & Label_Text
                  & " rejects Set");
            end Reject;
         begin
            if ND then
               Reject ("null indices", Null_Index => True);
               Reject ("dimension count", Count => 2);
               Reject ("negative index", Index => -1);
               Reject ("past extent", Index => 2);
            else
               Reject ("negative row", Row => -1);
               Reject ("row extent", Row => 2);
               Reject ("negative column", Col => -1);
               Reject ("column extent", Col => 3);
            end if;
         end Inspect;
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle (Image, Inspect'Access);
      end Check_Geometry;
   begin
      for Width in 2 .. 4 loop
         Check_Mat (OpenCV.Core.Int32, Width, Width, Good => True);
         Check_Mat (OpenCV.Core.Int32, Width, Width, Good => True, ND => True);
         Check_Geometry (Width, ND => False);
         Check_Geometry (Width, ND => True);
      end loop;
      --  Same element byte count must never substitute for depth/channels.
      Check_Mat (OpenCV.Core.Float64, 1, 2);
      Check_Mat (OpenCV.Core.Float32, 2, 2);
      Check_Mat (OpenCV.Core.Int16, 4, 2);
      Check_Mat (OpenCV.Core.UInt16, 4, 2);
      Check_Mat (OpenCV.Core.Float32, 3, 3);
      Check_Mat (OpenCV.Core.Int16, 6, 3);
      Check_Mat (OpenCV.Core.UInt16, 6, 3);
      Check_Mat (OpenCV.Core.UInt8, 12, 3);
      Check_Mat (OpenCV.Core.Float64, 2, 4);
      Check_Mat (OpenCV.Core.Float32, 4, 4);
      Check_Mat (OpenCV.Core.Int16, 8, 4);
      Check_Mat (OpenCV.Core.UInt8, 16, 4);
      Check_Mat (OpenCV.Core.Float32, 3, 3, ND => True);
      Check_Mat (OpenCV.Core.Float64, 2, 4, ND => True);
      V2 := (9, 8);
      V3 := (9, 8, 7);
      V4 := (9, 8, 7, 6);
      S := C.Mat_Get_Int32_Vec2 (C.Null_Mat_Handle, 0, 0, V2'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument and then V2 = (0, 0),
         "C2 null handle zeroes output");
      S := C.Mat_Get_Int32_Vec3 (C.Null_Mat_Handle, 0, 0, V3'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument and then V3 = (0, 0, 0),
         "C3 null handle zeroes output");
      S := C.Mat_Get_Int32_Vec4 (C.Null_Mat_Handle, 0, 0, V4'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument and then V4 = (0, 0, 0, 0),
         "C4 null handle zeroes output");
      S := C.Mat_Set_Int32_Vec2 (C.Null_Mat_Handle, 0, 0, A2'Access);
      AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "C2 null Set");
      S := C.Mat_Set_Int32_Vec3 (C.Null_Mat_Handle, 0, 0, A3'Access);
      AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "C3 null Set");
      S := C.Mat_Set_Int32_Vec4 (C.Null_Mat_Handle, 0, 0, A4'Access);
      AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "C4 null Set");
   end Check;
end Int32_Vector_Tests.Raw_ABI;
