with OpenCV.Core.UInt8_Vec2;

package OpenCV.Core.UInt8_Vec2_Access is
   function Get (Image : Mat; Row, Column : Integer) return UInt8_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : UInt8_Vec2.Vector);
   function Get (Image : Mat; Indices : Index_Array) return UInt8_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : UInt8_Vec2.Vector);
end OpenCV.Core.UInt8_Vec2_Access;
