with Interfaces.C;

package body Integer_Borrow_Lifetime_Probe is

   use type Interfaces.C.unsigned_char;

   function Probe_Begin return Interfaces.C.unsigned_char
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_begin";

   function Probe_Restore_Default return Interfaces.C.unsigned_char
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_restore_default";

   function Probe_Finish return Interfaces.C.unsigned_char
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_finish";

   function Probe_Target_Captured return Interfaces.C.unsigned_char
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_target_captured";

   function Probe_Target_Live return Interfaces.C.unsigned_char
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_target_live";

   function Probe_Deallocation_Count return Interfaces.C.int
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_deallocation_count";

   function Probe_Target_Size return Interfaces.C.unsigned_long
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_target_size";

   procedure Check (Status : Interfaces.C.unsigned_char) is
   begin
      if Status /= 0 then
         raise Probe_Error;
      end if;
   end Check;

   procedure Begin_Observation is
   begin
      Check (Probe_Begin);
   end Begin_Observation;

   procedure Restore_Default_Allocator is
   begin
      Check (Probe_Restore_Default);
   end Restore_Default_Allocator;

   procedure Finish is
   begin
      Check (Probe_Finish);
   end Finish;

   function Target_Captured return Boolean
   is (Probe_Target_Captured /= 0);

   function Target_Live return Boolean
   is (Probe_Target_Live /= 0);

   function Deallocation_Count return Natural
   is (Natural (Probe_Deallocation_Count));

   function Target_Size return Natural
   is (Natural (Probe_Target_Size));

end Integer_Borrow_Lifetime_Probe;
