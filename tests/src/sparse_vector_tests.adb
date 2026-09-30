with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Sparse;
with OpenCV.Core.Sparse.UInt8_Vec2_Access;
with OpenCV.Core.Sparse.UInt8_Vec3_Access;
with OpenCV.Core.Sparse.UInt8_Vec4_Access;
with OpenCV.Core.Sparse.Int8_Vec2_Access;
with OpenCV.Core.Sparse.Int8_Vec3_Access;
with OpenCV.Core.Sparse.Int8_Vec4_Access;
with OpenCV.Core.Sparse.UInt16_Vec2_Access;
with OpenCV.Core.Sparse.UInt16_Vec3_Access;
with OpenCV.Core.Sparse.UInt16_Vec4_Access;
with OpenCV.Core.Sparse.Int16_Vec2_Access;
with OpenCV.Core.Sparse.Int16_Vec3_Access;
with OpenCV.Core.Sparse.Int16_Vec4_Access;
with OpenCV.Core.Sparse.Int32_Vec2_Access;
with OpenCV.Core.Sparse.Int32_Vec3_Access;
with OpenCV.Core.Sparse.Int32_Vec4_Access;
with OpenCV.Core.Sparse.Float16_Vec2_Access;
with OpenCV.Core.Sparse.Float16_Vec3_Access;
with OpenCV.Core.Sparse.Float16_Vec4_Access;
with OpenCV.Core.Sparse.Float32_Vec2_Access;
with OpenCV.Core.Sparse.Float32_Vec3_Access;
with OpenCV.Core.Sparse.Float32_Vec4_Access;
with OpenCV.Core.Sparse.Float64_Vec2_Access;
with OpenCV.Core.Sparse.Float64_Vec3_Access;
with OpenCV.Core.Sparse.Float64_Vec4_Access;
with OpenCV.Core.UInt8_Vec2;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec4;
with OpenCV.Core.Int8_Vec2;
with OpenCV.Core.Int8_Vec3;
with OpenCV.Core.Int8_Vec4;
with OpenCV.Core.UInt16_Vec2;
with OpenCV.Core.UInt16_Vec3;
with OpenCV.Core.UInt16_Vec4;
with OpenCV.Core.Int16_Vec2;
with OpenCV.Core.Int16_Vec3;
with OpenCV.Core.Int16_Vec4;
with OpenCV.Core.Int32_Vec2;
with OpenCV.Core.Int32_Vec3;
with OpenCV.Core.Int32_Vec4;
with OpenCV.Core.Float16_Vec2;
with OpenCV.Core.Float16_Vec3;
with OpenCV.Core.Float16_Vec4;
with OpenCV.Core.Float32_Vec2;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec4;
with OpenCV.Core.Float64_Vec2;
with OpenCV.Core.Float64_Vec3;
with OpenCV.Core.Float64_Vec4;
with OpenCV.Core.Int32_Vec2_Access;
with OpenCV.Core.Float16_Vec3_Access;
with OpenCV.Core.Float64_Vec4_Access;
with OpenCV.Internal.C_API;

