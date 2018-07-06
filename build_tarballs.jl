using BinaryBuilder

GDALVERSION = v"2.3.1"

# Collection of sources required to build GDAL
sources = [
    "https://download.osgeo.org/gdal/$GDALVERSION/gdal-$GDALVERSION.tar.xz" =>
    "9c4625c45a3ee7e49a604ef221778983dd9fd8104922a87f20b99d9bedb7725a",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd gdal-$GDALVERSION/

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
    BinaryProvider.Linux(:i686, :glibc),
    BinaryProvider.Linux(:x86_64, :glibc),
    BinaryProvider.Linux(:aarch64, :glibc),
    BinaryProvider.Linux(:armv7l, :glibc),
    BinaryProvider.Linux(:powerpc64le, :glibc),
    BinaryProvider.MacOS(),
    BinaryProvider.Windows(:i686),
    BinaryProvider.Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libgdal", :libgdal),
    ExecutableProduct(prefix, "gdalinfo", :gdalinfo_path),
    ExecutableProduct(prefix, "gdalwarp", :gdalwarp_path),
    ExecutableProduct(prefix, "gdal_translate", :gdal_translate_path),
    ExecutableProduct(prefix, "ogr2ogr", :ogr2ogr_path),
    ExecutableProduct(prefix, "ogrinfo", :ogrinfo_path)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaGeo/GEOSBuilder/releases/download/v3.6.2-2/build.jl",
    "https://github.com/JuliaGeo/PROJBuilder/releases/download/v4.9.3-2/build.jl",
    "https://github.com/staticfloat/ZlibBuilder/releases/download/v1.2.11-3/build.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "GDAL", sources, script, platforms, products, dependencies)
