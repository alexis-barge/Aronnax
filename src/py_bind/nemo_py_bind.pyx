# cython: language_level=3
# distutils: language = c
# cython: boundscheck=True, wraparound=False

import numpy as np

""" Import Fortran interface - nogil since Fortran does not manipulate Python objects """
cdef extern void c_nemo_init(int *klocalcomm, int *kit000) nogil
cdef extern void c_nemo_advance(int *kite_start, int *kite_end, float *pstp_c ,int *kinfo) nogil
cdef extern void c_nemo_get_size(const char **cd_varname_c, int *knx, int *kny, int *knz) nogil
cdef extern void c_nemo_get_val(const char **cd_varname_c, int *knx, int *kny, int *knz, double *pval) nogil
cdef extern void c_nemo_set_val(const char **cd_varname_c, int *knx, int *kny, int *knz, double *pval) nogil
cdef extern void c_nemo_finalization() nogil

# --------------------------------------------------------------------------------------------- #

def nemo_init(localcomm):
    # Check types
    if not isinstance(localcomm, (int)):
        raise TypeError(f"init_nemo: localcomm must be int, got {type(localcomm)}")

    # convert
    cdef int klocalcomm = localcomm
    cdef int kit000 = 0

    # call
    with nogil:
        c_nemo_init(&klocalcomm,&kit000)

    return kit000 


def nemo_advance(ite_start,ite_end,stp):
    # Check types
    if not isinstance(ite_start, (int,np.integer)):
        raise TypeError(f"nemo_advance: ite_start must be int, got {type(ite_start)}")
    if not isinstance(ite_end, (int,np.integer)):
        raise TypeError(f"nemo_advance: ite_end must be int, got {type(ite_end)}")
    if not isinstance(stp, (float,np.floating)):
        raise TypeError(f"nemo_advance: stp must be float, got {type(stp)}")

    # convert
    cdef int kite_start = ite_start
    cdef int kite_end = ite_end 
    cdef float pstp_c = stp
    cdef int kinfo = 0

    # call
    with nogil:
        c_nemo_advance(&kite_start, &kite_end, &pstp_c, &kinfo)

    return kinfo


def nemo_get_val(varname):
    # Check types 
    if not isinstance(varname, (str)): 
        raise TypeError(f"nemo_get_val: varname must be str, got {type(varname)}")

    # convert
    cdef bytes varname_tmp = varname.encode("utf-8")
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
        raise TypeError(f"nemo_set_val: varname must be str, got {type(varname)}")
    if not isinstance(val, (np.ndarray)): 
        raise TypeError(f"nemo_set_val: val must be array, got {type(val)}")

    # Convert
    cdef bytes varname_tmp = varname.encode("utf-8")
    cdef const char *cd_varname_c = varname_tmp
    cdef double [:,:,:] pval = np.array( val, dtype=np.float64)

    # Check size
    cdef int nx, ny, nz
    c_nemo_get_size(&cd_varname_c,&nx,&ny,&nz)

    if val.shape != (nx,ny,nz):
        raise TypeError(f"nemo_set_val: array size {val.shape} to set does not match {varname} NEMO size")

    # call
    with nogil:
        c_nemo_set_val(&cd_varname_c,&nx,&ny,&nz,&pval[0,0,0])


def nemo_finalization():
    # call
    with nogil:
        c_nemo_finalization()
