with OpenCV.Core.Int8_Vec3;

--  Typed access to three-channel signed 8-bit (CV_8SC3) Mats. One vector is
--  one complete 3-byte element; component 0 is channel 0. Every signed value
--  -128 .. 127 is preserved exactly. The Row/Column overloads require a 2-D
--  Mat. The Index_Array overloads require one zero-based index per Mat
--  dimension; iteration order maps to OpenCV dimension order regardless of
--  the array's bounds. Depth must be exactly Int8 and the channel count
--  exactly 3; violations raise OpenCV_Error.

package OpenCV.Core.Int8_Vec3_Access is
   function Get (Image : Mat; Row, Column : Integer) return Int8_Vec3.Vector;
   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Int8_Vec3.Vector);
   function Get (Image : Mat; Indices : Index_Array) return Int8_Vec3.Vector;
   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Int8_Vec3.Vector);
end OpenCV.Core.Int8_Vec3_Access;
