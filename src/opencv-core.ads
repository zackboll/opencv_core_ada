with Ada.Finalization;
with Interfaces;
private with OpenCV.Internal.C_API;

package OpenCV.Core is

   type Depth_Type is
     (UInt8, Int8, UInt16, Int16, Int32, Float32, Float64, Float16);

   type Norm_Kind is (L1, L2, Infinity);

   --  Min_Max is a normalization mode rather than a Mat.Norm reduction kind.
   type Normalize_Kind is (L1, L2, Infinity, Min_Max);

   type Comparison_Kind is
     (Equal,
      Not_Equal,
      Less_Than,
      Less_Or_Equal,
      Greater_Than,
      Greater_Or_Equal);

   type Flip_Kind is (Vertical, Horizontal, Both_Axes);

   type Border_Kind is
     (Constant_Border, Replicate, Reflect, Reflect_101, Wrap);

   type Rotation_Kind is (Clockwise_90, Half_Turn, Counterclockwise_90);

   type Reduction_Axis is (Across_Rows, Across_Columns);

   type Reduction_Kind is (Sum, Average, Maximum, Minimum, Sum_Of_Squares);

   --  Selects which equal extremum is reported by Arg_Minimum and Arg_Maximum.
   type Extremum_Occurrence is (First_Occurrence, Last_Occurrence);

   type Angle_Unit is (Radians, Degrees);

   --  Sort axis names describe the values being ordered, not a reduction.
   --  Each_Row sorts the columns of every row independently, left to right.
   --  Each_Column sorts the rows of every column independently, top to bottom.
   type Sort_Axis is (Each_Row, Each_Column);

   type Sort_Order is (Ascending, Descending);

   --  Selects the uncentered transposed-product orientation. There is
   --  no default; the caller must choose which square product is
   --  intended.
   type Transposed_Product_Order is
     (Transpose_Times_Self, Self_Times_Transpose);

   --  Identifies which triangle of a square Mat is authoritative when
   --  completing symmetry in place. Upper_Triangle copies the upper
   --  triangle onto the lower triangle. Lower_Triangle copies the lower
   --  triangle onto the upper triangle.
   type Symmetry_Source is (Upper_Triangle, Lower_Triangle);

   --  Interprets a 2-D sample matrix for Covariance. Samples_Are_Rows
   --  treats each row as one observation. Samples_Are_Columns treats
   --  each column as one observation.
   type Sample_Orientation is (Samples_Are_Rows, Samples_Are_Columns);

   --  Selects whether Covariance divides the accumulation by the
   --  sample count N. Unscaled leaves the raw accumulation.
   --  By_Sample_Count applies OpenCV's COVAR_SCALE factor 1/N. This
   --  is not unbiased covariance and is not 1/(N - 1).
   type Covariance_Scaling is (Unscaled, By_Sample_Count);

   --  Selects ordinary complex spectrum multiplication or
   --  multiplication by the conjugate of the right-hand spectrum.
   --  Ordinary products participate in frequency-domain convolution.
   --  Conjugate-right products participate in frequency-domain
   --  correlation. This operation performs only spectral
   --  multiplication; inverse transformation and any required
   --  padding or cropping remain caller operations.
   type Spectrum_Multiplication_Kind is
     (Ordinary_Spectrum_Product, Conjugate_Right_Spectrum_Product);

   type Channel_Count is new Interfaces.Integer_32 range 1 .. 512;

   type Mat_Size is
     new Interfaces.Integer_64 range 0 .. Interfaces.Integer_64'Last;

   type Size_Coordinate is
     new Interfaces.Integer_32 range 0 .. Interfaces.Integer_32'Last;

   type Point_Coordinate is new Interfaces.Integer_32;

   --  A border interpolation either selects a zero-based source coordinate or
   --  indicates that an out-of-range Constant_Border coordinate has no donor.
   type Border_Interpolation_Result (Uses_Constant : Boolean := False) is
   record
      case Uses_Constant is
         when False =>
            Index : Size_Coordinate;

         when True =>
            null;
      end case;
   end record;

   --  A zero-based half-open index interval: Start <= index < Stop.
   type Index_Range is record
      Start : Size_Coordinate := 0;
      Stop  : Size_Coordinate := 0;
   end record;

   type Size is record
      Width  : Size_Coordinate := 0;
      Height : Size_Coordinate := 0;
   end record;

   type Point is record
      X : Point_Coordinate := 0;
      Y : Point_Coordinate := 0;
   end record;

   --  A zero-based, value-semantic sequence of points. An empty result has
   --  the null range 1 .. 0.
   type Point_Array is array (Natural range <>) of Point;

   --  CV_8U and CV_32F element value domains used by typed Mat accessors.
   subtype UInt8_Value is Interfaces.Unsigned_8;
   subtype Float32_Value is Interfaces.IEEE_Float_32;

   type Mat_Type is record
      Depth    : Depth_Type;
      Channels : Channel_Count;
   end record;

   type Scalar is record
      Component_0 : Long_Float := 0.0;
      Component_1 : Long_Float := 0.0;
      Component_2 : Long_Float := 0.0;
      Component_3 : Long_Float := 0.0;
   end record;

   type Min_Max_Result is record
      Minimum          : Long_Float;
      Maximum          : Long_Float;
      Minimum_Location : Point;
      Maximum_Location : Point;
   end record;

   type Mean_Std_Dev_Result is record
      Mean               : Scalar;
      Standard_Deviation : Scalar;
   end record;

   --  Discriminated result of Check_Range. First_Invalid is present only
   --  when Valid is False. Point.X is the column and Point.Y is the row.
   type Range_Check_Result (Valid : Boolean := True) is record
      case Valid is
         when True =>
            null;

         when False =>
            First_Invalid : Point;
      end case;
   end record;

   type Rect is record
      X      : Size_Coordinate := 0;
      Y      : Size_Coordinate := 0;
      Width  : Size_Coordinate := 0;
      Height : Size_Coordinate := 0;
   end record;

   function Make_Scalar
     (Component_0 : Long_Float;
      Component_1 : Long_Float := 0.0;
      Component_2 : Long_Float := 0.0;
      Component_3 : Long_Float := 0.0) return Scalar;

   type Mat is tagged private;

   --  Selects OpenCV's random or Arthur--Vassilvitskii k-means++ center
   --  initialization. Both choices consume OpenCV's global RNG. Cluster
   --  numbers, including their order in Centers, have no semantic meaning.
   type K_Means_Initialization is (Random_Centers, Plus_Plus_Centers);

   --  OpenCV 4.10 k-means always uses both count and epsilon termination.
   --  Its effective iteration count is constrained to 2 .. 100, so this type
   --  prevents the silent clamping performed by the native implementation.
   type K_Means_Iteration_Count is range 2 .. 100;

   type K_Means_Criteria is record
      Maximum_Iterations : K_Means_Iteration_Count := 100;
      Epsilon            : Long_Float := 1.0E-4;
   end record;

   --  Independently owned K_Means outputs. Labels is N x 1 Int32 C1, and
   --  Centers is Cluster_Count x feature-dimension Float32 C1. Compactness is
   --  sum_i ||sample_i - center[labels_i]||**2.
   type K_Means_Result is record
      Labels      : Mat;
      Centers     : Mat;
      Compactness : Long_Float;
   end record;

   type Batch_Distance_Kind is
     (L1_Distance,
      L2_Distance,
      Squared_L2_Distance,
      Hamming_Distance,
      Hamming_2_Distance);

   --  Independently owned K-nearest-neighbor outputs. Indices is Int32 C1
   --  and contains zero-based rows of the candidate Mat.
   type Nearest_Neighbor_Result is record
      Distances : Mat;
      Indices   : Mat;
   end record;

   --  Independent polar outputs of Cart_To_Polar. Magnitude is
   --  sqrt (X**2 + Y**2). Angle is the corresponding OpenCV fast phase
   --  of (X, Y). Each component has normal Mat controlled ownership and
   --  is independent of the source Mats and of the other component.

   type Polar_Coordinates is record
      Magnitude : Mat;
      Angle     : Mat;
   end record;

   --  Independent Cartesian outputs of Polar_To_Cart. X is
   --  Magnitude * cos (Angle) and Y is Magnitude * sin (Angle).
   --  Each component has normal Mat controlled ownership and
   --  is independent of the source Mats and of the other component.
   type Cartesian_Coordinates is record
      X : Mat;
      Y : Mat;
   end record;

   --  Independently owned outputs of Covariance. Covariance is the
   --  normal feature covariance matrix. Mean is the corresponding
   --  per-feature average computed by OpenCV. Each field has normal
   --  Mat controlled ownership and is independent of Self and of the
   --  other field.
   type Covariance_Result is record
      Covariance : Mat;
      Mean       : Mat;
   end record;

   --  Independently owned outputs of Eigen_Decomposition and
   --  Non_Symmetric_Eigen_Decomposition. Eigenvalues is the N x 1
   --  column of eigenvalues. Eigenvectors is the N x N matrix of
   --  corresponding eigenvectors stored by row. Each field has normal
   --  Mat controlled ownership and is independent of Self and of the
   --  other field.
   type Eigen_Decomposition_Result is record
      Eigenvalues  : Mat;
      Eigenvectors : Mat;
   end record;

   --  Independently owned outputs of Principal_Component_Analysis.
   --  Mean is the per-feature average. Eigenvalues is the K x 1
   --  column of principal variances in descending order.
   --  Eigenvectors stores one feature-space principal direction per
   --  row so that row i corresponds to eigenvalue i. Each field has
   --  normal Mat controlled ownership and is independent of Self and
   --  of the other fields.
   type Principal_Component_Analysis_Result is record
      Mean         : Mat;
      Eigenvalues  : Mat;
      Eigenvectors : Mat;
   end record;

   --  Independently owned outputs of Linear_Discriminant_Analysis.
   --  Eigenvalues is the K x 1 column of discriminant eigenvalues in
   --  descending order. Eigenvectors is D x K, with each discriminant
   --  direction stored in a column corresponding to the eigenvalue in
   --  that column. The fields have normal Mat controlled ownership and
   --  are independent of the input Mats and of each other.
   type Linear_Discriminant_Analysis_Result is record
      Eigenvalues  : Mat;
      Eigenvectors : Mat;
   end record;

   --  Independently owned outputs of Singular_Value_Decomposition.
   --  Singular_Values is the R x 1 column of nonnegative singular
   --  values in descending order, where R = min (Rows, Columns).
   --  U is the Rows x R matrix of left singular vectors stored as
   --  columns. V_Transpose is the R x Columns matrix of transposed
   --  right singular vectors. Each field has normal Mat controlled
   --  ownership and is independent of Self and of the other fields.
   type Singular_Value_Decomposition_Result is record
      Singular_Values : Mat;
      U               : Mat;
      V_Transpose     : Mat;
   end record;

   --  Discriminated result of Invert. Inverse is present only when
   --  Invertible is True. Inverse has normal Mat controlled ownership
   --  and independent storage. A singular matrix yields Invertible
   --  False rather than a zero-filled placeholder inverse.
   type Inversion_Result (Invertible : Boolean := False) is record
      case Invertible is
         when True =>
            Inverse : Mat;

         when False =>
            null;
      end case;
   end record;

   --  Discriminated result of Solve. Solution is present only when
   --  Solved is True. Solution has normal Mat controlled ownership
   --  and independent storage. A singular coefficient matrix yields
   --  Solved False rather than a zero-filled placeholder solution.
   type Solve_Result (Solved : Boolean := False) is record
      case Solved is
         when True =>
            Solution : Mat;

         when False =>
            null;
      end case;
   end record;

   --  Status of a continuous linear-program maximization. Numerical_Loss means
   --  OpenCV lost a feasible solution through floating-point arithmetic.
   type Linear_Program_Status is
     (Unique_Optimum, Multiple_Optima, Unbounded, Infeasible, Numerical_Loss);

   --  Unique_Optimum and Multiple_Optima contain one independently owned
   --  solution. The remaining statuses deliberately expose no candidate Mat.
   type Linear_Program_Result (Status : Linear_Program_Status := Infeasible) is
   record
      case Status is
         when Unique_Optimum | Multiple_Optima =>
            Solution : Mat;

         when Unbounded | Infeasible | Numerical_Loss =>
            null;
      end case;
   end record;

   --  Solves the least-squares problem A * X ~= B using OpenCV 4.10
   --  cv::solve with DECOMP_SVD. Unlike Solve, which is the LU API for
   --  ordinary square systems, Self (A) may be square or overdetermined:
   --  M = A.Rows must be at least N = A.Columns. Underdetermined systems
   --  are rejected because OpenCV 4.10 cv::solve rejects M < N even for
   --  DECOMP_SVD. Right_Hand_Side (B) must have M rows and may have K >= 1
   --  columns. The independently owned Float32 or Float64 C1 result has
   --  shape N x K. A and B must be non-empty, single-channel, Float32 or
   --  Float64, and have the same depth. Rank-deficient A is accepted and
   --  receives OpenCV's SVD pseudo-solution using its internal singular-value
   --  threshold. Inputs are unchanged, the result owns independent storage,
   --  and non-contiguous Regions are supported. Numerical rounding and SVD
   --  singular-value thresholding apply.
   function Solve_Least_Squares (Self : Mat; Right_Hand_Side : Mat) return Mat;

   --  Solves a continuous linear program using OpenCV 4.10 simplex: maximize
   --  c * x subject to A * x <= b and x >= 0. Objective is a non-empty C1
   --  Float32 or Float64 1 x N or N x 1 vector (N >= 1). Constraints is a
   --  non-empty C1 Float32 or Float64 M x (N + 1) Mat (M >= 1), with A in its
   --  first N columns and b in its last column. Input depths may differ, but
   --  every coefficient must be finite. Constraint_Tolerance is finite and
   --  nonnegative. Unique_Optimum and Multiple_Optima contain one arbitrary
   --  optimum as an independently owned N x 1 Float64 C1 Solution; Unbounded,
   --  Infeasible, and Numerical_Loss contain no Solution. Inputs are unchanged
   --  and non-contiguous Regions are supported. This is maximization only; a
   --  caller may negate c when its minimization fits this formulation.
   function Solve_Linear_Program
     (Objective            : Mat;
      Constraints          : Mat;
      Constraint_Tolerance : Long_Float := 1.0E-12)
      return Linear_Program_Result;

   --  The mathematical real-root result of Solve_Cubic: infinitely many
   --  roots, no real roots, or one, two, or three distinct real roots.
   type Cubic_Root_Status is
     (Infinitely_Many_Roots,
      No_Real_Roots,
      One_Real_Root,
      Two_Real_Roots,
      Three_Real_Roots);

   --  Discriminated result of Solve_Cubic. Roots exists only when Status
   --  denotes a finite positive count of distinct real roots. It is an
   --  independently owned 3 x 1 single-channel Mat with the coefficient
   --  depth; only its leading one, two, or three entries selected by Status
   --  are mathematically valid. OpenCV does not guarantee root ordering.
   type Cubic_Solution_Result (Status : Cubic_Root_Status := No_Real_Roots) is
   record
      case Status is
         when One_Real_Root | Two_Real_Roots | Three_Real_Roots =>
            Roots : Mat;

         when Infinitely_Many_Roots | No_Real_Roots =>
            null;
      end case;
   end record;

   --  Result of Solve_Polynomial. Roots is an independently owned effective-
   --  degree x 1 C2 Mat. Trailing high-order coefficients whose converted
   --  Float64 components' absolute-value sum is at most OpenCV 4.10's
   --  DBL_EPSILON are trimmed; OpenCV's original-degree padding rows are not
   --  exposed.
   type Polynomial_Solution_Result is record
      Roots              : Mat;
      Maximum_Correction : Long_Float;
   end record;

   --  A zero-based, owning sequence of Mats. An empty result has the null
   --  range 1 .. 0. Each element has normal Mat controlled ownership and
   --  shallow-copy assignment semantics.
   type Mat_Array is array (Natural range <>) of Mat;

   type Channel_Source_Kind is (From_Source, Zero_Fill);

   --  Source_Index and Destination_Index are the actual indices of Sources
   --  and Destinations, respectively. Channel indices are zero-based within
   --  their selected Mat. Zero_Fill writes zero to the destination channel.
   type Channel_Route (Source_Kind : Channel_Source_Kind := From_Source) is
   record
      Destination_Index   : Natural;
      Destination_Channel : Natural;
      case Source_Kind is
         when From_Source =>
            Source_Index   : Natural;
            Source_Channel : Natural;

         when Zero_Fill =>
            null;
      end case;
   end record;

   type Channel_Route_Array is array (Natural range <>) of Channel_Route;

   function Create
     (Rows, Columns : Natural; Element_Type : Mat_Type) return Mat
   with Pre => Rows <= 2_147_483_647 and then Columns <= 2_147_483_647;

   function Create (Dimensions : Size; Element_Type : Mat_Type) return Mat;

   --  Creates an independent square matrix with Diagonal on its main diagonal
   --  and zero in every off-diagonal element. Diagonal must be a row or column
   --  vector. The result preserves Diagonal's depth and channel count.
   function Diagonal_Matrix (Diagonal : Mat) return Mat;

   --  Both operations create a distinct Mat header sharing Self's storage.
   --  Depth and total scalar storage are preserved; Columns is derived.
   function Reshape (Self : Mat; Channels : Channel_Count) return Mat;
   function Reshape
     (Self : Mat; Channels : Channel_Count; Rows : Positive) return Mat;

   --  Creates a distinct single-column Mat header sharing Self's storage for
   --  the selected diagonal. Offset zero selects the main diagonal; positive
   --  offsets select diagonals above it (Offset 1 starts at row 0, column 1),
   --  and negative offsets select diagonals below it (Offset -1 starts at row
   --  1, column 0). Offset must select at least one element.
   function Diagonal_View
     (Self : Mat; Offset : Point_Coordinate := 0) return Mat;

   function Clone (Self : Mat) return Mat;

   --  Clusters Float32 samples with OpenCV 4.10 cv::kmeans. Samples must be a
   --  non-empty 2-D Mat with at least one channel. For Rows = 1, each column
   --  is a sample and the feature dimension is Channels. Otherwise, each row
   --  is a sample and the feature dimension is Columns * Channels. Thus N x D
   --  Float32 C1, N x 1 Float32 Cn, and 1 x N Float32 Cn are supported.
   --  Cluster_Count must not exceed the resulting sample count. Non-contiguous
   --  Regions are supported and Samples is unchanged. Epsilon must be finite
   --  and nonnegative. Initialization applies to every attempt. Attempts
   --  defaults to 3. KMEANS_USE_INITIAL_LABELS is provided by the distinct
   --  overload below.
   function K_Means
     (Samples        : Mat;
      Cluster_Count  : Positive;
      Criteria       : K_Means_Criteria :=
        (Maximum_Iterations => 100, Epsilon => 1.0E-4);
      Attempts       : Positive := 3;
      Initialization : K_Means_Initialization := Plus_Plus_Centers)
      return K_Means_Result;

   --  Refines an initial partition using OpenCV 4.10 cv::kmeans. Samples has
   --  the same contract as the no-label overload. Initial_Labels must be a
   --  non-empty Int32 C1 row or column vector containing exactly one
   --  zero-based
   --  label in 0 .. Cluster_Count - 1 for every logical sample. Labels may be
   --  N x 1 or 1 x N, where N follows Samples' sample-count rule. The input is
   --  unchanged, including when it is a non-contiguous Region. OpenCV repairs
   --  initially empty clusters. Attempt 1 starts from Initial_Labels. Attempts
   --  defaults to 1; when it exceeds 1, later attempts use
   --  Subsequent_Initialization and the returned result has the lowest
   --  compactness of all attempts, so its labels may be from a later attempt.
   --  Set_Random_Seed makes those later randomized attempts reproducible
   --  on the calling thread.
   function K_Means
     (Samples                   : Mat;
      Cluster_Count             : Positive;
      Initial_Labels            : Mat;
      Criteria                  : K_Means_Criteria :=
        (Maximum_Iterations => 100, Epsilon => 1.0E-4);
      Attempts                  : Positive := 1;
      Subsequent_Initialization : K_Means_Initialization := Plus_Plus_Centers)
      return K_Means_Result;

   --  Returns Neighbor_Count nearest candidate row-vectors for each query row.
   --  Queries and Candidates are non-empty, single-channel UInt8 or Float32
   --  Mats with equal column counts; their row counts may differ. Each row is
   --  one vector, so channels are not folded into its width. Neighbor_Count
   --  must not exceed Candidates.Rows. Float32 supports L1, L2, and squared
   --  L2; UInt8 additionally supports Hamming and Hamming2. Distances is
   --  Queries.Rows x Neighbor_Count C1: Float32 except Int32 for Hamming and
   --  Hamming2. Indices has the same shape and is Int32 C1. Rows are returned
   --  nearest-first; ordering of exact ties is OpenCV-defined. Results own
   --  independent storage, inputs are unchanged, and non-contiguous Regions
   --  are supported. Masks, update, crosscheck, and all-pairs mode are not
   --  exposed.
   function K_Nearest_Neighbors
     (Queries        : Mat;
      Candidates     : Mat;
      Neighbor_Count : Positive;
      Kind           : Batch_Distance_Kind := L2_Distance)
      return Nearest_Neighbor_Result;
   --  Returns an independent Mat whose rows and columns are swapped. Element
   --  depth and channel count are preserved, including for multi-channel Mats.
   --  Empty Mats produce an empty result. Non-contiguous Regions are accepted.
   function Transpose (Self : Mat) return Mat;
   --  Returns an independent Mat with the same dimensions and element type as
   --  Self. Vertical reverses row order, Horizontal reverses column order,
   --  and Both_Axes reverses both. Empty Mats produce an empty result.
   --  Non-contiguous Regions are accepted.
   function Flip (Self : Mat; Kind : Flip_Kind) return Mat;

   --  Returns an independent Mat with Self's rows, columns, depth, and
   --  channel count. Each_Row independently sorts the values across the
   --  columns of every row, left to right. Each_Column independently sorts
   --  the values down the rows of every column, top to bottom. Ascending is
   --  the default order and Each_Row is the default axis. Self must be
   --  single-channel. Supported depths are UInt8, Int8, UInt16, Int16,
   --  Int32, Float32, and Float64. Float16 is rejected because OpenCV 4.10
   --  has no sort implementation for it. Self is not modified. The result
   --  owns independent storage, including when Self is a non-contiguous
   --  Region. Continuity is not required. A default empty Mat and typed 0x0
   --  Mats of a supported depth produce an empty result that preserves the
   --  source shape, depth, and channel count. Typed empty Float16 is
   --  rejected. Equal values are sorted correctly, but their relative order
   --  is not guaranteed. NaN ordering is not part of the public contract.
   function Sort
     (Self  : Mat;
      Axis  : Sort_Axis := Each_Row;
      Order : Sort_Order := Ascending) return Mat;
   --  Returns an independent Int32 single-channel Mat of Self's rows and
   --  columns containing zero-based indices, not the sorted values. Each_Row
   --  independently orders the columns of every row and stores the original
   --  column indices. Each_Column independently orders the rows of every
   --  column and stores the original row indices. Ascending is the default
   --  order and Each_Row is the default axis. Self is not modified. Self must
   --  be single-channel. Supported source depths are UInt8, Int8, UInt16,
   --  Int16, Int32, Float32, and Float64. Float16 is rejected because
   --  OpenCV 4.10 has no sortIdx implementation for it. Continuity is not
   --  required. The result owns independent storage, including when Self is a
   --  non-contiguous Region; Region indices are relative to that Region
   --  rather than to its parent. Equal values produce a valid permutation
   --  that would sort those values, but their relative order is not stable
   --  or otherwise guaranteed. NaN ordering is not part of the public
   --  contract. A default empty Mat and typed 0x0 Mats of a supported depth
   --  raise OpenCV_Error because OpenCV 4.10's sortIdx implementation asserts
   --  that source and destination data pointers differ, and empty Mats share
   --  a null data pointer. Typed empty Float16 is rejected before the ABI.
   function Sort_Indices
     (Self  : Mat;
      Axis  : Sort_Axis := Each_Row;
      Order : Sort_Order := Ascending) return Mat;

   --  Returns an independent Mat with a border of the requested thickness.
   --  Constant uses Value; other border kinds extrapolate source pixels.
   --  When Self is a Region, Isolated is false by default so OpenCV may use
   --  pixels from its parent Mat. Isolated true restricts extrapolation to the
   --  Region boundaries. Empty Mats produce an empty result when every border
   --  is zero.
   function Copy_Make_Border
     (Self     : Mat;
      Top      : Natural;
      Bottom   : Natural;
      Left     : Natural;
      Right    : Natural;
      Kind     : Border_Kind;
      Value    : Scalar := (others => 0.0);
      Isolated : Boolean := False) return Mat;

   --  Maps a zero-based one-dimensional Position to a source coordinate for a
   --  source Length. Length must be positive. In-range coordinates map to
   --  themselves. Replicate clamps, Reflect repeats the edge, Reflect_101
   --  does not repeat the edge, and Wrap is periodic. An out-of-range
   --  Constant_Border coordinate has no donor and returns Uses_Constant True;
   --  OpenCV's -1 sentinel is not exposed. This computes only a coordinate;
   --  it neither reads a Mat nor copies pixels. Extreme coordinates that would
   --  overflow OpenCV 4.10 signed arithmetic raise OpenCV_Error.
   function Border_Interpolate
     (Position : Point_Coordinate; Length : Positive; Kind : Border_Kind)
      return Border_Interpolation_Result;

   --  Separates Self into one independent single-channel Mat per channel.
   --  Results use channel indices 0 .. Self.Channels - 1, preserve Self's
   --  depth and dimensions, and do not share pixel storage with Self. Empty
   --  Mats return an empty Mat_Array. Single-channel Mats return one deep
   --  copy.
   --  Non-contiguous Regions and all supported Mat depths are accepted.
   function Split (Self : Mat) return Mat_Array;
   --  Returns an independent single-channel Mat containing the zero-based
   --  Channel of Self. Channel must be in 0 .. Self.Channels - 1. The result
   --  preserves Self's depth and dimensions, and does not share pixel storage
   --  with Self. Non-contiguous Regions and all supported Mat depths are
   --  accepted. An empty Mat accepts channel 0 and returns an empty,
   --  single-channel UInt8 Mat, matching OpenCV semantics.
   function Extract_Channel (Self : Mat; Channel : Natural) return Mat;
   --  Copies the single channel in Source into the zero-based Channel of Self.
   --  Source and Self must have identical dimensions and depth; Channel must
   --  be in 0 .. Self.Channels - 1. Self is modified in place, preserving its
   --  dimensions and element type. Non-contiguous Regions are accepted and
   --  retain normal shared-storage view semantics. Empty UInt8 single-channel
   --  Mats accept channel 0 as a no-op, matching OpenCV semantics.
   procedure Insert_Channel
     (Self : in out Mat; Source : Mat; Channel : Natural);
   --  Copies or zero-fills the specified channels into preallocated
   --  Destinations. Mat indices in Routes directly index the supplied arrays;
   --  their lower bounds need not be zero. All source and destination Mats
   --  must have identical dimensions and depth. A destination channel may
   --  occur in at most one route. Routes are applied in array iteration order.
   --  An empty Routes array is a no-op.
   procedure Mix_Channels
     (Sources      : Mat_Array;
      Destinations : in out Mat_Array;
      Routes       : Channel_Route_Array);
   --  Concatenates the channels of every non-empty input Mat, in array
   --  iteration order, into an independent Mat. Inputs may themselves be
   --  multi-channel, but must have identical dimensions and depth. The input
   --  array must not be empty and the total channel count must not exceed 512.
   function Merge (Channels : Mat_Array) return Mat;
   --  Copies Self into Destination, allocating or reallocating Destination to
   --  Self's shape and element type when necessary. Destination may be a
   --  compatible view. Exact self-copy is supported; partially overlapping
   --  source and destination storage is not supported by OpenCV.
   procedure Copy_To (Self : Mat; Destination : in out Mat);
   --  Copies elements selected by Mask into Destination. Mask uses the common
   --  mask contract (UInt8, one channel, same shape as Self). Any nonzero mask
   --  value selects the complete element, including every channel. Unselected
   --  elements retain their values in a compatible Destination; if Destination
   --  is allocated or reallocated, they are initialized to zero.
   procedure Copy_To (Self : Mat; Destination : in out Mat; Mask : Mat);
   function Convert_To
     (Self   : Mat;
      Depth  : Depth_Type;
      Scale  : Long_Float := 1.0;
      Offset : Long_Float := 0.0) return Mat;
   --  Returns an independent UInt8 Mat with Self's shape and channel count.
   --  Each channel is converted as saturate_cast<UInt8>
   --  (abs (Self * Scale + Offset)).
   function Convert_Scale_Abs
     (Self : Mat; Scale : Long_Float := 1.0; Offset : Long_Float := 0.0)
      return Mat;
   --  Applies a 256-entry lookup table to an 8-bit source. Self must have
   --  UInt8 or Int8 depth. Table must contain exactly 256 continuous
   --  elements and either one channel or the same channel count as Self.
   --  The result has Self's shape and channel count and Table's depth, and
   --  owns independent storage. Int8 sources are indexed by their stored
   --  8-bit pattern (0 .. 255), matching OpenCV 4.10.0. Float16 tables and
   --  16-bit sources are not supported. A 0x0 8-bit source produces a 0x0
   --  result; a default empty Mat is rejected by OpenCV.
   function Apply_LUT (Self : Mat; Table : Mat) return Mat;
   --  Returns an independent Mat with Self's shape, depth, and channel count.
   --  Self must be Float32 or Float64. Each channel is processed independently
   --  by cv::sqrt. On OpenCV 4.10 the 0.5-power HAL path uses std::sqrt, so
   --  negative finite values and -Infinity become NaN, +Infinity stays
   --  +Infinity, and a typed 0x0 source stays empty. A default empty Mat and
   --  non-floating depths are rejected.
   function Sqrt (Self : Mat) return Mat;
   --  Returns an independent Mat with Self's shape, depth, and channel count.
   --  Self must be Float32 or Float64. Each channel is processed independently
   --  by cv::exp. On OpenCV 4.10 the implementation is approximate (about
   --  7e-6 relative error for Float32 and less than 1e-10 for Float64) and
   --  may convert denormalized outputs to zero. Special values such as NaN
   --  and Infinity are not handled. A typed 0x0 source stays empty. A default
   --  empty Mat and non-floating depths are rejected.
   function Exp (Self : Mat) return Mat;
   --  Returns an independent Mat with Self's shape, depth, and channel count.
   --  Self must be Float32 or Float64. Each channel is processed independently
   --  by cv::log (natural logarithm). On OpenCV 4.10 the implementation is
   --  approximate. Output on zero, negative, and special values such as NaN
   --  and Infinity is undefined. A typed 0x0 source stays empty. A default
   --  empty Mat and non-floating depths are rejected.
   function Log (Self : Mat) return Mat;
   --  Returns an independent Mat with Self's shape, depth, and channel count.
   --  Each channel is processed independently by cv::pow. When Power is an
   --  integer, source signs are preserved (src(I) ** Power). When Power is
   --  not an integer, OpenCV documents abs (src(I)) ** Power and Self must
   --  be Float32 or Float64; on OpenCV 4.10 the general non-integer CPU path
   --  yields NaN for negative finite values. Nonnegative integer Power also
   --  supports UInt8, Int8, UInt16, Int16, and Int32. UInt8, Int8, UInt16,
   --  and Int16 results saturate; Int32 overflow is not saturated. Negative
   --  integer powers are accepted only for Float32 and Float64. Powers 0, 1,
   --  and 2 use specialized integer paths. Powers 0.5 and -0.5 use specialized
   --  square-root and inverse-square-root paths and require Float32 or
   --  Float64. Float16 is not supported. Special values such as NaN and
   --  Infinity are not handled. A typed 0x0 source stays empty. A default
   --  empty Mat is accepted for a nonnegative integer Power and rejected
   --  otherwise.
   function Pow (Self : Mat; Power : Long_Float) return Mat;
   --  Returns an independent Mat with X's shape, depth, and channel count.
   --  X and Y must be Float32 or Float64 with identical dimensions, depth,
   --  and channel count. Each channel is processed independently by
   --  cv::magnitude as sqrt (X**2 + Y**2). A typed 0x0 pair stays empty. A
   --  default empty Mat, mismatched shape or type, and non-floating depths
   --  including Float16 are rejected.

   function Magnitude (X, Y : Mat) return Mat;
   --  Returns an independent Mat with X's shape, depth, and channel count.
   --  X and Y are the Cartesian components of 2D vectors. They must be
   --  Float32 or Float64 with identical dimensions, depth, and channel
   --  count. Each channel is processed independently by cv::phase as
   --  atan2 (Y, X). Units selects radians in [0, 2*Pi) by default or
   --  degrees in [0, 360). OpenCV documents about 0.3 degrees of angle
   --  estimation accuracy. When both X and Y are zero, the angle is 0.
   --  A typed 0x0 pair stays empty. A default empty Mat, mismatched
   --  shape or type, and non-floating depths including Float16 are
   --  rejected.
   function Phase (X, Y : Mat; Units : Angle_Unit := Radians) return Mat;
   --  Returns independently owned Magnitude and Angle Mats with X's shape,
   --  depth, and channel count. X and Y are the Cartesian components of 2D
   --  vectors. They must be Float32 or Float64 with identical dimensions,
   --  depth, and channel count. Each channel is processed independently by
   --  a single cv::cartToPolar call. Magnitude is sqrt (X**2 + Y**2). Angle
   --  uses the same OpenCV fast-angle semantics as Phase. Units selects
   --  radians by default or degrees. OpenCV documents angles measured from
   --  0 to 2*Pi or 0 to 360 degrees, with about 0.3 degrees of angle
   --  estimation accuracy; the approximation does not guarantee a
   --  mathematically strict half-open range. When both X and Y are zero,
   --  Magnitude and Angle are 0. A typed 0x0 pair stays empty. A default
   --  empty Mat, mismatched shape or type, and non-floating depths
   --  including Float16 are rejected.
   function Cart_To_Polar
     (X, Y : Mat; Units : Angle_Unit := Radians) return Polar_Coordinates;
   --  Returns independently owned X and Y Mats with Angle's shape, depth,
   --  and channel count. Angle is the authoritative operand and must be
   --  Float32 or Float64. When Magnitude is non-empty, it must have the
   --  same dimensions, depth, and channel count as Angle. An empty
   --  Magnitude, or the one-argument overload, means unit magnitude for
   --  every Angle element. Each channel is processed independently by a
   --  single cv::polarToCart call. X is Magnitude * cos (Angle) and Y is
   --  Magnitude * sin (Angle). Units selects radians by default or
   --  degrees. OpenCV documents relative coordinate accuracy of about
   --  1e-6. There is no required Angle range. A typed 0x0 Angle stays
   --  empty. A default empty Angle is rejected. Float16 and other
   --  non-floating Angle depths are rejected.
   function Polar_To_Cart
     (Magnitude, Angle : Mat; Units : Angle_Unit := Radians)
      return Cartesian_Coordinates;
   function Polar_To_Cart
     (Angle : Mat; Units : Angle_Unit := Radians) return Cartesian_Coordinates;
   --  Returns an independently owned full-complex Discrete Fourier
   --  Transform of Self using OpenCV 4.10 cv::dft. This is not DCT,
   --  a packed CCS spectrum, a batched DFT_ROWS transform, or an
   --  in-place procedure. Self must be a non-empty 2-D Float32 or
   --  Float64 Mat with 1 or 2 channels. A 1 x N row, an N x 1
   --  column, and an ordinary M x N matrix are all transformed as
   --  2-D arrays of those dimensions; OpenCV's 1-D path is used
   --  only when the shape itself is a single row or column.
   --  Single-channel real input uses DFT_COMPLEX_OUTPUT so the
   --  result is an explicit C2 spectrum of the same rows, columns,
   --  and floating depth: channel 0 is the real part and channel 1
   --  is the imaginary part. Packed CCS output is not part of this
   --  API. Two-channel input is already complex and is transformed
   --  in place of that representation, returning C2 of the same
   --  shape and depth. Other channel counts are rejected rather
   --  than reinterpreted as complex. The forward transform is
   --  unscaled. Continuity is not required; non-contiguous Regions
   --  are supported. Self is unchanged. The result owns independent
   --  storage. Very large matrices whose dimensions would cause
   --  OpenCV 4.10's internal signed DFT arithmetic to overflow are
   --  rejected with OpenCV_Error. Rows * Columns must fit signed
   --  32-bit, and each transformed dimension must fit that same
   --  limit after multiplication by the full-complex element size
   --  (8 bytes for Float32, 16 bytes for Float64).
   function Discrete_Fourier_Transform (Self : Mat) return Mat;
   --  Returns an independently owned normalized inverse Discrete
   --  Fourier Transform of a full-complex spectrum using OpenCV
   --  4.10 cv::dft with DFT_INVERSE and DFT_SCALE. Self must be a
   --  non-empty 2-D Float32 or Float64 Mat with exactly 2 channels.
   --  Channel 0 is the real part and channel 1 is the imaginary
   --  part. The result has Self's rows, columns, depth, and 2
   --  channels. DFT_SCALE is always applied so that
   --  Inverse_Discrete_Fourier_Transform
   --  (Discrete_Fourier_Transform (Source)) approximately
   --  reproduces Source rather than Source * Rows * Columns.
   --  OpenCV's unscaled inverse is not the default Ada behavior.
   --  Continuity is not required; non-contiguous Regions are
   --  supported. Self is unchanged. The result owns independent
   --  storage. Very large matrices whose dimensions would cause
   --  OpenCV 4.10's internal signed DFT arithmetic to overflow are
   --  rejected with OpenCV_Error. Rows * Columns must fit signed
   --  32-bit, and each transformed dimension must fit that same
   --  limit after multiplication by the full-complex element size
   --  (8 bytes for Float32, 16 bytes for Float64).
   function Inverse_Discrete_Fourier_Transform (Self : Mat) return Mat;
   --  Returns an independently owned real inverse Discrete Fourier
   --  Transform of a full-complex spectrum using OpenCV 4.10
   --  cv::dft with DFT_INVERSE, DFT_SCALE, and DFT_REAL_OUTPUT.
   --  Self must be a non-empty 2-D Float32 or Float64 Mat with
   --  exactly 2 channels. The result has Self's rows, columns, and
   --  depth, and 1 channel. This is the natural inverse of
   --  Discrete_Fourier_Transform when the original source was real.
   --  DFT_REAL_OUTPUT assumes the input complex spectrum has the
   --  conjugate symmetry required for a real spatial-domain result.
   --  OpenCV 4.10 does not verify that symmetry, and this binding
   --  does not invent a numerical tolerance. A spectrum obtained
   --  from a real forward transform satisfies the assumption. A
   --  malformed arbitrary C2 input is a caller-precondition
   --  violation rather than a rejected argument, analogous to the
   --  symmetric-eigen policy. Continuity is not required;
   --  non-contiguous Regions are supported. Self is unchanged. The
   --  result owns independent storage. Very large matrices whose
   --  dimensions would cause OpenCV 4.10's internal signed DFT
   --  arithmetic to overflow are rejected with OpenCV_Error. Rows
   --  * Columns must fit signed 32-bit, and each transformed
   --  dimension must fit that same limit after multiplication by
   --  the full-complex element size (8 bytes for Float32, 16 bytes
   --  for Float64).
   function Inverse_Real_Discrete_Fourier_Transform (Self : Mat) return Mat;
   --  Returns an independently owned Discrete Cosine Transform of
   --  Self using OpenCV 4.10 cv::dct. This is not DFT, a packed CCS
   --  spectrum, a batched DCT_ROWS transform, or an in-place
   --  procedure. Self must be a non-empty 2-D Float32 or Float64 Mat
   --  with exactly one channel. OpenCV 4.10 treats 1 x 1 as an
   --  identity DCT. A 1 x N row or an N x 1 column with N > 1 is
   --  transformed as a 1-D vector and requires N even. An ordinary
   --  M x N matrix with M > 1 and N > 1 is transformed as 2-D and
   --  requires both M and N even. Odd transformed dimensions greater
   --  than one are rejected rather than padded. The result has Self's
   --  rows, columns, floating depth, and one channel. OpenCV's DCT
   --  uses its documented orthonormal cosine-transform convention, so
   --  Inverse_Discrete_Cosine_Transform
   --  (Discrete_Cosine_Transform (Source)) approximately reproduces
   --  Source without a caller scale factor. Continuity is not
   --  required; non-contiguous Regions are supported. Self is
   --  unchanged. The result owns independent storage. Very large
   --  matrices whose transformed dimensions would cause OpenCV
   --  4.10's internal signed DCT work-buffer arithmetic to overflow
   --  are rejected with OpenCV_Error. Each transformed dimension
   --  must fit signed 32-bit after multiplication by the complex
   --  element size used by the DCT DFT path (8 bytes for Float32,
   --  16 bytes for Float64).
   function Discrete_Cosine_Transform (Self : Mat) return Mat;
   --  Returns an independently owned inverse Discrete Cosine
   --  Transform of Self using OpenCV 4.10 cv::dct with DCT_INVERSE.
   --  Self must be a non-empty 2-D Float32 or Float64 Mat with
   --  exactly one channel and the same transform geometry as
   --  Discrete_Cosine_Transform, including the 1 x 1 identity case.
   --  The result has Self's rows, columns, floating depth, and one
   --  channel. Continuity is not required; non-contiguous Regions
   --  are supported. Self is unchanged. The result owns independent
   --  storage. Very large matrices whose transformed dimensions
   --  would cause OpenCV 4.10's internal signed DCT work-buffer
   --  arithmetic to overflow are rejected with OpenCV_Error.
   function Inverse_Discrete_Cosine_Transform (Self : Mat) return Mat;
   --  Returns an independently owned per-element product of two
   --  full-complex spectra using OpenCV 4.10 cv::mulSpectrums.
   --  Left and Right must be non-empty 2-D Float32 or Float64 Mats
   --  with exactly 2 channels, identical rows, identical columns,
   --  and identical depth. Channel 0 is the real part and channel 1
   --  is the imaginary part. Packed CCS C1 spectra are rejected
   --  even though OpenCV itself accepts them. Kind selects ordinary
   --  complex multiplication or multiplication by the conjugate of
   --  Right. Ordinary products participate in frequency-domain
   --  convolution; conjugate-right products participate in
   --  frequency-domain correlation. This operation does not
   --  transform, pad, scale, or invert; those remain caller
   --  operations. DFT_ROWS is not part of this API. Continuity is
   --  not required; non-contiguous Regions are supported. Left and
   --  Right are unchanged. The result has the same rows, columns,
   --  depth, and two channels, and owns independent storage.
   function Multiply_Spectra
     (Left  : Mat;
      Right : Mat;
      Kind  : Spectrum_Multiplication_Kind := Ordinary_Spectrum_Product)
      return Mat;

   --  Returns the smallest OpenCV-efficient DFT length N >=
   --  Minimum_Size using OpenCV 4.10 cv::getOptimalDFTSize. Efficient
   --  sizes are products of powers of 2, 3, and 5. This only selects
   --  an efficient length; it does not allocate a Mat or guarantee
   --  that Discrete_Fourier_Transform will accept a matrix of that
   --  size under the separate OpenCV 4.10 DFT signed-arithmetic
   --  safety limits. A request too close to INT_MAX raises
   --  OpenCV_Error because OpenCV returns a negative sentinel.
   function Optimal_DFT_Size (Minimum_Size : Positive) return Positive;

   --  Returns OpenCV 4.10's recommended efficient even DCT length
   --  N1 >= Minimum_Size using the documented relationship
   --  2 * Optimal_DFT_Size (ceil (Minimum_Size / 2)). The helper
   --  does not allocate or transform a Mat. It returns 2 for
   --  Minimum_Size = 1 even though OpenCV 4.10 supports a 1 x 1
   --  DCT as an identity; this function follows OpenCV's
   --  performance-sizing formula rather than reporting the
   --  minimum executable DCT size. The returned length does not
   --  imply that a Mat of that size passes the separate
   --  Float32/Float64 DCT arithmetic-safety limits.
   function Optimal_DCT_Size (Minimum_Size : Positive) return Positive;

   --  Returns an independent Mat with Self's shape and element type.  For L1,
   --  L2, and Infinity, Alpha is the target norm and Beta is ignored.  For
   --  Min_Max, Alpha and Beta specify the destination range bounds.
   function Normalize
     (Self  : Mat;
      Kind  : Normalize_Kind := L2;
      Alpha : Long_Float := 1.0;
      Beta  : Long_Float := 0.0) return Mat;
   --  Both operands must have identical 2D shape and element type.  Each
   --  result owns independent storage and preserves that element type.
   function Add (Left, Right : Mat) return Mat;
   function Subtract (Left, Right : Mat) return Mat;
   function Multiply (Left, Right : Mat) return Mat;
   function Divide (Left, Right : Mat) return Mat;
   function Abs_Diff (Left, Right : Mat) return Mat;
   function Minimum (Left, Right : Mat) return Mat;
   function Maximum (Left, Right : Mat) return Mat;
   function Add_Weighted
     (Left  : Mat;
      Alpha : Long_Float;
      Right : Mat;
      Beta  : Long_Float;
      Gamma : Long_Float := 0.0) return Mat;
   --  Returns an independent Mat with Self's shape and element type.
   --  Each element is Self * Scale + Right. Depths below Float32 use
   --  OpenCV's addWeighted path: UInt8, Int8, UInt16, and Int16 saturate;
   --  Int32 does not. Float32 and Float64 use the dedicated scaleAdd
   --  kernels. Float16 is not supported by OpenCV.
   --  Both operands must have identical 2D shape and element type.
   function Scale_Add (Self : Mat; Scale : Long_Float; Right : Mat) return Mat;

   function Bitwise_And (Left, Right : Mat) return Mat;
   function Bitwise_And (Left, Right, Mask : Mat) return Mat;
   function Bitwise_Or (Left, Right : Mat) return Mat;
   function Bitwise_Or (Left, Right, Mask : Mat) return Mat;
   function Bitwise_Xor (Left, Right : Mat) return Mat;
   function Bitwise_Xor (Left, Right, Mask : Mat) return Mat;
   function Bitwise_Not (Self : Mat) return Mat;
   function Bitwise_Not (Self, Mask : Mat) return Mat;
   function In_Range (Self : Mat; Lower, Upper : Scalar) return Mat;
   --  Returns an independent Mat rotated by Kind.  90-degree rotations
   --  exchange rows and columns; a half turn preserves dimensions and every
   --  variant preserves element depth and channel count.
   function Rotate (Self : Mat; Kind : Rotation_Kind) return Mat;
   --  Returns an independent Mat tiled vertically Row_Repetitions times and
   --  horizontally Column_Repetitions times. Element depth and channel count
   --  are preserved. Empty Mats produce an empty result.
   function Repeat
     (Self : Mat; Row_Repetitions : Positive; Column_Repetitions : Positive)
      return Mat;
   --  Concatenates Sources left to right into an independent Mat. Inputs must
   --  have identical row counts and complete element types. Their column
   --  counts may differ. An empty input array produces an empty Mat; empty
   --  individual Mats are accepted when they satisfy the same requirements.
   function HConcat (Sources : Mat_Array) return Mat;
   --  Concatenates Sources top to bottom into an independent Mat. Inputs must
   --  have identical column counts and complete element types. Their row
   --  counts may differ. An empty input array produces an empty Mat; empty
   --  individual Mats are accepted when they satisfy the same requirements.
   function VConcat (Sources : Mat_Array) return Mat;
   --  Both operands must be single-channel with identical rows, columns, and
   --  depth.  The result is an independent UInt8 single-channel mask with 255
   --  where the comparison is true and 0 otherwise, suitable for masked ops.
   function Compare (Left, Right : Mat; Kind : Comparison_Kind) return Mat;
   function Is_Empty (Self : Mat) return Boolean;
   function Rows (Self : Mat) return Natural;
   function Columns (Self : Mat) return Natural;

   --  Composed from the established column and row queries: Width = Columns,
   --  Height = Rows.  No separate C ABI accessor is required.
   function Dimensions (Self : Mat) return Size;
   function Channels (Self : Mat) return Channel_Count;
   function Depth (Self : Mat) return Depth_Type;
   function Total (Self : Mat) return Mat_Size;
   function Element_Size (Self : Mat) return Mat_Size;
   function Channel_Size (Self : Mat) return Mat_Size;
   function Is_Continuous (Self : Mat) return Boolean;
   function Is_Submatrix (Self : Mat) return Boolean;
   function Region (Self : Mat; Area : Rect) return Mat;

   --  These operations create distinct Mat headers sharing Self's storage.
   --  Index_Range uses its direct half-open [Start, Stop) representation.
   function Row_View (Self : Mat; Row : Size_Coordinate) return Mat;
   function Row_View (Self : Mat; Rows : Index_Range) return Mat;
   function Column_View (Self : Mat; Column : Size_Coordinate) return Mat;
   function Column_View (Self : Mat; Columns : Index_Range) return Mat;

   --  Sets the calling thread's OpenCV default RNG state. Reseeding that
   --  thread with the same Seed restarts its sequence. Fill_Uniform,
   --  Fill_Normal, and every other OpenCV operation that uses the default RNG
   --  (including K_Means when it consumes that RNG) advance this state. A call
   --  from another thread controls that other thread's independent RNG.
   procedure Set_Random_Seed (Seed : Interfaces.Integer_32);

   procedure Set_To (Self : in out Mat; Value : Scalar);
   --  Sets elements selected by Mask to Value. Mask uses the common mask
   --  contract (UInt8, one channel, same shape as Self). Any nonzero mask
   --  value selects the complete element, including every channel.
   procedure Set_To (Self : in out Mat; Value : Scalar; Mask : Mat);
   --  Fills Self in place from OpenCV's default RNG. Each channel uses its
   --  corresponding Scalar bound; generated values are lower-inclusive and
   --  upper-exclusive. Self must be non-empty and have 1 .. 4 channels.
   --  UInt8, Int8, UInt16, Int16, Int32, Float32, Float64, and Float16 are
   --  supported. Non-contiguous Regions are supported and remain Regions.
   procedure Fill_Uniform
     (Self : in out Mat; Lower_Bound, Upper_Bound : Scalar);
   --  Fills Self in place from OpenCV's default RNG using one Mean and
   --  Standard_Deviation per channel (the diagonal/vector form only). Self
   --  must be non-empty, have 1 .. 4 channels, and have depth UInt8, Int8,
   --  UInt16, Int16, Int32, Float32, or Float64. Integer results use OpenCV's
   --  saturating conversion/clipping. Float16 is unsupported. Non-contiguous
   --  Regions are supported and remain Regions.
   procedure Fill_Normal
     (Self : in out Mat; Mean : Scalar; Standard_Deviation : Scalar);
   --  Randomly permutes Self in place using the calling thread's OpenCV
   --  default RNG, which advances. Set_Random_Seed makes it reproducible
   --  on that thread. Self must be a non-empty 2-D row or column vector.
   --  Complete Mat elements are moved as units, so multi-channel elements keep
   --  their channels together. Valid non-contiguous vector Regions are
   --  supported and retain their shared storage. OpenCV 4.10 supports complete
   --  element sizes of only 1, 2, 3, 4, 6, 8, 12, 16, 24, and 32 bytes.
   --  The order may remain unchanged by chance. Iteration_Factor is not
   --  exposed because OpenCV 4.10's randShuffle implementation ignores it.
   procedure Shuffle (Self : in out Mat);
   function Sum (Self : Mat) return Scalar;
   --  Returns the per-channel sum of Self's main diagonal. Rectangular and
   --  empty Mats are accepted. Self must have at most four channels, matching
   --  Scalar's complete representation. Float16 Mats are not supported by
   --  OpenCV's trace implementation. Non-contiguous views are accepted.
   function Trace (Self : Mat) return Scalar;
   --  Returns the determinant of a non-empty square single-channel Mat as
   --  Long_Float. Self must be Float32 or Float64. 1x1 through 3x3 use
   --  OpenCV's direct formulas; larger matrices use OpenCV LU factorization
   --  with partial pivoting. Singular matrices return 0. Self is not
   --  modified. Non-contiguous Regions are supported. Empty Mats are
   --  rejected, including typed 0x0 matrices. Exact floating-point
   --  arithmetic is not promised for arbitrary matrices.
   function Determinant (Self : Mat) return Long_Float;
   --  Performs ordinary matrix inversion using OpenCV 4.10 DECOMP_LU.
   --  Self must be a non-empty square single-channel Float32 or Float64
   --  Mat. 1x1 through 3x3 use OpenCV's direct paths; larger matrices
   --  use OpenCV LU factorization. A non-singular matrix returns
   --  Invertible True and an Inverse with Self's depth and dimensions
   --  and independently owned storage. A singular matrix returns
   --  Invertible False and does not raise OpenCV_Error. Self is never
   --  modified. Non-contiguous Regions are supported. Empty Mats,
   --  including typed 0x0 matrices, rectangular Mats, multi-channel
   --  Mats, and unsupported depths are rejected. Numerical rounding is
   --  inherent in floating-point inversion.
   function Invert (Self : Mat) return Inversion_Result;
   --  Solves A * X = B using OpenCV 4.10 DECOMP_LU only. Self is the
   --  coefficient matrix A and must be a non-empty square single-channel
   --  Float32 or Float64 Mat. Right_Hand_Side is B and must be a
   --  non-empty single-channel Mat with Self's depth and row count.
   --  B may contain one or more columns. A unique solution returns
   --  Solved True and a Solution of shape Self.Columns x
   --  Right_Hand_Side.Columns with the same floating depth and
   --  independently owned storage. A singular A returns Solved False
   --  and does not raise OpenCV_Error; no Solution Mat is exposed.
   --  Both inputs remain unchanged. Non-contiguous Regions are
   --  accepted. This is not a least-squares or pseudo-solution API.
   --  Numerical rounding is inherent in floating-point solution.
   function Solve (Self : Mat; Right_Hand_Side : Mat) return Solve_Result;
   --  Finds distinct real roots with OpenCV 4.10 cv::solveCubic, unlike Solve
   --  which solves a linear system. Coefficients must be a non-empty,
   --  single-channel Float32 or Float64 vector of shape 1 x 3, 3 x 1, 1 x 4,
   --  or 4 x 1. Three coefficients represent x**3 + A*x**2 + B*x + C = 0;
   --  four represent A*x**3 + B*x**2 + C*x + D = 0. A zero leading A in the
   --  four-coefficient form is valid and reduces the equation to quadratic,
   --  linear, or constant. Status describes the mathematical root result;
   --  Roots is present only for a finite positive count, is independently
   --  owned, has the coefficient depth, and has only the Status-selected
   --  leading entries valid. Root ordering is not guaranteed. Coefficients
   --  are unchanged, and non-contiguous Regions are accepted.
   function Solve_Cubic (Coefficients : Mat) return Cubic_Solution_Result;
   function Solve_Polynomial
     (Coefficients : Mat; Maximum_Iterations : Positive := 300)
      return Polynomial_Solution_Result;
   --  Returns the scalar dot product of Self and Other as Long_Float,
   --  corresponding to OpenCV 4.10 cv::Mat::dot's double. This is the
   --  sum of every corresponding spatial-element and channel product.
   --  It is not algebraic Matrix_Multiply, not element-wise Multiply,
   --  and not a complex or Hermitian inner product. Self and Other
   --  must both be non-empty and must share identical Rows, Columns,
   --  Depth, and channel count. A 1x3 C1 Mat and a 3x1 C1 Mat are
   --  incompatible; shapes are not flattened. Supported depths are
   --  UInt8, Int8, UInt16, Int16, Int32, Float32, and Float64.
   --  Float16 is rejected. Multi-channel Mats are supported; every
   --  corresponding channel component is included. Two-channel values
   --  are ordinary scalar channels, unlike Matrix_Multiply which
   --  treats Float32/Float64 C2 as OpenCV complex matrices. Empty
   --  Mats, including typed 0x0 operands, are rejected. Continuity
   --  is not required; non-contiguous Regions are supported. Inputs
   --  are unchanged. Exact SIMD accumulation order and
   --  architecture-identical floating results are not promised.
   function Dot_Product (Self : Mat; Other : Mat) return Long_Float;
   --  Returns the scalar Mahalanobis distance of Self and Other as
   --  Long_Float, corresponding to OpenCV 4.10 cv::Mahalanobis's
   --  double. This is the weighted distance
   --  sqrt ((Self - Other)' * Inverse_Covariance * (Self - Other)).
   --  Self and Other are mathematical one-dimensional vectors: non-empty
   --  single-channel Float32 or Float64 row (1 x N) or column (N x 1)
   --  Mats with identical shape and complete type. A 1xN row and an Nx1
   --  column of the same length are incompatible; shapes are not
   --  flattened. An arbitrary M x N matrix is rejected even when
   --  OpenCV's implementation would treat width*height*channels as a
   --  vector. Inverse_Covariance must be a non-empty single-channel Mat
   --  with the same depth as the vectors and exactly N x N. Empty Mats,
   --  including typed empty vectors, integer depths, Float16, and
   --  multi-channel operands are rejected. Continuity is not required;
   --  non-contiguous Regions are supported. Inputs are unchanged.
   function Mahalanobis_Distance
     (Self : Mat; Other : Mat; Inverse_Covariance : Mat) return Long_Float;

   --  Returns the three-dimensional vector cross product Self x Other
   --  using OpenCV 4.10 cv::Mat::cross. This is not element-wise
   --  Multiply and not algebraic Matrix_Multiply. Operand order
   --  matters: reversing the operands negates the result. Self and
   --  Other must both be non-empty and must share identical Rows,
   --  Columns, Depth, and channel count. Each operand must be one
   --  three-component vector in exactly one of these representations:
   --  3x1 C1, 1x3 C1, or 1x1 C3. A 3x1 C1 Mat and a 1x3 C1 Mat are
   --  incompatible; shapes are not flattened. Unusual combinations
   --  that happen to contain three scalars, including 3x1 C3, are
   --  rejected. Supported depths are Float32 and Float64. Integer
   --  depths and Float16 are rejected. Empty Mats, including typed
   --  empty vectors, are rejected. Continuity is not required;
   --  non-contiguous Regions are supported. Inputs are unchanged.
   --  The independently owned result has Self's Rows, Columns, Depth,
   --  and channel count.
   function Cross_Product (Self : Mat; Other : Mat) return Mat;

   --  Performs algebraic matrix multiplication Result = Left * Right
   --  using OpenCV 4.10 cv::gemm. This is not the existing element-wise
   --  Multiply. Left.Columns must equal Right.Rows; the independently
   --  owned result has shape Left.Rows x Right.Columns and the same
   --  complete element type as both operands. Operands need not be
   --  square. Both operands must be non-empty and must share an
   --  identical complete element type of Float32 or Float64 with one
   --  channel (real) or two channels (complex). Two-channel values use
   --  OpenCV complex multiplication, with channel 0 as the real part
   --  and channel 1 as the imaginary part. Unsupported depths and
   --  other channel counts are rejected. Continuity is not required;
   --  non-contiguous Regions are supported. Inputs are unchanged.
   function Matrix_Multiply (Left, Right : Mat) return Mat;

   --  Computes Result = Product_Scale * Left * Right + Addend_Scale *
   --  Addend using OpenCV 4.10 cv::gemm. This is algebraic matrix
   --  multiplication followed by matrix addition. It is not the
   --  existing element-wise Multiply, Scale_Add, or Add_Weighted.
   --  Left.Columns must equal Right.Rows; Addend must have the exact
   --  product shape Left.Rows x Right.Columns. The independently owned
   --  result has that shape and the same complete element type as all
   --  three operands. Operands need not be square. All three operands
   --  must be non-empty and must share an identical complete element
   --  type of Float32 or Float64 with one channel (real) or two
   --  channels (complex). Two-channel values use OpenCV complex
   --  arithmetic, with channel 0 as the real part and channel 1 as the
   --  imaginary part. Product_Scale and Addend_Scale are real scalar
   --  weights. Addend is validated even when Addend_Scale is 0.0. No
   --  transpose behavior is part of this API. Unsupported depths and
   --  other channel counts are rejected. Continuity is not required;
   --  non-contiguous Regions are supported. Inputs are unchanged.
   --  Float32 scaling follows OpenCV's Float32 numerical behavior.
   function Matrix_Multiply_Add
     (Left, Right   : Mat;
      Addend        : Mat;
      Product_Scale : Long_Float := 1.0;
      Addend_Scale  : Long_Float := 1.0) return Mat;

   --  Computes the uncentered transposed product of Self using
   --  OpenCV 4.10 cv::mulTransposed with no Delta. Transpose_Times_Self
   --  computes Scale * Self'T * Self and yields a Self.Columns x
   --  Self.Columns result. Self_Times_Transpose computes Scale * Self
   --  * Self'T and yields a Self.Rows x Self.Rows result. Order has no
   --  default. Self must be non-empty and single-channel. Supported
   --  source depths are UInt8, UInt16, Int16, Float32, and Float64.
   --  Int8, Int32, Float16, and multi-channel Mats are rejected.
   --  Automatic output depth follows the OpenCV 4.10 implementation,
   --  not the documentation's dtype=-1 claim: Float64 sources produce
   --  Float64 and every other supported source produces Float32.
   --  Explicit Output_Depth may be Float32 or Float64. Float64 source
   --  with Float32 output is rejected because OpenCV 4.10 has no such
   --  kernel. Scale is applied to the complete product and may be
   --  positive, zero, negative, or fractional. The result is
   --  symmetric, owns independent storage, and does not modify Self.
   --  Continuity is not required; non-contiguous Regions are
   --  supported. Delta/centering is not part of this API.
   function Transposed_Product
     (Self : Mat; Order : Transposed_Product_Order; Scale : Long_Float := 1.0)
      return Mat;
   function Transposed_Product
     (Self         : Mat;
      Order        : Transposed_Product_Order;
      Output_Depth : Depth_Type;
      Scale        : Long_Float := 1.0) return Mat;

   --  Computes the centered transposed product of Self using
   --  OpenCV 4.10 cv::mulTransposed with a required non-empty Offset
   --  (OpenCV's delta). Offset is subtracted, with OpenCV
   --  broadcasting, before the product. Transpose_Times_Self computes
   --  Scale * (Self - Offset)'T * (Self - Offset) and yields a
   --  Self.Columns x Self.Columns result. Self_Times_Transpose
   --  computes Scale * (Self - Offset) * (Self - Offset)'T and yields
   --  a Self.Rows x Self.Rows result. Order has no default. Offset
   --  must be non-empty; a default empty Mat or typed 0x0 Mat is
   --  rejected rather than treated as the uncentered form. Accepted
   --  Offset shapes for Self M x N are M x N, 1 x N, M x 1, and 1 x 1.
   --  Self and Offset must each be single-channel. Self keeps the
   --  uncentered source-depth contract: UInt8, UInt16, Int16,
   --  Float32, or Float64. Offset may be UInt8, Int8, UInt16, Int16,
   --  Int32, Float32, or Float64; Float16 Offset is rejected. OpenCV
   --  converts Offset to the effective computation depth. Automatic
   --  output is Float64 when Self or Offset is Float64 and Float32
   --  otherwise. Explicit Float32 rejects Float64 Self or Offset so
   --  the returned Mat is actually Float32. Explicit Float64 accepts
   --  every supported Self/Offset combination. Scale is applied to the
   --  completed centered product. Continuity is not required.
   --  Inputs remain unchanged. The result owns independent storage.
   --  This is a general centered transposed product; covariance
   --  construction is one use, not the only meaning. The formal is
   --  named Offset because Ada reserves Delta.
   function Transposed_Product
     (Self   : Mat;
      Offset : Mat;
      Order  : Transposed_Product_Order;
      Scale  : Long_Float := 1.0) return Mat;
   function Transposed_Product
     (Self         : Mat;
      Offset       : Mat;
      Order        : Transposed_Product_Order;
      Output_Depth : Depth_Type;
      Scale        : Long_Float := 1.0) return Mat;

   --  Calculates the normal feature covariance matrix and mean of
   --  Self using OpenCV 4.10 cv::calcCovarMatrix. Self is a 2-D
   --  single-channel sample matrix. Samples_Are_Rows, the default,
   --  treats an M x N Mat as M samples of N features: Mean is 1 x N
   --  and Covariance is N x N. Samples_Are_Columns treats an M x N
   --  Mat as N samples of M features: Mean is M x 1 and Covariance
   --  is M x M. The scrambled/sample-space covariance form is not
   --  part of this API. OpenCV always computes Mean; a caller-
   --  supplied average is not accepted. Unscaled returns the raw
   --  centered accumulation. By_Sample_Count, the default, divides
   --  that accumulation by the selected sample count N. That factor
   --  is 1/N, matching OpenCV COVAR_SCALE; it is not 1/(N - 1) and
   --  is not unbiased sample covariance. Self must be non-empty and
   --  Float32 or Float64. The selected orientation must contain at
   --  least one sample. Multi-channel Mats, integer depths, and
   --  Float16 are rejected. Output Covariance and Mean preserve
   --  Self's floating-point depth and are independently owned. The
   --  caller does not preallocate either output. Continuity is not
   --  required; non-contiguous Regions are supported. Self is
   --  unchanged.
   function Covariance
     (Self        : Mat;
      Orientation : Sample_Orientation := Samples_Are_Rows;
      Scaling     : Covariance_Scaling := By_Sample_Count)
      return Covariance_Result;

   --  Decomposes a real symmetric matrix using OpenCV 4.10 cv::eigen.
   --  Self must be a non-empty square single-channel Float32 or
   --  Float64 Mat that represents a real symmetric matrix. This is
   --  not PCA, SVD, or a non-symmetric eigen solver. OpenCV 4.10
   --  does not validate symmetry and defines no symmetry
   --  tolerance. Its symmetric eigensolver backends assume
   --  self-adjoint input rather than comparing Self with its
   --  transpose. A non-symmetric input is therefore a
   --  caller-precondition violation and may produce misleading
   --  output rather than a rejection. This binding does not invent a
   --  floating-point symmetry check. Multi-channel Mats, integer
   --  depths, and Float16 are rejected. The matrix dimension N must
   --  not exceed 8_460. OpenCV 4.10's fallback symmetric eigensolver
   --  computes an internal iteration bound using signed integer
   --  arithmetic that is not safe for larger dimensions. Outputs
   --  preserve Self's floating-point depth. For an N x N source,
   --  Eigenvalues is N x 1 with values stored from largest to
   --  smallest, and Eigenvectors is N x N with one eigenvector per
   --  row so that row i corresponds
   --  to eigenvalue i. Eigenvector sign is mathematically arbitrary:
   --  v and -v represent the same eigenvector. Both OpenCV 4.10
   --  backends produce orthonormal eigenvectors; a repeated
   --  eigenspace does not have a unique basis. Continuity is not
   --  required; non-contiguous Regions are supported. Self is
   --  unchanged. Both outputs are independently owned. The caller
   --  does not preallocate either output. A valid matrix satisfying

   --  this contract yields a populated result. An OpenCV numerical
   --  failure (cv::eigen returning false) raises OpenCV_Error rather
   --  than exposing a Boolean.
   function Eigen_Decomposition (Self : Mat) return Eigen_Decomposition_Result;

   --  Computes the real non-symmetric eigendecomposition using OpenCV 4.10
   --  cv::eigenNonSymmetric. Self must be a non-empty square Float32 or
   --  Float64 single-channel Mat with dimension at most 2_147_483. Unlike
   --  Eigen_Decomposition, symmetry is not required. All eigenvalues must be
   --  real; this is an OpenCV caller precondition, and this binding does not
   --  invent a numerical complex-eigenvalue detector. Eigenvalues are ordered
   --  from largest to smallest, and each corresponding eigenvector is stored
   --  in a row. Eigenvector sign is arbitrary, and repeated eigenspaces need
   --  not have unique bases. Non-contiguous Regions are supported. Self is
   --  unchanged; both result Mats are independently owned and independent of
   --  Self and each other.
   function Non_Symmetric_Eigen_Decomposition
     (Self : Mat) return Eigen_Decomposition_Result;

   --  Computes a supervised Linear Discriminant Analysis basis using OpenCV
   --  4.10 cv::LDA. Samples is an N x D row-aligned matrix: each row is one
   --  observation and each column is one feature. Samples must be non-empty,
   --  single-channel, Float32 or Float64, and finite. Labels must be a
   --  non-empty Int32 C1 row (1 x N) or column (N x 1) vector. Arbitrary
   --  signed Int32 label values are accepted, but at least two distinct
   --  classes are required. Inputs are unchanged and non-contiguous Regions
   --  are supported.
   --
   --  The result is always Float64: Eigenvalues is K x 1 and Eigenvectors is
   --  D x K, with discriminant directions stored by column, so Samples *
   --  Eigenvectors projects row-aligned samples. Eigenvalues are descending;
   --  eigenvector signs are arbitrary. The automatic count is
   --  K = min (class count - 1, D). The explicit overload requires Components
   --  not exceed that value. This computes a discriminant subspace, not a
   --  classifier, and does not add projection or reconstruction wrappers.
   --  Singular or ill-conditioned within-class scatter can yield degenerate
   --  numerical results under OpenCV 4.10. OpenCV warns to stdout when N < D;
   --  this binding preserves that native behavior rather than rejecting it.
   --  D must not exceed 8460 because OpenCV 4.10's internal LDA eigensolver
   --  can use either a non-symmetric path or the symmetric cv::eigen fallback;
   --  this signed-arithmetic safety limit covers both paths.
   function Linear_Discriminant_Analysis
     (Samples : Mat; Labels : Mat) return Linear_Discriminant_Analysis_Result;

   function Linear_Discriminant_Analysis
     (Samples : Mat; Labels : Mat; Components : Positive)
      return Linear_Discriminant_Analysis_Result;

   --  Computes the default compact/economy SVD of Self using OpenCV
   --  4.10 cv::SVD::compute with flags = 0. This is not PCA, a
   --  symmetric eigen solver, or a full-size SVD. Self is treated as
   --  the mathematical matrix A exactly as stored; no orientation
   --  parameter is required. The decomposition satisfies
   --  A ~= U * diag (Singular_Values) * V_Transpose subject to
   --  ordinary floating-point rounding. Let R = min (Rows, Columns).
   --  Singular_Values is R x 1, U is Rows x R, and V_Transpose is
   --  R x Columns. Those compact shapes apply to tall, square, and
   --  wide matrices. Singular values are nonnegative and sorted from
   --  largest to smallest. Self must be a non-empty single-channel
   --  Float32 or Float64 Mat. Multi-channel Mats, integer depths, and
   --  Float16 are rejected. Square shape, full rank, and
   --  nonsingularity are not required. Rank-deficient matrices and
   --  zero singular values are valid. Singular-vector signs are
   --  arbitrary: corresponding columns of U and rows of V_Transpose
   --  may simultaneously change sign. A repeated or zero singular
   --  value does not have a unique basis within its singular
   --  subspace. Outputs preserve Self's floating-point depth and are
   --  independently owned. The caller does not preallocate any
   --  output. Continuity is not required; non-contiguous Regions are
   --  supported. Self is unchanged.
   function Singular_Value_Decomposition
     (Self : Mat) return Singular_Value_Decomposition_Result;

   --  Solves A * X ~= Right_Hand_Side from an already computed
   --  compact SVD basis using OpenCV 4.10 cv::SVD::backSubst. This
   --  does not recompute the SVD, does not reconstruct A, and does
   --  not expose cv::SVD. The mathematical operation is
   --  X ~= V * diag (W)^+ * U^T * Right_Hand_Side, where the
   --  reciprocal of sufficiently small singular values is omitted
   --  according to OpenCV 4.10's internal threshold. There is no
   --  caller-configurable tolerance. For a full-rank square system
   --  this behaves like solving A * X = B. For an overdetermined
   --  system (M > N) it returns the SVD least-squares solution. For
   --  an underdetermined system (M < N) it returns the SVD
   --  minimum-norm solution. Rank-deficient bases are accepted;
   --  near-zero singular directions are discarded by OpenCV rather
   --  than rejected here. Basis is a publicly constructible record,
   --  so its compact structure is validated before the ABI. Let
   --  M = Basis.U.Rows, N = Basis.V_Transpose.Columns, and
   --  R = Basis.Singular_Values.Rows. Singular_Values must be a
   --  non-empty single-channel Float32 or Float64 R x 1 column with
   --  R >= 1. U must be a non-empty single-channel Mat of the same
   --  depth and shape M x R with M >= 1. V_Transpose must be a
   --  non-empty single-channel Mat of the same depth and shape
   --  R x N with N >= 1. The compact identity R = min (M, N) is
   --  required; FULL_UV layouts are rejected. Right_Hand_Side must
   --  be a non-empty single-channel Mat of the same depth, M rows,
   --  and K >= 1 columns. Empty RHS is rejected; this is not a
   --  pseudoinverse API. Depths are not converted: Float32 Basis
   --  plus Float32 RHS yields a Float32 result, and Float64 Basis
   --  plus Float64 RHS yields a Float64 result. The independently
   --  owned result has shape N x K. The products N * K and M * R
   --  must not exceed 2_147_483_647 because OpenCV 4.10 forms
   --  destination and U element addresses with signed int index
   --  arithmetic. Continuity is not required; ordinary
   --  non-contiguous Regions are supported subject to OpenCV 4.10's
   --  signed-index limits on inherited physical row strides. Basis
   --  fields and Right_Hand_Side are unchanged.
   function SVD_Back_Substitute
     (Basis : Singular_Value_Decomposition_Result; Right_Hand_Side : Mat)
      return Mat;

   --  Returns the Moore-Penrose pseudoinverse of Self using compact
   --  OpenCV 4.10 SVD and empty-RHS SVD back substitution. This is
   --  not Invert, Solve, or a caller-tunable rank decision. Self of
   --  shape M x N yields an independently owned N x M result with
   --  Self's floating depth and one channel. Self must be a
   --  non-empty single-channel Float32 or Float64 Mat. Multi-channel
   --  Mats, integer depths, and Float16 are rejected. Square,
   --  tall, and wide shapes are supported. Full rank and
   --  nonsingularity are not required. Rank-deficient matrices and
   --  the zero matrix are valid. Numerical rank follows OpenCV
   --  4.10's SVD back-substitution threshold; there is no caller
   --  tolerance. For a square nonsingular matrix the result agrees
   --  numerically with Invert.Inverse subject to ordinary
   --  floating-point rounding. Continuity is not required;
   --  non-contiguous Regions are supported. The product
   --  Self.Rows * Self.Columns must not exceed 2_147_483_647
   --  because OpenCV 4.10 forms the packed N x M destination
   --  address with signed int index arithmetic. Self is unchanged.
   function Pseudo_Inverse (Self : Mat) return Mat;

   --  Returns the reciprocal 2-norm condition number of Self:
   --  sigma_min / sigma_max. Singular values come from OpenCV 4.10
   --  SVD. Compact rank is R = min (Rows, Columns), so the values
   --  are sigma_1 >= ... >= sigma_R >= 0 and the result is
   --  sigma_R / sigma_1 when sigma_1 > 0. A result of 1.0 means
   --  well / perfectly conditioned. Values approaching 0 indicate
   --  ill conditioning. If the largest singular value is exactly 0,
   --  the result is 0.0 rather than 0 / 0. Singular and zero
   --  matrices are valid and return 0.0 when the smallest singular
   --  value is zero. Square, tall, and wide matrices are supported.
   --  Self must be a non-empty single-channel Float32 or Float64
   --  Mat. Multi-channel Mats, integer depths, and Float16 are
   --  rejected. Computation uses singular values only; U and
   --  V_Transpose are not required. The result is scale invariant
   --  subject to floating-point representability and rounding:
   --  rcond (c * A) = rcond (A) for nonzero scalar c. This is the
   --  ratio of the singular values OpenCV actually computes, not
   --  the pseudoinverse / SVD back-substitution numerical-rank
   --  threshold and not cv::invert (DECOMP_SVD)'s scale-dependent
   --  return metric. There is no caller tolerance. Continuity is
   --  not required; non-contiguous Regions are supported. Self is
   --  unchanged. Ordinary floating-point rounding applies.
   function Reciprocal_Condition_Number (Self : Mat) return Long_Float;

   --  Returns an independently owned unit-length N x 1 vector minimizing
   --  ||Self * X|| for an M x N source, directly using OpenCV 4.10
   --  cv::SVD::solveZ. This is an SVD null/minimum-residual vector, not an
   --  ordinary linear-system solution. For a nontrivial null space it is a
   --  null-space direction and Self * X is approximately zero; otherwise it
   --  is the right singular vector for the smallest singular value. Its sign
   --  is arbitrary. Self must be non-empty Float32 or Float64 C1; square,
   --  tall, and wide Mats are accepted, including non-contiguous Regions.
   --  Wide Mats use OpenCV's internal FULL_UV behavior to obtain the complete
   --  right-singular basis. Otherwise valid inputs are rejected when OpenCV
   --  4.10's internal SVD temporary-workspace arithmetic would overflow the
   --  host allocation size. Self is unchanged, and there is no caller
   --  tolerance.
   function SVD_Solve_Zero (Self : Mat) return Mat;

   --  Computes the PCA basis of Self using OpenCV 4.10 cv::PCA.
   --  Self is a 2-D single-channel sample matrix. Samples_Are_Rows,
   --  the default, treats an M x N Mat as M samples of N features:
   --  Mean is 1 x N. Samples_Are_Columns treats an M x N Mat as N
   --  samples of M features: Mean is M x 1. Available component
   --  count K_all is min (sample count, feature count). The
   --  no-Components overload retains every OpenCV PCA component, so
   --  K = K_all. That is the number OpenCV computes, not necessarily
   --  the numerical rank, and zero-variance components may be
   --  present. The Components overload requests exactly that many
   --  leading components: 1 <= Components <= K_all. Excess requests
   --  raise OpenCV_Error rather than silently clamping. The
   --  Retained_Variance overload asks OpenCV 4.10 to choose K from a
   --  variance fraction: 0.95 means 95 percent, not 95.0. Valid
   --  values satisfy 0.0 < Retained_Variance <= 1.0; NaN is
   --  rejected. OpenCV 4.10 computes the full eigenvalue set, then
   --  retains rowRange(0, L) after breaking at the first cumulative
   --  energy that is strictly greater than Retained_Variance. The
   --  component that first exceeded the threshold is therefore not
   --  included, so the returned basis is not guaranteed in every
   --  case to represent at least the requested fraction. This is
   --  OpenCV 4.10 behavior. Retained_Variance = 1.0 cannot satisfy
   --  energy > 1.0 for ordinary positive-total-variance input, so
   --  OpenCV retains every available component. The overload always
   --  keeps at least two components and therefore requires
   --  Available_Components >= 2. A one-component source is rejected
   --  here because OpenCV 4.10's retained-variance implementation
   --  would then attempt rowRange(0, 2) on a one-row eigen result.
   --  The all-components and Components overloads continue to
   --  support one-component PCA. Zero-total-variance input can
   --  produce 0/0 in OpenCV's cumulative-energy ratio and is outside
   --  this binding's stronger public numerical guarantees. For K
   --  retained components, Eigenvalues is K x 1 in descending order
   --  and Eigenvectors is K x Feature_Count with one principal
   --  direction per row. Eigenvector sign is mathematically
   --  arbitrary: v and -v represent the same direction. OpenCV PCA
   --  uses scaled covariance with the population-style 1/N
   --  convention (COVAR_SCALE), not unbiased 1/(N - 1). When
   --  feature count exceeds sample count, OpenCV may compute a
   --  smaller sample-space covariance internally; the public result
   --  is always expressed in feature space. Rank-deficient data and
   --  zero eigenvalues are allowed. Self must be non-empty and
   --  Float32 or Float64. Multi-channel Mats, integer depths, and
   --  Float16 are rejected. Sample count and feature count must both
   --  be nonzero. Available component count must not exceed 8_460
   --  because OpenCV 4.10's fallback symmetric eigensolver computes
   --  an internal iteration bound using signed integer arithmetic
   --  that is not safe for larger covariance dimensions. This limit
   --  applies even when Components is 1, because OpenCV computes the
   --  full covariance eigen decomposition before truncating.
   --  Outputs preserve Self's floating-point depth and are
   --  independently owned. The caller does not preallocate any
   --  output. Continuity is not required; non-contiguous Regions are
   --  supported. Self is unchanged. Finite sample values are a
   --  caller precondition: this binding does not replace NaN or
   --  Infinity, and OpenCV's eigen path is not specified for
   --  non-finite input.
   function Principal_Component_Analysis
     (Self : Mat; Orientation : Sample_Orientation := Samples_Are_Rows)
      return Principal_Component_Analysis_Result;
   function Principal_Component_Analysis
     (Self        : Mat;
      Components  : Positive;
      Orientation : Sample_Orientation := Samples_Are_Rows)
      return Principal_Component_Analysis_Result;
   function Principal_Component_Analysis
     (Self              : Mat;
      Retained_Variance : Long_Float;
      Orientation       : Sample_Orientation := Samples_Are_Rows)
      return Principal_Component_Analysis_Result;

   --  Projects Self onto an already computed PCA basis. This does
   --  not recompute Principal_Component_Analysis. Self is a 2-D
   --  single-channel sample matrix of new or existing observations.
   --  Orientation must match the layout used to produce Basis and
   --  is not inferred from Basis.Mean: a one-feature column mean is
   --  1 x 1 and is therefore ambiguous. Samples_Are_Rows, the
   --  default, requires Basis.Mean = 1 x F and Self = S x F, and
   --  returns S x K. Samples_Are_Columns requires Basis.Mean =
   --  F x 1 and Self = F x S, and returns K x S. K is
   --  Basis.Eigenvectors.Rows and F is Basis.Eigenvectors.Columns.
   --  Self must be non-empty and Float32 or Float64. Multi-channel
   --  Mats, integer depths, and Float16 are rejected. Self's
   --  floating-point depth may differ from Basis.Mean; OpenCV
   --  converts the samples to the basis precision internally. The
   --  independently owned result has Basis.Mean.Depth. Basis.Mean
   --  must be non-empty, single-channel, and Float32 or Float64.
   --  Basis.Eigenvectors must be non-empty, single-channel, the
   --  same depth as Basis.Mean, and K x F with 1 <= K <= F.
   --  Basis.Eigenvalues is not used. Continuity is not required;
   --  non-contiguous Regions are supported. Self and Basis are
   --  unchanged. Finite sample values are a caller precondition:
   --  this binding does not replace NaN or Infinity.
   function PCA_Project
     (Self        : Mat;
      Basis       : Principal_Component_Analysis_Result;
      Orientation : Sample_Orientation := Samples_Are_Rows) return Mat;

   --  Reconstructs feature-space samples from principal-component
   --  coordinates using an already computed PCA basis. This does
   --  not recompute Principal_Component_Analysis. Self is a 2-D
   --  single-channel coordinate matrix. Orientation must match the
   --  layout used to produce Basis and is not inferred from
   --  Basis.Mean: a one-feature column mean is 1 x 1 and is
   --  therefore ambiguous. Samples_Are_Rows, the default, requires
   --  Basis.Mean = 1 x F and Self = S x K, and returns S x F.
   --  Samples_Are_Columns requires Basis.Mean = F x 1 and Self =
   --  K x S, and returns F x S. K is Basis.Eigenvectors.Rows and
   --  F is Basis.Eigenvectors.Columns. Self must be non-empty and
   --  Float32 or Float64. Multi-channel Mats, integer depths, and
   --  Float16 are rejected. Self's floating-point depth may differ
   --  from Basis.Mean; OpenCV converts the coordinates to the
   --  basis precision internally. The independently owned result
   --  has Basis.Mean.Depth. Basis.Mean and Basis.Eigenvectors must
   --  satisfy the same structural contract as PCA_Project.
   --  Basis.Eigenvalues is not used. Continuity is not required;
   --  non-contiguous Regions are supported. Self and Basis are
   --  unchanged. Finite coordinate values are a caller
   --  precondition: this binding does not replace NaN or Infinity.
   function PCA_Back_Project
     (Self        : Mat;
      Basis       : Principal_Component_Analysis_Result;
      Orientation : Sample_Orientation := Samples_Are_Rows) return Mat;

   --  Interprets each Self element as its channel vector and applies
   --  OpenCV 4.10 cv::transform. This is a per-element channel/vector
   --  transform at the same spatial location; it does not geometrically
   --  move pixels. Coefficients.Rows determines the result channel
   --  count. An M x N coefficient Mat, where N is Self.Channels,
   --  performs the linear transform Result(I) = Coefficients * Self(I).
   --  An M x (N+1) coefficient Mat performs the affine transform
   --  Result(I) = Coefficients * [Self(I); 1], so the final column is
   --  additive bias. The result preserves Self's rows, columns, and
   --  depth. Self must be non-empty, at most two-dimensional, and have
   --  1 to 4 channels. Result channels may be 1 to 512. Supported
   --  source depths are UInt8, Int8, UInt16, Int16, Int32, Float32, and
   --  Float64. Float16 is rejected because OpenCV 4.10 has no
   --  TransformFunc for CV_16F. Coefficients must be a non-empty
   --  single-channel Float32 or Float64 Mat with at least one and at
   --  most 512 rows and either Self.Channels or Self.Channels + 1
   --  columns. Integer coefficient Mats are rejected. OpenCV internally
   --  represents coefficients as Float32 for UInt8, Int8, UInt16,
   --  Int16, and Float32 sources, and as Float64 for Int32 and Float64
   --  sources; a Float64 coefficient Mat used with a Float32 source is
   --  therefore converted internally to Float32, and a Float32
   --  coefficient Mat used with Int32 or Float64 Self is converted
   --  internally to Float64. Integer output conversion follows OpenCV's
   --  native saturate_cast / rounding rules. Continuity is not
   --  required; non-contiguous Regions are supported for both Self and
   --  Coefficients. Inputs are unchanged. The result owns independent
   --  storage.
   function Transform (Self : Mat; Coefficients : Mat) return Mat;

   --  Interprets each Self element as a 2D or 3D vector and applies
   --  OpenCV 4.10 cv::perspectiveTransform. This transforms vector
   --  coordinates at each Mat element. It does not spatially resample,
   --  warp, interpolate, or move pixels in an image; that operation is
   --  imgproc warpPerspective. Self must be a non-empty Float32 or
   --  Float64 Mat with at most two dimensions and exactly 2 or 3
   --  channels. C1, C4 and larger, and every non-floating depth
   --  including Float16, are rejected. Transform_Matrix must be a
   --  non-empty single-channel Float32 or Float64 Mat with at most two
   --  dimensions. A C2 source requires a 3x3 matrix. A C3 source
   --  requires a 4x4 matrix. Other matrix sizes, including the internal
   --  OpenCV C3-to-C2 3x4 path, are not part of this API. The result
   --  preserves Self's rows, columns, depth, and channels. OpenCV
   --  performs the homogeneous division. When abs(w) <= FLT_EPSILON,
   --  OpenCV 4.10 writes a zero vector; the same FLT_EPSILON threshold
   --  is used for Float32 and Float64 sources. OpenCV converts a
   --  non-continuous or non-Float64 matrix to an internal Float64
   --  coefficient buffer; this binding does not pre-convert it.
   --  Continuity is not required; non-contiguous Regions are supported
   --  for both Self and Transform_Matrix. Inputs are unchanged. The
   --  result owns independent storage.
   function Perspective_Transform
     (Self : Mat; Transform_Matrix : Mat) return Mat;

   --  Reduces a two-dimensional Mat independently in every channel.
   --  Across_Rows
   --  produces one row; Across_Columns produces one column. The result owns
   --  independent storage. Without Output_Depth, OpenCV uses Self's depth.
   --  Maximum and Minimum require their output depth to equal Self.Depth.
   function Reduce
     (Self : Mat; Axis : Reduction_Axis; Kind : Reduction_Kind) return Mat;
   function Reduce
     (Self         : Mat;
      Axis         : Reduction_Axis;
      Kind         : Reduction_Kind;
      Output_Depth : Depth_Type) return Mat;
   --  Returns independently owned CV_32SC1 index Mats. Indices are zero-based
   --  along Axis: Across_Rows produces 1 x Self.Columns row indices, while
   --  Across_Columns produces Self.Rows x 1 column indices. Self must be
   --  non-empty and single-channel; supported depths are UInt8, Int8, UInt16,
   --  Int16, Int32, Float32, and Float64. Float16 is not dispatched by the
   --  OpenCV 4.10 implementation. Equal
   --  extrema select the first or last occurrence as requested. Non-contiguous
   --  Regions are supported, Self is unchanged, and results do not share its
   --  storage. OpenCV leaves behavior unspecified when Float32 or Float64 NaN
   --  values participate in the reduction.
   function Arg_Minimum
     (Self       : Mat;
      Axis       : Reduction_Axis;
      Occurrence : Extremum_Occurrence := First_Occurrence) return Mat;
   function Arg_Maximum
     (Self       : Mat;
      Axis       : Reduction_Axis;
      Occurrence : Extremum_Occurrence := First_Occurrence) return Mat;
   --  Both reductions operate independently on each channel.  They support
   --  one through four channels, matching Scalar's complete representation.
   --  Mean returns a zero Scalar for an empty Mat; Mean_Std_Dev rejects one.
   function Mean (Self : Mat) return Scalar;
   --  Mean of Self elements selected by Mask. Mask uses the common mask
   --  contract (UInt8, one channel, same shape as Self). Any nonzero mask
   --  value selects the element. An all-zero mask returns a zero Scalar.
   --  Empty Self/Mask follow OpenCV mean semantics (zero Scalar).
   function Mean (Self, Mask : Mat) return Scalar;
   function Mean_Std_Dev (Self : Mat) return Mean_Std_Dev_Result;
   --  Per-channel mean and population standard deviation of Self elements
   --  selected by Mask. Mask uses the common mask contract. Any nonzero mask
   --  value selects the element. An all-zero mask returns zero mean and
   --  standard-deviation Scalars. Empty Self/Mask is rejected.
   function Mean_Std_Dev (Self, Mask : Mat) return Mean_Std_Dev_Result;
   function Norm (Self : Mat; Kind : Norm_Kind := L2) return Long_Float;
   --  Computes the requested norm over elements selected by Mask. Mask uses
   --  the common mask contract (UInt8, one channel, same shape as Self). Any
   --  nonzero mask value selects every scalar component of the element. Empty
   --  Self/Mask and all-zero masks return zero according to OpenCV semantics.
   function Norm
     (Self : Mat; Mask : Mat; Kind : Norm_Kind := L2) return Long_Float;

   --  Computes OpenCV 4.10 cv::PSNR in decibels over every scalar channel
   --  component. Left and Right must be non-empty and have identical rows,
   --  columns, depth, and channel count. All public Mat depths, including
   --  Float16, and all channel counts are supported. Continuity is not
   --  required, so matching non-contiguous Regions are accepted. Peak_Value,
   --  OpenCV's R parameter, defaults to 255.0 and must be positive, finite,
   --  and representable as a C double. OpenCV computes
   --    20 * log10 (Peak_Value / (RMSE + DBL_EPSILON));
   --  consequently identical inputs return a large finite value rather than
   --  infinity. Inputs are unchanged. OpenCV itself would produce non-finite
   --  results for zero, negative, or non-finite peak values; this Ada API
   --  rejects those values.
   function Peak_Signal_To_Noise_Ratio
     (Left : Mat; Right : Mat; Peak_Value : Long_Float := 255.0)
      return Long_Float;

   function Min_Max_Loc (Self : Mat) return Min_Max_Result;
   --  Finds extrema among Self elements selected by Mask. Mask uses the
   --  common mask contract. Any nonzero mask value selects the element. An
   --  all-zero mask returns zero extrema and (-1, -1) locations. Point.X is
   --  the column and Point.Y is the row.
   function Min_Max_Loc (Self, Mask : Mat) return Min_Max_Result;

   --  Counts nonzero scalar elements. Supports single-channel Mats of any
   --  supported depth (including Float16). Rejects multi-channel Mats.
   --  Non-contiguous views are supported. Empty Mat returns 0.
   function Count_Non_Zero (Self : Mat) return Mat_Size;

   --  Returns true if a single-channel Mat contains at least one nonzero
   --  element. Supports non-contiguous views. Rejects multi-channel Mats.
   --  Empty Mat returns false.
   function Has_Non_Zero (Self : Mat) return Boolean;

   --  Returns locations of all nonzero elements in row-major order. Point.X
   --  is the column and Point.Y is the row. Supports 2-D, single-channel Mats
   --  with UInt8, Int8, UInt16, Int16, Int32, Float32, or Float64 depth;
   --  Float16 and multi-channel Mats are rejected. Empty and all-zero Mats
   --  return an empty Point_Array. Locations for a Region are relative to that
   --  Region rather than to its parent Mat.
   function Find_Non_Zero (Self : Mat) return Point_Array;

   --  Checks every scalar channel value of Self. The no-bound overload
   --  uses OpenCV 4.10's default range check: NaN and +/- Infinity are
   --  invalid, and floating-point values are subject to OpenCV's default
   --  finite extrema. The positive maximum finite endpoint is excluded
   --  by the half-open upper bound. The bounded overload passes Minimum
   --  and Maximum through to OpenCV. Float32 and Float64 use the
   --  requested half-open [Minimum, Maximum) interval. Integer depths
   --  convert those floating bounds to effective integer limits with
   --  OpenCV's floor/ceil behavior before checking, so a value may be
   --  accepted even when it is not mathematically inside
   --  [Minimum, Maximum). First_Invalid.X is the column and
   --  First_Invalid.Y is the row of the first invalid element in
   --  row-major order. Multi-channel Mats are checked channel-by-channel;
   --  the reported Point identifies the element, not a channel. Supports
   --  UInt8, Int8, UInt16, Int16, Int32, Float32, and Float64. Float16 is
   --  not supported by OpenCV 4.10. Empty Mats, including a default empty
   --  Mat and typed 0x0 Mats, are valid when they contain no elements.
   --  Non-contiguous Regions are accepted; First_Invalid is relative to
   --  Self. Does not modify Self.
   function Check_Range (Self : Mat) return Range_Check_Result;
   function Check_Range
     (Self : Mat; Minimum : Long_Float; Maximum : Long_Float)
      return Range_Check_Result;

   --  Replaces every NaN scalar channel value of Self in place. Only
   --  Float32 Mats are accepted; UInt8, Int8, UInt16, Int16, Int32,
   --  Float16, and Float64 are rejected. Multi-channel values are
   --  processed channel-by-channel. The default replacement is 0.0.
   --  Finite values and +/- Infinity are left unchanged, so a Mat that
   --  still contains Infinity is not necessarily valid according to
   --  Check_Range. The replacement is converted to Float32 before it
   --  is stored; NaN and infinite replacements are stored as that
   --  Float32 representation. Non-contiguous Regions are accepted and
   --  mutate their parent/shared storage. A normal shallow Mat alias
   --  observes the same mutation. A typed 0x0 Float32 Mat is a no-op
   --  that preserves its depth and channel count. A default empty Mat
   --  is rejected because its depth is not Float32.
   procedure Patch_NaNs (Self : in out Mat; Value : Float32_Value := 0.0);

   --  Completes Self into a symmetric square Mat in place. Source names
   --  the authoritative triangle. Upper_Triangle, the default, preserves
   --  the diagonal and upper triangle and copies each upper-triangle
   --  element onto its reflected lower-triangle location. That mapping
   --  is OpenCV 4.10 lowerToUpper=false. Lower_Triangle preserves the
   --  diagonal and lower triangle and copies each lower-triangle element
   --  onto its reflected upper-triangle location. Self must be square
   --  and Float32 or Float64. Any valid channel count is accepted
   --  because OpenCV copies each complete element with elemSize().
   --  Dimensions, depth, and channel count are unchanged. Continuity is
   --  not required. Non-contiguous Regions are supported and mutate the
   --  corresponding parent pixels around the Region's own diagonal. A
   --  normal shallow Mat alias observes the same mutation. Clone remains
   --  independent. A typed 0x0 Float32 or Float64 Mat is a no-op that
   --  preserves its depth and channel count. A default empty Mat is
   --  rejected because its depth is not Float32 or Float64. This
   --  procedure does not allocate a replacement Mat.
   procedure Complete_Symmetry
     (Self : in out Mat; Source : Symmetry_Source := Upper_Triangle);

   --  Initializes Self in place as a scaled identity. Self is modified
   --  directly; this procedure does not allocate a replacement Mat.
   --  Self need not be square. Every off-diagonal element becomes zero
   --  and each main-diagonal element becomes Value converted by
   --  OpenCV's Scalar conversion. The diagonal length is
   --  min (Rows, Columns). The default Value is (1.0, 0.0, 0.0, 0.0),
   --  matching cv::Scalar (1); it does not replicate 1 to every
   --  channel. For a multi-channel Mat the Scalar components map to
   --  the corresponding channels. All eight public depths are
   --  accepted, including Float16. Channel count must be 1 through 4;
   --  more than four channels are rejected because OpenCV's Scalar
   --  conversion path only represents four destination channels.
   --  Dimensions, depth, and channel count are unchanged. Continuity
   --  is not required. Non-contiguous Regions are supported and mutate
   --  the corresponding parent pixels around the Region's own
   --  diagonal. A normal shallow Mat alias observes the same
   --  mutation. Clone remains independent. A default empty Mat and
   --  typed 0x0 Mats are no-ops that preserve their metadata.
   procedure Set_Identity
     (Self  : in out Mat;
      Value : Scalar := (Component_0 => 1.0, others => 0.0));
private

   type Mat is new Ada.Finalization.Controlled with record
      Handle : OpenCV.Internal.C_API.Mat_Handle :=
        OpenCV.Internal.C_API.Null_Mat_Handle;
   end record;

   overriding
   procedure Initialize (Self : in out Mat);
   overriding
   procedure Adjust (Self : in out Mat);
   overriding
   procedure Finalize (Self : in out Mat);

end OpenCV.Core;
