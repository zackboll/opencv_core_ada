with Ada.Text_IO;
with Interfaces;
with Interfaces.C;
with OpenCV.Core;
with OpenCV.Core.Float16_Vec2;
with OpenCV.Core.Float16_Vec2_Access;
with OpenCV.Core.Float16_Vec2_Mat_View;
with OpenCV.Core.Float16_Vec2_Row_Access;
with OpenCV.Core.Float16_Vec2_Buffer_Access;
with System;
with System.Storage_Elements;

procedure Float16_Boundary_Controls is
   use OpenCV.Core;
   use System.Storage_Elements;
   use type Interfaces.Unsigned_16;
   use type Interfaces.C.unsigned;
   use type System.Address;
   package V renames Float16_Vec2;
   package Views renames Float16_Vec2_Mat_View;
   package Rows renames Float16_Vec2_Row_Access;
   package Buffers renames Float16_Vec2_Buffer_Access;
   Data             : aliased Views.Buffer_Array :=
     (7 .. 14 => (Float16_From_Bits (16#8000#), Float16_From_Bits (16#7C00#)));
   Callbacks        : Natural := 0;
   Strided          : Boolean := False;
   Callback_Error   : exception;
   Raise_Callback   : Boolean := False;
   function Live return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3c_live_views";
   function Destroyed return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3c_destroyed_views";
   procedure Misalign (Enabled : Interfaces.C.unsigned)
   with Import, Convention => C, External_Name => "r3g_set_misalignment";
   function Leases return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3g_lease_count";
   function Live_Leases return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3h_live_leases";
   function Destroyed_Leases return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3h_destroyed_leases";
   procedure Snapshot (Address : System.Address; Size : Interfaces.C.size_t)
   with Import, Convention => C, External_Name => "r3c_snapshot";
   function Unchanged
     (Address : System.Address; Size : Interfaces.C.size_t)
      return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3c_bytes_unchanged";
   procedure Check_Value (Value : V.Vector) is
   begin
      if Float16_Bits (Value (0)) /= 16#8000#
        or else Float16_Bits (Value (1)) /= 16#7C00#
      then
         raise Program_Error with "raw bits or component order changed";
      end if;
   end Check_Value;
   procedure Read_Row (Values : aliased Rows.Row_Array) is
      Offset : constant Natural := 4;
   begin
      if Live_Leases /= 1 then
         raise Program_Error with "row lease interception missing";
      end if;
      if Raise_Callback then
         raise Callback_Error;
      end if;
      if Values (Values'First)'Address /= Data (7 + Offset)'Address then
         raise Program_Error with "row does not alias backing storage";
      end if;
      Check_Value (Values (Values'First));
      Callbacks := Callbacks + 1;
   end Read_Row;
   procedure Write_Row (Values : aliased in out Rows.Row_Array) is
   begin
      Read_Row (Values);
      Values (Values'First + 1) :=
        (Float16_From_Bits (16#7E55#), Float16_From_Bits (16#FC00#));
      if Float16_Bits (Data (12) (0)) /= 16#7E55#
        or else Float16_Bits (Data (12) (1)) /= 16#FC00#
      then
         raise Program_Error with "row write not visible";
      end if;
   end Write_Row;
   procedure Read_Buffer (Values : aliased Buffers.Buffer_Array) is
   begin
      if Live_Leases /= 1 then
         raise Program_Error with "buffer lease interception missing";
      end if;
      if Raise_Callback then
         raise Callback_Error;
      end if;
      if Values (Values'First)'Address /= Data (7)'Address then
         raise Program_Error with "buffer does not alias backing storage";
      end if;
      Check_Value (Values (Values'First));
      Callbacks := Callbacks + 1;
   end Read_Buffer;
   procedure Write_Buffer (Values : aliased in out Buffers.Buffer_Array) is
   begin
      Read_Buffer (Values);
      Values (Values'Last) :=
        (Float16_From_Bits (16#0000#), Float16_From_Bits (16#0001#));
      if Float16_Bits (Data (14) (1)) /= 1 then
         raise Program_Error with "buffer write not visible";
      end if;
   end Write_Buffer;
   procedure Borrow (Image : in out Mat) is
   begin
      if Live /= 1 then
         raise Program_Error with "view not live in callback";
      end if;
      if Raise_Callback then
         raise Callback_Error;
      end if;
      Check_Value (Float16_Vec2_Access.Get (Image, 0, 0));
      declare
         Before           : constant Views.Buffer_Array := Data;
         Before_Callbacks : constant Natural := Callbacks;
         use type Views.Buffer_Array;
      begin
         Misalign (1);
         Snapshot (Data (Data'First)'Address, 32);
         for Form in 0 .. 3 loop
            begin
               case Form is
                  when 0 =>
                     Rows.With_Read_Only_Row (Image, 0, Read_Row'Access);

                  when 1 =>
                     Rows.With_Writable_Row (Image, 0, Write_Row'Access);

                  when 2 =>
                     Buffers.With_Read_Only_Buffer (Image, Read_Buffer'Access);

                  when 3 =>
                     Buffers.With_Writable_Buffer (Image, Write_Buffer'Access);
               end case;
               raise Program_Error with "misaligned borrowing accepted";
            exception
               when OpenCV.OpenCV_Error =>
                  null;
            end;
         end loop;
         Misalign (0);
         if Data /= Before
           or else Callbacks /= Before_Callbacks
           or else Live_Leases /= 0
           or else Unchanged (Data (Data'First)'Address, 32) /= 1
         then
            raise Program_Error with "misaligned borrowing changed storage";
         end if;
      end;
      Rows.With_Read_Only_Row (Image, 1, Read_Row'Access);
      Rows.With_Writable_Row (Image, 1, Write_Row'Access);
      if not Strided then
         Buffers.With_Read_Only_Buffer (Image, Read_Buffer'Access);
         Buffers.With_Writable_Buffer (Image, Write_Buffer'Access);
      end if;
      if Live_Leases /= 0 then
         raise Program_Error with "successful borrow retained lease";
      end if;
      Raise_Callback := True;
      for Form in 0 .. 3 loop
         declare
            Before : constant Interfaces.C.unsigned := Destroyed_Leases;
         begin
            Snapshot (Data (Data'First)'Address, 32);
            begin
               case Form is
                  when 0 =>
                     Rows.With_Read_Only_Row (Image, 1, Read_Row'Access);

                  when 1 =>
                     Rows.With_Writable_Row (Image, 1, Write_Row'Access);

                  when 2 =>
                     Buffers.With_Read_Only_Buffer (Image, Read_Buffer'Access);

                  when 3 =>
                     Buffers.With_Writable_Buffer (Image, Write_Buffer'Access);
               end case;
               raise Program_Error with "borrowing exception lost";
            exception
               when Callback_Error =>
                  null;
               when OpenCV.OpenCV_Error =>
                  if not Strided or else Form < 2 then
                     raise;
                  end if;
            end;
            if Live_Leases /= 0
              or else Destroyed_Leases /= Before + 1
              or else Unchanged (Data (Data'First)'Address, 32) /= 1
            then
               raise Program_Error with "borrowing failure leaked or mutated";
            end if;
         end;
      end loop;
      Raise_Callback := False;
   end Borrow;
   Before_Destroyed : Interfaces.C.unsigned;
   procedure ND_Read (Image : Mat) is
   begin
      Check_Value (Float16_Vec2_Access.Get (Image, (0, 0, 0)));
      if Image.Dimension_Count /= 3 then
         raise Program_Error with "N-D view shape lost";
      end if;
   end ND_Read;
   procedure Read_View (Image : Mat) is
   begin
      Check_Value (Float16_Vec2_Access.Get (Image, 0, 0));
      if Live /= 1 then
         raise Program_Error with "read-only constructor interception missing";
      end if;
   end Read_View;
   procedure ND_Write (Image : in out Mat) is
   begin
      ND_Read (Image);
      Float16_Vec2_Access.Set
        (Image,
         (1, 0, 1),
         (Float16_From_Bits (16#7E55#), Float16_From_Bits (16#FC00#)));
      if Float16_Bits (Data (12) (0)) /= 16#7E55# then
         raise Program_Error with "N-D write does not alias";
      end if;
   end ND_Write;
begin
   if To_Integer (Data (7)'Address) rem 2 /= 0
     or else To_Integer (Data (8)'Address) - To_Integer (Data (7)'Address) /= 4
   then
      raise Program_Error with "backing alignment or stride mismatch";
   end if;
   Views.With_Writable_Mat_View (Data, 2, 4, Borrow'Access);
   if Leases = 0 or else Leases /= Destroyed_Leases then
      raise Program_Error with "lease interception accounting mismatch";
   end if;
   if Live /= 0 or else Callbacks /= 4 then
      raise Program_Error with "packed callback or lifetime mismatch";
   end if;
   Data :=
     (others => (Float16_From_Bits (16#8000#), Float16_From_Bits (16#7C00#)));
   Strided := True;
   Views.With_Writable_Strided_Mat_View (Data, 2, 3, 4, Borrow'Access);
   if Live /= 0
     or else Callbacks /= 6
     or else Float16_Bits (Data (10) (0)) /= 16#8000#
     or else Float16_Bits (Data (14) (1)) /= 16#7C00#
   then
      raise Program_Error with "strided padding or lifetime mismatch";
   end if;
   Raise_Callback := True;
   Before_Destroyed := Destroyed;
   begin
      Views.With_Writable_Mat_View (Data, 2, 4, Borrow'Access);
      raise Program_Error with "callback exception lost";
   exception
      when Callback_Error =>
         null;
   end;
   if Live /= 0 or else Destroyed /= Before_Destroyed + 1 then
      raise Program_Error with "exception leaked view";
   end if;
   Raise_Callback := False;
   Views.With_Read_Only_Mat_View (Data, 2, 4, Read_View'Access);
   Views.With_Read_Only_Strided_Mat_View (Data, 2, 3, 4, Read_View'Access);
   for Form in 0 .. 3 loop
      Data :=
        (others =>
           (Float16_From_Bits (16#8000#), Float16_From_Bits (16#7C00#)));
      case Form is
         when 0 =>
            Views.With_Read_Only_Mat_View (Data, (2, 1, 4), ND_Read'Access);

         when 1 =>
            Views.With_Writable_Mat_View (Data, (2, 1, 4), ND_Write'Access);

         when 2 =>
            Views.With_Read_Only_Strided_Mat_View
              (Data, (2, 1, 3), (4, 3, 1), ND_Read'Access);

         when 3 =>
            Views.With_Writable_Strided_Mat_View
              (Data, (2, 1, 3), (4, 3, 1), ND_Write'Access);
      end case;
      if Live /= 0 or else Live_Leases /= 0 then
         raise Program_Error with "N-D view retained native header";
      end if;
   end loop;
   Ada.Text_IO.Put_Line
     ("PASS Float16 Vec2 packed/strided aliasing, row/buffer borrowing,"
      & " signed-zero/nonfinite bits, padding and exception cleanup");
end Float16_Boundary_Controls;
