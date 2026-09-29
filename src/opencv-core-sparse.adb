with Ada.Exceptions;

package body OpenCV.Core.Sparse is
   package C renames OpenCV.Internal.C_API;
   use type C.Status;
   use type C.C_UInt8;

   procedure Check (Status : C.Status; Operation : String) is
   begin
      if Status /= C.Success then
         Ada.Exceptions.Raise_Exception
           (OpenCV_Error'Identity, Operation & ": " & C.Last_Error_Message);
      end if;
   end Check;

   procedure Require_Allocated (Self : Sparse_Mat) is
   begin
      if not Self.Is_Allocated then
         raise OpenCV_Error with "Sparse_Mat is unallocated";
      end if;
   end Require_Allocated;

   function Metadata (Self : Sparse_Mat) return C.C_Int32_Array is
      Values                      : C.C_Int32_Array (0 .. 2) := (others => 0);
      Bytes, Channel_Bytes, Nodes : aliased C.C_UInt64 := 0;
   begin
      Check
        (C.Sparse_Metadata
           (Self.Handle,
            Values (0)'Access,
            Values (1)'Access,
            Values (2)'Access,
            Bytes'Access,
            Channel_Bytes'Access,
            Nodes'Access),
         "sparse metadata");
      return Values;
   end Metadata;

   overriding
   procedure Initialize (Self : in out Sparse_Mat) is
      New_Handle : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
   begin
      Check (C.Sparse_Create (New_Handle'Access), "sparse initialization");
      Self.Handle := New_Handle;
   end Initialize;

   overriding
   procedure Adjust (Self : in out Sparse_Mat) is
      Old        : constant C.Sparse_Mat_Handle := Self.Handle;
      New_Handle : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
   begin
      Self.Handle := C.Null_Sparse_Mat_Handle;
      Check (C.Sparse_Copy (Old, New_Handle'Access), "sparse assignment");
      Self.Handle := New_Handle;
   end Adjust;

   overriding
   procedure Finalize (Self : in out Sparse_Mat) is
      Old : constant C.Sparse_Mat_Handle := Self.Handle;
   begin
      Self.Handle := C.Null_Sparse_Mat_Handle;
      C.Sparse_Destroy (Old);
   end Finalize;

   function Create
     (Shape : Dimension_Array; Element_Type : Mat_Type) return Sparse_Mat is
   begin
      if Shape'Length < 2 or else Shape'Length > 32 then
         raise OpenCV_Error with "Sparse_Mat requires 2 .. 32 dimensions";
      end if;
      declare
         Sizes      : C.C_Int32_Array (0 .. Shape'Length - 1);
         Position   : Natural := 0;
         Result     : Sparse_Mat;
         New_Handle : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
      begin
         for Value of Shape loop
            if Value = 0 then
               raise OpenCV_Error with "Sparse_Mat extents must be positive";
            end if;
            Sizes (Position) := C.C_Int32 (Value);
            Position := Position + 1;
         end loop;
         Check
           (C.Sparse_Create_ND
              (C.C_Int32 (Shape'Length),
               Sizes (0)'Access,
               C.C_Int32 (Depth_Type'Pos (Element_Type.Depth)),
               C.C_Int32 (Element_Type.Channels),
               New_Handle'Access),
            "sparse creation");
         C.Sparse_Destroy (Result.Handle);
         Result.Handle := New_Handle;
         return Result;
      end;
   end Create;

   function From_Dense (Source : Mat) return Sparse_Mat is
      Result     : Sparse_Mat;
      New_Handle : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
   begin
      if Source.Is_Empty then
         raise OpenCV_Error with "dense source must not be empty";
      end if;
      Check
        (C.Sparse_From_Dense (Source.Handle, New_Handle'Access),
         "dense to sparse");
      C.Sparse_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end From_Dense;

   function To_Dense (Self : Sparse_Mat) return Mat is
      Result     : Mat;
      New_Handle : aliased C.Mat_Handle := C.Null_Mat_Handle;
   begin
      Require_Allocated (Self);
      Check
        (C.Sparse_To_Dense (Self.Handle, New_Handle'Access),
         "sparse to dense");
      C.Mat_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end To_Dense;

   function Clone (Self : Sparse_Mat) return Sparse_Mat is
      Result     : Sparse_Mat;
      New_Handle : aliased C.Sparse_Mat_Handle := C.Null_Sparse_Mat_Handle;
   begin
      Check (C.Sparse_Clone (Self.Handle, New_Handle'Access), "sparse clone");
      C.Sparse_Destroy (Result.Handle);
      Result.Handle := New_Handle;
      return Result;
   end Clone;

   procedure Clear (Self : in out Sparse_Mat) is
   begin
      Check (C.Sparse_Clear (Self.Handle), "sparse clear");
   end Clear;

   function Dimension_Count (Self : Sparse_Mat) return Natural is
   begin
      return Natural (Metadata (Self) (0));
   end Dimension_Count;

   function Is_Allocated (Self : Sparse_Mat) return Boolean is
   begin
      return Self.Dimension_Count /= 0;
   end Is_Allocated;

   function Extent (Self : Sparse_Mat; Axis : Positive) return Size_Coordinate
   is
      Value : aliased C.C_Int32 := 0;
   begin
      Require_Allocated (Self);
      if Axis > Self.Dimension_Count then
         raise OpenCV_Error with "sparse axis out of bounds";
      end if;
      Check
        (C.Sparse_Extent (Self.Handle, C.C_Int32 (Axis - 1), Value'Access),
         "sparse extent");
      return Size_Coordinate (Value);
   end Extent;

   function Shape (Self : Sparse_Mat) return Dimension_Array is
      Count : constant Natural := Self.Dimension_Count;
   begin
      if Count = 0 then
         return (1 .. 0 => 0);
      end if;
      declare
         Result : Dimension_Array (1 .. Count);
      begin
         for Axis in Result'Range loop
            Result (Axis) := Self.Extent (Axis);
         end loop;
         return Result;
      end;
   end Shape;

   function Depth (Self : Sparse_Mat) return Depth_Type is
   begin
      Require_Allocated (Self);
      return Depth_Type'Val (Integer (Metadata (Self) (1)));
   end Depth;

   function Channels (Self : Sparse_Mat) return Channel_Count is
   begin
      Require_Allocated (Self);
      return Channel_Count (Metadata (Self) (2));
   end Channels;

   function Element_Size (Self : Sparse_Mat) return Mat_Size is
      D, P, N     : aliased C.C_Int32 := 0;
      E, B, Count : aliased C.C_UInt64 := 0;
   begin
      Require_Allocated (Self);
      Check
        (C.Sparse_Metadata
           (Self.Handle,
            D'Access,
            P'Access,
            N'Access,
            E'Access,
            B'Access,
            Count'Access),
         "sparse element size");
      return Mat_Size (E);
   end Element_Size;

   function Channel_Size (Self : Sparse_Mat) return Mat_Size is
      D, P, N     : aliased C.C_Int32 := 0;
      E, B, Count : aliased C.C_UInt64 := 0;
   begin
      Require_Allocated (Self);
      Check
        (C.Sparse_Metadata
           (Self.Handle,
            D'Access,
            P'Access,
            N'Access,
            E'Access,
            B'Access,
            Count'Access),
         "sparse channel size");
      return Mat_Size (B);
   end Channel_Size;

   function Stored_Element_Count (Self : Sparse_Mat) return Mat_Size is
      D, P, N     : aliased C.C_Int32 := 0;
      E, B, Count : aliased C.C_UInt64 := 0;
   begin
      Check
        (C.Sparse_Metadata
           (Self.Handle,
            D'Access,
            P'Access,
            N'Access,
            E'Access,
            B'Access,
            Count'Access),
         "sparse node count");
      return Mat_Size (Count);
   end Stored_Element_Count;

   procedure Check_Indices (Self : Sparse_Mat; Indices : Index_Array) is
      Axis : Positive := 1;
   begin
      Require_Allocated (Self);
      if Indices'Length /= Self.Dimension_Count then
         raise OpenCV_Error with "sparse index dimension mismatch";
      end if;
      for Value of Indices loop
         if Value >= Self.Extent (Axis) then
            raise OpenCV_Error with "sparse index out of bounds";
         end if;
         Axis := Axis + 1;
      end loop;
   end Check_Indices;

   procedure Check_Layout
     (Self : Sparse_Mat; Indices : Index_Array; Expected : Depth_Type) is
   begin
      Check_Indices (Self, Indices);
      Check_Layout (Self, Expected);
   end Check_Layout;

   procedure Check_Layout (Self : Sparse_Mat; Expected : Depth_Type) is
   begin
      Require_Allocated (Self);
      if Self.Depth /= Expected or else Self.Channels /= 1 then
         raise OpenCV_Error with "sparse C1 depth mismatch";
      end if;
   end Check_Layout;

   function C_Indices (Indices : Index_Array) return C.C_Int32_Array is
      Result   : C.C_Int32_Array (0 .. Indices'Length - 1);
      Position : Natural := 0;
   begin
      for Value of Indices loop
         Result (Position) := C.C_Int32 (Value);
         Position := Position + 1;
      end loop;
      return Result;
   end C_Indices;

   function Contains (Self : Sparse_Mat; Indices : Index_Array) return Boolean
   is
      Values : C.C_Int32_Array := C_Indices (Indices);
      Found  : aliased C.C_UInt8 := 0;
   begin
      Check_Indices (Self, Indices);
      Check
        (C.Sparse_Contains
           (Self.Handle,
            C.C_Int32 (Values'Length),
            Values (0)'Access,
            Found'Access),
         "sparse contains");
      return Found = 1;
   end Contains;

   procedure Erase (Self : in out Sparse_Mat; Indices : Index_Array) is
      Values : C.C_Int32_Array := C_Indices (Indices);
   begin
      Check_Indices (Self, Indices);
      Check
        (C.Sparse_Erase
           (Self.Handle, C.C_Int32 (Values'Length), Values (0)'Access),
         "sparse erase");
   end Erase;
end OpenCV.Core.Sparse;
