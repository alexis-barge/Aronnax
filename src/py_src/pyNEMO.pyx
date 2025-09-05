# cython: language_level=3
# distutils: language = c
# cython: boundscheck=True, wraparound=False

import numpy as np
cimport numpy as np

""" Import Fortran interface - nogil since Fortran does not manipulate Python objects """
cdef extern void c_nemo_init(int *klocalcomm, int *kit000) nogil
cdef extern void c_nemo_advance(int *kite, int *kite_start, float *pstp_c, int *ldiag_c) nogil
cdef extern void c_nemo_finalization(int *kitend) nogil

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


def nemo_advance(ite,ite_start,stp,diag):
    # Check types
    if not isinstance(ite, (int,np.integer)):
        raise TypeError(f"nemo_advance: ite must be int, got {type(ite)}")
    if not isinstance(ite_start, (int,np.integer)):
        raise TypeError(f"nemo_advance: ite_start must be int, got {type(ite_start)}")
    if not isinstance(stp, (float,np.floating)):
        raise TypeError(f"nemo_advance: stp must be float, got {type(stp)}")
    if not isinstance(diag, (bool,np.bool_)):
        raise TypeError(f"nemo_advance: diag must be bool, got {type(diag)}")

    # convert
    cdef int kite = ite
    cdef int kite_start = ite_start 
    cdef float pstp_c = stp
    cdef int ldiag_c = diag

    # call
    with nogil:
        c_nemo_advance(&kite, &kite_start, &pstp_c, &ldiag_c)


def nemo_finalization(itend):
    # Check types
    if not isinstance(itend, (int,np.integer)):
        raise TypeError(f"nemo_finalization: itend must be int, got {type(itend)}")

    # convert
    cdef int kitend = itend

    # call
    with nogil:
        c_nemo_finalization(&kitend)
