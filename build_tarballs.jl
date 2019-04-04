using BinaryBuilder


src_version = v"2.4.1"  # also change in raw script string

# Collection of sources required to build GDAL
sources = [
    "https://download.osgeo.org/gdal/$src_version/gdal-$src_version.tar.xz" =>
    "fd51b4900b2fc49b98d8714f55fc8a78ebfd07218357f93fb796791115a5a1ad",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd gdal-2.4.1/

# Show options in the log
./configure --help

./configure --prefix=$prefix --host=$target \
    --with-geos=$prefix/bin/geos-config \
    --with-static-proj4=$prefix \
    --with-libz=$prefix \
    --with-sqlite3=$prefix \
    --with-curl=$prefix/bin/curl-config \
    --enable-shared=yes \
    --enable-static=no
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
    "https://github.com/JuliaGeo/GEOSBuilder/releases/download/v3.7.1-5/build_GEOS.v3.7.1.jl",
    "https://github.com/JuliaGeo/PROJBuilder/releases/download/v5.2.0-0/build_PROJ.v5.2.0.jl",
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl",
    "https://github.com/JuliaDatabases/SQLiteBuilder/releases/download/v0.9.0/build_SQLiteBuilder.v0.1.0.jl",
    "https://github.com/JuliaWeb/LibCURLBuilder/releases/download/v0.4.0/build_LibCURL.v7.64.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "GDAL", src_version, sources, script, platforms, products, dependencies)
