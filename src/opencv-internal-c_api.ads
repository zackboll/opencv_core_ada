with Interfaces;
with Interfaces.C;
with System;

package OpenCV.Internal.C_API is

   type Status is new Interfaces.Integer_32;

   Success                : constant Status := 0;
   Error_OpenCV           : constant Status := 1;
   Error_Standard_CPP     : constant Status := 2;
   Error_Unknown          : constant Status := 3;
   Error_Invalid_Argument : constant Status := 4;

   type Mat_Handle is new System.Address;
   Null_Mat_Handle : constant Mat_Handle := Mat_Handle (System.Null_Address);

   subtype C_Int32 is Interfaces.Integer_32;
   subtype C_Double is Interfaces.C.double;

   type Scalar is record
      Component_0 : C_Double;
      Component_1 : C_Double;
      Component_2 : C_Double;
      Component_3 : C_Double;
   end record
   with Convention => C;

   Depth_UInt8   : constant C_Int32 := 0;
   Depth_Int8    : constant C_Int32 := 1;
   Depth_UInt16  : constant C_Int32 := 2;
   Depth_Int16   : constant C_Int32 := 3;
   Depth_Int32   : constant C_Int32 := 4;
   Depth_Float32 : constant C_Int32 := 5;
   Depth_Float64 : constant C_Int32 := 6;
   Depth_Float16 : constant C_Int32 := 7;

   subtype C_Boolean is Interfaces.Unsigned_8;
   C_False : constant C_Boolean := 0;
   C_True  : constant C_Boolean := 1;

   function Last_Error_Message return String;

   function Mat_Create (Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_create";

   function Mat_Create_2D
     (Rows     : C_Int32;
      Columns  : C_Int32;
      Depth    : C_Int32;
      Channels : C_Int32;
      Result   : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_create_2d";

   function Mat_Copy
     (Source : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_copy";

   procedure Mat_Destroy (Self : Mat_Handle)
   with Import, Convention => C, External_Name => "opencv_core_mat_destroy";

   function Mat_Is_Empty
     (Self : Mat_Handle; Result : access C_Boolean) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_is_empty";

   function Mat_Rows (Self : Mat_Handle; Result : access C_Int32) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_rows";

   function Mat_Columns
     (Self : Mat_Handle; Result : access C_Int32) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_columns";

   function Mat_Channels
     (Self : Mat_Handle; Result : access C_Int32) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_channels";

   function Mat_Depth
     (Self : Mat_Handle; Result : access C_Int32) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_depth";

   function Mat_Set_To (Self : Mat_Handle; Value : access Scalar) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_set_to";

   function Mat_Sum (Self : Mat_Handle; Result : access Scalar) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_sum";

end OpenCV.Internal.C_API;
