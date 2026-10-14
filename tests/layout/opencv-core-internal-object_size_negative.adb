with Ada.Text_IO;
with Interfaces;
with Interfaces.C;
with OpenCV.Core.Internal.Object_Storage;
with OpenCV.Core.Internal.Typed_External_Mat_View;
with System;

procedure OpenCV.Core.Internal.Object_Size_Negative is
   use type Interfaces.C.unsigned;
   --  Deliberate padding is the negative fixture, not a production warning.
   pragma Warnings (Off, "32 bits of * unused");
   type Padded is record
      First, Second : Interfaces.Unsigned_16;
   end record
   with Size => 32, Object_Size => 64, Alignment => 2;
   pragma Warnings (On, "32 bits of * unused");
   type Buffer is array (Natural range <>) of Padded with Component_Size => 32;
   package Views is new
     Typed_External_Mat_View
       (Padded,
        Buffer,
        Float16,
        2,
        32,
        2,
        "padded test");
   type Padded_Scalar is mod 2**16 with Size => 16, Object_Size => 32;
   package Scalar_Storage is new Object_Storage (Padded_Scalar, 16);
   Data      : aliased Buffer := (7 .. 14 => (16#8000#, 16#7C00#));
   Before    : constant Buffer := Data;
   Callbacks : Natural := 0;
   function Count
     (Boundary : Interfaces.C.unsigned) return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3b_constructor_count";
   procedure Snapshot (Address : System.Address; Size : Interfaces.C.size_t)
   with Import, Convention => C, External_Name => "r3c_snapshot";
   function Unchanged
     (Address : System.Address; Size : Interfaces.C.size_t)
      return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3c_bytes_unchanged";
   function Live return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3c_live_views";
   procedure Read (Image : Mat) is
      pragma Unreferenced (Image);
   begin
      Callbacks := Callbacks + 1;
   end Read;
   procedure Write (Image : in out Mat) is
   begin
      Read (Image);
   end Write;
begin
   if Padded'Size /= 32
     or else Padded'Object_Size /= 64
     or else Buffer'Component_Size /= 32
     or else Padded'Alignment /= 2
   then
      raise Program_Error with "invalid padded fixture";
   end if;
   for Form in 0 .. 7 loop
      Snapshot (Data (Data'First)'Address, 32);
      begin
         case Form is
            when 0 =>
               Views.With_Writable_Mat_View (Data, 2, 4, Write'Access);

            when 1 =>
               Views.With_Read_Only_Mat_View (Data, 2, 4, Read'Access);

            when 2 =>
               Views.With_Writable_Mat_View (Data, (2, 2, 2), Write'Access);

            when 3 =>
               Views.With_Read_Only_Mat_View (Data, (2, 2, 2), Read'Access);

            when 4 =>
               Views.With_Writable_Strided_Mat_View
                 (Data, 2, 3, 4, Write'Access);

            when 5 =>
               Views.With_Read_Only_Strided_Mat_View
                 (Data, 2, 3, 4, Read'Access);

            when 6 =>
               Views.With_Writable_Strided_Mat_View
                 (Data, (2, 1, 3), (4, 3, 1), Write'Access);

            when 7 =>
               Views.With_Read_Only_Strided_Mat_View
                 (Data, (2, 1, 3), (4, 3, 1), Read'Access);
         end case;
         raise Program_Error with "padded object accepted";
      exception
         when OpenCV_Error =>
            null;
      end;
      if Callbacks /= 0
        or else Data /= Before
        or else Live /= 0
        or else Unchanged (Data (Data'First)'Address, 32) /= 1
      then
         raise Program_Error with "rejection was not atomic";
      end if;
      for Boundary in Interfaces.C.unsigned range 0 .. 3 loop
         if Count (Boundary) /= 0 then
            raise Program_Error with "rejection entered constructor";
         end if;
      end loop;
      Ada.Text_IO.Put_Line
        ("PASS wrong Object_Size form" & Integer'Image (Form));
   end loop;
   begin
      Scalar_Storage.Verify;
      raise Program_Error with "padded scalar accepted";
   exception
      when OpenCV_Error =>
         null;
   end;
   Ada.Text_IO.Put_Line ("PASS scalar Size=16 Object_Size=32 rejection");
end OpenCV.Core.Internal.Object_Size_Negative;
