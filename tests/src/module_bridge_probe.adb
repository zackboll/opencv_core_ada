with Ada.Exceptions;
with Interfaces.C;

package body Module_Bridge_Probe is

   subtype C_Int32 is Interfaces.C.int;
   subtype C_UInt8 is Interfaces.C.unsigned_char;
   type C_Int32_Array is array (Positive range <>) of aliased C_Int32
   with Convention => C;

   use type C_Int32;

   function Probe_Version_Major return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_version_major";

   function Probe_Input
     (Handle  : OpenCV.Core.Module_Interop.Input_Mat_Handle;
      Rows    : access C_Int32;
      Columns : access C_Int32;
      Depth   : access C_Int32;
      Value   : access C_Int32) return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_input";

   function Probe_Mutate
     (Handle : OpenCV.Core.Module_Interop.Output_Mat_Handle; Value : C_UInt8)
      return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_mutate";

   function Probe_Create
     (Handle  : OpenCV.Core.Module_Interop.Output_Mat_Handle;
      Rows    : C_Int32;
      Columns : C_Int32;
      Value   : C_UInt8) return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_create";

   function Probe_Invalid_Inputs return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_invalid_inputs";

   subtype C_Float32 is Interfaces.C.C_float;
   subtype Probe_Index_Array is C_Int32_Array (1 .. 32);

   function Probe_Sparse_Input
     (Handle          :
        OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Index_Count     : C_Int32;
      Indices         : access constant C_Int32;
      Extent_Capacity : C_Int32;
      Extents         : access C_Int32;
      Depth           : access C_Int32;
      Channels        : access C_Int32;
      Nodes           : access C_Int32;
      Value           : access C_Int32) return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_sparse_input";

   function Probe_Sparse_Inputs
     (Left            :
        OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Right           :
        OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Index_Count     : C_Int32;
      Left_Indices    : access constant C_Int32;
      Right_Indices   : access constant C_Int32;
      Extent_Capacity : C_Int32;
      Left_Extents    : access C_Int32;
      Right_Extents   : access C_Int32;
      Left_Nodes      : access C_Int32;
      Right_Nodes     : access C_Int32;
      Left_Depth      : access C_Int32;
      Right_Depth     : access C_Int32;
      Left_Channels   : access C_Int32;
      Right_Channels  : access C_Int32;
      Left_Value      : access C_Int32;
      Right_Value     : access C_Int32) return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_sparse_inputs";

   function Probe_Sparse_Mutate
     (Handle : OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle;
      Value  : C_Float32) return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_sparse_mutate";

   function Probe_Sparse_Create
     (Handle   : OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle;
      Extent_0 : C_Int32;
      Extent_1 : C_Int32;
      Value    : C_Float32) return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_sparse_create";

   function Probe_Sparse_Invalid_Inputs return C_Int32
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_module_probe_sparse_invalid_inputs";

   procedure Raise_On_Error (Status : C_Int32; Operation : String) is
   begin
      if Status /= 0 then
         Ada.Exceptions.Raise_Exception
           (OpenCV.OpenCV_Error'Identity, Operation & " failed");
      end if;
   end Raise_On_Error;

   function OpenCV_Major_Version return Natural is
   begin
      return Natural (Probe_Version_Major);
   end OpenCV_Major_Version;

   procedure Inspect
     (Handle      : OpenCV.Core.Module_Interop.Input_Mat_Handle;
      Observation : out Input_Observation)
   is
      Rows    : aliased C_Int32 := 0;
      Columns : aliased C_Int32 := 0;
      Depth   : aliased C_Int32 := 0;
      Value   : aliased C_Int32 := 0;
   begin
      Raise_On_Error
        (Probe_Input
           (Handle, Rows'Access, Columns'Access, Depth'Access, Value'Access),
         "module bridge input probe");
      Observation :=
        (Integer (Rows), Integer (Columns), Integer (Depth), Integer (Value));
   end Inspect;

   procedure Mutate
     (Handle : OpenCV.Core.Module_Interop.Output_Mat_Handle;
      Value  : Interfaces.Unsigned_8) is
   begin
      Raise_On_Error
        (Probe_Mutate (Handle, C_UInt8 (Value)),
         "module bridge mutation probe");
   end Mutate;

   procedure Create
     (Handle  : OpenCV.Core.Module_Interop.Output_Mat_Handle;
      Rows    : Natural;
      Columns : Natural;
      Value   : Interfaces.Unsigned_8) is
   begin
      Raise_On_Error
        (Probe_Create
           (Handle, C_Int32 (Rows), C_Int32 (Columns), C_UInt8 (Value)),
         "module bridge create probe");
   end Create;

   procedure Check_Invalid_Inputs is
   begin
      Raise_On_Error
        (Probe_Invalid_Inputs, "module bridge invalid-input probe");
   end Check_Invalid_Inputs;

   procedure Inspect_Sparse
     (Handle      : OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Indices     : OpenCV.Core.Index_Array;
      Observation : out Sparse_Input_Observation)
   is
      Native_Indices : aliased Probe_Index_Array := (others => 0);
      Extents        : aliased Probe_Index_Array := (others => 0);
      Depth          : aliased C_Int32 := 0;
      Channels       : aliased C_Int32 := 0;
      Nodes          : aliased C_Int32 := 0;
      Value          : aliased C_Int32 := 0;
   begin
      if Indices'Length not in 1 .. Probe_Index_Array'Length then
         raise Constraint_Error with "sparse probe index rank";
      end if;
      for Axis in Indices'Range loop
         Native_Indices (Native_Indices'First + (Axis - Indices'First)) :=
           C_Int32 (Indices (Axis));
      end loop;
      Raise_On_Error
        (Probe_Sparse_Input
           (Handle,
            C_Int32 (Indices'Length),
            Native_Indices (Native_Indices'First)'Access,
            C_Int32 (Extents'Length),
            Extents (Extents'First)'Access,
            Depth'Access,
            Channels'Access,
            Nodes'Access,
            Value'Access),
         "module bridge sparse input probe");
      Observation :=
        (Dimensions => Integer (Indices'Length),
         Extents    => (others => 0),
         Depth      => Integer (Depth),
         Channels   => Integer (Channels),
         Nodes      => Integer (Nodes),
         Value      => Integer (Value));
      for Axis in 1 .. Indices'Length loop
         Observation.Extents (Axis) :=
           OpenCV.Size_Coordinate (Extents (Extents'First + Axis - 1));
      end loop;
   end Inspect_Sparse;

   procedure Inspect_Sparse_Pair
     (Left              :
        OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Right             :
        OpenCV.Core.Sparse.Module_Interop.Input_Sparse_Mat_Handle;
      Left_Indices      : OpenCV.Core.Index_Array;
      Right_Indices     : OpenCV.Core.Index_Array;
      Left_Observation  : out Sparse_Input_Observation;
      Right_Observation : out Sparse_Input_Observation)
   is
      Native_Left    : aliased Probe_Index_Array := (others => 0);
      Native_Right   : aliased Probe_Index_Array := (others => 0);
      Left_Extents   : aliased Probe_Index_Array := (others => 0);
      Right_Extents  : aliased Probe_Index_Array := (others => 0);
      Left_Nodes     : aliased C_Int32 := 0;
      Right_Nodes    : aliased C_Int32 := 0;
      Left_Depth     : aliased C_Int32 := 0;
      Right_Depth    : aliased C_Int32 := 0;
      Left_Channels  : aliased C_Int32 := 0;
      Right_Channels : aliased C_Int32 := 0;
      Left_Value     : aliased C_Int32 := 0;
      Right_Value    : aliased C_Int32 := 0;
   begin
      if Left_Indices'Length /= Right_Indices'Length
        or else Left_Indices'Length not in 1 .. Probe_Index_Array'Length
      then
         raise Constraint_Error with "sparse probe pair index rank";
      end if;
      for Axis in Left_Indices'Range loop
         Native_Left (Native_Left'First + (Axis - Left_Indices'First)) :=
           C_Int32 (Left_Indices (Axis));
      end loop;
      for Axis in Right_Indices'Range loop
         Native_Right (Native_Right'First + (Axis - Right_Indices'First)) :=
           C_Int32 (Right_Indices (Axis));
      end loop;
      Raise_On_Error
        (Probe_Sparse_Inputs
           (Left,
            Right,
            C_Int32 (Left_Indices'Length),
            Native_Left (Native_Left'First)'Access,
            Native_Right (Native_Right'First)'Access,
            C_Int32 (Left_Extents'Length),
            Left_Extents (Left_Extents'First)'Access,
            Right_Extents (Right_Extents'First)'Access,
            Left_Nodes'Access,
            Right_Nodes'Access,
            Left_Depth'Access,
            Right_Depth'Access,
            Left_Channels'Access,
            Right_Channels'Access,
            Left_Value'Access,
            Right_Value'Access),
         "module bridge sparse pair probe");
      Left_Observation :=
        (Dimensions => Integer (Left_Indices'Length),
         Extents    => (others => 0),
         Depth      => Integer (Left_Depth),
         Channels   => Integer (Left_Channels),
         Nodes      => Integer (Left_Nodes),
         Value      => Integer (Left_Value));
      Right_Observation :=
        (Dimensions => Integer (Right_Indices'Length),
         Extents    => (others => 0),
         Depth      => Integer (Right_Depth),
         Channels   => Integer (Right_Channels),
         Nodes      => Integer (Right_Nodes),
         Value      => Integer (Right_Value));
      for Axis in 1 .. Left_Indices'Length loop
         Left_Observation.Extents (Axis) :=
           OpenCV.Size_Coordinate
             (Left_Extents (Left_Extents'First + Axis - 1));
         Right_Observation.Extents (Axis) :=
           OpenCV.Size_Coordinate
             (Right_Extents (Right_Extents'First + Axis - 1));
      end loop;
   end Inspect_Sparse_Pair;

   procedure Mutate_Sparse
     (Handle : OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle;
      Value  : Interfaces.IEEE_Float_32) is
   begin
      Raise_On_Error
        (Probe_Sparse_Mutate (Handle, C_Float32 (Value)),
         "module bridge sparse mutation probe");
   end Mutate_Sparse;

   procedure Create_Sparse
     (Handle   : OpenCV.Core.Sparse.Module_Interop.Output_Sparse_Mat_Handle;
      Extent_0 : Natural;
      Extent_1 : Natural;
      Value    : Interfaces.IEEE_Float_32) is
   begin
      Raise_On_Error
        (Probe_Sparse_Create
           (Handle, C_Int32 (Extent_0), C_Int32 (Extent_1), C_Float32 (Value)),
         "module bridge sparse create probe");
   end Create_Sparse;

   procedure Check_Invalid_Sparse_Inputs is
   begin
      Raise_On_Error
        (Probe_Sparse_Invalid_Inputs,
         "module bridge sparse invalid-input probe");
   end Check_Invalid_Sparse_Inputs;

end Module_Bridge_Probe;
