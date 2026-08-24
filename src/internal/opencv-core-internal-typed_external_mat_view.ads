generic
   type Element_Type is private;
   type Buffer_Array is array (Natural range <>) of Element_Type;
   Required_Depth : Depth_Type;
   Required_Channels : Channel_Count;
   Expected_Element_Bits : Positive;
   Native_Element_Alignment : Positive;
   Type_Name : String;
package OpenCV.Core.Internal.Typed_External_Mat_View is

   --  Invokes Process with a temporary Mat whose pixels alias Data.
   --  The Mat header does not own Data and is valid only during Process.
   procedure With_Writable_Mat_View
     (Data    : aliased in out Buffer_Array;
      Rows    : Positive;
      Columns : Positive;
      Process : not null access procedure (Image : in out Mat));

   --  Invokes Process with a temporary Mat whose logical rows alias Data at
   --  Row_Stride_Elements complete Buffer_Array elements apart.
   procedure With_Writable_Strided_Mat_View
     (Data                : aliased in out Buffer_Array;
      Rows                : Positive;
      Columns             : Positive;
      Row_Stride_Elements : Positive;
      Process             : not null access procedure (Image : in out Mat));

end OpenCV.Core.Internal.Typed_External_Mat_View;
