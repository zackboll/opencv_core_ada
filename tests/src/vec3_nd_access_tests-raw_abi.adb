with Ada.Unchecked_Conversion;
with AUnit.Assertions;
with Interfaces;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;

package body Vec3_ND_Access_Tests.Raw_ABI is

   use type Interfaces.Unsigned_16;
   use type OpenCV.Internal.C_API.C_Int32;
   use type OpenCV.Internal.C_API.Status;
   use type OpenCV.Internal.C_API.UInt8_Vec3;
   use type OpenCV.Internal.C_API.Float16_Vec3;

   function To_Mat_Handle is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        OpenCV.Internal.C_API.Mat_Handle);

   function Raw_Handle
     (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      return OpenCV.Internal.C_API.Mat_Handle
   is (To_Mat_Handle (Handle));

   procedure Rejects_Unsafe_Calls is
      Volume     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
      Same_Width : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 3, 4),
           Element_Type => (Depth => OpenCV.Core.UInt16, Channels => 3));
      Half       : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape        => (2, 2, 2),
           Element_Type => (Depth => OpenCV.Core.Float16, Channels => 3));
      Indices    : aliased OpenCV.Internal.C_API.C_Int32_Array := (0, 0, 0);
      Output     : aliased OpenCV.Internal.C_API.UInt8_Vec3 := (9, 8, 7);
      Input      : aliased constant OpenCV.Internal.C_API.UInt8_Vec3 :=
        (1, 2, 3);
      Half_Out   : aliased OpenCV.Internal.C_API.Float16_Vec3 := (others => 1);
      Half_In    : aliased constant OpenCV.Internal.C_API.Float16_Vec3 :=
        (16#0000#, 16#8000#, 16#7E01#);
      Status     : OpenCV.Internal.C_API.Status;

      procedure Probe (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw : constant OpenCV.Internal.C_API.Mat_Handle :=
           Raw_Handle (Handle);
      begin
         Status :=
           OpenCV.Internal.C_API.Mat_Get_UInt8_Vec3_ND
             (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Error_Invalid_Argument,
            "A null UInt8 Vec3 N-D output must be rejected");

         Output := (9, 8, 7);
         Status :=
           OpenCV.Internal.C_API.Mat_Get_UInt8_Vec3_ND
             (Raw, 2, Indices (0)'Access, Output'Access);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Error_Invalid_Argument
            and then Output = (0, 0, 0),
            "A dimension mismatch must zero the UInt8 Vec3 output");

         Status :=
           OpenCV.Internal.C_API.Mat_Set_UInt8_Vec3_ND
             (Raw, 3, null, Input'Access);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Error_Invalid_Argument,
            "Positive ndims with null indices must be rejected");

         Status :=
           OpenCV.Internal.C_API.Mat_Set_UInt8_Vec3_ND
             (Raw, 3, Indices (0)'Access, null);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Error_Invalid_Argument,
            "A null UInt8 Vec3 setter value must be rejected");

         Indices (0) := -1;
         Status :=
           OpenCV.Internal.C_API.Mat_Get_UInt8_Vec3_ND
             (Raw, 3, Indices (0)'Access, Output'Access);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Error_Invalid_Argument,
            "A negative raw Vec3 index must be rejected");

         Indices := (0, 3, 0);
         Status :=
           OpenCV.Internal.C_API.Mat_Get_UInt8_Vec3_ND
             (Raw, 3, Indices (0)'Access, Output'Access);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Error_Invalid_Argument,
            "A raw Vec3 index past an extent must be rejected");
         Indices := (0, 0, 0);
      end Probe;

      procedure Probe_Same_Width
        (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         Raw : constant OpenCV.Internal.C_API.Mat_Handle :=
           Raw_Handle (Handle);
      begin
         Status :=
           OpenCV.Internal.C_API.Mat_Get_Float16_Vec3_ND
             (Raw, 3, Indices (0)'Access, Half_Out'Access);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Error_Invalid_Argument
            and then Half_Out = (0, 0, 0),
            "A same-size non-Float16 Vec3 layout must be rejected");
      end Probe_Same_Width;

      procedure Probe_Float16
        (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         Raw : constant OpenCV.Internal.C_API.Mat_Handle :=
           Raw_Handle (Handle);
      begin
         Status :=
           OpenCV.Internal.C_API.Mat_Set_Float16_Vec3_ND
             (Raw, 3, Indices (0)'Access, Half_In'Access);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Success,
            "A valid Float16 Vec3 N-D raw write must succeed");
         Status :=
           OpenCV.Internal.C_API.Mat_Get_Float16_Vec3_ND
             (Raw, 3, Indices (0)'Access, Half_Out'Access);
         AUnit.Assertions.Assert
           (Status = OpenCV.Internal.C_API.Success
            and then Half_Out.Component_0 = 16#0000#
            and then Half_Out.Component_1 = 16#8000#
            and then Half_Out.Component_2 = 16#7E01#,
            "Raw Float16 Vec3 N-D access must preserve exact component bytes");
      end Probe_Float16;
   begin
      OpenCV.Core.Module_Interop.With_Input_Handle (Volume, Probe'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Same_Width, Probe_Same_Width'Access);
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Half, Probe_Float16'Access);
   end Rejects_Unsafe_Calls;

end Vec3_ND_Access_Tests.Raw_ABI;
