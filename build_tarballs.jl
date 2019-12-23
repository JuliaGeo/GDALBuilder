using BinaryBuilder


src_version = v"3.0.2"  # also change in raw script string

# Collection of sources required to build GDAL
sources = [
    "https://download.osgeo.org/gdal/$src_version/gdal-$src_version.tar.xz" =>
    "c3765371ce391715c8f28bd6defbc70b57aa43341f6e94605f04fe3c92468983",
    "https://curl.haxx.se/download/curl-7.64.1.tar.gz" =>
    "432d3f466644b9416bc5b649d344116a753aeaa520c8beaf024a90cba9d3d35d",
]

# Bash recipe for building across all platforms
script = raw"""

# CURL

cd $WORKSPACE/srcdir/curl-7.64.1
# Configure and build
./configure \
    --prefix=$prefix \
    --host=$target \
    --with-mbedtls \
    --without-ssl \
    --disable-manual
if [[ $target == *-w64-mingw32 ]]; then
    LDFLAGS="$LDFLAGS -L$prefix/bin"
elif [[ $target == x86_64-apple-darwin14 ]]; then
    LDFLAGS="$LDFLAGS -L$prefix/lib -Wl,-rpath,$prefix/lib"
else
    LDFLAGS="$LDFLAGS -L$prefix/lib -Wl,-rpath-link,$prefix/lib"
fi
make -j${nproc} LDFLAGS="$LDFLAGS" CPPFLAGS="$CPPFLAGS -I$prefix/include"
make install



# GDAL

cd $WORKSPACE/srcdir/gdal-3.0.2/

if [[ ${target} == *w64-mingw32* ]]; then
    # Symlink libproj for Windows, else configure couldn't find it
    # TODO fix in PROJBuilder or in GDAL configure?
    ln -s $prefix/lib/libproj_6_1.dll.a $prefix/lib/libproj.dll.a
    # Also symlink the library folder of mingw, so libstdc++ and
    # others can be found. The path is ignored by BinaryBuilder.
    mkdir $prefix/$target
    ln -s /opt/$target/$target/lib $prefix/$target/lib
elif [[ ${target} == *freebsd* ]]; then
    # FreeBSD's default Clang ran into issues with configure
    # which seemed to think it was the GNU compiler. Therefore,
    # let's just use the GNU compiler instead.
    CC=gcc
    CXX=g++
elif [[ ${target} == *64-linux* ]]; then
    # Symlink the library folder of mingw, so libstdc++ and
    # others can be found.
    mkdir $prefix/$target
    ln -s /opt/$target/$target/lib $prefix/$target/lib
    ln -s /opt/$target/$target/lib64/*.so* $prefix/lib/
elif [[ ${target} == *i686-linux* ]]; then
    # Symlink the library folder so libstdc++ and
    # others can be found.
    mkdir $prefix/$target
    ln -s /opt/$target/$target/lib $prefix/$target/lib
    ln -s /opt/$target/$target/lib/*.so* $prefix/lib/
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
    --enable-shared \
    --disable-static \
    "CC=$CC" \
    "CXX=$CXX"
    #"CFLAGS=-Wl,-rpath-link=/opt/x86_64-linux-gnu/x86_64-linux-gnu/lib64"

make -j${nproc}
make install

# strip shared libraries to reduce filesize
if [[ ${target} == *w64-mingw32* ]]; then
    strip $prefix/bin/*.dll
elif [[ ${target} == *apple-darwin* ]]; then
    :
else
    strip $prefix/lib/libgdal.so
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gcc_versions(platforms)

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libgdal", :libgdal),
    LibraryProduct(prefix, "libcurl", :libcurl),
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
    "https://github.com/JuliaWeb/MbedTLSBuilder/releases/download/v0.20.0/build_MbedTLS.v2.6.1.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "GDAL", src_version, sources, script, platforms, products, dependencies)
