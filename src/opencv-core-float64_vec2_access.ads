with OpenCV.Core.Float64_Vec2;

package OpenCV.Core.Float64_Vec2_Access is
   function Get
     (Image : Mat; Row, Column : Integer) return Float64_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : Float64_Vec2.Vector);
   function Get
     (Image : Mat; Indices : Index_Array) return Float64_Vec2.Vector;
   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : Float64_Vec2.Vector);
end OpenCV.Core.Float64_Vec2_Access;
