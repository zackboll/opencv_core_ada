// Standalone: includes the actual private production helpers, not replicas.
#ifndef BITWISE_SHIM_SOURCE
#define BITWISE_SHIM_SOURCE "../../cpp/opencv_core_shim.cpp"
#endif
#include BITWISE_SHIM_SOURCE
#include <opencv2/core/ocl.hpp>
#include <iostream>
#include <cstring>

static void require(bool ok, const char *why) {
    if (!ok) throw std::runtime_error(why);
}
static cv::Mat host(const cv::Mat &m) { return m; }
static cv::Mat host(const cv::UMat &m) {
    cv::Mat result; m.copyTo(result); return result;
}
template<class Dense> static Dense wrap(const cv::Mat &m) {
    Dense result; m.copyTo(result); return result;
}
static bool equal(const cv::Mat &a, const cv::Mat &b) {
    if (a.dims!=b.dims || a.type()!=b.type()) return false;
    for(int i=0;i<a.dims;++i) if(a.size[i]!=b.size[i]) return false;
    if(a.empty()) return b.empty();
    cv::Mat x=a.clone(),y=b.clone();
    return std::memcmp(x.data,y.data,x.total()*x.elemSize())==0;
}
static uchar result(uchar a, uchar b, int op) {
    switch(op) {
    case 0: return a & b;
    case 1: return a | b;
    case 2: return a ^ b;
    default: return static_cast<uchar>(~a);
    }
}
template<class Dense> static void apply(const Dense &a,const Dense &b,
    Dense &d,int op,const Dense *mask=nullptr) {
    if(op==3) dense_bitwise_not(a,d,mask);
    else dense_bitwise_binary(a,b,d,static_cast<bitwise_operation>(op),mask);
}
template<class Dense> static void native(const Dense &a,const Dense &b,
    Dense &d,int op,const Dense *mask=nullptr) {
    if(mask) {
        switch(op) {
        case 0: cv::bitwise_and(a,b,d,*mask); break;
        case 1: cv::bitwise_or(a,b,d,*mask); break;
        case 2: cv::bitwise_xor(a,b,d,*mask); break;
        default: cv::bitwise_not(a,d,*mask);
        }
    } else {
        switch(op) {
        case 0: cv::bitwise_and(a,b,d); break;
        case 1: cv::bitwise_or(a,b,d); break;
        case 2: cv::bitwise_xor(a,b,d); break;
        default: cv::bitwise_not(a,d);
        }
    }
}
static cv::Mat oracle(const cv::Mat &a,const cv::Mat &b,
    const cv::Mat &old,int op,const cv::Mat *mask) {
    cv::Mat e=old.clone();
    for(int r=0;r<a.rows;++r) for(int c=0;c<a.cols;++c)
        if(!mask || mask->at<uchar>(r,c))
            for(size_t k=0;k<a.elemSize();++k) {
                size_t i=c*a.elemSize()+k;
                e.ptr(r)[i]=result(a.ptr(r)[i],b.ptr(r)[i],op);
            }
    return e;
}
template<class Dense> static void run(const char *family) {
    for(int depth:{CV_8U,CV_16S,CV_32S,CV_16F,CV_32F,CV_64F})
    for(int cn:{1,3,4}) for(int op=0;op<4;++op) {
        cv::Mat x(2,257,CV_MAKETYPE(depth,cn)),y(x.size(),x.type());
        for(int r=0;r<2;++r) for(size_t c=0;c<257*x.elemSize();++c) {
            x.ptr(r)[c]=static_cast<uchar>(c*37+170+r);
            y.ptr(r)[c]=static_cast<uchar>(c*19+204+r);
        }
        // Raw half encodings: +0,-0,1,+inf,and two NaN payloads.
        if(depth==CV_16F) {
            const uint16_t bits[]={0,0x8000,0x3c00,0x7c00,0x7e35,0xfe71};
            for(int r=0;r<2;++r) for(int c=0;c<257*cn;++c) {
                x.ptr<uint16_t>(r)[c]=bits[c%6];
                y.ptr<uint16_t>(r)[c]=bits[(c+2)%6];
            }
        }
        for(int mask_kind=0;mask_kind<4;++mask_kind) {
            cv::Mat hm(2,257,CV_8U);
            const uchar bytes[]={0,1,2,127,255};
            for(int r=0;r<2;++r) for(int c=0;c<257;++c)
                hm.at<uchar>(r,c)=mask_kind==2?0:mask_kind==3?1:bytes[c%5];
            Dense a=wrap<Dense>(x),b=wrap<Dense>(y),m=wrap<Dense>(hm);
            const Dense *mask=mask_kind?&m:nullptr;
            for(int layout=0;layout<5;++layout) {
                int old_type=layout==3?CV_MAKETYPE((depth+1)%7,cn):
                    layout==4?CV_MAKETYPE(depth,cn==1?3:1):x.type();
                Dense parent=wrap<Dense>(cv::Mat(4,260,old_type,cv::Scalar::all(91)));
                Dense d=layout==0?wrap<Dense>(cv::Mat(2,257,x.type(),cv::Scalar::all(37))):
                    parent(cv::Rect(1,1,layout==2?256:257,2));
                d.setTo(cv::Scalar::all(37));
                Dense alias=d;
                cv::Mat before=host(parent).clone();
                cv::Mat old=layout>=2?cv::Mat::zeros(x.size(),x.type()):host(d).clone();
                cv::Mat e=oracle(x,y,old,op,mask_kind?&hm:nullptr);
                cv::Size whole; cv::Point offset;
                d.locateROI(whole,offset);
                apply(a,b,d,op,mask);
                require(equal(host(d),e),"every reused/reallocated result bit");
                if(layout<=1) {
                    require(equal(host(alias),e),"alias still attached");
                    cv::Size w; cv::Point o; d.locateROI(w,o);
                    require(w==whole&&o==offset,"Region geometry unchanged");
                    if(layout==1) {
                        cv::Mat wanted=before.clone(); e.copyTo(wanted(cv::Rect(1,1,257,2)));
                        require(equal(host(parent),wanted),"every Parent guard");
                    }
                    alias.setTo(cv::Scalar::all(23));
                    require(equal(host(alias),host(d)),"alias write");
                    d.setTo(cv::Scalar::all(25));
                    require(equal(host(alias),host(d)),"destination write");
                } else {
                    require(equal(host(parent),before),"old Parent untouched");
                    d.setTo(cv::Scalar::all(25));
                    require(equal(host(parent),before),"new output detached");
                    alias.setTo(cv::Scalar::all(31));
                    require(!equal(host(parent),before),"old alias still reaches Parent");
                }
            }
            // Exact headers, shallow same-layout aliases, and A=A identities.
            for(bool same:{false,true}) for(int mode=0;mode<5;++mode) {
                a=wrap<Dense>(x); b=same?a:wrap<Dense>(y);
                Dense d=mode==0?wrap<Dense>(x):mode<=2?a:b;
                cv::Mat old=host(d).clone(),oldb=host(b).clone();
                cv::Mat e=oracle(x,oldb,old,op,mask_kind?&hm:nullptr);
                if(mode==1) { apply(a,b,a,op,mask); d=a; }
                else if(mode==3) { apply(a,b,b,op,mask); d=b; }
                else apply(a,b,d,op,mask);
                require(equal(host(d),e),"old source bits in alias result including tail");
            }
            Dense d, direct;
            apply(a,b,d,op,mask); native(a,b,direct,op,mask);
            require(equal(host(d),host(direct)),"function/helper/direct-native bits");
        }
    }
    // Genuine N-D Not: independent byte oracle, reuse, mismatch, exact alias.
    const int shape[]={2,3,5};
    for(int depth:{CV_8U,CV_16F}) {
        cv::Mat x(3,shape,depth);
        for(size_t i=0;i<x.total()*x.elemSize();++i) x.data[i]=static_cast<uchar>(i*37);
        cv::Mat e=x.clone();
        for(size_t i=0;i<e.total()*e.elemSize();++i) e.data[i]=static_cast<uchar>(~e.data[i]);
        for(int mode=0;mode<4;++mode) {
            Dense a=wrap<Dense>(x),b=a;
            Dense d=mode==0?Dense():mode==1?wrap<Dense>(x):
                mode==2?wrap<Dense>(cv::Mat(2,7,CV_64FC3)):a;
            Dense alias=d;
            apply(a,b,d,3);
            require(equal(host(d),e),"N-D Not exact bytes/rank/type");
            if(mode==1||mode==3) require(equal(host(alias),e),"N-D storage reused");
        }
        Dense a=wrap<Dense>(x);
        dense_bitwise_not(a,a);
        require(equal(host(a),e),"N-D exact source header alias");
    }
    // Empty metadata deliberately logged rather than normalized.
    for(int depth:{CV_8U,CV_16F}) for(int form=0;form<4;++form)
    for(bool masked:{false,true}) for(int op=0;op<4;++op)
    for(bool typed_mask:{false,true}) {
        Dense a=form&1?wrap<Dense>(cv::Mat(0,0,depth)):Dense();
        Dense b=form&2?wrap<Dense>(cv::Mat(0,0,depth)):Dense();
        // copyTo does not preserve typed empties, construct explicitly instead.
        if(form&1) a=Dense(0,0,depth);
        if(form&2) b=Dense(0,0,depth);
        Dense m=typed_mask?Dense(0,0,CV_8U):Dense();
        Dense d(2,257,CV_16SC2); d.setTo(cv::Scalar::all(91)); Dense alias=d;
        cv::Mat old=host(alias).clone();
        {
            apply(a,b,d,op,masked?&m:nullptr);
            require(d.empty(),"empty semantic result");
            const bool released=op==3||masked ? !(form&1) :
                std::is_same<Dense,cv::UMat>::value ? form==0 : form!=3;
            require(d.dims==(released && CV_VERSION_MAJOR>=5 ? 0 : 2),
                    "empty release/create rank");
            require(d.type()==(released ? CV_16SC2 : depth),
                    "empty old-type/source-type");
            for(int i=0;i<d.dims;++i)
                require(d.size[i]==0,"every empty shape extent");
            require(!alias.empty(),"old empty-result alias survives");
            require(equal(host(alias),old),"every old empty-result alias bit survives");
            std::cout<<family<<" empty depth="<<depth<<" form="<<form
                     <<" masked="<<masked<<" typed-mask="<<typed_mask
                     <<" op="<<op<<" dims="<<d.dims<<" type="<<d.type()
                     <<" shape=";
            for(int i=0;i<d.dims;++i) std::cout<<d.size[i]<<',';
            std::cout<<'\n';
        }
    }
    // Mask=Destination observation only: explicitly outside binding contract.
    for(int op=0;op<4;++op) {
        Dense a(2,257,CV_8U),b(2,257,CV_8U),d(2,257,CV_8U);
        a.setTo(cv::Scalar(170)); b.setTo(cv::Scalar(204));
        cv::Mat hm(2,257,CV_8U);
        for(int r=0;r<2;++r) for(int c=0;c<257;++c) hm.at<uchar>(r,c)=c%5?1:0;
        d=wrap<Dense>(hm);
        cv::Mat e=oracle(host(a),host(b),hm,op,&hm);
        apply(a,b,d,op,&d);
        std::cout<<family<<" mask=destination op="<<op
                 <<" expected="<<equal(host(d),e)<<'\n';
    }
    std::cout<<family<<" all required helper cases passed\n";
}
int main() {
    try {
        std::cout<<"OpenCV "<<CV_VERSION<<" haveOpenCL="<<cv::ocl::haveOpenCL()<<'\n';
        const bool previous=cv::ocl::useOpenCL();
        for(bool requested:{false,true}) {
            cv::ocl::setUseOpenCL(requested);
            std::cout<<"requestedOpenCL="<<requested
                     <<" actualOpenCL="<<cv::ocl::useOpenCL()<<'\n';
            run<cv::Mat>("Mat"); run<cv::UMat>("UMat");
        }
        cv::ocl::setUseOpenCL(previous);
    } catch(const std::exception &e) {
        std::cerr<<e.what()<<'\n'; return 1;
    }
}