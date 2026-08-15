with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with Mat_Test_Support;
with OpenCV.Core.Float32_Vec3_Access;

package body Mat_Mask_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Mat_Size;
   use type OpenCV.Core.UInt8_Vec3.Vector;

   use Mat_Test_Support;
   use type OpenCV.Core.Float32_Access.Float32_Classification;

   procedure Mat_Bitwise_Operations_Handle_UInt8_And_Vec3
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right                                               :
        OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Vec_Left, Vec_Right                                       :
        OpenCV.Core.Mat := OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      And_Result, Or_Result, Xor_Result, Not_Result, Vec_Result :
        OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Left, 0, 0, 16#AA#);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 0, 16#0F#);
      And_Result := Left.Bitwise_And (Right);
      Or_Result := Left.Bitwise_Or (Right);
      Xor_Result := Left.Bitwise_Xor (Right);
      Not_Result := Left.Bitwise_Not;
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Vec_Left, 0, 0, (16#F0#, 16#0F#, 16#AA#));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Vec_Right, 0, 0, (16#0F#, 16#F0#, 16#55#));
      Vec_Result := Vec_Left.Bitwise_Xor (Vec_Right);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (And_Result, 0, 0) = 16#0A#
         and then OpenCV.Core.UInt8_Access.Get (Or_Result, 0, 0) = 16#AF#
         and then OpenCV.Core.UInt8_Access.Get (Xor_Result, 0, 0) = 16#A5#
         and then OpenCV.Core.UInt8_Access.Get (Not_Result, 0, 0) = 16#55#
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 0)
                  = (16#FF#, 16#FF#, 16#FF#),
         "Bitwise operations must preserve UInt8 and Vec3 bit patterns");
   end Mat_Bitwise_Operations_Handle_UInt8_And_Vec3;

   procedure Mat_Bitwise_Operations_Handle_Int16_And_Float32
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Int16_Left, Int16_Right                      : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Int16, 1));
      Int16_And, Int16_Not                         : OpenCV.Core.Mat;
      Numerator, Zeroes                            : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Infinity, And_Result, Xor_Result, Not_Result : OpenCV.Core.Mat;
   begin
      Int16_Left.Set_To (OpenCV.Core.Make_Scalar (-1.0));
      Int16_Right.Set_To (OpenCV.Core.Make_Scalar (255.0));
      Int16_And := Int16_Left.Bitwise_And (Int16_Right);
      Int16_Not := Int16_Right.Bitwise_Not;
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 0, 1.0);
      Zeroes.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Infinity := Numerator.Divide (Zeroes);
      And_Result := Infinity.Bitwise_And (Infinity);
      Xor_Result := Infinity.Bitwise_Xor (Infinity);
      Not_Result := Infinity.Bitwise_Not;

      AUnit.Assertions.Assert
        (Int16_And.Sum.Component_0 = 255.0
         and then Int16_Not.Sum.Component_0 = -256.0
         and then OpenCV.Core.Float32_Access.Classify (And_Result, 0, 0)
                  = OpenCV.Core.Float32_Access.Positive_Infinity
         and then OpenCV.Core.Float32_Access.Classify (Xor_Result, 0, 0)
                  = OpenCV.Core.Float32_Access.Finite
         and then OpenCV.Core.Float32_Access.Classify (Not_Result, 0, 0)
                  = OpenCV.Core.Float32_Access.Finite,
         "Bitwise operations must use signed and Float32 stored bit patterns");
   end Mat_Bitwise_Operations_Handle_Int16_And_Float32;

   procedure Mat_Bitwise_Operations_Handle_Regions_And_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right                                        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      Result                                             : OpenCV.Core.Mat;
      Empty_Left, Empty_Right, Empty_Binary, Empty_Unary : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (240.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (15.0));
      Result :=
        Left.Region ((1, 0, 2, 3)).Bitwise_Or (Right.Region ((1, 0, 2, 3)));
      OpenCV.Core.UInt8_Access.Set (Left, 0, 1, 0);
      OpenCV.Core.UInt8_Access.Set (Result, 0, 1, 16#33#);
      Empty_Binary := Empty_Left.Bitwise_And (Empty_Right);
      Empty_Unary := Empty_Left.Bitwise_Not;

      AUnit.Assertions.Assert
        (Result.Is_Continuous
         and then OpenCV.Core.UInt8_Access.Get (Result, 0, 0) = 16#FF#
         and then OpenCV.Core.UInt8_Access.Get (Left, 0, 2) = 16#F0#
         and then OpenCV.Core.UInt8_Access.Get (Right, 0, 2) = 16#0F#
         and then Empty_Binary.Is_Empty
         and then Empty_Unary.Is_Empty,
         "Bitwise operations must support Regions, independence, and empty"
         & " Mats");
   end Mat_Bitwise_Operations_Handle_Regions_And_Independence;

   procedure Mat_Bitwise_Compatibility_Failures
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
         X : constant OpenCV.Core.Mat := Base.Bitwise_And (Rows);
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat := Base.Bitwise_Or (Columns);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat := Base.Bitwise_Xor (Depth);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat := Base.Bitwise_And (Channels);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
   begin
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Bitwise_And must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Bitwise_Or must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Bitwise_Xor must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Bitwise_And must reject mismatched channels");
   end Mat_Bitwise_Compatibility_Failures;

   procedure Masked_Bitwise_Operations_Select_Nonzero_Values
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left, Right, Mask                             : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      And_Result, Or_Result, Xor_Result, Not_Result : OpenCV.Core.Mat;
   begin
      Left.Set_To (OpenCV.Core.Make_Scalar (170.0));
      Right.Set_To (OpenCV.Core.Make_Scalar (15.0));
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 0, 0);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 1, 1);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 0, 255);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 1, 0);
      And_Result := Left.Bitwise_And (Right, Mask);
      Or_Result := Left.Bitwise_Or (Right, Mask);
      Xor_Result := Left.Bitwise_Xor (Right, Mask);
      Not_Result := Left.Bitwise_Not (Mask);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (And_Result, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (And_Result, 0, 1) = 16#0A#
         and then OpenCV.Core.UInt8_Access.Get (And_Result, 1, 0) = 16#0A#
         and then OpenCV.Core.UInt8_Access.Get (Or_Result, 0, 1) = 16#AF#
         and then OpenCV.Core.UInt8_Access.Get (Xor_Result, 1, 0) = 16#A5#
         and then OpenCV.Core.UInt8_Access.Get (Not_Result, 0, 1) = 16#55#
         and then OpenCV.Core.UInt8_Access.Get (Not_Result, 1, 1) = 0,
         "Masked bitwise operations must select any nonzero UInt8 mask value"
         & " and zero unselected new output");
   end Masked_Bitwise_Operations_Select_Nonzero_Values;

   procedure Masked_Bitwise_Vec3_Regions_Independence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Vec_Left, Vec_Right        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 3));
      Vec_Mask                   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Source, Other, Mask_Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Vec_Result, Region_Result  : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Vec_Left, 0, 0, (16#F0#, 16#0F#, 16#AA#));
      OpenCV.Core.UInt8_Vec3_Access.Set
        (Vec_Right, 0, 0, (16#0F#, 16#F0#, 16#55#));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Left, 0, 1, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Vec_Right, 0, 1, (4, 5, 6));
      Vec_Mask.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Vec_Mask, 0, 0, 1);
      Vec_Result := Vec_Left.Bitwise_Xor (Vec_Right, Vec_Mask);
      Source.Set_To (OpenCV.Core.Make_Scalar (240.0));
      Other.Set_To (OpenCV.Core.Make_Scalar (15.0));
      Mask_Parent.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 0, 1, 255);
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 1, 2, 1);
      Region_Result :=
        Source.Region ((1, 0, 2, 2)).Bitwise_Or
          (Other.Region ((1, 0, 2, 2)), Mask_Parent.Region ((1, 0, 2, 2)));
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 0);
      OpenCV.Core.UInt8_Access.Set (Mask_Parent, 0, 1, 0);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 0)
         = (16#FF#, 16#FF#, 16#FF#)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Vec_Result, 0, 1)
                  = (0, 0, 0)
         and then not Mask_Parent.Region ((1, 0, 2, 2)).Is_Continuous
         and then Region_Result.Is_Continuous
         and then OpenCV.Core.UInt8_Access.Get (Region_Result, 0, 0) = 16#FF#
         and then OpenCV.Core.UInt8_Access.Get (Region_Result, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Region_Result, 1, 1) = 16#FF#,
         "Masked bitwise operations must support Vec3 and non-continuous masks"
         & " with independent output");
   end Masked_Bitwise_Vec3_Regions_Independence;

   procedure Masked_Bitwise_Invalid_Masks_And_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source, Other                          : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 1));
      Float_Mask                             : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.Float32, 1));
      Multi_Mask                             : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 3));
      Rows_Mask                              : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 1, (OpenCV.Core.UInt8, 1));
      Columns_Mask                           : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 2, (OpenCV.Core.UInt8, 1));
      Empty_Source, Empty_Mask, Empty_Result : OpenCV.Core.Mat;
      procedure Float_Depth is
         X : constant OpenCV.Core.Mat :=
           Source.Bitwise_And (Other, Float_Mask);
      begin
         pragma Unreferenced (X);
      end Float_Depth;
      procedure Multi_Channel is
         X : constant OpenCV.Core.Mat := Source.Bitwise_Or (Other, Multi_Mask);
      begin
         pragma Unreferenced (X);
      end Multi_Channel;
      procedure Wrong_Rows is
         X : constant OpenCV.Core.Mat := Source.Bitwise_Xor (Other, Rows_Mask);
      begin
         pragma Unreferenced (X);
      end Wrong_Rows;
      procedure Wrong_Columns is
         X : constant OpenCV.Core.Mat := Source.Bitwise_Not (Columns_Mask);
      begin
         pragma Unreferenced (X);
      end Wrong_Columns;
   begin
      Empty_Result := Empty_Source.Bitwise_Not (Empty_Mask);
      AUnit.Assertions.Assert
        (Empty_Result.Is_Empty,
         "Masked empty Mat operation must remain empty");
      Assert_Raises_OpenCV_Error
        (Float_Depth'Access, "Mask must reject Float32 depth");
      Assert_Raises_OpenCV_Error
        (Multi_Channel'Access, "Mask must reject multiple channels");
      Assert_Raises_OpenCV_Error
        (Wrong_Rows'Access, "Mask must reject wrong rows");
      Assert_Raises_OpenCV_Error
        (Wrong_Columns'Access, "Mask must reject wrong columns");
   end Masked_Bitwise_Invalid_Masks_And_Empty;

   procedure In_Range_Uses_Inclusive_UInt8_Bounds_And_Mask_Contract
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Source              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.UInt8, 1));
      Range_Mask, Applied : OpenCV.Core.Mat;
      Other               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.UInt8, 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Source, 0, 0, 9);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 15);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 3, 20);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 4, 21);
      Other.Set_To (OpenCV.Core.Make_Scalar (255.0));
      Range_Mask :=
        Source.In_Range
          (Lower => OpenCV.Core.Make_Scalar (10.0),
           Upper => OpenCV.Core.Make_Scalar (20.0));
      Applied := Source.Bitwise_And (Other, Range_Mask);
      OpenCV.Core.UInt8_Access.Set (Source, 0, 2, 0);

      AUnit.Assertions.Assert
        (Range_Mask.Rows = Source.Rows
         and then Range_Mask.Columns = Source.Columns
         and then Range_Mask.Depth = OpenCV.Core.UInt8
         and then Range_Mask.Channels = 1
         and then OpenCV.Core.UInt8_Access.Get (Range_Mask, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Range_Mask, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Range_Mask, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Range_Mask, 0, 3) = 255
         and then OpenCV.Core.UInt8_Access.Get (Range_Mask, 0, 4) = 0
         and then OpenCV.Core.UInt8_Access.Get (Applied, 0, 2) = 15,
         "In_Range must be inclusive and produce a directly usable mask");
   end In_Range_Uses_Inclusive_UInt8_Bounds_And_Mask_Contract;

   procedure In_Range_Handles_Float32_Vec3_And_Regions
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Float_Image                       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Vec_Image                         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 5, (OpenCV.Core.Float32, 3));
      Region_Source                     : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Float_Mask, Vec_Mask, Region_Mask : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Float_Image, 0, 0, -1.5);
      OpenCV.Core.Float32_Access.Set (Float_Image, 0, 1, -1.0);
      OpenCV.Core.Float32_Access.Set (Float_Image, 0, 2, 0.5);
      OpenCV.Core.Float32_Access.Set (Float_Image, 0, 3, 1.25);
      Float_Mask :=
        Float_Image.In_Range
          (OpenCV.Core.Make_Scalar (-1.0), OpenCV.Core.Make_Scalar (1.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Vec_Image, 0, 0, (1.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Vec_Image, 0, 1, (0.0, 2.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Vec_Image, 0, 2, (1.0, 4.0, 3.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Vec_Image, 0, 3, (1.0, 2.0, 4.0));
      OpenCV.Core.Float32_Vec3_Access.Set (Vec_Image, 0, 4, (1.0, 2.0, 3.0));
      Vec_Mask :=
        Vec_Image.In_Range
          (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0),
           OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0));
      Region_Source.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Region_Source, 0, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Region_Source, 0, 2, 20);
      OpenCV.Core.UInt8_Access.Set (Region_Source, 1, 1, 15);
      OpenCV.Core.UInt8_Access.Set (Region_Source, 1, 2, 25);
      Region_Mask :=
        Region_Source.Region ((1, 0, 2, 2)).In_Range
          (OpenCV.Core.Make_Scalar (10.0), OpenCV.Core.Make_Scalar (20.0));

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Float_Mask, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Float_Mask, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Float_Mask, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Float_Mask, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Vec_Mask, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Vec_Mask, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Vec_Mask, 0, 2) = 0
         and then OpenCV.Core.UInt8_Access.Get (Vec_Mask, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Vec_Mask, 0, 4) = 255
         and then Region_Mask.Is_Continuous
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 1, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 1, 1) = 0,
         "In_Range must use fractional bounds, all Vec3 channels, and"
         & " Regions");
   end In_Range_Handles_Float32_Vec3_And_Regions;

   procedure In_Range_Handles_Nonfinite_Empty_And_Channel_Failures
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Numerator, Zeroes : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Nonfinite, Mask   : OpenCV.Core.Mat;
      Empty             : OpenCV.Core.Mat;
      Five_Channel      : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 1, (OpenCV.Core.UInt8, 5));
      procedure Empty_Source is
         X : constant OpenCV.Core.Mat :=
           Empty.In_Range
             (OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (1.0));
      begin
         pragma Unreferenced (X);
      end Empty_Source;
      procedure Too_Many_Channels is
         X : constant OpenCV.Core.Mat :=
           Five_Channel.In_Range
             (OpenCV.Core.Make_Scalar (0.0), OpenCV.Core.Make_Scalar (255.0));
      begin
         pragma Unreferenced (X);
      end Too_Many_Channels;
   begin
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 2, -1.0);
      Zeroes.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Nonfinite := Numerator.Divide (Zeroes);
      Mask :=
        Nonfinite.In_Range
          (OpenCV.Core.Make_Scalar (-1.0), OpenCV.Core.Make_Scalar (1.0));

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Mask, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Mask, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Mask, 0, 2) = 0,
         "In_Range must reject NaN and infinite values against finite bounds");
      Assert_Raises_OpenCV_Error
        (Empty_Source'Access, "In_Range must reject an empty source");
      Assert_Raises_OpenCV_Error
        (Too_Many_Channels'Access,
         "In_Range must reject more than four channels");
   end In_Range_Handles_Nonfinite_Empty_And_Channel_Failures;

   procedure Compare_UInt8_All_Modes_And_Mask_Contract
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left                   : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Right                  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Eq, Ne, Lt, Le, Gt, Ge : OpenCV.Core.Mat;
      Other, Applied         : OpenCV.Core.Mat;
   begin
      OpenCV.Core.UInt8_Access.Set (Left, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Left, 0, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Left, 0, 2, 10);
      OpenCV.Core.UInt8_Access.Set (Left, 0, 3, 20);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 0, 1);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 1, 4);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 2, 10);
      OpenCV.Core.UInt8_Access.Set (Right, 0, 3, 30);

      Eq := Left.Compare (Right, OpenCV.Core.Equal);
      Ne := Left.Compare (Right, OpenCV.Core.Not_Equal);
      Lt := Left.Compare (Right, OpenCV.Core.Less_Than);
      Le := Left.Compare (Right, OpenCV.Core.Less_Or_Equal);
      Gt := Left.Compare (Right, OpenCV.Core.Greater_Than);
      Ge := Left.Compare (Right, OpenCV.Core.Greater_Or_Equal);

      Other := OpenCV.Core.Create (1, 4, (OpenCV.Core.UInt8, 1));
      Other.Set_To (OpenCV.Core.Make_Scalar (255.0));
      Applied := Left.Bitwise_And (Other, Ge);
      OpenCV.Core.UInt8_Access.Set (Left, 0, 1, 0);

      AUnit.Assertions.Assert
        (Eq.Rows = 1
         and then Eq.Columns = 4
         and then Eq.Depth = OpenCV.Core.UInt8
         and then Eq.Channels = 1
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 2) = 0
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 3) = 255
         and then OpenCV.Core.UInt8_Access.Get (Lt, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Lt, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Lt, 0, 2) = 0
         and then OpenCV.Core.UInt8_Access.Get (Lt, 0, 3) = 255
         and then OpenCV.Core.UInt8_Access.Get (Le, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Le, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Le, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Le, 0, 3) = 255
         and then OpenCV.Core.UInt8_Access.Get (Gt, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Gt, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Gt, 0, 2) = 0
         and then OpenCV.Core.UInt8_Access.Get (Gt, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Ge, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Ge, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Ge, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Ge, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Applied, 0, 1) = 5,
         "Compare must cover all UInt8 modes and produce a usable mask");
   end Compare_UInt8_All_Modes_And_Mask_Contract;

   procedure Compare_Float32_NaN_And_Regions (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Left                         : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Right                        : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 4, (OpenCV.Core.Float32, 1));
      Eq, Ne                       : OpenCV.Core.Mat;
      Region_Left                  : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Region_Right                 : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Region_Mask                  : OpenCV.Core.Mat;
      Numerator, Zeroes, Nonfinite : OpenCV.Core.Mat;
      Finite                       : OpenCV.Core.Mat :=
        OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Nan_Eq                       : OpenCV.Core.Mat;
   begin
      OpenCV.Core.Float32_Access.Set (Left, 0, 0, -1.5);
      OpenCV.Core.Float32_Access.Set (Left, 0, 1, 0.5);
      OpenCV.Core.Float32_Access.Set (Left, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Left, 0, 3, 2.25);
      OpenCV.Core.Float32_Access.Set (Right, 0, 0, -1.5);
      OpenCV.Core.Float32_Access.Set (Right, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 2, 1.0);
      OpenCV.Core.Float32_Access.Set (Right, 0, 3, 0.0);
      Eq := Left.Compare (Right, OpenCV.Core.Equal);
      Ne := Left.Compare (Right, OpenCV.Core.Not_Equal);

      Region_Left.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Region_Right.Set_To (OpenCV.Core.Make_Scalar (0.0));
      OpenCV.Core.UInt8_Access.Set (Region_Left, 0, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Region_Left, 0, 2, 20);
      OpenCV.Core.UInt8_Access.Set (Region_Left, 1, 1, 30);
      OpenCV.Core.UInt8_Access.Set (Region_Left, 1, 2, 5);
      OpenCV.Core.UInt8_Access.Set (Region_Right, 0, 1, 10);
      OpenCV.Core.UInt8_Access.Set (Region_Right, 0, 2, 15);
      OpenCV.Core.UInt8_Access.Set (Region_Right, 1, 1, 25);
      OpenCV.Core.UInt8_Access.Set (Region_Right, 1, 2, 5);
      Region_Mask :=
        Region_Left.Region ((1, 0, 2, 2)).Compare
          (Region_Right.Region ((1, 0, 2, 2)), OpenCV.Core.Greater_Than);

      Numerator := OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      Zeroes := OpenCV.Core.Create (1, 3, (OpenCV.Core.Float32, 1));
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 0, 0.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 1, 1.0);
      OpenCV.Core.Float32_Access.Set (Numerator, 0, 2, -1.0);
      Zeroes.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Nonfinite := Numerator.Divide (Zeroes);
      Finite.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Nan_Eq := Nonfinite.Compare (Finite, OpenCV.Core.Equal);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Access.Get (Eq, 0, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 2) = 255
         and then OpenCV.Core.UInt8_Access.Get (Eq, 0, 3) = 0
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Ne, 0, 3) = 255
         and then Region_Mask.Is_Continuous
         and then Region_Mask.Rows = 2
         and then Region_Mask.Columns = 2
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 0, 1) = 255
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 1, 0) = 255
         and then OpenCV.Core.UInt8_Access.Get (Region_Mask, 1, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Nan_Eq, 0, 0) = 0
         and then OpenCV.Core.UInt8_Access.Get (Nan_Eq, 0, 1) = 0
         and then OpenCV.Core.UInt8_Access.Get (Nan_Eq, 0, 2) = 0,
         "Compare must handle Float32, NaN, and non-contiguous Regions");
   end Compare_Float32_NaN_And_Regions;

   procedure Compare_Rejects_Incompatible_Operands
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Base  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Rows  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (3, 3, (OpenCV.Core.UInt8, 1));
      Cols  : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 4, (OpenCV.Core.UInt8, 1));
      Depth : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.Float32, 1));
      Multi : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 3));
      procedure Bad_Rows is
         X : constant OpenCV.Core.Mat :=
           Base.Compare (Rows, OpenCV.Core.Equal);
      begin
         pragma Unreferenced (X);
      end Bad_Rows;
      procedure Bad_Columns is
         X : constant OpenCV.Core.Mat :=
           Base.Compare (Cols, OpenCV.Core.Equal);
      begin
         pragma Unreferenced (X);
      end Bad_Columns;
      procedure Bad_Depth is
         X : constant OpenCV.Core.Mat :=
           Base.Compare (Depth, OpenCV.Core.Equal);
      begin
         pragma Unreferenced (X);
      end Bad_Depth;
      procedure Bad_Channels is
         X : constant OpenCV.Core.Mat :=
           Base.Compare (Multi, OpenCV.Core.Equal);
      begin
         pragma Unreferenced (X);
      end Bad_Channels;
      procedure Multi_Left is
         X : constant OpenCV.Core.Mat :=
           Multi.Compare (Base, OpenCV.Core.Equal);
      begin
         pragma Unreferenced (X);
      end Multi_Left;
   begin
      Assert_Raises_OpenCV_Error
        (Bad_Rows'Access, "Compare must reject mismatched rows");
      Assert_Raises_OpenCV_Error
        (Bad_Columns'Access, "Compare must reject mismatched columns");
      Assert_Raises_OpenCV_Error
        (Bad_Depth'Access, "Compare must reject mismatched depths");
      Assert_Raises_OpenCV_Error
        (Bad_Channels'Access, "Compare must reject multi-channel right");
      Assert_Raises_OpenCV_Error
        (Multi_Left'Access, "Compare must reject multi-channel left");
   end Compare_Rejects_Incompatible_Operands;

   procedure Count_Non_Zero_UInt8_Zero_And_Nonzero
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 1));
      Count : OpenCV.Core.Mat_Size;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (0.0));
      Count := Image.Count_Non_Zero;
      AUnit.Assertions.Assert
        (Count = 0, "Count_Non_Zero must return 0 for all-zero UInt8 Mat");

      OpenCV.Core.UInt8_Access.Set (Image, 0, 1, 5);
      OpenCV.Core.UInt8_Access.Set (Image, 1, 2, 255);
      Count := Image.Count_Non_Zero;
      AUnit.Assertions.Assert
        (Count = 2, "Count_Non_Zero must count nonzero UInt8 elements");
   end Count_Non_Zero_UInt8_Zero_And_Nonzero;

   procedure Has_Non_Zero_Returns_False_For_All_Zero_Matrix
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
   begin
      AUnit.Assertions.Assert
        (not Image.Has_Non_Zero,
         "Has_Non_Zero must return False for an all-zero matrix");
   end Has_Non_Zero_Returns_False_For_All_Zero_Matrix;

   procedure Has_Non_Zero_Returns_True_For_Nonzero_Value
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
   begin
      OpenCV.Core.UInt8_Access.Set (Image, 0, 1, 42);
      AUnit.Assertions.Assert
        (Image.Has_Non_Zero,
         "Has_Non_Zero must return True when matrix contains a nonzero value");
   end Has_Non_Zero_Returns_True_For_Nonzero_Value;

   procedure Has_Non_Zero_Rejects_Multi_Channel_Mat
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 3, (OpenCV.Core.UInt8, 3));

      procedure Check is
         Result : constant Boolean := Image.Has_Non_Zero;
      begin
         pragma Unreferenced (Result);
      end Check;
   begin
      Assert_Raises_OpenCV_Error
        (Check'Access, "Has_Non_Zero must reject multi-channel Mats");
   end Has_Non_Zero_Rejects_Multi_Channel_Mat;

   procedure Masked_Set_To_Uses_Common_Mask_Contract_And_Scalar_Semantics
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Image              : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
      Mask               : OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 1));
      Multi_Channel_Mask : constant OpenCV.Core.Mat :=
        OpenCV.Core.Create (2, 2, (OpenCV.Core.UInt8, 3));
      Value              : constant OpenCV.Core.Scalar :=
        OpenCV.Core.Make_Scalar (10.0, 20.0, 30.0);

      procedure Set_With_Multi_Channel_Mask is
      begin
         Image.Set_To (Value, Multi_Channel_Mask);
      end Set_With_Multi_Channel_Mask;
   begin
      Image.Set_To (OpenCV.Core.Make_Scalar (1.0, 2.0, 3.0));
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 0, 0);
      OpenCV.Core.UInt8_Access.Set (Mask, 0, 1, 1);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 0, 255);
      OpenCV.Core.UInt8_Access.Set (Mask, 1, 1, 0);
      Image.Set_To (Value, Mask);

      AUnit.Assertions.Assert
        (OpenCV.Core.UInt8_Vec3_Access.Get (Image, 0, 0) = (1, 2, 3)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Image, 0, 1)
                  = (10, 20, 30)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Image, 1, 0)
                  = (10, 20, 30)
         and then OpenCV.Core.UInt8_Vec3_Access.Get (Image, 1, 1) = (1, 2, 3),
         "Masked Set_To must set every channel of elements selected by any"
         & " nonzero single-channel mask value");
      Assert_Raises_OpenCV_Error
        (Set_With_Multi_Channel_Mask'Access,
         "Masked Set_To must reject multi-channel UInt8 masks");
   end Masked_Set_To_Uses_Common_Mask_Contract_And_Scalar_Semantics;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("Mat bitwise operations handle UInt8 and Vec3",
            Mat_Bitwise_Operations_Handle_UInt8_And_Vec3'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat bitwise operations handle Int16 and Float32",
            Mat_Bitwise_Operations_Handle_Int16_And_Float32'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat bitwise operations handle Regions and independence",
            Mat_Bitwise_Operations_Handle_Regions_And_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Mat bitwise binary operations reject incompatible operands",
            Mat_Bitwise_Compatibility_Failures'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked bitwise operations select nonzero values",
            Masked_Bitwise_Operations_Select_Nonzero_Values'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked bitwise operations handle Vec3, Regions, and independence",
            Masked_Bitwise_Vec3_Regions_Independence'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked bitwise operations reject invalid masks and handle empty",
            Masked_Bitwise_Invalid_Masks_And_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range uses inclusive UInt8 bounds and mask contract",
            In_Range_Uses_Inclusive_UInt8_Bounds_And_Mask_Contract'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range handles Float32, Vec3, and Regions",
            In_Range_Handles_Float32_Vec3_And_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("In_Range handles nonfinite, empty, and channel failures",
            In_Range_Handles_Nonfinite_Empty_And_Channel_Failures'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare covers UInt8 modes and mask contract",
            Compare_UInt8_All_Modes_And_Mask_Contract'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare handles Float32, NaN, and Regions",
            Compare_Float32_NaN_And_Regions'Access));
      Result.Add_Test
        (Caller.Create
           ("Compare rejects incompatible operands",
            Compare_Rejects_Incompatible_Operands'Access));
      Result.Add_Test
        (Caller.Create
           ("Count_Non_Zero UInt8 zero and nonzero",
            Count_Non_Zero_UInt8_Zero_And_Nonzero'Access));
      Result.Add_Test
        (Caller.Create
           ("Has_Non_Zero returns False for all-zero matrix",
            Has_Non_Zero_Returns_False_For_All_Zero_Matrix'Access));
      Result.Add_Test
        (Caller.Create
           ("Has_Non_Zero returns True for nonzero value",
            Has_Non_Zero_Returns_True_For_Nonzero_Value'Access));
      Result.Add_Test
        (Caller.Create
           ("Has_Non_Zero rejects multi-channel Mat",
            Has_Non_Zero_Rejects_Multi_Channel_Mat'Access));
      Result.Add_Test
        (Caller.Create
           ("Masked Set_To uses common mask contract and Scalar semantics",
            Masked_Set_To_Uses_Common_Mask_Contract_And_Scalar_Semantics'Access));
      return Result'Access;
   end Suite;

end Mat_Mask_Tests;
