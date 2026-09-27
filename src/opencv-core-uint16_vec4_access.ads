with OpenCV.Core.UInt16_Vec4;

package OpenCV.Core.UInt16_Vec4_Access is
   function Get (Image : Mat; Row, Column : Integer) return UInt16_Vec4.Vector;
   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : UInt16_Vec4.Vector);
   function Get (Image : Mat; Indices : Index_Array) return UInt16_Vec4.Vector;
   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : UInt16_Vec4.Vector);
end OpenCV.Core.UInt16_Vec4_Access;
