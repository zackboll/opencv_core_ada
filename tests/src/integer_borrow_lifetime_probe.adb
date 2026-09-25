with Interfaces;

package body Integer_Borrow_Lifetime_Probe is

   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_64;

   subtype C_UInt8 is Interfaces.Unsigned_8;
   subtype C_Int32 is Interfaces.Integer_32;
   subtype C_UInt64 is Interfaces.Unsigned_64;

   pragma
     Compile_Time_Error
       (C_UInt8'Size /= 8,
        "borrow probe status must be an 8-bit unsigned C type");
   pragma
     Compile_Time_Error
       (C_Int32'Size /= 32,
        "borrow probe deallocation count must be a 32-bit signed C type");
   pragma
     Compile_Time_Error
       (C_UInt64'Size /= 64,
        "borrow probe target size must be a 64-bit unsigned C type");

   function Probe_Begin return C_UInt8
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_begin";

   function Probe_Restore_Default return C_UInt8
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_restore_default";

   function Probe_Finish return C_UInt8
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_finish";

   function Probe_Target_Captured return C_UInt8
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_target_captured";

   function Probe_Target_Live return C_UInt8
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_target_live";

   function Probe_Deallocation_Count return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_deallocation_count";

   function Probe_Target_Size return C_UInt64
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_target_size";

   procedure Check (Status : C_UInt8) is
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

   function Target_Size return Natural is
      Size : constant C_UInt64 := Probe_Target_Size;
   begin
      if Size > C_UInt64 (Natural'Last) then
         raise Constraint_Error
           with "observed target size exceeds the test-facing Natural range";
      end if;
      return Natural (Size);
   end Target_Size;

end Integer_Borrow_Lifetime_Probe;