package body Sparse_Vector_Tests is
   package C renames OpenCV.Internal.C_API;
   package S renames OpenCV.Core.Sparse;
   use type C.Status;
   use type C.C_UInt8;
   use type C.C_Int32;
   use type C.C_Float32;
   use type C.C_Float64;
   use type C.UInt8_Vec2;
   use type C.UInt8_Vec3;
   use type C.UInt8_Vec4;
   use type C.Int8_Vec2;
   use type C.UInt16_Vec2;
   use type C.Int16_Vec4;
   use type C.Float16_Vec2;
   use type C.Float32_Vec2;
   use type C.Float32_Vec4;
   use type C.Float64_Vec2;
   use type C.C_Int32_Array;
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Core.Index_Array;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.UInt8_Vec2.Vector;
   use type OpenCV.Core.UInt8_Vec3.Vector;
   use type OpenCV.Core.UInt8_Vec4.Vector;
   use type OpenCV.Core.Int8_Vec2.Vector;
   use type OpenCV.Core.Int8_Vec3.Vector;
   use type OpenCV.Core.Int8_Vec4.Vector;
   use type OpenCV.Core.UInt16_Vec2.Vector;
   use type OpenCV.Core.UInt16_Vec3.Vector;
   use type OpenCV.Core.UInt16_Vec4.Vector;
   use type OpenCV.Core.Int16_Vec2.Vector;
   use type OpenCV.Core.Int16_Vec3.Vector;
   use type OpenCV.Core.Int16_Vec4.Vector;
   use type OpenCV.Core.Int32_Vec2.Vector;
   use type OpenCV.Core.Int32_Vec3.Vector;
   use type OpenCV.Core.Int32_Vec4.Vector;
   use type OpenCV.Core.Float16_Vec2.Vector;
   use type OpenCV.Core.Float16_Vec3.Vector;
   use type OpenCV.Core.Float16_Vec4.Vector;
   use type OpenCV.Core.Float32_Vec2.Vector;
   use type OpenCV.Core.Float32_Vec3.Vector;
   use type OpenCV.Core.Float32_Vec4.Vector;
   use type OpenCV.Core.Float64_Vec2.Vector;
   use type OpenCV.Core.Float64_Vec3.Vector;
   use type OpenCV.Core.Float64_Vec4.Vector;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_64;
   use type Interfaces.Integer_8;
   use type Interfaces.Integer_16;
   use type Interfaces.IEEE_Float_32;
   use type OpenCV.Size_Coordinate;
   use type OpenCV.Core.Dimension_Array;
   use Mat_Test_Support;

   subtype Fixture is Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      AUnit.Assertions.Assert (Condition, Message);
   end Assert;

   function Half
     (Bits : Interfaces.Unsigned_16) return OpenCV.Core.Float16_Value
   is (OpenCV.Core.Float16_From_Bits (Bits));

   function Bits_Of
     (Value : OpenCV.Core.Float16_Value) return Interfaces.Unsigned_16
   is (OpenCV.Core.Float16_Bits (Value));

   generic
      type Vector is private;
      with
        function Get
          (Image : S.Sparse_Mat; Indices : OpenCV.Core.Index_Array)
           return Vector;
      with
        procedure Set
          (Image   : in out S.Sparse_Mat;
           Indices : OpenCV.Core.Index_Array;
           Value   : Vector);
      with
        procedure For_Each_Stored
          (Image   : S.Sparse_Mat;
           Process :
             not null access procedure
               (Indices : OpenCV.Core.Index_Array; Value : Vector));
   procedure Exercise
     (Kind     : OpenCV.Core.Depth_Type;
      Channels : OpenCV.Core.Channel_Count;
      Sample   : Vector;
      Zero     : Vector;
      Name     : String);

   procedure Exercise
     (Kind     : OpenCV.Core.Depth_Type;
      Channels : OpenCV.Core.Channel_Count;
      Sample   : Vector;
      Zero     : Vector;
      Name     : String)
   is
      Image : S.Sparse_Mat := S.Create ((2, 3), (Kind, Channels));
      Seen  : Boolean := False;
      procedure Visit (Indices : OpenCV.Core.Index_Array; Value : Vector) is
      begin
         Assert
           (not Seen and then Indices = (1, 2) and then Value = Sample,
            Name & " unexpected stored vector");
         Seen := True;
      end Visit;
   begin
      Assert
        (Get (Image, (1, 2)) = Zero
         and then not Image.Contains ((1, 2))
         and then Image.Stored_Element_Count = 0,
         Name & " missing read created a node");
      Set (Image, (1, 2), Sample);
      Assert
        (Image.Contains ((1, 2))
         and then Image.Stored_Element_Count = 1
         and then Get (Image, (1, 2)) = Sample,
         Name & " stored vector");
      For_Each_Stored (Image, Visit'Access);
      Assert (Seen, Name & " traversal");
   end Exercise;

   procedure All_Layouts (Test : in out Fixture) is
      pragma Unreferenced (Test);
      procedure U8_2 is new
        Exercise
          (OpenCV.Core.UInt8_Vec2.Vector,
           S.UInt8_Vec2_Access.Get,
           S.UInt8_Vec2_Access.Set,
           S.UInt8_Vec2_Access.For_Each_Stored);
      procedure U8_3 is new
        Exercise
          (OpenCV.Core.UInt8_Vec3.Vector,
           S.UInt8_Vec3_Access.Get,
           S.UInt8_Vec3_Access.Set,
           S.UInt8_Vec3_Access.For_Each_Stored);
      procedure U8_4 is new
        Exercise
          (OpenCV.Core.UInt8_Vec4.Vector,
           S.UInt8_Vec4_Access.Get,
           S.UInt8_Vec4_Access.Set,
           S.UInt8_Vec4_Access.For_Each_Stored);
      procedure I8_2 is new
        Exercise
          (OpenCV.Core.Int8_Vec2.Vector,
           S.Int8_Vec2_Access.Get,
           S.Int8_Vec2_Access.Set,
           S.Int8_Vec2_Access.For_Each_Stored);
      procedure I8_3 is new
        Exercise
          (OpenCV.Core.Int8_Vec3.Vector,
           S.Int8_Vec3_Access.Get,
           S.Int8_Vec3_Access.Set,
           S.Int8_Vec3_Access.For_Each_Stored);
      procedure I8_4 is new
        Exercise
          (OpenCV.Core.Int8_Vec4.Vector,
           S.Int8_Vec4_Access.Get,
           S.Int8_Vec4_Access.Set,
           S.Int8_Vec4_Access.For_Each_Stored);
      procedure U16_2 is new
        Exercise
          (OpenCV.Core.UInt16_Vec2.Vector,
           S.UInt16_Vec2_Access.Get,
           S.UInt16_Vec2_Access.Set,
           S.UInt16_Vec2_Access.For_Each_Stored);
      procedure U16_3 is new
        Exercise
          (OpenCV.Core.UInt16_Vec3.Vector,
           S.UInt16_Vec3_Access.Get,
           S.UInt16_Vec3_Access.Set,
           S.UInt16_Vec3_Access.For_Each_Stored);
      procedure U16_4 is new
        Exercise
          (OpenCV.Core.UInt16_Vec4.Vector,
           S.UInt16_Vec4_Access.Get,
           S.UInt16_Vec4_Access.Set,
           S.UInt16_Vec4_Access.For_Each_Stored);
      procedure I16_2 is new
        Exercise
          (OpenCV.Core.Int16_Vec2.Vector,
           S.Int16_Vec2_Access.Get,
           S.Int16_Vec2_Access.Set,
           S.Int16_Vec2_Access.For_Each_Stored);
      procedure I16_3 is new
        Exercise
          (OpenCV.Core.Int16_Vec3.Vector,
           S.Int16_Vec3_Access.Get,
           S.Int16_Vec3_Access.Set,
           S.Int16_Vec3_Access.For_Each_Stored);
      procedure I16_4 is new
        Exercise
          (OpenCV.Core.Int16_Vec4.Vector,
           S.Int16_Vec4_Access.Get,
           S.Int16_Vec4_Access.Set,
           S.Int16_Vec4_Access.For_Each_Stored);
   begin
      U8_2 (OpenCV.Core.UInt8, 2, (1, 200), (0, 0), "UInt8 C2");
      U8_3 (OpenCV.Core.UInt8, 3, (1, 2, 255), (others => 0), "UInt8 C3");
      U8_4 (OpenCV.Core.UInt8, 4, (4, 3, 2, 1), (others => 0), "UInt8 C4");
      I8_2 (OpenCV.Core.Int8, 2, (-128, 127), (0, 0), "Int8 C2");
      I8_3 (OpenCV.Core.Int8, 3, (-1, 0, 127), (others => 0), "Int8 C3");
      I8_4 (OpenCV.Core.Int8, 4, (-128, -1, 1, 127), (others => 0), "Int8 C4");
      U16_2 (OpenCV.Core.UInt16, 2, (1, 65_535), (0, 0), "UInt16 C2");
      U16_3 (OpenCV.Core.UInt16, 3, (7, 8, 9), (others => 0), "UInt16 C3");
      U16_4
        (OpenCV.Core.UInt16, 4, (1, 2, 3, 65_534), (others => 0), "UInt16 C4");
      I16_2 (OpenCV.Core.Int16, 2, (-32_768, 32_767), (0, 0), "Int16 C2");
      I16_3 (OpenCV.Core.Int16, 3, (-2, 0, 3), (others => 0), "Int16 C3");
      I16_4 (OpenCV.Core.Int16, 4, (-9, -8, 7, 6), (others => 0), "Int16 C4");
      declare
         procedure I32_2 is new
           Exercise
             (OpenCV.Core.Int32_Vec2.Vector,
              S.Int32_Vec2_Access.Get,
              S.Int32_Vec2_Access.Set,
              S.Int32_Vec2_Access.For_Each_Stored);
         procedure I32_3 is new
           Exercise
             (OpenCV.Core.Int32_Vec3.Vector,
              S.Int32_Vec3_Access.Get,
              S.Int32_Vec3_Access.Set,
              S.Int32_Vec3_Access.For_Each_Stored);
         procedure I32_4 is new
           Exercise
             (OpenCV.Core.Int32_Vec4.Vector,
              S.Int32_Vec4_Access.Get,
              S.Int32_Vec4_Access.Set,
              S.Int32_Vec4_Access.For_Each_Stored);
         procedure F32_2 is new
           Exercise
             (OpenCV.Core.Float32_Vec2.Vector,
              S.Float32_Vec2_Access.Get,
              S.Float32_Vec2_Access.Set,
              S.Float32_Vec2_Access.For_Each_Stored);
         procedure F32_3 is new
           Exercise
             (OpenCV.Core.Float32_Vec3.Vector,
              S.Float32_Vec3_Access.Get,
              S.Float32_Vec3_Access.Set,
              S.Float32_Vec3_Access.For_Each_Stored);
         procedure F32_4 is new
           Exercise
             (OpenCV.Core.Float32_Vec4.Vector,
              S.Float32_Vec4_Access.Get,
              S.Float32_Vec4_Access.Set,
              S.Float32_Vec4_Access.For_Each_Stored);
         procedure F64_2 is new
           Exercise
             (OpenCV.Core.Float64_Vec2.Vector,
              S.Float64_Vec2_Access.Get,
              S.Float64_Vec2_Access.Set,
              S.Float64_Vec2_Access.For_Each_Stored);
         procedure F64_3 is new
           Exercise
             (OpenCV.Core.Float64_Vec3.Vector,
              S.Float64_Vec3_Access.Get,
              S.Float64_Vec3_Access.Set,
              S.Float64_Vec3_Access.For_Each_Stored);
         procedure F64_4 is new
           Exercise
             (OpenCV.Core.Float64_Vec4.Vector,
              S.Float64_Vec4_Access.Get,
              S.Float64_Vec4_Access.Set,
              S.Float64_Vec4_Access.For_Each_Stored);
         procedure F16_2 is new
           Exercise
             (OpenCV.Core.Float16_Vec2.Vector,
              S.Float16_Vec2_Access.Get,
              S.Float16_Vec2_Access.Set,
              S.Float16_Vec2_Access.For_Each_Stored);
         procedure F16_3 is new
           Exercise
             (OpenCV.Core.Float16_Vec3.Vector,
              S.Float16_Vec3_Access.Get,
              S.Float16_Vec3_Access.Set,
              S.Float16_Vec3_Access.For_Each_Stored);
         procedure F16_4 is new
           Exercise
             (OpenCV.Core.Float16_Vec4.Vector,
              S.Float16_Vec4_Access.Get,
              S.Float16_Vec4_Access.Set,
              S.Float16_Vec4_Access.For_Each_Stored);
      begin
         I32_2
           (OpenCV.Core.Int32,
            2,
            (-2_000_000_000, 2_000_000_001),
            (0, 0),
            "Int32 C2");
         I32_3 (OpenCV.Core.Int32, 3, (-5, 0, 9), (others => 0), "Int32 C3");
         I32_4
           (OpenCV.Core.Int32, 4, (1, -2, 3, -4), (others => 0), "Int32 C4");
         F32_2
           (OpenCV.Core.Float32, 2, (-1.5, 2.25), (0.0, 0.0), "Float32 C2");
         F32_3
           (OpenCV.Core.Float32,
            3,
            (0.5, -0.5, 4.0),
            (others => 0.0),
            "Float32 C3");
         F32_4
           (OpenCV.Core.Float32,
            4,
            (1.0, 2.0, 3.0, 4.0),
            (others => 0.0),
            "Float32 C4");
         F64_2
           (OpenCV.Core.Float64, 2, (-8.125, 16.5), (0.0, 0.0), "Float64 C2");
         F64_3
           (OpenCV.Core.Float64,
            3,
            (1.0, 2.0, -3.0),
            (others => 0.0),
            "Float64 C3");
         F64_4
           (OpenCV.Core.Float64,
            4,
            (9.0, 8.0, 7.0, 6.0),
            (others => 0.0),
            "Float64 C4");
         F16_2
           (OpenCV.Core.Float16,
            2,
            (Half (16#3C00#), Half (16#BC00#)),
            (Half (0), Half (0)),
            "Float16 C2");
         F16_3
           (OpenCV.Core.Float16,
            3,
            (Half (16#0001#), Half (16#3C00#), Half (16#7C00#)),
            (others => Half (0)),
            "Float16 C3");
         F16_4
           (OpenCV.Core.Float16,
            4,
            (Half (16#8000#),
             Half (16#0001#),
             Half (16#FC00#),
             Half (16#7E05#)),
            (others => Half (0)),
            "Float16 C4");
      end;
   end All_Layouts;

   procedure Explicit_Zero_Vectors (Test : in out Fixture) is
      pragma Unreferenced (Test);
      C2   : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Int32, 2));
      C3   : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.UInt8, 3));
      C4   : S.Sparse_Mat := S.Create ((2, 2), (OpenCV.Core.Float64, 4));
      Seen : Natural := 0;
      procedure Visit2
        (Indices : OpenCV.Core.Index_Array;
         Value   : OpenCV.Core.Int32_Vec2.Vector) is
      begin
         Assert (Indices = (0, 1) and then Value = (0, 0), "zero C2 visit");
         Seen := Seen + 1;
      end Visit2;
      procedure Visit3
        (Indices : OpenCV.Core.Index_Array;
         Value   : OpenCV.Core.UInt8_Vec3.Vector) is
      begin
         Assert (Indices = (1, 0) and then Value = (0, 0, 0), "zero C3 visit");
         Seen := Seen + 1;
      end Visit3;
      procedure Visit4
        (Indices : OpenCV.Core.Index_Array;
         Value   : OpenCV.Core.Float64_Vec4.Vector) is
      begin
         Assert
           (Indices = (1, 1) and then Value = (0.0, 0.0, 0.0, 0.0),
            "zero C4 visit");
         Seen := Seen + 1;
      end Visit4;
   begin
      S.Int32_Vec2_Access.Set (C2, (0, 1), (0, 0));
      S.UInt8_Vec3_Access.Set (C3, (1, 0), (0, 0, 0));
      S.Float64_Vec4_Access.Set (C4, (1, 1), (0.0, 0.0, 0.0, 0.0));
      Assert
        (C2.Contains ((0, 1))
         and then C2.Stored_Element_Count = 1
         and then S.Int32_Vec2_Access.Get (C2, (0, 1)) = (0, 0),
         "explicit zero C2 node");
      Assert
        (C3.Contains ((1, 0))
         and then C3.Stored_Element_Count = 1
         and then S.UInt8_Vec3_Access.Get (C3, (1, 0)) = (0, 0, 0),
         "explicit zero C3 node");
      Assert
        (C4.Contains ((1, 1))
         and then C4.Stored_Element_Count = 1
         and then S.Float64_Vec4_Access.Get (C4, (1, 1))
                  = (0.0, 0.0, 0.0, 0.0),
         "explicit zero C4 node");
      S.Int32_Vec2_Access.For_Each_Stored (C2, Visit2'Access);
      S.UInt8_Vec3_Access.For_Each_Stored (C3, Visit3'Access);
      S.Float64_Vec4_Access.For_Each_Stored (C4, Visit4'Access);
      Assert (Seen = 3, "explicit zero vectors are stored nodes");
   end Explicit_Zero_Vectors;

   procedure Exact_Float16_Vectors (Test : in out Fixture) is
      pragma Unreferenced (Test);
      type Word is new Interfaces.Unsigned_16;
      Patterns     : constant array (1 .. 7) of Word :=
        (16#0000#, 16#8000#, 16#0001#, 16#3C00#, 16#7C00#, 16#FC00#, 16#7E05#);
      C2           : S.Sparse_Mat :=
        S.Create ((1, 7), (OpenCV.Core.Float16, 2));
      C3           : S.Sparse_Mat :=
        S.Create ((1, 7), (OpenCV.Core.Float16, 3));
      C4           : S.Sparse_Mat :=
        S.Create ((1, 7), (OpenCV.Core.Float16, 4));
      Seen2, Seen3 : array (1 .. 7) of Boolean := (others => False);
      Seen4        : array (1 .. 7) of Boolean := (others => False);
      procedure Check2
        (Indices : OpenCV.Core.Index_Array;
         Value   : OpenCV.Core.Float16_Vec2.Vector)
      is
         Column : constant Positive := Positive (Integer (Indices (2)) + 1);
      begin
         Assert
           (Indices (1) = 0
            and then Bits_Of (Value (0))
                     = Interfaces.Unsigned_16 (Patterns (Column))
            and then Bits_Of (Value (1))
                     = Interfaces.Unsigned_16 (Patterns ((Column mod 7) + 1))
            and then not Seen2 (Column),
            "Float16 C2 visit bits");
         Seen2 (Column) := True;
      end Check2;
      procedure Check3
        (Indices : OpenCV.Core.Index_Array;
         Value   : OpenCV.Core.Float16_Vec3.Vector)
      is
         Column : constant Positive := Positive (Integer (Indices (2)) + 1);
      begin
         Assert
           (Bits_Of (Value (0)) = Interfaces.Unsigned_16 (Patterns (Column))
            and then Bits_Of (Value (1))
                     = Interfaces.Unsigned_16 (Patterns ((Column mod 7) + 1))
            and then Bits_Of (Value (2)) = 16#7E05#
            and then not Seen3 (Column),
            "Float16 C3 visit bits");
         Seen3 (Column) := True;
      end Check3;
      procedure Check4
        (Indices : OpenCV.Core.Index_Array;
         Value   : OpenCV.Core.Float16_Vec4.Vector)
      is
         Column : constant Positive := Positive (Integer (Indices (2)) + 1);
      begin
         Assert
           (Bits_Of (Value (0)) = 16#0000#
            and then Bits_Of (Value (1)) = 16#8000#
            and then Bits_Of (Value (2))
                     = Interfaces.Unsigned_16 (Patterns (Column))
            and then Bits_Of (Value (3)) = 16#7E05#
            and then not Seen4 (Column),
            "Float16 C4 visit bits");
         Seen4 (Column) := True;
      end Check4;
   begin
      for Column in Patterns'Range loop
         declare
            Index : constant OpenCV.Core.Index_Array :=
              (0, OpenCV.Size_Coordinate (Column - 1));
            Next  : constant Word := Patterns ((Column mod 7) + 1);
            Got2  : OpenCV.Core.Float16_Vec2.Vector;
            Got3  : OpenCV.Core.Float16_Vec3.Vector;
            Got4  : OpenCV.Core.Float16_Vec4.Vector;
         begin
            S.Float16_Vec2_Access.Set
              (C2,
               Index,
               (Half (Interfaces.Unsigned_16 (Patterns (Column))),
                Half (Interfaces.Unsigned_16 (Next))));
            S.Float16_Vec3_Access.Set
              (C3,
               Index,
               (Half (Interfaces.Unsigned_16 (Patterns (Column))),
                Half (Interfaces.Unsigned_16 (Next)),
                Half (16#7E05#)));
            S.Float16_Vec4_Access.Set
              (C4,
               Index,
               (Half (16#0000#),
                Half (16#8000#),
                Half (Interfaces.Unsigned_16 (Patterns (Column))),
                Half (16#7E05#)));
            Got2 := S.Float16_Vec2_Access.Get (C2, Index);
            Got3 := S.Float16_Vec3_Access.Get (C3, Index);
            Got4 := S.Float16_Vec4_Access.Get (C4, Index);
            Assert
              (Bits_Of (Got2 (0)) = Interfaces.Unsigned_16 (Patterns (Column))
               and then Bits_Of (Got2 (1)) = Interfaces.Unsigned_16 (Next),
               "Float16 C2 get bits");
            Assert
              (Bits_Of (Got3 (0)) = Interfaces.Unsigned_16 (Patterns (Column))
               and then Bits_Of (Got3 (1)) = Interfaces.Unsigned_16 (Next)
               and then Bits_Of (Got3 (2)) = 16#7E05#,
               "Float16 C3 get bits");
            Assert
              (Bits_Of (Got4 (0)) = 16#0000#
               and then Bits_Of (Got4 (1)) = 16#8000#
               and then Bits_Of (Got4 (2))
                        = Interfaces.Unsigned_16 (Patterns (Column))
               and then Bits_Of (Got4 (3)) = 16#7E05#,
               "Float16 C4 get bits");
         end;
      end loop;
      S.Float16_Vec2_Access.For_Each_Stored (C2, Check2'Access);
      S.Float16_Vec3_Access.For_Each_Stored (C3, Check3'Access);
      S.Float16_Vec4_Access.For_Each_Stored (C4, Check4'Access);
      Assert
        ((for all Item of Seen2 => Item)
         and then (for all Item of Seen3 => Item)
         and then (for all Item of Seen4 => Item),
         "every Float16 vector pattern visited once");
   end Exact_Float16_Vectors;

   procedure Public_Rejections (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image : S.Sparse_Mat := S.Create ((2, 3), (OpenCV.Core.UInt8, 4));
      Wide  : S.Sparse_Mat :=
        S.Create ((2, 2, 2, 2, 2), (OpenCV.Core.Int32, 2));
      Maxed : S.Sparse_Mat :=
        S.Create ((1 .. 32 => 2), (OpenCV.Core.Float32, 4));
      procedure Expect (Operation : not null access procedure) is
      begin
         Operation.all;
         Assert (False, "expected OpenCV_Error");
      exception
         when OpenCV.OpenCV_Error =>
            null;
      end Expect;
      procedure Short_Index is
      begin
         S.UInt8_Vec4_Access.Set (Image, (1 => 0), (1, 2, 3, 4));
      end Short_Index;
      procedure At_Extent is
      begin
         S.UInt8_Vec4_Access.Set (Image, (0, 3), (1, 2, 3, 4));
      end At_Extent;
      procedure Wrong_Channels is
      begin
         S.UInt16_Vec2_Access.Set (Image, (0, 0), (1, 2));
      end Wrong_Channels;
   begin
      Expect (Short_Index'Access);
      Expect (At_Extent'Access);
      Expect (Wrong_Channels'Access);
      Assert
        (Image.Stored_Element_Count = 0,
         "rejected public Set creates no node");
      S.Int32_Vec2_Access.Set (Wide, (1, 0, 1, 0, 1), (-3, 4));
      Assert
        (S.Int32_Vec2_Access.Get (Wide, (1, 0, 1, 0, 1)) = (-3, 4)
         and then Wide.Stored_Element_Count = 1,
         "5D vector node");
      S.Float32_Vec4_Access.Set (Maxed, (1 .. 32 => 1), (1.0, 2.0, 3.0, 4.0));
      Assert
        (Maxed.Dimension_Count = 32
         and then Maxed.Stored_Element_Count = 1
         and then S.Float32_Vec4_Access.Get (Maxed, (1 .. 32 => 1))
                  = (1.0, 2.0, 3.0, 4.0),
         "32D vector node");
   end Public_Rejections;

   procedure Ownership_And_Callback (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Image           : S.Sparse_Mat :=
        S.Create ((2, 2), (OpenCV.Core.Int16, 4));
      Alias           : S.Sparse_Mat;
      Copy            : S.Sparse_Mat;
      Count           : Natural := 0;
      Callback_Failed : exception;
      procedure Visit
        (Indices : OpenCV.Core.Index_Array;
         Value   : OpenCV.Core.Int16_Vec4.Vector)
      is
         pragma Unreferenced (Indices, Value);
      begin
         Count := Count + 1;
      end Visit;
      procedure Explode
        (Indices : OpenCV.Core.Index_Array;
         Value   : OpenCV.Core.Int16_Vec4.Vector)
      is
         pragma Unreferenced (Indices, Value);
      begin
         Count := Count + 1;
         raise Callback_Failed;
      end Explode;
   begin
      S.Int16_Vec4_Access.Set (Image, (0, 0), (1, 2, 3, 4));
      S.Int16_Vec4_Access.Set (Image, (1, 1), (-1, -2, -3, -4));
      Alias := Image;
      S.Int16_Vec4_Access.Set (Alias, (0, 1), (9, 8, 7, 6));
      Assert
        (S.Int16_Vec4_Access.Get (Image, (0, 1)) = (9, 8, 7, 6)
         and then Image.Stored_Element_Count = 3,
         "shallow vector alias");
      S.Int16_Vec4_Access.For_Each_Stored (Alias, Visit'Access);
      Assert (Count = 3, "alias traversal sees shared nodes");
      Copy := Image.Clone;
      Image.Erase ((0, 0));
      S.Int16_Vec4_Access.Set (Copy, (1, 0), (5, 5, 5, 5));
      Assert
        (not Image.Contains ((0, 0))
         and then S.Int16_Vec4_Access.Get (Copy, (0, 0)) = (1, 2, 3, 4)
         and then not Image.Contains ((1, 0))
         and then Copy.Stored_Element_Count = 4,
         "clone independence");
      Count := 0;
      begin
         S.Int16_Vec4_Access.For_Each_Stored (Image, Explode'Access);
         Assert (False, "callback did not raise");
      exception
         when Callback_Failed =>
            null;
      end;
      Assert (Count = 1, "vector callback stops traversal");
      Count := 0;
      S.Int16_Vec4_Access.For_Each_Stored (Image, Visit'Access);
      Assert
        (Count = 2
         and then S.Int16_Vec4_Access.Get (Image, (1, 1)) = (-1, -2, -3, -4),
         "usable after vector callback exception");
   end Ownership_And_Callback;

   procedure Dense_Vector_Roundtrip (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Integer_Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (4, 5, (OpenCV.Core.Int32, 2));
      Float_Image    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.Float64, 4));
      Half_Image     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float16, 3));
   begin
      Integer_Parent.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Int32_Vec2_Access.Set (Integer_Parent, 2, 3, (-7, 11));
      declare
         View   : constant OpenCV.Core.Mat :=
           Integer_Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
         Sparse : constant S.Sparse_Mat := S.From_Dense (View);
         Dense  : constant OpenCV.Core.Mat := Sparse.To_Dense;
      begin
         Assert
           (Sparse.Shape = (2, 3)
            and then Sparse.Channels = 2
            and then Sparse.Stored_Element_Count = 1
            and then S.Int32_Vec2_Access.Get (Sparse, (1, 2)) = (-7, 11)
            and then OpenCV.Core.Int32_Vec2_Access.Get (Dense, 1, 2)
                     = (-7, 11),
            "non-contiguous integer vector region");
      end;
      Float_Image.Set_To (OpenCV.Make_Scalar (0.0));
      OpenCV.Core.Float64_Vec4_Access.Set
        (Float_Image, 1, 0, (1.5, -2.5, 3.5, -4.5));
      declare
         Sparse : constant S.Sparse_Mat := S.From_Dense (Float_Image);
         Dense  : constant OpenCV.Core.Mat := Sparse.To_Dense;
         Seen   : Natural := 0;
         procedure Visit
           (Indices : OpenCV.Core.Index_Array;
            Value   : OpenCV.Core.Float64_Vec4.Vector) is
         begin
            Assert
              (Indices = (1, 0) and then Value = (1.5, -2.5, 3.5, -4.5),
               "float stored vector");
            Seen := Seen + 1;
         end Visit;
      begin
         S.Float64_Vec4_Access.For_Each_Stored (Sparse, Visit'Access);
         Assert
           (Seen = 1
            and then OpenCV.Core.Float64_Vec4_Access.Get (Dense, 1, 0)
                     = (1.5, -2.5, 3.5, -4.5)
            and then OpenCV.Core.Float64_Vec4_Access.Get (Dense, 0, 0)
                     = (0.0, 0.0, 0.0, 0.0),
            "Float64 vector dense roundtrip");
      end;
      OpenCV.Core.Float16_Vec3_Access.Set
        (Half_Image,
         0,
         0,
         (Half (16#0000#), Half (16#0000#), Half (16#0000#)));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Half_Image,
         0,
         1,
         (Half (16#8000#), Half (16#0001#), Half (16#7E05#)));
      declare
         Sparse : constant S.Sparse_Mat := S.From_Dense (Half_Image);
         Dense  : constant OpenCV.Core.Mat := Sparse.To_Dense;
         Back   : constant OpenCV.Core.Float16_Vec3.Vector :=
           OpenCV.Core.Float16_Vec3_Access.Get (Dense, 0, 1);
         Stored : constant OpenCV.Core.Float16_Vec3.Vector :=
           S.Float16_Vec3_Access.Get (Sparse, (0, 1));
      begin
         Assert
           (not Sparse.Contains ((0, 0))
            and then Sparse.Contains ((0, 1))
            and then Bits_Of (Stored (0)) = 16#8000#
            and then Bits_Of (Stored (1)) = 16#0001#
            and then Bits_Of (Stored (2)) = 16#7E05#
            and then Bits_Of (Back (0)) = 16#8000#
            and then Bits_Of (Back (1)) = 16#0001#
            and then Bits_Of (Back (2)) = 16#7E05#,
            "Float16 vector dense exact bits");
      end;
   end Dense_Vector_Roundtrip;

   procedure Raw_Vector_Safety (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Sizes              : aliased C.C_Int32_Array := (0 => 2, 1 => 3);
      Negative           : aliased C.C_Int32_Array := (0 => -1, 1 => 0);
      Good               : aliased C.C_Int32_Array := (0 => 1, 1 => 2);
      Bad                : aliased C.C_Int32_Array := (0 => 0, 1 => 3);
      Short              : aliased C.C_Int32_Array := (0 => 0, 1 => 0);
      Raw                : aliased C.Sparse_Mat_Handle :=
        C.Null_Sparse_Mat_Handle;
      It                 : aliased C.Sparse_Iterator_Handle :=
        C.Null_Sparse_Iterator_Handle;
      Out2               : aliased C.UInt8_Vec2 := (9, 9);
      In2                : aliased constant C.UInt8_Vec2 := (1, 2);
      Zero2              : aliased constant C.UInt8_Vec2 := (0, 0);
      Nodes              : aliased C.C_UInt64 := 99;
      D, Depth, Channels : aliased C.C_Int32 := 0;
      E, B               : aliased C.C_UInt64 := 0;
      Found              : aliased C.C_UInt8 := 99;
      Indices            : aliased C.C_Int32_Array (0 .. 1) := (others => -1);
      procedure Nodes_Are (Expected : C.C_UInt64; Reason : String) is
      begin
         Assert
           (C.Sparse_Metadata
              (Raw,
               D'Access,
               Depth'Access,
               Channels'Access,
               E'Access,
               B'Access,
               Nodes'Access)
            = C.Success
            and then Nodes = Expected,
            Reason);
      end Nodes_Are;
   begin
      Assert
        (C.Sparse_Create_ND (2, Sizes (0)'Access, 0, 2, Raw'Access)
         = C.Success,
         "raw C2 create");
      Assert
        (C.Sparse_Get_UInt8_Vec2
           (C.Null_Sparse_Mat_Handle, 2, Good (0)'Access, Out2'Access)
         = C.Error_Invalid_Argument
         and then Out2 = (0, 0),
         "null handle zeroes vector");
      Out2 := (9, 9);
      Assert
        (C.Sparse_Get_UInt8_Vec2 (Raw, 2, null, Out2'Access)
         = C.Error_Invalid_Argument
         and then Out2 = (0, 0),
         "null indices");
      Assert
        (C.Sparse_Get_UInt8_Vec2 (Raw, 2, Good (0)'Access, null)
         = C.Error_Invalid_Argument,
         "null get output");
      Assert
        (C.Sparse_Set_UInt8_Vec2 (Raw, 2, Good (0)'Access, null)
         = C.Error_Invalid_Argument,
         "null set input");
      Assert
        (C.Sparse_Set_UInt8_Vec2 (Raw, 1, Good (0)'Access, In2'Access)
         = C.Error_Invalid_Argument
         and then C.Sparse_Set_UInt8_Vec2
                    (Raw, 2, Negative (0)'Access, In2'Access)
                  = C.Error_Invalid_Argument
         and then C.Sparse_Set_UInt8_Vec2 (Raw, 2, Bad (0)'Access, In2'Access)
                  = C.Error_Invalid_Argument
         and then C.Sparse_Set_UInt8_Vec2
                    (Raw, 1, Short (0)'Access, In2'Access)
                  = C.Error_Invalid_Argument,
         "bad raw coordinates");
      Nodes_Are (0, "rejected coordinates create no node");
      Assert
        (C.Sparse_Get_UInt8_Vec2 (Raw, 2, Good (0)'Access, Out2'Access)
         = C.Success
         and then Out2 = (0, 0),
         "missing vector is zero");
      Nodes_Are (0, "missing get creates no node");
      Assert
        (C.Sparse_Set_UInt8_Vec2 (Raw, 2, Good (0)'Access, Zero2'Access)
         = C.Success,
         "explicit zero set");
      Nodes_Are (1, "explicit zero vector is a node");
      Assert
        (C.Sparse_Iterator_Create (Raw, It'Access) = C.Success, "iterator");
      Out2 := (9, 9);
      Found := 99;
      declare
         Signed : aliased C.Int8_Vec2 := (9, 9);
      begin
         Assert
           (C.Sparse_Iterator_Next_Int8_Vec2
              (It, 2, Indices (0)'Access, Signed'Access, Found'Access)
            = C.Error_Invalid_Argument
            and then Signed = (0, 0)
            and then Found = 0,
            "exact depth mismatch does not advance");
      end;
      declare
         Wider : aliased C.UInt8_Vec3 := (9, 9, 9);
      begin
         Found := 99;
         Assert
           (C.Sparse_Iterator_Next_UInt8_Vec3
              (It, 2, Indices (0)'Access, Wider'Access, Found'Access)
            = C.Error_Invalid_Argument
            and then Found = 0
            and then Wider = (0, 0, 0),
            "channel mismatch does not advance");
      end;
      declare
         Lookalike : aliased C.UInt16_Vec2 := (99, 99);
      begin
         Found := 99;
         Assert
           (C.Sparse_Iterator_Next_UInt16_Vec2
              (It, 2, Indices (0)'Access, Lookalike'Access, Found'Access)
            = C.Error_Invalid_Argument
            and then Lookalike = (0, 0)
            and then Found = 0,
            "same-width wrong layout does not advance");
      end;
      Out2 := (9, 9);
      Found := 99;
      Indices := (others => -1);
      Assert
        (C.Sparse_Iterator_Next_UInt8_Vec2
           (It, 2, Indices (0)'Access, Out2'Access, Found'Access)
         = C.Success
         and then Found = 1
         and then Out2 = (0, 0)
         and then Indices = Good,
         "valid next still returns original node");
      Found := 99;
      Assert
        (C.Sparse_Iterator_Next_UInt8_Vec2
           (It, 2, Indices (0)'Access, Out2'Access, Found'Access)
         = C.Success
         and then Found = 0,
         "iterator end");
      Found := 99;
      Assert
        (C.Sparse_Iterator_Next_UInt8_Vec2
           (It, 2, Indices (0)'Access, Out2'Access, Found'Access)
         = C.Success
         and then Found = 0,
         "repeated iterator end");
      C.Sparse_Iterator_Destroy (It);
      C.Sparse_Destroy (Raw);
   end Raw_Vector_Safety;

   procedure Same_Width_Collisions (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Sizes              : aliased C.C_Int32_Array := (0 => 2, 1 => 2);
      Index              : aliased C.C_Int32_Array := (0 => 1, 1 => 0);
      Raw                : aliased C.Sparse_Mat_Handle :=
        C.Null_Sparse_Mat_Handle;
      It                 : aliased C.Sparse_Iterator_Handle :=
        C.Null_Sparse_Iterator_Handle;
      Indices            : aliased C.C_Int32_Array := (0 => -1, 1 => -1);
      Found              : aliased C.C_UInt8 := 99;
      Nodes              : aliased C.C_UInt64 := 0;
      D, Depth, Channels : aliased C.C_Int32 := 0;
      E, B               : aliased C.C_UInt64 := 0;
      procedure Make (Kind, Count : C.C_Int32) is
      begin
         C.Sparse_Destroy (Raw);
         Raw := C.Null_Sparse_Mat_Handle;
         Assert
           (C.Sparse_Create_ND (2, Sizes (0)'Access, Kind, Count, Raw'Access)
            = C.Success,
            "collision fixture");
      end Make;
      procedure No_Node (Reason : String) is
      begin
         Assert
           (C.Sparse_Metadata
              (Raw,
               D'Access,
               Depth'Access,
               Channels'Access,
               E'Access,
               B'Access,
               Nodes'Access)
            = C.Success
            and then Nodes = 0,
            Reason);
      end No_Node;
   begin
      Make (2, 2);
      declare
         Wrong : aliased C.UInt8_Vec4 := (9, 8, 7, 6);
         Input : aliased constant C.UInt8_Vec4 := (1, 2, 3, 4);
      begin
         Assert
           (C.Sparse_Get_UInt8_Vec4 (Raw, 2, Index (0)'Access, Wrong'Access)
            = C.Error_Invalid_Argument
            and then Wrong = (0, 0, 0, 0)
            and then C.Sparse_Set_UInt8_Vec4
                       (Raw, 2, Index (0)'Access, Input'Access)
                     = C.Error_Invalid_Argument,
            "UInt8 C4 versus UInt16 C2");
      end;
      No_Node ("UInt8 C4 write");
      Make (2, 2);
      declare
         Wrong : aliased C.Float16_Vec2 := (99, 99);
         Input : aliased constant C.Float16_Vec2 := (1, 2);
      begin
         Assert
           (C.Sparse_Get_Float16_Vec2 (Raw, 2, Index (0)'Access, Wrong'Access)
            = C.Error_Invalid_Argument
            and then Wrong = (0, 0)
            and then C.Sparse_Set_Float16_Vec2
                       (Raw, 2, Index (0)'Access, Input'Access)
                     = C.Error_Invalid_Argument,
            "Float16 C2 versus UInt16 C2");
      end;
      No_Node ("Float16 C2 write");
      Make (4, 1);
      declare
         Wrong : aliased C.UInt16_Vec2 := (99, 99);
         Input : aliased constant C.UInt16_Vec2 := (1, 2);
      begin
         Assert
           (C.Sparse_Get_UInt16_Vec2 (Raw, 2, Index (0)'Access, Wrong'Access)
            = C.Error_Invalid_Argument
            and then Wrong = (0, 0)
            and then C.Sparse_Set_UInt16_Vec2
                       (Raw, 2, Index (0)'Access, Input'Access)
                     = C.Error_Invalid_Argument,
            "UInt16 C2 versus Int32 C1");
      end;
      No_Node ("UInt16 C2 write");
      Make (4, 2);
      declare
         Wrong : aliased C.Int16_Vec4 := (9, 8, 7, 6);
         Input : aliased constant C.Int16_Vec4 := (1, 2, 3, 4);
      begin
         Assert
           (C.Sparse_Get_Int16_Vec4 (Raw, 2, Index (0)'Access, Wrong'Access)
            = C.Error_Invalid_Argument
            and then Wrong = (0, 0, 0, 0)
            and then C.Sparse_Set_Int16_Vec4
                       (Raw, 2, Index (0)'Access, Input'Access)
                     = C.Error_Invalid_Argument,
            "Int16 C4 versus Int32 C2");
      end;
      No_Node ("Int16 C4 write");
      Make (6, 1);
      declare
         Wrong : aliased C.Float32_Vec2 := (9.0, 8.0);
         Input : aliased constant C.Float32_Vec2 := (1.0, 2.0);
      begin
         Assert
           (C.Sparse_Get_Float32_Vec2 (Raw, 2, Index (0)'Access, Wrong'Access)
            = C.Error_Invalid_Argument
            and then Wrong = (0.0, 0.0)
            and then C.Sparse_Set_Float32_Vec2
                       (Raw, 2, Index (0)'Access, Input'Access)
                     = C.Error_Invalid_Argument,
            "Float32 C2 versus Float64 C1");
      end;
      No_Node ("Float32 C2 write");
      Make (6, 2);
      declare
         Stored : aliased constant C.Float64_Vec2 := (3.0, 4.0);
         Wrong  : aliased C.Float32_Vec4 := (9.0, 8.0, 7.0, 6.0);
         Back   : aliased C.Float64_Vec2 := (0.0, 0.0);
      begin
         Assert
           (C.Sparse_Set_Float64_Vec2 (Raw, 2, Index (0)'Access, Stored'Access)
            = C.Success,
            "store Float64 C2");
         Assert
           (C.Sparse_Iterator_Create (Raw, It'Access) = C.Success,
            "collision iterator");
         Assert
           (C.Sparse_Iterator_Next_Float32_Vec4
              (It, 2, Indices (0)'Access, Wrong'Access, Found'Access)
            = C.Error_Invalid_Argument
            and then Wrong = (0.0, 0.0, 0.0, 0.0)
            and then Found = 0,
            "Float32 C4 versus Float64 C2 does not advance");
         Assert
           (C.Sparse_Iterator_Next_Float64_Vec2
              (It, 2, Indices (0)'Access, Back'Access, Found'Access)
            = C.Success
            and then Found = 1
            and then Back = Stored
            and then Indices = Index,
            "rejected iterator still yields original vector");
      end;
      C.Sparse_Iterator_Destroy (It);
      C.Sparse_Destroy (Raw);
   end Same_Width_Collisions;

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create ("Sparse vector all 24 layouts", All_Layouts'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse explicit zero vectors", Explicit_Zero_Vectors'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse Float16 vector exact bits", Exact_Float16_Vectors'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse vector public bounds and dimensions",
            Public_Rejections'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse vector alias clone and callback cleanup",
            Ownership_And_Callback'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse vector dense interoperability",
            Dense_Vector_Roundtrip'Access));
      Result.Add_Test
        (Caller.Create ("Sparse raw vector safety", Raw_Vector_Safety'Access));
      Result.Add_Test
        (Caller.Create
           ("Sparse same-byte-width vector collisions",
            Same_Width_Collisions'Access));
      return Result'Access;
   end Suite;
end Sparse_Vector_Tests;
