package body OpenCV.Core.Internal.Object_Storage is
   procedure Verify is
   begin
      --  Ordinary conditional: enforcement is independent of -gnatp.
      if Element_Type'Size /= Expected_Element_Bits then
         raise OpenCV_Error with "typed element value size mismatch";
      end if;
      if Element_Type'Object_Size /= Expected_Element_Bits then
         raise OpenCV_Error with "typed element object storage size mismatch";
      end if;
      if Array_Component_Bits /= Expected_Element_Bits then
         raise OpenCV_Error with "typed array component stride mismatch";
      end if;
      if Native_Alignment /= Expected_Native_Alignment then
         raise OpenCV_Error with "typed native alignment allowance mismatch";
      end if;
      if Element_Type'Alignment > Native_Alignment then
         raise OpenCV_Error with "typed element alignment mismatch";
      end if;
   end Verify;
end OpenCV.Core.Internal.Object_Storage;
