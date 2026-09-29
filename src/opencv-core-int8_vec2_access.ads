with OpenCV.Core.Int8_Vec2;

--  Typed access to two-channel signed 8-bit (CV_8SC2) Mats. One vector is
--  one complete 2-byte element; component 0 is channel 0. Every signed value
--  -128 .. 127 is preserved exactly. The Row/Column overloads require a 2-D
--  Mat. The Index_Array overloads require one zero-based index per Mat
--  dimension; iteration order maps to OpenCV dimension order regardless of
--  the array's bounds. Depth must be exactly Int8 and the channel count
--  exactly 2; violations raise OpenCV_Error.

package OpenCV.Core.Int8_Vec2_Access is
   function Get (Image : Mat; Row, Column : Integer) return Int8_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Int8_Vec2.Vector);
   function Get (Image : Mat; Indices : Index_Array) return Int8_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Int8_Vec2.Vector);
end OpenCV.Core.Int8_Vec2_Access;
