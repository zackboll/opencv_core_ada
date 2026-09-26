with OpenCV.Core.Float32_Vec2;

package OpenCV.Core.Float32_Vec2_Access is
   function Get
     (Image : Mat; Row, Column : Integer) return Float32_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Float32_Vec2.Vector);
   function Get
     (Image : Mat; Indices : Index_Array) return Float32_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Float32_Vec2.Vector);
end OpenCV.Core.Float32_Vec2_Access;
