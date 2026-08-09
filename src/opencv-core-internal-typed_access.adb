with Ada.Exceptions;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Internal.Typed_Access is

   use type OpenCV.Internal.C_API.Status;

   procedure Raise_On_Error
     (Status : OpenCV.Internal.C_API.Status; Operation : String)
   is
      Diagnostic : constant String := OpenCV.Internal.C_API.Last_Error_Message;
   begin
      if Status = OpenCV.Internal.C_API.Success then
         return;
      end if;

      if Diagnostic'Length = 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " failed");
      else
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & " failed: " & Diagnostic);
      end if;
   end Raise_On_Error;

   function Get_UInt8 (Image : Mat; Row, Column : Integer) return UInt8_Value
   is
      Result : aliased OpenCV.Internal.C_API.C_UInt8 := 0;
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Get_UInt8
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Result => Result'Access);
   begin
      Raise_On_Error (Status, "UInt8 typed Mat read");
      return UInt8_Value (Result);
   end Get_UInt8;

   procedure Set_UInt8
     (Image : in out Mat; Row, Column : Integer; Value : UInt8_Value)
   is
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Set_UInt8
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Value  => OpenCV.Internal.C_API.C_UInt8 (Value));
   begin
      Raise_On_Error (Status, "UInt8 typed Mat write");
   end Set_UInt8;

   function Get_Float32
     (Image : Mat; Row, Column : Integer) return Float32_Value
   is
      Result : aliased OpenCV.Internal.C_API.C_Float32 := 0.0;
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Get_Float32
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Result => Result'Access);
   begin
      Raise_On_Error (Status, "Float32 typed Mat read");
      return Float32_Value (Result);
   end Get_Float32;

   procedure Set_Float32
     (Image : in out Mat; Row, Column : Integer; Value : Float32_Value)
   is
      Status : constant OpenCV.Internal.C_API.Status :=
        OpenCV.Internal.C_API.Mat_Set_Float32
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Value  => OpenCV.Internal.C_API.C_Float32 (Value));
   begin
      Raise_On_Error (Status, "Float32 typed Mat write");
   end Set_Float32;

end OpenCV.Core.Internal.Typed_Access;
