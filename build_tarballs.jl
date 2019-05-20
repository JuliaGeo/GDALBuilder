using BinaryBuilder


src_version = v"3.0.0"  # also change in raw script string

# Collection of sources required to build GDAL
sources = [
    "https://download.osgeo.org/gdal/$src_version/gdal-$src_version.tar.xz" =>
    "ad316fa052d94d9606e90b20a514b92b2dd64e3142dfdbd8f10981a5fcd5c43e",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd gdal-3.0.0/

if [[ ${target} == *w64-mingw32* ]]; then
    # Windows builds gave a libtool issue,	
    # Linux gave an issue on some builds without it.
    LIBTOOL_USAGE=--without-libtool
    # Symlink libproj for Windows, else configure couldn't find it
    # TODO fix in PROJBuilder or in GDAL configure?
    ln -s $prefix/lib/libproj_6_1.dll.a $prefix/lib/libproj.dll.a
elif [[ ${target} == *freebsd* ]]; then
    # FreeBSD's default Clang ran into issues with configure
    # which seemed to think it was the GNU compiler. Therefore,
    # let's just use the GNU compiler instead.
    CC=gcc
    CXX=g++
fi

# Show options in the log
./configure --help

./configure --prefix=$prefix --host=$target \
    --with-geos=$prefix/bin/geos-config \
    --with-proj=$prefix \
    --with-libz=$prefix \
    --with-sqlite3=$prefix \
    --with-curl=$prefix/bin/curl-config \
    --with-python=no \
    --enable-shared=yes \
    --enable-static=no \
    "CC=$CC" \
    "CXX=$CXX" \
    ${LIBTOOL_USAGE}

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
    ExecutableProduct(prefix, "gdal_contour", :gdal_contour_path),
    ExecutableProduct(prefix, "gdal_grid", :gdal_grid_path),
    ExecutableProduct(prefix, "gdal_rasterize", :gdal_rasterize_path),
    ExecutableProduct(prefix, "gdal_translate", :gdal_translate_path),
    ExecutableProduct(prefix, "gdaladdo", :gdaladdo_path),
    ExecutableProduct(prefix, "gdalbuildvrt", :gdalbuildvrt_path),
    ExecutableProduct(prefix, "gdaldem", :gdaldem_path),
    ExecutableProduct(prefix, "gdalinfo", :gdalinfo_path),
    ExecutableProduct(prefix, "gdallocationinfo", :gdallocationinfo_path),
    ExecutableProduct(prefix, "gdalmanage", :gdalmanage_path),
    ExecutableProduct(prefix, "gdalsrsinfo", :gdalsrsinfo_path),
    ExecutableProduct(prefix, "gdaltindex", :gdaltindex_path),
    ExecutableProduct(prefix, "gdaltransform", :gdaltransform_path),
    ExecutableProduct(prefix, "gdalwarp", :gdalwarp_path),
    ExecutableProduct(prefix, "nearblack", :nearblack_path),
    ExecutableProduct(prefix, "ogr2ogr", :ogr2ogr_path),
    ExecutableProduct(prefix, "ogrinfo", :ogrinfo_path),
    ExecutableProduct(prefix, "ogrlineref", :ogrlineref_path),
    ExecutableProduct(prefix, "ogrtindex", :ogrtindex_path)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaGeo/GEOSBuilder/releases/download/v3.7.2-0/build_GEOS.v3.7.2.jl",
    "https://github.com/JuliaGeo/PROJBuilder/releases/download/v6.1.0-1/build_PROJ.v6.1.0.jl",
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl",
    "https://github.com/JuliaDatabases/SQLiteBuilder/releases/download/v0.10.0/build_SQLite.v3.28.0.jl",
    "https://github.com/JuliaWeb/LibCURLBuilder/releases/download/v0.5.1/build_LibCURL.v7.64.1.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "GDAL", src_version, sources, script, platforms, products, dependencies)
