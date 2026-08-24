generic
   type Element_Type is private;
   type Row_Array is array (Natural range <>) of Element_Type;
   Required_Depth : Depth_Type;
   Required_Channels : Channel_Count;
   Expected_Element_Bits : Positive;
   Native_Element_Alignment : Positive;
   Type_Name : String;
package OpenCV.Core.Internal.Typed_Row_Borrowing is

   --  Overlay one logical Mat row onto Row_Array for the duration of
   --  Process. Data is an explicitly aliased view of native storage.
   procedure With_Read_Only_Row
     (Image   : Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased Row_Array));

   procedure With_Writable_Row
     (Image   : in out Mat;
      Row     : Natural;
      Process : not null access procedure (Data : aliased in out Row_Array));

end OpenCV.Core.Internal.Typed_Row_Borrowing;
