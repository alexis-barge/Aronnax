SUBROUTINE c_nemo_init(klocal_comm,kit000) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_init  ***
      !!
      !! ** Purpose :   C interface for NEMO initialization
      !!----------------------------------------------------------------------

      USE iso_c_binding, ONLY: c_int
      USE nemo_api

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      INTEGER (c_int), INTENT(IN)  ::   klocal_comm   ! imposed communicator
      INTEGER (c_int), INTENT(OUT) ::   kit000        ! first iteration
      !!----------------------------------------------------------------------
      
      ! Convert
      
      ! API - return starting iteration
      CALL nemo_api_init(klocal_comm)
      kit000 = nit000
      
END SUBROUTINE c_nemo_init


SUBROUTINE c_nemo_advance(kite_start,kite_end,pstp_c,kinfo) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_init  ***
      !!
      !! ** Purpose :   C interface for advancing time loop
      !!----------------------------------------------------------------------

      USE iso_c_binding, ONLY: c_int, c_float
      USE nemo_api

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      INTEGER (c_int), INTENT(IN) ::   kite_end, kite_start ! number of time iteration
      INTEGER (c_float), INTENT(IN) :: pstp_c               ! time step - C
      INTEGER (c_int), INTENT(OUT)  :: kinfo
      ! Local variables
      REAL(wp) :: pstp_f        ! time step - Fortran
      !!----------------------------------------------------------------------
      
      ! Convert
      pstp_f = REAL(pstp_c, kind=wp)
      
      ! API - return error flag
      CALL nemo_api_advance(kite_start,kite_end)
      kinfo = nstop

END SUBROUTINE c_nemo_advance


SUBROUTINE c_nemo_finalization() BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_finalization  ***
      !!
      !! ** Purpose :   C interface for NEMO finalization
      !!----------------------------------------------------------------------

      USE nemo_api

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      ! Local variables
      !!----------------------------------------------------------------------
      
      ! Convert
      
      ! API
      CALL nemo_api_finalization(0)
      
END SUBROUTINE c_nemo_finalization


SUBROUTINE c_nemo_get_size(cd_varname_c,knx,kny,knz) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  FUNCTION c_nemo_geti_size  ***
      !!
      !! ** Purpose :   C interface to get NEMO array size
      !!----------------------------------------------------------------------

      USE iso_c_binding, ONLY: c_int, c_ptr
      USE nemo_api
      USE utils

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      TYPE (c_ptr), INTENT(IN) :: cd_varname_c
      INTEGER (c_int), INTENT(OUT) :: knx, kny, knz
      ! Local variables
      CHARACTER(len=:), ALLOCATABLE :: cd_varname_f
      !!----------------------------------------------------------------------

      ! Convert
      CALL c_string_to_fortran(cd_varname_c, cd_varname_f)

      ! API
      knx = jpi 
      kny = jpj
      knz = jpk

END SUBROUTINE c_nemo_get_size


SUBROUTINE c_nemo_get_val(cd_varname_c,knx,kny,knz,pval) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_get  ***
      !!
      !! ** Purpose :   C interface to get NEMO variables values
      !!----------------------------------------------------------------------

      USE iso_c_binding, ONLY: c_ptr, c_double, c_int
      USE nemo_api
      USE utils

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      TYPE (c_ptr), INTENT(IN) :: cd_varname_c
      INTEGER (c_int), INTENT(IN) :: knx, kny, knz
      REAL (c_double), INTENT(OUT) :: pval(knx,kny,knz)
      ! Local variables
      CHARACTER(len=:), ALLOCATABLE :: cd_varname_f
      !!----------------------------------------------------------------------

      ! Convert
      CALL c_string_to_fortran(cd_varname_c, cd_varname_f)

      ! API
      pval(:,:,:) = REAL( ts(:,:,:,1,1), kind=c_double)

END SUBROUTINE c_nemo_get_val


SUBROUTINE c_nemo_set_val(cd_varname_c,knx,kny,knz,pval) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_get  ***
      !!
      !! ** Purpose :   C interface to set NEMO variables values
      !!----------------------------------------------------------------------

      USE iso_c_binding, ONLY: c_ptr, c_double, c_int
      USE nemo_api
      USE utils

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      TYPE (c_ptr), INTENT(IN) :: cd_varname_c
      INTEGER (c_int), INTENT(IN) :: knx, kny, knz
      REAL (c_double), INTENT(IN) :: pval(knx,kny,knz)
      ! Local variables
      CHARACTER(len=:), ALLOCATABLE :: cd_varname_f
      !!----------------------------------------------------------------------

      ! Convert
      CALL c_string_to_fortran(cd_varname_c, cd_varname_f)

      ! API
      ts(:,:,:,1,1) = REAL( pval(:,:,:), kind=wp )

END SUBROUTINE c_nemo_set_val
