with Ada.Text_IO;
with Interfaces;
with Interfaces.C;
with OpenCV.Core.Float16_Vec2;
with OpenCV.Core.Internal.Object_Storage;
with OpenCV.Core.Internal.Typed_Row_Borrowing;
with OpenCV.Core.Internal.Typed_Continuous_Borrowing;

procedure OpenCV.Core.Internal.Layout_Guard_Controls is
   use type Interfaces.C.unsigned;
   pragma Warnings (Off, "32 bits of * unused");
   type Padded is record
      A, B : Interfaces.Unsigned_16;
   end record
   with Size => 32, Object_Size => 64, Alignment => 2;
   pragma Warnings (On, "32 bits of * unused");
   package Padded_Guard is new Object_Storage (Padded, 32, 32, 2, 2);
   type Element is new Float16_Vec2.Vector with Alignment => 4;
   type Buffer is array (Natural range <>) of Element;
   package Overaligned is new
     Object_Storage (Element, Element'Size, Buffer'Component_Size, 2, 2);
   package Wrong_Size is new Object_Storage (Interfaces.Unsigned_32, 16);
   package Wrong_Stride is new
     Object_Storage (Interfaces.Unsigned_32, 32, 64, 4, 4);
   package Wrong_Allowance is new
     Object_Storage (Interfaces.Unsigned_32, 32, 32, 8, 4);
   --  This layout is legal for aliased callbacks; only its native allowance
   --  is incompatible. No compressed padded overlay is manufactured.
   type Ordinary_Buffer is array (Natural range <>) of Interfaces.Unsigned_32;
   package Rows is new
     Typed_Row_Borrowing
       (Interfaces.Unsigned_32,
        Ordinary_Buffer,
        Int32,
        1,
        32,
        2,
        "guard test");
   package Buffers is new
     Typed_Continuous_Borrowing
       (Interfaces.Unsigned_32,
        Ordinary_Buffer,
        Int32,
        1,
        32,
        2,
        "guard test");
   Image     : Mat;
   Callbacks : Natural := 0;
   function Leases return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3g_lease_count";
   procedure Read (Data : aliased Ordinary_Buffer) is
      pragma Unreferenced (Data);
   begin
      Callbacks := Callbacks + 1;
   end Read;
   procedure Write (Data : aliased in out Ordinary_Buffer) is
   begin
      Read (Data);
   end Write;
begin
   if Padded'Size /= 32 or else Padded'Object_Size /= 64 then
      raise Program_Error with "padded fixture does not isolate Object_Size";
   end if;
   if Element'Size /= 32
     or else Element'Object_Size /= 32
     or else Element'Alignment /= 4
     or else Buffer'Component_Size /= 32
   then
      raise Program_Error with "over-alignment fixture is not independent";
   end if;
   for Test in 0 .. 4 loop
      begin
         case Test is
            when 0 =>
               Padded_Guard.Verify;

            when 1 =>
               Overaligned.Verify;

            when 2 =>
               Wrong_Size.Verify;

            when 3 =>
               Wrong_Stride.Verify;

            when 4 =>
               Wrong_Allowance.Verify;
         end case;
         raise Program_Error with "invalid layout accepted";
      exception
         when OpenCV_Error =>
            null;
      end;
   end loop;
   for Form in 0 .. 3 loop
      begin
         case Form is
            when 0 =>
               Rows.With_Read_Only_Row (Image, 0, Read'Access);

            when 1 =>
               Rows.With_Writable_Row (Image, 0, Write'Access);

            when 2 =>
               Buffers.With_Read_Only_Buffer (Image, Read'Access);

            when 3 =>
               Buffers.With_Writable_Buffer (Image, Write'Access);
         end case;
         raise Program_Error with "invalid borrowing layout accepted";
      exception
         when OpenCV_Error =>
            null;
      end;
      if Leases /= 0 or else Callbacks /= 0 then
         raise Program_Error with "guard entered lease or callback";
      end if;
   end loop;
   Ada.Text_IO.Put_Line
     ("PASS actual padded-object guard and four legal pre-lease rejections");
end OpenCV.Core.Internal.Layout_Guard_Controls;
