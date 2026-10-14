with Ada.Text_IO;
with OpenCV;
with OpenCV.Core;
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

--  Independent measurements of the actual public types, not C ABI records.

procedure Representation_Measurements is
   generic
      type Element is private;
      Bits, Native_Alignment : Positive;
      Name : String;
   procedure Measure;
   procedure Measure is
      type Buffer is array (Natural range <>) of Element;
      subtype Two_Elements is Buffer (7 .. 8);
   begin
      if Element'Size /= Bits
        or else Element'Object_Size /= Bits
        or else Buffer'Component_Size /= Bits
        or else Element'Alignment > Native_Alignment
      then
         raise Program_Error with Name & " representation mismatch";
      end if;
      Ada.Text_IO.Put_Line
        (Name
         & " Size="
         & Natural'Image (Element'Size)
         & " Object_Size="
         & Natural'Image (Element'Object_Size)
         & " Component_Size="
         & Natural'Image (Buffer'Component_Size)
         & " Alignment="
         & Natural'Image (Element'Alignment)
         & " Native_Alignment="
         & Natural'Image (Native_Alignment)
         & " Array_Size="
         & Natural'Image (Two_Elements'Size));
   end Measure;
   procedure U8 is new Measure (OpenCV.UInt8_Value, 8, 1, "UInt8");
   procedure I8 is new Measure (OpenCV.Int8_Value, 8, 1, "Int8");
   procedure U16 is new Measure (OpenCV.UInt16_Value, 16, 2, "UInt16");
   procedure I16 is new Measure (OpenCV.Int16_Value, 16, 2, "Int16");
   procedure I32 is new Measure (OpenCV.Int32_Value, 32, 4, "Int32");
   procedure F16 is new Measure (OpenCV.Core.Float16_Value, 16, 2, "Float16");
   procedure F32 is new Measure (OpenCV.Float32_Value, 32, 4, "Float32");
   procedure F64 is new Measure (OpenCV.Float64_Value, 64, 8, "Float64");
   procedure U82 is new
     Measure (OpenCV.Core.UInt8_Vec2.Vector, 16, 1, "UInt8 Vec2");
   procedure U83 is new
     Measure (OpenCV.Core.UInt8_Vec3.Vector, 24, 1, "UInt8 Vec3");
   procedure U84 is new
     Measure (OpenCV.Core.UInt8_Vec4.Vector, 32, 1, "UInt8 Vec4");
   procedure I82 is new
     Measure (OpenCV.Core.Int8_Vec2.Vector, 16, 1, "Int8 Vec2");
   procedure I83 is new
     Measure (OpenCV.Core.Int8_Vec3.Vector, 24, 1, "Int8 Vec3");
   procedure I84 is new
     Measure (OpenCV.Core.Int8_Vec4.Vector, 32, 1, "Int8 Vec4");
   procedure U162 is new
     Measure (OpenCV.Core.UInt16_Vec2.Vector, 32, 2, "UInt16 Vec2");
   procedure U163 is new
     Measure (OpenCV.Core.UInt16_Vec3.Vector, 48, 2, "UInt16 Vec3");
   procedure U164 is new
     Measure (OpenCV.Core.UInt16_Vec4.Vector, 64, 2, "UInt16 Vec4");
   procedure I162 is new
     Measure (OpenCV.Core.Int16_Vec2.Vector, 32, 2, "Int16 Vec2");
   procedure I163 is new
     Measure (OpenCV.Core.Int16_Vec3.Vector, 48, 2, "Int16 Vec3");
   procedure I164 is new
     Measure (OpenCV.Core.Int16_Vec4.Vector, 64, 2, "Int16 Vec4");
   procedure I322 is new
     Measure (OpenCV.Core.Int32_Vec2.Vector, 64, 4, "Int32 Vec2");
   procedure I323 is new
     Measure (OpenCV.Core.Int32_Vec3.Vector, 96, 4, "Int32 Vec3");
   procedure I324 is new
     Measure (OpenCV.Core.Int32_Vec4.Vector, 128, 4, "Int32 Vec4");
   procedure F162 is new
     Measure (OpenCV.Core.Float16_Vec2.Vector, 32, 2, "Float16 Vec2");
   procedure F163 is new
     Measure (OpenCV.Core.Float16_Vec3.Vector, 48, 2, "Float16 Vec3");
   procedure F164 is new
     Measure (OpenCV.Core.Float16_Vec4.Vector, 64, 2, "Float16 Vec4");
   procedure F322 is new
     Measure (OpenCV.Core.Float32_Vec2.Vector, 64, 4, "Float32 Vec2");
   procedure F323 is new
     Measure (OpenCV.Core.Float32_Vec3.Vector, 96, 4, "Float32 Vec3");
   procedure F324 is new
     Measure (OpenCV.Core.Float32_Vec4.Vector, 128, 4, "Float32 Vec4");
   procedure F642 is new
     Measure (OpenCV.Core.Float64_Vec2.Vector, 128, 8, "Float64 Vec2");
   procedure F643 is new
     Measure (OpenCV.Core.Float64_Vec3.Vector, 192, 8, "Float64 Vec3");
   procedure F644 is new
     Measure (OpenCV.Core.Float64_Vec4.Vector, 256, 8, "Float64 Vec4");
begin
   U8;
   I8;
   U16;
   I16;
   I32;
   F16;
   F32;
   F64;
   U82;
   U83;
   U84;
   I82;
   I83;
   I84;
   U162;
   U163;
   U164;
   I162;
   I163;
   I164;
   I322;
   I323;
   I324;
   F162;
   F163;
   F164;
   F322;
   F323;
   F324;
   F642;
   F643;
   F644;
end Representation_Measurements;
