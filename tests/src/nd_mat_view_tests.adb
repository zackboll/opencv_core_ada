with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with Module_Bridge_Probe;
with ND_Mat_View_Checks;
with Read_Only_Mat_View_Checks;
with ND_Mat_View_Tests.Raw_ABI;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float16_Buffer_Access;
with OpenCV.Core.Float16_Mat_View;
with OpenCV.Core.Float16_Vec3;
with OpenCV.Core.Float16_Vec3_Access;
with OpenCV.Core.Float16_Vec3_Buffer_Access;
with OpenCV.Core.Float16_Vec3_Mat_View;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Buffer_Access;
with OpenCV.Core.Float32_Mat_View;
with OpenCV.Core.Float32_Vec2;
with OpenCV.Core.Float32_Vec2_Access;
with OpenCV.Core.Float32_Vec2_Buffer_Access;
with OpenCV.Core.Float32_Vec2_Mat_View;
with OpenCV.Core.Float32_Vec3;
with OpenCV.Core.Float32_Vec3_Access;
with OpenCV.Core.Float32_Vec3_Buffer_Access;
with OpenCV.Core.Float32_Vec3_Mat_View;
with OpenCV.Core.Float32_Vec4;
with OpenCV.Core.UInt8_Vec4;
with OpenCV.Core.UInt8_Vec4_Access;
with OpenCV.Core.UInt8_Vec4_Buffer_Access;
with OpenCV.Core.UInt8_Vec4_Mat_View;
with OpenCV.Core.Float32_Vec4_Access;
with OpenCV.Core.Float32_Vec4_Buffer_Access;
with OpenCV.Core.Float32_Vec4_Mat_View;
with OpenCV.Core.Float64_Access;
with OpenCV.Core.Float64_Buffer_Access;
with OpenCV.Core.Float64_Mat_View;
with OpenCV.Core.Float64_Vec2;
with OpenCV.Core.Float64_Vec2_Access;
with OpenCV.Core.Float64_Vec2_Buffer_Access;
with OpenCV.Core.Float64_Vec2_Mat_View;
with OpenCV.Core.Float64_Vec3;
with OpenCV.Core.Float64_Vec3_Access;
with OpenCV.Core.Float64_Vec3_Buffer_Access;
with OpenCV.Core.Float64_Vec3_Mat_View;
with OpenCV.Core.Float64_Vec4;
with OpenCV.Core.Float64_Vec4_Access;
with OpenCV.Core.Float64_Vec4_Buffer_Access;
with OpenCV.Core.Float64_Vec4_Mat_View;
with OpenCV.Core.Int16_Access;
with OpenCV.Core.Int16_Buffer_Access;
with OpenCV.Core.Int16_Mat_View;
with OpenCV.Core.Int32_Access;
with OpenCV.Core.Int32_Buffer_Access;
with OpenCV.Core.Int32_Mat_View;
with OpenCV.Core.Int8_Access;
with OpenCV.Core.Int8_Buffer_Access;
with OpenCV.Core.Int8_Mat_View;
with OpenCV.Core.Module_Interop;
with OpenCV.Core.UInt16_Access;
with OpenCV.Core.UInt16_Buffer_Access;
with OpenCV.Core.UInt16_Mat_View;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Buffer_Access;
with OpenCV.Core.UInt8_Mat_View;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with OpenCV.Core.UInt8_Vec3_Buffer_Access;
with OpenCV.Core.UInt8_Vec3_Mat_View;

