# cython: language_level=3
# distutils: language = c
# cython: boundscheck=True, wraparound=False

import numpy as np
cimport numpy as np

""" Import Fortran interface - nogil since Fortran does not manipulate Python objects """
cdef extern void c_nemo_init(int *klocalcomm, int *kit000) nogil
cdef extern void c_nemo_advance(int *kite_start, int *kite_end, float *pstp_c, int *kinfo) nogil
cdef extern void c_nemo_get(const char **cd_varname_c) nogil
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


def nemo_get(varname):
    # Check types 
    if not isinstance(varname, (str)): 
        raise TypeError(f"nemo_get: varname must be str, got {type(varname)}")

    # convert
    cdef bytes varname_tmp = varname.encode("utf-8")
    cdef const char *cd_varname_c = varname_tmp
    
    # call
    with nogil:
        c_nemo_get(&cd_varname_c)


def nemo_finalization():
    # call
    with nogil:
        c_nemo_finalization()
