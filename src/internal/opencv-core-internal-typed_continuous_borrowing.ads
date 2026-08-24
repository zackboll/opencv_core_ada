generic
   type Element_Type is private;
   type Buffer_Array is array (Natural range <>) of Element_Type;
   Required_Depth : Depth_Type;
   Required_Channels : Channel_Count;
   Expected_Element_Bits : Positive;
   Native_Element_Alignment : Positive;
   Type_Name : String;
package OpenCV.Core.Internal.Typed_Continuous_Borrowing is

   --  Overlay a continuous Mat onto Buffer_Array for the duration of
   --  Process. Data is an explicitly aliased flat view of native
   --  storage in row-major element order.
   procedure With_Read_Only_Buffer
     (Image   : Mat;
      Process : not null access procedure (Data : aliased Buffer_Array));

   procedure With_Writable_Buffer
     (Image   : in out Mat;
      Process :
        not null access procedure (Data : aliased in out Buffer_Array));

end OpenCV.Core.Internal.Typed_Continuous_Borrowing;
