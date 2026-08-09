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
   subtype C_UInt8 is Interfaces.Unsigned_8;
   subtype C_UInt64 is Interfaces.Unsigned_64;
   subtype C_Float32 is Interfaces.C.C_float;
   subtype C_Double is Interfaces.C.double;

   type Scalar is record
      Component_0 : C_Double;
      Component_1 : C_Double;
      Component_2 : C_Double;
      Component_3 : C_Double;
   end record
   with Convention => C;

   type UInt8_Vec3 is record
      Component_0 : C_UInt8;
      Component_1 : C_UInt8;
      Component_2 : C_UInt8;
   end record
   with Convention => C;

   type Float32_Vec3 is record
      Component_0 : C_Float32;
      Component_1 : C_Float32;
      Component_2 : C_Float32;
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

   Norm_L1  : constant C_Int32 := 1;
   Norm_L2  : constant C_Int32 := 2;
   Norm_Inf : constant C_Int32 := 3;

   Normalize_L1      : constant C_Int32 := 1;
   Normalize_L2      : constant C_Int32 := 2;
   Normalize_Inf     : constant C_Int32 := 3;
   Normalize_Min_Max : constant C_Int32 := 4;

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

   function Mat_Clone
     (Source : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_clone";

   function Mat_Convert_To
     (Source : Mat_Handle;
      Depth  : C_Int32;
      Scale  : C_Double;
      Offset : C_Double;
      Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_convert_to";

   function Mat_Normalize
     (Source : Mat_Handle;
      Kind   : C_Int32;
      Alpha  : C_Double;
      Beta   : C_Double;
      Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_normalize";

   function Mat_Add
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_add";

   function Mat_Subtract
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_subtract";

   function Mat_Region
     (Source : Mat_Handle;
      X      : C_Int32;
      Y      : C_Int32;
      Width  : C_Int32;
      Height : C_Int32;
      Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_region";

   function Mat_Row_View
     (Source : Mat_Handle; Row : C_Int32; Result : access Mat_Handle)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_row_view";

   function Mat_Column_View
     (Source : Mat_Handle; Column : C_Int32; Result : access Mat_Handle)
      return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_column_view";

   function Mat_Row_Range_View
     (Source : Mat_Handle;
      Start  : C_Int32;
      Stop   : C_Int32;
      Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_row_range_view";

   function Mat_Column_Range_View
     (Source : Mat_Handle;
      Start  : C_Int32;
      Stop   : C_Int32;
      Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_column_range_view";

   function Mat_Reshape
     (Source   : Mat_Handle;
      Channels : C_Int32;
      Rows     : C_Int32;
      Result   : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_reshape";

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

   function Mat_Total
     (Self : Mat_Handle; Result : access C_UInt64) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_total";

   function Mat_Element_Size
     (Self : Mat_Handle; Result : access C_UInt64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_element_size";

   function Mat_Channel_Size
     (Self : Mat_Handle; Result : access C_UInt64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_channel_size";

   function Mat_Is_Continuous
     (Self : Mat_Handle; Result : access C_Boolean) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_is_continuous";

   function Mat_Is_Submatrix
     (Self : Mat_Handle; Result : access C_Boolean) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_is_submatrix";

   function Mat_Get_UInt8
     (Self : Mat_Handle; Row, Column : C_Int32; Result : access C_UInt8)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_get_uint8";

   function Mat_Set_UInt8
     (Self : Mat_Handle; Row, Column : C_Int32; Value : C_UInt8) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_set_uint8";

   function Mat_Get_Float32
     (Self : Mat_Handle; Row, Column : C_Int32; Result : access C_Float32)
      return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_get_float32";

   function Mat_Set_Float32
     (Self : Mat_Handle; Row, Column : C_Int32; Value : C_Float32)
      return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_set_float32";

   function Mat_Read_UInt8_Row
     (Self          : Mat_Handle;
      Row           : C_Int32;
      Data          : System.Address;
      Element_Count : C_UInt64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_read_uint8_row";

   function Mat_Write_UInt8_Row
     (Self          : Mat_Handle;
      Row           : C_Int32;
      Data          : System.Address;
      Element_Count : C_UInt64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_write_uint8_row";

   function Mat_Read_Float32_Row
     (Self          : Mat_Handle;
      Row           : C_Int32;
      Data          : System.Address;
      Element_Count : C_UInt64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_read_float32_row";

   function Mat_Write_Float32_Row
     (Self          : Mat_Handle;
      Row           : C_Int32;
      Data          : System.Address;
      Element_Count : C_UInt64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_write_float32_row";

   function Mat_Get_UInt8_Vec3
     (Self   : Mat_Handle;
      Row    : C_Int32;
      Column : C_Int32;
      Result : access UInt8_Vec3) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_get_uint8_vec3";

   function Mat_Set_UInt8_Vec3
     (Self   : Mat_Handle;
      Row    : C_Int32;
      Column : C_Int32;
      Value  : access constant UInt8_Vec3) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_set_uint8_vec3";

   function Mat_Get_Float32_Vec3
     (Self   : Mat_Handle;
      Row    : C_Int32;
      Column : C_Int32;
      Result : access Float32_Vec3) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_get_float32_vec3";

   function Mat_Set_Float32_Vec3
     (Self   : Mat_Handle;
      Row    : C_Int32;
      Column : C_Int32;
      Value  : access constant Float32_Vec3) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_set_float32_vec3";

   function Mat_Read_UInt8_Vec3_Row
     (Self          : Mat_Handle;
      Row           : C_Int32;
      Data          : System.Address;
      Element_Count : C_UInt64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_read_uint8_vec3_row";

   function Mat_Write_UInt8_Vec3_Row
     (Self          : Mat_Handle;
      Row           : C_Int32;
      Data          : System.Address;
      Element_Count : C_UInt64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_write_uint8_vec3_row";

   function Mat_Read_Float32_Vec3_Row
     (Self          : Mat_Handle;
      Row           : C_Int32;
      Data          : System.Address;
      Element_Count : C_UInt64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_read_float32_vec3_row";

   function Mat_Write_Float32_Vec3_Row
     (Self          : Mat_Handle;
      Row           : C_Int32;
      Data          : System.Address;
      Element_Count : C_UInt64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_write_float32_vec3_row";

   function Mat_Set_To (Self : Mat_Handle; Value : access Scalar) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_set_to";

   function Mat_Sum (Self : Mat_Handle; Result : access Scalar) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_sum";

   function Mat_Mean (Self : Mat_Handle; Result : access Scalar) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_mean";

   function Mat_Mean_Std_Dev
     (Self               : Mat_Handle;
      Mean               : access Scalar;
      Standard_Deviation : access Scalar) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_mean_std_dev";

   function Mat_Norm
     (Self : Mat_Handle; Kind : C_Int32; Result : access C_Double)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_norm";

   function Mat_Min_Max_Loc
     (Self      : Mat_Handle;
      Minimum   : access C_Double;
      Maximum   : access C_Double;
      Minimum_X : access C_Int32;
      Minimum_Y : access C_Int32;
      Maximum_X : access C_Int32;
      Maximum_Y : access C_Int32) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_min_max_loc";

end OpenCV.Internal.C_API;
