with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float16_Access;
with OpenCV.Core.Float16_Buffer_Access;
with OpenCV.Core.Float16_Vec3;
with OpenCV.Core.Float16_Vec3_Access;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with Mat_Test_Support;

package body Mat_Arithmetic_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;

   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Float32_Access.Float32_Classification;
   use type OpenCV.Core.UInt8_Vec3.Vector;

   use Mat_Test_Support;
   function F16
     (Bits : Interfaces.Unsigned_16) return OpenCV.Core.Float16_Value
   is (OpenCV.Core.Float16_From_Bits (Bits));

   function Bits_Of
     (Value : OpenCV.Core.Float16_Value) return Interfaces.Unsigned_16
   is (OpenCV.Core.Float16_Bits (Value));

   function Expected_Add
     (Left, Right : OpenCV.Core.Float16_Value) return OpenCV.Core.Float16_Value
   is (OpenCV.Core.To_Float16
         (OpenCV.Core.To_Float32 (Left) + OpenCV.Core.To_Float32 (Right)));

   function Expected_Subtract
     (Left, Right : OpenCV.Core.Float16_Value) return OpenCV.Core.Float16_Value
   is (OpenCV.Core.To_Float16
         (OpenCV.Core.To_Float32 (Left) - OpenCV.Core.To_Float32 (Right)));

   function Float16_C1 (Rows, Columns : Natural) return OpenCV.Core.Mat
   is (OpenCV.Core.Create (Rows, Columns, (OpenCV.Core.Float16, 1)));

   function Float16_C3 (Rows, Columns : Natural) return OpenCV.Core.Mat
   is (OpenCV.Core.Create (Rows, Columns, (OpenCV.Core.Float16, 3)));

   function Pixel
     (C0, C1, C2 : Interfaces.Unsigned_16)
      return OpenCV.Core.Float16_Vec3.Vector
   is ((0 => F16 (C0), 1 => F16 (C1), 2 => F16 (C2)));

   procedure Assert_Bits
     (Value    : OpenCV.Core.Float16_Value;
      Expected : Interfaces.Unsigned_16;
      Message  : String)
   is
      Stored : constant Interfaces.Unsigned_16 := Bits_Of (Value);
   begin
      AUnit.Assertions.Assert
        (Stored = Expected,
         Message
         & " (got"
         & Interfaces.Unsigned_16'Image (Stored)
         & ", expected"
         & Interfaces.Unsigned_16'Image (Expected)
         & ")");
   end Assert_Bits;

   procedure Assert_Stored_Bits
     (Image    : OpenCV.Core.Mat;
      Row      : Integer;
      Column   : Integer;
      Expected : Interfaces.Unsigned_16;
      Message  : String) is
   begin
      Assert_Bits
        (OpenCV.Core.Float16_Access.Get (Image, Row, Column),
         Expected,
         Message);
   end Assert_Stored_Bits;

   procedure Assert_Stored_Pixel
     (Image    : OpenCV.Core.Mat;
      Row      : Integer;
      Column   : Integer;
      Expected : OpenCV.Core.Float16_Vec3.Vector;
      Message  : String)
   is
      Stored : constant OpenCV.Core.Float16_Vec3.Vector :=
        OpenCV.Core.Float16_Vec3_Access.Get (Image, Row, Column);
   begin
      for Component in OpenCV.Core.Float16_Vec3.Component_Index loop
         Assert_Bits
           (Stored (Component),
            Bits_Of (Expected (Component)),
            Message & " component" & Integer'Image (Component));
      end loop;
   end Assert_Stored_Pixel;

   procedure Assert_Float16_Metadata
     (Image         : OpenCV.Core.Mat;
      Rows, Columns : Natural;
      Channels      : OpenCV.Core.Channel_Count;
      Message       : String) is
   begin
      AUnit.Assertions.Assert
        (Image.Rows = Rows
         and then Image.Columns = Columns
         and then Image.Depth = OpenCV.Core.Float16
         and then Image.Channels = Channels,
         Message);
   end Assert_Float16_Metadata;

   procedure Set_C1
     (Image       : in out OpenCV.Core.Mat;
      Row, Column : Integer;
      Bits        : Interfaces.Unsigned_16) is
   begin
      OpenCV.Core.Float16_Access.Set (Image, Row, Column, F16 (Bits));
   end Set_C1;

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
      Integer_Denominator : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Float_Numerator     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Float_Denominator   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Integer_Result      : OpenCV.Core.Mat;
      Float_Result        : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Integer_Numerator, 0, 0, 20);
      Integer_Denominator.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Integer_Result := Integer_Numerator.Divide (Integer_Denominator);
      OpenCV.Core.Float32_Access.Set (Float_Numerator, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Float_Numerator, 0, 1, -1.0);
      OpenCV.Core.Float32_Access.Set (Float_Numerator, 0, 2, 0.0);
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
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 3, 0.0);
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
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 1, 0.0);
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

   procedure Mat_Mixed_Empty_Representations_Remain_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Default_Empty       : OpenCV.Core.Mat;
      Typed_Empty         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (0, 0, (OpenCV.Core.UInt8, 1));
      Default_Times_Typed : constant OpenCV.Core.Mat :=
        Default_Empty.Multiply (Typed_Empty);
      Typed_Times_Default : constant OpenCV.Core.Mat :=
        Typed_Empty.Multiply (Default_Empty);
      Default_Over_Typed  : constant OpenCV.Core.Mat :=
        Default_Empty.Divide (Typed_Empty);
      Typed_Over_Default  : constant OpenCV.Core.Mat :=
        Typed_Empty.Divide (Default_Empty);
      Default_Min_Typed   : constant OpenCV.Core.Mat :=
        Default_Empty.Minimum (Typed_Empty);
      Typed_Min_Default   : constant OpenCV.Core.Mat :=
        Typed_Empty.Minimum (Default_Empty);
      Default_Max_Typed   : constant OpenCV.Core.Mat :=
        Default_Empty.Maximum (Typed_Empty);
      Typed_Max_Default   : constant OpenCV.Core.Mat :=
        Typed_Empty.Maximum (Default_Empty);

      function Is_Compatible_Empty (Image : OpenCV.Core.Mat) return Boolean
      is (Image.Is_Empty
          and then Image.Rows = 0
          and then Image.Columns = 0
          and then Image.Depth = OpenCV.Core.UInt8
          and then Image.Channels = 1);
   begin
      AUnit.Assertions.Assert
        (Is_Compatible_Empty (Default_Times_Typed)
         and then Is_Compatible_Empty (Typed_Times_Default),
         "Multiply must accept mixed default-empty and typed 0x0 UInt8 C1"
         & " operands as an empty result");
      AUnit.Assertions.Assert
        (Is_Compatible_Empty (Default_Over_Typed)
         and then Is_Compatible_Empty (Typed_Over_Default),
         "Divide must accept mixed default-empty and typed 0x0 UInt8 C1"
         & " operands as an empty result");
      AUnit.Assertions.Assert
        (Is_Compatible_Empty (Default_Min_Typed)
         and then Is_Compatible_Empty (Typed_Min_Default)
         and then Is_Compatible_Empty (Default_Max_Typed)
         and then Is_Compatible_Empty (Typed_Max_Default),
         "Minimum and Maximum must accept mixed default-empty and typed 0x0"
         & " UInt8 C1 operands as an empty result");
   end Mat_Mixed_Empty_Representations_Remain_Empty;

   procedure Mat_Add_Works_For_Float16_C1 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat := Float16_C1 (1, 3);
      Right  : OpenCV.Core.Mat := Float16_C1 (1, 3);
      Result : OpenCV.Core.Mat;
   begin
      --  1.0 + 2.0 = 3.0, 1.5 + 2.25 = 3.75, -2.0 + 0.5 = -1.5
      Set_C1 (Left, 0, 0, 16#3C00#);
      Set_C1 (Left, 0, 1, 16#3E00#);
      Set_C1 (Left, 0, 2, 16#C000#);
      Set_C1 (Right, 0, 0, 16#4000#);
      Set_C1 (Right, 0, 1, 16#4080#);
      Set_C1 (Right, 0, 2, 16#3800#);
      Result := Left.Add (Right);
      Assert_Float16_Metadata
        (Result, 1, 3, 1, "Float16 C1 Add must preserve shape and type");
      Assert_Stored_Bits (Result, 0, 0, 16#4200#, "1.0 + 2.0 must be 3.0");
      Assert_Stored_Bits (Result, 0, 1, 16#4380#, "1.5 + 2.25 must be 3.75");
      Assert_Stored_Bits (Result, 0, 2, 16#BE00#, "-2.0 + 0.5 must be -1.5");
      Assert_Stored_Bits (Left, 0, 0, 16#3C00#, "Add must not mutate Left");
      Assert_Stored_Bits (Right, 0, 0, 16#4000#, "Add must not mutate Right");
      Set_C1 (Result, 0, 0, 16#7C00#);
      Assert_Stored_Bits
        (Left, 0, 0, 16#3C00#, "mutating the result must not affect Left");
   end Mat_Add_Works_For_Float16_C1;

   procedure Mat_Subtract_Works_For_Float16_C1 (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat := Float16_C1 (1, 3);
      Right  : OpenCV.Core.Mat := Float16_C1 (1, 3);
      Result : OpenCV.Core.Mat;
   begin
      --  3.0 - 1.0, 1.0 - 2.0, -1.5 - (-0.5)
      Set_C1 (Left, 0, 0, 16#4200#);
      Set_C1 (Left, 0, 1, 16#3C00#);
      Set_C1 (Left, 0, 2, 16#BE00#);
      Set_C1 (Right, 0, 0, 16#3C00#);
      Set_C1 (Right, 0, 1, 16#4000#);
      Set_C1 (Right, 0, 2, 16#B800#);
      Result := Left.Subtract (Right);
      Assert_Float16_Metadata
        (Result, 1, 3, 1, "Float16 C1 Subtract must preserve shape and type");
      Assert_Stored_Bits (Result, 0, 0, 16#4000#, "3.0 - 1.0 must be 2.0");
      Assert_Stored_Bits (Result, 0, 1, 16#BC00#, "1.0 - 2.0 must be -1.0");
      Assert_Stored_Bits
        (Result, 0, 2, 16#BC00#, "-1.5 - (-0.5) must be -1.0");
   end Mat_Subtract_Works_For_Float16_C1;

   procedure Mat_Float16_Add_Subtract_Round_To_Nearest_Even
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left  : OpenCV.Core.Mat := Float16_C1 (1, 4);
      Right : OpenCV.Core.Mat := Float16_C1 (1, 4);
      Sum   : OpenCV.Core.Mat;
      Diff  : OpenCV.Core.Mat;
   begin
      --  exact 1+2; 1 + 2^-12 rounds down; 1 + 3*2^-12 rounds up;
      --  1 + 2^-11 is the ties-to-even midpoint.
      Set_C1 (Left, 0, 0, 16#3C00#);
      Set_C1 (Right, 0, 0, 16#4000#);
      Set_C1 (Left, 0, 1, 16#3C00#);
      Set_C1 (Right, 0, 1, 16#1000#);
      Set_C1 (Left, 0, 2, 16#3C00#);
      Set_C1 (Right, 0, 2, 16#1800#);
      Set_C1 (Left, 0, 3, 16#3C00#);
      Set_C1 (Right, 0, 3, 16#1400#);
      Sum := Left.Add (Right);
      Diff := Left.Subtract (Right);
      for Column in 0 .. 3 loop
         declare
            L : constant OpenCV.Core.Float16_Value :=
              OpenCV.Core.Float16_Access.Get (Left, 0, Column);
            R : constant OpenCV.Core.Float16_Value :=
              OpenCV.Core.Float16_Access.Get (Right, 0, Column);
         begin
            Assert_Bits
              (OpenCV.Core.Float16_Access.Get (Sum, 0, Column),
               Bits_Of (Expected_Add (L, R)),
               "Float16 Add rounding must match the Float32 oracle");
            Assert_Bits
              (OpenCV.Core.Float16_Access.Get (Diff, 0, Column),
               Bits_Of (Expected_Subtract (L, R)),
               "Float16 Subtract rounding must match the Float32 oracle");
         end;
      end loop;
   end Mat_Float16_Add_Subtract_Round_To_Nearest_Even;

   procedure Mat_Float16_Add_Subtract_Handle_Subnormals
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left  : OpenCV.Core.Mat := Float16_C1 (1, 3);
      Right : OpenCV.Core.Mat := Float16_C1 (1, 3);
      Sum   : OpenCV.Core.Mat;
      Diff  : OpenCV.Core.Mat;
   begin
      Set_C1 (Left, 0, 0, 16#0001#);
      Set_C1 (Right, 0, 0, 16#0001#);
      Set_C1 (Left, 0, 1, 16#0400#);
      Set_C1 (Right, 0, 1, 16#03FF#);
      Set_C1 (Left, 0, 2, 16#0003#);
      Set_C1 (Right, 0, 2, 16#0003#);
      Sum := Left.Add (Right);
      Diff := Left.Subtract (Right);
      Assert_Bits
        (OpenCV.Core.Float16_Access.Get (Sum, 0, 0),
         Bits_Of
           (Expected_Add
              (OpenCV.Core.Float16_Access.Get (Left, 0, 0),
               OpenCV.Core.Float16_Access.Get (Right, 0, 0))),
         "min subnormal + min subnormal");
      Assert_Bits
        (OpenCV.Core.Float16_Access.Get (Diff, 0, 1),
         Bits_Of
           (Expected_Subtract
              (OpenCV.Core.Float16_Access.Get (Left, 0, 1),
               OpenCV.Core.Float16_Access.Get (Right, 0, 1))),
         "min normal - max subnormal");
      Assert_Bits
        (OpenCV.Core.Float16_Access.Get (Diff, 0, 2),
         Bits_Of
           (Expected_Subtract
              (OpenCV.Core.Float16_Access.Get (Left, 0, 2),
               OpenCV.Core.Float16_Access.Get (Right, 0, 2))),
         "small positive - itself");
   end Mat_Float16_Add_Subtract_Handle_Subnormals;

   procedure Mat_Float16_Add_Overflows_To_Signed_Infinity
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left  : OpenCV.Core.Mat := Float16_C1 (1, 2);
      Right : OpenCV.Core.Mat := Float16_C1 (1, 2);
      Sum   : OpenCV.Core.Mat;
   begin
      Set_C1 (Left, 0, 0, 16#7BFF#);
      Set_C1 (Right, 0, 0, 16#7BFF#);
      Set_C1 (Left, 0, 1, 16#FBFF#);
      Set_C1 (Right, 0, 1, 16#FBFF#);
      Sum := Left.Add (Right);
      Assert_Stored_Bits
        (Sum, 0, 0, 16#7C00#, "max finite + max finite must be +Inf");
      Assert_Stored_Bits
        (Sum,
         0,
         1,
         16#FC00#,
         "negative max finite + negative max finite must be -Inf");
      AUnit.Assertions.Assert
        (OpenCV.Core.Is_Infinite (OpenCV.Core.Float16_Access.Get (Sum, 0, 0))
         and then not OpenCV.Core.Is_Negative
                        (OpenCV.Core.Float16_Access.Get (Sum, 0, 0)),
         "+overflow must classify as nonnegative infinity");
      AUnit.Assertions.Assert
        (OpenCV.Core.Is_Infinite (OpenCV.Core.Float16_Access.Get (Sum, 0, 1))
         and then OpenCV.Core.Is_Negative
                    (OpenCV.Core.Float16_Access.Get (Sum, 0, 1)),
         "-overflow must classify as negative infinity");
   end Mat_Float16_Add_Overflows_To_Signed_Infinity;

   procedure Mat_Float16_Add_Subtract_Signed_Zero
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left  : OpenCV.Core.Mat := Float16_C1 (1, 5);
      Right : OpenCV.Core.Mat := Float16_C1 (1, 5);
      Sum   : OpenCV.Core.Mat;
      Diff  : OpenCV.Core.Mat;
   begin
      --  +0 + -0, -0 + -0, +0 - +0, -0 - +0, x - x
      Set_C1 (Left, 0, 0, 16#0000#);
      Set_C1 (Right, 0, 0, 16#8000#);
      Set_C1 (Left, 0, 1, 16#8000#);
      Set_C1 (Right, 0, 1, 16#8000#);
      Set_C1 (Left, 0, 2, 16#0000#);
      Set_C1 (Right, 0, 2, 16#0000#);
      Set_C1 (Left, 0, 3, 16#8000#);
      Set_C1 (Right, 0, 3, 16#0000#);
      Set_C1 (Left, 0, 4, 16#3C00#);
      Set_C1 (Right, 0, 4, 16#3C00#);
      Sum := Left.Add (Right);
      Diff := Left.Subtract (Right);
      for Column in 0 .. 4 loop
         declare
            L : constant OpenCV.Core.Float16_Value :=
              OpenCV.Core.Float16_Access.Get (Left, 0, Column);
            R : constant OpenCV.Core.Float16_Value :=
              OpenCV.Core.Float16_Access.Get (Right, 0, Column);
         begin
            Assert_Bits
              (OpenCV.Core.Float16_Access.Get (Sum, 0, Column),
               Bits_Of (Expected_Add (L, R)),
               "signed-zero Add must match the Float32 oracle");
            Assert_Bits
              (OpenCV.Core.Float16_Access.Get (Diff, 0, Column),
               Bits_Of (Expected_Subtract (L, R)),
               "signed-zero Subtract must match the Float32 oracle");
         end;
      end loop;
   end Mat_Float16_Add_Subtract_Signed_Zero;

   procedure Mat_Float16_Add_Subtract_Infinity_And_NaN
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left      : OpenCV.Core.Mat := Float16_C1 (1, 6);
      Right     : OpenCV.Core.Mat := Float16_C1 (1, 6);
      Sum       : OpenCV.Core.Mat;
      Diff      : OpenCV.Core.Mat;
      Plus_Inf  : constant OpenCV.Core.Float16_Value := F16 (16#7C00#);
      Minus_Inf : constant OpenCV.Core.Float16_Value := F16 (16#FC00#);
      One       : constant OpenCV.Core.Float16_Value := F16 (16#3C00#);
      Quiet_NaN : constant OpenCV.Core.Float16_Value := F16 (16#7E00#);
   begin
      OpenCV.Core.Float16_Access.Set (Left, 0, 0, Plus_Inf);
      OpenCV.Core.Float16_Access.Set (Right, 0, 0, One);
      OpenCV.Core.Float16_Access.Set (Left, 0, 1, Minus_Inf);
      OpenCV.Core.Float16_Access.Set (Right, 0, 1, One);
      OpenCV.Core.Float16_Access.Set (Left, 0, 2, Plus_Inf);
      OpenCV.Core.Float16_Access.Set (Right, 0, 2, Plus_Inf);
      OpenCV.Core.Float16_Access.Set (Left, 0, 3, Minus_Inf);
      OpenCV.Core.Float16_Access.Set (Right, 0, 3, Minus_Inf);
      OpenCV.Core.Float16_Access.Set (Left, 0, 4, Quiet_NaN);
      OpenCV.Core.Float16_Access.Set (Right, 0, 4, One);
      OpenCV.Core.Float16_Access.Set (Left, 0, 5, One);
      OpenCV.Core.Float16_Access.Set (Right, 0, 5, Quiet_NaN);
      Sum := Left.Add (Right);
      Diff := Left.Subtract (Right);
      AUnit.Assertions.Assert
        (OpenCV.Core.Is_Infinite (OpenCV.Core.Float16_Access.Get (Sum, 0, 0))
         and then not OpenCV.Core.Is_Negative
                        (OpenCV.Core.Float16_Access.Get (Sum, 0, 0)),
         "+Inf + finite must be +Inf");
      AUnit.Assertions.Assert
        (OpenCV.Core.Is_Infinite (OpenCV.Core.Float16_Access.Get (Sum, 0, 1))
         and then OpenCV.Core.Is_Negative
                    (OpenCV.Core.Float16_Access.Get (Sum, 0, 1)),
         "-Inf + finite must be -Inf");
      AUnit.Assertions.Assert
        (OpenCV.Core.Is_NaN (OpenCV.Core.Float16_Access.Get (Diff, 0, 2)),
         "+Inf - +Inf must be NaN");
      AUnit.Assertions.Assert
        (OpenCV.Core.Is_NaN (OpenCV.Core.Float16_Access.Get (Diff, 0, 3)),
         "-Inf - -Inf must be NaN");
      AUnit.Assertions.Assert
        (OpenCV.Core.Is_NaN (OpenCV.Core.Float16_Access.Get (Sum, 0, 4)),
         "NaN + finite must be NaN");
      AUnit.Assertions.Assert
        (OpenCV.Core.Is_NaN (OpenCV.Core.Float16_Access.Get (Diff, 0, 5)),
         "finite - NaN must be NaN");
   end Mat_Float16_Add_Subtract_Infinity_And_NaN;

   procedure Mat_Add_Works_For_Float16_C3 (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat := Float16_C3 (1, 1);
      Right  : OpenCV.Core.Mat := Float16_C3 (1, 1);
      Result : OpenCV.Core.Mat;
   begin
      --  (1.0, -2.0, 0.5) + (2.0, 0.5, 4.0) = (3.0, -1.5, 4.5)
      OpenCV.Core.Float16_Vec3_Access.Set
        (Left, 0, 0, Pixel (16#3C00#, 16#C000#, 16#3800#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Right, 0, 0, Pixel (16#4000#, 16#3800#, 16#4400#));
      Result := Left.Add (Right);
      Assert_Float16_Metadata
        (Result, 1, 1, 3, "Float16 C3 Add must preserve C3 metadata");
      Assert_Stored_Pixel
        (Result,
         0,
         0,
         Pixel (16#4200#, 16#BE00#, 16#4480#),
         "Float16 C3 Add must keep component order");
   end Mat_Add_Works_For_Float16_C3;

   procedure Mat_Subtract_Works_For_Float16_C3 (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat := Float16_C3 (1, 1);
      Right  : OpenCV.Core.Mat := Float16_C3 (1, 1);
      Result : OpenCV.Core.Mat;
   begin
      --  (4.0, -1.0, 2.5) - (1.0, 0.5, -0.5) = (3.0, -1.5, 3.0)
      OpenCV.Core.Float16_Vec3_Access.Set
        (Left, 0, 0, Pixel (16#4400#, 16#BC00#, 16#4100#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Right, 0, 0, Pixel (16#3C00#, 16#3800#, 16#B800#));
      Result := Left.Subtract (Right);
      Assert_Stored_Pixel
        (Result,
         0,
         0,
         Pixel (16#4200#, 16#BE00#, 16#4200#),
         "Float16 C3 Subtract must compute each channel independently");
   end Mat_Subtract_Works_For_Float16_C3;

   procedure Mat_Float16_C3_Mixed_Numeric_Categories
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left     : OpenCV.Core.Mat := Float16_C3 (1, 1);
      Right    : OpenCV.Core.Mat := Float16_C3 (1, 1);
      Result   : OpenCV.Core.Mat;
      Expected : OpenCV.Core.Float16_Vec3.Vector;
   begin
      --  channel 0 subnormal, channel 1 finite rounding, channel 2 overflow
      OpenCV.Core.Float16_Vec3_Access.Set
        (Left, 0, 0, Pixel (16#0001#, 16#3C00#, 16#7BFF#));
      OpenCV.Core.Float16_Vec3_Access.Set
        (Right, 0, 0, Pixel (16#0001#, 16#1400#, 16#7BFF#));
      Result := Left.Add (Right);
      Expected :=
        (0 => Expected_Add (F16 (16#0001#), F16 (16#0001#)),
         1 => Expected_Add (F16 (16#3C00#), F16 (16#1400#)),
         2 => Expected_Add (F16 (16#7BFF#), F16 (16#7BFF#)));
      Assert_Stored_Pixel
        (Result,
         0,
         0,
         Expected,
         "C3 mixed categories must match the oracle independently");
   end Mat_Float16_C3_Mixed_Numeric_Categories;

   procedure Mat_Float16_C3_Add_Subtract_Multi_Row
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left  : OpenCV.Core.Mat := Float16_C3 (2, 3);
      Right : OpenCV.Core.Mat := Float16_C3 (2, 3);
      Sum   : OpenCV.Core.Mat;
      Diff  : OpenCV.Core.Mat;
   begin
      for Row in 0 .. 1 loop
         for Column in 0 .. 2 loop
            declare
               Base : constant Interfaces.Unsigned_16 :=
                 Interfaces.Unsigned_16 (16#3C00# + Row * 16#40# + Column);
            begin
               OpenCV.Core.Float16_Vec3_Access.Set
                 (Left, Row, Column, Pixel (Base, 16#C000#, 16#3800#));
               OpenCV.Core.Float16_Vec3_Access.Set
                 (Right, Row, Column, Pixel (16#3C00#, 16#3800#, Base));
            end;
         end loop;
      end loop;
      Sum := Left.Add (Right);
      Diff := Left.Subtract (Right);
      Assert_Float16_Metadata
        (Sum, 2, 3, 3, "multi-row Float16 C3 Add must keep image shape");
      for Row in 0 .. 1 loop
         for Column in 0 .. 2 loop
            declare
               L             : constant OpenCV.Core.Float16_Vec3.Vector :=
                 OpenCV.Core.Float16_Vec3_Access.Get (Left, Row, Column);
               R             : constant OpenCV.Core.Float16_Vec3.Vector :=
                 OpenCV.Core.Float16_Vec3_Access.Get (Right, Row, Column);
               Expected_Sum  : constant OpenCV.Core.Float16_Vec3.Vector :=
                 (0 => Expected_Add (L (0), R (0)),
                  1 => Expected_Add (L (1), R (1)),
                  2 => Expected_Add (L (2), R (2)));
               Expected_Diff : constant OpenCV.Core.Float16_Vec3.Vector :=
                 (0 => Expected_Subtract (L (0), R (0)),
                  1 => Expected_Subtract (L (1), R (1)),
                  2 => Expected_Subtract (L (2), R (2)));
            begin
               Assert_Stored_Pixel (Sum, Row, Column, Expected_Sum, "C3 Add");
               Assert_Stored_Pixel
                 (Diff, Row, Column, Expected_Diff, "C3 Subtract");
            end;
         end loop;
      end loop;
   end Mat_Float16_C3_Add_Subtract_Multi_Row;

   procedure Mat_Float16_Add_Subtract_Handle_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left_Parent  : OpenCV.Core.Mat := Float16_C1 (4, 6);
      Right_Parent : OpenCV.Core.Mat := Float16_C1 (4, 6);
      Left_Region  : OpenCV.Core.Mat;
      Right_Region : OpenCV.Core.Mat;
      Result       : OpenCV.Core.Mat;
      C3_Parent_L  : OpenCV.Core.Mat := Float16_C3 (4, 6);
      C3_Parent_R  : OpenCV.Core.Mat := Float16_C3 (4, 6);
      C3_Region_L  : OpenCV.Core.Mat;
      C3_Region_R  : OpenCV.Core.Mat;
      C3_Result    : OpenCV.Core.Mat;
   begin
      for Row in 0 .. 3 loop
         for Column in 0 .. 5 loop
            Set_C1 (Left_Parent, Row, Column, 16#3C00#);
            Set_C1 (Right_Parent, Row, Column, 16#4000#);
            OpenCV.Core.Float16_Vec3_Access.Set
              (C3_Parent_L, Row, Column, Pixel (16#3C00#, 16#C000#, 16#3800#));
            OpenCV.Core.Float16_Vec3_Access.Set
              (C3_Parent_R, Row, Column, Pixel (16#4000#, 16#3800#, 16#4400#));
         end loop;
      end loop;
      Left_Region :=
        Left_Parent.Region ((X => 2, Y => 1, Width => 3, Height => 2));
      Right_Region :=
        Right_Parent.Region ((X => 2, Y => 1, Width => 3, Height => 2));
      AUnit.Assertions.Assert
        (not Left_Region.Is_Continuous,
         "C1 Region fixture must be non-contiguous");
      Result := Left_Region.Add (Right_Region);
      Assert_Float16_Metadata
        (Result, 2, 3, 1, "Region Add result must be independent Float16 C1");
      AUnit.Assertions.Assert
        (Result.Is_Continuous,
         "Region arithmetic must produce independent continuous storage");
      Assert_Stored_Bits (Result, 0, 0, 16#4200#, "Region Add 1.0+2.0");
      Assert_Stored_Bits
        (Left_Parent, 0, 0, 16#3C00#, "C1 parent Left must stay unchanged");
      Assert_Stored_Bits
        (Right_Parent, 1, 2, 16#4000#, "C1 parent Right must stay unchanged");
      Set_C1 (Result, 0, 0, 16#7C00#);
      Assert_Stored_Bits
        (Left_Parent,
         1,
         2,
         16#3C00#,
         "mutating Region Add result must not affect the parent");

      C3_Region_L :=
        C3_Parent_L.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      C3_Region_R :=
        C3_Parent_R.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      AUnit.Assertions.Assert
        (not C3_Region_L.Is_Continuous,
         "C3 Region fixture must be non-contiguous");
      C3_Result := C3_Region_L.Subtract (C3_Region_R);
      Assert_Float16_Metadata
        (C3_Result, 2, 3, 3, "C3 Region Subtract must keep Float16 C3");
      Assert_Stored_Pixel
        (C3_Result,
         0,
         0,
         (0 => Expected_Subtract (F16 (16#3C00#), F16 (16#4000#)),
          1 => Expected_Subtract (F16 (16#C000#), F16 (16#3800#)),
          2 => Expected_Subtract (F16 (16#3800#), F16 (16#4400#))),
         "C3 Region Subtract (1,-2,0.5)-(2,0.5,4)");
      Assert_Stored_Pixel
        (C3_Parent_L,
         0,
         0,
         Pixel (16#3C00#, 16#C000#, 16#3800#),
         "C3 parent must remain unchanged outside the Region");
   end Mat_Float16_Add_Subtract_Handle_Regions;

   procedure Mat_Float16_Add_Subtract_Ownership
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left   : OpenCV.Core.Mat := Float16_C1 (1, 2);
      Right  : OpenCV.Core.Mat := Float16_C1 (1, 2);
      Alias  : OpenCV.Core.Mat;
      Result : OpenCV.Core.Mat;
   begin
      Set_C1 (Left, 0, 0, 16#3C00#);
      Set_C1 (Left, 0, 1, 16#4000#);
      Set_C1 (Right, 0, 0, 16#3C00#);
      Set_C1 (Right, 0, 1, 16#3C00#);
      Alias := Left;
      Result := Left.Add (Right);
      Assert_Stored_Bits
        (Alias, 0, 0, 16#3C00#, "shallow alias must still share Left");
      Set_C1 (Alias, 0, 0, 16#4400#);
      Assert_Stored_Bits
        (Left, 0, 0, 16#4400#, "alias mutation must still share Left storage");
      Assert_Stored_Bits
        (Result, 0, 0, 16#4000#, "result must not share Left storage");
      Set_C1 (Result, 0, 1, 16#7C00#);
      Assert_Stored_Bits
        (Left, 0, 1, 16#4000#, "mutating result must not affect Left");
      Assert_Stored_Bits
        (Right, 0, 1, 16#3C00#, "mutating result must not affect Right");
      Set_C1 (Right, 0, 0, 16#7BFF#);
      Assert_Stored_Bits
        (Result,
         0,
         0,
         16#4000#,
         "later input mutation must not affect result");
   end Mat_Float16_Add_Subtract_Ownership;

   procedure Mat_Float16_Add_Subtract_Reject_Incompatible
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      C1_A        : constant OpenCV.Core.Mat := Float16_C1 (1, 1);
      C1_B        : constant OpenCV.Core.Mat := Float16_C1 (2, 1);
      C1_Wide     : constant OpenCV.Core.Mat := Float16_C1 (1, 2);
      C3          : constant OpenCV.Core.Mat := Float16_C3 (1, 1);
      F32         : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Default_Mat : OpenCV.Core.Mat;
      procedure Bad_Shape is
         X : constant OpenCV.Core.Mat := C1_A.Add (C1_B);
      begin
         pragma Unreferenced (X);
      end Bad_Shape;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat := C1_A.Subtract (C1_Wide);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat := C1_A.Add (C3);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat := C1_A.Subtract (F32);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Default is
         X : constant OpenCV.Core.Mat := Default_Mat.Add (C1_A);
      begin
         pragma Unreferenced (X);
      end Bad_Default;
   begin
      Assert_Raises_OpenCV_Error
        (Bad_Shape'Access, "Float16 Add must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access,
         "Float16 Subtract must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access,
         "Float16 Add must reject C1 vs C3 channel mismatch");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access,
         "Float16 Subtract must reject Float32 depth mismatch");
      Assert_Raises_OpenCV_Error
        (Bad_Default'Access,
         "Float16 Add must reject a default Mat paired with a typed Mat");
   end Mat_Float16_Add_Subtract_Reject_Incompatible;

   Finite_Count : constant := 2 * 16#7C00#;

   type Operand_Bits is array (Positive range <>) of Interfaces.Unsigned_16;

   Sweep_Operands : constant Operand_Bits :=
     (16#0000#,
      16#8000#,
      16#0001#,
      16#03FF#,
      16#0400#,
      16#3C00#,
      16#BC00#,
      16#7BFF#,
      16#FBFF#);

   Sample_Pair_Count : constant := 4096;

   procedure Fill_Finite_Left
     (Data : aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
   is
      Index : Natural := 0;
   begin
      for Bits in Interfaces.Unsigned_16 range 0 .. 16#7BFF# loop
         Data (Index) := F16 (Bits);
         Index := Index + 1;
      end loop;
      for Bits in Interfaces.Unsigned_16 range 16#8000# .. 16#FBFF# loop
         Data (Index) := F16 (Bits);
         Index := Index + 1;
      end loop;
   end Fill_Finite_Left;

   procedure Fill_Constant
     (Image : in out OpenCV.Core.Mat; Bits : Interfaces.Unsigned_16)
   is
      procedure Fill
        (Data : aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
      is
      begin
         for Index in Data'Range loop
            Data (Index) := F16 (Bits);
         end loop;
      end Fill;
   begin
      OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
        (Image, Fill'Access);
   end Fill_Constant;

   function Sample_Left_Bits (Index : Natural) return Interfaces.Unsigned_16 is
      Raw : constant Natural := (Index * 13) mod Finite_Count;
   begin
      if Raw < 16#7C00# then
         return Interfaces.Unsigned_16 (Raw);
      else
         return Interfaces.Unsigned_16 (Raw - 16#7C00#) + 16#8000#;
      end if;
   end Sample_Left_Bits;

   function Sample_Right_Bits (Index : Natural) return Interfaces.Unsigned_16
   is
      Raw : constant Natural := (Index * 29 + 17) mod Finite_Count;
   begin
      if Raw < 16#7C00# then
         return Interfaces.Unsigned_16 (Raw);
      else
         return Interfaces.Unsigned_16 (Raw - 16#7C00#) + 16#8000#;
      end if;
   end Sample_Right_Bits;

   procedure Mat_Float16_Finite_Oracle_Sweep (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left : OpenCV.Core.Mat := Float16_C1 (1, Finite_Count);
   begin
      OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
        (Left, Fill_Finite_Left'Access);
      for Operand of Sweep_Operands loop
         declare
            Right : OpenCV.Core.Mat := Float16_C1 (1, Finite_Count);
            Sum   : OpenCV.Core.Mat;
            Diff  : OpenCV.Core.Mat;
            procedure Check
              (Data   : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array;
               Is_Add : Boolean)
            is
               Right_Value : constant OpenCV.Core.Float16_Value :=
                 F16 (Operand);
            begin
               for Index in Data'Range loop
                  declare
                     Left_Value : constant OpenCV.Core.Float16_Value :=
                       OpenCV.Core.Float16_Access.Get (Left, 0, Index);
                     Expected   : constant OpenCV.Core.Float16_Value :=
                       (if Is_Add
                        then Expected_Add (Left_Value, Right_Value)
                        else Expected_Subtract (Left_Value, Right_Value));
                  begin
                     if Bits_Of (Data (Index)) /= Bits_Of (Expected) then
                        AUnit.Assertions.Assert
                          (False,
                           (if Is_Add then "Add" else "Subtract")
                           & " oracle mismatch left="
                           & Interfaces.Unsigned_16'Image
                               (Bits_Of (Left_Value))
                           & " right="
                           & Interfaces.Unsigned_16'Image (Operand)
                           & " got="
                           & Interfaces.Unsigned_16'Image
                               (Bits_Of (Data (Index)))
                           & " expected="
                           & Interfaces.Unsigned_16'Image
                               (Bits_Of (Expected)));
                     end if;
                  end;
               end loop;
            end Check;
            procedure Check_Add
              (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
            is
            begin
               Check (Data, True);
            end Check_Add;
            procedure Check_Sub
              (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array)
            is
            begin
               Check (Data, False);
            end Check_Sub;
         begin
            Fill_Constant (Right, Operand);
            Sum := Left.Add (Right);
            Diff := Left.Subtract (Right);
            OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
              (Sum, Check_Add'Access);
            OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
              (Diff, Check_Sub'Access);
         end;
      end loop;
   end Mat_Float16_Finite_Oracle_Sweep;

   procedure Mat_Float16_Finite_Oracle_Sample (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left  : OpenCV.Core.Mat := Float16_C1 (1, Sample_Pair_Count);
      Right : OpenCV.Core.Mat := Float16_C1 (1, Sample_Pair_Count);
      Sum   : OpenCV.Core.Mat;
      Diff  : OpenCV.Core.Mat;
      procedure Fill_Sample
        (Left_Data :
           aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
      begin
         for Index in Left_Data'Range loop
            Left_Data (Index) := F16 (Sample_Left_Bits (Index));
         end loop;
      end Fill_Sample;
      procedure Fill_Right
        (Right_Data :
           aliased in out OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
      begin
         for Index in Right_Data'Range loop
            Right_Data (Index) := F16 (Sample_Right_Bits (Index));
         end loop;
      end Fill_Right;
      procedure Check_Add
        (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
      begin
         for Index in Data'Range loop
            declare
               L : constant OpenCV.Core.Float16_Value :=
                 F16 (Sample_Left_Bits (Index));
               R : constant OpenCV.Core.Float16_Value :=
                 F16 (Sample_Right_Bits (Index));
            begin
               if Bits_Of (Data (Index)) /= Bits_Of (Expected_Add (L, R)) then
                  AUnit.Assertions.Assert
                    (False, "sampled Add mismatch at" & Integer'Image (Index));
               end if;
            end;
         end loop;
      end Check_Add;
      procedure Check_Sub
        (Data : aliased OpenCV.Core.Float16_Buffer_Access.Buffer_Array) is
      begin
         for Index in Data'Range loop
            declare
               L : constant OpenCV.Core.Float16_Value :=
                 F16 (Sample_Left_Bits (Index));
               R : constant OpenCV.Core.Float16_Value :=
                 F16 (Sample_Right_Bits (Index));
            begin
               if Bits_Of (Data (Index)) /= Bits_Of (Expected_Subtract (L, R))
               then
                  AUnit.Assertions.Assert
                    (False,
                     "sampled Subtract mismatch at" & Integer'Image (Index));
               end if;
            end;
         end loop;
      end Check_Sub;
   begin
      OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
        (Left, Fill_Sample'Access);
      OpenCV.Core.Float16_Buffer_Access.With_Writable_Buffer
        (Right, Fill_Right'Access);
      Sum := Left.Add (Right);
      Diff := Left.Subtract (Right);
      OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
        (Sum, Check_Add'Access);
      OpenCV.Core.Float16_Buffer_Access.With_Read_Only_Buffer
        (Diff, Check_Sub'Access);
   end Mat_Float16_Finite_Oracle_Sample;

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
      Result.Add_Test
        (Caller.Create
           ("Mat mixed empty representations remain empty",
            Mat_Mixed_Empty_Representations_Remain_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Add works for Float16 C1",
            Mat_Add_Works_For_Float16_C1'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Subtract works for Float16 C1",
            Mat_Subtract_Works_For_Float16_C1'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 Add and Subtract round to nearest even",
            Mat_Float16_Add_Subtract_Round_To_Nearest_Even'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 Add and Subtract handle subnormals",
            Mat_Float16_Add_Subtract_Handle_Subnormals'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 Add overflows to signed infinity",
            Mat_Float16_Add_Overflows_To_Signed_Infinity'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 Add and Subtract signed zero",
            Mat_Float16_Add_Subtract_Signed_Zero'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 Add and Subtract infinity and NaN",
            Mat_Float16_Add_Subtract_Infinity_And_NaN'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Add works for Float16 C3",
            Mat_Add_Works_For_Float16_C3'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Subtract works for Float16 C3",
            Mat_Subtract_Works_For_Float16_C3'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 C3 mixed numeric categories",
            Mat_Float16_C3_Mixed_Numeric_Categories'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 C3 Add and Subtract multi-row",
            Mat_Float16_C3_Add_Subtract_Multi_Row'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 Add and Subtract handle Regions",
            Mat_Float16_Add_Subtract_Handle_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 Add and Subtract ownership",
            Mat_Float16_Add_Subtract_Ownership'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 Add and Subtract reject incompatible",
            Mat_Float16_Add_Subtract_Reject_Incompatible'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 finite oracle sweep",
            Mat_Float16_Finite_Oracle_Sweep'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat Float16 finite oracle sample",
            Mat_Float16_Finite_Oracle_Sample'Access));

      return Result'Access;
   end Suite;

end Mat_Arithmetic_Tests;
