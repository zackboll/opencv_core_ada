with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with Mat_Test_Support;
with Module_Bridge_Probe;
with ND_Strided_Mat_View_Checks;
with ND_Strided_Mat_View_Tests.Raw_ABI;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float16_Buffer_Access;
with OpenCV.Core.Float16_Mat_View;
with OpenCV.Core.Float16_Vec2;
with OpenCV.Core.Float16_Vec2_Access;
with OpenCV.Core.Float16_Vec2_Buffer_Access;
with OpenCV.Core.Float16_Vec2_Mat_View;
with OpenCV.Core.Float16_Vec3;
with OpenCV.Core.Float16_Vec3_Access;
with OpenCV.Core.Float16_Vec3_Buffer_Access;
with OpenCV.Core.Float16_Vec3_Mat_View;
with OpenCV.Core.Float16_Vec4;
with OpenCV.Core.Float16_Vec4_Access;
with OpenCV.Core.Float16_Vec4_Buffer_Access;
with OpenCV.Core.Float16_Vec4_Mat_View;
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
with OpenCV.Core.UInt16_Vec4;
with OpenCV.Core.UInt16_Vec3;
with OpenCV.Core.UInt16_Vec3_Access;
with OpenCV.Core.UInt16_Vec3_Buffer_Access;
with OpenCV.Core.UInt16_Vec3_Mat_View;
with OpenCV.Core.UInt16_Vec4_Access;
with OpenCV.Core.UInt16_Vec4_Buffer_Access;
with OpenCV.Core.UInt16_Vec4_Mat_View;
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
with OpenCV.Core.UInt8_Vec2;
with OpenCV.Core.UInt8_Vec2_Access;
with OpenCV.Core.UInt8_Vec2_Buffer_Access;
with OpenCV.Core.UInt8_Vec2_Mat_View;
with OpenCV.Core.UInt16_Vec2;
with OpenCV.Core.UInt16_Vec2_Access;
with OpenCV.Core.UInt16_Vec2_Buffer_Access;
with OpenCV.Core.UInt16_Vec2_Mat_View;
with OpenCV.Core.Int16_Vec2;
with OpenCV.Core.Int16_Vec2_Access;
with OpenCV.Core.Int16_Vec2_Buffer_Access;
with OpenCV.Core.Int16_Vec2_Mat_View;
with OpenCV.Core.Int16_Vec3;
with OpenCV.Core.Int16_Vec3_Access;
with OpenCV.Core.Int16_Vec3_Buffer_Access;
with OpenCV.Core.Int16_Vec3_Mat_View;
with OpenCV.Core.Int16_Vec4;
with OpenCV.Core.Int16_Vec4_Access;
with OpenCV.Core.Int16_Vec4_Buffer_Access;
with OpenCV.Core.Int16_Vec4_Mat_View;
with OpenCV.Core.Int32_Vec2;
with OpenCV.Core.Int32_Vec2_Access;
with OpenCV.Core.Int32_Vec2_Buffer_Access;
with OpenCV.Core.Int32_Vec2_Mat_View;
with OpenCV.Core.Int32_Vec3;
with OpenCV.Core.Int32_Vec3_Access;
with OpenCV.Core.Int32_Vec3_Buffer_Access;
with OpenCV.Core.Int32_Vec3_Mat_View;
with OpenCV.Core.Int32_Vec4;
with OpenCV.Core.Int32_Vec4_Access;
with OpenCV.Core.Int32_Vec4_Buffer_Access;
with OpenCV.Core.Int32_Vec4_Mat_View;
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

