with Ada.Unchecked_Conversion;
with AUnit.Assertions;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;

package body UInt16_Vec3_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type C.C_Int32;
   use type C.UInt16_Vec3;
   function Convert is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        C.Mat_Handle);

   procedure Check (Test : in out Mat_Test_Support.Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Good    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt16, 3));
      Half    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float16, 3));
      Six     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt8, 6));
      Flat    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 3));
      Indexes : aliased C.C_Int32_Array (0 .. 3) := (0, 0, 0, 0);
      V       : aliased C.UInt16_Vec3 := (9, 8, 7);
      Input   : aliased constant C.UInt16_Vec3 := (0, 32768, 65535);
      S       : C.Status;
      procedure Probe (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_UInt16_Vec3_ND (Raw, 3, Indexes (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "null N-D output");
         S := C.Mat_Set_UInt16_Vec3_ND (Raw, 3, Indexes (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "null N-D input");
         S := C.Mat_Set_UInt16_Vec3_ND (Raw, 3, null, Input'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "null N-D indices");
         V := (9, 8, 7);
         S := C.Mat_Get_UInt16_Vec3_ND (Raw, 3, null, V'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then V = (0, 0, 0),
            "null N-D indices zero output");
         V := (9, 8, 7);
         S := C.Mat_Get_UInt16_Vec3_ND (Raw, 2, Indexes (0)'Access, V'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then V = (0, 0, 0),
            "wrong dimension count zeros output");
         Indexes (0) := -1;
         V := (9, 8, 7);
         S := C.Mat_Get_UInt16_Vec3_ND (Raw, 3, Indexes (0)'Access, V'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then V = (0, 0, 0),
            "negative coordinate zeros output");
         Indexes := (0, 3, 0, 0);
         S :=
           C.Mat_Set_UInt16_Vec3_ND (Raw, 3, Indexes (0)'Access, Input'Access);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "past extent");
         V := (9, 8, 7);
         S := C.Mat_Get_UInt16_Vec3_ND (Raw, 3, Indexes (0)'Access, V'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then V = (0, 0, 0),
            "past extent Get zeros output");
         Indexes := (0, 0, 0, 0);
         S :=
           C.Mat_Set_UInt16_Vec3_ND (Raw, 3, Indexes (0)'Access, Input'Access);
         AUnit.Assertions.Assert (S = C.Success, "raw N-D Set succeeds");
         V := (9, 8, 7);
         S := C.Mat_Get_UInt16_Vec3_ND (Raw, 3, Indexes (0)'Access, V'Access);
         AUnit.Assertions.Assert
           (S = C.Success and then V = Input, "raw N-D Get is exact");
      end Probe;
      procedure Wrong (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         V := (9, 8, 7);
         S := C.Mat_Get_UInt16_Vec3_ND (Raw, 3, Indexes (0)'Access, V'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then V = (0, 0, 0),
            "six-byte N-D wrong layout Get");
         S :=
           C.Mat_Set_UInt16_Vec3_ND (Raw, 3, Indexes (0)'Access, Input'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "six-byte N-D wrong layout Set");
      end Wrong;
      procedure Wrong_2D (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         V := (9, 8, 7);
         S := C.Mat_Get_UInt16_Vec3 (Raw, 0, 0, V'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then V = (0, 0, 0),
            "six-byte 2-D wrong layout Get");
         S := C.Mat_Set_UInt16_Vec3 (Raw, 0, 0, Input'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "six-byte 2-D wrong layout Set");
      end Wrong_2D;
      procedure Good_2D (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_UInt16_Vec3 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "null 2-D output");
         S := C.Mat_Set_UInt16_Vec3 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "null 2-D value");
         S := C.Mat_Set_UInt16_Vec3 (Raw, 1, 2, Input'Access);
         AUnit.Assertions.Assert (S = C.Success, "raw 2-D Set succeeds");
         S := C.Mat_Get_UInt16_Vec3 (Raw, 1, 2, V'Access);
         AUnit.Assertions.Assert
           (S = C.Success and then V = Input, "raw 2-D Get is exact");
         V := (9, 8, 7);
         S := C.Mat_Get_UInt16_Vec3 (Raw, -1, 0, V'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then V = (0, 0, 0),
            "2-D negative row zeroed");
         V := (9, 8, 7);
         S := C.Mat_Get_UInt16_Vec3 (Raw, 0, 3, V'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then V = (0, 0, 0),
            "2-D past extent zeroed");
      end Good_2D;
   begin
      OpenCV.Core.Module_Interop.With_Input_Handle (Good, Probe'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle (Half, Wrong'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle (Six, Wrong'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle (Flat, Good_2D'Access);
      declare
         Half_2D : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 3, (OpenCV.Core.Float16, 3));
         Six_2D  : constant OpenCV.Core.Mat :=
           OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 6));
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle
           (Half_2D, Wrong_2D'Access);
         OpenCV.Core.Module_Interop.With_Input_Handle
           (Six_2D, Wrong_2D'Access);
      end;
      V := (9, 8, 7);
      S := C.Mat_Get_UInt16_Vec3 (C.Null_Mat_Handle, 0, 0, V'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument and then V = (0, 0, 0),
         "null 2-D Mat zeros output");
      S := C.Mat_Set_UInt16_Vec3 (C.Null_Mat_Handle, 0, 0, Input'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument, "null 2-D Mat Set");
      V := (9, 8, 7);
      S :=
        C.Mat_Get_UInt16_Vec3_ND
          (C.Null_Mat_Handle, 3, Indexes (0)'Access, V'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument and then V = (0, 0, 0),
         "null N-D Mat zeros output");
      S :=
        C.Mat_Set_UInt16_Vec3_ND
          (C.Null_Mat_Handle, 3, Indexes (0)'Access, Input'Access);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument, "null N-D Mat Set");
   end Check;
end UInt16_Vec3_Tests.Raw_ABI;
