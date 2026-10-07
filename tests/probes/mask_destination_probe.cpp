// Compile alone: exercises the actual private production helpers.
#include "../../cpp/opencv_core_shim.cpp"
#include <opencv2/core/ocl.hpp>
#include <iostream>
#include <limits>
#include <string>
#include <cstring>
#include <type_traits>

static void require(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}
static cv::Mat host(const cv::Mat &m) { return m; }
static cv::Mat host(const cv::UMat &m) {
    cv::Mat result; m.copyTo(result); return result;
}
template<class Dense> static Dense dense(const cv::Mat &m) {
    Dense result; m.copyTo(result); return result;
}
static void storage_equal(const cv::Mat &a, const cv::Mat &b) {
    require(a.dims==b.dims && a.size==b.size && a.type()==b.type(),
            "unchanged source metadata");
    cv::Mat x=a.clone(),y=b.clone();
    require(std::memcmp(x.data,y.data,x.total()*x.elemSize())==0,
            "every unchanged source byte");
}
static void equal(const cv::Mat &a, const cv::Mat &b);
static void exact_guards(bool range) {
    for(int depth:{CV_8U,CV_16S,CV_32F,CV_64F,CV_16F})
        for(int cn:{1,3}) {
            if(!range && cn!=1) continue;
            if(range && cn!=1 && depth!=CV_8U) continue;
            cv::Mat x(2,257,CV_32FC(cn));
            for(int r=0;r<2;++r) for(int c=0;c<257;++c)
                for(int ch=0;ch<cn;++ch)
                    x.ptr<float>(r)[c*cn+ch]=float(1+r+c%7+ch*10);
            x.convertTo(x,CV_MAKETYPE(depth,cn));
            for(int mode=0;mode<(range?1:2);++mode) {
                cv::UMat a=dense<cv::UMat>(x),b=dense<cv::UMat>(x);
                cv::UMat aa=a,bb=b;
                bool rejected=false;
                try {
                    if(range) dense_in_range_scalar(a,cv::Scalar::all(0),
                                                    cv::Scalar::all(100),a);
                    else dense_compare(a,b,cv::CMP_EQ,mode==0?a:b);
                } catch(const cv::Exception &e) {
                    require(e.code==cv::Error::StsBadArg,
                            "controlled alias guard, not native assertion");
                    rejected=true;
                }
                if(range || depth!=CV_8U) {
                    require(rejected,"exact UMat alias must reject");
                    storage_equal(host(a),x); storage_equal(host(b),x);
                    storage_equal(host(aa),x); storage_equal(host(bb),x);
                } else {
                    require(!rejected,"UInt8 exact Compare remains allowed");
                    cv::Mat expected(2,257,CV_8UC1,cv::Scalar(255));
                    equal(host(mode==0?a:b),expected);
                }
            }
        }
    std::cout<<"exact UMat helper rejection/preservation/UInt8 gates passed\n";
}
static void equal(const cv::Mat &a, const cv::Mat &b) {
    require(a.size == b.size && a.type() == CV_8UC1 && b.type() == CV_8UC1,
            "mask layout");
    cv::Mat x=a.clone(), y=b.clone();
    for(size_t i=0;i<x.total();++i)
        require(x.data[i]==y.data[i] && (x.data[i]==0 || x.data[i]==255),
                "every exact mask byte");
}
static bool selected(double a, double b, int kind) {
    switch(kind) {
    case cv::CMP_EQ: return a==b;
    case cv::CMP_NE: return a!=b;
    case cv::CMP_LT: return a<b;
    case cv::CMP_LE: return a<=b;
    case cv::CMP_GT: return a>b;
    default: return a>=b;
    }
}
template<class Dense> static void execute(const Dense &a, const Dense &b,
    Dense &d, bool range, int kind, bool direct=false) {
    if(range) {
        if(direct) cv::inRange(a,cv::Scalar(1,11,21,31),
                              cv::Scalar(3,13,23,33),d);
        else dense_in_range_scalar(a,cv::Scalar(1,11,21,31),
                                    cv::Scalar(3,13,23,33),d);
    } else {
        if(direct) cv::compare(a,b,d,kind);
        else dense_compare(a,b,kind,d);
    }
}
template<class Dense> static void aliases(bool range, bool direct) {
    for(int depth:{CV_8U,CV_16S,CV_32F}) for(int cn:{1,3}) {
        if((!range && cn!=1) || (cn!=1 && depth!=CV_8U)) continue;
        cv::Mat x(1,257,CV_MAKETYPE(depth,cn),cv::Scalar(2,12,22));
        cv::Mat y(1,257,x.type(),cv::Scalar(3,13,23));
        Dense base_a=dense<Dense>(x),base_b=dense<Dense>(y),e;
        execute(base_a,base_b,e,range,cv::CMP_LT,direct);
        for(int mode=0;mode<(range?2:4);++mode) {
            Dense a=dense<Dense>(x),b=dense<Dense>(y);
            Dense d=range?a:(mode==2?a:b);
            std::cout<<"alias depth="<<depth<<" cn="<<cn
                     <<" mode="<<mode<<std::endl;
            const bool must_reject=!direct && std::is_same<Dense,cv::UMat>::value
                && (range?mode==0:(mode<2 && depth!=CV_8U));
            bool rejected=false;
            try {
                if(mode==0) execute(a,b,a,range,cv::CMP_LT,direct);
                else if(!range && mode==1)
                    execute(a,b,b,range,cv::CMP_LT,direct);
                else execute(a,b,d,range,cv::CMP_LT,direct);
                equal(host(mode==0?a:(!range && mode==1)?b:d),host(e));
                std::cout<<"parity\n";
            } catch(const std::exception &err) {
                rejected=true;
                std::cout<<"exception/difference: "<<err.what()<<'\n';
            }
            if(must_reject) {
                require(rejected,"helper exact alias rejection");
                storage_equal(host(a),x); storage_equal(host(b),y);
            }
        }
    }
}
template<class Dense> static void layouts(bool range) {
    for(int depth:{CV_8U,CV_16S,CV_32S,CV_32F,CV_64F,CV_16F}) {
        if(depth==CV_16F && CV_VERSION_MAJOR<5) continue;
        for(int cn=1;cn<=(range?4:1);++cn) {
            cv::Mat x(1,257,CV_32SC(cn)),y(1,257,CV_32SC(cn));
            for(int c=0;c<257;++c) for(int ch=0;ch<cn;++ch) {
                int v=ch*10+1+c%3;
                if(range && c%7==ch+1) v-=4;
                else if(range && c%7==5) v+=4;
                x.ptr<int>()[c*cn+ch]=v;
                y.ptr<int>()[c*cn+ch]=v+c%3-1;
            }
            x.convertTo(x,CV_MAKETYPE(depth,cn));
            y.convertTo(y,CV_MAKETYPE(depth,cn));
            for(int kind=0;kind<(range?1:6);++kind) {
                Dense a=dense<Dense>(x),b=dense<Dense>(y),e,n;
                execute(a,b,e,range,kind); execute(a,b,n,range,kind,true);
                equal(host(e),host(n));
                cv::Mat expected(1,257,CV_8UC1);
                for(int c=0;c<257;++c) {
                    bool pass=true;
                    for(int ch=0;ch<cn;++ch)
                        pass=pass && (range ? (c%7!=ch+1 && c%7!=5)
                            : selected(1+c%3,1+c%3+c%3-1,kind));
                    expected.at<uchar>(0,c)=pass?255:0;
                }
                equal(host(e),expected);
                Dense d=dense<Dense>(cv::Mat(1,257,CV_8UC1,cv::Scalar(91)));
                Dense alias=d;
                execute(a,b,d,range,kind); equal(host(alias),expected);
                alias.setTo(cv::Scalar(17));
                require(host(d).template at<uchar>(0,256)==17,"alias write");
                d.setTo(cv::Scalar(19));
                require(host(alias).template at<uchar>(0,256)==19,"dst write");
                Dense parent=dense<Dense>(cv::Mat(3,260,CV_8UC1,cv::Scalar(91)));
                d=parent(cv::Rect(1,1,257,1)); alias=d;
                execute(a,b,d,range,kind); equal(host(alias),expected);
                cv::Size whole; cv::Point offset; d.locateROI(whole,offset);
                require(whole==cv::Size(260,3) && offset==cv::Point(1,1),
                        "Region location");
                cv::Mat p=host(parent);
                for(int r=0;r<3;++r) for(int c=0;c<260;++c)
                    require(p.at<uchar>(r,c)==(r==1 && c>=1 && c<=257?
                        expected.at<uchar>(0,c-1):91),"Region Parent guards");
                for(int mismatch=0;mismatch<3;++mismatch) {
                    int old=mismatch==1?CV_16SC1:mismatch==2?CV_8UC3:CV_8UC1;
                    parent=dense<Dense>(cv::Mat(3,260,old,cv::Scalar::all(91)));
                    d=parent(cv::Rect(1,1,mismatch==0?256:257,1)); alias=d;
                    execute(a,b,d,range,kind); equal(host(d),expected);
                    require(alias.type()==old,"old Alias type");
                    cv::Mat before=host(parent).clone(),after;
                    parent.setTo(cv::Scalar::all(23)); equal(host(d),expected);
                    host(alias).convertTo(after,CV_64F);
                    require(after.ptr<double>()[0]==23,"old attachment");
                    before.convertTo(before,CV_64F);
                    for(size_t i=0;i<before.total()*before.channels();++i)
                        require(before.ptr<double>()[i]==91,"old Parent");
                }
            }
        }
    }
    if(range) {
        for(int depth:{CV_8U,CV_16S,CV_32S}) {
            Dense a=dense<Dense>(cv::Mat(1,257,depth,cv::Scalar(1))),d;
            dense_in_range_scalar(a,cv::Scalar(1.2),cv::Scalar(2.8),d);
            cv::Mat h=host(d);
            for(int c=0;c<257;++c)
                require(h.at<uchar>(0,c)==255,"integer scalar rounding");
        }
        int shape[]={2,3,5};
        for(int depth:{CV_8U,CV_32F,CV_16F}) {
            if(depth==CV_16F && CV_VERSION_MAJOR<5) continue;
            for(int cn:{1,3}) {
                Dense a=dense<Dense>(cv::Mat(3,shape,CV_MAKETYPE(depth,cn),
                                             cv::Scalar(2,12,22))),b,e,d;
                execute(a,b,e,true,0);
                d=dense<Dense>(cv::Mat(3,shape,CV_8UC1,cv::Scalar(91)));
                Dense alias=d;
                execute(a,b,d,true,0); equal(host(d),host(e));
                equal(host(alias),host(e));
                require(d.dims==3 && d.size[0]==2 && d.size[1]==3
                        && d.size[2]==5,"N-D shape");
                d=dense<Dense>(cv::Mat(1,2,CV_64FC4));
                execute(a,b,d,true,0); equal(host(d),host(e));
            }
        }
    } else {
        const double nan=std::numeric_limits<double>::quiet_NaN();
        const double inf=std::numeric_limits<double>::infinity();
        for(int depth:{CV_32F,CV_64F}) for(double v:{nan,inf,-inf,0.,-0.,3.})
            for(int kind=0;kind<6;++kind) {
                cv::Mat seed(1,257,CV_64F,cv::Scalar(v));
                seed.convertTo(seed,depth);
                Dense a=dense<Dense>(seed),b=dense<Dense>(
                    cv::Mat(1,257,depth,cv::Scalar(0))),e,n;
                execute(a,b,e,false,kind); execute(a,b,n,false,kind,true);
                equal(host(e),host(n));
                std::cout<<"special depth="<<depth<<" value="<<v
                         <<" kind="<<kind<<" first="
                         <<int(host(e).template at<uchar>(0,0))
                         <<" tail="<<int(host(e).template at<uchar>(0,256))
                         <<'\n';
            }
        cv::Mat x(1,257,CV_32S),y(1,257,CV_32S);
        for(int c=0;c<257;++c) {
            x.at<int>(0,c)=c%2?std::numeric_limits<int>::min():
                              std::numeric_limits<int>::max();
            y.at<int>(0,c)=c%2?x.at<int>(0,c)+1:x.at<int>(0,c)-1;
        }
        for(int kind=0;kind<6;++kind) {
            Dense a=dense<Dense>(x),b=dense<Dense>(y),e;
            execute(a,b,e,false,kind);
            cv::Mat observed=host(e);
            for(int c=0;c<257;++c)
                require(observed.at<uchar>(0,c)==
                    (selected(x.at<int>(0,c),y.at<int>(0,c),kind)?255:0),
                    "exact Int32 extrema");
        }
    }
    for(int typed=0;typed<3;++typed) {
        Dense a,b,d=dense<Dense>(cv::Mat(2,3,CV_8UC1,cv::Scalar(91)));
        if(typed) { a.create(0,0,typed==1?CV_8U:CV_32F); b=a; }
        Dense alias=d;
        try {
            execute(a,b,d,range,0);
            require(!range && d.empty(),"empty policy");
            Dense fresh;
            execute(a,b,fresh,false,0);
            std::cout<<"empty form="<<typed<<" dst dims="<<d.dims
                     <<" type="<<d.type()<<" rows="<<d.rows
                     <<" cols="<<d.cols<<" fresh dims="<<fresh.dims
                     <<" type="<<fresh.type()<<'\n';
        } catch(const cv::Exception &) {
            require(range,"unexpected Compare empty rejection");
            require(d.dims==2 && d.rows==2 && d.cols==3 && d.type()==CV_8UC1,
                    "empty range unchanged layout");
        }
        require(host(alias).template at<uchar>(0,0)==91,"empty retained Alias");
    }
    std::cout<<"layout/mode/channel/ND/empty/direct parity passed\n";
}
template<class Dense> static void half(bool range) {
    cv::Mat seed(1,257,CV_32F,cv::Scalar(2)); seed.convertTo(seed,CV_16F);
    Dense a=dense<Dense>(seed),b=dense<Dense>(seed);
    Dense d=dense<Dense>(cv::Mat(2,3,CV_8UC1,cv::Scalar(91))),alias=d;
    try {
        execute(a,b,d,range,cv::CMP_EQ);
        require(CV_VERSION_MAJOR>=5,"4.x must reject Float16");
        require(d.type()==CV_8UC1,"half mask output");
        cv::Mat observed=host(d);
        for(int c=0;c<257;++c)
            require(observed.at<uchar>(0,c)==255,"half exact mask byte");
    } catch(const cv::Exception &) {
        require(CV_VERSION_MAJOR<5,"5.0 must support Float16");
        require(d.size==alias.size && d.type()==alias.type(),"half metadata");
        require(host(d).template at<uchar>(1,2)==91,"half unchanged bytes");
        cv::Mat observed=host(d);
        for(int r=0;r<2;++r) for(int c=0;c<3;++c)
            require(observed.at<uchar>(r,c)==91,"every half rejected byte");
    }
    std::cout<<"Float16 helper version boundary passed\n";
}
int main(int argc,char **argv) {
    if(argc!=5) {
        std::cerr<<"usage: probe mat|umat compare|range layouts|aliases|native-aliases|half|exact-guards opencl-request\n";
        return 2;
    }
    cv::ocl::setUseOpenCL(std::string(argv[4])=="1");
    std::cout<<"OpenCV "<<CV_VERSION<<" OpenCL requested="<<argv[4]
             <<" enabled="<<cv::ocl::useOpenCL()<<std::endl;
    const bool range=std::string(argv[2])=="range";
    const std::string mode=argv[3];
    try {
        if(mode=="exact-guards") exact_guards(range);
        else if(std::string(argv[1])=="mat") {
            if(mode=="layouts") layouts<cv::Mat>(range);
            else if(mode=="half") half<cv::Mat>(range);
            else aliases<cv::Mat>(range,mode=="native-aliases");
        } else {
            if(mode=="layouts") layouts<cv::UMat>(range);
            else if(mode=="half") half<cv::UMat>(range);
            else aliases<cv::UMat>(range,mode=="native-aliases");
        }
    } catch(const std::exception &e) { std::cerr<<e.what()<<'\n'; return 1; }
}