with OpenCV.Core;

--  Test-only generic that checks OpenCV.Core.With_Selected_View for one typed
--  N-D Get/Set family. One Element is one complete Mat element (a whole
--  Vec2/Vec3/Vec4 for C2/C3/C4 layouts). Value_At must return pairwise
--  distinct values for offsets 0 .. 47, 100 .. 111, and 200.
--
--  The canonical fixture is an owning source of Shape (2, 3, 2, 4) whose
--  element (I, J, L, K) holds Value_At (packed ordinal). The selection
--  (Fix 1, Keep [0, 3), Fix 1, Keep [0, 4)) yields a gapped (3, 4) View with
--  View (J, K) = Source (1, J, 1, K); rows begin eight elements apart.

generic
   type Element is private;
   Element_Type : OpenCV.Core.Mat_Type;
   Name : String;
   with function Value_At (Offset : Natural) return Element;
   with
     function Get
       (Image : OpenCV.Core.Mat; Indices : OpenCV.Core.Index_Array)
        return Element;
   with
     procedure Set
       (Image   : in out OpenCV.Core.Mat;
        Indices : OpenCV.Core.Index_Array;
        Value   : Element);
package ND_Selected_View_Checks is

   --  Selections (7 .. 10) over the canonical fixture: depth, channels,
   --  Dimension_Count = 2, Rows = 3, Columns = 4, Total = 12, non-continuous;
   --  every View (J, K) reads Source (1, J, 1, K); View writes reach the
   --  source; source writes are visible through View; unselected source
   --  elements are unchanged after the callback.
   procedure Check_Middle_Drop;

end ND_Selected_View_Checks;
