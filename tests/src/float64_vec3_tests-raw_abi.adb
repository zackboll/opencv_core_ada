with Ada.Strings.Fixed;
with Ada.Unchecked_Conversion;
with AUnit.Assertions;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;

package body Float64_Vec3_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type C.C_Int32;
   use type C.Float64_Vec3;
   function Convert is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        C.Mat_Handle);
   procedure Check is
      Image          : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float64, 3));
      Same_Width     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float32, 6));
      Wrong_Channels : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float64, 2));
      Two_D          : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 3));
      Same_Width_2D  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 6));
      Indices        : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
      Out_Value      : aliased C.Float64_Vec3 := (9.0, 8.0, 7.0);
      In_Value       : aliased constant C.Float64_Vec3 := (1.0, 2.0, 3.0);
      S              : C.Status;
      procedure Probe (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_Float64_Vec3_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "null output");
         S :=
           C.Mat_Get_Float64_Vec3_ND
             (Raw, 2, Indices (0)'Access, Out_Value'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out_Value = (0.0, 0.0, 0.0),
            "dimension mismatch zero-initializes output");
         S := C.Mat_Set_Float64_Vec3_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "null setter value");
         S := C.Mat_Get_Float64_Vec3_ND (Raw, 3, null, Out_Value'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "null indices");
         S :=
           C.Mat_Set_Float64_Vec3_ND
             (C.Null_Mat_Handle, 3, Indices (0)'Access, In_Value'Access);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "null Mat");
         Indices (0) := -1;
         S :=
           C.Mat_Get_Float64_Vec3_ND
             (Raw, 3, Indices (0)'Access, Out_Value'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "negative index");
         Indices (0) := 2;
         S :=
           C.Mat_Set_Float64_Vec3_ND
             (Raw, 3, Indices (0)'Access, In_Value'Access);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "past extent");
      end Probe;
      procedure Layout (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw   : constant C.Mat_Handle := Convert (H);
         Valid : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
      begin
         S :=
           C.Mat_Get_Float64_Vec3_ND
             (Raw, 3, Valid (0)'Access, Out_Value'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument
            and then Ada.Strings.Fixed.Index (C.Last_Error_Message, "Float64")
                     /= 0,
            "same-width C6 rejected for Float64 depth, not bounds");
      end Layout;
      procedure Channels (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Valid : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
      begin
         S :=
           C.Mat_Set_Float64_Vec3_ND
             (Convert (H), 3, Valid (0)'Access, In_Value'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "wrong channels");
      end Channels;
      procedure Layout_2D (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S := C.Mat_Get_Float64_Vec3 (Convert (H), 0, 0, Out_Value'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument
            and then Ada.Strings.Fixed.Index (C.Last_Error_Message, "Float64")
                     /= 0,
            "same-width C6 2-D rejected for Float64 depth, not bounds");
      end Layout_2D;
      procedure Two_D_Probe (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_Float64_Vec3 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "2-D null output");
         S := C.Mat_Set_Float64_Vec3 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "2-D null value");
         S := C.Mat_Get_Float64_Vec3 (Raw, -1, 0, Out_Value'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then Out_Value = (0.0, 0.0, 0.0),
            "negative row");
         S := C.Mat_Set_Float64_Vec3 (Raw, 0, -1, In_Value'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "negative column");
         S := C.Mat_Get_Float64_Vec3 (Raw, 2, 0, Out_Value'Access);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "past row");
         S := C.Mat_Set_Float64_Vec3 (Raw, 0, 3, In_Value'Access);
         AUnit.Assertions.Assert (S = C.Error_Invalid_Argument, "past column");
         S :=
           C.Mat_Get_Float64_Vec3 (C.Null_Mat_Handle, 0, 0, Out_Value'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "2-D null Mat");
      end Two_D_Probe;
   begin
      OpenCV.Core.Module_Interop.With_Input_Handle (Image, Probe'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle (Same_Width, Layout'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Wrong_Channels, Channels'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Same_Width_2D, Layout_2D'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle (Two_D, Two_D_Probe'Access);
   end Check;
end Float64_Vec3_Tests.Raw_ABI;
