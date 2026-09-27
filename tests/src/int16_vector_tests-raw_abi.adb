with Ada.Unchecked_Conversion;
with Interfaces;
with AUnit.Assertions;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;

package body Int16_Vector_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type C.Int16_Vec2;
   use type C.Int16_Vec3;
   use type C.Int16_Vec4;
   use type Interfaces.Integer_16;
   use type C.C_Int32;
   function Convert is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        C.Mat_Handle);

   procedure Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Indices : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
      A2      : aliased constant C.Int16_Vec2 := (-32_768, 32_767);
      A3      : aliased constant C.Int16_Vec3 := (-32_767, -1, 32_766);
      A4      : aliased constant C.Int16_Vec4 := (-32_768, -1, 0, 32_767);
      V2      : aliased C.Int16_Vec2 := (9, 8);
      V3      : aliased C.Int16_Vec3 := (9, 8, 7);
      V4      : aliased C.Int16_Vec4 := (9, 8, 7, 6);
      S       : C.Status;

      procedure Probe
        (H     : OpenCV.Core.Module_Interop.Input_Mat_Handle;
         Width : Positive;
         Good  : Boolean;
         ND    : Boolean)
      is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         case Width is
            when 2      =>
               V2 := (9, 8);
               if ND then
                  S :=
                    C.Mat_Get_Int16_Vec2_ND
                      (Raw, 3, Indices (0)'Access, V2'Access);
               else
                  S := C.Mat_Get_Int16_Vec2 (Raw, 0, 0, V2'Access);
               end if;
               if Good then
                  AUnit.Assertions.Assert (S = C.Success, "Int16 C2 raw Get");
               else
                  AUnit.Assertions.Assert
                    (S = C.Error_Invalid_Argument and then V2 = (0, 0),
                     "Int16 C2 rejects same-byte wrong layout and zeros Get");
               end if;
               if ND then
                  S :=
                    C.Mat_Set_Int16_Vec2_ND
                      (Raw, 3, Indices (0)'Access, A2'Access);
               else
                  S := C.Mat_Set_Int16_Vec2 (Raw, 0, 0, A2'Access);
               end if;
               AUnit.Assertions.Assert
                 (S = (if Good then C.Success else C.Error_Invalid_Argument),
                  "Int16 C2 raw Set exact type");
               if Good then
                  if ND then
                     S :=
                       C.Mat_Get_Int16_Vec2_ND
                         (Raw, 3, Indices (0)'Access, V2'Access);
                  else
                     S := C.Mat_Get_Int16_Vec2 (Raw, 0, 0, V2'Access);
                  end if;
                  AUnit.Assertions.Assert
                    (S = C.Success and then V2 = A2,
                     "Int16 C2 signed raw round trip");
               end if;

            when 3      =>
               V3 := (9, 8, 7);
               if ND then
                  S :=
                    C.Mat_Get_Int16_Vec3_ND
                      (Raw, 3, Indices (0)'Access, V3'Access);
               else
                  S := C.Mat_Get_Int16_Vec3 (Raw, 0, 0, V3'Access);
               end if;
               if Good then
                  AUnit.Assertions.Assert (S = C.Success, "Int16 C3 raw Get");
               else
                  AUnit.Assertions.Assert
                    (S = C.Error_Invalid_Argument and then V3 = (0, 0, 0),
                     "Int16 C3 rejects same-byte wrong layout and zeros Get");
               end if;
               if ND then
                  S :=
                    C.Mat_Set_Int16_Vec3_ND
                      (Raw, 3, Indices (0)'Access, A3'Access);
               else
                  S := C.Mat_Set_Int16_Vec3 (Raw, 0, 0, A3'Access);
               end if;
               AUnit.Assertions.Assert
                 (S = (if Good then C.Success else C.Error_Invalid_Argument),
                  "Int16 C3 raw Set exact type");
               if Good then
                  if ND then
                     S :=
                       C.Mat_Get_Int16_Vec3_ND
                         (Raw, 3, Indices (0)'Access, V3'Access);
                  else
                     S := C.Mat_Get_Int16_Vec3 (Raw, 0, 0, V3'Access);
                  end if;
                  AUnit.Assertions.Assert
                    (S = C.Success and then V3 = A3,
                     "Int16 C3 signed raw round trip");
               end if;

            when 4      =>
               V4 := (9, 8, 7, 6);
               if ND then
                  S :=
                    C.Mat_Get_Int16_Vec4_ND
                      (Raw, 3, Indices (0)'Access, V4'Access);
               else
                  S := C.Mat_Get_Int16_Vec4 (Raw, 0, 0, V4'Access);
               end if;
               if Good then
                  AUnit.Assertions.Assert (S = C.Success, "Int16 C4 raw Get");
               else
                  AUnit.Assertions.Assert
                    (S = C.Error_Invalid_Argument and then V4 = (0, 0, 0, 0),
                     "Int16 C4 rejects same-byte wrong layout and zeros Get");
               end if;
               if ND then
                  S :=
                    C.Mat_Set_Int16_Vec4_ND
                      (Raw, 3, Indices (0)'Access, A4'Access);
               else
                  S := C.Mat_Set_Int16_Vec4 (Raw, 0, 0, A4'Access);
               end if;
               AUnit.Assertions.Assert
                 (S = (if Good then C.Success else C.Error_Invalid_Argument),
                  "Int16 C4 raw Set exact type");
               if Good then
                  if ND then
                     S :=
                       C.Mat_Get_Int16_Vec4_ND
                         (Raw, 3, Indices (0)'Access, V4'Access);
                  else
                     S := C.Mat_Get_Int16_Vec4 (Raw, 0, 0, V4'Access);
                  end if;
                  AUnit.Assertions.Assert
                    (S = C.Success and then V4 = A4,
                     "Int16 C4 signed raw round trip");
               end if;

            when others =>
               null;
         end case;
      end Probe;

      procedure Check_Mat
        (Depth    : OpenCV.Core.Depth_Type;
         Channels : Positive;
         Width    : Positive;
         Good     : Boolean := False;
         ND       : Boolean := False)
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
            Probe (H, Width, Good, ND);
         end Inspect;
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle (Image, Inspect'Access);
      end Check_Mat;

      procedure Bad_Arguments (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_Int16_Vec2 (Raw, 0, 0, null);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "C2 null out");
         S := C.Mat_Set_Int16_Vec2 (Raw, 0, 0, null);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "C2 null in");
         S := C.Mat_Get_Int16_Vec3 (Raw, 0, 0, null);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "C3 null out");
         S := C.Mat_Set_Int16_Vec3 (Raw, 0, 0, null);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "C3 null in");
         S := C.Mat_Get_Int16_Vec4 (Raw, 0, 0, null);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "C4 null out");
         S := C.Mat_Set_Int16_Vec4 (Raw, 0, 0, null);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "C4 null in");
         S := C.Mat_Get_Int16_Vec2_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "C2 ND null out");
         S := C.Mat_Get_Int16_Vec3_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "C3 ND null out");
         S := C.Mat_Get_Int16_Vec4_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "C4 ND null out");
         S := C.Mat_Set_Int16_Vec2_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "C2 ND null in");
         S := C.Mat_Set_Int16_Vec3_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "C3 ND null in");
         S := C.Mat_Set_Int16_Vec4_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "C4 ND null in");

      end Bad_Arguments;
      procedure Check_Bad_Geometry (Width : Positive; ND : Boolean) is
         Image : constant OpenCV.Core.Mat :=
           (if ND
            then
              OpenCV.Core.Create
                (Shape        => (2, 3, 4),
                 Element_Type =>
                   (OpenCV.Core.Int16, OpenCV.Core.Channel_Count (Width)))
            else
              OpenCV.Core.Create
                (2,
                 3,
                 (OpenCV.Core.Int16, OpenCV.Core.Channel_Count (Width))));

         procedure Inspect (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
            Raw : constant C.Mat_Handle := Convert (H);

            procedure Reject_Get
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
                          C.Mat_Get_Int16_Vec2_ND
                            (Raw,
                             Count,
                             (if Null_Index then null else Indices (0)'Access),
                             V2'Access)
                        else C.Mat_Get_Int16_Vec2 (Raw, Row, Col, V2'Access));
                     AUnit.Assertions.Assert
                       (S = C.Error_Invalid_Argument and then V2 = (0, 0),
                        "C2 " & Label_Text & " zeroes Get");

                  when 3      =>
                     V3 := (9, 8, 7);
                     S :=
                       (if ND
                        then
                          C.Mat_Get_Int16_Vec3_ND
                            (Raw,
                             Count,
                             (if Null_Index then null else Indices (0)'Access),
                             V3'Access)
                        else C.Mat_Get_Int16_Vec3 (Raw, Row, Col, V3'Access));
                     AUnit.Assertions.Assert
                       (S = C.Error_Invalid_Argument and then V3 = (0, 0, 0),
                        "C3 " & Label_Text & " zeroes Get");

                  when 4      =>
                     V4 := (9, 8, 7, 6);
                     S :=
                       (if ND
                        then
                          C.Mat_Get_Int16_Vec4_ND
                            (Raw,
                             Count,
                             (if Null_Index then null else Indices (0)'Access),
                             V4'Access)
                        else C.Mat_Get_Int16_Vec4 (Raw, Row, Col, V4'Access));
                     AUnit.Assertions.Assert
                       (S = C.Error_Invalid_Argument
                        and then V4 = (0, 0, 0, 0),
                        "C4 " & Label_Text & " zeroes Get");

                  when others =>
                     null;
               end case;
            end Reject_Get;

            procedure Reject_Set
              (Label_Text : String;
               Count      : C.C_Int32 := 3;
               Index      : C.C_Int32 := 0;
               Null_Index : Boolean := False) is
            begin
               Indices (0) := Index;
               case Width is
                  when 2      =>
                     S :=
                       C.Mat_Set_Int16_Vec2_ND
                         (Raw,
                          Count,
                          (if Null_Index then null else Indices (0)'Access),
                          A2'Access);

                  when 3      =>
                     S :=
                       C.Mat_Set_Int16_Vec3_ND
                         (Raw,
                          Count,
                          (if Null_Index then null else Indices (0)'Access),
                          A3'Access);

                  when 4      =>
                     S :=
                       C.Mat_Set_Int16_Vec4_ND
                         (Raw,
                          Count,
                          (if Null_Index then null else Indices (0)'Access),
                          A4'Access);

                  when others =>
                     null;
               end case;
               AUnit.Assertions.Assert
                 (S = C.Error_Invalid_Argument,
                  "C" & Positive'Image (Width) & " " & Label_Text & " Set");
            end Reject_Set;
         begin
            if ND then
               Reject_Get ("null indices", Null_Index => True);
               Reject_Set ("null indices", Null_Index => True);
               Reject_Get ("wrong dimension count", Count => 2);
               Reject_Set ("wrong dimension count", Count => 2);
               Reject_Get ("negative coordinate", Index => -1);
               Reject_Set ("negative coordinate", Index => -1);
               Reject_Get ("coordinate extent", Index => 2);
               Reject_Set ("coordinate extent", Index => 2);
            else
               Reject_Get ("negative row", Row => -1);
               Reject_Get ("column extent", Col => 3);
               Reject_Get ("row extent", Row => 2);
            end if;
         end Inspect;
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle (Image, Inspect'Access);
      end Check_Bad_Geometry;
   begin
      for Width in 2 .. 4 loop
         Check_Mat (OpenCV.Core.Int16, Width, Width, True);
         Check_Mat (OpenCV.Core.Int16, Width, Width, True, True);
         Check_Mat (OpenCV.Core.UInt16, Width, Width);
         Check_Mat (OpenCV.Core.UInt16, Width, Width, ND => True);
      end loop;
      Check_Mat (OpenCV.Core.Float32, 1, 2);
      Check_Mat (OpenCV.Core.UInt8, 4, 2);
      Check_Mat (OpenCV.Core.Float16, 3, 3);
      Check_Mat (OpenCV.Core.UInt8, 6, 3);
      Check_Mat (OpenCV.Core.Float64, 1, 4);
      Check_Mat (OpenCV.Core.Float32, 2, 4);
      declare
         Good_ND : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Int16, 2));
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle
           (Good_ND, Bad_Arguments'Access);
      end;
      for Width in 2 .. 4 loop
         Check_Bad_Geometry (Width, ND => True);
         Check_Bad_Geometry (Width, ND => False);
      end loop;
      V2 := (9, 8);
      V3 := (9, 8, 7);
      V4 := (9, 8, 7, 6);
      S := C.Mat_Get_Int16_Vec2 (C.Null_Mat_Handle, 0, 0, V2'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument and then V2 = (0, 0), "C2 null Mat");
      S := C.Mat_Get_Int16_Vec3 (C.Null_Mat_Handle, 0, 0, V3'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument and then V3 = (0, 0, 0), "C3 null Mat");
      S := C.Mat_Get_Int16_Vec4 (C.Null_Mat_Handle, 0, 0, V4'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument and then V4 = (0, 0, 0, 0),
         "C4 null Mat");
      S := C.Mat_Set_Int16_Vec2 (C.Null_Mat_Handle, 0, 0, A2'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument, "C2 null Set Mat");
      S := C.Mat_Set_Int16_Vec3 (C.Null_Mat_Handle, 0, 0, A3'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument, "C3 null Set Mat");
      S := C.Mat_Set_Int16_Vec4 (C.Null_Mat_Handle, 0, 0, A4'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument, "C4 null Set Mat");
      V2 := (9, 8);
      V3 := (9, 8, 7);
      V4 := (9, 8, 7, 6);
      S :=
        C.Mat_Get_Int16_Vec2_ND
          (C.Null_Mat_Handle, 3, Indices (0)'Access, V2'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument and then V2 = (0, 0), "C2 null ND Mat");
      S :=
        C.Mat_Get_Int16_Vec3_ND
          (C.Null_Mat_Handle, 3, Indices (0)'Access, V3'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument and then V3 = (0, 0, 0),
         "C3 null ND Mat");
      S :=
        C.Mat_Get_Int16_Vec4_ND
          (C.Null_Mat_Handle, 3, Indices (0)'Access, V4'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument and then V4 = (0, 0, 0, 0),
         "C4 null ND Mat");
   end Check;
end Int16_Vector_Tests.Raw_ABI;
