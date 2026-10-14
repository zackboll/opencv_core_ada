generic
   type Element_Type is private;
   Expected_Element_Bits : Positive;
   Array_Component_Bits : Positive := Expected_Element_Bits;
   Native_Alignment : Positive := Element_Type'Alignment;
   Expected_Native_Alignment : Positive := Native_Alignment;
package OpenCV.Core.Internal.Object_Storage is
   --  Call-time checks, independent of assertions and suppressed Ada checks.
   --  Object_Size is checked separately from value size and array stride.
   --  Expected_Native_Alignment is the depth's storage allowance, not the
   --  element's requested alignment. Call before construction or lease entry.
   procedure Verify;
end OpenCV.Core.Internal.Object_Storage;
