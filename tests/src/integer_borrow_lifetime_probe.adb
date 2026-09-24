package body Integer_Borrow_Lifetime_Probe is

   procedure Probe_Arm
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_arm";

   procedure Probe_Disarm
   with
     Import,
     Convention    => C,
     External_Name => "integer_borrow_lifetime_probe_disarm";

   procedure Arm is
   begin
      Probe_Arm;
   end Arm;

   procedure Disarm is
   begin
      Probe_Disarm;
   end Disarm;

end Integer_Borrow_Lifetime_Probe;
