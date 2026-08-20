with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Unbounded;
with AUnit.Assertions;
with AUnit.Test_Caller;
with Interfaces;
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Persistence;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;
with Mat_Test_Support;

package body Persistence_Tests is

   use type Interfaces.IEEE_Float_32;
   use type Interfaces.Unsigned_8;
   use type OpenCV.Core.Channel_Count;
   use type OpenCV.Core.Depth_Type;
   use type OpenCV.Core.UInt8_Vec3.Vector;
   use Mat_Test_Support;

   package Persistence renames OpenCV.Core.Persistence;

   function Temporary_Directory return String is
   begin
      if Ada.Environment_Variables.Exists ("TMPDIR") then
         return Ada.Environment_Variables.Value ("TMPDIR");
      elsif Ada.Environment_Variables.Exists ("TMP") then
         return Ada.Environment_Variables.Value ("TMP");
      else
         return "/tmp";
      end if;
   end Temporary_Directory;

   function Test_Path (Leaf : String) return String
   is (Ada.Directories.Compose (Temporary_Directory, Leaf));

   procedure Delete_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   end Delete_If_Exists;

   procedure Prepare (Path : String) is
   begin
      Delete_If_Exists (Path);
   end Prepare;

   procedure Cleanup (Path : String) is
   begin
      Delete_If_Exists (Path);
   end Cleanup;

   function Make_Float32_Matrix return OpenCV.Core.Mat is
      Image : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 3,
           Element_Type => (Depth => OpenCV.Core.Float32, Channels => 1));
   begin
      OpenCV.Core.Float32_Access.Set (Image, 0, 0, 1.0);
      OpenCV.Core.Float32_Access.Set (Image, 0, 1, 2.5);
      OpenCV.Core.Float32_Access.Set (Image, 0, 2, -3.25);
      OpenCV.Core.Float32_Access.Set (Image, 1, 0, 4.0);
      OpenCV.Core.Float32_Access.Set (Image, 1, 1, 5.125);
      OpenCV.Core.Float32_Access.Set (Image, 1, 2, 6.75);
      return Image;
   end Make_Float32_Matrix;

   procedure Assert_Same_Float32_Matrix
     (Left, Right : OpenCV.Core.Mat; Message : String) is
   begin
      AUnit.Assertions.Assert
        (Left.Rows = Right.Rows
         and then Left.Columns = Right.Columns
         and then Left.Depth = Right.Depth
         and then Left.Channels = Right.Channels,
         Message & ": metadata");

      for Row in 0 .. Left.Rows - 1 loop
         for Column in 0 .. Left.Columns - 1 loop
            AUnit.Assertions.Assert
              (Approximately_Equal
                 (Long_Float
                    (OpenCV.Core.Float32_Access.Get (Left, Row, Column)),
                  Long_Float
                    (OpenCV.Core.Float32_Access.Get (Right, Row, Column))),
               Message & ": value at" & Row'Image & "," & Column'Image);
         end loop;
      end loop;
   end Assert_Same_Float32_Matrix;

   procedure Write_Named
     (Path : String; Name : String; Value : OpenCV.Core.Mat)
   is
      Storage : Persistence.File_Storage :=
        Persistence.Open (Path, Persistence.Write_Only);
   begin
      Storage.Write (Name, Value);
   end Write_Named;

   procedure YAML_Float32_Mat_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path     : constant String :=
        Test_Path ("opencvcore_ada_persistence_matrix.yml");
      Original : constant OpenCV.Core.Mat := Make_Float32_Matrix;
   begin
      Prepare (Path);
      begin
         Write_Named (Path, "Matrix", Original);

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
            Loaded  : constant OpenCV.Core.Mat := Storage.Read_Mat ("Matrix");
         begin
            Assert_Same_Float32_Matrix
              (Original, Loaded, "YAML Float32 C1 round trip");
         end;

         Assert_Same_Float32_Matrix
           (Original,
            Make_Float32_Matrix,
            "YAML write must not modify source");
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end YAML_Float32_Mat_Round_Trip;

   procedure XML_Mat_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path     : constant String :=
        Test_Path ("opencvcore_ada_persistence_matrix.xml");
      Original : constant OpenCV.Core.Mat := Make_Float32_Matrix;
   begin
      Prepare (Path);
      begin
         Write_Named (Path, "Matrix", Original);

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
            Loaded  : constant OpenCV.Core.Mat := Storage.Read_Mat ("Matrix");
         begin
            Assert_Same_Float32_Matrix
              (Original, Loaded, "XML Float32 C1 round trip");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end XML_Mat_Round_Trip;

   procedure JSON_Mat_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path     : constant String :=
        Test_Path ("opencvcore_ada_persistence_matrix.json");
      Original : constant OpenCV.Core.Mat := Make_Float32_Matrix;
   begin
      Prepare (Path);
      begin
         Write_Named (Path, "Matrix", Original);

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
            Loaded  : constant OpenCV.Core.Mat := Storage.Read_Mat ("Matrix");
         begin
            Assert_Same_Float32_Matrix
              (Original, Loaded, "JSON Float32 C1 round trip");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end JSON_Mat_Round_Trip;

   procedure Multiple_Named_Mats_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_multiple.yml");
      A    : constant OpenCV.Core.Mat := Make_Float32_Matrix;
      B    : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 1,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
   begin
      Prepare (Path);
      OpenCV.Core.UInt8_Vec3_Access.Set (B, 0, 0, (10, 20, 30));
      OpenCV.Core.UInt8_Vec3_Access.Set (B, 0, 1, (40, 50, 60));

      begin
         declare
            Writer : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);
         begin
            Writer.Write ("A", A);
            Writer.Write ("B", B);
         end;

         declare
            Reader   : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
            Loaded_A : constant OpenCV.Core.Mat := Reader.Read_Mat ("A");
            Loaded_B : constant OpenCV.Core.Mat := Reader.Read_Mat ("B");
         begin
            Assert_Same_Float32_Matrix
              (A, Loaded_A, "named Mat A must be selected independently");
            AUnit.Assertions.Assert
              (Loaded_B.Rows = 1
               and then Loaded_B.Columns = 2
               and then Loaded_B.Depth = OpenCV.Core.UInt8
               and then Loaded_B.Channels = 3,
               "named Mat B must preserve UInt8 C3 metadata");
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Vec3_Access.Get (Loaded_B, 0, 0)
               = (10, 20, 30)
               and then OpenCV.Core.UInt8_Vec3_Access.Get (Loaded_B, 0, 1)
                        = (40, 50, 60),
               "named Mat B must preserve its independent values");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Multiple_Named_Mats_Round_Trip;

   procedure UInt8_C3_Type_Is_Preserved (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path     : constant String :=
        Test_Path ("opencvcore_ada_persistence_uint8_c3.yml");
      Original : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 2,
           Columns      => 2,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 3));
   begin
      Prepare (Path);
      OpenCV.Core.UInt8_Vec3_Access.Set (Original, 0, 0, (1, 2, 3));
      OpenCV.Core.UInt8_Vec3_Access.Set (Original, 0, 1, (4, 5, 6));
      OpenCV.Core.UInt8_Vec3_Access.Set (Original, 1, 0, (7, 8, 9));
      OpenCV.Core.UInt8_Vec3_Access.Set (Original, 1, 1, (10, 11, 12));

      begin
         Write_Named (Path, "Colors", Original);

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
            Loaded  : constant OpenCV.Core.Mat := Storage.Read_Mat ("Colors");
         begin
            AUnit.Assertions.Assert
              (Loaded.Rows = 2
               and then Loaded.Columns = 2
               and then Loaded.Depth = OpenCV.Core.UInt8
               and then Loaded.Channels = 3,
               "UInt8 C3 persistence must preserve depth and channels");
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Vec3_Access.Get (Loaded, 0, 0) = (1, 2, 3)
               and then OpenCV.Core.UInt8_Vec3_Access.Get (Loaded, 1, 1)
                        = (10, 11, 12),
               "UInt8 C3 persistence must preserve values");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end UInt8_C3_Type_Is_Preserved;

   procedure Non_Contiguous_Region_Is_Written (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Path   : constant String :=
        Test_Path ("opencvcore_ada_persistence_region.yml");
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Region : OpenCV.Core.Mat;
   begin
      Prepare (Path);

      for Row in 0 .. 3 loop
         for Column in 0 .. 4 loop
            OpenCV.Core.UInt8_Access.Set
              (Parent, Row, Column, Interfaces.Unsigned_8 (Row * 10 + Column));
         end loop;
      end loop;

      Region := Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      AUnit.Assertions.Assert
        (not Region.Is_Continuous, "Region fixture must be non-contiguous");

      begin
         Write_Named (Path, "Region", Region);

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
            Loaded  : constant OpenCV.Core.Mat := Storage.Read_Mat ("Region");
         begin
            AUnit.Assertions.Assert
              (Loaded.Rows = 2 and then Loaded.Columns = 3,
               "persisted Region must keep its logical dimensions");
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Access.Get (Loaded, 0, 0) = 11
               and then OpenCV.Core.UInt8_Access.Get (Loaded, 0, 1) = 12
               and then OpenCV.Core.UInt8_Access.Get (Loaded, 0, 2) = 13
               and then OpenCV.Core.UInt8_Access.Get (Loaded, 1, 0) = 21
               and then OpenCV.Core.UInt8_Access.Get (Loaded, 1, 1) = 22
               and then OpenCV.Core.UInt8_Access.Get (Loaded, 1, 2) = 23,
               "persisted Region must contain only the ROI values");
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Access.Get (Parent, 0, 0) = 0
               and then OpenCV.Core.UInt8_Access.Get (Parent, 3, 4) = 34
               and then OpenCV.Core.UInt8_Access.Get (Region, 0, 0) = 11,
               "Region write must leave the parent and Region unchanged");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Non_Contiguous_Region_Is_Written;

   procedure Missing_Name_Raises_Without_Poisoning_Storage
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_missing.yml");
   begin
      Prepare (Path);
      begin
         Write_Named (Path, "Existing", Make_Float32_Matrix);

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);

            procedure Read_Missing is
               Unused : constant OpenCV.Core.Mat :=
                 Storage.Read_Mat ("Missing");
               pragma Unreferenced (Unused);
            begin
               null;
            end Read_Missing;
         begin
            Assert_Raises_OpenCV_Error
              (Read_Missing'Access, "a missing name must raise OpenCV_Error");

            declare
               Existing : constant OpenCV.Core.Mat :=
                 Storage.Read_Mat ("Existing");
            begin
               AUnit.Assertions.Assert
                 (Existing.Rows = 2 and then Existing.Columns = 3,
                  "a missing-name failure must not poison File_Storage");
            end;
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Missing_Name_Raises_Without_Poisoning_Storage;

   procedure Empty_Mat_Round_Trip_Is_Present (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Path  : constant String :=
        Test_Path ("opencvcore_ada_persistence_empty.yml");
      Empty : OpenCV.Core.Mat;
   begin
      Prepare (Path);
      begin
         Write_Named (Path, "Empty", Empty);

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
            Loaded  : constant OpenCV.Core.Mat := Storage.Read_Mat ("Empty");

            procedure Read_Missing is
               Unused : constant OpenCV.Core.Mat :=
                 Storage.Read_Mat ("Missing");
               pragma Unreferenced (Unused);
            begin
               null;
            end Read_Missing;
         begin
            AUnit.Assertions.Assert
              (Loaded.Is_Empty,
               "a serialized empty Mat must read back as empty");
            Assert_Raises_OpenCV_Error
              (Read_Missing'Access,
               "an empty Mat node must remain distinct from a missing name");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Empty_Mat_Round_Trip_Is_Present;

   procedure Read_Mat_Outlives_Storage (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path   : constant String :=
        Test_Path ("opencvcore_ada_persistence_lifetime.yml");
      Source : constant OpenCV.Core.Mat := Make_Float32_Matrix;
      Loaded : OpenCV.Core.Mat;
   begin
      Prepare (Path);
      begin
         Write_Named (Path, "Matrix", Source);

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
         begin
            Loaded := Storage.Read_Mat ("Matrix");
         end;

         Assert_Same_Float32_Matrix
           (Source, Loaded, "Read_Mat must remain valid after finalization");
         OpenCV.Core.Float32_Access.Set (Loaded, 0, 0, 99.0);
         AUnit.Assertions.Assert
           (Approximately_Equal
              (Long_Float (OpenCV.Core.Float32_Access.Get (Loaded, 0, 0)),
               99.0),
            "a Mat read from storage must remain independently mutable");
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Read_Mat_Outlives_Storage;

   procedure Mode_Misuse_Is_Rejected (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_mode.yml");
   begin
      Prepare (Path);
      begin
         declare
            Writer : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);

            procedure Read_From_Writer is
               Unused : constant OpenCV.Core.Mat := Writer.Read_Mat ("Matrix");
               pragma Unreferenced (Unused);
            begin
               null;
            end Read_From_Writer;
         begin
            Writer.Write ("Matrix", Make_Float32_Matrix);
            Assert_Raises_OpenCV_Error
              (Read_From_Writer'Access,
               "Read_Mat must reject Write_Only storage");

            declare
               procedure Read_Integer_From_Writer is
                  Unused : constant Integer := Writer.Read_Integer ("Count");
                  pragma Unreferenced (Unused);
               begin
                  null;
               end Read_Integer_From_Writer;
            begin
               Assert_Raises_OpenCV_Error
                 (Read_Integer_From_Writer'Access,
                  "Read_Integer must reject Write_Only storage");
            end;
         end;

         declare
            Reader : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);

            procedure Write_On_Reader is
               Value : constant OpenCV.Core.Mat := Make_Float32_Matrix;
            begin
               Reader.Write ("Matrix", Value);
            end Write_On_Reader;

            procedure Write_Integer_On_Reader is
            begin
               Reader.Write ("Count", 1);
            end Write_Integer_On_Reader;
         begin
            Assert_Raises_OpenCV_Error
              (Write_On_Reader'Access, "Write must reject Read_Only storage");
            Assert_Raises_OpenCV_Error
              (Write_Integer_On_Reader'Access,
               "Write(Integer) must reject Read_Only storage");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Mode_Misuse_Is_Rejected;

   procedure Open_Failure_Raises (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);

      procedure Open_Missing is
         Unused : Persistence.File_Storage :=
           Persistence.Open
             (Test_Path ("opencvcore_ada_persistence_does_not_exist.yml"),
              Persistence.Read_Only);
         pragma Unreferenced (Unused);
      begin
         null;
      end Open_Missing;
   begin
      Delete_If_Exists
        (Test_Path ("opencvcore_ada_persistence_does_not_exist.yml"));
      Assert_Raises_OpenCV_Error
        (Open_Missing'Access,
         "opening a nonexistent Read_Only file must raise OpenCV_Error");
   end Open_Failure_Raises;

   procedure Invalid_Names_And_Filenames_Are_Rejected
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_invalid.yml");

      procedure Open_Empty_Filename is
         Unused : Persistence.File_Storage :=
           Persistence.Open ("", Persistence.Write_Only);
         pragma Unreferenced (Unused);
      begin
         null;
      end Open_Empty_Filename;

      procedure Open_Embedded_NUL is
         Unused : Persistence.File_Storage :=
           Persistence.Open
             ("bad" & Character'Val (0) & ".yml", Persistence.Write_Only);
         pragma Unreferenced (Unused);
      begin
         null;
      end Open_Embedded_NUL;
   begin
      Prepare (Path);
      begin
         Assert_Raises_OpenCV_Error
           (Open_Empty_Filename'Access, "empty filename must be rejected");
         Assert_Raises_OpenCV_Error
           (Open_Embedded_NUL'Access,
            "an embedded NUL in a filename must be rejected");

         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);

            procedure Write_Empty_Name is
            begin
               Storage.Write ("", Make_Float32_Matrix);
            end Write_Empty_Name;

            procedure Write_Embedded_NUL is
            begin
               Storage.Write
                 ("Na" & Character'Val (0) & "me", Make_Float32_Matrix);
            end Write_Embedded_NUL;
         begin
            Assert_Raises_OpenCV_Error
              (Write_Empty_Name'Access, "empty node name must be rejected");
            Assert_Raises_OpenCV_Error
              (Write_Embedded_NUL'Access,
               "an embedded NUL in a node name must be rejected");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Invalid_Names_And_Filenames_Are_Rejected;

   procedure Integer_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_integers.yml");
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);
         begin
            Storage.Write ("Positive", 123_456);
            Storage.Write ("Negative", -123_456);
            Storage.Write ("Zero", 0);
            Storage.Write ("Max_Int32", 2_147_483_647);
            Storage.Write ("Min_Safe", -2_147_483_647);
         end;

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
         begin
            AUnit.Assertions.Assert
              (Storage.Read_Integer ("Positive") = 123_456,
               "positive integer must round trip exactly");
            AUnit.Assertions.Assert
              (Storage.Read_Integer ("Negative") = -123_456,
               "negative integer must round trip exactly");
            AUnit.Assertions.Assert
              (Storage.Read_Integer ("Zero") = 0,
               "integer zero must round trip exactly");
            AUnit.Assertions.Assert
              (Storage.Read_Integer ("Max_Int32") = 2_147_483_647,
               "signed 32-bit maximum must round trip exactly");
            AUnit.Assertions.Assert
              (Storage.Read_Integer ("Min_Safe") = -2_147_483_647,
               "OpenCV 4.10 integer write minimum must round trip exactly");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Integer_Round_Trip;

   procedure Integer_Min_Is_Rejected (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_int_min.yml");
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);

            procedure Write_Int_Min is
            begin
               Storage.Write ("Min_Int32", -2_147_483_648);
            end Write_Int_Min;
         begin
            Assert_Raises_OpenCV_Error
              (Write_Int_Min'Access,
               "Write(Integer) must reject -2147483648 with OpenCV 4.10");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Integer_Min_Is_Rejected;

   procedure Real_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_reals.yml");
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);
         begin
            Storage.Write ("Zero", 0.0);
            Storage.Write ("Negative", -2.5);
            Storage.Write ("Precise", 1.234_567_890_123_45);
         end;

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
         begin
            AUnit.Assertions.Assert
              (Approximately_Equal (Storage.Read_Real ("Zero"), 0.0, 1.0E-15),
               "real zero must round trip");
            AUnit.Assertions.Assert
              (Approximately_Equal
                 (Storage.Read_Real ("Negative"), -2.5, 1.0E-15),
               "negative real must round trip");
            AUnit.Assertions.Assert
              (Approximately_Equal
                 (Storage.Read_Real ("Precise"),
                  1.234_567_890_123_45,
                  1.0E-15),
               "Float64 real must round trip at binary64 precision");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Real_Round_Trip;

   procedure Integer_Widens_To_Real (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_int_to_real.yml");
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);
         begin
            Storage.Write ("Count", 123_456_789);
         end;

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
         begin
            AUnit.Assertions.Assert
              (Approximately_Equal
                 (Storage.Read_Real ("Count"), 123_456_789.0, 0.0),
               "Read_Real must widen an integer node exactly");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Integer_Widens_To_Real;

   procedure String_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path     : constant String :=
        Test_Path ("opencvcore_ada_persistence_strings.yml");
      Ordinary : constant String := "Front Camera";
      Empty    : constant String := "";
      Spaced   : constant String := "  leading and trailing  ";
      Escaped  : constant String := "quote "" and backslash \ path";
      Broken   : constant String := "line one" & ASCII.LF & "line two";
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);
         begin
            Storage.Write ("Ordinary", Ordinary);
            Storage.Write ("Empty", Empty);
            Storage.Write ("Spaced", Spaced);
            Storage.Write ("Escaped", Escaped);
            Storage.Write ("Broken", Broken);
         end;

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
         begin
            AUnit.Assertions.Assert
              (Storage.Read_String ("Ordinary") = Ordinary,
               "ordinary text must round trip exactly");
            AUnit.Assertions.Assert
              (Storage.Read_String ("Empty") = Empty,
               "empty string must round trip as a present empty value");
            AUnit.Assertions.Assert
              (Storage.Read_String ("Spaced") = Spaced,
               "spaces must be preserved");
            AUnit.Assertions.Assert
              (Storage.Read_String ("Escaped") = Escaped,
               "quotes and backslashes must round trip exactly");
            AUnit.Assertions.Assert
              (Storage.Read_String ("Broken") = Broken,
               "a YAML line break in a string must round trip exactly");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end String_Round_Trip;

   procedure Mixed_Named_Values_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path   : constant String :=
        Test_Path ("opencvcore_ada_persistence_mixed.yml");
      Matrix : constant OpenCV.Core.Mat := Make_Float32_Matrix;
      Camera : constant String := "Front Camera";
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);
         begin
            Storage.Write ("Iterations", 100);
            Storage.Write ("Threshold", 0.001);
            Storage.Write ("Camera_Name", Camera);
            Storage.Write ("Camera_Matrix", Matrix);
         end;

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
         begin
            AUnit.Assertions.Assert
              (Storage.Read_Integer ("Iterations") = 100,
               "mixed file integer must round trip");
            AUnit.Assertions.Assert
              (Approximately_Equal
                 (Storage.Read_Real ("Threshold"), 0.001, 1.0E-15),
               "mixed file real must round trip");
            AUnit.Assertions.Assert
              (Storage.Read_String ("Camera_Name") = Camera,
               "mixed file string must round trip");
            Assert_Same_Float32_Matrix
              (Matrix,
               Storage.Read_Mat ("Camera_Matrix"),
               "mixed file Mat must round trip");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Mixed_Named_Values_Round_Trip;

   procedure JSON_Scalar_And_String_Round_Trip (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Path    : constant String :=
        Test_Path ("opencvcore_ada_persistence_scalars.json");
      Escaped : constant String := "quote "" and backslash \ path";
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);
         begin
            Storage.Write ("Threshold", 1.234_567_890_123_45);
            Storage.Write ("Label", Escaped);
         end;

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
         begin
            AUnit.Assertions.Assert
              (Approximately_Equal
                 (Storage.Read_Real ("Threshold"),
                  1.234_567_890_123_45,
                  1.0E-15),
               "JSON real must round trip at binary64 precision");
            AUnit.Assertions.Assert
              (Storage.Read_String ("Label") = Escaped,
               "JSON escaped string must round trip exactly");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end JSON_Scalar_And_String_Round_Trip;

   procedure Wrong_Node_Types_Are_Rejected (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_wrong_types.yml");
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);
         begin
            Storage.Write ("Int_Value", 7);
            Storage.Write ("Real_Value", 1.5);
            Storage.Write ("Text_Value", "seven");
            Storage.Write ("Mat_Value", Make_Float32_Matrix);
         end;

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);

            procedure Read_Integer_From_Real is
               Unused : constant Integer :=
                 Storage.Read_Integer ("Real_Value");
               pragma Unreferenced (Unused);
            begin
               null;
            end Read_Integer_From_Real;

            procedure Read_Integer_From_Text is
               Unused : constant Integer :=
                 Storage.Read_Integer ("Text_Value");
               pragma Unreferenced (Unused);
            begin
               null;
            end Read_Integer_From_Text;

            procedure Read_Real_From_Text is
               Unused : constant Long_Float :=
                 Storage.Read_Real ("Text_Value");
               pragma Unreferenced (Unused);
            begin
               null;
            end Read_Real_From_Text;

            procedure Read_String_From_Int is
               Unused : constant String := Storage.Read_String ("Int_Value");
               pragma Unreferenced (Unused);
            begin
               null;
            end Read_String_From_Int;
         begin
            Assert_Raises_OpenCV_Error
              (Read_Integer_From_Real'Access,
               "Read_Integer must reject a real node");
            Assert_Raises_OpenCV_Error
              (Read_Integer_From_Text'Access,
               "Read_Integer must reject a string node");
            Assert_Raises_OpenCV_Error
              (Read_Real_From_Text'Access,
               "Read_Real must reject a string node");
            Assert_Raises_OpenCV_Error
              (Read_String_From_Int'Access,
               "Read_String must reject an integer node");
            AUnit.Assertions.Assert
              (Approximately_Equal (Storage.Read_Real ("Int_Value"), 7.0, 0.0),
               "Read_Real must accept an integer node");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Wrong_Node_Types_Are_Rejected;

   procedure Missing_Versus_Stored_Zero_And_Empty
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_zero_empty.yml");
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);
         begin
            Storage.Write ("Zero_Int", 0);
            Storage.Write ("Zero_Real", 0.0);
            Storage.Write ("Empty_Text", "");
         end;

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);

            procedure Read_Missing_Integer is
               Unused : constant Integer := Storage.Read_Integer ("Missing");
               pragma Unreferenced (Unused);
            begin
               null;
            end Read_Missing_Integer;

            procedure Read_Missing_Real is
               Unused : constant Long_Float := Storage.Read_Real ("Missing");
               pragma Unreferenced (Unused);
            begin
               null;
            end Read_Missing_Real;

            procedure Read_Missing_String is
               Unused : constant String := Storage.Read_String ("Missing");
               pragma Unreferenced (Unused);
            begin
               null;
            end Read_Missing_String;
         begin
            AUnit.Assertions.Assert
              (Storage.Read_Integer ("Zero_Int") = 0,
               "stored integer zero must remain a present value");
            AUnit.Assertions.Assert
              (Approximately_Equal (Storage.Read_Real ("Zero_Real"), 0.0, 0.0),
               "stored real 0.0 must remain a present value");
            AUnit.Assertions.Assert
              (Storage.Read_String ("Empty_Text") = "",
               "stored empty string must remain a present value");
            Assert_Raises_OpenCV_Error
              (Read_Missing_Integer'Access,
               "a missing integer name must raise OpenCV_Error");
            Assert_Raises_OpenCV_Error
              (Read_Missing_Real'Access,
               "a missing real name must raise OpenCV_Error");
            Assert_Raises_OpenCV_Error
              (Read_Missing_String'Access,
               "a missing string name must raise OpenCV_Error");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Missing_Versus_Stored_Zero_And_Empty;

   procedure Embedded_NUL_String_Is_Rejected (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_nul.yml");
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);

            procedure Write_Embedded_NUL is
            begin
               Storage.Write ("Broken", "A" & Character'Val (0) & "B");
            end Write_Embedded_NUL;
         begin
            Assert_Raises_OpenCV_Error
              (Write_Embedded_NUL'Access,
               "Write(String) must reject an embedded NUL");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Embedded_NUL_String_Is_Rejected;

   procedure YAML_Memory_Mixed_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Matrix : constant OpenCV.Core.Mat := Make_Float32_Matrix;
      Camera : constant String := "Camera";
   begin
      declare
         Storage : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.YAML);
      begin
         Storage.Write ("Count", 12);
         Storage.Write ("Threshold", 0.25);
         Storage.Write ("Name", Camera);
         Storage.Write ("Matrix", Matrix);

         declare
            Serialized : constant String := Storage.Close_And_Get_Text;
         begin
            AUnit.Assertions.Assert
              (Serialized'Length > 0,
               "YAML memory serialization must produce text");

            declare
               Reader : constant Persistence.File_Storage :=
                 Persistence.Open_Memory (Serialized);
            begin
               AUnit.Assertions.Assert
                 (Reader.Read_Integer ("Count") = 12,
                  "YAML memory integer must round trip");
               AUnit.Assertions.Assert
                 (Approximately_Equal
                    (Reader.Read_Real ("Threshold"), 0.25, 1.0E-15),
                  "YAML memory real must round trip");
               AUnit.Assertions.Assert
                 (Reader.Read_String ("Name") = Camera,
                  "YAML memory string must round trip");
               Assert_Same_Float32_Matrix
                 (Matrix,
                  Reader.Read_Mat ("Matrix"),
                  "YAML memory Mat must round trip");
            end;
         end;
      end;
   end YAML_Memory_Mixed_Round_Trip;

   procedure XML_Memory_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Matrix : constant OpenCV.Core.Mat := Make_Float32_Matrix;
   begin
      declare
         Storage : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.XML);
      begin
         Storage.Write ("Count", 7);
         Storage.Write ("Matrix", Matrix);

         declare
            Serialized : constant String := Storage.Close_And_Get_Text;
         begin
            AUnit.Assertions.Assert
              (Serialized'Length > 0,
               "XML memory serialization must produce text");

            declare
               Reader : constant Persistence.File_Storage :=
                 Persistence.Open_Memory (Serialized);
            begin
               AUnit.Assertions.Assert
                 (Reader.Read_Integer ("Count") = 7,
                  "XML memory integer must round trip");
               Assert_Same_Float32_Matrix
                 (Matrix,
                  Reader.Read_Mat ("Matrix"),
                  "XML memory Mat must round trip");
            end;
         end;
      end;
   end XML_Memory_Round_Trip;

   procedure JSON_Memory_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Escaped : constant String := "quote "" and backslash \ path";
   begin
      declare
         Storage : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.JSON);
      begin
         Storage.Write ("Threshold", 1.234_567_890_123_45);
         Storage.Write ("Label", Escaped);

         declare
            Serialized : constant String := Storage.Close_And_Get_Text;
         begin
            AUnit.Assertions.Assert
              (Serialized'Length > 0,
               "JSON memory serialization must produce text");

            declare
               Reader : constant Persistence.File_Storage :=
                 Persistence.Open_Memory (Serialized);
            begin
               AUnit.Assertions.Assert
                 (Approximately_Equal
                    (Reader.Read_Real ("Threshold"),
                     1.234_567_890_123_45,
                     1.0E-15),
                  "JSON memory real must round trip");
               AUnit.Assertions.Assert
                 (Reader.Read_String ("Label") = Escaped,
                  "JSON memory escaped string must round trip exactly");
            end;
         end;
      end;
   end JSON_Memory_Round_Trip;

   procedure Storage_Closes_After_Text_Extraction
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Storage : Persistence.File_Storage :=
        Persistence.Create_Memory (Persistence.YAML);

      procedure Write_After_Close is
      begin
         Storage.Write ("Again", 2);
      end Write_After_Close;

      procedure Close_Again is
         Unused : constant String := Storage.Close_And_Get_Text;
         pragma Unreferenced (Unused);
      begin
         null;
      end Close_Again;
   begin
      Storage.Write ("Count", 1);

      declare
         Text : constant String := Storage.Close_And_Get_Text;
         pragma Unreferenced (Text);
      begin
         Assert_Raises_OpenCV_Error
           (Write_After_Close'Access,
            "Write must reject File_Storage after Close_And_Get_Text");
         Assert_Raises_OpenCV_Error
           (Close_Again'Access,
            "a second Close_And_Get_Text must raise OpenCV_Error");
      end;
   end Storage_Closes_After_Text_Extraction;

   procedure Disk_Storage_Cannot_Get_Memory_Text
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_disk_text.yml");
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);

            procedure Get_Text is
               Unused : constant String := Storage.Close_And_Get_Text;
               pragma Unreferenced (Unused);
            begin
               null;
            end Get_Text;
         begin
            Storage.Write ("Count", 1);
            Assert_Raises_OpenCV_Error
              (Get_Text'Access,
               "Close_And_Get_Text must reject disk File_Storage");
            Storage.Write ("Extra", 2);
         end;

         declare
            Storage : constant Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
         begin
            AUnit.Assertions.Assert
              (Storage.Read_Integer ("Count") = 1,
               "disk write must remain usable after rejected memory text");
            AUnit.Assertions.Assert
              (Storage.Read_Integer ("Extra") = 2,
               "disk write after rejected Close_And_Get_Text must persist");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Disk_Storage_Cannot_Get_Memory_Text;

   procedure Memory_Reader_Cannot_Get_Output_Text
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
   begin
      declare
         Writer : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.YAML);
      begin
         Writer.Write ("Count", 3);

         declare
            Serialized : constant String := Writer.Close_And_Get_Text;
            Storage    : Persistence.File_Storage :=
              Persistence.Open_Memory (Serialized);

            procedure Get_Text is
               Unused : constant String := Storage.Close_And_Get_Text;
               pragma Unreferenced (Unused);
            begin
               null;
            end Get_Text;
         begin
            AUnit.Assertions.Assert
              (Storage.Read_Integer ("Count") = 3,
               "memory reader fixture must contain the stored integer");
            Assert_Raises_OpenCV_Error
              (Get_Text'Access,
               "Close_And_Get_Text must reject memory Read_Only storage");
         end;
      end;
   end Memory_Reader_Cannot_Get_Output_Text;

   procedure Invalid_Memory_Input_Is_Rejected (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);

      procedure Open_Empty is
         Unused : Persistence.File_Storage := Persistence.Open_Memory ("");
         pragma Unreferenced (Unused);
      begin
         null;
      end Open_Empty;

      procedure Open_Malformed is
         Unused : Persistence.File_Storage :=
           Persistence.Open_Memory ("this is not yaml, xml, or json");
         pragma Unreferenced (Unused);
      begin
         null;
      end Open_Malformed;

      procedure Open_Embedded_NUL is
         Unused : Persistence.File_Storage :=
           Persistence.Open_Memory
             ("%YAML:1.0" & Character'Val (0) & "Count: 1");
         pragma Unreferenced (Unused);
      begin
         null;
      end Open_Embedded_NUL;
   begin
      Assert_Raises_OpenCV_Error
        (Open_Empty'Access, "Open_Memory must reject empty text");
      Assert_Raises_OpenCV_Error
        (Open_Malformed'Access,
         "Open_Memory must reject malformed nonempty text");
      Assert_Raises_OpenCV_Error
        (Open_Embedded_NUL'Access, "Open_Memory must reject an embedded NUL");
   end Invalid_Memory_Input_Is_Rejected;

   function Serialized_Count_Document return String is
      Storage : Persistence.File_Storage :=
        Persistence.Create_Memory (Persistence.YAML);
   begin
      Storage.Write ("Count", 42);
      return Storage.Close_And_Get_Text;
   end Serialized_Count_Document;

   procedure Temporary_Input_Buffer_Outlives_Open
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Storage : constant Persistence.File_Storage :=
        Persistence.Open_Memory (Serialized_Count_Document);
   begin
      AUnit.Assertions.Assert
        (Storage.Read_Integer ("Count") = 42,
         "Open_Memory must not depend on a temporary Ada C-string buffer");
   end Temporary_Input_Buffer_Outlives_Open;

   procedure Returned_Text_Outlives_Storage (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Held : Ada.Strings.Unbounded.Unbounded_String;
   begin
      declare
         Storage : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.JSON);
      begin
         Storage.Write ("Name", "Independent");
         Ada.Strings.Unbounded.Set_Unbounded_String
           (Held, Storage.Close_And_Get_Text);
      end;

      declare
         Storage : constant Persistence.File_Storage :=
           Persistence.Open_Memory (Ada.Strings.Unbounded.To_String (Held));
      begin
         AUnit.Assertions.Assert
           (Storage.Read_String ("Name") = "Independent",
            "Close_And_Get_Text must return an independent Ada String");
      end;
   end Returned_Text_Outlives_Storage;

   procedure Memory_Integer_Min_Is_Rejected (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Storage : Persistence.File_Storage :=
        Persistence.Create_Memory (Persistence.YAML);

      procedure Write_Int_Min is
      begin
         Storage.Write ("Min_Int32", -2_147_483_648);
      end Write_Int_Min;
   begin
      Assert_Raises_OpenCV_Error
        (Write_Int_Min'Access,
         "memory Write(Integer) must reject -2147483648 with OpenCV 4.10");
   end Memory_Integer_Min_Is_Rejected;
   procedure Nested_Map_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Matrix : constant OpenCV.Core.Mat := Make_Float32_Matrix;
   begin
      declare
         Storage : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.YAML);
      begin
         Storage.Write ("Version", 1);
         Storage.Begin_Map ("Camera");
         Storage.Write ("Name", "Front");
         Storage.Write ("RMS", 0.18);
         Storage.Write ("Matrix", Matrix);
         Storage.Begin_Map ("Settings");
         Storage.Write ("Count", 4);
         Storage.Write ("Threshold", 0.25);
         Storage.End_Structure;
         Storage.End_Structure;

         declare
            Serialized : constant String := Storage.Close_And_Get_Text;
            Reader     : Persistence.File_Storage :=
              Persistence.Open_Memory (Serialized);
         begin
            Reader.Enter_Map ("Camera");
            AUnit.Assertions.Assert
              (Reader.Read_String ("Name") = "Front",
               "nested map string must round trip");
            AUnit.Assertions.Assert
              (Approximately_Equal (Reader.Read_Real ("RMS"), 0.18, 1.0E-15),
               "nested map real must round trip");
            Assert_Same_Float32_Matrix
              (Matrix,
               Reader.Read_Mat ("Matrix"),
               "nested map Mat must round trip");

            Reader.Enter_Map ("Settings");
            AUnit.Assertions.Assert
              (Reader.Read_Integer ("Count") = 4,
               "inner nested map integer must round trip");
            AUnit.Assertions.Assert
              (Approximately_Equal
                 (Reader.Read_Real ("Threshold"), 0.25, 1.0E-15),
               "inner nested map real must round trip");
            Reader.Leave_Structure;
            Reader.Leave_Structure;

            AUnit.Assertions.Assert
              (Reader.Read_Integer ("Version") = 1,
               "top-level value must remain readable after unwind");
         end;
      end;
   end Nested_Map_Round_Trip;

   procedure Scalar_Sequence_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
   begin
      declare
         Storage : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.YAML);
      begin
         Storage.Begin_Sequence ("Values");
         Storage.Append (7);
         Storage.Append (-3);
         Storage.Append (42);
         Storage.End_Structure;

         declare
            Serialized : constant String := Storage.Close_And_Get_Text;
            Reader     : Persistence.File_Storage :=
              Persistence.Open_Memory (Serialized);
         begin
            Reader.Enter_Sequence ("Values");
            AUnit.Assertions.Assert
              (Reader.Sequence_Length = 3, "scalar sequence length must be 3");
            AUnit.Assertions.Assert
              (Reader.Read_Integer (0) = 7, "sequence integer 0 must match");
            AUnit.Assertions.Assert
              (Reader.Read_Integer (1) = -3, "sequence integer 1 must match");
            AUnit.Assertions.Assert
              (Reader.Read_Integer (2) = 42, "sequence integer 2 must match");
            Reader.Leave_Structure;
         end;
      end;
   end Scalar_Sequence_Round_Trip;

   procedure Heterogeneous_Sequence_Round_Trip (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Matrix : constant OpenCV.Core.Mat := Make_Float32_Matrix;
   begin
      declare
         Storage : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.YAML);
      begin
         Storage.Begin_Sequence ("Mixed");
         Storage.Append (11);
         Storage.Append (0.5);
         Storage.Append ("label");
         Storage.Append (Matrix);
         Storage.End_Structure;

         declare
            Serialized : constant String := Storage.Close_And_Get_Text;
            Reader     : Persistence.File_Storage :=
              Persistence.Open_Memory (Serialized);

            procedure Read_Integer_From_Real is
               Unused : constant Integer := Reader.Read_Integer (1);
               pragma Unreferenced (Unused);
            begin
               null;
            end Read_Integer_From_Real;
         begin
            Reader.Enter_Sequence ("Mixed");
            AUnit.Assertions.Assert
              (Reader.Sequence_Length = 4,
               "heterogeneous sequence length must be 4");
            AUnit.Assertions.Assert
              (Reader.Read_Integer (0) = 11,
               "heterogeneous integer element must round trip");
            AUnit.Assertions.Assert
              (Approximately_Equal (Reader.Read_Real (1), 0.5, 1.0E-15),
               "heterogeneous real element must round trip");
            AUnit.Assertions.Assert
              (Reader.Read_String (2) = "label",
               "heterogeneous string element must round trip");
            Assert_Same_Float32_Matrix
              (Matrix,
               Reader.Read_Mat (3),
               "heterogeneous Mat element must round trip");
            Assert_Raises_OpenCV_Error
              (Read_Integer_From_Real'Access,
               "Read_Integer must reject a real sequence element");
            Reader.Leave_Structure;
         end;
      end;
   end Heterogeneous_Sequence_Round_Trip;
   procedure Sequence_Of_Maps_With_Nested_Sequence
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
   begin
      declare
         Storage : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.YAML);
      begin
         Storage.Begin_Sequence ("Features");

         Storage.Begin_Map;
         Storage.Write ("X", 167);
         Storage.Write ("Y", 49);
         Storage.Begin_Sequence ("LBP");
         Storage.Append (1);
         Storage.Append (0);
         Storage.Append (0);
         Storage.Append (1);
         Storage.Append (1);
         Storage.Append (0);
         Storage.Append (1);
         Storage.Append (1);
         Storage.End_Structure;
         Storage.End_Structure;

         Storage.Begin_Map;
         Storage.Write ("X", 298);
         Storage.Write ("Y", 130);
         Storage.Begin_Sequence ("LBP");
         Storage.Append (0);
         Storage.Append (0);
         Storage.Append (0);
         Storage.Append (1);
         Storage.Append (0);
         Storage.Append (0);
         Storage.Append (1);
         Storage.Append (1);
         Storage.End_Structure;
         Storage.End_Structure;

         Storage.End_Structure;

         declare
            Serialized : constant String := Storage.Close_And_Get_Text;
            Reader     : Persistence.File_Storage :=
              Persistence.Open_Memory (Serialized);
         begin
            Reader.Enter_Sequence ("Features");
            AUnit.Assertions.Assert
              (Reader.Sequence_Length = 2,
               "features sequence length must be 2");

            Reader.Enter_Map (0);
            AUnit.Assertions.Assert
              (Reader.Read_Integer ("X") = 167, "feature 0 X must match");
            AUnit.Assertions.Assert
              (Reader.Read_Integer ("Y") = 49, "feature 0 Y must match");
            Reader.Enter_Sequence ("LBP");
            AUnit.Assertions.Assert
              (Reader.Sequence_Length = 8, "feature 0 LBP length must be 8");
            AUnit.Assertions.Assert
              (Reader.Read_Integer (0) = 1
               and then Reader.Read_Integer (3) = 1
               and then Reader.Read_Integer (7) = 1,
               "feature 0 LBP values must match");
            Reader.Leave_Structure;
            Reader.Leave_Structure;

            Reader.Enter_Map (1);
            AUnit.Assertions.Assert
              (Reader.Read_Integer ("X") = 298, "feature 1 X must match");
            AUnit.Assertions.Assert
              (Reader.Read_Integer ("Y") = 130, "feature 1 Y must match");
            Reader.Enter_Sequence ("LBP");
            AUnit.Assertions.Assert
              (Reader.Read_Integer (3) = 1
               and then Reader.Read_Integer (6) = 1
               and then Reader.Read_Integer (7) = 1,
               "feature 1 LBP values must match");
            Reader.Leave_Structure;
            Reader.Leave_Structure;
            Reader.Leave_Structure;
         end;
      end;
   end Sequence_Of_Maps_With_Nested_Sequence;

   procedure Empty_Map_And_Sequence_Are_Present
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
   begin
      declare
         Storage : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.YAML);
      begin
         Storage.Begin_Map ("Empty_Map");
         Storage.End_Structure;
         Storage.Begin_Sequence ("Empty_Sequence");
         Storage.End_Structure;

         declare
            Serialized : constant String := Storage.Close_And_Get_Text;
            Reader     : Persistence.File_Storage :=
              Persistence.Open_Memory (Serialized);

            procedure Enter_Missing_Map is
            begin
               Reader.Enter_Map ("Missing_Map");
            end Enter_Missing_Map;

            procedure Enter_Missing_Sequence is
            begin
               Reader.Enter_Sequence ("Missing_Sequence");
            end Enter_Missing_Sequence;
         begin
            Reader.Enter_Map ("Empty_Map");
            Reader.Leave_Structure;
            Reader.Enter_Sequence ("Empty_Sequence");
            AUnit.Assertions.Assert
              (Reader.Sequence_Length = 0, "empty sequence length must be 0");
            Reader.Leave_Structure;
            Assert_Raises_OpenCV_Error
              (Enter_Missing_Map'Access,
               "a missing map must remain distinct from an empty map");
            Assert_Raises_OpenCV_Error
              (Enter_Missing_Sequence'Access,
               "a missing sequence must remain distinct from an empty "
               & "sequence");
         end;
      end;
   end Empty_Map_And_Sequence_Are_Present;

   procedure JSON_Hierarchy_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Escaped : constant String := "quote "" and backslash \ path";
   begin
      declare
         Storage : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.JSON);
      begin
         Storage.Begin_Map ("Camera");
         Storage.Write ("Name", Escaped);
         Storage.Begin_Sequence ("Coefficients");
         Storage.Append (0.1);
         Storage.Append (-0.02);
         Storage.End_Structure;
         Storage.End_Structure;

         declare
            Serialized : constant String := Storage.Close_And_Get_Text;
            Reader     : Persistence.File_Storage :=
              Persistence.Open_Memory (Serialized);
         begin
            Reader.Enter_Map ("Camera");
            AUnit.Assertions.Assert
              (Reader.Read_String ("Name") = Escaped,
               "JSON nested escaped string must round trip");
            Reader.Enter_Sequence ("Coefficients");
            AUnit.Assertions.Assert
              (Reader.Sequence_Length = 2, "JSON nested sequence length");
            AUnit.Assertions.Assert
              (Approximately_Equal (Reader.Read_Real (0), 0.1, 1.0E-15),
               "JSON nested sequence first real");
            AUnit.Assertions.Assert
              (Approximately_Equal (Reader.Read_Real (1), -0.02, 1.0E-15),
               "JSON nested sequence second real");
            Reader.Leave_Structure;
            Reader.Leave_Structure;
         end;
      end;
   end JSON_Hierarchy_Round_Trip;

   procedure XML_Hierarchy_Round_Trip (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Path : constant String :=
        Test_Path ("opencvcore_ada_persistence_hierarchy.xml");
   begin
      Prepare (Path);
      begin
         declare
            Storage : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Write_Only);
         begin
            Storage.Begin_Map ("Camera");
            Storage.Write ("Count", 3);
            Storage.Begin_Sequence ("Values");
            Storage.Append (8);
            Storage.Append (9);
            Storage.End_Structure;
            Storage.End_Structure;
         end;

         declare
            Reader : Persistence.File_Storage :=
              Persistence.Open (Path, Persistence.Read_Only);
         begin
            Reader.Enter_Map ("Camera");
            AUnit.Assertions.Assert
              (Reader.Read_Integer ("Count") = 3,
               "XML nested integer must round trip");
            Reader.Enter_Sequence ("Values");
            AUnit.Assertions.Assert
              (Reader.Sequence_Length = 2, "XML nested sequence length");
            AUnit.Assertions.Assert
              (Reader.Read_Integer (0) = 8
               and then Reader.Read_Integer (1) = 9,
               "XML nested sequence values must match");
            Reader.Leave_Structure;
            Reader.Leave_Structure;
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end XML_Hierarchy_Round_Trip;

   procedure Nested_Non_Contiguous_Mat_Round_Trip
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Parent : OpenCV.Core.Mat :=
        OpenCV.Core.Create
          (Rows         => 4,
           Columns      => 5,
           Element_Type => (Depth => OpenCV.Core.UInt8, Channels => 1));
      Region : OpenCV.Core.Mat;
   begin
      for Row in 0 .. 3 loop
         for Column in 0 .. 4 loop
            OpenCV.Core.UInt8_Access.Set
              (Parent, Row, Column, Interfaces.Unsigned_8 (Row * 10 + Column));
         end loop;
      end loop;

      Region := Parent.Region ((X => 1, Y => 1, Width => 3, Height => 2));
      AUnit.Assertions.Assert
        (not Region.Is_Continuous, "Region fixture must be non-contiguous");

      declare
         Storage : Persistence.File_Storage :=
           Persistence.Create_Memory (Persistence.YAML);
      begin
         Storage.Begin_Map ("Nested");
         Storage.Write ("Region", Region);
         Storage.End_Structure;

         declare
            Serialized : constant String := Storage.Close_And_Get_Text;
            Reader     : Persistence.File_Storage :=
              Persistence.Open_Memory (Serialized);
            Loaded     : OpenCV.Core.Mat;
         begin
            Reader.Enter_Map ("Nested");
            Loaded := Reader.Read_Mat ("Region");
            AUnit.Assertions.Assert
              (Loaded.Rows = 2 and then Loaded.Columns = 3,
               "nested Region must keep its logical dimensions");
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Access.Get (Loaded, 0, 0) = 11
               and then OpenCV.Core.UInt8_Access.Get (Loaded, 1, 2) = 23,
               "nested Region must contain only the ROI values");
            AUnit.Assertions.Assert
              (OpenCV.Core.UInt8_Access.Get (Parent, 0, 0) = 0
               and then OpenCV.Core.UInt8_Access.Get (Region, 0, 0) = 11,
               "nested Region write must leave parent and Region unchanged");
            Reader.Leave_Structure;
         end;
      end;
   end Nested_Non_Contiguous_Mat_Round_Trip;

   procedure Writer_State_Misuse_Is_Rejected (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Storage : Persistence.File_Storage :=
        Persistence.Create_Memory (Persistence.YAML);

      procedure Append_At_Root is
      begin
         Storage.Append (1);
      end Append_At_Root;

      procedure Unnamed_Map_At_Root is
      begin
         Storage.Begin_Map;
      end Unnamed_Map_At_Root;

      procedure Unnamed_Sequence_At_Root is
      begin
         Storage.Begin_Sequence;
      end Unnamed_Sequence_At_Root;

      procedure End_At_Root is
      begin
         Storage.End_Structure;
      end End_At_Root;

      procedure Append_Inside_Map is
      begin
         Storage.Append (2);
      end Append_Inside_Map;

      procedure Named_Write_Inside_Sequence is
      begin
         Storage.Write ("Named", 3);
      end Named_Write_Inside_Sequence;

      procedure Named_Map_Inside_Sequence is
      begin
         Storage.Begin_Map ("Named");
      end Named_Map_Inside_Sequence;

      procedure Named_Sequence_Inside_Sequence is
      begin
         Storage.Begin_Sequence ("Named");
      end Named_Sequence_Inside_Sequence;
   begin
      Assert_Raises_OpenCV_Error
        (Append_At_Root'Access, "Append must reject the root mapping");
      Assert_Raises_OpenCV_Error
        (Unnamed_Map_At_Root'Access, "unnamed Begin_Map must reject root");
      Assert_Raises_OpenCV_Error
        (Unnamed_Sequence_At_Root'Access,
         "unnamed Begin_Sequence must reject root");
      Assert_Raises_OpenCV_Error
        (End_At_Root'Access, "End_Structure must reject the implicit root");

      Storage.Begin_Map ("Inner");
      Assert_Raises_OpenCV_Error
        (Append_Inside_Map'Access, "Append must reject a mapping context");
      Storage.End_Structure;

      Storage.Begin_Sequence ("Items");
      Assert_Raises_OpenCV_Error
        (Named_Write_Inside_Sequence'Access,
         "named Write must reject a sequence context");
      Assert_Raises_OpenCV_Error
        (Named_Map_Inside_Sequence'Access,
         "named Begin_Map must reject a sequence context");
      Assert_Raises_OpenCV_Error
        (Named_Sequence_Inside_Sequence'Access,
         "named Begin_Sequence must reject a sequence context");
      Storage.End_Structure;
   end Writer_State_Misuse_Is_Rejected;

   procedure Unbalanced_Memory_Close_Is_Recoverable
     (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Storage : Persistence.File_Storage :=
        Persistence.Create_Memory (Persistence.YAML);

      procedure Close_While_Open is
         Unused : constant String := Storage.Close_And_Get_Text;
         pragma Unreferenced (Unused);
      begin
         null;
      end Close_While_Open;
   begin
      Storage.Begin_Map ("Open");
      Assert_Raises_OpenCV_Error
        (Close_While_Open'Access,
         "Close_And_Get_Text must reject an unclosed structure");
      Storage.Write ("Count", 5);
      Storage.End_Structure;

      declare
         Serialized : constant String := Storage.Close_And_Get_Text;
         Reader     : Persistence.File_Storage :=
           Persistence.Open_Memory (Serialized);
      begin
         Reader.Enter_Map ("Open");
         AUnit.Assertions.Assert
           (Reader.Read_Integer ("Count") = 5,
            "recovered Close_And_Get_Text must persist the closed map");
         Reader.Leave_Structure;
      end;
   end Unbalanced_Memory_Close_Is_Recoverable;
   procedure Reader_State_Misuse_Is_Rejected (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Writer : Persistence.File_Storage :=
        Persistence.Create_Memory (Persistence.YAML);
   begin
      Writer.Write ("Count", 1);
      Writer.Begin_Map ("Inner");
      Writer.Write ("X", 2);
      Writer.End_Structure;
      Writer.Begin_Sequence ("Items");
      Writer.Append (3);
      Writer.End_Structure;

      declare
         Serialized : constant String := Writer.Close_And_Get_Text;
         Reader     : Persistence.File_Storage :=
           Persistence.Open_Memory (Serialized);

         procedure Length_At_Root is
            Unused : constant Natural := Reader.Sequence_Length;
            pragma Unreferenced (Unused);
         begin
            null;
         end Length_At_Root;

         procedure Indexed_Read_At_Root is
            Unused : constant Integer := Reader.Read_Integer (0);
            pragma Unreferenced (Unused);
         begin
            null;
         end Indexed_Read_At_Root;

         procedure Indexed_Enter_At_Root is
         begin
            Reader.Enter_Map (0);
         end Indexed_Enter_At_Root;

         procedure Leave_At_Root is
         begin
            Reader.Leave_Structure;
         end Leave_At_Root;

         procedure Indexed_Read_Inside_Map is
            Unused : constant Integer := Reader.Read_Integer (0);
            pragma Unreferenced (Unused);
         begin
            null;
         end Indexed_Read_Inside_Map;

         procedure Named_Read_Inside_Sequence is
            Unused : constant Integer := Reader.Read_Integer ("Name");
            pragma Unreferenced (Unused);
         begin
            null;
         end Named_Read_Inside_Sequence;

         procedure Named_Enter_Inside_Sequence is
         begin
            Reader.Enter_Map ("Name");
         end Named_Enter_Inside_Sequence;
      begin
         Assert_Raises_OpenCV_Error
           (Length_At_Root'Access, "Sequence_Length must reject root");
         Assert_Raises_OpenCV_Error
           (Indexed_Read_At_Root'Access,
            "indexed Read_Integer must reject root");
         Assert_Raises_OpenCV_Error
           (Indexed_Enter_At_Root'Access,
            "indexed Enter_Map must reject root");
         Assert_Raises_OpenCV_Error
           (Leave_At_Root'Access, "Leave_Structure must reject the root");

         Reader.Enter_Map ("Inner");
         Assert_Raises_OpenCV_Error
           (Indexed_Read_Inside_Map'Access,
            "indexed read must reject a mapping context");
         Reader.Leave_Structure;

         Reader.Enter_Sequence ("Items");
         Assert_Raises_OpenCV_Error
           (Named_Read_Inside_Sequence'Access,
            "named Read_Integer must reject a sequence context");
         Assert_Raises_OpenCV_Error
           (Named_Enter_Inside_Sequence'Access,
            "named Enter_Map must reject a sequence context");
         Reader.Leave_Structure;
      end;
   end Reader_State_Misuse_Is_Rejected;

   procedure Wrong_Collection_Type_Is_Rejected (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Writer : Persistence.File_Storage :=
        Persistence.Create_Memory (Persistence.YAML);
   begin
      Writer.Begin_Map ("One_Map");
      Writer.Write ("X", 1);
      Writer.End_Structure;
      Writer.Begin_Sequence ("One_Sequence");
      Writer.Begin_Map;
      Writer.Write ("Y", 2);
      Writer.End_Structure;
      Writer.End_Structure;

      declare
         Serialized : constant String := Writer.Close_And_Get_Text;
         Reader     : Persistence.File_Storage :=
           Persistence.Open_Memory (Serialized);

         procedure Enter_Map_As_Sequence is
         begin
            Reader.Enter_Sequence ("One_Map");
         end Enter_Map_As_Sequence;

         procedure Enter_Sequence_As_Map is
         begin
            Reader.Enter_Map ("One_Sequence");
         end Enter_Sequence_As_Map;

         procedure Enter_Map_As_Indexed_Sequence is
         begin
            Reader.Enter_Sequence (0);
         end Enter_Map_As_Indexed_Sequence;
      begin
         Assert_Raises_OpenCV_Error
           (Enter_Map_As_Sequence'Access,
            "Enter_Sequence must reject a mapping node");
         Assert_Raises_OpenCV_Error
           (Enter_Sequence_As_Map'Access,
            "Enter_Map must reject a sequence node");

         Reader.Enter_Sequence ("One_Sequence");
         Assert_Raises_OpenCV_Error
           (Enter_Map_As_Indexed_Sequence'Access,
            "indexed Enter_Sequence must reject a mapping element");
         Reader.Leave_Structure;
      end;
   end Wrong_Collection_Type_Is_Rejected;
   procedure Out_Of_Range_Index_Is_Rejected (Test : in out Mat_Test_Fixture) is
      pragma Unreferenced (Test);
      Writer : Persistence.File_Storage :=
        Persistence.Create_Memory (Persistence.YAML);
   begin
      Writer.Begin_Sequence ("Values");
      Writer.Append (1);
      Writer.Append (2);
      Writer.End_Structure;

      declare
         Serialized : constant String := Writer.Close_And_Get_Text;
         Reader     : Persistence.File_Storage :=
           Persistence.Open_Memory (Serialized);

         procedure Read_At_Length is
            Unused : constant Integer :=
              Reader.Read_Integer (Reader.Sequence_Length);
            pragma Unreferenced (Unused);
         begin
            null;
         end Read_At_Length;
      begin
         Reader.Enter_Sequence ("Values");
         Assert_Raises_OpenCV_Error
           (Read_At_Length'Access,
            "indexed read must reject Sequence_Length as an index");
         Reader.Leave_Structure;
      end;
   end Out_Of_Range_Index_Is_Rejected;

   procedure Navigation_Unwind_Preserves_Root (Test : in out Mat_Test_Fixture)
   is
      pragma Unreferenced (Test);
      Writer : Persistence.File_Storage :=
        Persistence.Create_Memory (Persistence.YAML);
   begin
      Writer.Write ("Root", 99);
      Writer.Begin_Map ("Outer");
      Writer.Begin_Sequence ("Middle");
      Writer.Begin_Map;
      Writer.Begin_Sequence ("Inner");
      Writer.Append (1);
      Writer.End_Structure;
      Writer.End_Structure;
      Writer.End_Structure;
      Writer.End_Structure;

      declare
         Serialized : constant String := Writer.Close_And_Get_Text;
         Reader     : Persistence.File_Storage :=
           Persistence.Open_Memory (Serialized);
      begin
         Reader.Enter_Map ("Outer");
         Reader.Enter_Sequence ("Middle");
         Reader.Enter_Map (0);
         Reader.Enter_Sequence ("Inner");
         AUnit.Assertions.Assert
           (Reader.Read_Integer (0) = 1, "deepest sequence value must match");
         Reader.Leave_Structure;
         Reader.Leave_Structure;
         Reader.Leave_Structure;
         Reader.Leave_Structure;
         AUnit.Assertions.Assert
           (Reader.Read_Integer ("Root") = 99,
            "root value must remain readable after deep unwind");
      end;
   end Navigation_Unwind_Preserves_Root;

   package Caller is new AUnit.Test_Caller (Mat_Test_Fixture);

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Result.Add_Test
        (Caller.Create
           ("YAML Float32 Mat round trip",
            YAML_Float32_Mat_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create ("XML Mat round trip", XML_Mat_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create ("JSON Mat round trip", JSON_Mat_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Multiple named Mats round trip",
            Multiple_Named_Mats_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("UInt8 C3 type is preserved", UInt8_C3_Type_Is_Preserved'Access));
      Result.Add_Test
        (Caller.Create
           ("Non-contiguous Region is written",
            Non_Contiguous_Region_Is_Written'Access));
      Result.Add_Test
        (Caller.Create
           ("Missing name raises without poisoning storage",
            Missing_Name_Raises_Without_Poisoning_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Empty Mat round trip is present",
            Empty_Mat_Round_Trip_Is_Present'Access));
      Result.Add_Test
        (Caller.Create
           ("Read_Mat outlives File_Storage",
            Read_Mat_Outlives_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Mode misuse is rejected", Mode_Misuse_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create ("Open failure raises", Open_Failure_Raises'Access));
      Result.Add_Test
        (Caller.Create
           ("Invalid names and filenames are rejected",
            Invalid_Names_And_Filenames_Are_Rejected'Access));
      Result.Add_Test
        (Caller.Create ("Integer round trip", Integer_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer INT_MIN is rejected", Integer_Min_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create ("Real round trip", Real_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Integer widens to real", Integer_Widens_To_Real'Access));
      Result.Add_Test
        (Caller.Create ("String round trip", String_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Mixed named values round trip",
            Mixed_Named_Values_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("JSON scalar and string round trip",
            JSON_Scalar_And_String_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Wrong node types are rejected",
            Wrong_Node_Types_Are_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Missing versus stored zero and empty",
            Missing_Versus_Stored_Zero_And_Empty'Access));
      Result.Add_Test
        (Caller.Create
           ("Embedded NUL string is rejected",
            Embedded_NUL_String_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("YAML memory mixed round trip",
            YAML_Memory_Mixed_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("XML memory round trip", XML_Memory_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("JSON memory round trip", JSON_Memory_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Storage closes after text extraction",
            Storage_Closes_After_Text_Extraction'Access));
      Result.Add_Test
        (Caller.Create
           ("Disk storage cannot get memory text",
            Disk_Storage_Cannot_Get_Memory_Text'Access));
      Result.Add_Test
        (Caller.Create
           ("Memory reader cannot get output text",
            Memory_Reader_Cannot_Get_Output_Text'Access));
      Result.Add_Test
        (Caller.Create
           ("Invalid memory input is rejected",
            Invalid_Memory_Input_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Temporary input buffer outlives open",
            Temporary_Input_Buffer_Outlives_Open'Access));
      Result.Add_Test
        (Caller.Create
           ("Returned text outlives storage",
            Returned_Text_Outlives_Storage'Access));
      Result.Add_Test
        (Caller.Create
           ("Memory integer INT_MIN is rejected",
            Memory_Integer_Min_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Nested map round trip", Nested_Map_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Scalar sequence round trip", Scalar_Sequence_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Heterogeneous sequence round trip",
            Heterogeneous_Sequence_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Sequence of maps with nested sequence",
            Sequence_Of_Maps_With_Nested_Sequence'Access));
      Result.Add_Test
        (Caller.Create
           ("Empty map and sequence are present",
            Empty_Map_And_Sequence_Are_Present'Access));
      Result.Add_Test
        (Caller.Create
           ("JSON hierarchy round trip", JSON_Hierarchy_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("XML hierarchy round trip", XML_Hierarchy_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Nested non-contiguous Mat round trip",
            Nested_Non_Contiguous_Mat_Round_Trip'Access));
      Result.Add_Test
        (Caller.Create
           ("Writer state misuse is rejected",
            Writer_State_Misuse_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Unbalanced memory close is recoverable",
            Unbalanced_Memory_Close_Is_Recoverable'Access));
      Result.Add_Test
        (Caller.Create
           ("Reader state misuse is rejected",
            Reader_State_Misuse_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Wrong collection type is rejected",
            Wrong_Collection_Type_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Out-of-range index is rejected",
            Out_Of_Range_Index_Is_Rejected'Access));
      Result.Add_Test
        (Caller.Create
           ("Navigation unwind preserves root",
            Navigation_Unwind_Preserves_Root'Access));
      return Result'Access;
   end Suite;

end Persistence_Tests;
