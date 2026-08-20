with Ada.Directories;
with Ada.Environment_Variables;
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
            Storage.Write ("Min_Int32", -2_147_483_648);
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
              (Storage.Read_Integer ("Min_Int32") = -2_147_483_648,
               "signed 32-bit minimum must round trip exactly");
         end;
      exception
         when others =>
            Cleanup (Path);
            raise;
      end;
      Cleanup (Path);
   end Integer_Round_Trip;

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
      Escaped : constant String := "quote "" and slash / path";
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
      return Result'Access;
   end Suite;

end Persistence_Tests;
