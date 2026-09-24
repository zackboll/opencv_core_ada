package Integer_Borrow_Lifetime_Probe is

   --  Test-only instrumentation. Arming makes OpenCV fill a Mat allocation
   --  with the sentinel byte 16#A5# immediately before freeing it. Disarm
   --  restores the previous allocator. This is not a public API.
   procedure Arm;
   procedure Disarm;

end Integer_Borrow_Lifetime_Probe;
