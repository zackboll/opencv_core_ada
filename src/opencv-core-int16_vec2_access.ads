with OpenCV.Core.Int16_Vec2;

package OpenCV.Core.Int16_Vec2_Access is
   function Get (Image : Mat; Row, Column : Integer) return Int16_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Int16_Vec2.Vector);
   function Get (Image : Mat; Indices : Index_Array) return Int16_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Int16_Vec2.Vector);
end OpenCV.Core.Int16_Vec2_Access;
