with Ada.Strings.Fixed;
with Ada.Unchecked_Conversion;
with AUnit.Assertions;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;

package body Vec4_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type C.C_Int32;
   use type C.Float32_Vec4;
   use type C.Float64_Vec4;
   function Convert is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        C.Mat_Handle);

   procedure Check is
      Indices    : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
      F32        : aliased C.Float32_Vec4 := (9.0, 8.0, 7.0, 6.0);
      F64        : aliased C.Float64_Vec4 := (9.0, 8.0, 7.0, 6.0);
      V32        : aliased constant C.Float32_Vec4 := (1.0, 2.0, 3.0, 4.0);
      V64        : aliased constant C.Float64_Vec4 := (1.0, 2.0, 3.0, 4.0);
      S          : C.Status;
      D32        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float32, 4));
      D64        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float64, 4));
      W32        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float64, 2));
      W64        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float32, 8));
      Two32      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 4));
      Two64      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 4));
      Wrong32    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 2));
      Wrong64    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 8));
      Channels32 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 2));
      Channels64 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 2));
      procedure Probe32 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_Float32_Vec4_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float32 null output");
         S := C.Mat_Set_Float32_Vec4_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float32 null value");
         S :=
           C.Mat_Get_Float32_Vec4_ND
             (C.Null_Mat_Handle, 3, Indices (0)'Access, F32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then F32 = (0.0, 0.0, 0.0, 0.0),
            "Float32 null Mat zero output");
         S := C.Mat_Get_Float32_Vec4_ND (Raw, 3, null, F32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float32 null indices");
         S :=
           C.Mat_Get_Float32_Vec4_ND (Raw, 2, Indices (0)'Access, F32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float32 dimension mismatch");
         Indices (0) := -1;
         S :=
           C.Mat_Get_Float32_Vec4_ND (Raw, 3, Indices (0)'Access, F32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float32 negative index");
         Indices (0) := 2;
         S :=
           C.Mat_Set_Float32_Vec4_ND (Raw, 3, Indices (0)'Access, V32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float32 past extent");
      end Probe32;
      procedure Probe64 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_Float64_Vec4_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float64 null output");
         S := C.Mat_Set_Float64_Vec4_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float64 null value");
         S :=
           C.Mat_Get_Float64_Vec4_ND
             (C.Null_Mat_Handle, 3, Indices (0)'Access, F64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then F64 = (0.0, 0.0, 0.0, 0.0),
            "Float64 null Mat zero output");
         S := C.Mat_Get_Float64_Vec4_ND (Raw, 3, null, F64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float64 null indices");
         S :=
           C.Mat_Get_Float64_Vec4_ND (Raw, 2, Indices (0)'Access, F64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float64 dimension mismatch");
         Indices (0) := -1;
         S :=
           C.Mat_Get_Float64_Vec4_ND (Raw, 3, Indices (0)'Access, F64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float64 negative index");
         Indices (0) := 2;
         S :=
           C.Mat_Set_Float64_Vec4_ND (Raw, 3, Indices (0)'Access, V64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float64 past extent");
      end Probe64;
      procedure Layout32 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Valid : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
      begin
         S :=
           C.Mat_Get_Float32_Vec4_ND
             (Convert (H), 3, Valid (0)'Access, F32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument
            and then Ada.Strings.Fixed.Index (C.Last_Error_Message, "Float32")
                     /= 0,
            "equal-size Float64 C2 must not be Float32 C4");
      end Layout32;
      procedure Layout64 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Valid : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
      begin
         S :=
           C.Mat_Get_Float64_Vec4_ND
             (Convert (H), 3, Valid (0)'Access, F64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument
            and then Ada.Strings.Fixed.Index (C.Last_Error_Message, "Float64")
                     /= 0,
            "equal-size Float32 C8 must not be Float64 C4");
      end Layout64;
      procedure Two_D32 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_Float32_Vec4 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "2D Float32 null out");
         S := C.Mat_Set_Float32_Vec4 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "2D Float32 null value");
         S := C.Mat_Get_Float32_Vec4 (Raw, -1, 0, F32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then F32 = (0.0, 0.0, 0.0, 0.0),
            "2D Float32 negative zero out");
         S := C.Mat_Set_Float32_Vec4 (Raw, 0, 3, V32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "2D Float32 past column");
      end Two_D32;
      procedure Two_D64 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_Float64_Vec4 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "2D Float64 null out");
         S := C.Mat_Set_Float64_Vec4 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "2D Float64 null value");
         S := C.Mat_Get_Float64_Vec4 (Raw, -1, 0, F64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then F64 = (0.0, 0.0, 0.0, 0.0),
            "2D Float64 negative zero out");
         S := C.Mat_Set_Float64_Vec4 (Raw, 0, 3, V64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "2D Float64 past column");
      end Two_D64;
      procedure Wrong_2D32 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S := C.Mat_Get_Float32_Vec4 (Convert (H), 0, 0, F32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument
            and then Ada.Strings.Fixed.Index (C.Last_Error_Message, "Float32")
                     /= 0,
            "2D equal-size Float64 C2 rejected");
      end Wrong_2D32;
      procedure Wrong_2D64 (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S := C.Mat_Get_Float64_Vec4 (Convert (H), 0, 0, F64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument
            and then Ada.Strings.Fixed.Index (C.Last_Error_Message, "Float64")
                     /= 0,
            "2D equal-size Float32 C8 rejected");
      end Wrong_2D64;
      procedure Wrong_Channels32
        (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S := C.Mat_Set_Float32_Vec4 (Convert (H), 0, 0, V32'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float32 wrong channels");
      end Wrong_Channels32;
      procedure Wrong_Channels64
        (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S := C.Mat_Set_Float64_Vec4 (Convert (H), 0, 0, V64'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "Float64 wrong channels");
      end Wrong_Channels64;
   begin
      OpenCV.Core.Module_Interop.With_Input_Handle (D32, Probe32'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle (D64, Probe64'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle (W32, Layout32'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle (W64, Layout64'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle (Two32, Two_D32'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle (Two64, Two_D64'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Wrong32, Wrong_2D32'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Wrong64, Wrong_2D64'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Channels32, Wrong_Channels32'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Channels64, Wrong_Channels64'Access);
   end Check;
end Vec4_Tests.Raw_ABI;
