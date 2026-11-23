# cython: language_level=3
# distutils: language = c
# cython: boundscheck=True, wraparound=False

import numpy as np

""" Import Fortran interface - nogil since Fortran does not manipulate Python objects """
cdef extern void c_nemo_init(int *klocalcomm, int *kit000, int *kdastp) nogil
cdef extern void c_nemo_advance(int *kite_start, int *kite_end, int *ld_rst, int *kdastp, int *kinfo) nogil
cdef extern void c_nemo_get_size(const char **cd_varname_c, int *knx, int *kny, int *knz) nogil
cdef extern void c_nemo_get_val(const char **cd_varname_c, int *knx, int *kny, int *knz, double *pval) nogil
cdef extern void c_nemo_set_val(const char **cd_varname_c, int *knx, int *kny, int *knz, double *pval, int *kerr) nogil
cdef extern void c_nemo_finalization(int *kerr) nogil

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


def nemo_advance(ite_start,ite_end,rst):
    # Check types
    if not isinstance(ite_start, (int,np.integer)):
        raise TypeError(f"Cython layer -- nemo_advance: ite_start must be int, got {type(ite_start)}")
    if not isinstance(ite_end, (int,np.integer)):
        raise TypeError(f"Cython layer -- nemo_advance: ite_end must be int, got {type(ite_end)}")
    if not isinstance(rst, (int,np.integer)):
        raise TypeError(f"Cython layer -- nemo_advance: rst must be int, got {type(rst)}")

    # convert
    cdef int kite_start = ite_start
    cdef int kite_end = ite_end 
    cdef int ld_rst = rst
    cdef int kdastp = 0
    cdef int kinfo = 0

    # call
    with nogil:
        c_nemo_advance(&kite_start, &kite_end, &ld_rst, &kdastp, &kinfo)

    return kinfo, kdastp


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
    cdef int err

    # Check size
    cdef int nx, ny, nz
    c_nemo_get_size(&cd_varname_c,&nx,&ny,&nz)

    if val.shape != (nx,ny,nz):
        raise TypeError(f"Cython layer -- nemo_set_val: array size {val.shape} to set does not match {varname} NEMO size ({nx},{ny},{nz})")

    # call
    with nogil:
        c_nemo_set_val(&cd_varname_c,&nx,&ny,&nz,&pval[0,0,0],&err)

    return err

def nemo_finalization():
    # convert
    cdef int err

    # call
    with nogil:
        c_nemo_finalization(&err)

    return err