package body ND_Mat_View_Tests is

   use type Interfaces.Unsigned_16;
   use type OpenCV.Float32_Value;
   use type OpenCV.Float64_Value;
   use type OpenCV.Int32_Value;
   use type OpenCV.UInt8_Value;
   use type OpenCV.Size_Coordinate;
   use type OpenCV.Core.Float64_Vec2.Vector;
   use type OpenCV.Core.Float64_Vec3.Vector;
   use type OpenCV.Core.Float64_Vec4.Vector;

   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   --  Value generators. Offsets 0 .. 23 and 100 .. 102 are distinct.

   function F16
     (Bits : Interfaces.Unsigned_16) return OpenCV.Core.Float16_Value
   renames OpenCV.Core.Float16_From_Bits;

   --  1.0 + 2**-40 is not representable in Float32.
   Fine : constant OpenCV.Float64_Value := 2.0**(-40);

   function UInt8_At (O : Natural) return OpenCV.UInt8_Value
   is (OpenCV.UInt8_Value (O + 1));

   function Int8_At (O : Natural) return OpenCV.Int8_Value
   is (OpenCV.Int8_Value (O - 120));

   function UInt16_At (O : Natural) return OpenCV.UInt16_Value
   is (OpenCV.UInt16_Value (65_535 - O));

   function Int16_At (O : Natural) return OpenCV.Int16_Value
   is (OpenCV.Int16_Value (Integer (O) - 32_768));

   function Int32_At (O : Natural) return OpenCV.Int32_Value
   is (case O is
         when 100    => OpenCV.Int32_Value'First,
         when 101    => OpenCV.Int32_Value'Last,
         when others => OpenCV.Int32_Value (O) * (-1_000) - 7);

   --  Exact binary16 patterns: signalling NaN payload, smallest and
   --  largest subnormal, and negative zero. A Float32 round trip would
   --  quiet the signalling NaN, and value comparison would equate zeros.
   --  Offsets 0 and 23 are the first and last caller elements; 100 .. 102
   --  are written through N-D Set, caller Data, and a nested buffer.
   function Float16_At (O : Natural) return OpenCV.Core.Float16_Value
   is (case O is
         when 0      => F16 (16#03FF#),
         when 23     => F16 (16#7C01#),
         when 100    => F16 (16#8000#),
         when 101    => F16 (16#0001#),
         when 102    => F16 (16#7C03#),
         when others => F16 (16#3C00# + Interfaces.Unsigned_16 (O)));

   function Float32_At (O : Natural) return OpenCV.Float32_Value
   is (OpenCV.Float32_Value (O) * 0.5 - 3.25);

   --  Every value is 1.0 + k * 2**-40 with k >= 1, which needs more than
   --  Float32's 24-bit significand, so any narrowing would be detected.
   function Float64_At (O : Natural) return OpenCV.Float64_Value
   is (1.0 + OpenCV.Float64_Value (O + 1) * Fine);

   function F32_Vec2_At (O : Natural) return OpenCV.Core.Float32_Vec2.Vector
   is (Float32_At (O), -Float32_At (O) - 100.0);

   function F64_Vec2_At (O : Natural) return OpenCV.Core.Float64_Vec2.Vector
   is (Float64_At (O), -Float64_At (O));

   function U8_Vec3_At (O : Natural) return OpenCV.Core.UInt8_Vec3.Vector
   is (OpenCV.UInt8_Value (O),
       OpenCV.UInt8_Value (O + 50),
       OpenCV.UInt8_Value (O + 150));

   --  Component 2 carries a distinct signalling-NaN payload per element and
   --  components 0 / 1 carry subnormal and negative-zero-adjacent patterns.
   function F16_Vec3_At (O : Natural) return OpenCV.Core.Float16_Vec3.Vector
   is (F16 (16#0001# + Interfaces.Unsigned_16 (O)),
       F16 (16#8000# + Interfaces.Unsigned_16 (O)),
       F16 (16#7C01# + Interfaces.Unsigned_16 (O)));

   function F32_Vec3_At (O : Natural) return OpenCV.Core.Float32_Vec3.Vector
   is (Float32_At (O), Float32_At (O) + 0.25, -Float32_At (O));

   function F64_Vec3_At (O : Natural) return OpenCV.Core.Float64_Vec3.Vector
   is (Float64_At (O), -Float64_At (O), Float64_At (O) * 3.0);

   function U8_Vec4_At (O : Natural) return OpenCV.Core.UInt8_Vec4.Vector
   is (OpenCV.UInt8_Value (O),
       OpenCV.UInt8_Value (O + 50),
       OpenCV.UInt8_Value (O + 150),
       OpenCV.UInt8_Value (255 - O));

   function F32_Vec4_At (O : Natural) return OpenCV.Core.Float32_Vec4.Vector
   is (Float32_At (O), 1.0, -Float32_At (O), 2.0);

   function F64_Vec4_At (O : Natural) return OpenCV.Core.Float64_Vec4.Vector
   is (Float64_At (O),
       -2.0 - OpenCV.Float64_Value (O) * Fine,
       3.0 + 2.0**(-44),
       -Float64_At (O));

   package RO_U8 is new
     Read_Only_Mat_View_Checks
       (OpenCV.UInt8_Value,
        OpenCV.Core.UInt8_Mat_View.Buffer_Array,
        OpenCV.Core.UInt8_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 1),
        "UInt8 C1",
        UInt8_At,
        OpenCV.Core.UInt8_Access.Get,
        OpenCV.Core.UInt8_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.UInt8_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.UInt8_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.UInt8_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.UInt8_Buffer_Access.With_Read_Only_Buffer);
   package RO_I8 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Int8_Value,
        OpenCV.Core.Int8_Mat_View.Buffer_Array,
        OpenCV.Core.Int8_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int8, 1),
        "Int8 C1",
        Int8_At,
        OpenCV.Core.Int8_Access.Get,
        OpenCV.Core.Int8_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Int8_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Int8_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Int8_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Int8_Buffer_Access.With_Read_Only_Buffer);
   package RO_U16 is new
     Read_Only_Mat_View_Checks
       (OpenCV.UInt16_Value,
        OpenCV.Core.UInt16_Mat_View.Buffer_Array,
        OpenCV.Core.UInt16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt16, 1),
        "UInt16 C1",
        UInt16_At,
        OpenCV.Core.UInt16_Access.Get,
        OpenCV.Core.UInt16_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.UInt16_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.UInt16_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.UInt16_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer);
   package RO_I16 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Int16_Value,
        OpenCV.Core.Int16_Mat_View.Buffer_Array,
        OpenCV.Core.Int16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int16, 1),
        "Int16 C1",
        Int16_At,
        OpenCV.Core.Int16_Access.Get,
        OpenCV.Core.Int16_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Int16_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Int16_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Int16_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer);
   package RO_I32 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Int32_Value,
        OpenCV.Core.Int32_Mat_View.Buffer_Array,
        OpenCV.Core.Int32_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int32, 1),
        "Int32 C1",
        Int32_At,
        OpenCV.Core.Int32_Access.Get,
        OpenCV.Core.Int32_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Int32_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Int32_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Int32_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer);
   package RO_F16 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Core.Float16_Value,
        OpenCV.Core.Float16_Mat_View.Buffer_Array,
        OpenCV.Core.Float16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float16, 1),
        "Float16 C1",
        Float16_At,
        OpenCV.Core.Float16_Access.Get,
        OpenCV.Core.Float16_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float16_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float16_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float16_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer);
   package RO_F32 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Float32_Value,
        OpenCV.Core.Float32_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 1),
        "Float32 C1",
        Float32_At,
        OpenCV.Core.Float32_Access.Get,
        OpenCV.Core.Float32_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float32_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float32_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float32_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float32_Buffer_Access.With_Read_Only_Buffer);
   package RO_F64 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Float64_Value,
        OpenCV.Core.Float64_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 1),
        "Float64 C1",
        Float64_At,
        OpenCV.Core.Float64_Access.Get,
        OpenCV.Core.Float64_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float64_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float64_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float64_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer);
   package RO_F32V2 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Core.Float32_Vec2.Vector,
        OpenCV.Core.Float32_Vec2_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 2),
        "Float32 C2",
        F32_Vec2_At,
        OpenCV.Core.Float32_Vec2_Access.Get,
        OpenCV.Core.Float32_Vec2_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float32_Vec2_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float32_Vec2_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float32_Vec2_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float32_Vec2_Buffer_Access.With_Read_Only_Buffer);
   package RO_F64V2 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Core.Float64_Vec2.Vector,
        OpenCV.Core.Float64_Vec2_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 2),
        "Float64 C2",
        F64_Vec2_At,
        OpenCV.Core.Float64_Vec2_Access.Get,
        OpenCV.Core.Float64_Vec2_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float64_Vec2_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float64_Vec2_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float64_Vec2_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float64_Vec2_Buffer_Access.With_Read_Only_Buffer);
   package RO_U8V3 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Core.UInt8_Vec3.Vector,
        OpenCV.Core.UInt8_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.UInt8_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 3),
        "UInt8 C3",
        U8_Vec3_At,
        OpenCV.Core.UInt8_Vec3_Access.Get,
        OpenCV.Core.UInt8_Vec3_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.UInt8_Vec3_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.UInt8_Vec3_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.UInt8_Vec3_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Read_Only_Buffer);
   package RO_F16V3 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Core.Float16_Vec3.Vector,
        OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float16, 3),
        "Float16 C3",
        F16_Vec3_At,
        OpenCV.Core.Float16_Vec3_Access.Get,
        OpenCV.Core.Float16_Vec3_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float16_Vec3_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float16_Vec3_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float16_Vec3_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer);
   package RO_F32V3 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Core.Float32_Vec3.Vector,
        OpenCV.Core.Float32_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 3),
        "Float32 C3",
        F32_Vec3_At,
        OpenCV.Core.Float32_Vec3_Access.Get,
        OpenCV.Core.Float32_Vec3_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float32_Vec3_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float32_Vec3_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float32_Vec3_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float32_Vec3_Buffer_Access.With_Read_Only_Buffer);
   package RO_F64V3 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Core.Float64_Vec3.Vector,
        OpenCV.Core.Float64_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 3),
        "Float64 C3",
        F64_Vec3_At,
        OpenCV.Core.Float64_Vec3_Access.Get,
        OpenCV.Core.Float64_Vec3_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float64_Vec3_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float64_Vec3_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float64_Vec3_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float64_Vec3_Buffer_Access.With_Read_Only_Buffer);
   package RO_U8V4 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Core.UInt8_Vec4.Vector,
        OpenCV.Core.UInt8_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.UInt8_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 4),
        "UInt8 C4",
        U8_Vec4_At,
        OpenCV.Core.UInt8_Vec4_Access.Get,
        OpenCV.Core.UInt8_Vec4_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.UInt8_Vec4_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.UInt8_Vec4_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.UInt8_Vec4_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.UInt8_Vec4_Buffer_Access.With_Read_Only_Buffer);
   package RO_F32V4 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Core.Float32_Vec4.Vector,
        OpenCV.Core.Float32_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 4),
        "Float32 C4",
        F32_Vec4_At,
        OpenCV.Core.Float32_Vec4_Access.Get,
        OpenCV.Core.Float32_Vec4_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float32_Vec4_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float32_Vec4_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float32_Vec4_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float32_Vec4_Buffer_Access.With_Read_Only_Buffer);
   package RO_F64V4 is new
     Read_Only_Mat_View_Checks
       (OpenCV.Core.Float64_Vec4.Vector,
        OpenCV.Core.Float64_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 4),
        "Float64 C4",
        F64_Vec4_At,
        OpenCV.Core.Float64_Vec4_Access.Get,
        OpenCV.Core.Float64_Vec4_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float64_Vec4_Mat_View.With_Read_Only_Mat_View,
        OpenCV.Core.Float64_Vec4_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float64_Vec4_Mat_View.With_Read_Only_Strided_Mat_View,
        OpenCV.Core.Float64_Vec4_Buffer_Access.With_Read_Only_Buffer);

   --  One instance per typed Mat_View package.

   package UInt8_Checks is new
     ND_Mat_View_Checks
       (OpenCV.UInt8_Value,
        OpenCV.Core.UInt8_Mat_View.Buffer_Array,
        OpenCV.Core.UInt8_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 1),
        "UInt8 C1",
        UInt8_At,
        OpenCV.Core.UInt8_Access.Get,
        OpenCV.Core.UInt8_Access.Set,
        OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt8_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt8_Buffer_Access.With_Writable_Buffer);

   package Int8_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Int8_Value,
        OpenCV.Core.Int8_Mat_View.Buffer_Array,
        OpenCV.Core.Int8_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int8, 1),
        "Int8 C1",
        Int8_At,
        OpenCV.Core.Int8_Access.Get,
        OpenCV.Core.Int8_Access.Set,
        OpenCV.Core.Int8_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int8_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int8_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int8_Buffer_Access.With_Writable_Buffer);

   package UInt16_Checks is new
     ND_Mat_View_Checks
       (OpenCV.UInt16_Value,
        OpenCV.Core.UInt16_Mat_View.Buffer_Array,
        OpenCV.Core.UInt16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt16, 1),
        "UInt16 C1",
        UInt16_At,
        OpenCV.Core.UInt16_Access.Get,
        OpenCV.Core.UInt16_Access.Set,
        OpenCV.Core.UInt16_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt16_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt16_Buffer_Access.With_Writable_Buffer);

   package Int16_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Int16_Value,
        OpenCV.Core.Int16_Mat_View.Buffer_Array,
        OpenCV.Core.Int16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int16, 1),
        "Int16 C1",
        Int16_At,
        OpenCV.Core.Int16_Access.Get,
        OpenCV.Core.Int16_Access.Set,
        OpenCV.Core.Int16_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int16_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int16_Buffer_Access.With_Writable_Buffer);

   package Int32_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Int32_Value,
        OpenCV.Core.Int32_Mat_View.Buffer_Array,
        OpenCV.Core.Int32_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int32, 1),
        "Int32 C1",
        Int32_At,
        OpenCV.Core.Int32_Access.Get,
        OpenCV.Core.Int32_Access.Set,
        OpenCV.Core.Int32_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int32_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer);

   package Float16_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Core.Float16_Value,
        OpenCV.Core.Float16_Mat_View.Buffer_Array,
        OpenCV.Core.Float16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float16, 1),
        "Float16 C1",
        Float16_At,
        OpenCV.Core.Float16_Access.Get,
        OpenCV.Core.Float16_Access.Set,
        OpenCV.Core.Float16_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float16_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer);

   package Float32_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Float32_Value,
        OpenCV.Core.Float32_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 1),
        "Float32 C1",
        Float32_At,
        OpenCV.Core.Float32_Access.Get,
        OpenCV.Core.Float32_Access.Set,
        OpenCV.Core.Float32_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Buffer_Access.With_Writable_Buffer);

   package Float64_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Float64_Value,
        OpenCV.Core.Float64_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 1),
        "Float64 C1",
        Float64_At,
        OpenCV.Core.Float64_Access.Get,
        OpenCV.Core.Float64_Access.Set,
        OpenCV.Core.Float64_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Buffer_Access.With_Writable_Buffer);

   package F32_Vec2_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Core.Float32_Vec2.Vector,
        OpenCV.Core.Float32_Vec2_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 2),
        "Float32 C2",
        F32_Vec2_At,
        OpenCV.Core.Float32_Vec2_Access.Get,
        OpenCV.Core.Float32_Vec2_Access.Set,
        OpenCV.Core.Float32_Vec2_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Vec2_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Vec2_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Vec2_Buffer_Access.With_Writable_Buffer);

   package F64_Vec2_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Core.Float64_Vec2.Vector,
        OpenCV.Core.Float64_Vec2_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 2),
        "Float64 C2",
        F64_Vec2_At,
        OpenCV.Core.Float64_Vec2_Access.Get,
        OpenCV.Core.Float64_Vec2_Access.Set,
        OpenCV.Core.Float64_Vec2_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Vec2_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Vec2_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Vec2_Buffer_Access.With_Writable_Buffer);

   package U8_Vec3_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Core.UInt8_Vec3.Vector,
        OpenCV.Core.UInt8_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.UInt8_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 3),
        "UInt8 C3",
        U8_Vec3_At,
        OpenCV.Core.UInt8_Vec3_Access.Get,
        OpenCV.Core.UInt8_Vec3_Access.Set,
        OpenCV.Core.UInt8_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt8_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Writable_Buffer);

   package F16_Vec3_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Core.Float16_Vec3.Vector,
        OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float16, 3),
        "Float16 C3",
        F16_Vec3_At,
        OpenCV.Core.Float16_Vec3_Access.Get,
        OpenCV.Core.Float16_Vec3_Access.Set,
        OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float16_Vec3_Buffer_Access.With_Writable_Buffer);

   package F32_Vec3_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Core.Float32_Vec3.Vector,
        OpenCV.Core.Float32_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 3),
        "Float32 C3",
        F32_Vec3_At,
        OpenCV.Core.Float32_Vec3_Access.Get,
        OpenCV.Core.Float32_Vec3_Access.Set,
        OpenCV.Core.Float32_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Vec3_Buffer_Access.With_Writable_Buffer);

   package F64_Vec3_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Core.Float64_Vec3.Vector,
        OpenCV.Core.Float64_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 3),
        "Float64 C3",
        F64_Vec3_At,
        OpenCV.Core.Float64_Vec3_Access.Get,
        OpenCV.Core.Float64_Vec3_Access.Set,
        OpenCV.Core.Float64_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Vec3_Buffer_Access.With_Writable_Buffer);

   package U8_Vec4_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Core.UInt8_Vec4.Vector,
        OpenCV.Core.UInt8_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.UInt8_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 4),
        "UInt8 C4",
        U8_Vec4_At,
        OpenCV.Core.UInt8_Vec4_Access.Get,
        OpenCV.Core.UInt8_Vec4_Access.Set,
        OpenCV.Core.UInt8_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt8_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt8_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt8_Vec4_Buffer_Access.With_Writable_Buffer);

   package F32_Vec4_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Core.Float32_Vec4.Vector,
        OpenCV.Core.Float32_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 4),
        "Float32 C4",
        F32_Vec4_At,
        OpenCV.Core.Float32_Vec4_Access.Get,
        OpenCV.Core.Float32_Vec4_Access.Set,
        OpenCV.Core.Float32_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Vec4_Buffer_Access.With_Writable_Buffer);

   package F64_Vec4_Checks is new
     ND_Mat_View_Checks
       (OpenCV.Core.Float64_Vec4.Vector,
        OpenCV.Core.Float64_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 4),
        "Float64 C4",
        F64_Vec4_At,
        OpenCV.Core.Float64_Vec4_Access.Get,
        OpenCV.Core.Float64_Vec4_Access.Set,
        OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Vec4_Buffer_Access.With_Writable_Buffer);

   procedure Raw_ABI_Rejects_Malformed_Requests (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check_Rejections;
   end Raw_ABI_Rejects_Malformed_Requests;

   procedure Raw_ABI_Creates_Packed_Views (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check_Valid_Views;
   end Raw_ABI_Creates_Packed_Views;

   procedure Raw_ABI_Marks_Temporary_View (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check_Temporary_View;
   end Raw_ABI_Marks_Temporary_View;

   procedure C1_Volumes_Alias_Caller_Storage (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      UInt8_Checks.Check_Volume;
      Int8_Checks.Check_Volume;
      UInt16_Checks.Check_Volume;
      Int16_Checks.Check_Volume;
      Int32_Checks.Check_Volume;
      Float16_Checks.Check_Volume;
      Float32_Checks.Check_Volume;
      Float64_Checks.Check_Volume;
   end C1_Volumes_Alias_Caller_Storage;

   procedure Vector_Volumes_Alias_Caller_Storage (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      F32_Vec2_Checks.Check_Volume;
      F64_Vec2_Checks.Check_Volume;
      U8_Vec3_Checks.Check_Volume;
      F16_Vec3_Checks.Check_Volume;
      F32_Vec3_Checks.Check_Volume;
      F64_Vec3_Checks.Check_Volume;
      U8_Vec4_Checks.Check_Volume;
      F32_Vec4_Checks.Check_Volume;
      F64_Vec4_Checks.Check_Volume;
   end Vector_Volumes_Alias_Caller_Storage;

   procedure Two_Dimensional_Shape_Matches_Rows_Columns (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
   begin
      UInt8_Checks.Check_Two_Dimensional_Shape;
      Int8_Checks.Check_Two_Dimensional_Shape;
      UInt16_Checks.Check_Two_Dimensional_Shape;
      Int16_Checks.Check_Two_Dimensional_Shape;
      Int32_Checks.Check_Two_Dimensional_Shape;
      Float16_Checks.Check_Two_Dimensional_Shape;
      Float32_Checks.Check_Two_Dimensional_Shape;
      Float64_Checks.Check_Two_Dimensional_Shape;
      F32_Vec2_Checks.Check_Two_Dimensional_Shape;
      F64_Vec2_Checks.Check_Two_Dimensional_Shape;
      U8_Vec3_Checks.Check_Two_Dimensional_Shape;
      F16_Vec3_Checks.Check_Two_Dimensional_Shape;
      F32_Vec3_Checks.Check_Two_Dimensional_Shape;
      F64_Vec3_Checks.Check_Two_Dimensional_Shape;
      U8_Vec4_Checks.Check_Two_Dimensional_Shape;
      F32_Vec4_Checks.Check_Two_Dimensional_Shape;
      F64_Vec4_Checks.Check_Two_Dimensional_Shape;
   end Two_Dimensional_Shape_Matches_Rows_Columns;

   procedure Views_Reject_Shallow_Escape_And_Clone (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      UInt8_Checks.Check_No_Escape_And_Clone;
      Int8_Checks.Check_No_Escape_And_Clone;
      UInt16_Checks.Check_No_Escape_And_Clone;
      Int16_Checks.Check_No_Escape_And_Clone;
      Int32_Checks.Check_No_Escape_And_Clone;
      Float16_Checks.Check_No_Escape_And_Clone;
      Float32_Checks.Check_No_Escape_And_Clone;
      Float64_Checks.Check_No_Escape_And_Clone;
      F32_Vec2_Checks.Check_No_Escape_And_Clone;
      F64_Vec2_Checks.Check_No_Escape_And_Clone;
      U8_Vec3_Checks.Check_No_Escape_And_Clone;
      F16_Vec3_Checks.Check_No_Escape_And_Clone;
      F32_Vec3_Checks.Check_No_Escape_And_Clone;
      F64_Vec3_Checks.Check_No_Escape_And_Clone;
      U8_Vec4_Checks.Check_No_Escape_And_Clone;
      F32_Vec4_Checks.Check_No_Escape_And_Clone;
      F64_Vec4_Checks.Check_No_Escape_And_Clone;
   end Views_Reject_Shallow_Escape_And_Clone;

   function Bits
     (Value : OpenCV.Core.Float16_Value) return Interfaces.Unsigned_16
   renames OpenCV.Core.Float16_Bits;

   procedure Float16_Views_Preserve_Exact_Bits (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Patterns : constant array (0 .. 3) of Interfaces.Unsigned_16 :=
        (16#7C01#, 16#8000#, 16#0001#, 16#03FF#);
      Scalars  : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (5 .. 12 => F16 (16#3C00#));
      Pixels   : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (3 .. 10 => (others => F16 (16#3C00#)));
      Invoked  : Natural := 0;

      --  Shape (2, 4, 1): zero-based (I, J, 0) is flat offset I * 4 + J.
      procedure Scalar_Process (Image : in out OpenCV.Core.Mat) is
         procedure Inspect
           (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
         begin
            for P in Patterns'Range loop
               AUnit.Assertions.Assert
                 (Bits (Data (P)) = Patterns (P)
                  and then Bits (Data (4 + P)) = Patterns (3 - P),
                  "Float16 C1 N-D buffer must expose exact binary16 bits");
            end loop;
         end Inspect;
      begin
         Invoked := Invoked + 1;
         for P in Patterns'Range loop
            AUnit.Assertions.Assert
              (Bits
                 (OpenCV.Core.Float16_Access.Get
                    (Image, (0, OpenCV.Size_Coordinate (P), 0)))
               = Patterns (P),
               "Float16 C1 N-D Get must read exact caller bits");
            OpenCV.Core.Float16_Access.Set
              (Image,
               (1, OpenCV.Size_Coordinate (P), 0),
               F16 (Patterns (3 - P)));
         end loop;
         OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect'Access);
      end Scalar_Process;

      --  Shape (2, 2, 2): (0, 0, 0) is Pixels (3) and (1, 1, 1) is
      --  Pixels (3 + 7) = Pixels (10).
      procedure Pixel_Process (Image : in out OpenCV.Core.Mat) is
         Value : constant OpenCV.Core.Float16_Vec3.Vector :=
           OpenCV.Core.Float16_Vec3_Access.Get (Image, (0, 0, 0));
      begin
         Invoked := Invoked + 1;
         AUnit.Assertions.Assert
           (Bits (Value (0)) = 16#7C01#
            and then Bits (Value (1)) = 16#8000#
            and then Bits (Value (2)) = 16#0001#,
            "Float16 C3 N-D Get must read exact caller bits");
         OpenCV.Core.Float16_Vec3_Access.Set
           (Image,
            (1, 1, 1),
            (F16 (16#03FF#), F16 (16#7C01#), F16 (16#8000#)));
      end Pixel_Process;
   begin
      Scalars := (others => F16 (16#3C00#));
      for P in Patterns'Range loop
         Scalars (Scalars'First + P) := F16 (Patterns (P));
      end loop;
      OpenCV.Core.Float16_Mat_View.With_Writable_Mat_View
        (Scalars, (2, 4, 1), Scalar_Process'Access);
      for P in Patterns'Range loop
         AUnit.Assertions.Assert
           (Bits (Scalars (Scalars'First + P)) = Patterns (P)
            and then Bits (Scalars (Scalars'First + 4 + P)) = Patterns (3 - P),
            "Float16 C1 N-D Set must store exact bits in caller Data");
      end loop;

      Pixels := (others => (others => F16 (16#3C00#)));
      Pixels (3) := (F16 (16#7C01#), F16 (16#8000#), F16 (16#0001#));
      OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Mat_View
        (Pixels, (2, 2, 2), Pixel_Process'Access);
      AUnit.Assertions.Assert
        (Bits (Pixels (10) (0)) = 16#03FF#
         and then Bits (Pixels (10) (1)) = 16#7C01#
         and then Bits (Pixels (10) (2)) = 16#8000#
         and then Bits (Pixels (3) (0)) = 16#7C01#,
         "Float16 C3 N-D Set must store exact bits in caller Data");
      AUnit.Assertions.Assert
        (Invoked = 2, "both Float16 N-D view callbacks must be invoked");
   end Float16_Views_Preserve_Exact_Bits;

   procedure Float64_Views_Do_Not_Narrow (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Precise : constant OpenCV.Float64_Value := 1.0 + 2.0**(-40);
      Other   : constant OpenCV.Float64_Value := -3.0 - 2.0**(-45);
      --  A variable keeps the Float32 probe below out of static folding.
      Probe   : OpenCV.Float64_Value := Precise;
      C1      : aliased OpenCV.Core.Float64_Mat_View.Buffer_Array :=
        (0 .. 7 => 0.0);
      C2      : aliased OpenCV.Core.Float64_Vec2_Mat_View.Buffer_Array :=
        (1 .. 8 => (others => 0.0));
      C3      : aliased OpenCV.Core.Float64_Vec3_Mat_View.Buffer_Array :=
        (2 .. 9 => (others => 0.0));
      C4      : aliased OpenCV.Core.Float64_Vec4_Mat_View.Buffer_Array :=
        (3 .. 10 => (others => 0.0));
      Count   : Natural := 0;

      subtype F64_Buffer is OpenCV.Core.Float64_Buffer_Access.Buffer_Array;

      procedure C1_Process (Image : in out OpenCV.Core.Mat) is
         procedure Mutate (Data : aliased in out F64_Buffer) is
         begin
            AUnit.Assertions.Assert
              (Data (0) = Precise, "Float64 C1 buffer must not narrow");
            Data (7) := Other;
         end Mutate;
      begin
         Count := Count + 1;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Access.Get (Image, (0, 0, 0)) = Precise,
            "Float64 C1 N-D Get must not narrow");
         OpenCV.Core.Float64_Buffer_Access.With_Writable_Buffer
           (Image, Mutate'Access);
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Access.Get (Image, (1, 1, 1)) = Other,
            "Float64 C1 buffer write must reach N-D Get exactly");
         OpenCV.Core.Float64_Access.Set (Image, (1, 0, 1), Precise);
      end C1_Process;

      procedure C2_Process (Image : in out OpenCV.Core.Mat) is
         procedure Inspect
           (Data : aliased OpenCV.Core.Float64_Vec2_Buffer_Access.Buffer_Array)
         is
         begin
            AUnit.Assertions.Assert
              (Data (0) = (Precise, Other),
               "Float64 C2 buffer must not narrow");
         end Inspect;
      begin
         Count := Count + 1;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec2_Access.Get (Image, (0, 0, 0))
            = (Precise, Other),
            "Float64 C2 N-D Get must not narrow");
         OpenCV.Core.Float64_Vec2_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect'Access);
         OpenCV.Core.Float64_Vec2_Access.Set
           (Image, (1, 1, 1), (Other, Precise));
      end C2_Process;

      procedure C3_Process (Image : in out OpenCV.Core.Mat) is
         procedure Inspect
           (Data : aliased OpenCV.Core.Float64_Vec3_Buffer_Access.Buffer_Array)
         is
         begin
            AUnit.Assertions.Assert
              (Data (0) = (Precise, Other, Precise),
               "Float64 C3 buffer must not narrow");
         end Inspect;
      begin
         Count := Count + 1;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec3_Access.Get (Image, (0, 0, 0))
            = (Precise, Other, Precise),
            "Float64 C3 N-D Get must not narrow");
         OpenCV.Core.Float64_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect'Access);
         OpenCV.Core.Float64_Vec3_Access.Set
           (Image, (1, 1, 1), (Other, Precise, Other));
      end C3_Process;

      procedure C4_Process (Image : in out OpenCV.Core.Mat) is
         procedure Inspect
           (Data : aliased OpenCV.Core.Float64_Vec4_Buffer_Access.Buffer_Array)
         is
         begin
            AUnit.Assertions.Assert
              (Data (0) = (Precise, Other, Precise, Other),
               "Float64 C4 buffer must not narrow");
         end Inspect;
      begin
         Count := Count + 1;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec4_Access.Get (Image, (0, 0, 0))
            = (Precise, Other, Precise, Other),
            "Float64 C4 N-D Get must not narrow");
         OpenCV.Core.Float64_Vec4_Buffer_Access.With_Read_Only_Buffer
           (Image, Inspect'Access);
         OpenCV.Core.Float64_Vec4_Access.Set
           (Image, (1, 1, 1), (Other, Precise, Other, Precise));
      end C4_Process;
   begin
      Probe := OpenCV.Float64_Value (OpenCV.Float32_Value (Probe));
      AUnit.Assertions.Assert
        (Probe /= Precise,
         "the Float64 fixture must not be representable in Float32");
      C1 (0) := Precise;
      C2 (1) := (Precise, Other);
      C3 (2) := (Precise, Other, Precise);
      C4 (3) := (Precise, Other, Precise, Other);
      OpenCV.Core.Float64_Mat_View.With_Writable_Mat_View
        (C1, (2, 2, 2), C1_Process'Access);
      OpenCV.Core.Float64_Vec2_Mat_View.With_Writable_Mat_View
        (C2, (2, 2, 2), C2_Process'Access);
      OpenCV.Core.Float64_Vec3_Mat_View.With_Writable_Mat_View
        (C3, (2, 2, 2), C3_Process'Access);
      OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Mat_View
        (C4, (2, 2, 2), C4_Process'Access);
      AUnit.Assertions.Assert
        (Count = 4
         and then C1 (7) = Other
         and then C1 (5) = Precise
         and then C2 (8) = (Other, Precise)
         and then C3 (9) = (Other, Precise, Other)
         and then C4 (10) = (Other, Precise, Other, Precise),
         "Float64 N-D Set must store exact values in caller Data");
   end Float64_Views_Do_Not_Narrow;

   procedure Invalid_Shapes_Rejected_Before_Process (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Storage : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (4 .. 27 => 7);
      Longer  : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (0 .. 24 => 7);
      Shorter : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (0 .. 22 => 7);
      Single  : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (0 .. 0 => 7);
      Vectors : aliased OpenCV.Core.Float64_Vec4_Mat_View.Buffer_Array :=
        (0 .. 95 => (others => 0.0));

      procedure Check_Rejected
        (Attempt : not null access procedure (Invoked : in out Boolean);
         Label   : String)
      is
         Invoked : Boolean := False;

         procedure Run is
         begin
            Attempt (Invoked);
         end Run;
      begin
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Run'Access, Label & " must raise OpenCV_Error");
         AUnit.Assertions.Assert
           (not Invoked, Label & " must be rejected before Process");
      end Check_Rejected;

      generic
         Shape : OpenCV.Core.Dimension_Array;
      procedure View_Storage (Invoked : in out Boolean);

      procedure View_Storage (Invoked : in out Boolean) is
         procedure Process (Image : in out OpenCV.Core.Mat) is
            pragma Unreferenced (Image);
         begin
            Invoked := True;
         end Process;
      begin
         OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
           (Storage, Shape, Process'Access);
      end View_Storage;

      Empty_Shape : constant OpenCV.Core.Dimension_Array (1 .. 0) :=
        (others => 1);
      Many_Shape  : constant OpenCV.Core.Dimension_Array (1 .. 33) :=
        (others => 1);

      procedure Null_Shape is new View_Storage (Empty_Shape);
      procedure One_Dimensional is new View_Storage ((1 => 24));
      procedure Zero_Extent is new View_Storage ((2, 0, 4));
      procedure Overflowing is new
        View_Storage
          ((OpenCV.Size_Coordinate'Last, OpenCV.Size_Coordinate'Last, 2));
      procedure Mismatched is new View_Storage ((2, 3, 5));

      procedure Thirty_Three (Invoked : in out Boolean) is
         procedure Process (Image : in out OpenCV.Core.Mat) is
            pragma Unreferenced (Image);
         begin
            Invoked := True;
         end Process;
      begin
         OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
           (Single, Many_Shape, Process'Access);
      end Thirty_Three;

      procedure Too_Long (Invoked : in out Boolean) is
         procedure Process (Image : in out OpenCV.Core.Mat) is
            pragma Unreferenced (Image);
         begin
            Invoked := True;
         end Process;
      begin
         OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
           (Longer, (2, 3, 4), Process'Access);
      end Too_Long;

      procedure Too_Short (Invoked : in out Boolean) is
         procedure Process (Image : in out OpenCV.Core.Mat) is
            pragma Unreferenced (Image);
         begin
            Invoked := True;
         end Process;
      begin
         OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
           (Shorter, (2, 3, 4), Process'Access);
      end Too_Short;

      --  96 Vec4 values are 96 complete elements, not 24 elements of four
      --  scalars: a (2, 3, 4) C4 view requires exactly 24 entries.
      procedure Scalar_Count (Invoked : in out Boolean) is
         procedure Process (Image : in out OpenCV.Core.Mat) is
            pragma Unreferenced (Image);
         begin
            Invoked := True;
         end Process;
      begin
         OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Mat_View
           (Vectors, (2, 3, 4), Process'Access);
      end Scalar_Count;

      --  Size_Coordinate confines public extents to 0 .. Int32'Last, so an
      --  extent beyond OpenCV's signed int domain cannot reach the view.
      Beyond_Int32 : Long_Long_Integer :=
        Long_Long_Integer (OpenCV.Size_Coordinate'Last);

      procedure Bad_Extent_Literal is
         Invalid : constant Long_Long_Integer := Beyond_Int32;
         Shape   : OpenCV.Core.Dimension_Array (1 .. 2) := (1, 1);
      begin
         Shape (2) := OpenCV.Size_Coordinate (Invalid);
         AUnit.Assertions.Assert
           (Shape (2) = 0, "unreachable: the extent must be out of range");
      end Bad_Extent_Literal;
   begin
      Check_Rejected (Null_Shape'Access, "a null Shape");
      Check_Rejected (One_Dimensional'Access, "a one-dimensional Shape");
      Check_Rejected (Thirty_Three'Access, "a 33-dimensional Shape");
      Check_Rejected (Zero_Extent'Access, "a zero extent");
      Check_Rejected (Overflowing'Access, "an unrepresentable product");
      Check_Rejected (Mismatched'Access, "a product unequal to Data'Length");
      Check_Rejected (Too_Long'Access, "Data longer than product (Shape)");
      Check_Rejected (Too_Short'Access, "Data shorter than product (Shape)");
      Check_Rejected (Scalar_Count'Access, "a C4 scalar-count Data length");

      Beyond_Int32 := Beyond_Int32 + 1;
      declare
         Raised : Boolean := False;
      begin
         begin
            Bad_Extent_Literal;
         exception
            when Constraint_Error =>
               Raised := True;
         end;
         AUnit.Assertions.Assert
           (Raised,
            "an extent above the signed Int32 domain must be unrepresentable"
            & " in Dimension_Array");
      end;

      AUnit.Assertions.Assert
        ((for all Value of Storage => Value = 7)
         and then (for all Value of Longer => Value = 7)
         and then (for all Value of Shorter => Value = 7),
         "rejected N-D views must leave caller storage unchanged");
   end Invalid_Shapes_Rejected_Before_Process;

   --  Views a 1 x ... x 1 x 2 Int32 shape of Count dimensions and checks
   --  that the final coordinate maps to the last caller element.
   procedure View_High_Dimensional (Count : Positive; Invoked : out Boolean) is
      Storage : aliased OpenCV.Core.Int32_Mat_View.Buffer_Array :=
        (0 => 41, 1 => 42);
      Shape   : OpenCV.Core.Dimension_Array (1 .. Count) := (others => 1);

      procedure Process (Image : in out OpenCV.Core.Mat) is
         Last : OpenCV.Core.Index_Array (1 .. Count) := (others => 0);
      begin
         Invoked := True;
         Last (Count) := 1;
         AUnit.Assertions.Assert
           (Image.Dimension_Count = Count
            and then Image.Extent (Count) = 2
            and then Image.Is_Continuous,
            "a high-dimensional packed view must report every dimension");
         AUnit.Assertions.Assert
           (OpenCV.Core.Int32_Access.Get (Image, Last) = 42,
            "the final coordinate must map to the last Data element");
         OpenCV.Core.Int32_Access.Set (Image, Last, -9);
      end Process;
   begin
      Invoked := False;
      Shape (Count) := 2;
      OpenCV.Core.Int32_Mat_View.With_Writable_Mat_View
        (Storage, Shape, Process'Access);
      AUnit.Assertions.Assert
        (Invoked and then Storage (1) = -9,
         "a high-dimensional view write must reach caller Data");
   end View_High_Dimensional;

   --  Expects the binding to reject a Count-dimensional view before Process
   --  runs, leaving caller Data unchanged.
   procedure Expect_High_Dimensional_Rejected (Count : Positive) is
      Storage : aliased OpenCV.Core.Int32_Mat_View.Buffer_Array :=
        (0 => 41, 1 => 42);
      Shape   : OpenCV.Core.Dimension_Array (1 .. Count) := (others => 1);
      Invoked : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Process;

      procedure Attempt is
      begin
         OpenCV.Core.Int32_Mat_View.With_Writable_Mat_View
           (Storage, Shape, Process'Access);
      end Attempt;
   begin
      Shape (Count) := 2;
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Attempt'Access,
         "a"
         & Count'Image
         & "-dimensional view above OpenCV 5's native"
         & " Mat capacity must raise OpenCV_Error");
      AUnit.Assertions.Assert
        (not Invoked,
         "a"
         & Count'Image
         & "-dimensional view rejected by the binding must"
         & " not run Process");
      AUnit.Assertions.Assert
        (Storage (0) = 41 and then Storage (1) = 42,
         "a rejected high-dimensional view must leave caller Data unchanged");
   end Expect_High_Dimensional_Rejected;

   procedure High_Dimensional_Views_Follow_Native_Limit (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Invoked_10 : Boolean;
      Invoked_11 : Boolean;
      Invoked_32 : Boolean;
   begin
      --  10 is within every supported OpenCV's native Mat capacity.
      View_High_Dimensional (10, Invoked_10);
      AUnit.Assertions.Assert
        (Invoked_10, "a 10-dimensional view must run Process");

      if Module_Bridge_Probe.OpenCV_Major_Version < 5 then
         --  OpenCV 4.x retains the historic 32-dimensional limit.
         View_High_Dimensional (11, Invoked_11);
         View_High_Dimensional (32, Invoked_32);
         AUnit.Assertions.Assert
           (Invoked_11 and then Invoked_32,
            "OpenCV 4.x must run Process for 11- and 32-dimensional views");
      else
         --  OpenCV 5.0's native MatShape capacity is 10 dimensions. The
         --  binding itself rejects longer shapes before native construction
         --  instead of relying on OpenCV to reject them.
         Expect_High_Dimensional_Rejected (11);
         Expect_High_Dimensional_Rejected (32);
      end if;
   end High_Dimensional_Views_Follow_Native_Limit;

   Process_Failure : exception;

   procedure Process_Exception_Propagates_Unchanged (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Storage : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (1 .. 24 => 0);
      Raised  : Boolean := False;
      After   : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         OpenCV.Core.UInt8_Access.Set (Image, (1, 2, 3), 99);
         raise Process_Failure;
      end Process;

      procedure Reuse (Image : in out OpenCV.Core.Mat) is
      begin
         After := OpenCV.Core.UInt8_Access.Get (Image, (1, 2, 3)) = 99;
      end Reuse;
   begin
      begin
         OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
           (Storage, (2, 3, 4), Process'Access);
      exception
         when Process_Failure =>
            Raised := True;
      end;
      AUnit.Assertions.Assert
        (Raised, "a Process exception must propagate unchanged");
      AUnit.Assertions.Assert
        (Storage (24) = 99,
         "writes completed before the exception must remain in caller Data");
      --  Caller storage is still owned and usable by a fresh view.
      OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
        (Storage, (2, 3, 4), Reuse'Access);
      AUnit.Assertions.Assert
        (After, "caller storage must remain usable after the exception");
   end Process_Exception_Propagates_Unchanged;

   procedure Module_Interop_Is_Input_Only (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Storage        : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (0 .. 23 => 5);
      Input_Invoked  : Boolean := False;
      Output_Invoked : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is
         procedure Inspect
           (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle)
         is
            pragma Unreferenced (Handle);
         begin
            Input_Invoked := True;
         end Inspect;

         procedure Output
           (Handle : OpenCV.Core.Module_Interop.Output_Mat_Handle)
         is
            pragma Unreferenced (Handle);
         begin
            Output_Invoked := True;
         end Output;

         procedure Attempt_Output is
         begin
            OpenCV.Core.Module_Interop.With_Output_Handle
              (Image, Output'Access);
         end Attempt_Output;
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle (Image, Inspect'Access);
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Attempt_Output'Access,
            "an N-D external view must reject an output handle");
      end Process;
   begin
      OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
        (Storage, (2, 3, 4), Process'Access);
      AUnit.Assertions.Assert
        (Input_Invoked and then not Output_Invoked,
         "N-D external view input borrowing must work and output must not");
   end Module_Interop_Is_Input_Only;

   procedure Read_Only_Packed_All_Layouts (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      RO_U8.Check_Packed;
      RO_I8.Check_Packed;
      RO_U16.Check_Packed;
      RO_I16.Check_Packed;
      RO_I32.Check_Packed;
      RO_F16.Check_Packed;
      RO_F32.Check_Packed;
      RO_F64.Check_Packed;
      RO_F32V2.Check_Packed;
      RO_F64V2.Check_Packed;
      RO_U8V3.Check_Packed;
      RO_F16V3.Check_Packed;
      RO_F32V3.Check_Packed;
      RO_F64V3.Check_Packed;
      RO_U8V4.Check_Packed;
      RO_F32V4.Check_Packed;
      RO_F64V4.Check_Packed;
   end Read_Only_Packed_All_Layouts;

   procedure Read_Only_Strided_All_Layouts (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      RO_U8.Check_Strided;
      RO_I8.Check_Strided;
      RO_U16.Check_Strided;
      RO_I16.Check_Strided;
      RO_I32.Check_Strided;
      RO_F16.Check_Strided;
      RO_F32.Check_Strided;
      RO_F64.Check_Strided;
      RO_F32V2.Check_Strided;
      RO_F64V2.Check_Strided;
      RO_U8V3.Check_Strided;
      RO_F16V3.Check_Strided;
      RO_F32V3.Check_Strided;
      RO_F64V3.Check_Strided;
      RO_U8V4.Check_Strided;
      RO_F32V4.Check_Strided;
      RO_F64V4.Check_Strided;
   end Read_Only_Strided_All_Layouts;

   procedure Read_Only_Clone_No_Escape_And_Module_Input (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data          : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (11 => 1, 12 => 2, 13 => 3, 14 => 4, 15 => 5, 16 => 6);
      Copy          : OpenCV.Core.Mat;
      Input_Invoked : Boolean := False;

      procedure Inspect (Image : OpenCV.Core.Mat) is
         procedure Input (Handle : OpenCV.Core.Module_Interop.Input_Mat_Handle)
         is
            Observation : Module_Bridge_Probe.Input_Observation;
         begin
            Module_Bridge_Probe.Inspect (Handle, Observation);
            Input_Invoked :=
              Observation.Rows = 2
              and then Observation.Columns = 3
              and then Observation.Value = 1;
         end Input;
         procedure Shallow_Copy is
            Other : constant OpenCV.Core.Mat := Image;
         begin
            AUnit.Assertions.Assert (Other.Rows = 2, "unreachable copy");
         end Shallow_Copy;
         procedure Slice_View is
            Other : constant OpenCV.Core.Mat := Image.Slice (((0, 2), (0, 3)));
         begin
            AUnit.Assertions.Assert (Other.Rows = 2, "unreachable slice");
         end Slice_View;
         procedure Reshaped is
            Other : constant OpenCV.Core.Mat := Image.Reshape (1, 3);
         begin
            AUnit.Assertions.Assert (Other.Rows = 3, "unreachable reshape");
         end Reshaped;
         procedure Region_View is
            Other : constant OpenCV.Core.Mat :=
              Image.Region ((X => 0, Y => 0, Width => 2, Height => 2));
         begin
            AUnit.Assertions.Assert (Other.Rows = 2, "unreachable region");
         end Region_View;
      begin
         OpenCV.Core.Module_Interop.With_Input_Handle (Image, Input'Access);
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Shallow_Copy'Access, "read-only shallow copy must reject");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Slice_View'Access, "read-only slice must reject");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Reshaped'Access, "read-only reshape must reject");
         Mat_Test_Support.Assert_Raises_OpenCV_Error
           (Region_View'Access, "read-only region must reject");
         Copy := Image.Clone;
      end Inspect;
   begin
      OpenCV.Core.UInt8_Mat_View.With_Read_Only_Mat_View
        (Data, 2, 3, Inspect'Access);
      AUnit.Assertions.Assert
        (Input_Invoked and then Data (11) = 1,
         "module input works without changing caller data");
      Data (11) := 90;
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Copy, 0, 0) = 1,
         "Clone retains original pixel after caller write");
      OpenCV.Core.UInt8_Access.Set (Copy, 0, 0, 42);
      AUnit.Assertions.Assert
        (Data (11) = 90, "Clone writes cannot change caller data");
      AUnit.Assertions.Assert
        (Copy.Slice (((0, 2), (0, 3))).Rows = 2
         and then Copy.Reshape (1, 3).Rows = 3,
         "owned Clone supports shallow views");
   end Read_Only_Clone_No_Escape_And_Module_Input;

   procedure Read_Only_Float16_Exact_Bits (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Data   : aliased constant OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (11 => F16 (16#7C01#),
         12 => F16 (16#8000#),
         13 => F16 (16#0001#),
         14 => F16 (16#03FF#));
      Pixels :
        aliased constant OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
          (11 .. 14 => (F16 (16#7C01#), F16 (16#8000#), F16 (16#0001#)));
      procedure Inspect (Image : OpenCV.Core.Mat) is
         procedure Buffer
           (B : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
         begin
            for I in 0 .. 3 loop
               AUnit.Assertions.Assert
                 (Bits (B (I)) = Bits (Data (11 + I)),
                  "exact Float16 buffer bits");
            end loop;
         end Buffer;
      begin
         for I in 0 .. 3 loop
            AUnit.Assertions.Assert
              (Bits
                 (OpenCV.Core.Float16_Access.Get
                    (Image, (0, OpenCV.Size_Coordinate (I), 0)))
               = Bits (Data (11 + I)),
               "exact Float16 N-D Get bits");
         end loop;
         OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
           (Image, Buffer'Access);
      end Inspect;
      procedure Inspect_Pixels (Image : OpenCV.Core.Mat) is
         V : constant OpenCV.Core.Float16_Vec3.Vector :=
           OpenCV.Core.Float16_Vec3_Access.Get (Image, (0, 0, 0));
         procedure Buffer
           (B : aliased OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array) is
         begin
            AUnit.Assertions.Assert
              (Bits (B (0) (0)) = 16#7C01#
               and then Bits (B (0) (1)) = 16#8000#
               and then Bits (B (0) (2)) = 16#0001#,
               "exact Float16 C3 borrowed bits");
         end Buffer;
      begin
         AUnit.Assertions.Assert
           (Bits (V (0)) = 16#7C01#
            and then Bits (V (1)) = 16#8000#
            and then Bits (V (2)) = 16#0001#,
            "exact Float16 C3 Get bits");
         OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer
           (Image, Buffer'Access);
      end Inspect_Pixels;
   begin
      OpenCV.Core.Float16_Mat_View.With_Read_Only_Mat_View
        (Data, (1, 4, 1), Inspect'Access);
      OpenCV.Core.Float16_Vec3_Mat_View.With_Read_Only_Mat_View
        (Pixels, (2, 2, 1), Inspect_Pixels'Access);
   end Read_Only_Float16_Exact_Bits;

   procedure Read_Only_Invalid_Capacity_Rejects_Before_Process
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Data    : aliased constant OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (11 .. 16 => 7);
      Invoked : Boolean := False;
      procedure Inspect (Image : OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Inspect;
      procedure Bad_Packed is
      begin
         OpenCV.Core.UInt8_Mat_View.With_Read_Only_Mat_View
           (Data, (2, 4), Inspect'Access);
      end Bad_Packed;
      procedure Bad_Stride is
      begin
         OpenCV.Core.UInt8_Mat_View.With_Read_Only_Strided_Mat_View
           (Data, 2, 3, 5, Inspect'Access);
      end Bad_Stride;
      procedure Bad_ND_Stride is
      begin
         OpenCV.Core.UInt8_Mat_View.With_Read_Only_Strided_Mat_View
           (Data, (2, 3), (2, 1), Inspect'Access);
      end Bad_ND_Stride;
   begin
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Bad_Packed'Access, "read-only packed capacity mismatch");
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Bad_Stride'Access, "read-only complete row stride required");
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Bad_ND_Stride'Access, "read-only nested stride must not overlap");
      AUnit.Assertions.Assert
        (not Invoked, "invalid views never call Process");
   end Read_Only_Invalid_Capacity_Rejects_Before_Process;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Read-only packed 2-D/N-D constant views alias all 17 layouts",
            Read_Only_Packed_All_Layouts'Access));
      Result.Add_Test
        (Caller.Create
           ("Read-only Clone, shallow rejection, and module input",
            Read_Only_Clone_No_Escape_And_Module_Input'Access));
      Result.Add_Test
        (Caller.Create
           ("Read-only Float16 C1/C3 preserve exact bits",
            Read_Only_Float16_Exact_Bits'Access));
      Result.Add_Test
        (Caller.Create
           ("Read-only invalid shape and strides reject before callback",
            Read_Only_Invalid_Capacity_Rejects_Before_Process'Access));
      Result.Add_Test
        (Caller.Create
           ("Read-only gapped and packed strides cover all 17 layouts",
            Read_Only_Strided_All_Layouts'Access));
      Result.Add_Test
        (Caller.Create
           ("External N-D view raw ABI rejects malformed requests",
            Raw_ABI_Rejects_Malformed_Requests'Access));
      Result.Add_Test
        (Caller.Create
           ("External N-D view raw ABI creates packed 2-D and 3-D views",
            Raw_ABI_Creates_Packed_Views'Access));
      Result.Add_Test
        (Caller.Create
           ("External N-D view raw ABI marks a temporary external view",
            Raw_ABI_Marks_Temporary_View'Access));
      Result.Add_Test
        (Caller.Create
           ("C1 N-D views alias caller storage for all 8 packages",
            C1_Volumes_Alias_Caller_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("C2/C3/C4 N-D views alias caller storage for all 9 packages",
            Vector_Volumes_Alias_Caller_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Shape (2, 3) views match Rows/Columns views for all 17 packages",
            Two_Dimensional_Shape_Matches_Rows_Columns'Access));
      Result.Add_Test
        (Caller.Create
           ("N-D views reject Slice/Reshape and Clone independently (x17)",
            Views_Reject_Shallow_Escape_And_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 C1/C3 N-D views preserve exact binary16 bits",
            Float16_Views_Preserve_Exact_Bits'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 C1/C2/C3/C4 N-D views do not narrow",
            Float64_Views_Do_Not_Narrow'Access));
      Result.Add_Test
        (Caller.Create
           ("Invalid N-D view shapes are rejected before Process",
            Invalid_Shapes_Rejected_Before_Process'Access));
      Result.Add_Test
        (Caller.Create
           ("High-dimensional packed views follow the native dimension limit",
            High_Dimensional_Views_Follow_Native_Limit'Access));
      Result.Add_Test
        (Caller.Create
           ("N-D view Process exceptions propagate unchanged",
            Process_Exception_Propagates_Unchanged'Access));
      Result.Add_Test
        (Caller.Create
           ("N-D views are Module_Interop input-only",
            Module_Interop_Is_Input_Only'Access));
      return Result'Access;
   end Suite;

end ND_Mat_View_Tests;
