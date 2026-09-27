with Ada.Unchecked_Conversion;
with AUnit.Assertions;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;

package body Unsigned_Vec2_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type C.UInt8_Vec2;
   use type C.UInt16_Vec2;
   use type C.C_Int32;
   function Convert is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        C.Mat_Handle);

   procedure Check is
      Indexes : aliased C.C_Int32_Array (0 .. 2) := (1, 2, 3);
      Out8    : aliased C.UInt8_Vec2 := (9, 9);
      Out16   : aliased C.UInt16_Vec2 := (9, 9);
      In8     : aliased constant C.UInt8_Vec2 := (0, 255);
      In16    : aliased constant C.UInt16_Vec2 := (0, 65535);
      S       : C.Status;
      procedure Probe8 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_UInt8_Vec2 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 null output");
         S := C.Mat_Set_UInt8_Vec2 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 null value");
         S := C.Mat_Get_UInt8_Vec2 (C.Null_Mat_Handle, 0, 0, Out8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out8 = (0, 0),
            "UInt8 null Mat zeros output");
         S := C.Mat_Set_UInt8_Vec2 (Raw, 1, 2, In8'Access);
         AUnit.Assertions.Assert (S = C.Success, "UInt8 exact 2-D Set");
         S := C.Mat_Get_UInt8_Vec2 (Raw, 1, 2, Out8'Access);
         AUnit.Assertions.Assert
           (S = C.Success and then Out8 = In8, "UInt8 exact 2-D round trip");
      end Probe8;
      procedure Probe16 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_UInt16_Vec2 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 null output");
         S := C.Mat_Set_UInt16_Vec2 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 null value");
         S := C.Mat_Get_UInt16_Vec2 (C.Null_Mat_Handle, 0, 0, Out16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out16 = (0, 0),
            "UInt16 null Mat zeros output");
         S := C.Mat_Set_UInt16_Vec2 (Raw, 1, 2, In16'Access);
         AUnit.Assertions.Assert (S = C.Success, "UInt16 exact 2-D Set");
         S := C.Mat_Get_UInt16_Vec2 (Raw, 1, 2, Out16'Access);
         AUnit.Assertions.Assert
           (S = C.Success and then Out16 = In16,
            "UInt16 exact 2-D round trip");
      end Probe16;
      procedure Probe8_ND (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_UInt8_Vec2_ND (Raw, 3, Indexes (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 null ND output");
         S := C.Mat_Set_UInt8_Vec2_ND (Raw, 3, Indexes (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 null ND value");
         S := C.Mat_Get_UInt8_Vec2_ND (Raw, 3, null, Out8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out8 = (0, 0),
            "UInt8 null indices");
         S :=
           C.Mat_Get_UInt8_Vec2_ND (Raw, 2, Indexes (0)'Access, Out8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out8 = (0, 0),
            "UInt8 wrong dimension count");
         Indexes (0) := -1;
         S :=
           C.Mat_Get_UInt8_Vec2_ND (Raw, 3, Indexes (0)'Access, Out8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out8 = (0, 0),
            "UInt8 negative coordinate");
         S := C.Mat_Set_UInt8_Vec2_ND (Raw, 3, Indexes (0)'Access, In8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 negative Set");
         Indexes (0) := 2;
         S :=
           C.Mat_Get_UInt8_Vec2_ND (Raw, 3, Indexes (0)'Access, Out8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out8 = (0, 0),
            "UInt8 past extent");
         S := C.Mat_Set_UInt8_Vec2_ND (Raw, 3, Indexes (0)'Access, In8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 past Set");
         Indexes (0) := 1;
         S := C.Mat_Set_UInt8_Vec2_ND (Raw, 3, Indexes (0)'Access, In8'Access);
         AUnit.Assertions.Assert (S = C.Success, "UInt8 ND Set");
         S :=
           C.Mat_Get_UInt8_Vec2_ND (Raw, 3, Indexes (0)'Access, Out8'Access);
         AUnit.Assertions.Assert
           (S = C.Success and then Out8 = In8, "UInt8 ND round trip");
      end Probe8_ND;
      procedure Probe16_ND (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_UInt16_Vec2_ND (Raw, 3, Indexes (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 null ND output");
         S := C.Mat_Set_UInt16_Vec2_ND (Raw, 3, Indexes (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 null ND value");
         S := C.Mat_Get_UInt16_Vec2_ND (Raw, 3, null, Out16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out16 = (0, 0),
            "UInt16 null indices");
         S :=
           C.Mat_Get_UInt16_Vec2_ND (Raw, 2, Indexes (0)'Access, Out16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out16 = (0, 0),
            "UInt16 wrong dimension count");
         Indexes (0) := -1;
         S :=
           C.Mat_Get_UInt16_Vec2_ND (Raw, 3, Indexes (0)'Access, Out16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out16 = (0, 0),
            "UInt16 negative coordinate");
         S :=
           C.Mat_Set_UInt16_Vec2_ND (Raw, 3, Indexes (0)'Access, In16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 negative Set");
         Indexes (0) := 2;
         S :=
           C.Mat_Get_UInt16_Vec2_ND (Raw, 3, Indexes (0)'Access, Out16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out16 = (0, 0),
            "UInt16 past extent");
         S :=
           C.Mat_Set_UInt16_Vec2_ND (Raw, 3, Indexes (0)'Access, In16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 past Set");
         Indexes (0) := 1;
         S :=
           C.Mat_Set_UInt16_Vec2_ND (Raw, 3, Indexes (0)'Access, In16'Access);
         AUnit.Assertions.Assert (S = C.Success, "UInt16 ND Set");
         S :=
           C.Mat_Get_UInt16_Vec2_ND (Raw, 3, Indexes (0)'Access, Out16'Access);
         AUnit.Assertions.Assert
           (S = C.Success and then Out16 = In16, "UInt16 ND round trip");
      end Probe16_ND;
      procedure Wrong8 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         Out8 := (9, 9);
         S := C.Mat_Get_UInt8_Vec2 (Raw, 0, 0, Out8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out8 = (0, 0),
            "UInt8 same-byte wrong Get");
         S := C.Mat_Set_UInt8_Vec2 (Raw, 0, 0, In8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 same-byte wrong Set");
      end Wrong8;
      procedure Wrong8_ND (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         Out8 := (9, 9);
         S :=
           C.Mat_Get_UInt8_Vec2_ND (Raw, 3, Indexes (0)'Access, Out8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out8 = (0, 0),
            "UInt8 ND wrong Get");
         S := C.Mat_Set_UInt8_Vec2_ND (Raw, 3, Indexes (0)'Access, In8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 ND wrong Set");
      end Wrong8_ND;
      procedure Wrong16 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         Out16 := (9, 9);
         S := C.Mat_Get_UInt16_Vec2 (Raw, 0, 0, Out16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out16 = (0, 0),
            "UInt16 same-byte wrong Get");
         S := C.Mat_Set_UInt16_Vec2 (Raw, 0, 0, In16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 same-byte wrong Set");
      end Wrong16;
      procedure Wrong16_ND (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         Out16 := (9, 9);
         S :=
           C.Mat_Get_UInt16_Vec2_ND (Raw, 3, Indexes (0)'Access, Out16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out16 = (0, 0),
            "UInt16 ND wrong Get");
         S :=
           C.Mat_Set_UInt16_Vec2_ND (Raw, 3, Indexes (0)'Access, In16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 ND wrong Set");
      end Wrong16_ND;
      procedure Check_Wrong
        (Depth    : OpenCV.Core.Depth_Type;
         Channels : OpenCV.Core.Channel_Count;
         Is_UInt8 : Boolean)
      is
         Wrong    : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (1, 1, (Depth, Channels));
         Wrong_ND : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Shape => (2, 3, 4), Element_Type => (Depth, Channels));
      begin
         if Is_UInt8 then
            OpenCV.Core.Module_Interop.With_Input_Handle
              (Wrong, Wrong8'Access);
            OpenCV.Core.Module_Interop.With_Input_Handle
              (Wrong_ND, Wrong8_ND'Access);
         else
            OpenCV.Core.Module_Interop.With_Input_Handle
              (Wrong, Wrong16'Access);
            OpenCV.Core.Module_Interop.With_Input_Handle
              (Wrong_ND, Wrong16_ND'Access);
         end if;
      end Check_Wrong;
   begin
      declare
         Image  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 2));
         Volume : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt8, 2));
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle (Image, Probe8'Access);
         OpenCV.Core.Module_Interop.With_Input_Handle
           (Volume, Probe8_ND'Access);
      end;
      declare
         Image  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 2));
         Volume : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create
             (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt16, 2));
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle (Image, Probe16'Access);
         OpenCV.Core.Module_Interop.With_Input_Handle
           (Volume, Probe16_ND'Access);
      end;
      Check_Wrong (OpenCV.Core.UInt16, 1, True);
      Check_Wrong (OpenCV.Core.Int8, 2, True);
      Check_Wrong (OpenCV.Core.Float32, 1, False);
      Check_Wrong (OpenCV.Core.UInt8, 4, False);
      Check_Wrong (OpenCV.Core.Float16, 2, False);
   end Check;
end Unsigned_Vec2_Tests.Raw_ABI;
