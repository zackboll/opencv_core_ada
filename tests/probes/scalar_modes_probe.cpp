// Standalone native probe; no binding helpers or constant full-Mat operands.
#include <opencv2/core.hpp>
#include <iostream>
#include <stdexcept>
#include <cmath>

static void check(bool ok, const char* message) {
    if (!ok) throw std::runtime_error(message);
}
static void apply(const cv::Mat& source, const cv::Scalar& scalar,
                  cv::Mat& destination, int operation) {
    switch (operation) {
    case 0: cv::add(source, scalar, destination, cv::noArray(), source.depth()); break;
    case 1: cv::subtract(source, scalar, destination, cv::noArray(), source.depth()); break;
    case 2: cv::multiply(source, scalar, destination, 1, source.depth()); break;
    case 3: cv::divide(source, scalar, destination, 1, source.depth()); break;
    case 4: cv::subtract(scalar, source, destination, cv::noArray(), source.depth()); break;
    case 5: cv::divide(scalar, source, destination, 1, source.depth()); break;
    default: throw std::runtime_error("operation");
    }
}
int main() {
    for (int depth : {CV_8U,CV_8S,CV_16U,CV_16S,CV_32S,CV_32F,CV_64F})
        for (int channels : {1,2,3,4})
            for (int operation=0; operation<6; ++operation) {
                cv::Mat parent(5,263,CV_MAKETYPE(depth,channels),cv::Scalar::all(8));
                cv::Mat source=parent(cv::Rect(2,1,257,3));
                cv::Scalar scalar(2,3,4,5);
                cv::Mat expected;
                apply(source,scalar,expected,operation);
                cv::Mat exact=source.clone();
                auto* exact_data=exact.data;
                apply(exact,scalar,exact,operation);
                check(exact.data==exact_data && cv::norm(exact,expected,cv::NORM_INF)==0,
                      "exact arithmetic alias");
                cv::Mat shallow=source.clone(), alias=shallow;
                apply(shallow,scalar,alias,operation);
                check(alias.data==shallow.data && cv::norm(alias,expected,cv::NORM_INF)==0,
                      "same-layout shallow alias");
                cv::Mat dstparent(5,263,source.type(),cv::Scalar::all(91));
                cv::Mat destination=dstparent(cv::Rect(2,1,257,3));
                auto* data=destination.data;
                apply(source,scalar,destination,operation);
                check(data==destination.data && cv::norm(destination,expected,cv::NORM_INF)==0,
                      "strided reusable Region");
                check(cv::sum(dstparent.row(0))[0]==91*263, "parent guards");
                cv::Mat wrong(1,1,CV_32FC1,cv::Scalar(19)), retained=wrong;
                apply(source,scalar,wrong,operation);
                check(wrong.type()==source.type() && cv::norm(wrong,expected,cv::NORM_INF)==0
                      && retained.at<float>(0,0)==19, "incompatible output detaches");
            }
    for (int depth : {CV_8U,CV_8S,CV_16U,CV_16S,CV_32S,CV_32F,CV_64F}) {
        for (double coefficient : {-2.5,-1.5,-0.5,0.5,1.5,2.5}) {
            cv::Mat a(1,257,CV_MAKETYPE(depth,1),cv::Scalar(12)), d;
            for (int op=0;op<6;++op) {
                apply(a,cv::Scalar(coefficient),d,op);
                cv::Mat alias=a.clone();
                apply(alias,cv::Scalar(coefficient),alias,op);
                check(cv::norm(d,alias,cv::NORM_INF)==0,"fractional alias parity");
            }
        }
    }
    for (int depth : {CV_8U,CV_8S,CV_16U,CV_16S,CV_32S,CV_32F,CV_64F}) {
        cv::Mat source(2,257,CV_MAKETYPE(depth,1),cv::Scalar(2));
        for (double scalar : {-1e100,-0.5,1.5,2.0,2.5,1e100})
            for (int relation : {cv::CMP_EQ,cv::CMP_NE,cv::CMP_LT,cv::CMP_LE,cv::CMP_GT,cv::CMP_GE}) {
                cv::Mat mask;
                cv::compare(source,scalar,mask,relation);
                const bool selected=relation==cv::CMP_EQ?2==scalar:relation==cv::CMP_NE?2!=scalar:
                    relation==cv::CMP_LT?2<scalar:relation==cv::CMP_LE?2<=scalar:
                    relation==cv::CMP_GT?2>scalar:2>=scalar;
                check(cv::countNonZero(mask)==(selected?514:0), "fraction/out-of-range comparison");
            }
    }
    std::cout << "PASS native scalar modes " << CV_VERSION
              << ": 7 depths, C1..C4, 6 operations, exact/shallow/ROI/rebind, comparisons\n";
}