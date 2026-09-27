with OpenCV.Core.UInt8_Vec4;

package OpenCV.Core.UInt8_Vec4_Access is
   function Get (Image : Mat; Row, Column : Integer) return UInt8_Vec4.Vector;
   procedure Set
     (Image : in out Mat; Row, Column : Integer; Value : UInt8_Vec4.Vector);
   function Get (Image : Mat; Indices : Index_Array) return UInt8_Vec4.Vector;
   procedure Set
     (Image : in out Mat; Indices : Index_Array; Value : UInt8_Vec4.Vector);
end OpenCV.Core.UInt8_Vec4_Access;
