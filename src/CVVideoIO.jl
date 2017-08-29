module CVVideoIO

export VideoCapture, isOpened, release

using LibOpenCV
using CVCore
using Cxx

libopencv_videoio = LibOpenCV.find_library_e("libopencv_videoio")
try
    Libdl.dlopen(libopencv_videoio, Libdl.RTLD_GLOBAL)
catch e
    warn("You might need to set DYLD_LIBRARY_PATH to load dependencies proeprty.")
    rethrow(e)
end

cxx"""
#include <opencv2/videoio.hpp>
"""

include("const.jl")

const cvVideoCapture = cxxt"cv::VideoCapture"
cvVideoCapture(idx::Int) = icxx"return cv::VideoCapture($idx);"

const VideoCapture = cvVideoCapture

function Base.read!(cap::VideoCapture, img::Mat{UInt8})
    icxx"$cap.read($(img.handle));"
end

function Base.read(cap::VideoCapture)
    mat = Mat{UInt8}()
    ok = read!(cap, mat)
    ok, Mat(mat)
end

for f in [
        :grab,
        :isOpened,
        :release
        ]
    body = Expr(:macrocall, Symbol("@icxx_str"), "\$cap.$f();")
    @eval $f(cap::VideoCapture) = $body
end

Base.close(cap::VideoCapture) = release(cap)

set(cap::VideoCapture, propId, value) = icxx"$cap.set($propId, $value);"
get(cap::VideoCapture, propId) = icxx"$cap.get($propId);"

end # module
