with Ada.Unchecked_Conversion;
with AUnit.Assertions;
with OpenCV.Core;
with OpenCV.Core.Module_Interop;
with OpenCV.Internal.C_API;
with System;
with System.Storage_Elements;

package body ND_Buffer_Access_Tests.Raw_ABI is

   package C renames OpenCV.Internal.C_API;

   use type C.Status;
   use type C.C_UInt64;
   use type System.Address;
   use type OpenCV.Core.Mat_Size;

   function Raw_Handle is new
     Ada.Unchecked_Conversion
       (OpenCV.Core.Module_Interop.Input_Mat_Handle,
        C.Mat_Handle);

   --  A non-null address used to prove that outputs are cleared.
   Sentinel : aliased constant Integer := 0;

   type Borrow_Result is record
      Status  : C.Status;
      Address : System.Address;
      Bytes   : C.C_UInt64;
   end record;

   function Borrow (Handle : C.Mat_Handle) return Borrow_Result is
      Address : aliased System.Address := Sentinel'Address;
      Bytes   : aliased C.C_UInt64 := 16#DEAD#;
      Status  : constant C.Status :=
        C.Mat_Borrow_Contiguous_Data (Handle, Address'Access, Bytes'Access);
   begin
      return (Status => Status, Address => Address, Bytes => Bytes);
   end Borrow;

   function Borrow (Image : OpenCV.Core.Mat) return Borrow_Result is
      Result : Borrow_Result;

      procedure Probe (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
      begin
         Result := Borrow (Raw_Handle (Handle));
      end Probe;
   begin
      OpenCV.Core.Module_Interop.With_Input_Handle (Image, Probe'Access);
      return Result;
   end Borrow;

   procedure Assert_Rejected (Result : Borrow_Result; Message : String) is
   begin
      AUnit.Assertions.Assert
        (Result.Status = C.Error_Invalid_Argument
         and then Result.Address = System.Null_Address
         and then Result.Bytes = 0
         and then C.Last_Error_Message'Length > 0,
         Message & " must be rejected with null / zero outputs");
   end Assert_Rejected;

   procedure Assert_Empty (Result : Borrow_Result; Message : String) is
   begin
      AUnit.Assertions.Assert
        (Result.Status = C.Success
         and then Result.Address = System.Null_Address
         and then Result.Bytes = 0,
         Message & " must succeed with a null address and zero bytes");
   end Assert_Empty;

   function Logical_Bytes (Image : OpenCV.Core.Mat) return C.C_UInt64
   is (C.C_UInt64 (Image.Total * Image.Element_Size));

   procedure Check_Null_Arguments is
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));

      procedure Probe (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle) is
         Raw     : constant C.Mat_Handle := Raw_Handle (Handle);
         Address : aliased System.Address := Sentinel'Address;
         Bytes   : aliased C.C_UInt64 := 16#DEAD#;
         Status  : C.Status;
      begin
         Status := C.Mat_Borrow_Contiguous_Data (Raw, null, Bytes'Access);
         AUnit.Assertions.Assert
           (Status = C.Error_Invalid_Argument and then Bytes = 0,
            "null out_data must be rejected and clear out_byte_count");

         Status := C.Mat_Borrow_Contiguous_Data (Raw, Address'Access, null);
         AUnit.Assertions.Assert
           (Status = C.Error_Invalid_Argument
            and then Address = System.Null_Address,
            "null out_byte_count must be rejected and clear out_data");
      end Probe;
   begin
      Assert_Rejected (Borrow (C.Null_Mat_Handle), "A null Mat handle");
      OpenCV.Core.Module_Interop.With_Input_Handle (Image, Probe'Access);
   end Check_Null_Arguments;

   procedure Check_Two_Dimensional is
      Image  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Parent : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 4, (OpenCV.Core.UInt8, 1));
      Window : constant OpenCV.Core.Mat :=
        Parent.Region ((X => 1, Y => 0, Width => 2, Height => 2));
      Result : constant Borrow_Result := Borrow (Image);
      Row_0  : aliased System.Address := System.Null_Address;

      procedure Borrow_First_Row
        (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         Bytes  : aliased C.C_UInt64 := 0;
         Status : constant C.Status :=
           C.Mat_Borrow_Row_Data
             (Raw_Handle (Handle), 0, Row_0'Access, Bytes'Access);
      begin
         AUnit.Assertions.Assert
           (Status = C.Success, "2-D row borrow must still succeed");
      end Borrow_First_Row;
   begin
      OpenCV.Core.Module_Interop.With_Input_Handle
        (Image, Borrow_First_Row'Access);
      AUnit.Assertions.Assert
        (Result.Status = C.Success
         and then Result.Bytes = 24
         and then Result.Bytes = Logical_Bytes (Image)
         and then Result.Address /= System.Null_Address
         and then Result.Address = Row_0,
         "A continuous 2-D Mat must report Total * Element_Size bytes"
         & " starting at its data pointer");

      AUnit.Assertions.Assert
        (not Window.Is_Continuous,
         "The 2-D Region fixture must be non-continuous");
      Assert_Rejected (Borrow (Window), "A non-contiguous 2-D Region");
   end Check_Two_Dimensional;

   procedure Check_N_Dimensional is
      Volume : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.Float64, 4));
      Bytes3 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Shape => (2, 3, 4), Element_Type => (OpenCV.Core.UInt8, 1));
      Packed : constant OpenCV.Core.Mat :=
        Bytes3.Slice (((1, 2), (0, 3), (0, 4)));
      Gapped : constant OpenCV.Core.Mat :=
        Bytes3.Slice (((0, 2), (1, 2), (0, 4)));
      Result : constant Borrow_Result := Borrow (Volume);
      Whole  : constant Borrow_Result := Borrow (Bytes3);
      Tail   : constant Borrow_Result := Borrow (Packed);

      procedure Row_API_Stays_Two_Dimensional
        (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle)
      is
         Address : aliased System.Address := Sentinel'Address;
         Bytes   : aliased C.C_UInt64 := 16#DEAD#;
         Status  : constant C.Status :=
           C.Mat_Borrow_Row_Data
             (Raw_Handle (Handle), 0, Address'Access, Bytes'Access);
      begin
         AUnit.Assertions.Assert
           (Status = C.Error_Invalid_Argument
            and then Address = System.Null_Address
            and then Bytes = 0,
            "The row borrow ABI must continue to reject N-D Mats");
      end Row_API_Stays_Two_Dimensional;
   begin
      AUnit.Assertions.Assert
        (Result.Status = C.Success
         and then Result.Address /= System.Null_Address
         and then Result.Bytes = 768
         and then Result.Bytes = Logical_Bytes (Volume),
         "A 2 x 3 x 4 Float64 C4 Mat must report 24 * 32 = 768 bytes");

      AUnit.Assertions.Assert
        (Whole.Status = C.Success and then Whole.Bytes = 24,
         "A 2 x 3 x 4 UInt8 Mat must report 24 bytes");

      AUnit.Assertions.Assert
        (Packed.Is_Continuous and then Packed.Total = 12,
         "The leading-axis Slice fixture must be continuous");
      AUnit.Assertions.Assert
        (Tail.Status = C.Success
         and then Tail.Bytes = 12
         and then System.Storage_Elements."+" (Whole.Address, 12)
                  = Tail.Address,
         "A continuous N-D Slice must start 12 elements into its source"
         & " and report exactly 12 bytes");

      AUnit.Assertions.Assert
        (not Gapped.Is_Continuous and then Gapped.Total = 8,
         "The middle-axis Slice fixture must be non-continuous");
      Assert_Rejected (Borrow (Gapped), "A non-contiguous N-D Slice");

      OpenCV.Core.Module_Interop.With_Input_Handle
        (Volume, Row_API_Stays_Two_Dimensional'Access);
   end Check_N_Dimensional;

   procedure Check_Empty is
      Default_Mat : OpenCV.Core.Mat;
      Typed_Empty : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));
   begin
      AUnit.Assertions.Assert
        (Default_Mat.Dimension_Count = 0,
         "The default Mat fixture must have zero dimensions");
      Assert_Empty (Borrow (Default_Mat), "A default zero-dimension Mat");
      Assert_Empty (Borrow (Typed_Empty), "A typed empty 0 x 0 Mat");
   end Check_Empty;

   procedure Check is
   begin
      Check_Null_Arguments;
      Check_Two_Dimensional;
      Check_N_Dimensional;
      Check_Empty;
   end Check;

end ND_Buffer_Access_Tests.Raw_ABI;
