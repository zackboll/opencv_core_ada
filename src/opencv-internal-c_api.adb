with Interfaces.C.Strings;

package body OpenCV.Internal.C_API is

   use type Interfaces.C.Strings.chars_ptr;

   function Last_Error_Message_Pointer return Interfaces.C.Strings.chars_ptr
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_last_error_message";

   function Last_Error_Message return String is
      Message : constant Interfaces.C.Strings.chars_ptr :=
        Last_Error_Message_Pointer;
   begin
      if Message = Interfaces.C.Strings.Null_Ptr then
         return "";
      end if;

      return Interfaces.C.Strings.Value (Message);
   end Last_Error_Message;

end OpenCV.Internal.C_API;
