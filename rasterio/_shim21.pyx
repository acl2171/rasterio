"""Rasterio shims for GDAL 2.1"""

# cython: boundscheck=False

include "directives.pxi"

# The baseline GDAL API.
include "gdal.pxi"

# Shim API for GDAL >= 2.0
include "shim_rasterioex.pxi"


# Declarations and implementations specific for GDAL >= 2.1
cdef extern from "gdal.h" nogil:

    cdef CPLErr GDALDeleteRasterNoDataValue(GDALRasterBandH hBand)
    GDALDatasetH GDALOpenEx(const char *filename, int flags, const char **allowed_drivers, const char **options, const char **siblings) # except -1

from rasterio._err cimport exc_wrap_pointer


cdef GDALDatasetH open_dataset(
        object filename, int flags, object allowed_drivers, object open_options,
        object siblings) except NULL:
    """Wrapper for GDALOpen and GDALOpenShared"""
    cdef char **drivers = NULL
    cdef char **options = NULL
    cdef GDALDatasetH hds = NULL
    cdef const char *fname = NULL

    filename = filename.encode('utf-8')
    fname = filename

    # Construct a null terminated C list of driver
    # names for GDALOpenEx.
    if allowed_drivers:
        for name in allowed_drivers:
            name = name.encode('utf-8')
            drivers = CSLAddString(drivers, <const char *>name)

    for k, v in open_options.items():
        k = k.upper().encode('utf-8')

        # Normalize values consistent with code in _env module.
        if isinstance(v, bool):
            v = ('ON' if v else 'OFF').encode('utf-8')
        else:
            v = str(v).encode('utf-8')

        options = CSLAddNameValue(options, <const char *>k, <const char *>v)

    # Ensure raster flags
    flags = flags | 0x02

    with nogil:
        hds = GDALOpenEx(fname, flags, drivers, options, NULL)
    try:
        return exc_wrap_pointer(hds)
    finally:
        CSLDestroy(drivers)
        CSLDestroy(options)


cdef int delete_nodata_value(GDALRasterBandH hBand) except 3:
    return GDALDeleteRasterNoDataValue(hBand)
