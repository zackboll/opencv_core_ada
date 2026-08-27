with Ada.Exceptions;
with OpenCV.Core.Internal.Typed_Access;
with OpenCV.Internal.C_API;

package body OpenCV.Core.Float32_Access is

   use type OpenCV.Internal.C_API.Status;

   procedure Raise_Invalid_Access (Message : String) is
   begin
      Ada.Exceptions.Raise_Exception (OpenCV_Error'Identity, Message);
   end Raise_Invalid_Access;

   procedure Raise_On_Error
     (Status : OpenCV.Internal.C_API.Status; Operation : String)
   is
      Diagnostic : constant String := OpenCV.Internal.C_API.Last_Error_Message;
   begin
      if Status = OpenCV.Internal.C_API.Success then
         return;
      end if;

      if Diagnostic'Length = 0 then
         Raise_Invalid_Access (Operation & " failed");
      else
         Raise_Invalid_Access (Operation & " failed: " & Diagnostic);
      end if;
   end Raise_On_Error;

   procedure Validate (Image : Mat; Row, Column : Integer) is
   begin
      if Image.Depth /= Float32 then
         Raise_Invalid_Access
           ("Float32 typed Mat access requires a Float32 Mat");

      elsif Image.Channels /= 1 then
         Raise_Invalid_Access
           ("typed Mat access requires exactly one channel");

      elsif Row < 0 or else Row >= Image.Rows then
         Raise_Invalid_Access ("Mat row index is outside the valid range");

      elsif Column < 0 or else Column >= Image.Columns then
         Raise_Invalid_Access ("Mat column index is outside the valid range");
      end if;
   end Validate;

   function Get (Image : Mat; Row, Column : Integer) return Float32_Value is
   begin
      Validate (Image, Row, Column);
      return
        OpenCV.Core.Internal.Typed_Access.Get_Float32 (Image, Row, Column);
   end Get;

   function Classify
     (Image : Mat; Row, Column : Integer) return Float32_Classification
   is
      Result : aliased OpenCV.Internal.C_API.C_Int32 :=
        OpenCV.Internal.C_API.Float32_Finite;
      Status : OpenCV.Internal.C_API.Status;
   begin
      Validate (Image, Row, Column);
      Status :=
        OpenCV.Internal.C_API.Mat_Classify_Float32
          (Self   => Image.Handle,
           Row    => OpenCV.Internal.C_API.C_Int32 (Row),
           Column => OpenCV.Internal.C_API.C_Int32 (Column),
           Result => Result'Access);
      Raise_On_Error (Status, "Float32 typed Mat classification");

      case Result is
         when OpenCV.Internal.C_API.Float32_Finite            =>
            return Finite;

         when OpenCV.Internal.C_API.Float32_Positive_Infinity =>
            return Positive_Infinity;

         when OpenCV.Internal.C_API.Float32_Negative_Infinity =>
            return Negative_Infinity;

         when OpenCV.Internal.C_API.Float32_Not_A_Number      =>
            return Not_A_Number;

         when others                                          =>
            Raise_Invalid_Access
              ("Float32 typed Mat classification returned an invalid value");
            return Finite;
      end case;
   end Classify;

   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Float32_Value) is
   begin
      Validate (Image, Row, Column);
      OpenCV.Core.Internal.Typed_Access.Set_Float32
        (Image, Row, Column, Value);
   end Set;
   procedure Validate (Image : Mat; Indices : Index_Array) is
      Axis : Positive := 1;
   begin
      if Image.Depth /= Float32 then
         Raise_Invalid_Access
           ("Float32 typed Mat access requires a Float32 Mat");

      elsif Image.Channels /= 1 then
         Raise_Invalid_Access
           ("typed Mat access requires exactly one channel");

      elsif Image.Dimension_Count = 0 then
         Raise_Invalid_Access
           ("typed Mat access requires a Mat with at least one dimension");

      elsif Indices'Length /= Image.Dimension_Count then
         Raise_Invalid_Access
           ("typed Mat access requires one index per Mat dimension");
      end if;

      for Index_Value of Indices loop
         if Index_Value >= Image.Extent (Axis) then
            Raise_Invalid_Access ("Mat index is outside the valid range");
         end if;

         Axis := Axis + 1;
      end loop;
   end Validate;

   function Get (Image : Mat; Indices : Index_Array) return Float32_Value is
   begin
      Validate (Image, Indices);
      return OpenCV.Core.Internal.Typed_Access.Get_Float32 (Image, Indices);
   end Get;

   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Float32_Value) is
   begin
      Validate (Image, Indices);
      OpenCV.Core.Internal.Typed_Access.Set_Float32 (Image, Indices, Value);
   end Set;

end OpenCV.Core.Float32_Access;
