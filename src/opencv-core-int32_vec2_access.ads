with OpenCV.Core.Int32_Vec2;

package OpenCV.Core.Int32_Vec2_Access is
   function Get (Image : Mat; Row, Column : Integer) return Int32_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Int32_Vec2.Vector);
   function Get (Image : Mat; Indices : Index_Array) return Int32_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Int32_Vec2.Vector);
end OpenCV.Core.Int32_Vec2_Access;
