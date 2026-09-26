with Ada.Unchecked_Conversion;
with Ada.Strings.Fixed;
with AUnit.Assertions;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;

package body Vec2_Access_Tests.Raw_ABI is
   use type OpenCV.Internal.C_API.Status;
   use type OpenCV.Internal.C_API.C_Float32;
   use type OpenCV.Internal.C_API.C_Float64;
   use type OpenCV.Internal.C_API.C_Int32;
   package C renames OpenCV.Internal.C_API;
   function Raw_Handle is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        C.Mat_Handle);
   procedure Check is
      Image             : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float32, 2));
      Same_Width        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float64, 1));
      Double_Image      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 2));
      Double_Same_Width : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 4));
      Wrong_Channels32  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Wrong_Channels64  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 1));
      Idx               : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
      Out32             : aliased C.Float32_Vec2 := (9.0, 8.0);
      In32              : aliased constant C.Float32_Vec2 := (1.0, 2.0);
      Out64             : aliased C.Float64_Vec2 := (9.0, 8.0);
      In64              : aliased constant C.Float64_Vec2 := (1.0, 2.0);
      S                 : C.Status;
      procedure Probe (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Raw_Handle (H);
      begin
         S := C.Mat_Get_Float32_Vec2_ND (Raw, 3, Idx (0)'Access, null);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "null output");
         S := C.Mat_Get_Float32_Vec2_ND (Raw, 2, Idx (0)'Access, Out32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument
            and then Out32.Component_0 = 0.0
            and then Out32.Component_1 = 0.0,
            "dimension mismatch zeroes output");
         S := C.Mat_Get_Float32_Vec2_ND (Raw, 3, null, Out32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "null indices");
         S := C.Mat_Set_Float32_Vec2_ND (Raw, 3, Idx (0)'Access, null);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "null value");
         S :=
           C.Mat_Set_Float32_Vec2_ND
             (C.Null_Mat_Handle, 3, Idx (0)'Access, In32'Access);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "null Mat");
         Idx (0) := -1;
         S := C.Mat_Get_Float32_Vec2_ND (Raw, 3, Idx (0)'Access, Out32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "negative index");
         Idx (0) := 2;
         S := C.Mat_Get_Float32_Vec2_ND (Raw, 3, Idx (0)'Access, Out32'Access);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "past extent");
      end Probe;
      procedure Wrong32 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Valid_Indices : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
      begin
         S :=
           C.Mat_Get_Float32_Vec2_ND
             (Raw_Handle (H), 3, Valid_Indices (0)'Access, Out32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument
            and then Ada.Strings.Fixed.Index
                       (C.Last_Error_Message, "Mat depth must be Float32")
                     /= 0,
            "same-width layout must fail for Float32 depth, not bounds");
      end Wrong32;
      procedure Probe64 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Raw_Handle (H);
      begin
         S := C.Mat_Get_Float64_Vec2 (Raw, -1, 0, Out64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out64.Component_0 = 0.0,
            "negative row zeroes output");
         S := C.Mat_Set_Float64_Vec2 (Raw, 0, 3, In64'Access);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "past column");
         S := C.Mat_Set_Float64_Vec2 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "null double value");
      end Probe64;
      procedure Wrong_32_Channel
        (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S := C.Mat_Get_Float32_Vec2 (Raw_Handle (H), 0, 0, Out32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float32 C1 rejects Vec2 read");
      end Wrong_32_Channel;
      procedure Wrong_64_Channel
        (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S := C.Mat_Get_Float64_Vec2 (Raw_Handle (H), 0, 0, Out64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float64 C1 rejects Vec2 read");
      end Wrong_64_Channel;
      procedure Wrong64 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S := C.Mat_Get_Float64_Vec2 (Raw_Handle (H), 0, 0, Out64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument,
            "same-size Float32 C4 must not be read as Float64 C2");
      end Wrong64;
   begin
      OpenCV.Core.Module_Interop.With_Input_Handle (Image, Probe'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Same_Width, Wrong32'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Double_Image, Probe64'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Double_Same_Width, Wrong64'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Wrong_Channels32, Wrong_32_Channel'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Wrong_Channels64, Wrong_64_Channel'Access);
   end Check;
end Vec2_Access_Tests.Raw_ABI;