package body ND_Strided_Mat_View_Tests is

   use type Interfaces.Unsigned_16;
   use type OpenCV.Float32_Value;
   use type OpenCV.Float64_Value;
   use type OpenCV.UInt8_Value;
   use type OpenCV.Int32_Value;
   use type OpenCV.Size_Coordinate;
   use type OpenCV.Core.Float64_Vec4.Vector;

   subtype Fixture is Mat_Test_Support.Mat_Test_Fixture;
   package Caller is new AUnit.Test_Caller (Fixture);
   Result : aliased AUnit.Test_Suites.Test_Suite;

   --  Value generators. Offsets 0 .. 23, 50, 60, and 100 .. 103 are
   --  pairwise distinct for every layout.

   function F16
     (Bits : Interfaces.Unsigned_16) return OpenCV.Core.Float16_Value
   renames OpenCV.Core.Float16_From_Bits;

   function Bits
     (Value : OpenCV.Core.Float16_Value) return Interfaces.Unsigned_16
   renames OpenCV.Core.Float16_Bits;

   --  1.0 + 2**-40 is not representable in Float32.
   Fine : constant OpenCV.Float64_Value := 2.0**(-40);

   function UInt8_At (O : Natural) return OpenCV.UInt8_Value
   is (OpenCV.UInt8_Value (O + 1));

   function Int8_At (O : Natural) return OpenCV.Int8_Value
   is (OpenCV.Int8_Value (Integer (O) - 120));

   function UInt16_At (O : Natural) return OpenCV.UInt16_Value
   is (OpenCV.UInt16_Value (65_535 - O));

   function Int16_At (O : Natural) return OpenCV.Int16_Value
   is (OpenCV.Int16_Value (Integer (O) - 32_768));

   function Int32_At (O : Natural) return OpenCV.Int32_Value
   is (OpenCV.Int32_Value (O) * (-1_000) - 7);

   function Float16_At (O : Natural) return OpenCV.Core.Float16_Value
   is (F16 (16#3C00# + Interfaces.Unsigned_16 (O)));

   function Float32_At (O : Natural) return OpenCV.Float32_Value
   is (OpenCV.Float32_Value (O) * 0.5 - 3.25);

   --  Every value is 1.0 + k * 2**-40 with k >= 1; narrowing is detectable.
   function Float64_At (O : Natural) return OpenCV.Float64_Value
   is (1.0 + OpenCV.Float64_Value (O + 1) * Fine);

   function F32_Vec2_At (O : Natural) return OpenCV.Core.Float32_Vec2.Vector
   is (Float32_At (O), -Float32_At (O) - 100.0);

   function F64_Vec2_At (O : Natural) return OpenCV.Core.Float64_Vec2.Vector
   is (Float64_At (O), -Float64_At (O));

   function U8_Vec2_At (O : Natural) return OpenCV.Core.UInt8_Vec2.Vector
   is (OpenCV.UInt8_Value (O), OpenCV.UInt8_Value (255 - O));

   function U16_Vec2_At (O : Natural) return OpenCV.Core.UInt16_Vec2.Vector
   is (OpenCV.UInt16_Value (O), OpenCV.UInt16_Value (65535 - O));

   function S16_Vec2_At (O : Natural) return OpenCV.Core.Int16_Vec2.Vector
   is (OpenCV.Int16_Value (Integer (O) - 32_768),
       OpenCV.Int16_Value (32_767 - Integer (O)));
   function S16_Vec3_At (O : Natural) return OpenCV.Core.Int16_Vec3.Vector
   is (OpenCV.Int16_Value (Integer (O) - 32_768),
       OpenCV.Int16_Value (Integer (O) - 1),
       OpenCV.Int16_Value (32_767 - Integer (O)));
   function S16_Vec4_At (O : Natural) return OpenCV.Core.Int16_Vec4.Vector
   is (OpenCV.Int16_Value (Integer (O) - 32_768),
       OpenCV.Int16_Value (Integer (O) - 1),
       OpenCV.Int16_Value (32_767 - Integer (O)),
       OpenCV.Int16_Value (-Integer (O)));

   function S32_Vec2_At (O : Natural) return OpenCV.Core.Int32_Vec2.Vector
   is (OpenCV.Int32_Value'First + OpenCV.Int32_Value (O),
       OpenCV.Int32_Value'Last - OpenCV.Int32_Value (O));
   function S32_Vec3_At (O : Natural) return OpenCV.Core.Int32_Vec3.Vector
   is (OpenCV.Int32_Value'First + OpenCV.Int32_Value (O),
       -1 - OpenCV.Int32_Value (O),
       OpenCV.Int32_Value'Last - OpenCV.Int32_Value (O));
   function S32_Vec4_At (O : Natural) return OpenCV.Core.Int32_Vec4.Vector
   is (OpenCV.Int32_Value'First + OpenCV.Int32_Value (O),
       -1 - OpenCV.Int32_Value (O),
       OpenCV.Int32_Value'Last - OpenCV.Int32_Value (O),
       OpenCV.Int32_Value (O));

   function U8_Vec3_At (O : Natural) return OpenCV.Core.UInt8_Vec3.Vector
   is (OpenCV.UInt8_Value (O),
       OpenCV.UInt8_Value (O + 50),
       OpenCV.UInt8_Value (O + 150));

   function F16_Vec3_At (O : Natural) return OpenCV.Core.Float16_Vec3.Vector
   is (F16 (16#0001# + Interfaces.Unsigned_16 (O)),
       F16 (16#8000# + Interfaces.Unsigned_16 (O)),
       F16 (16#3C00# + Interfaces.Unsigned_16 (O)));

   --  Signaling-NaN payloads, negative zero neighbours, subnormals and
   --  negative NaN payloads, bit-distinct per element and component.
   function F16_Vec2_At (O : Natural) return OpenCV.Core.Float16_Vec2.Vector
   is (F16 (16#7C01# + Interfaces.Unsigned_16 (O)),
       F16 (16#8000# + Interfaces.Unsigned_16 (O)));
   function F16_Vec4_At (O : Natural) return OpenCV.Core.Float16_Vec4.Vector
   is (F16 (16#0001# + Interfaces.Unsigned_16 (O)),
       F16 (16#FC01# + Interfaces.Unsigned_16 (O)),
       F16 (16#3C00# + Interfaces.Unsigned_16 (O)),
       F16 (16#7E00# + Interfaces.Unsigned_16 (O)));

   function U16_Vec3_At (O : Natural) return OpenCV.Core.UInt16_Vec3.Vector
   is (OpenCV.UInt16_Value (O),
       OpenCV.UInt16_Value (32768 + O),
       OpenCV.UInt16_Value (65535 - O));

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

   function U16_Vec4_At (O : Natural) return OpenCV.Core.UInt16_Vec4.Vector
   is (OpenCV.UInt16_Value (O),
       OpenCV.UInt16_Value (32768 + O),
       OpenCV.UInt16_Value (65535 - O),
       OpenCV.UInt16_Value (O + 1));

   function F64_Vec4_At (O : Natural) return OpenCV.Core.Float64_Vec4.Vector
   is (Float64_At (O),
       -2.0 - OpenCV.Float64_Value (O) * Fine,
       3.0 + 2.0**(-44),
       -Float64_At (O));

   --  Float32 C1 keeps its established Row_Stride_Elements overload name.
   procedure Float32_Row_Strided
     (Data       : aliased in out OpenCV.Core.Float32_Mat_View.Buffer_Array;
      Rows       : Positive;
      Columns    : Positive;
      Row_Stride : Positive;
      Process    : not null access procedure (Image : in out OpenCV.Core.Mat))
   is
   begin
      OpenCV.Core.Float32_Mat_View.With_Writable_Mat_View
        (Data                => Data,
         Rows                => Rows,
         Columns             => Columns,
         Row_Stride_Elements => Row_Stride,
         Process             => Process);
   end Float32_Row_Strided;

   --  One instance per typed Mat_View package.

   package UInt8_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.UInt8_Value,
        OpenCV.Core.UInt8_Mat_View.Buffer_Array,
        OpenCV.Core.UInt8_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 1),
        "UInt8 C1",
        UInt8_At,
        OpenCV.Core.UInt8_Access.Get,
        OpenCV.Core.UInt8_Access.Set,
        OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt8_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt8_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt8_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt8_Buffer_Access.With_Writable_Buffer);

   package Int8_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Int8_Value,
        OpenCV.Core.Int8_Mat_View.Buffer_Array,
        OpenCV.Core.Int8_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int8, 1),
        "Int8 C1",
        Int8_At,
        OpenCV.Core.Int8_Access.Get,
        OpenCV.Core.Int8_Access.Set,
        OpenCV.Core.Int8_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int8_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int8_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int8_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int8_Buffer_Access.With_Writable_Buffer);

   package UInt16_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.UInt16_Value,
        OpenCV.Core.UInt16_Mat_View.Buffer_Array,
        OpenCV.Core.UInt16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt16, 1),
        "UInt16 C1",
        UInt16_At,
        OpenCV.Core.UInt16_Access.Get,
        OpenCV.Core.UInt16_Access.Set,
        OpenCV.Core.UInt16_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt16_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt16_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt16_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt16_Buffer_Access.With_Writable_Buffer);

   package Int16_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Int16_Value,
        OpenCV.Core.Int16_Mat_View.Buffer_Array,
        OpenCV.Core.Int16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int16, 1),
        "Int16 C1",
        Int16_At,
        OpenCV.Core.Int16_Access.Get,
        OpenCV.Core.Int16_Access.Set,
        OpenCV.Core.Int16_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int16_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int16_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int16_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int16_Buffer_Access.With_Writable_Buffer);

   package Int32_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Int32_Value,
        OpenCV.Core.Int32_Mat_View.Buffer_Array,
        OpenCV.Core.Int32_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int32, 1),
        "Int32 C1",
        Int32_At,
        OpenCV.Core.Int32_Access.Get,
        OpenCV.Core.Int32_Access.Set,
        OpenCV.Core.Int32_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int32_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int32_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int32_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int32_Buffer_Access.With_Writable_Buffer);

   package Float16_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Float16_Value,
        OpenCV.Core.Float16_Mat_View.Buffer_Array,
        OpenCV.Core.Float16_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float16, 1),
        "Float16 C1",
        Float16_At,
        OpenCV.Core.Float16_Access.Get,
        OpenCV.Core.Float16_Access.Set,
        OpenCV.Core.Float16_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer);

   package Float32_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Float32_Value,
        OpenCV.Core.Float32_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 1),
        "Float32 C1",
        Float32_At,
        OpenCV.Core.Float32_Access.Get,
        OpenCV.Core.Float32_Access.Set,
        OpenCV.Core.Float32_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Mat_View.With_Writable_Strided_Mat_View,
        Float32_Row_Strided,
        OpenCV.Core.Float32_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Buffer_Access.With_Writable_Buffer);

   package Float64_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Float64_Value,
        OpenCV.Core.Float64_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 1),
        "Float64 C1",
        Float64_At,
        OpenCV.Core.Float64_Access.Get,
        OpenCV.Core.Float64_Access.Set,
        OpenCV.Core.Float64_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float64_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float64_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Buffer_Access.With_Writable_Buffer);

   package U8_Vec2_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.UInt8_Vec2.Vector,
        OpenCV.Core.UInt8_Vec2_Mat_View.Buffer_Array,
        OpenCV.Core.UInt8_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 2),
        "UInt8 C2",
        U8_Vec2_At,
        OpenCV.Core.UInt8_Vec2_Access.Get,
        OpenCV.Core.UInt8_Vec2_Access.Set,
        OpenCV.Core.UInt8_Vec2_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt8_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt8_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt8_Vec2_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt8_Vec2_Buffer_Access.With_Writable_Buffer);
   package U16_Vec2_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.UInt16_Vec2.Vector,
        OpenCV.Core.UInt16_Vec2_Mat_View.Buffer_Array,
        OpenCV.Core.UInt16_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt16, 2),
        "UInt16 C2",
        U16_Vec2_At,
        OpenCV.Core.UInt16_Vec2_Access.Get,
        OpenCV.Core.UInt16_Vec2_Access.Set,
        OpenCV.Core.UInt16_Vec2_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt16_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt16_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt16_Vec2_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt16_Vec2_Buffer_Access.With_Writable_Buffer);
   package S16_Vec2_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Int16_Vec2.Vector,
        OpenCV.Core.Int16_Vec2_Mat_View.Buffer_Array,
        OpenCV.Core.Int16_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int16, 2),
        "Int16 C2",
        S16_Vec2_At,
        OpenCV.Core.Int16_Vec2_Access.Get,
        OpenCV.Core.Int16_Vec2_Access.Set,
        OpenCV.Core.Int16_Vec2_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int16_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int16_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int16_Vec2_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int16_Vec2_Buffer_Access.With_Writable_Buffer);
   package S16_Vec3_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Int16_Vec3.Vector,
        OpenCV.Core.Int16_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.Int16_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int16, 3),
        "Int16 C3",
        S16_Vec3_At,
        OpenCV.Core.Int16_Vec3_Access.Get,
        OpenCV.Core.Int16_Vec3_Access.Set,
        OpenCV.Core.Int16_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int16_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int16_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int16_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int16_Vec3_Buffer_Access.With_Writable_Buffer);
   package S16_Vec4_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Int16_Vec4.Vector,
        OpenCV.Core.Int16_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.Int16_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int16, 4),
        "Int16 C4",
        S16_Vec4_At,
        OpenCV.Core.Int16_Vec4_Access.Get,
        OpenCV.Core.Int16_Vec4_Access.Set,
        OpenCV.Core.Int16_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int16_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int16_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int16_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int16_Vec4_Buffer_Access.With_Writable_Buffer);

   package S32_Vec2_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Int32_Vec2.Vector,
        OpenCV.Core.Int32_Vec2_Mat_View.Buffer_Array,
        OpenCV.Core.Int32_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int32, 2),
        "Int32 C2",
        S32_Vec2_At,
        OpenCV.Core.Int32_Vec2_Access.Get,
        OpenCV.Core.Int32_Vec2_Access.Set,
        OpenCV.Core.Int32_Vec2_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int32_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int32_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int32_Vec2_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int32_Vec2_Buffer_Access.With_Writable_Buffer);
   package S32_Vec3_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Int32_Vec3.Vector,
        OpenCV.Core.Int32_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.Int32_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int32, 3),
        "Int32 C3",
        S32_Vec3_At,
        OpenCV.Core.Int32_Vec3_Access.Get,
        OpenCV.Core.Int32_Vec3_Access.Set,
        OpenCV.Core.Int32_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int32_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int32_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int32_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int32_Vec3_Buffer_Access.With_Writable_Buffer);
   package S32_Vec4_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Int32_Vec4.Vector,
        OpenCV.Core.Int32_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.Int32_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Int32, 4),
        "Int32 C4",
        S32_Vec4_At,
        OpenCV.Core.Int32_Vec4_Access.Get,
        OpenCV.Core.Int32_Vec4_Access.Set,
        OpenCV.Core.Int32_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Int32_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int32_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Int32_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Int32_Vec4_Buffer_Access.With_Writable_Buffer);

   package F32_Vec2_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Float32_Vec2.Vector,
        OpenCV.Core.Float32_Vec2_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 2),
        "Float32 C2",
        F32_Vec2_At,
        OpenCV.Core.Float32_Vec2_Access.Get,
        OpenCV.Core.Float32_Vec2_Access.Set,
        OpenCV.Core.Float32_Vec2_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float32_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float32_Vec2_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Vec2_Buffer_Access.With_Writable_Buffer);

   package F64_Vec2_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Float64_Vec2.Vector,
        OpenCV.Core.Float64_Vec2_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 2),
        "Float64 C2",
        F64_Vec2_At,
        OpenCV.Core.Float64_Vec2_Access.Get,
        OpenCV.Core.Float64_Vec2_Access.Set,
        OpenCV.Core.Float64_Vec2_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float64_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float64_Vec2_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Vec2_Buffer_Access.With_Writable_Buffer);

   package U8_Vec3_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.UInt8_Vec3.Vector,
        OpenCV.Core.UInt8_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.UInt8_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 3),
        "UInt8 C3",
        U8_Vec3_At,
        OpenCV.Core.UInt8_Vec3_Access.Get,
        OpenCV.Core.UInt8_Vec3_Access.Set,
        OpenCV.Core.UInt8_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt8_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt8_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt8_Vec3_Buffer_Access.With_Writable_Buffer);

   package U16_Vec3_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.UInt16_Vec3.Vector,
        OpenCV.Core.UInt16_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.UInt16_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt16, 3),
        "UInt16 C3",
        U16_Vec3_At,
        OpenCV.Core.UInt16_Vec3_Access.Get,
        OpenCV.Core.UInt16_Vec3_Access.Set,
        OpenCV.Core.UInt16_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt16_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt16_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt16_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt16_Vec3_Buffer_Access.With_Writable_Buffer);
   package F16_Vec3_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Float16_Vec3.Vector,
        OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.Float16_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float16, 3),
        "Float16 C3",
        F16_Vec3_At,
        OpenCV.Core.Float16_Vec3_Access.Get,
        OpenCV.Core.Float16_Vec3_Access.Set,
        OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float16_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float16_Vec3_Buffer_Access.With_Writable_Buffer);
   package F16_Vec2_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Float16_Vec2.Vector,
        OpenCV.Core.Float16_Vec2_Mat_View.Buffer_Array,
        OpenCV.Core.Float16_Vec2_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float16, 2),
        "Float16 C2",
        F16_Vec2_At,
        OpenCV.Core.Float16_Vec2_Access.Get,
        OpenCV.Core.Float16_Vec2_Access.Set,
        OpenCV.Core.Float16_Vec2_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float16_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float16_Vec2_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float16_Vec2_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float16_Vec2_Buffer_Access.With_Writable_Buffer);
   package F16_Vec4_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Float16_Vec4.Vector,
        OpenCV.Core.Float16_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.Float16_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float16, 4),
        "Float16 C4",
        F16_Vec4_At,
        OpenCV.Core.Float16_Vec4_Access.Get,
        OpenCV.Core.Float16_Vec4_Access.Set,
        OpenCV.Core.Float16_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float16_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float16_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float16_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float16_Vec4_Buffer_Access.With_Writable_Buffer);

   package F32_Vec3_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Float32_Vec3.Vector,
        OpenCV.Core.Float32_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 3),
        "Float32 C3",
        F32_Vec3_At,
        OpenCV.Core.Float32_Vec3_Access.Get,
        OpenCV.Core.Float32_Vec3_Access.Set,
        OpenCV.Core.Float32_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float32_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float32_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Vec3_Buffer_Access.With_Writable_Buffer);

   package F64_Vec3_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Float64_Vec3.Vector,
        OpenCV.Core.Float64_Vec3_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Vec3_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 3),
        "Float64 C3",
        F64_Vec3_At,
        OpenCV.Core.Float64_Vec3_Access.Get,
        OpenCV.Core.Float64_Vec3_Access.Set,
        OpenCV.Core.Float64_Vec3_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float64_Vec3_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float64_Vec3_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Vec3_Buffer_Access.With_Writable_Buffer);

   package U8_Vec4_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.UInt8_Vec4.Vector,
        OpenCV.Core.UInt8_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.UInt8_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt8, 4),
        "UInt8 C4",
        U8_Vec4_At,
        OpenCV.Core.UInt8_Vec4_Access.Get,
        OpenCV.Core.UInt8_Vec4_Access.Set,
        OpenCV.Core.UInt8_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt8_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt8_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt8_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt8_Vec4_Buffer_Access.With_Writable_Buffer);

   package U16_Vec4_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.UInt16_Vec4.Vector,
        OpenCV.Core.UInt16_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.UInt16_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.UInt16, 4),
        "UInt16 C4",
        U16_Vec4_At,
        OpenCV.Core.UInt16_Vec4_Access.Get,
        OpenCV.Core.UInt16_Vec4_Access.Set,
        OpenCV.Core.UInt16_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.UInt16_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt16_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.UInt16_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.UInt16_Vec4_Buffer_Access.With_Writable_Buffer);
   package F32_Vec4_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Float32_Vec4.Vector,
        OpenCV.Core.Float32_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.Float32_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float32, 4),
        "Float32 C4",
        F32_Vec4_At,
        OpenCV.Core.Float32_Vec4_Access.Get,
        OpenCV.Core.Float32_Vec4_Access.Set,
        OpenCV.Core.Float32_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float32_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float32_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float32_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float32_Vec4_Buffer_Access.With_Writable_Buffer);

   package F64_Vec4_Checks is new
     ND_Strided_Mat_View_Checks
       (OpenCV.Core.Float64_Vec4.Vector,
        OpenCV.Core.Float64_Vec4_Mat_View.Buffer_Array,
        OpenCV.Core.Float64_Vec4_Buffer_Access.Buffer_Array,
        (OpenCV.Core.Float64, 4),
        "Float64 C4",
        F64_Vec4_At,
        OpenCV.Core.Float64_Vec4_Access.Get,
        OpenCV.Core.Float64_Vec4_Access.Set,
        OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Mat_View,
        OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Strided_Mat_View,
        OpenCV.Core.Float64_Vec4_Buffer_Access.With_Read_Only_Buffer,
        OpenCV.Core.Float64_Vec4_Buffer_Access.With_Writable_Buffer);

   procedure Raw_ABI_Rejects_Malformed_Requests (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check_Rejections;
   end Raw_ABI_Rejects_Malformed_Requests;

   procedure Raw_ABI_Creates_Strided_Views (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check_Valid_Views;
   end Raw_ABI_Creates_Strided_Views;

   procedure Raw_ABI_Marks_Temporary_View (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Raw_ABI.Check_Temporary_View;
   end Raw_ABI_Marks_Temporary_View;

   procedure C1_Gapped_Volumes_Alias_Caller_Storage (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      UInt8_Checks.Check_Gapped_Volume;
      Int8_Checks.Check_Gapped_Volume;
      UInt16_Checks.Check_Gapped_Volume;
      Int16_Checks.Check_Gapped_Volume;
      Int32_Checks.Check_Gapped_Volume;
      Float16_Checks.Check_Gapped_Volume;
      Float32_Checks.Check_Gapped_Volume;
      Float64_Checks.Check_Gapped_Volume;
   end C1_Gapped_Volumes_Alias_Caller_Storage;

   procedure Vector_Gapped_Volumes_Alias_Caller_Storage (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
   begin
      U8_Vec2_Checks.Check_Gapped_Volume;
      U16_Vec2_Checks.Check_Gapped_Volume;
      S16_Vec2_Checks.Check_Gapped_Volume;
      S32_Vec2_Checks.Check_Gapped_Volume;
      F16_Vec2_Checks.Check_Gapped_Volume;
      F32_Vec2_Checks.Check_Gapped_Volume;
      F64_Vec2_Checks.Check_Gapped_Volume;
      U8_Vec3_Checks.Check_Gapped_Volume;
      F16_Vec3_Checks.Check_Gapped_Volume;
      U16_Vec3_Checks.Check_Gapped_Volume;
      S16_Vec3_Checks.Check_Gapped_Volume;
      S32_Vec3_Checks.Check_Gapped_Volume;
      F32_Vec3_Checks.Check_Gapped_Volume;
      F64_Vec3_Checks.Check_Gapped_Volume;
      U8_Vec4_Checks.Check_Gapped_Volume;
      U16_Vec4_Checks.Check_Gapped_Volume;
      S16_Vec4_Checks.Check_Gapped_Volume;
      S32_Vec4_Checks.Check_Gapped_Volume;
      F16_Vec4_Checks.Check_Gapped_Volume;
      F32_Vec4_Checks.Check_Gapped_Volume;
      F64_Vec4_Checks.Check_Gapped_Volume;
   end Vector_Gapped_Volumes_Alias_Caller_Storage;

   procedure Packed_Equivalent_Strides_Are_Continuous (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
   begin
      UInt8_Checks.Check_Packed_Equivalent;
      Int8_Checks.Check_Packed_Equivalent;
      UInt16_Checks.Check_Packed_Equivalent;
      Int16_Checks.Check_Packed_Equivalent;
      Int32_Checks.Check_Packed_Equivalent;
      Float16_Checks.Check_Packed_Equivalent;
      Float32_Checks.Check_Packed_Equivalent;
      Float64_Checks.Check_Packed_Equivalent;
      U8_Vec2_Checks.Check_Packed_Equivalent;
      U16_Vec2_Checks.Check_Packed_Equivalent;
      S16_Vec2_Checks.Check_Packed_Equivalent;
      S32_Vec2_Checks.Check_Packed_Equivalent;
      F16_Vec2_Checks.Check_Packed_Equivalent;
      F32_Vec2_Checks.Check_Packed_Equivalent;
      F64_Vec2_Checks.Check_Packed_Equivalent;
      U8_Vec3_Checks.Check_Packed_Equivalent;
      F16_Vec3_Checks.Check_Packed_Equivalent;
      U16_Vec3_Checks.Check_Packed_Equivalent;
      S16_Vec3_Checks.Check_Packed_Equivalent;
      S32_Vec3_Checks.Check_Packed_Equivalent;
      F32_Vec3_Checks.Check_Packed_Equivalent;
      F64_Vec3_Checks.Check_Packed_Equivalent;
      U8_Vec4_Checks.Check_Packed_Equivalent;
      U16_Vec4_Checks.Check_Packed_Equivalent;
      S16_Vec4_Checks.Check_Packed_Equivalent;
      S32_Vec4_Checks.Check_Packed_Equivalent;
      F16_Vec4_Checks.Check_Packed_Equivalent;
      F32_Vec4_Checks.Check_Packed_Equivalent;
      F64_Vec4_Checks.Check_Packed_Equivalent;
   end Packed_Equivalent_Strides_Are_Continuous;

   procedure Two_Dimensional_Strides_Match_Row_Stride (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
   begin
      UInt8_Checks.Check_Two_Dimensional_Equivalence;
      Int8_Checks.Check_Two_Dimensional_Equivalence;
      UInt16_Checks.Check_Two_Dimensional_Equivalence;
      Int16_Checks.Check_Two_Dimensional_Equivalence;
      Int32_Checks.Check_Two_Dimensional_Equivalence;
      Float16_Checks.Check_Two_Dimensional_Equivalence;
      Float32_Checks.Check_Two_Dimensional_Equivalence;
      Float64_Checks.Check_Two_Dimensional_Equivalence;
      U8_Vec2_Checks.Check_Two_Dimensional_Equivalence;
      U16_Vec2_Checks.Check_Two_Dimensional_Equivalence;
      S16_Vec2_Checks.Check_Two_Dimensional_Equivalence;
      S32_Vec2_Checks.Check_Two_Dimensional_Equivalence;
      F16_Vec2_Checks.Check_Two_Dimensional_Equivalence;
      F32_Vec2_Checks.Check_Two_Dimensional_Equivalence;
      F64_Vec2_Checks.Check_Two_Dimensional_Equivalence;
      U8_Vec3_Checks.Check_Two_Dimensional_Equivalence;
      F16_Vec3_Checks.Check_Two_Dimensional_Equivalence;
      U16_Vec3_Checks.Check_Two_Dimensional_Equivalence;
      S16_Vec3_Checks.Check_Two_Dimensional_Equivalence;
      S32_Vec3_Checks.Check_Two_Dimensional_Equivalence;
      F32_Vec3_Checks.Check_Two_Dimensional_Equivalence;
      F64_Vec3_Checks.Check_Two_Dimensional_Equivalence;
      U8_Vec4_Checks.Check_Two_Dimensional_Equivalence;
      U16_Vec4_Checks.Check_Two_Dimensional_Equivalence;
      S16_Vec4_Checks.Check_Two_Dimensional_Equivalence;
      S32_Vec4_Checks.Check_Two_Dimensional_Equivalence;
      F16_Vec4_Checks.Check_Two_Dimensional_Equivalence;
      F32_Vec4_Checks.Check_Two_Dimensional_Equivalence;
      F64_Vec4_Checks.Check_Two_Dimensional_Equivalence;
   end Two_Dimensional_Strides_Match_Row_Stride;

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
      U8_Vec2_Checks.Check_No_Escape_And_Clone;
      U16_Vec2_Checks.Check_No_Escape_And_Clone;
      S16_Vec2_Checks.Check_No_Escape_And_Clone;
      S32_Vec2_Checks.Check_No_Escape_And_Clone;
      F16_Vec2_Checks.Check_No_Escape_And_Clone;
      F32_Vec2_Checks.Check_No_Escape_And_Clone;
      F64_Vec2_Checks.Check_No_Escape_And_Clone;
      U8_Vec3_Checks.Check_No_Escape_And_Clone;
      F16_Vec3_Checks.Check_No_Escape_And_Clone;
      U16_Vec3_Checks.Check_No_Escape_And_Clone;
      S16_Vec3_Checks.Check_No_Escape_And_Clone;
      S32_Vec3_Checks.Check_No_Escape_And_Clone;
      F32_Vec3_Checks.Check_No_Escape_And_Clone;
      F64_Vec3_Checks.Check_No_Escape_And_Clone;
      U8_Vec4_Checks.Check_No_Escape_And_Clone;
      U16_Vec4_Checks.Check_No_Escape_And_Clone;
      S16_Vec4_Checks.Check_No_Escape_And_Clone;
      S32_Vec4_Checks.Check_No_Escape_And_Clone;
      F16_Vec4_Checks.Check_No_Escape_And_Clone;
      F32_Vec4_Checks.Check_No_Escape_And_Clone;
      F64_Vec4_Checks.Check_No_Escape_And_Clone;
   end Views_Reject_Shallow_Escape_And_Clone;

   --  Canonical gapped layout offsets used by the focused tests.
   function Gap_Offset (I, J, K : Natural) return Natural
   is (I * 20 + J * 6 + K);

   function Is_Padding (Offset : Natural) return Boolean
   is (not (Offset mod 20 < 18 and then (Offset mod 20) mod 6 < 4));

   procedure Float16_Strided_Views_Preserve_Exact_Bits (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Patterns : constant array (0 .. 3) of Interfaces.Unsigned_16 :=
        (16#7C01#, 16#8000#, 16#0001#, 16#03FF#);
      Pad_C1   : constant Interfaces.Unsigned_16 := 16#7E55#;
      Pad_C3   : constant Interfaces.Unsigned_16 := 16#FC0F#;
      Scalars  : aliased OpenCV.Core.Float16_Mat_View.Buffer_Array :=
        (3 .. 42 => F16 (Pad_C1));
      Pixels   : aliased OpenCV.Core.Float16_Vec3_Mat_View.Buffer_Array :=
        (5 .. 44 => (others => F16 (Pad_C3)));
      Invoked  : Natural := 0;

      --  Row (0, 1, K) holds the patterns; Set writes them reversed into
      --  row (1, 2, K).
      procedure Scalar_Process (Image : in out OpenCV.Core.Mat) is
      begin
         Invoked := Invoked + 1;
         for P in Patterns'Range loop
            AUnit.Assertions.Assert
              (Bits
                 (OpenCV.Core.Float16_Access.Get
                    (Image, (0, 1, OpenCV.Size_Coordinate (P))))
               = Patterns (P),
               "Float16 C1 strided N-D Get must read exact caller bits");
            OpenCV.Core.Float16_Access.Set
              (Image,
               (1, 2, OpenCV.Size_Coordinate (P)),
               F16 (Patterns (3 - P)));
         end loop;
      end Scalar_Process;

      procedure Pixel_Process (Image : in out OpenCV.Core.Mat) is
         Value : constant OpenCV.Core.Float16_Vec3.Vector :=
           OpenCV.Core.Float16_Vec3_Access.Get (Image, (0, 1, 2));
      begin
         Invoked := Invoked + 1;
         AUnit.Assertions.Assert
           (Bits (Value (0)) = 16#7C01#
            and then Bits (Value (1)) = 16#8000#
            and then Bits (Value (2)) = 16#0001#,
            "Float16 C3 strided N-D Get must read exact caller bits");
         OpenCV.Core.Float16_Vec3_Access.Set
           (Image,
            (1, 2, 3),
            (F16 (16#03FF#), F16 (16#7C01#), F16 (16#8000#)));
      end Pixel_Process;
   begin
      for P in Patterns'Range loop
         Scalars (Scalars'First + Gap_Offset (0, 1, P)) := F16 (Patterns (P));
      end loop;
      OpenCV.Core.Float16_Mat_View.With_Writable_Strided_Mat_View
        (Scalars, (2, 3, 4), (20, 6, 1), Scalar_Process'Access);
      for P in Patterns'Range loop
         AUnit.Assertions.Assert
           (Bits (Scalars (Scalars'First + Gap_Offset (0, 1, P)))
            = Patterns (P)
            and then Bits (Scalars (Scalars'First + Gap_Offset (1, 2, P)))
                     = Patterns (3 - P),
            "Float16 C1 strided N-D Set must store exact caller bits");
      end loop;
      for Offset in 0 .. 39 loop
         if Is_Padding (Offset) then
            AUnit.Assertions.Assert
              (Bits (Scalars (Scalars'First + Offset)) = Pad_C1,
               "Float16 C1 strided padding bits must be untouched");
         end if;
      end loop;

      Pixels (Pixels'First + Gap_Offset (0, 1, 2)) :=
        (F16 (16#7C01#), F16 (16#8000#), F16 (16#0001#));
      OpenCV.Core.Float16_Vec3_Mat_View.With_Writable_Strided_Mat_View
        (Pixels, (2, 3, 4), (20, 6, 1), Pixel_Process'Access);
      declare
         Last : constant OpenCV.Core.Float16_Vec3.Vector :=
           Pixels (Pixels'First + Gap_Offset (1, 2, 3));
      begin
         AUnit.Assertions.Assert
           (Bits (Last (0)) = 16#03FF#
            and then Bits (Last (1)) = 16#7C01#
            and then Bits (Last (2)) = 16#8000#,
            "Float16 C3 strided N-D Set must store exact caller bits");
      end;
      for Offset in 0 .. 39 loop
         if Is_Padding (Offset) then
            for C in 0 .. 2 loop
               AUnit.Assertions.Assert
                 (Bits (Pixels (Pixels'First + Offset) (C)) = Pad_C3,
                  "Float16 C3 strided padding bits must be untouched");
            end loop;
         end if;
      end loop;
      AUnit.Assertions.Assert
        (Invoked = 2, "both Float16 strided callbacks must be invoked");
   end Float16_Strided_Views_Preserve_Exact_Bits;

   procedure Float64_Strided_Views_Do_Not_Narrow (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Precise : constant OpenCV.Float64_Value := 1.0 + 2.0**(-40);
      Other   : constant OpenCV.Float64_Value := -2.0 - 2.0**(-42);
      --  Variables keep the Float32 probes below out of static folding.
      Probe_1 : OpenCV.Float64_Value := Precise;
      Probe_2 : OpenCV.Float64_Value := Other;
      C1      : aliased OpenCV.Core.Float64_Mat_View.Buffer_Array :=
        (0 .. 39 => 0.0);
      C4      : aliased OpenCV.Core.Float64_Vec4_Mat_View.Buffer_Array :=
        (1 .. 40 => (others => 0.0));
      Count   : Natural := 0;

      procedure C1_Process (Image : in out OpenCV.Core.Mat) is
      begin
         Count := Count + 1;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Access.Get (Image, (0, 1, 2)) = Precise,
            "Float64 C1 strided N-D Get must not narrow");
         OpenCV.Core.Float64_Access.Set (Image, (1, 2, 3), Other);
      end C1_Process;

      procedure C4_Process (Image : in out OpenCV.Core.Mat) is
      begin
         Count := Count + 1;
         AUnit.Assertions.Assert
           (OpenCV.Core.Float64_Vec4_Access.Get (Image, (1, 0, 0))
            = (Precise, Other, -Precise, -Other),
            "Float64 C4 strided N-D Get must not narrow");
         OpenCV.Core.Float64_Vec4_Access.Set
           (Image, (0, 2, 1), (Other, Precise, -Other, -Precise));
      end C4_Process;
   begin
      Probe_1 := OpenCV.Float64_Value (OpenCV.Float32_Value (Probe_1));
      Probe_2 := OpenCV.Float64_Value (OpenCV.Float32_Value (Probe_2));
      AUnit.Assertions.Assert
        (Probe_1 /= Precise and then Probe_2 /= Other,
         "the Float64 fixtures must not be representable as Float32");

      C1 (Gap_Offset (0, 1, 2)) := Precise;
      OpenCV.Core.Float64_Mat_View.With_Writable_Strided_Mat_View
        (C1, (2, 3, 4), (20, 6, 1), C1_Process'Access);
      AUnit.Assertions.Assert
        (C1 (Gap_Offset (1, 2, 3)) = Other
         and then C1 (Gap_Offset (0, 1, 2)) = Precise,
         "Float64 C1 strided N-D Set must store the exact binary64 value");

      C4 (C4'First + Gap_Offset (1, 0, 0)) :=
        (Precise, Other, -Precise, -Other);
      OpenCV.Core.Float64_Vec4_Mat_View.With_Writable_Strided_Mat_View
        (C4, (2, 3, 4), (20, 6, 1), C4_Process'Access);
      AUnit.Assertions.Assert
        (C4 (C4'First + Gap_Offset (0, 2, 1))
         = (Other, Precise, -Other, -Precise),
         "Float64 C4 strided N-D Set must store exact binary64 values");
      for Offset in 0 .. 39 loop
         if Is_Padding (Offset) then
            AUnit.Assertions.Assert
              (C1 (Offset) = 0.0
               and then C4 (C4'First + Offset) = (0.0, 0.0, 0.0, 0.0),
               "Float64 strided padding must be untouched");
         end if;
      end loop;
      AUnit.Assertions.Assert
        (Count = 2, "both Float64 strided callbacks must be invoked");
   end Float64_Strided_Views_Do_Not_Narrow;

   Half_Positive : constant Positive := Positive'Last / 2;

   --  Attempts a UInt8 strided view that the binding must reject before
   --  Process runs, leaving caller Data unchanged.
   procedure Expect_Rejected
     (Length  : Natural;
      Shape   : OpenCV.Core.Dimension_Array;
      Strides : OpenCV.Core.Dimension_Stride_Array;
      Label   : String)
   is
      Storage : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (1 .. Length => 7);
      Invoked : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is
         pragma Unreferenced (Image);
      begin
         Invoked := True;
      end Process;

      procedure Attempt is
      begin
         OpenCV.Core.UInt8_Mat_View.With_Writable_Strided_Mat_View
           (Storage, Shape, Strides, Process'Access);
      end Attempt;
   begin
      Mat_Test_Support.Assert_Raises_OpenCV_Error
        (Attempt'Access, Label & " must raise OpenCV_Error");
      AUnit.Assertions.Assert (not Invoked, Label & " must not run Process");
      AUnit.Assertions.Assert
        ((for all Value of Storage => Value = 7),
         Label & " must leave caller Data unchanged");
   end Expect_Rejected;

   procedure Invalid_Strides_Rejected_Before_Process (Test : in out Fixture) is
      pragma Unreferenced (Test);
   begin
      Expect_Rejected (40, (2, 3, 4), (20, 1), "fewer strides than extents");
      Expect_Rejected
        (40, (2, 3, 4), (40, 20, 6, 1), "more strides than extents");
      Expect_Rejected (40, (2, 3, 4), (20, 6, 2), "final stride of 2");
      Expect_Rejected (40, (2, 3, 4), (20, 3, 1), "inner stride 3 < 1 * 4");
      Expect_Rejected (40, (2, 3, 4), (17, 6, 1), "outer stride 17 < 6 * 3");
      Expect_Rejected
        (40,
         (2, 4, 1),
         (Positive'Last, Half_Positive, 1),
         "nested-stride multiplication overflow");
      Expect_Rejected
        (40, (4, 2), (Half_Positive, 1), "outer capacity overflow");
      Expect_Rejected
        (39, (2, 3, 4), (20, 6, 1), "Data one element short of 2 * 20");
      Expect_Rejected
        (36,
         (2, 3, 4),
         (20, 6, 1),
         "Data reaching only the final logical element");
      Expect_Rejected (40, (1 => 4), (1 => 1), "a one-dimensional shape");
      Expect_Rejected (40, (2, 0, 4), (20, 6, 1), "a zero extent");
   end Invalid_Strides_Rejected_Before_Process;

   --  Views a (1, .., 1, 2) Int32 shape of Count dimensions with strides
   --  (2, .., 2, 1) and checks that the final coordinate maps to the last
   --  caller element.
   procedure View_High_Dimensional (Count : Positive; Invoked : out Boolean) is
      Storage : aliased OpenCV.Core.Int32_Mat_View.Buffer_Array :=
        (0 => 41, 1 => 42);
      Shape   : OpenCV.Core.Dimension_Array (1 .. Count) := (others => 1);
      Strides : OpenCV.Core.Dimension_Stride_Array (1 .. Count) :=
        (others => 2);

      procedure Process (Image : in out OpenCV.Core.Mat) is
         Last : OpenCV.Core.Index_Array (1 .. Count) := (others => 0);
      begin
         Invoked := True;
         Last (Count) := 1;
         AUnit.Assertions.Assert
           (Image.Dimension_Count = Count and then Image.Extent (Count) = 2,
            "a high-dimensional strided view must report every dimension");
         AUnit.Assertions.Assert
           (OpenCV.Core.Int32_Access.Get (Image, Last) = 42,
            "the final coordinate must map to the last Data element");
         OpenCV.Core.Int32_Access.Set (Image, Last, -9);
      end Process;
   begin
      Invoked := False;
      Shape (Count) := 2;
      Strides (Count) := 1;
      OpenCV.Core.Int32_Mat_View.With_Writable_Strided_Mat_View
        (Storage, Shape, Strides, Process'Access);
      AUnit.Assertions.Assert
        (Invoked and then Storage (1) = -9,
         "a high-dimensional strided view write must reach caller Data");
   end View_High_Dimensional;

   procedure Strided_Views_Follow_Native_Dimension_Limit
     (Test : in out Fixture)
   is
      pragma Unreferenced (Test);
      Native_Limit : constant Positive :=
        (if Module_Bridge_Probe.OpenCV_Major_Version >= 5 then 10 else 32);
      Invoked      : Boolean;
      Shape        : OpenCV.Core.Dimension_Array (1 .. Native_Limit + 1) :=
        (others => 1);
      Strides      :
        OpenCV.Core.Dimension_Stride_Array (1 .. Native_Limit + 1) :=
          (others => 2);
   begin
      View_High_Dimensional (Native_Limit, Invoked);
      AUnit.Assertions.Assert
        (Invoked,
         "a strided view at the native dimension limit must run Process");

      --  One above: rejected by the binding (Ada for 33 on OpenCV 4.x, the
      --  shim's native_maximum_mat_dimensions guard for 11 on OpenCV 5.0)
      --  before native construction.
      Shape (Shape'Last) := 2;
      Strides (Strides'Last) := 1;
      Expect_Rejected
        (2, Shape, Strides, "one dimension above the native Mat limit");
   end Strided_Views_Follow_Native_Dimension_Limit;

   procedure Extra_Trailing_Storage_Is_Untouched (Test : in out Fixture) is
      pragma Unreferenced (Test);
      --  40 required elements (2 * 20) plus 5 trailing elements.
      Storage : aliased OpenCV.Core.UInt16_Mat_View.Buffer_Array :=
        (0 .. 44 => 999);
      Invoked : Boolean := False;

      procedure Process (Image : in out OpenCV.Core.Mat) is
      begin
         Invoked := True;
         for I in 0 .. 1 loop
            for J in 0 .. 2 loop
               for K in 0 .. 3 loop
                  OpenCV.Core.UInt16_Access.Set
                    (Image,
                     (OpenCV.Size_Coordinate (I),
                      OpenCV.Size_Coordinate (J),
                      OpenCV.Size_Coordinate (K)),
                     OpenCV.UInt16_Value (Gap_Offset (I, J, K)));
               end loop;
            end loop;
         end loop;
      end Process;
   begin
      OpenCV.Core.UInt16_Mat_View.With_Writable_Strided_Mat_View
        (Storage, (2, 3, 4), (20, 6, 1), Process'Access);
      AUnit.Assertions.Assert (Invoked, "trailing-storage view must run");
      for Offset in Storage'Range loop
         if Offset >= 40 or else Is_Padding (Offset) then
            AUnit.Assertions.Assert
              (Storage (Offset) = 999,
               "padding and extra trailing storage must be untouched");
         else
            AUnit.Assertions.Assert
              (Natural (Storage (Offset)) = Offset,
               "every logical element must be written at its stride offset");
         end if;
      end loop;
   end Extra_Trailing_Storage_Is_Untouched;

   procedure Module_Interop_Is_Input_Only (Test : in out Fixture) is
      pragma Unreferenced (Test);
      Storage        : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
        (0 .. 39 => 5);
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
            "a strided N-D external view must reject an output handle");
      end Process;
   begin
      OpenCV.Core.UInt8_Mat_View.With_Writable_Strided_Mat_View
        (Storage, (2, 3, 4), (20, 6, 1), Process'Access);
      AUnit.Assertions.Assert
        (Input_Invoked and then not Output_Invoked,
         "strided N-D view input borrowing must work and output must not");
   end Module_Interop_Is_Input_Only;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("External strided N-D view raw ABI rejects malformed requests",
            Raw_ABI_Rejects_Malformed_Requests'Access));
      Result.Add_Test
        (Caller.Create
           ("External strided N-D raw ABI creates gapped and packed views",
            Raw_ABI_Creates_Strided_Views'Access));
      Result.Add_Test
        (Caller.Create
           ("External strided N-D view raw ABI marks a temporary view",
            Raw_ABI_Marks_Temporary_View'Access));
      Result.Add_Test
        (Caller.Create
           ("C1 gapped strided N-D views alias caller storage (x8)",
            C1_Gapped_Volumes_Alias_Caller_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("C2/C3/C4 gapped strided N-D views alias caller storage (x16)",
            Vector_Gapped_Volumes_Alias_Caller_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Packed-equivalent strides are continuous and borrowable (x24)",
            Packed_Equivalent_Strides_Are_Continuous'Access));
      Result.Add_Test
        (Caller.Create
           ("Strides (5, 1) match the 2-D Row_Stride overload (x24)",
            Two_Dimensional_Strides_Match_Row_Stride'Access));
      Result.Add_Test
        (Caller.Create
           ("Strided N-D views reject shallow escape; Clone is independent",
            Views_Reject_Shallow_Escape_And_Clone'Access));
      Result.Add_Test
        (Caller.Create
           ("Float16 C1/C3 strided N-D views preserve exact binary16 bits",
            Float16_Strided_Views_Preserve_Exact_Bits'Access));
      Result.Add_Test
        (Caller.Create
           ("Float64 C1/C4 strided N-D views do not narrow",
            Float64_Strided_Views_Do_Not_Narrow'Access));
      Result.Add_Test
        (Caller.Create
           ("Invalid N-D strides are rejected before Process",
            Invalid_Strides_Rejected_Before_Process'Access));
      Result.Add_Test
        (Caller.Create
           ("Strided N-D views follow the native dimension limit",
            Strided_Views_Follow_Native_Dimension_Limit'Access));
      Result.Add_Test
        (Caller.Create
           ("Strided N-D views leave extra trailing storage untouched",
            Extra_Trailing_Storage_Is_Untouched'Access));
      Result.Add_Test
        (Caller.Create
           ("Strided N-D views are Module_Interop input-only",
            Module_Interop_Is_Input_Only'Access));
      return Result'Access;
   end Suite;

end ND_Strided_Mat_View_Tests;
