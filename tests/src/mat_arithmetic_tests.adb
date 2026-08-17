with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with Mat_Test_Support;

package body Mat_Arithmetic_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Float32_Access.Float32_Classification;
   use type OpenCV.Core.UInt8_Vec3.Vector;

   use Mat_Test_Support;

   procedure Mat_Add_And_Subtract_Work_For_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Right           : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Sum, Difference : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left, 0, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, -2.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, 2.5);
      OpenCV.Core.Float32_Access.Set (Right, 0, 1, 3.0);
      Sum := Left.Add (Right);
      Difference := Left.Subtract (Right);
      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Sum, 0, 0)), 4.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Difference, 0, 1)),
                     -5.0),
         "Float32 addition and subtraction must preserve arithmetic results");
      AUnit.Assertions.Assert
        (Sum.Rows = Left.Rows
         and then Sum.Columns = Left.Columns
         and then Sum.Depth = Left.Depth
         and then Sum.Channels = Left.Channels,
         "Mat addition must preserve compatible operand metadata");
   end Mat_Add_And_Subtract_Work_For_Float32;

   procedure Mat_Arithmetic_Saturates_And_Supports_Vec3
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Right           : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Sum, Difference : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Left, 0, 0, (250, 5, 10));
      OpenCV.Core.UInt8_Vec3_Access.Set (Right, 0, 0, (20, 20, 30));
      Sum := Left.Add (Right);
      Difference := Left.Subtract (Right);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Sum, 0, 0) = (255, 25, 40)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Difference, 0, 0)
                  = (230, 0, 0),
         "UInt8 Vec3 arithmetic must process components independently with"
         & " saturation");
   end Mat_Arithmetic_Saturates_And_Supports_Vec3;

   procedure Mat_Arithmetic_Supports_Int16 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Left       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      Right      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      Sum        : OpenCV.Core.Mat;
      Difference : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (1_000.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (-250.0));
      Sum := Left.Add (Right);
      Difference := Left.Subtract (Right);

      AUnit.Assertions.Assert
        (Sum.Sum.Component_0 = 750.0
         and then Difference.Sum.Component_0 = 1_250.0,
         "Mat arithmetic must support preserved-depth Int16 operands");
   end Mat_Arithmetic_Supports_Int16;

   procedure Mat_Arithmetic_Is_Independent_And_Handles_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (1.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (2.0));
      Result := Left.Region ((1, 0, 2, 3)).Add (Right.Region ((1, 0, 2, 3)));
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 9.0);
      OpenCV.Core.Float32_Access.Set (Result, 0, 1, 7.0);
      AUnit.Assertions.Assert
        (Result.Is_Continuous
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     3.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Left, 0, 2)),
                     1.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Right, 0, 2)),
                     2.0),
         "Arithmetic Regions must produce independent continuous results");
   end Mat_Arithmetic_Is_Independent_And_Handles_Regions;

   procedure Mat_Arithmetic_Compatibility_And_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty_Left, Empty_Right, Empty_Result : OpenCV.Core.Mat;
      One_By_One                            : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Two_By_One                            : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      One_By_Two                            : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Depth                                 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Channels                              : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      procedure Bad_Rows is
         X : constant OpenCV.Core.Mat := One_By_One.Add (Two_By_One);
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat := One_By_One.Add (One_By_Two);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat := One_By_One.Add (Depth);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat := One_By_One.Subtract (Channels);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
   begin
      Empty_Result := Empty_Left.Add (Empty_Right);
      AUnit.Assertions.Assert
        (Empty_Result.Is_Empty,
         "Adding two empty Mats must produce an empty Mat");
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Add must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Add must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Add must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access,
         "Subtract must reject mismatched channel counts");
   end Mat_Arithmetic_Compatibility_And_Empty;

   procedure Mat_Multiply_And_Divide_Work_For_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Right             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Product, Quotient : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left, 0, 0, 6.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, -9.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 2, 5.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 1, 3.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 2, 2.0);
      Product := Left.Multiply (Right);
      Quotient := Left.Divide (Right);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Product, 0, 0)), 12.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Product, 0, 1)),
                     -27.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Quotient, 0, 0)),
                     3.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Quotient, 0, 1)),
                     -3.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Quotient, 0, 2)),
                     2.5),
         "Float32 multiplication and division must preserve arithmetic"
         & " results");
      AUnit.Assertions.Assert
        (Product.Rows = Left.Rows
         and then Product.Columns = Left.Columns
         and then Product.Depth = Left.Depth
         and then Product.Channels = Left.Channels,
         "Mat multiplication must preserve compatible operand metadata");
   end Mat_Multiply_And_Divide_Work_For_Float32;

   procedure Mat_Multiply_And_Divide_Handle_UInt8_And_Vec3
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Right             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Product, Quotient : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (Left, 0, 0, (20, 7, 5));
      OpenCV.Core.UInt8_Vec3_Access.Set (Right, 0, 0, (20, 2, 0));
      Product := Left.Multiply (Right);
      Quotient := Left.Divide (Right);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Product, 0, 0) = (255, 14, 0)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Quotient, 0, 0)
                  = (1, 4, 0),
         "UInt8 Vec3 multiplication and division must use OpenCV saturation"
         & " and preserved-depth rounding");
   end Mat_Multiply_And_Divide_Handle_UInt8_And_Vec3;

   procedure Mat_Divide_By_Zero_Preserves_OpenCV_Semantics
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Integer_Numerator   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Integer_Denominator : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Float_Numerator     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Float_Denominator   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Integer_Result      : OpenCV.Core.Mat;
      Float_Result        : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Integer_Numerator, 0, 0, 20);
      Integer_Result := Integer_Numerator.Divide (Integer_Denominator);
      OpenCV.Core.Float32_Access.Set (Float_Numerator, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Float_Numerator, 0, 1, -1.0);
      Float_Denominator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Float_Result := Float_Numerator.Divide (Float_Denominator);
      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Integer_Result, 0, 0) = 0,
         "OpenCV integer division by zero must produce zero");
      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Classify (Float_Result, 0, 0)
         = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Float_Result, 0, 1)
                  = OpenCV.Core.Float32_Access.Negative_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Float_Result, 0, 2)
                  = OpenCV.Core.Float32_Access.Not_A_Number,
         "OpenCV Float32 division by zero must preserve IEEE Inf and NaN");
   end Mat_Divide_By_Zero_Preserves_OpenCV_Semantics;

   procedure Float32_Classification_Identifies_Stored_Values
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Numerator    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Denominator  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Finite_Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Result       : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 2, -1.0);
      OpenCV.Core.Float32_Access.Set (Finite_Image, 0, 0, 2.0);
      Denominator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Result := Numerator.Divide (Denominator);

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Classify (Finite_Image, 0, 0)
         = OpenCV.Core.Float32_Access.Finite
         and then OpenCV.Core.Float32_Access.Classify (Result, 0, 0)
                  = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Result, 0, 1)
                  = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Result, 0, 2)
                  = OpenCV.Core.Float32_Access.Negative_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Result, 0, 3)
                  = OpenCV.Core.Float32_Access.Not_A_Number,
         "Float32 classification must identify finite, infinite, and NaN"
         & " values");
   end Float32_Classification_Identifies_Stored_Values;

   procedure Mat_Multiply_And_Divide_Handle_Regions_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Right    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Product  : OpenCV.Core.Mat;
      Quotient : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (6.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (2.0));
      Product :=
        Left.Region ((1, 0, 2, 3)).Multiply (Right.Region ((1, 0, 2, 3)));
      Quotient :=
        Left.Region ((1, 0, 2, 3)).Divide (Right.Region ((1, 0, 2, 3)));
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 10.0);
      OpenCV.Core.Float32_Access.Set (Product, 0, 1, 9.0);

      AUnit.Assertions.Assert
        (Product.Is_Continuous
         and then Quotient.Is_Continuous
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Product, 0, 0)),
                     12.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Quotient, 1, 1)),
                     3.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Left, 0, 2)),
                     6.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Right, 0, 2)),
                     2.0),
         "Arithmetic Regions must produce independent continuous results");
   end Mat_Multiply_And_Divide_Handle_Regions_And_Independence;

   procedure Mat_Multiply_Divide_Int16_Empty_Compatibility
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Int16_Left                                             :
        OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      Int16_Right                                            :
        OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      Empty_Left, Empty_Right, Empty_Product, Empty_Quotient : OpenCV.Core.Mat;
      Different_Rows                                         :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (2, 1, (OpenCV.Core.Int16, 1));
      Different_Columns                                      :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (1, 2, (OpenCV.Core.Int16, 1));
      Different_Depth                                        :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Different_Channels                                     :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 3));
      Product, Quotient                                      : OpenCV.Core.Mat;
      procedure Multiply_Mismatched_Rows is
         Ignored : constant OpenCV.Core.Mat :=
           Int16_Left.Multiply (Different_Rows);
      begin
         pragma Unreferenced (Ignored);
      end Multiply_Mismatched_Rows;
      procedure Divide_Mismatched_Columns is
         Ignored : constant OpenCV.Core.Mat :=
           Int16_Left.Divide (Different_Columns);
      begin
         pragma Unreferenced (Ignored);
      end Divide_Mismatched_Columns;
      procedure Divide_Mismatched_Depth is
         Ignored : constant OpenCV.Core.Mat :=
           Int16_Left.Divide (Different_Depth);
      begin
         pragma Unreferenced (Ignored);
      end Divide_Mismatched_Depth;
      procedure Multiply_Mismatched_Channels is
         Ignored : constant OpenCV.Core.Mat :=
           Int16_Left.Multiply (Different_Channels);
      begin
         pragma Unreferenced (Ignored);
      end Multiply_Mismatched_Channels;
   begin
      Int16_Left.Set_To (OpenCV.Core.Make_Scalar (-12.0));
      Int16_Right.Set_To (OpenCV.Core.Make_Scalar (3.0));
      Product := Int16_Left.Multiply (Int16_Right);
      Quotient := Int16_Left.Divide (Int16_Right);
      Empty_Product := Empty_Left.Multiply (Empty_Right);
      Empty_Quotient := Empty_Left.Divide (Empty_Right);

      AUnit.Assertions.Assert
        (Product.Sum.Component_0 = -36.0
         and then Quotient.Sum.Component_0 = -4.0
         and then Empty_Product.Is_Empty
         and then Empty_Quotient.Is_Empty,
         "Multiply and Divide must support Int16 and preserve empty Mat"
         & " results");
      Assert_Raises_OpenCV_Error
        (Multiply_Mismatched_Rows'Access,
         "Multiply must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Divide_Mismatched_Columns'Access,
         "Divide must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Divide_Mismatched_Depth'Access,
         "Divide must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Multiply_Mismatched_Channels'Access,
         "Multiply must reject mismatched channel counts");
   end Mat_Multiply_Divide_Int16_Empty_Compatibility;

   procedure Mat_Abs_Diff_Handles_Float32_And_Metadata
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Result      : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left, 0, 0, -3.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 5.5);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, 2.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 1, -1.5);
      Result := Left.Abs_Diff (Right);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Result, 0, 0)), 5.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     7.0)
         and then Result.Rows = Left.Rows
         and then Result.Columns = Left.Columns
         and then Result.Depth = Left.Depth
         and then Result.Channels = Left.Channels,
         "Float32 absolute difference must preserve values and metadata");
   end Mat_Abs_Diff_Handles_Float32_And_Metadata;

   procedure Mat_Abs_Diff_Handles_UInt8_Vec3_And_Int16
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Left, UInt8_Right    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Int16_Left, Int16_Right    : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      UInt8_Result, Int16_Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (UInt8_Left, 0, 0, (10, 250, 50));
      OpenCV.Core.UInt8_Vec3_Access.Set (UInt8_Right, 0, 0, (200, 20, 80));
      UInt8_Result := UInt8_Left.Abs_Diff (UInt8_Right);
      Int16_Left.Set_To (OpenCV.Core.Make_Scalar (-32_768.0));
      Int16_Right.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Int16_Result := Int16_Left.Abs_Diff (Int16_Right);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (UInt8_Result, 0, 0)
         = (190, 230, 30)
         and then Int16_Result.Sum.Component_0 = 32_767.0,
         "Abs_Diff must process Vec3 channels and saturate Int16 minimum");
   end Mat_Abs_Diff_Handles_UInt8_Vec3_And_Int16;

   procedure Mat_Abs_Diff_Handles_Regions_Nonfinite_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right                           : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Result                                : OpenCV.Core.Mat;
      Zeros                                 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Numerator                             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Nonfinite                             : OpenCV.Core.Mat;
      Empty_Left, Empty_Right, Empty_Result : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (8.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (3.0));
      Result :=
        Left.Region ((1, 0, 2, 3)).Abs_Diff (Right.Region ((1, 0, 2, 3)));
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 99.0);
      OpenCV.Core.Float32_Access.Set (Result, 0, 1, 9.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 0, 1.0);
      Zeros.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Nonfinite := Numerator.Divide (Zeros);
      Empty_Result := Empty_Left.Abs_Diff (Empty_Right);

      AUnit.Assertions.Assert
        (Result.Is_Continuous
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     5.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Left, 0, 2)),
                     8.0)
         and then OpenCV.Core.Float32_Access.Classify (Nonfinite, 0, 0)
                  = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Nonfinite, 0, 1)
                  = OpenCV.Core.Float32_Access.Not_A_Number
         and then OpenCV.Core.Float32_Access.Classify
                    (Nonfinite.Abs_Diff (Nonfinite), 0, 0)
                  = OpenCV.Core.Float32_Access.Not_A_Number
         and then Empty_Result.Is_Empty,
         "Abs_Diff must support Regions, independent output, empty, and IEEE"
         & " Float32 semantics");
   end Mat_Abs_Diff_Handles_Regions_Nonfinite_And_Independence;

   procedure Mat_Abs_Diff_Rejects_Incompatible_Operands
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Base     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Rows     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Columns  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Depth    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Channels : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      procedure Bad_Rows is
         X : constant OpenCV.Core.Mat := Base.Abs_Diff (Rows);
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat := Base.Abs_Diff (Columns);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat := Base.Abs_Diff (Depth);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat := Base.Abs_Diff (Channels);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
   begin
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Abs_Diff must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Abs_Diff must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Abs_Diff must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Abs_Diff must reject mismatched channels");
   end Mat_Abs_Diff_Rejects_Incompatible_Operands;

   procedure Mat_Add_Weighted_Handles_Float32_And_Metadata
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Result      : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (10.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (20.0));
      Result :=
        Left.Add_Weighted
          (Alpha => 0.25, Right => Right, Beta => 0.75, Gamma => 2.0);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Result, 0, 0)), 19.5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     19.5)
         and then Result.Rows = Left.Rows
         and then Result.Columns = Left.Columns
         and then Result.Depth = Left.Depth
         and then Result.Channels = Left.Channels,
         "Add_Weighted must apply Alpha, Beta, Gamma, and preserve metadata");
   end Mat_Add_Weighted_Handles_Float32_And_Metadata;

   procedure Mat_Add_Weighted_Handles_UInt8_Vec3_And_Int16
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Left, UInt8_Right               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Int16_Left, Int16_Right               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      UInt8_Result, Saturated, Int16_Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set (UInt8_Left, 0, 0, (1, 10, 200));
      OpenCV.Core.UInt8_Vec3_Access.Set (UInt8_Right, 0, 0, (2, 20, 100));
      UInt8_Result :=
        UInt8_Left.Add_Weighted
          (Alpha => 0.5, Right => UInt8_Right, Beta => 0.5, Gamma => 0.5);
      Saturated :=
        UInt8_Left.Add_Weighted
          (Alpha => 2.0, Right => UInt8_Right, Beta => 2.0, Gamma => 100.0);
      Int16_Left.Set_To (OpenCV.Core.Make_Scalar (-10.0));
      Int16_Right.Set_To (OpenCV.Core.Make_Scalar (20.0));
      Int16_Result :=
        Int16_Left.Add_Weighted
          (Alpha => 0.5, Right => Int16_Right, Beta => 0.5);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (UInt8_Result, 0, 0) = (2, 16, 150)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Saturated, 0, 0)
                  = (106, 160, 255)
         and then Int16_Result.Sum.Component_0 = 5.0,
         "Add_Weighted must use OpenCV rounded saturation per channel");
   end Mat_Add_Weighted_Handles_UInt8_Vec3_And_Int16;

   procedure Mat_Add_Weighted_Handles_Regions_Empty_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right                           : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.Float32, 1));
      Result                                : OpenCV.Core.Mat;
      Empty_Left, Empty_Right, Empty_Result : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (4.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (12.0));
      Result :=
        Left.Region ((1, 0, 2, 3)).Add_Weighted
          (Alpha => 0.25,
           Right => Right.Region ((1, 0, 2, 3)),
           Beta  => 0.75,
           Gamma => 1.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 99.0);
      OpenCV.Core.Float32_Access.Set (Result, 0, 1, 9.0);
      Empty_Result :=
        Empty_Left.Add_Weighted
          (Alpha => 1.0, Right => Empty_Right, Beta => 1.0);

      AUnit.Assertions.Assert
        (Result.Is_Continuous
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     11.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Left, 0, 2)),
                     4.0)
         and then Approximately_Equal
                    (Long_Float (OpenCV.Core.Float32_Access.Get (Right, 0, 2)),
                     12.0)
         and then Empty_Result.Is_Empty,
         "Add_Weighted must support Regions, independent output, and empty"
         & " Mats");
   end Mat_Add_Weighted_Handles_Regions_Empty_And_Independence;

   procedure Mat_Add_Weighted_Rejects_Incompatible_Operands
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Base     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Rows     : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Columns  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Depth    : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Channels : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      procedure Bad_Rows is
         X : constant OpenCV.Core.Mat := Base.Add_Weighted (1.0, Rows, 1.0);
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat := Base.Add_Weighted (1.0, Columns, 1.0);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat := Base.Add_Weighted (1.0, Depth, 1.0);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat :=
           Base.Add_Weighted (1.0, Channels, 1.0);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
   begin
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Add_Weighted must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Add_Weighted must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Add_Weighted must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Add_Weighted must reject mismatched channels");
   end Mat_Add_Weighted_Rejects_Incompatible_Operands;

   procedure Mat_Scale_Add_Maps_UInt8_Exactly (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Result : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Left, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Left, 0, 1, 2);
      OpenCV.Core.UInt8_Access.Set (Left, 1, 0, 3);
      OpenCV.Core.UInt8_Access.Set (Left, 1, 1, 4);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 0, 10);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 1, 20);
      OpenCV.Core.UInt8_Access.Set (Right, 1, 0, 30);
      OpenCV.Core.UInt8_Access.Set (Right, 1, 1, 40);
      Result := Left.Scale_Add (Scale => 2.0, Right => Right);

      AUnit.Assertions.Assert
        (Result.Rows = 2
         and then Result.Columns = 2
         and then Result.Depth = OpenCV.Core.UInt8
         and then Result.Channels = 1
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 12
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 1) = 24
         and then OpenCV.Core.UInt8_Access.Get (Result, 1, 0) = 36
         and then OpenCV.Core.UInt8_Access.Get (Result, 1, 1) = 48,
         "Scale_Add must map UInt8 values as Scale * Left + Right");
   end Mat_Scale_Add_Maps_UInt8_Exactly;

   procedure Mat_Scale_Add_Saturates_UInt8_And_Int16
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Left, UInt8_Right, Saturated, Underflow, Rounded :
        OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Int16_Left, Int16_Right, Int16_High, Int16_Low         :
        OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (UInt8_Left, 0, 0, 200);
      OpenCV.Core.UInt8_Access.Set (UInt8_Right, 0, 0, 100);
      Saturated := UInt8_Left.Scale_Add (Scale => 2.0, Right => UInt8_Right);
      OpenCV.Core.UInt8_Access.Set (UInt8_Left, 0, 0, 10);
      OpenCV.Core.UInt8_Access.Set (UInt8_Right, 0, 0, 1);
      Underflow := UInt8_Left.Scale_Add (Scale => -2.0, Right => UInt8_Right);
      OpenCV.Core.UInt8_Access.Set (UInt8_Left, 0, 0, 10);
      OpenCV.Core.UInt8_Access.Set (UInt8_Right, 0, 0, 3);
      Rounded := UInt8_Left.Scale_Add (Scale => 0.5, Right => UInt8_Right);
      Int16_Left.Set_To (OpenCV.Core.Make_Scalar (20_000.0));
      Int16_Right.Set_To (OpenCV.Core.Make_Scalar (20_000.0));
      Int16_High := Int16_Left.Scale_Add (Scale => 2.0, Right => Int16_Right);
      Int16_Left.Set_To (OpenCV.Core.Make_Scalar (-20_000.0));
      Int16_Right.Set_To (OpenCV.Core.Make_Scalar (-20_000.0));
      Int16_Low := Int16_Left.Scale_Add (Scale => 2.0, Right => Int16_Right);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Saturated, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Underflow, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Rounded, 0, 0) = 8
         and then Int16_High.Sum.Component_0 = 32_767.0
         and then Int16_Low.Sum.Component_0 = -32_768.0,
         "Scale_Add must apply OpenCV integer saturation and rounding");
   end Mat_Scale_Add_Saturates_UInt8_And_Int16;

   procedure Mat_Scale_Add_Handles_Float32_Negative_And_Nonfinite
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right, Result                  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Numerator, Zeroes, Finite, Nonfinite : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Scaled_Nonfinite                     : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left, 0, 0, 1.5);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, -2.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, 2.5);
      OpenCV.Core.Float32_Access.Set (Right, 0, 1, 3.0);
      Result := Left.Scale_Add (Scale => 2.0, Right => Right);
      Numerator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 1, 1.0);
      Zeroes.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Finite.Set_To (OpenCV.Core.Make_Scalar (2.0));
      Nonfinite := Numerator.Divide (Zeroes);
      Scaled_Nonfinite := Nonfinite.Scale_Add (Scale => 2.0, Right => Finite);

      AUnit.Assertions.Assert
        (Result.Rows = Left.Rows
         and then Result.Columns = Left.Columns
         and then Result.Depth = OpenCV.Core.Float32
         and then Result.Channels = Left.Channels
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 0)),
                     5.5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Result, 0, 1)),
                     -1.0)
         and then OpenCV.Core.Float32_Access.Classify (Scaled_Nonfinite, 0, 0)
                  = OpenCV.Core.Float32_Access.Not_A_Number
         and then OpenCV.Core.Float32_Access.Classify (Scaled_Nonfinite, 0, 1)
                  = OpenCV.Core.Float32_Access.Positive_Infinity,
         "Scale_Add must map Float32 values, negatives, NaN, and infinity");
   end Mat_Scale_Add_Handles_Float32_Negative_And_Nonfinite;

   procedure Mat_Scale_Add_Handles_Vec3_Regions_And_Lifetime
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Result : OpenCV.Core.Mat;
   begin
      declare
         Left  : OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 3));
         Right : OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 3));
         View  : constant OpenCV.Core.Mat :=
           Left.Region ((X => 1, Y => 0, Width => 2, Height => 3));
      begin
         OpenCV.Core.UInt8_Vec3_Access.Set (Left, 0, 0, (9, 9, 9));
         OpenCV.Core.UInt8_Vec3_Access.Set (Left, 0, 1, (1, 2, 3));
         OpenCV.Core.UInt8_Vec3_Access.Set (Left, 0, 2, (4, 5, 6));
         OpenCV.Core.UInt8_Vec3_Access.Set (Right, 0, 1, (10, 20, 30));
         OpenCV.Core.UInt8_Vec3_Access.Set (Right, 0, 2, (40, 50, 60));
         AUnit.Assertions.Assert
           (not View.Is_Continuous,
            "Scale_Add test Region must be non-continuous");
         Result :=
           View.Scale_Add (Scale => 2.0, Right => Right.Region ((1, 0, 2, 3)));
         OpenCV.Core.UInt8_Vec3_Access.Set (Left, 0, 1, (99, 99, 99));
         OpenCV.Core.UInt8_Vec3_Access.Set (Result, 1, 0, (7, 8, 9));
      end;

      AUnit.Assertions.Assert
        (not Result.Is_Empty
         and then Result.Is_Continuous
         and then Result.Rows = 3
         and then Result.Columns = 2
         and then Result.Depth = OpenCV.Core.UInt8
         and then Result.Channels = 3
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Result, 0, 0)
                  = (12, 24, 36)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Result, 0, 1)
                  = (48, 60, 72)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Result, 1, 0) = (7, 8, 9),
         "Scale_Add must process Vec3 Regions independently of source"
         & " lifetime");
   end Mat_Scale_Add_Handles_Vec3_Regions_And_Lifetime;

   procedure Mat_Scale_Add_Handles_Empty_And_Compatibility
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Empty_Left, Empty_Right, Empty_Result : OpenCV.Core.Mat;
      Base                                  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Rows                                  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Columns                               : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Depth                                 : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Channels                              : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      procedure Bad_Rows is
         X : constant OpenCV.Core.Mat :=
           Base.Scale_Add (Scale => 1.0, Right => Rows);
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat :=
           Base.Scale_Add (Scale => 1.0, Right => Columns);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat :=
           Base.Scale_Add (Scale => 1.0, Right => Depth);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat :=
           Base.Scale_Add (Scale => 1.0, Right => Channels);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
   begin
      Empty_Result :=
        Empty_Left.Scale_Add (Scale => 2.0, Right => Empty_Right);
      AUnit.Assertions.Assert
        (Empty_Result.Is_Empty,
         "Scale_Add of two empty Mats must produce an empty Mat");
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Scale_Add must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Scale_Add must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Scale_Add must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Scale_Add must reject mismatched channels");
   end Mat_Scale_Add_Handles_Empty_And_Compatibility;

   procedure Mat_Scale_Add_Supports_Int32 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int32, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int32, 1));
      Result : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (1_000.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (250.0));
      Result := Left.Scale_Add (Scale => 2.0, Right => Right);

      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Int32
         and then Result.Sum.Component_0 = 2_250.0,
         "Scale_Add must support in-range Int32 values as Scale * Left +"
         & " Right");
   end Mat_Scale_Add_Supports_Int32;

   procedure Mat_Scale_Add_Supports_Float64 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float64, 1));
      Right  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float64, 1));
      Result : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (1.5));
      Right.Set_To (OpenCV.Core.Make_Scalar (0.25));
      Result := Left.Scale_Add (Scale => 2.5, Right => Right);

      AUnit.Assertions.Assert
        (Result.Depth = OpenCV.Core.Float64
         and then Approximately_Equal (Result.Sum.Component_0, 4.0),
         "Scale_Add must support Float64 values as Scale * Left + Right");
   end Mat_Scale_Add_Supports_Float64;

   procedure Mat_Minimum_And_Maximum_Map_UInt8_And_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      UInt8_Left       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      UInt8_Right      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Float_Left       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Float_Right      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Minimum, Maximum : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (UInt8_Left, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (UInt8_Left, 0, 1, 8);
      OpenCV.Core.UInt8_Access.Set (UInt8_Left, 0, 2, 3);
      OpenCV.Core.UInt8_Access.Set (UInt8_Left, 1, 0, 9);
      OpenCV.Core.UInt8_Access.Set (UInt8_Left, 1, 1, 2);
      OpenCV.Core.UInt8_Access.Set (UInt8_Left, 1, 2, 7);
      OpenCV.Core.UInt8_Access.Set (UInt8_Right, 0, 0, 4);
      OpenCV.Core.UInt8_Access.Set (UInt8_Right, 0, 1, 5);
      OpenCV.Core.UInt8_Access.Set (UInt8_Right, 0, 2, 6);
      OpenCV.Core.UInt8_Access.Set (UInt8_Right, 1, 0, 3);
      OpenCV.Core.UInt8_Access.Set (UInt8_Right, 1, 1, 8);
      OpenCV.Core.UInt8_Access.Set (UInt8_Right, 1, 2, 1);
      Minimum := UInt8_Left.Minimum (UInt8_Right);
      Maximum := UInt8_Left.Maximum (UInt8_Right);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Minimum, 0, 0) = 1
         and then OpenCV.Core.UInt8_Access.Get (Minimum, 0, 1) = 5
         and then OpenCV.Core.UInt8_Access.Get (Minimum, 0, 2) = 3
         and then OpenCV.Core.UInt8_Access.Get (Minimum, 1, 0) = 3
         and then OpenCV.Core.UInt8_Access.Get (Minimum, 1, 1) = 2
         and then OpenCV.Core.UInt8_Access.Get (Minimum, 1, 2) = 1
         and then OpenCV.Core.UInt8_Access.Get (Maximum, 0, 0) = 4
         and then OpenCV.Core.UInt8_Access.Get (Maximum, 0, 1) = 8
         and then OpenCV.Core.UInt8_Access.Get (Maximum, 0, 2) = 6
         and then OpenCV.Core.UInt8_Access.Get (Maximum, 1, 0) = 9
         and then OpenCV.Core.UInt8_Access.Get (Maximum, 1, 1) = 8
         and then OpenCV.Core.UInt8_Access.Get (Maximum, 1, 2) = 7
         and then Minimum.Rows = 2
         and then Minimum.Columns = 3
         and then Minimum.Depth = OpenCV.Core.UInt8
         and then Minimum.Channels = 1,
         "Minimum and Maximum must map every UInt8 element and preserve"
         & " metadata");

      OpenCV.Core.Float32_Access.Set (Float_Left, 0, 0, -3.5);
      OpenCV.Core.Float32_Access.Set (Float_Left, 0, 1, 4.0);
      OpenCV.Core.Float32_Access.Set (Float_Left, 0, 2, -1.0);
      OpenCV.Core.Float32_Access.Set (Float_Right, 0, 0, -2.0);
      OpenCV.Core.Float32_Access.Set (Float_Right, 0, 1, -5.0);
      OpenCV.Core.Float32_Access.Set (Float_Right, 0, 2, 2.0);
      Minimum := Float_Left.Minimum (Float_Right);
      Maximum := Float_Left.Maximum (Float_Right);

      AUnit.Assertions.Assert
        (Approximately_Equal
           (Long_Float (OpenCV.Core.Float32_Access.Get (Minimum, 0, 0)), -3.5)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Minimum, 0, 1)),
                     -5.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Maximum, 0, 0)),
                     -2.0)
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Maximum, 0, 2)),
                     2.0),
         "Minimum and Maximum must compare positive and negative Float32"
         & " values");
   end Mat_Minimum_And_Maximum_Map_UInt8_And_Float32;

   procedure Mat_Minimum_And_Maximum_Handle_Vec3_Regions_And_Lifetime
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Minimum, Maximum : OpenCV.Core.Mat;
   begin
      declare
         Left, Right : OpenCV.Core.Mat :=
           OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 3));
      begin
         Left.Set_To (OpenCV.Core.Make_Scalar (9.0, 8.0, 7.0));
         Right.Set_To (OpenCV.Core.Make_Scalar (4.0, 5.0, 6.0));
         OpenCV.Core.UInt8_Vec3_Access.Set (Left, 0, 1, (1, 9, 3));
         OpenCV.Core.UInt8_Vec3_Access.Set (Right, 0, 1, (4, 2, 6));
         Minimum :=
           Left.Region ((1, 0, 2, 3)).Minimum (Right.Region ((1, 0, 2, 3)));
         Maximum :=
           Left.Region ((1, 0, 2, 3)).Maximum (Right.Region ((1, 0, 2, 3)));
         OpenCV.Core.UInt8_Vec3_Access.Set (Left, 0, 1, (99, 99, 99));
      end;

      AUnit.Assertions.Assert
        (Minimum.Is_Continuous
         and then Maximum.Is_Continuous
         and then Minimum.Rows = 3
         and then Minimum.Columns = 2
         and then Minimum.Depth = OpenCV.Core.UInt8
         and then Minimum.Channels = 3
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Minimum, 0, 0) = (1, 2, 3)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Minimum, 0, 1) = (4, 5, 6)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Maximum, 0, 0) = (4, 9, 6)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Maximum, 0, 1)
                  = (9, 8, 7),
         "Minimum and Maximum must process Vec3 Region channels independently"
         & " with owned result storage surviving source finalization");
   end Mat_Minimum_And_Maximum_Handle_Vec3_Regions_And_Lifetime;

   procedure Mat_Minimum_And_Maximum_Preserve_Float32_Nonfinite_Behavior
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Numerator, Zeroes, Finite   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.Float32, 1));
      Nonfinite, Minimum, Maximum : OpenCV.Core.Mat;
   begin
      Numerator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 1, 1.0);
      Zeroes.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Finite.Set_To (OpenCV.Core.Make_Scalar (2.0));
      Nonfinite := Numerator.Divide (Zeroes);
      Minimum := Nonfinite.Minimum (Finite);
      Maximum := Nonfinite.Maximum (Finite);

      AUnit.Assertions.Assert
        (OpenCV.Core.Float32_Access.Classify (Minimum, 0, 0)
         = OpenCV.Core.Float32_Access.Not_A_Number
         and then OpenCV.Core.Float32_Access.Classify (Maximum, 0, 0)
                  = OpenCV.Core.Float32_Access.Not_A_Number
         and then Approximately_Equal
                    (Long_Float
                       (OpenCV.Core.Float32_Access.Get (Minimum, 0, 1)),
                     2.0)
         and then OpenCV.Core.Float32_Access.Classify (Maximum, 0, 1)
                  = OpenCV.Core.Float32_Access.Positive_Infinity,
         "Minimum and Maximum must preserve OpenCV Float32 NaN and infinity"
         & " behavior");
   end Mat_Minimum_And_Maximum_Preserve_Float32_Nonfinite_Behavior;

   procedure Mat_Minimum_And_Maximum_Handle_Empty_And_Compatibility
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Base                                                  :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Rows                                                  :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Columns                                               :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Depth                                                 :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Channels                                              :
        constant OpenCV.Core.Mat :=
          OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Empty_Left, Empty_Right, Empty_Minimum, Empty_Maximum : OpenCV.Core.Mat;
      procedure Bad_Rows is
         Ignored : constant OpenCV.Core.Mat := Base.Minimum (Rows);
      begin
         pragma Unreferenced (Ignored);
      end Bad_Rows;
      procedure Bad_Columns is
         Ignored : constant OpenCV.Core.Mat := Base.Maximum (Columns);
      begin
         pragma Unreferenced (Ignored);
      end Bad_Columns;
      procedure Bad_Depth is
         Ignored : constant OpenCV.Core.Mat := Base.Minimum (Depth);
      begin
         pragma Unreferenced (Ignored);
      end Bad_Depth;
      procedure Bad_Channels is
         Ignored : constant OpenCV.Core.Mat := Base.Maximum (Channels);
      begin
         pragma Unreferenced (Ignored);
      end Bad_Channels;
   begin
      Empty_Minimum := Empty_Left.Minimum (Empty_Right);
      Empty_Maximum := Empty_Left.Maximum (Empty_Right);
      AUnit.Assertions.Assert
        (Empty_Minimum.Is_Empty and then Empty_Maximum.Is_Empty,
         "Minimum and Maximum of empty Mats must be empty");
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Minimum must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Maximum must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Minimum must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Maximum must reject mismatched channel counts");
   end Mat_Minimum_And_Maximum_Handle_Empty_And_Compatibility;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Min_Max_Nonfinite : constant Caller.Test_Method :=
        Mat_Minimum_And_Maximum_Preserve_Float32_Nonfinite_Behavior'Access;
   begin
      Result.Add_Test
        (Caller.Create
           ("Mat Add and Subtract work for Float32",
            Mat_Add_And_Subtract_Work_For_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat arithmetic saturates and supports Vec3",
            Mat_Arithmetic_Saturates_And_Supports_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat arithmetic supports Int16",
            Mat_Arithmetic_Supports_Int16'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat arithmetic is independent and handles Regions",
            Mat_Arithmetic_Is_Independent_And_Handles_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat arithmetic rejects incompatible operands and handles empty",
            Mat_Arithmetic_Compatibility_And_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Multiply and Divide work for Float32",
            Mat_Multiply_And_Divide_Work_For_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Multiply and Divide handle UInt8 and Vec3",
            Mat_Multiply_And_Divide_Handle_UInt8_And_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Divide by zero preserves OpenCV semantics",
            Mat_Divide_By_Zero_Preserves_OpenCV_Semantics'Access));
      Result.Add_Test
        (Caller.Create
           ("Float32 classification identifies stored values",
            Float32_Classification_Identifies_Stored_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Multiply and Divide handle Regions and independence",
            Mat_Multiply_And_Divide_Handle_Regions_And_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Multiply and Divide handle Int16, empty, and compatibility",
            Mat_Multiply_Divide_Int16_Empty_Compatibility'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Abs_Diff handles Float32 and metadata",
            Mat_Abs_Diff_Handles_Float32_And_Metadata'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Abs_Diff handles UInt8, Vec3, and Int16",
            Mat_Abs_Diff_Handles_UInt8_Vec3_And_Int16'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Abs_Diff handles Regions, nonfinite, and independence",
            Mat_Abs_Diff_Handles_Regions_Nonfinite_And_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Abs_Diff rejects incompatible operands",
            Mat_Abs_Diff_Rejects_Incompatible_Operands'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Add_Weighted handles Float32 and metadata",
            Mat_Add_Weighted_Handles_Float32_And_Metadata'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Add_Weighted handles UInt8, Vec3, and Int16",
            Mat_Add_Weighted_Handles_UInt8_Vec3_And_Int16'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Add_Weighted handles Regions, empty, and independence",
            Mat_Add_Weighted_Handles_Regions_Empty_And_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Add_Weighted rejects incompatible operands",
            Mat_Add_Weighted_Rejects_Incompatible_Operands'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Scale_Add maps UInt8 exactly",
            Mat_Scale_Add_Maps_UInt8_Exactly'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Scale_Add saturates UInt8 and Int16",
            Mat_Scale_Add_Saturates_UInt8_And_Int16'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Scale_Add handles Float32, negatives, and nonfinite",
            Mat_Scale_Add_Handles_Float32_Negative_And_Nonfinite'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Scale_Add handles Vec3 Regions and lifetime",
            Mat_Scale_Add_Handles_Vec3_Regions_And_Lifetime'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Scale_Add handles empty and compatibility",
            Mat_Scale_Add_Handles_Empty_And_Compatibility'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Scale_Add supports Int32",
            Mat_Scale_Add_Supports_Int32'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Scale_Add supports Float64",
            Mat_Scale_Add_Supports_Float64'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Minimum and Maximum map UInt8 and Float32",
            Mat_Minimum_And_Maximum_Map_UInt8_And_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Minimum and Maximum handle Vec3 Regions and lifetime",
            Mat_Minimum_And_Maximum_Handle_Vec3_Regions_And_Lifetime'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Minimum and Maximum preserve Float32 nonfinite behavior",
            Min_Max_Nonfinite));
      Result.Add_Test
        (Caller.Create
           ("Mat Minimum and Maximum handle empty and compatibility",
            Mat_Minimum_And_Maximum_Handle_Empty_And_Compatibility'Access));
      return Result'Access;
   end Suite;

end Mat_Arithmetic_Tests;
