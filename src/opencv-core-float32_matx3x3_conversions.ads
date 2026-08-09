with OpenCV.Core.Float32_Matx3x3;

package OpenCV.Core.Float32_Matx3x3_Conversions is

   function To_Mat (Value : OpenCV.Core.Float32_Matx3x3.Matrix) return Mat;

   function To_Matx3x3 (Image : Mat) return OpenCV.Core.Float32_Matx3x3.Matrix;

end OpenCV.Core.Float32_Matx3x3_Conversions;
