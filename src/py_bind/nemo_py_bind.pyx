# cython: language_level=3
# distutils: language = c
# cython: boundscheck=True, wraparound=False

import numpy as np

""" Import Fortran interface - nogil since Fortran does not manipulate Python objects """
cdef extern void c_nemo_init(int *klocalcomm, int *kit000, int *kdastp) nogil
cdef extern void c_nemo_advance(int *kite_start, int *kite_end, int *kinfo) nogil
cdef extern void c_nemo_get_size(const char **cd_varname_c, int *knx, int *kny, int *knz) nogil
cdef extern void c_nemo_get_val(const char **cd_varname_c, int *knx, int *kny, int *knz, double *pval) nogil
cdef extern void c_nemo_set_val(const char **cd_varname_c, int *knx, int *kny, int *knz, double *pval) nogil
cdef extern void c_nemo_finalization(int *kite, int *ll_write_rst) nogil

# --------------------------------------------------------------------------------------------- #

def nemo_init(localcomm):
    # Check types
    if not isinstance(localcomm, (int)):
        raise TypeError(f"Cython layer -- nemo_init: localcomm must be int, got {type(localcomm)}")

    # convert
    cdef int klocalcomm = localcomm
    cdef int kit000 = 0
    cdef int kdastp = 0

    # call
    with nogil:
        c_nemo_init(&klocalcomm,&kit000,&kdastp)

    return kit000, f"{kdastp:08d}" 


def nemo_advance(ite_start,ite_end):
    # Check types
    if not isinstance(ite_start, (int,np.integer)):
        raise TypeError(f"Cython layer -- nemo_advance: ite_start must be int, got {type(ite_start)}")
    if not isinstance(ite_end, (int,np.integer)):
        raise TypeError(f"Cython layer -- nemo_advance: ite_end must be int, got {type(ite_end)}")

    # convert
    cdef int kite_start = ite_start
    cdef int kite_end = ite_end 
    cdef int kinfo = 0

    # call
    with nogil:
        c_nemo_advance(&kite_start, &kite_end, &kinfo)

    return kinfo


def nemo_get_val(varname):
    # Check types 
    if not isinstance(varname, (str)): 
        raise TypeError(f"Cython layer -- nemo_get_val: varname must be str, got {type(varname)}")

    # convert
    cdef bytes varname_tmp = varname.lower().encode("utf-8")
    cdef const char *cd_varname_c = varname_tmp

    # empty array
    cdef int nx, ny, nz
    c_nemo_get_size(&cd_varname_c,&nx,&ny,&nz)
    cdef double[:,:,:] pval = np.empty( (nx,ny,nz) , dtype=np.float64, order="F")

    # call
    with nogil:
        c_nemo_get_val(&cd_varname_c,&nx,&ny,&nz,&pval[0,0,0])

    return pval.base


def nemo_set_val(varname,val):
    # Check types 
    if not isinstance(varname, (str)): 
        raise TypeError(f"Cython layer -- nemo_set_val: varname must be str, got {type(varname)}")
    if not isinstance(val, (np.ndarray)): 
        raise TypeError(f"Cython layer -- nemo_set_val: val must be array, got {type(val)}")

    # Convert
    cdef bytes varname_tmp = varname.lower().encode("utf-8")
    cdef const char *cd_varname_c = varname_tmp
    cdef double [:,:,:] pval = np.array( val, dtype=np.float64)

    # Check size
    cdef int nx, ny, nz
    c_nemo_get_size(&cd_varname_c,&nx,&ny,&nz)

    if val.shape != (nx,ny,nz):
        raise TypeError(f"Cython layer -- nemo_set_val: array size {val.shape} to set does not match {varname} NEMO size")

    # call
    with nogil:
        c_nemo_set_val(&cd_varname_c,&nx,&ny,&nz,&pval[0,0,0])


def nemo_finalization(ite,write_rst):
    # Check types 
    if not isinstance(ite, (int)): 
        raise TypeError(f"Cython layer -- nemo_finalization: ite must be int, got {type(ite)}")
    if not isinstance(write_rst, (int)): 
        raise TypeError(f"Cython layer -- nemo_finalization: write_rst must be int, got {type(write_rst)}")
    
    # convert
    cdef int kite = ite
    cdef int ll_write_rst = write_rst
    
    # call
    with nogil:
        c_nemo_finalization(&kite,&ll_write_rst)
