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

   type File_Storage_Handle is new System.Address;
   Null_File_Storage_Handle : constant File_Storage_Handle :=
     File_Storage_Handle (System.Null_Address);

   subtype C_Int32 is Interfaces.Integer_32;
   subtype C_UInt8 is Interfaces.Unsigned_8;
   subtype C_UInt64 is Interfaces.Unsigned_64;
   subtype C_Float32 is Interfaces.C.C_float;
   subtype C_Double is Interfaces.C.double;

   type Mat_Handle_Array is array (Natural range <>) of aliased Mat_Handle
   with Convention => C;

   type C_Int32_Array is array (Natural range <>) of aliased C_Int32
   with Convention => C;

   type Scalar is record
      Component_0 : C_Double;
      Component_1 : C_Double;
      Component_2 : C_Double;
      Component_3 : C_Double;
   end record
   with Convention => C;

   type Point is record
      X : C_Int32;
      Y : C_Int32;
   end record
   with Convention => C;

   type Point_Array is array (Natural range <>) of aliased Point
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

   Compare_Equal            : constant C_Int32 := 0;
   Compare_Not_Equal        : constant C_Int32 := 1;
   Compare_Less_Than        : constant C_Int32 := 2;
   Compare_Less_Or_Equal    : constant C_Int32 := 3;
   Compare_Greater_Than     : constant C_Int32 := 4;
   Compare_Greater_Or_Equal : constant C_Int32 := 5;

   Flip_Vertical   : constant C_Int32 := 0;
   Flip_Horizontal : constant C_Int32 := 1;
   Flip_Both_Axes  : constant C_Int32 := C_Int32'Val (-1);

   Border_Constant    : constant C_Int32 := 0;
   Border_Replicate   : constant C_Int32 := 1;
   Border_Reflect     : constant C_Int32 := 2;
   Border_Reflect_101 : constant C_Int32 := 3;
   Border_Wrap        : constant C_Int32 := 4;

   Rotate_90_Clockwise        : constant C_Int32 := 0;
   Rotate_180                 : constant C_Int32 := 1;
   Rotate_90_Counterclockwise : constant C_Int32 := 2;

   Reduce_Across_Rows    : constant C_Int32 := 0;
   Reduce_Across_Columns : constant C_Int32 := 1;

   Reduce_Sum            : constant C_Int32 := 0;
   Reduce_Average        : constant C_Int32 := 1;
   Reduce_Maximum        : constant C_Int32 := 2;
   Reduce_Minimum        : constant C_Int32 := 3;
   Reduce_Sum_Of_Squares : constant C_Int32 := 4;

   Default_Output_Depth : constant C_Int32 := C_Int32'Val (-1);

   Transposed_Product_Transpose_Times_Self : constant C_UInt8 := 0;
   Transposed_Product_Self_Times_Transpose : constant C_UInt8 := 1;

   Sample_Orientation_Rows    : constant C_Int32 := 0;
   Sample_Orientation_Columns : constant C_Int32 := 1;

   Covariance_Scaling_Unscaled        : constant C_Int32 := 0;
   Covariance_Scaling_By_Sample_Count : constant C_Int32 := 1;

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

   function Mat_Transpose
     (Source : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_transpose";

   function Mat_Flip
     (Source : Mat_Handle; Kind : C_Int32; Result : access Mat_Handle)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_flip";

   function Mat_Sort
     (Source     : Mat_Handle;
      Axis       : C_UInt8;
      Descending : C_UInt8;
      Result     : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_sort";

   function Mat_Sort_Indices
     (Source     : Mat_Handle;
      Axis       : C_UInt8;
      Descending : C_UInt8;
      Result     : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_sort_indices";

   function Mat_Copy_Make_Border
     (Source   : Mat_Handle;
      Top      : C_Int32;
      Bottom   : C_Int32;
      Left     : C_Int32;
      Right    : C_Int32;
      Kind     : C_Int32;
      Value    : access Scalar;
      Isolated : C_Boolean;
      Result   : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_copy_make_border";

   function Mat_Rotate
     (Source : Mat_Handle; Kind : C_Int32; Result : access Mat_Handle)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_rotate";

   function Mat_Repeat
     (Source             : Mat_Handle;
      Row_Repetitions    : C_Int32;
      Column_Repetitions : C_Int32;
      Result             : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_repeat";

   function Mat_Reduce
     (Source       : Mat_Handle;
      Axis         : C_Int32;
      Kind         : C_Int32;
      Output_Depth : C_Int32;
      Result       : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_reduce";

   function Mat_HConcat
     (Sources : access Mat_Handle; Count : C_Int32; Result : access Mat_Handle)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_hconcat";

   function Mat_VConcat
     (Sources : access Mat_Handle; Count : C_Int32; Result : access Mat_Handle)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_vconcat";

   function Mat_Split
     (Source : Mat_Handle; Results : access Mat_Handle; Count : C_Int32)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_split";

   function Mat_Extract_Channel
     (Source : Mat_Handle; Channel : C_Int32; Result : access Mat_Handle)
      return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_extract_channel";

   function Mat_Insert_Channel
     (Source, Destination : Mat_Handle; Channel : C_Int32) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_insert_channel";

   function Mat_Mix_Channels
     (Sources           : access Mat_Handle;
      Source_Count      : C_Int32;
      Destinations      : access Mat_Handle;
      Destination_Count : C_Int32;
      From_To           : access C_Int32;
      Pair_Count        : C_Int32) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_mix_channels";

   function Mat_Merge
     (Sources : access Mat_Handle; Count : C_Int32; Result : access Mat_Handle)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_merge";

   function Mat_Copy_To (Source, Destination : Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_copy_to";

   function Mat_Copy_To_Masked
     (Source, Destination, Mask : Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_copy_to_masked";

   function Mat_Convert_To
     (Source : Mat_Handle;
      Depth  : C_Int32;
      Scale  : C_Double;
      Offset : C_Double;
      Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_convert_to";

   function Mat_Convert_Scale_Abs
     (Source : Mat_Handle;
      Scale  : C_Double;
      Offset : C_Double;
      Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_convert_scale_abs";

   function Mat_Apply_LUT
     (Source, Table : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_apply_lut";

   function Mat_Sqrt
     (Source : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_sqrt";

   function Mat_Exp
     (Source : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_exp";

   function Mat_Log
     (Source : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_log";

   function Mat_Pow
     (Source : Mat_Handle; Power : C_Double; Result : access Mat_Handle)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_pow";

   function Mat_Magnitude
     (X, Y : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_magnitude";

   function Mat_Phase
     (X, Y             : Mat_Handle;
      Angle_In_Degrees : C_Boolean;
      Result           : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_phase";
   function Mat_Cart_To_Polar
     (X, Y             : Mat_Handle;
      Angle_In_Degrees : C_Boolean;
      Magnitude        : access Mat_Handle;
      Angle            : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_cart_to_polar";

   function Mat_Polar_To_Cart
     (Magnitude, Angle : Mat_Handle;
      Angle_In_Degrees : C_Boolean;
      X                : access Mat_Handle;
      Y                : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_polar_to_cart";

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

   function Mat_Multiply
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_multiply";

   function Mat_Divide
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_divide";

   function Mat_Abs_Diff
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_abs_diff";

   function Mat_Minimum
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_minimum";

   function Mat_Maximum
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_maximum";

   function Mat_Add_Weighted
     (Left   : Mat_Handle;
      Alpha  : C_Double;
      Right  : Mat_Handle;
      Beta   : C_Double;
      Gamma  : C_Double;
      Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_add_weighted";

   function Mat_Scale_Add
     (Left   : Mat_Handle;
      Scale  : C_Double;
      Right  : Mat_Handle;
      Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_scale_add";

   function Mat_Bitwise_And
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_bitwise_and";

   function Mat_Bitwise_Or
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_bitwise_or";

   function Mat_Bitwise_Xor
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_bitwise_xor";

   function Mat_Bitwise_Not
     (Self : Mat_Handle; Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_bitwise_not";

   function Mat_Bitwise_And_Masked
     (Left, Right, Mask : Mat_Handle; Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_bitwise_and_masked";

   function Mat_Bitwise_Or_Masked
     (Left, Right, Mask : Mat_Handle; Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_bitwise_or_masked";

   function Mat_Bitwise_Xor_Masked
     (Left, Right, Mask : Mat_Handle; Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_bitwise_xor_masked";

   function Mat_Bitwise_Not_Masked
     (Self, Mask : Mat_Handle; Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_bitwise_not_masked";

   function Mat_In_Range_Scalar
     (Self   : Mat_Handle;
      Lower  : access constant Scalar;
      Upper  : access constant Scalar;
      Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_in_range_scalar";

   function Mat_Compare
     (Left, Right : Mat_Handle; Kind : C_Int32; Result : access Mat_Handle)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_compare";

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

   function Mat_Diagonal_Matrix
     (Diagonal : Mat_Handle; Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_diagonal_matrix";

   function Mat_Diagonal_View
     (Source : Mat_Handle; Offset : C_Int32; Result : access Mat_Handle)
      return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_diagonal_view";

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

   Float32_Finite            : constant C_Int32 := 0;
   Float32_Positive_Infinity : constant C_Int32 := 1;
   Float32_Negative_Infinity : constant C_Int32 := 2;
   Float32_Not_A_Number      : constant C_Int32 := 3;

   function Mat_Classify_Float32
     (Self : Mat_Handle; Row, Column : C_Int32; Result : access C_Int32)
      return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_classify_float32";

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

   function Mat_Set_To_Masked
     (Self : Mat_Handle; Value : access Scalar; Mask : Mat_Handle)
      return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_set_to_masked";

   function Mat_Sum (Self : Mat_Handle; Result : access Scalar) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_sum";

   function Mat_Trace (Self : Mat_Handle; Result : access Scalar) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_trace";

   function Mat_Determinant
     (Source : Mat_Handle; Result : access C_Double) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_determinant";

   function Mat_Dot_Product
     (Left, Right : Mat_Handle; Result : access C_Double) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_dot_product";

   function Mat_Mahalanobis_Distance
     (Left               : Mat_Handle;
      Right              : Mat_Handle;
      Inverse_Covariance : Mat_Handle;
      Result             : access C_Double) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_mahalanobis_distance";

   function Mat_Cross_Product
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_cross_product";

   function Mat_Invert
     (Source     : Mat_Handle;
      Invertible : access C_Boolean;
      Result     : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_invert";

   function Mat_Solve
     (Coefficients    : Mat_Handle;
      Right_Hand_Side : Mat_Handle;
      Solved          : access C_Boolean;
      Result          : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_solve";

   function Mat_Matrix_Multiply
     (Left, Right : Mat_Handle; Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_matrix_multiply";

   function Mat_Matrix_Multiply_Add
     (Left          : Mat_Handle;
      Right         : Mat_Handle;
      Addend        : Mat_Handle;
      Product_Scale : C_Double;
      Addend_Scale  : C_Double;
      Result        : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_matrix_multiply_add";

   function Mat_Transposed_Product
     (Source       : Mat_Handle;
      Order        : C_UInt8;
      Scale        : C_Double;
      Output_Depth : C_Int32;
      Result       : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_transposed_product";

   function Mat_Transposed_Product_With_Delta
     (Source       : Mat_Handle;
      Offset       : Mat_Handle;
      Order        : C_UInt8;
      Scale        : C_Double;
      Output_Depth : C_Int32;
      Result       : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_transposed_product_with_delta";

   function Mat_Covariance
     (Source      : Mat_Handle;
      Orientation : C_Int32;
      Scaling     : C_Int32;
      Covariance  : access Mat_Handle;
      Mean        : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_covariance";

   function Mat_Eigen_Decomposition
     (Source       : Mat_Handle;
      Eigenvalues  : access Mat_Handle;
      Eigenvectors : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_eigen_decomposition";

   function Mat_Principal_Component_Analysis
     (Source         : Mat_Handle;
      Orientation    : C_Int32;
      Max_Components : C_Int32;
      Mean           : access Mat_Handle;
      Eigenvalues    : access Mat_Handle;
      Eigenvectors   : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_principal_component_analysis";

   function Mat_Principal_Component_Analysis_Retained_Variance
     (Source            : Mat_Handle;
      Orientation       : C_Int32;
      Retained_Variance : C_Double;
      Mean              : access Mat_Handle;
      Eigenvalues       : access Mat_Handle;
      Eigenvectors      : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name =>
       "opencv_core_mat_principal_component_analysis_retained_variance";

   function Mat_PCA_Project
     (Source       : Mat_Handle;
      Mean         : Mat_Handle;
      Eigenvectors : Mat_Handle;
      Orientation  : C_Int32;
      Result       : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_pca_project";

   function Mat_PCA_Back_Project
     (Source       : Mat_Handle;
      Mean         : Mat_Handle;
      Eigenvectors : Mat_Handle;
      Orientation  : C_Int32;
      Result       : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_pca_back_project";

   function Mat_Singular_Value_Decomposition
     (Source          : Mat_Handle;
      Singular_Values : access Mat_Handle;
      U               : access Mat_Handle;
      V_Transpose     : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_singular_value_decomposition";

   function Mat_SVD_Back_Substitute
     (Singular_Values : Mat_Handle;
      U               : Mat_Handle;
      V_Transpose     : Mat_Handle;
      Right_Hand_Side : Mat_Handle;
      Result          : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_svd_back_substitute";

   function Mat_Pseudo_Inverse
     (Source : Mat_Handle; Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_pseudo_inverse";

   function Mat_Reciprocal_Condition_Number
     (Source : Mat_Handle; Result : access C_Double) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_reciprocal_condition_number";

   function Mat_Transform
     (Source       : Mat_Handle;
      Coefficients : Mat_Handle;
      Result       : access Mat_Handle) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_transform";

   function Mat_Perspective_Transform
     (Source           : Mat_Handle;
      Transform_Matrix : Mat_Handle;
      Result           : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_perspective_transform";

   function Mat_Mean (Self : Mat_Handle; Result : access Scalar) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_mean";

   function Mat_Mean_Masked
     (Self, Mask : Mat_Handle; Result : access Scalar) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_mean_masked";

   function Mat_Mean_Std_Dev
     (Self               : Mat_Handle;
      Mean               : access Scalar;
      Standard_Deviation : access Scalar) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_mean_std_dev";

   function Mat_Mean_Std_Dev_Masked
     (Self, Mask         : Mat_Handle;
      Mean               : access Scalar;
      Standard_Deviation : access Scalar) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_mean_std_dev_masked";

   function Mat_Norm
     (Self : Mat_Handle; Kind : C_Int32; Result : access C_Double)
      return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_norm";

   function Mat_Norm_Masked
     (Self, Mask : Mat_Handle; Kind : C_Int32; Result : access C_Double)
      return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_norm_masked";

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

   function Mat_Min_Max_Loc_Masked
     (Self, Mask : Mat_Handle;
      Minimum    : access C_Double;
      Maximum    : access C_Double;
      Minimum_X  : access C_Int32;
      Minimum_Y  : access C_Int32;
      Maximum_X  : access C_Int32;
      Maximum_Y  : access C_Int32) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_min_max_loc_masked";

   function Mat_Count_Non_Zero
     (Self : Mat_Handle; Result : access Interfaces.Integer_64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_count_non_zero";
   function Mat_Has_Non_Zero
     (Self : Mat_Handle; Result : access Interfaces.Unsigned_8) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_has_non_zero";

   function Mat_Find_Non_Zero
     (Self     : Mat_Handle;
      Points   : access Point;
      Capacity : Interfaces.Integer_64;
      Count    : access Interfaces.Integer_64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_find_non_zero";

   function Mat_Check_Range
     (Source     : Mat_Handle;
      Use_Bounds : C_Boolean;
      Minimum    : C_Double;
      Maximum    : C_Double;
      Valid      : access C_Boolean;
      X          : access C_Int32;
      Y          : access C_Int32) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_check_range";

   function Mat_Patch_NaNs (Self : Mat_Handle; Value : C_Double) return Status
   with Import, Convention => C, External_Name => "opencv_core_mat_patch_nans";

   function Mat_Complete_Symmetry
     (Self : Mat_Handle; Source_Triangle : C_UInt8) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_complete_symmetry";

   function Mat_Set_Identity
     (Self : Mat_Handle; Value : access Scalar) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_mat_set_identity";

   Storage_Mode_Read_Only  : constant C_Int32 := 0;
   Storage_Mode_Write_Only : constant C_Int32 := 1;

   function File_Storage_Open
     (Filename : Interfaces.C.char_array;
      Mode     : C_Int32;
      Result   : access File_Storage_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_file_storage_open";

   procedure File_Storage_Destroy (Self : File_Storage_Handle)
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_file_storage_destroy";

   function File_Storage_Write_Mat
     (Self  : File_Storage_Handle;
      Name  : Interfaces.C.char_array;
      Value : Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_file_storage_write_mat";

   function File_Storage_Read_Mat
     (Self   : File_Storage_Handle;
      Name   : Interfaces.C.char_array;
      Result : access Mat_Handle) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_file_storage_read_mat";

   function File_Storage_Write_Int
     (Self  : File_Storage_Handle;
      Name  : Interfaces.C.char_array;
      Value : C_Int32) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_file_storage_write_int";

   function File_Storage_Read_Int
     (Self   : File_Storage_Handle;
      Name   : Interfaces.C.char_array;
      Result : access C_Int32) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_file_storage_read_int";

   function File_Storage_Write_Double
     (Self  : File_Storage_Handle;
      Name  : Interfaces.C.char_array;
      Value : C_Double) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_file_storage_write_double";

   function File_Storage_Read_Double
     (Self   : File_Storage_Handle;
      Name   : Interfaces.C.char_array;
      Result : access C_Double) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_file_storage_read_double";

   function File_Storage_Write_String
     (Self  : File_Storage_Handle;
      Name  : Interfaces.C.char_array;
      Value : Interfaces.C.char_array) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_file_storage_write_string";

   function File_Storage_Read_String
     (Self       : File_Storage_Handle;
      Name       : Interfaces.C.char_array;
      Buffer     : System.Address;
      Capacity   : C_UInt64;
      Out_Length : access C_UInt64) return Status
   with
     Import,
     Convention    => C,
     External_Name => "opencv_core_file_storage_read_string";

end OpenCV.Internal.C_API;
