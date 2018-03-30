using BinaryBuilder

# Collection of sources required to build GDAL
sources = [
    "https://download.osgeo.org/gdal/2.2.4/gdal-2.2.4.tar.xz" =>
    "441eb1d1acb35238ca43a1a0a649493fc91fdcbab231d0747e9d462eea192278",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd gdal-2.2.4/

# On Windows platforms, our ./configure invocation differs a bit
if [[ ${target} == *-w64-mingw* ]]; then
    EXTRA_CONFIGURE_FLAGS="LDFLAGS=-L$prefix/bin"
fi

./configure --prefix=$prefix --host=$target $EXTRA_CONFIGURE_FLAGS \
    --with-geos=$prefix/bin/geos-config \
    --with-static-proj4=$prefix \
    --with-libz=$prefix
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    BinaryProvider.Windows(:i686, :blank_libc, :blank_abi),
    BinaryProvider.Windows(:x86_64, :blank_libc, :blank_abi)
]

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "gdalinfo", :gdalinfo),
    ExecutableProduct(prefix, "gdalwarp", :gdalwarp),
    ExecutableProduct(prefix, "libgdal", :libgdal),
    ExecutableProduct(prefix, "gdal_translate", :gdal_translate),
    ExecutableProduct(prefix, "ogr2ogr", :ogr2ogr),
    ExecutableProduct(prefix, "ogrinfo", :ogrinfo)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaGeo/GEOSBuilder/releases/download/v3.6.2-0/build.jl",
    "https://github.com/JuliaGeo/PROJBuilder/releases/download/v4.9.3-0/build.jl",
    "https://github.com/staticfloat/ZlibBuilder/releases/download/v1.2.11-3/build.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "GDAL", sources, script, platforms, products, dependencies)

