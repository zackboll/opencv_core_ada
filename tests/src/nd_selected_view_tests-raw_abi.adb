with Ada.Exceptions;
with AUnit.Assertions;
with Integer_Borrow_Lifetime_Probe;
with Interfaces;
with OpenCV.Internal.C_API;
with System;
with System.Storage_Elements;

package body ND_Selected_View_Tests.Raw_ABI is

   package C renames OpenCV.Internal.C_API;
   package Probe renames Integer_Borrow_Lifetime_Probe;

   use type C.Status;
   use type C.Mat_Handle;
   use type C.C_Int32;
   use type C.C_Boolean;
   use type Interfaces.Unsigned_16;
   use type System.Address;

   type UInt16_Array is
     array (Natural range <>) of aliased Interfaces.Unsigned_16
   with Convention => C;

   function Diagnostic return String
   is (C.Last_Error_Message);

   function Contains (Source, Fragment : String) return Boolean
   is (Source'Length >= Fragment'Length
       and then (for some Offset in 0 .. Source'Length - Fragment'Length =>
                   Source
                     (Source'First
                      + Offset
                      .. Source'First + Offset + Fragment'Length - 1)
                   = Fragment));

   --  Creates an owning Int32 C1 source and stores each element's packed
   --  ordinal (final dimension fastest).
   function Create_Source (Shape : C.C_Int32_Array) return C.Mat_Handle is
      Sizes   : aliased C.C_Int32_Array := Shape;
      Handle  : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Indices : aliased C.C_Int32_Array (Shape'Range) := (others => 0);
      Total   : Natural := 1;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Create_ND
           (Shape'Length,
            Sizes (Sizes'First)'Access,
            C.Depth_Int32,
            1,
            Handle'Access)
         = C.Success,
         "raw selected-view source must be created");
      for Extent of Shape loop
         Total := Total * Natural (Extent);
      end loop;
      for Ordinal in 0 .. Total - 1 loop
         declare
            Rest : Natural := Ordinal;
         begin
            for Axis in reverse Shape'Range loop
               Indices (Axis) := C.C_Int32 (Rest mod Natural (Shape (Axis)));
               Rest := Rest / Natural (Shape (Axis));
            end loop;
         end;
         AUnit.Assertions.Assert
           (C.Mat_Set_Int32_ND
              (Handle,
               Shape'Length,
               Indices (Indices'First)'Access,
               C.C_Int32 (Ordinal))
            = C.Success,
            "raw selected-view source fill must succeed");
      end loop;
      return Handle;
   end Create_Source;

   function Get
     (Handle : C.Mat_Handle; Index : C.C_Int32_Array) return C.C_Int32
   is
      Indices : aliased C.C_Int32_Array := Index;
      Value   : aliased C.C_Int32 := -1;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Get_Int32_ND
           (Handle, Index'Length, Indices (Indices'First)'Access, Value'Access)
         = C.Success,
         "raw N-D Int32 Get must succeed");
      return Value;
   end Get;

   procedure Set
     (Handle : C.Mat_Handle; Index : C.C_Int32_Array; Value : C.C_Int32)
   is
      Indices : aliased C.C_Int32_Array := Index;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Set_Int32_ND
           (Handle, Index'Length, Indices (Indices'First)'Access, Value)
         = C.Success,
         "raw N-D Int32 Set must succeed");
   end Set;

   function Dims (Handle : C.Mat_Handle) return C.C_Int32 is
      Value : aliased C.C_Int32 := -1;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Dimension_Count (Handle, Value'Access) = C.Success,
         "raw dimension count must succeed");
      return Value;
   end Dims;

   function Extent (Handle : C.Mat_Handle; Axis : C.C_Int32) return C.C_Int32
   is
      Value : aliased C.C_Int32 := -1;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Extent (Handle, Axis, Value'Access) = C.Success,
         "raw extent must succeed");
      return Value;
   end Extent;

   function Continuous (Handle : C.Mat_Handle) return Boolean is
      Value : aliased C.C_Boolean := C.C_False;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Is_Continuous (Handle, Value'Access) = C.Success,
         "raw continuity query must succeed");
      return Value = C.C_True;
   end Continuous;

   function Submatrix (Handle : C.Mat_Handle) return Boolean is
      Value : aliased C.C_Boolean := C.C_False;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Is_Submatrix (Handle, Value'Access) = C.Success,
         "raw submatrix query must succeed");
      return Value = C.C_True;
   end Submatrix;

   --  Canonical 4-D source (2, 3, 2, 4): every element still holds its
   --  packed ordinal.
   function Canonical_Intact (Handle : C.Mat_Handle) return Boolean is
   begin
      for I in C.C_Int32 range 0 .. 1 loop
         for J in C.C_Int32 range 0 .. 2 loop
            for L in C.C_Int32 range 0 .. 1 loop
               for K in C.C_Int32 range 0 .. 3 loop
                  if Get (Handle, (I, J, L, K))
                    /= ((I * 3 + J) * 2 + L) * 4 + K
                  then
                     return False;
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
      return True;
   end Canonical_Intact;

   procedure Expect_Rejected
     (Source : C.Mat_Handle;
      Ndims  : C.C_Int32;
      Flags  : access C.C_UInt8;
      Starts : access C.C_Int32;
      Stops  : access C.C_Int32;
      Reason : String)
   is
      Sentinel : aliased Interfaces.Unsigned_16 := 0;
      --  Non-null sentinel proves the shim initializes *out_mat to null.
      Result   : aliased C.Mat_Handle := C.Mat_Handle (Sentinel'Address);
      Status   : constant C.Status :=
        C.Mat_Select_ND_View
          (Source, Ndims, Flags, Starts, Stops, Result'Access);
   begin
      AUnit.Assertions.Assert
        (Status = C.Error_Invalid_Argument
         and then Result = C.Null_Mat_Handle
         and then Contains (Diagnostic, Reason),
         "selected N-D view C ABI must reject with a null output for '"
         & Reason
         & "'; diagnostic was '"
         & Diagnostic
         & "'");
   end Expect_Rejected;

   procedure Reject_With
     (Source     : C.Mat_Handle;
      New_Flags  : C.C_UInt8_Array;
      New_Starts : C.C_Int32_Array;
      New_Stops  : C.C_Int32_Array;
      Reason     : String)
   is
      F  : aliased C.C_UInt8_Array := New_Flags;
      S  : aliased C.C_Int32_Array := New_Starts;
      St : aliased C.C_Int32_Array := New_Stops;
   begin
      Expect_Rejected
        (Source,
         C.C_Int32 (F'Length),
         F (F'First)'Access,
         S (S'First)'Access,
         St (St'First)'Access,
         Reason);
   end Reject_With;

   procedure Check_Rejections is
      Source : constant C.Mat_Handle := Create_Source ((2, 3, 2, 4));
      Plane  : constant C.Mat_Handle := Create_Source ((3, 4));
      Empty  : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Flags  : aliased C.C_UInt8_Array := (1, 0, 1, 0);
      Starts : aliased C.C_Int32_Array := (1, 0, 1, 0);
      Stops  : aliased C.C_Int32_Array := (2, 3, 2, 4);
      Wide   : aliased C.C_UInt8_Array (0 .. 32) := (others => 0);
      Wide_I : aliased C.C_Int32_Array (0 .. 32) := (others => 0);
      Status : C.Status;
   begin
      Status :=
        C.Mat_Select_ND_View
          (Source,
           4,
           Flags (0)'Access,
           Starts (0)'Access,
           Stops (0)'Access,
           null);
      AUnit.Assertions.Assert
        (Status = C.Error_Invalid_Argument
         and then Contains (Diagnostic, "out_mat must not be null"),
         "a null out_mat must be rejected");

      Expect_Rejected
        (C.Null_Mat_Handle,
         4,
         Flags (0)'Access,
         Starts (0)'Access,
         Stops (0)'Access,
         "source Mat handle must not be null");
      Expect_Rejected
        (Source,
         -1,
         Flags (0)'Access,
         Starts (0)'Access,
         Stops (0)'Access,
         "dimension count must be in 0 .. 32");
      Expect_Rejected
        (Source,
         33,
         Wide (0)'Access,
         Wide_I (0)'Access,
         Wide_I (0)'Access,
         "dimension count must be in 0 .. 32");
      Expect_Rejected
        (Source,
         3,
         Flags (0)'Access,
         Starts (0)'Access,
         Stops (0)'Access,
         "selector count must equal source Mat dimension count");
      Expect_Rejected
        (Source,
         4,
         null,
         Starts (0)'Access,
         Stops (0)'Access,
         "selector arrays must not be null");
      Expect_Rejected
        (Source,
         4,
         Flags (0)'Access,
         null,
         Stops (0)'Access,
         "selector arrays must not be null");
      Expect_Rejected
        (Source,
         4,
         Flags (0)'Access,
         Starts (0)'Access,
         null,
         "selector arrays must not be null");

      --  Default empty source: zero dimensions and no storage.
      AUnit.Assertions.Assert
        (C.Mat_Create (Empty'Access) = C.Success,
         "the empty raw fixture must be created");
      Expect_Rejected
        (Empty,
         0,
         Flags (0)'Access,
         Starts (0)'Access,
         Stops (0)'Access,
         "must have allocated storage");
      C.Mat_Destroy (Empty);

      Reject_With
        (Source,
         (1, 0, 2, 0),
         (1, 0, 1, 0),
         (2, 3, 2, 4),
         "drop flags must be 0 or 1");
      Reject_With
        (Source,
         (1, 0, 1, 0),
         (-1, 0, 1, 0),
         (2, 3, 2, 4),
         "ranges must not be negative");
      Reject_With
        (Source,
         (1, 0, 1, 0),
         (1, 0, 1, 0),
         (2, -3, 2, 4),
         "ranges must not be negative");
      Reject_With
        (Source,
         (1, 0, 1, 0),
         (1, 2, 1, 0),
         (2, 2, 2, 4),
         "range start must be below its stop");
      Reject_With
        (Source,
         (1, 0, 1, 0),
         (1, 2, 1, 0),
         (2, 1, 2, 4),
         "range start must be below its stop");
      Reject_With
        (Source,
         (1, 0, 1, 0),
         (1, 0, 1, 0),
         (2, 3, 2, 5),
         "range stop is outside source bounds");
      Reject_With
        (Source,
         (1, 0, 1, 0),
         (2, 0, 1, 0),
         (3, 3, 2, 4),
         "range stop is outside source bounds");
      Reject_With
        (Source,
         (1, 0, 1, 0),
         (0, 0, 1, 0),
         (2, 3, 2, 4),
         "dropped dimension must select exactly one index");
      Reject_With
        (Source,
         (0, 0, 0, 0),
         (0, 0, 0, 0),
         (2, 3, 2, 4),
         "must drop at least one dimension");
      Reject_With
        (Source,
         (1, 1, 1, 0),
         (1, 1, 1, 0),
         (2, 2, 2, 4),
         "must retain at least two dimensions");
      Reject_With
        (Source,
         (1, 1, 1, 1),
         (1, 1, 1, 1),
         (2, 2, 2, 2),
         "must retain at least two dimensions");
      Reject_With
        (Source,
         (0, 0, 0, 1),
         (0, 0, 0, 3),
         (2, 3, 2, 4),
         "must retain the final source dimension");
      Reject_With
        (Source,
         (0, 1, 0, 1),
         (0, 1, 0, 3),
         (2, 2, 2, 4),
         "must retain the final source dimension");

      --  A 2-D source cannot drop a dimension and still keep two.
      Reject_With
        (Plane, (1, 0), (1, 0), (2, 4), "must retain at least two dimensions");

      --  A temporary external-buffer source is rejected by the established
      --  temporary-view helper.
      declare
         Data     : aliased UInt16_Array (0 .. 23) := (others => 7);
         Sizes    : aliased C.C_Int32_Array := (2, 3, 4);
         External : aliased C.Mat_Handle := C.Null_Mat_Handle;
      begin
         AUnit.Assertions.Assert
           (C.Mat_Create_External_ND
              (3,
               Sizes (0)'Access,
               C.Depth_UInt16,
               1,
               Data (0)'Address,
               48,
               External'Access)
            = C.Success,
            "the temporary external source fixture must be created");
         Reject_With
           (External,
            (1, 0, 0),
            (1, 0, 0),
            (2, 3, 4),
            "cannot create shallow aliases");
         C.Mat_Destroy (External);
         AUnit.Assertions.Assert
           ((for all Value of Data => Value = 7),
            "a rejected external selection must not touch caller storage");
      end;

      AUnit.Assertions.Assert
        (Canonical_Intact (Source),
         "rejected selections must leave source data unchanged");
      C.Mat_Destroy (Source);
      C.Mat_Destroy (Plane);
   end Check_Rejections;

   function Select_View
     (Source     : C.Mat_Handle;
      New_Flags  : C.C_UInt8_Array;
      New_Starts : C.C_Int32_Array;
      New_Stops  : C.C_Int32_Array) return C.Mat_Handle
   is
      F      : aliased C.C_UInt8_Array := New_Flags;
      S      : aliased C.C_Int32_Array := New_Starts;
      St     : aliased C.C_Int32_Array := New_Stops;
      Result : aliased C.Mat_Handle := C.Null_Mat_Handle;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Select_ND_View
           (Source,
            C.C_Int32 (F'Length),
            F (F'First)'Access,
            S (S'First)'Access,
            St (St'First)'Access,
            Result'Access)
         = C.Success
         and then Result /= C.Null_Mat_Handle,
         "a valid raw selection must succeed; diagnostic was '"
         & Diagnostic
         & "'");
      return Result;
   end Select_View;

   --  Byte distance from Base to Address (Address >= Base).
   function Distance (Base, Address : System.Address) return Natural is
   begin
      return Natural (System.Storage_Elements."-" (Address, Base));
   end Distance;

   function Row_Address
     (Handle : C.Mat_Handle; Row : C.C_Int32) return System.Address
   is
      Address : aliased System.Address := System.Null_Address;
      Bytes   : aliased C.C_UInt64 := 0;
   begin
      AUnit.Assertions.Assert
        (C.Mat_Borrow_Row_Data (Handle, Row, Address'Access, Bytes'Access)
         = C.Success,
         "raw row borrowing must succeed; diagnostic was '"
         & Diagnostic
         & "'");
      return Address;
   end Row_Address;

   procedure Check_Valid_Views is
      Plane_Source : constant C.Mat_Handle := Create_Source ((2, 3, 4));
      Source       : constant C.Mat_Handle := Create_Source ((2, 3, 2, 4));
      Volume       : constant C.Mat_Handle := Create_Source ((2, 3, 2, 4));
      View         : C.Mat_Handle;
   begin
      --  1. Leading drop -> continuous 3 x 4 plane at Source (1, *, *).
      View := Select_View (Plane_Source, (1, 0, 0), (1, 0, 0), (2, 3, 4));
      AUnit.Assertions.Assert
        (Dims (View) = 2
         and then Extent (View, 0) = 3
         and then Extent (View, 1) = 4
         and then Continuous (View),
         "a leading drop must produce a continuous 3 x 4 plane");
      AUnit.Assertions.Assert
        (Get (View, (0, 0)) = 12 and then Get (View, (2, 3)) = 23,
         "plane (J, K) must read Source (1, J, K)");
      Set (View, (1, 2), -5);
      AUnit.Assertions.Assert
        (Get (Plane_Source, (1, 1, 2)) = -5,
         "a plane write must reach the source");
      Set (Plane_Source, (1, 0, 3), -6);
      AUnit.Assertions.Assert
        (Get (View, (0, 3)) = -6, "a source write must reach the plane");
      C.Mat_Destroy (View);

      --  2. Middle drops: the carrier-construction case. The final logical
      --  element View (2, 3) = Source (1, 2, 1, 3) is the final element of
      --  the source allocation, and rows are eight elements apart.
      View := Select_View (Source, (1, 0, 1, 0), (1, 0, 1, 0), (2, 3, 2, 4));
      AUnit.Assertions.Assert
        (Dims (View) = 2
         and then Extent (View, 0) = 3
         and then Extent (View, 1) = 4
         and then not Continuous (View)
         and then Submatrix (View),
         "middle drops must produce a gapped 3 x 4 submatrix view");
      AUnit.Assertions.Assert
        (Get (View, (0, 0)) = 28 and then Get (View, (2, 3)) = 47,
         "gapped (J, K) must read Source (1, J, 1, K)");
      declare
         --  Source (0, 0, *, *) as a 2 x 4 plane locates the allocation
         --  base, because row borrowing requires a 2-D Mat.
         Origin : constant C.Mat_Handle :=
           Select_View (Source, (1, 1, 0, 0), (0, 0, 0, 0), (1, 1, 2, 4));
      begin
         AUnit.Assertions.Assert
           (Distance (Row_Address (View, 0), Row_Address (View, 1)) = 32
            and then Distance (Row_Address (Origin, 0), Row_Address (View, 0))
                     = 28 * 4
            and then Distance (Row_Address (Origin, 0), Row_Address (View, 2))
                     + 4 * 4
                     = 48 * 4,
            "the gapped view must start at element 28 with an 8-element"
            & " stride and end exactly at the 48-element allocation end");
         C.Mat_Destroy (Origin);
      end;
      Set (View, (2, 3), -47);
      AUnit.Assertions.Assert
        (Get (Source, (1, 2, 1, 3)) = -47,
         "a write to the final logical element must reach the source end");
      Set (Source, (1, 0, 1, 0), -28);
      AUnit.Assertions.Assert
        (Get (View, (0, 0)) = -28, "a source write must reach the view");
      C.Mat_Destroy (View);

      --  3. 4-D -> 3-D: drop axis 2 only, keeping partial ranges.
      View := Select_View (Volume, (0, 0, 1, 0), (1, 1, 0, 2), (2, 3, 1, 4));
      AUnit.Assertions.Assert
        (Dims (View) = 3
         and then Extent (View, 0) = 1
         and then Extent (View, 1) = 2
         and then Extent (View, 2) = 2
         and then not Continuous (View),
         "a single middle drop must produce a gapped 1 x 2 x 2 view");
      --  View (0, B, C) = Volume (1, 1 + B, 0, 2 + C).
      AUnit.Assertions.Assert
        (Get (View, (0, 0, 0)) = 34 and then Get (View, (0, 1, 1)) = 43,
         "3-D view (A, B, C) must read Volume (1 + A, 1 + B, 0, 2 + C)");
      Set (View, (0, 1, 0), -1);
      AUnit.Assertions.Assert
        (Get (Volume, (1, 2, 0, 2)) = -1,
         "a 3-D view write must reach the source");
      C.Mat_Destroy (View);

      C.Mat_Destroy (Plane_Source);
      C.Mat_Destroy (Source);
      C.Mat_Destroy (Volume);
   end Check_Valid_Views;

   procedure Check_Storage_Guard is
      Started : Boolean := False;
   begin
      Probe.Begin_Observation;
      Started := True;
      declare
         Source : constant C.Mat_Handle := Create_Source ((2, 3, 2, 4));
         View   : C.Mat_Handle;
         Lease  : aliased C.Mat_Handle := C.Null_Mat_Handle;
      begin
         AUnit.Assertions.Assert
           (Probe.Target_Captured and then Probe.Target_Size >= 192,
            "the raw source allocation must be the observed target");
         Probe.Restore_Default_Allocator;

         View :=
           Select_View (Source, (1, 0, 1, 0), (1, 0, 1, 0), (2, 3, 2, 4));
         C.Mat_Destroy (Source);
         AUnit.Assertions.Assert
           (Probe.Target_Live and then Probe.Deallocation_Count = 0,
            "the selected view must retain the destroyed source allocation");
         AUnit.Assertions.Assert
           (Get (View, (2, 3)) = 47, "the guarded view must stay readable");
         Set (View, (0, 0), -9);
         AUnit.Assertions.Assert
           (Get (View, (0, 0)) = -9, "the guarded view must stay writable");

         AUnit.Assertions.Assert
           (C.Mat_Acquire_Borrow_Lease (View, Lease'Access) = C.Success
            and then Lease /= C.Null_Mat_Handle,
            "a borrow lease must be acquired from the selected view");
         C.Mat_Destroy (View);
         AUnit.Assertions.Assert
           (Probe.Target_Live and then Probe.Deallocation_Count = 0,
            "the lease must retain the allocation after the view is gone");
         AUnit.Assertions.Assert
           (Get (Lease, (0, 0)) = -9 and then Get (Lease, (1, 2)) = 38,
            "the lease must still address the selected storage");
         Set (Lease, (2, 3), -47);
         AUnit.Assertions.Assert
           (Get (Lease, (2, 3)) = -47, "the lease must remain writable");

         C.Mat_Destroy (Lease);
         AUnit.Assertions.Assert
           (not Probe.Target_Live and then Probe.Deallocation_Count = 1,
            "the allocation must be released exactly once with the lease");
      end;
      Probe.Finish;
      Started := False;
   exception
      when Original : others =>
         if Started then
            begin
               Probe.Finish;
            exception
               when others =>
                  null;
            end;
         end if;
         Ada.Exceptions.Reraise_Occurrence (Original);
   end Check_Storage_Guard;

   procedure Check_Temporary_View is
      Source : constant C.Mat_Handle := Create_Source ((2, 3, 2, 4));
      View   : constant C.Mat_Handle :=
        Select_View (Source, (1, 0, 1, 0), (1, 0, 1, 0), (2, 3, 2, 4));
      Starts : aliased C.C_Int32_Array := (0, 0);
      Stops  : aliased C.C_Int32_Array := (1, 4);
      Flat   : aliased constant C.C_Int32_Array := (4, 3);
      Clone  : aliased C.Mat_Handle := C.Null_Mat_Handle;
      Result : aliased C.Mat_Handle;
      Native : aliased System.Address;
      Status : C.Status;

      procedure Expect_Alias_Rejected (Operation : String) is
      begin
         AUnit.Assertions.Assert
           (Status = C.Error_Invalid_Argument
            and then Result = C.Null_Mat_Handle
            and then Contains (Diagnostic, "temporary external-buffer"),
            "raw selected view " & Operation & " must be rejected");
      end Expect_Alias_Rejected;
   begin
      Result := View;
      Status := C.Mat_Copy (View, Result'Access);
      Expect_Alias_Rejected ("shallow copy");

      Result := View;
      Status :=
        C.Mat_Slice_ND
          (View, 2, Starts (0)'Access, Stops (0)'Access, Result'Access);
      Expect_Alias_Rejected ("Slice");

      Result := View;
      Status := C.Mat_Reshape_ND (View, 1, 2, Flat (0)'Access, Result'Access);
      Expect_Alias_Rejected ("Reshape");

      Result := View;
      Status := C.Mat_Row_View (View, 0, Result'Access);
      Expect_Alias_Rejected ("Row_View");

      Native := View'Address;
      Status := C.Mat_Resolve_Output (View, Native'Access);
      AUnit.Assertions.Assert
        (Status = C.Error_Invalid_Argument
         and then Native = System.Null_Address,
         "raw selected view output resolution must be rejected");

      AUnit.Assertions.Assert
        (C.Mat_Clone (View, Clone'Access) = C.Success
         and then Clone /= C.Null_Mat_Handle
         and then Continuous (Clone)
         and then Get (Clone, (2, 3)) = 47,
         "raw selected view Clone must be continuous and hold the values");
      C.Mat_Destroy (View);

      Set (Clone, (0, 0), -1);
      AUnit.Assertions.Assert
        (Get (Source, (1, 0, 1, 0)) = 28,
         "a Clone write must not reach the source");

      --  The owned Clone is not temporary: it may shallow-alias.
      Result := C.Null_Mat_Handle;
      AUnit.Assertions.Assert
        (C.Mat_Reshape_ND (Clone, 1, 2, Flat (0)'Access, Result'Access)
         = C.Success
         and then Result /= C.Null_Mat_Handle,
         "an owned Clone of a raw selected view must Reshape");
      C.Mat_Destroy (Result);
      C.Mat_Destroy (Clone);
      C.Mat_Destroy (Source);
   end Check_Temporary_View;

end ND_Selected_View_Tests.Raw_ABI;
