package Integer_Borrow_Lifetime_Probe is

   --  Test-only observation of one OpenCV-owned Mat allocation. Begin
   --  installs a single-target allocator before that allocation is created.
   --  The observer records whether the original block was captured, whether
   --  it is still live, and how many times its final release was observed.
   --  Those counters live outside the allocation and remain readable after
   --  the block and its UMatData are destroyed. This is not a public API
   --  and does not prove absence of use-after-free by reading freed memory.

   Probe_Error : exception;

   procedure Begin_Observation;
   procedure Restore_Default_Allocator;
   procedure Finish;

   function Target_Captured return Boolean;
   function Target_Live return Boolean;
   function Deallocation_Count return Natural;
   --  Byte size of the captured target. Intended for the small fixture
   --  allocations used by these tests; the foreign size is uint64_t and is
   --  checked into Natural after the import.
   function Target_Size return Natural;

end Integer_Borrow_Lifetime_Probe;
