with OpenCV.Core.Float16_Vec2;

--  Exact-bit typed access to two-channel Float16 (CV_16FC2) Mats. One vector
--  is one complete 4-byte element; component 0 is channel 0. Each component
--  is the stored IEEE-754 binary16 encoding: signed zeros, subnormals,
--  infinities and NaN payloads (including signaling NaNs) are never converted
--  or canonicalized. The Row/Column overloads require a 2-D Mat. The
--  Index_Array overloads require one zero-based index per Mat dimension;
--  iteration order maps to OpenCV dimension order regardless of the array's
--  bounds. Depth must be exactly Float16 and the channel count exactly 2;
--  violations raise OpenCV_Error.

package OpenCV.Core.Float16_Vec2_Access is
   function Get
     (Image : Mat; Row, Column : Integer) return Float16_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Float16_Vec2.Vector);
   function Get
     (Image : Mat; Indices : Index_Array) return Float16_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Float16_Vec2.Vector);
end OpenCV.Core.Float16_Vec2_Access;
