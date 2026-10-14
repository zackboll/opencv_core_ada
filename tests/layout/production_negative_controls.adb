with Ada.Text_IO;
with Interfaces.C;
with OpenCV.Core;
with OpenCV.Core.Float16_Vec3_Mat_View;
with System;

procedure Production_Negative_Controls is
   use OpenCV.Core;
   use type Interfaces.C.unsigned;
   package Views renames Float16_Vec3_Mat_View;
   Data      : aliased Views.Buffer_Array :=
     (7 .. 14 => (others => Float16_From_Bits (16#7E55#)));
   Callbacks : Natural := 0;
   function Constructors
     (Boundary : Interfaces.C.unsigned) return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3b_constructor_count";
   function Live return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3c_live_views";
   procedure Snapshot (Address : System.Address; Size : Interfaces.C.size_t)
   with Import, Convention => C, External_Name => "r3c_snapshot";
   function Unchanged
     (Address : System.Address; Size : Interfaces.C.size_t)
      return Interfaces.C.unsigned
   with Import, Convention => C, External_Name => "r3c_bytes_unchanged";
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
   for Invalid_Geometry in Boolean loop
      for Form in 0 .. 7 loop
         Snapshot (Data (Data'First)'Address, 48);
         declare
            Columns : constant Positive := (if Invalid_Geometry then 3 else 5);
            Shape   : constant Dimension_Array :=
              (if Invalid_Geometry then (2, 0, 3) else (2, 1, 5));
            Stride  : constant Positive := (if Invalid_Geometry then 2 else 6);
         begin
            begin
               case Form is
                  when 0 =>
                     Views.With_Writable_Mat_View (Data, 2, 5, Write'Access);

                  when 1 =>
                     Views.With_Read_Only_Mat_View (Data, 2, 5, Read'Access);

                  when 2 =>
                     Views.With_Writable_Mat_View (Data, Shape, Write'Access);

                  when 3 =>
                     Views.With_Read_Only_Mat_View (Data, Shape, Read'Access);

                  when 4 =>
                     Views.With_Writable_Strided_Mat_View
                       (Data, 2, Columns, Stride, Write'Access);

                  when 5 =>
                     Views.With_Read_Only_Strided_Mat_View
                       (Data, 2, Columns, Stride, Read'Access);

                  when 6 =>
                     Views.With_Writable_Strided_Mat_View
                       (Data, Shape, (Stride, Columns, 1), Write'Access);

                  when 7 =>
                     Views.With_Read_Only_Strided_Mat_View
                       (Data, Shape, (Stride, Columns, 1), Read'Access);
               end case;
               raise Program_Error with "invalid production view accepted";
            exception
               when OpenCV.OpenCV_Error =>
                  null;
            end;
         end;
         if Callbacks /= 0
           or else Live /= 0
           or else Unchanged (Data (Data'First)'Address, 48) /= 1
         then
            raise Program_Error
              with "negative modified bytes or entered callback";
         end if;
         for Boundary in Interfaces.C.unsigned range 0 .. 3 loop
            if Constructors (Boundary) /= 0 then
               raise Program_Error with "negative entered native constructor";
            end if;
         end loop;
      end loop;
   end loop;
   Ada.Text_IO.Put_Line
     ("PASS production Vec3 geometry/capacity rejection, no constructor,"
      & " no callback and full initialized-byte preservation");
end Production_Negative_Controls;
