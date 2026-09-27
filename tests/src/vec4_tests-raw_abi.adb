with Ada.Strings.Fixed;
with Ada.Unchecked_Conversion;
with AUnit.Assertions;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;
with System;

package body Vec4_Tests.Raw_ABI is
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type C.C_Int32;
   use type C.Float32_Vec4;
   use type C.UInt8_Vec4;
   use type C.UInt16_Vec4;
   use type C.Float64_Vec4;
   function Convert is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        C.Mat_Handle);

   procedure Check is
      Indices               : aliased C.C_Int32_Array (0 .. 2) := (0, 0, 0);
      F32                   : aliased C.Float32_Vec4 := (9.0, 8.0, 7.0, 6.0);
      F64                   : aliased C.Float64_Vec4 := (9.0, 8.0, 7.0, 6.0);
      V32                   : aliased constant C.Float32_Vec4 :=
        (1.0, 2.0, 3.0, 4.0);
      V64                   : aliased constant C.Float64_Vec4 :=
        (1.0, 2.0, 3.0, 4.0);
      S                     : C.Status;
      D32                   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float32, 4));
      D64                   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float64, 4));
      W32                   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float64, 2));
      W64                   : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float32, 8));
      Two32                 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 4));
      Two64                 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 4));
      Wrong32               : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 2));
      Wrong64               : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 8));
      Channels32            : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 2));
      Channels64            : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 2));
      U8                    : aliased C.UInt8_Vec4 := (9, 8, 7, 6);
      V8                    : aliased constant C.UInt8_Vec4 :=
        (10, 20, 30, 255);
      U8_2D                 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 4));
      U8_ND                 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt8, 4));
      Equal_F32             : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Equal_U16             : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt16, 2));
      Wrong_U8_Channels     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 3));
      Wrong_U8_ND_Channels  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt8, 3));
      Wrong_U8_Depth        : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 4));
      U16                   : aliased C.UInt16_Vec4 := (9, 8, 7, 6);
      V16                   : aliased constant C.UInt16_Vec4 :=
        (0, 1, 32768, 65535);
      U16_2D                : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 4));
      U16_ND                : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt16, 4));
      Equal_F64             : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float64, 1));
      Equal_F32_ND          : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float32, 2));
      Wrong_U16_Channels    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt16, 3));
      Wrong_U16_ND_Channels : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt16, 3));
      procedure Probe_U16_2D (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_UInt16_Vec4 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 2D null output");
         S := C.Mat_Set_UInt16_Vec4 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 2D null value");
         U16 := (9, 8, 7, 6);
         S := C.Mat_Get_UInt16_Vec4 (C.Null_Mat_Handle, 0, 0, U16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U16 = (0, 0, 0, 0),
            "UInt16 2D null Mat zeroes output");
         U16 := (9, 8, 7, 6);
         S := C.Mat_Get_UInt16_Vec4 (Raw, -1, 0, U16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U16 = (0, 0, 0, 0),
            "UInt16 negative row zeroes output");
         S := C.Mat_Set_UInt16_Vec4 (Raw, 0, 3, V16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 2D past column");
         S := C.Mat_Read_UInt16_Vec4_Row (Raw, 0, System.Null_Address, 3);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 row null buffer");
         S := C.Mat_Read_UInt16_Vec4_Row (Raw, 0, U16'Address, 2);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 row wrong count");
         S := C.Mat_Read_UInt16_Vec4_Row (Raw, 2, U16'Address, 3);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 row past extent");
      end Probe_U16_2D;
      procedure Probe_U16_ND (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_UInt16_Vec4_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 ND null output");
         S := C.Mat_Set_UInt16_Vec4_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 ND null value");
         U16 := (9, 8, 7, 6);
         S :=
           C.Mat_Get_UInt16_Vec4_ND
             (C.Null_Mat_Handle, 3, Indices (0)'Access, U16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U16 = (0, 0, 0, 0),
            "UInt16 ND null Mat zeroes output");
         S := C.Mat_Get_UInt16_Vec4_ND (Raw, 3, null, U16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 ND null indices");
         S :=
           C.Mat_Get_UInt16_Vec4_ND (Raw, 2, Indices (0)'Access, U16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 ND dimension mismatch");
         Indices (0) := -1;
         U16 := (9, 8, 7, 6);
         S :=
           C.Mat_Get_UInt16_Vec4_ND (Raw, 3, Indices (0)'Access, U16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U16 = (0, 0, 0, 0),
            "UInt16 ND negative index zeroes output");
         Indices (0) := 2;
         S :=
           C.Mat_Set_UInt16_Vec4_ND (Raw, 3, Indices (0)'Access, V16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 ND past extent");
         Indices (0) := 0;
      end Probe_U16_ND;
      procedure Wrong_U16_2D (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
      begin
         U16 := (9, 8, 7, 6);
         S := C.Mat_Get_UInt16_Vec4 (Convert (H), 0, 0, U16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U16 = (0, 0, 0, 0),
            "same-byte Float64 C1 rejected before UInt16 read");
         S := C.Mat_Set_UInt16_Vec4 (Convert (H), 0, 0, V16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument,
            "same-byte Float64 C1 write rejected");
         S := C.Mat_Read_UInt16_Vec4_Row (Convert (H), 0, U16'Address, 3);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 row wrong depth");
      end Wrong_U16_2D;
      procedure Wrong_U16_ND (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
      begin
         U16 := (9, 8, 7, 6);
         S :=
           C.Mat_Get_UInt16_Vec4_ND
             (Convert (H), 3, Indices (0)'Access, U16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U16 = (0, 0, 0, 0),
            "same-byte Float32 C2 rejected before UInt16 ND read");
         S :=
           C.Mat_Set_UInt16_Vec4_ND
             (Convert (H), 3, Indices (0)'Access, V16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument,
            "same-byte Float32 C2 ND write rejected");
      end Wrong_U16_ND;
      procedure Check_U16_Channels
        (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S := C.Mat_Set_UInt16_Vec4 (Convert (H), 0, 0, V16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 2D wrong channels");
         S := C.Mat_Read_UInt16_Vec4_Row (Convert (H), 0, U16'Address, 3);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 row wrong channels");
      end Check_U16_Channels;
      procedure Check_U16_ND_Channels
        (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S :=
           C.Mat_Set_UInt16_Vec4_ND
             (Convert (H), 3, Indices (0)'Access, V16'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt16 ND wrong channels");
      end Check_U16_ND_Channels;
      procedure Probe_U8_2D (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_UInt8_Vec4 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 2D null out");
         S := C.Mat_Set_UInt8_Vec4 (Raw, 0, 0, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 2D null value");
         S := C.Mat_Get_UInt8_Vec4 (C.Null_Mat_Handle, 0, 0, U8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U8 = (0, 0, 0, 0),
            "UInt8 2D null Mat zeros output");
         U8 := (9, 8, 7, 6);
         S := C.Mat_Get_UInt8_Vec4 (Raw, -1, 0, U8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U8 = (0, 0, 0, 0),
            "UInt8 2D negative row zeros output");
         S := C.Mat_Set_UInt8_Vec4 (Raw, 0, 3, V8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 2D past column");
         S := C.Mat_Read_UInt8_Vec4_Row (Raw, 0, System.Null_Address, 3);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 row null buffer");
         S := C.Mat_Read_UInt8_Vec4_Row (Raw, 0, U8'Address, 2);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 row wrong count");
         S := C.Mat_Read_UInt8_Vec4_Row (Raw, 2, U8'Address, 3);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 row past extent");
      end Probe_U8_2D;
      procedure Probe_U8_ND (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         Raw : constant C.Mat_Handle := Convert (H);
      begin
         S := C.Mat_Get_UInt8_Vec4_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 ND null out");
         S := C.Mat_Set_UInt8_Vec4_ND (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 ND null value");
         U8 := (9, 8, 7, 6);
         S :=
           C.Mat_Get_UInt8_Vec4_ND
             (C.Null_Mat_Handle, 3, Indices (0)'Access, U8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U8 = (0, 0, 0, 0),
            "UInt8 ND null Mat zeros output");
         S := C.Mat_Get_UInt8_Vec4_ND (Raw, 3, null, U8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 ND null indices");
         S := C.Mat_Get_UInt8_Vec4_ND (Raw, 2, Indices (0)'Access, U8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 ND wrong dimensions");
         Indices (0) := -1;
         S := C.Mat_Get_UInt8_Vec4_ND (Raw, 3, Indices (0)'Access, U8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U8 = (0, 0, 0, 0),
            "UInt8 ND negative index zeros output");
         Indices (0) := 2;
         S := C.Mat_Set_UInt8_Vec4_ND (Raw, 3, Indices (0)'Access, V8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 ND past extent");
         Indices (0) := 0;
      end Probe_U8_ND;
      procedure Wrong_U8_2D (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
      begin
         U8 := (9, 8, 7, 6);
         S := C.Mat_Get_UInt8_Vec4 (Convert (H), 0, 0, U8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U8 = (0, 0, 0, 0),
            "equal-byte Float32 C1 rejected before UInt8 dereference");
         S := C.Mat_Set_UInt8_Vec4 (Convert (H), 0, 0, V8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument,
            "equal-byte Float32 C1 write rejected");
      end Wrong_U8_2D;
      procedure Wrong_U8_ND (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
      begin
         U8 := (9, 8, 7, 6);
         S :=
           C.Mat_Get_UInt8_Vec4_ND
             (Convert (H), 3, Indices (0)'Access, U8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument and then U8 = (0, 0, 0, 0),
            "equal-byte UInt16 C2 rejected before UInt8 ND dereference");
         S :=
           C.Mat_Set_UInt8_Vec4_ND
             (Convert (H), 3, Indices (0)'Access, V8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument,
            "equal-byte UInt16 C2 ND write rejected");
      end Wrong_U8_ND;
      procedure Wrong_U8_Row (H : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
      begin
         S := C.Mat_Read_UInt8_Vec4_Row (Convert (H), 0, U8'Address, 3);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 row wrong channels");
         S := C.Mat_Set_UInt8_Vec4 (Convert (H), 0, 0, V8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 2D wrong channels");
      end Wrong_U8_Row;
      procedure Wrong_U8_ND_Channel
        (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S :=
           C.Mat_Set_UInt8_Vec4_ND
             (Convert (H), 3, Indices (0)'Access, V8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 ND wrong channels");
      end Wrong_U8_ND_Channel;
      procedure Wrong_U8_Depth_Check
        (H : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         S := C.Mat_Read_UInt8_Vec4_Row (Convert (H), 0, U8'Address, 3);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 row wrong depth");
         S := C.Mat_Set_UInt8_Vec4 (Convert (H), 0, 0, V8'Access);
         AUnit.Assertions.Assert
           (S = C.Error_Invalid_Argument, "UInt8 2D wrong depth");
      end Wrong_U8_Depth_Check;
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
      OpenCV.Core.Module_Interop.With_Input_Handle
        (U16_2D, Probe_U16_2D'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (U16_ND, Probe_U16_ND'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Equal_F64, Wrong_U16_2D'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Equal_F32_ND, Wrong_U16_ND'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Wrong_U16_Channels, Check_U16_Channels'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Wrong_U16_ND_Channels, Check_U16_ND_Channels'Access);
      S := C.Mat_Read_UInt8_Vec4_Row (C.Null_Mat_Handle, 0, U8'Address, 3);
      AUnit.Assertions.Assert
        (S = C.Error_Invalid_Argument, "UInt8 row null Mat");
      OpenCV.Core.Module_Interop.With_Input_Handle (U8_2D, Probe_U8_2D'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle (U8_ND, Probe_U8_ND'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Equal_F32, Wrong_U8_2D'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Equal_U16, Wrong_U8_ND'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Wrong_U8_Channels, Wrong_U8_Row'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Wrong_U8_ND_Channels, Wrong_U8_ND_Channel'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Wrong_U8_Depth, Wrong_U8_Depth_Check'Access);
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
