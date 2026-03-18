SUBROUTINE c_nemo_init(klocal_comm,kit000,kdastp) BIND(C)
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
      INTEGER (c_int), INTENT(OUT) ::   kdastp        ! date at first iteration
      !!----------------------------------------------------------------------
      
      ! Convert
      
      ! API - return starting iteration
      CALL nemo_api_init(klocal_comm)
      kit000 = nit000
      kdastp = ndastp
      
END SUBROUTINE c_nemo_init


SUBROUTINE c_nemo_advance(kite_start,kite_end,ld_rst,kinfo) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_init  ***
      !!
      !! ** Purpose :   C interface for advancing time loop
      !!----------------------------------------------------------------------
      USE iso_c_binding, ONLY: c_int
      USE nemo_api

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      INTEGER (c_int), INTENT(IN)  ::   kite_end, kite_start ! number of time iteration
      INTEGER (c_int), INTENT(IN)  ::   ld_rst               ! write restart at kite_end
      INTEGER (c_int), INTENT(OUT) ::   kinfo
      ! Local variables
      !!----------------------------------------------------------------------
      
      ! Restart
      IF ( ld_rst == 1 ) nitrst = kite_end

      ! API - return error flag
      CALL nemo_api_advance(kite_start,kite_end)
      kinfo = nstop

      IF ( ld_rst == 1 ) nitrst = nitend

END SUBROUTINE c_nemo_advance


SUBROUTINE c_nemo_restart_ite(kite_curr,kite_restart) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_restart_ite  ***
      !!
      !! ** Purpose :   Returns number of minimal required iteration to perform 
      !!                writing of restart fils from current iteration 
      !!----------------------------------------------------------------------
      USE iso_c_binding, ONLY: c_int
      USE nemo_api

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      INTEGER (c_int), INTENT(IN)  :: kite_curr
      INTEGER (c_int), INTENT(OUT) :: kite_restart
      ! Local variables
      INTEGER :: ioce, iice
      !!----------------------------------------------------------------------

      ! API
      ioce = kite_curr + 1
#if defined key_si3
      iice = MOD( kite_curr - nit000, nn_fsbc ) + kite_curr + 2*nn_fsbc - 1  
#else
      iice = -1
#endif
      kite_restart = MAX( ioce, iice )

END SUBROUTINE c_nemo_restart_ite


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
      ! convert

      ! API
      CALL nemo_api_finalization(0)
      
END SUBROUTINE c_nemo_finalization


SUBROUTINE c_nemo_get_size(cd_varname_c,knx,kny,knz) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  FUNCTION c_nemo_get_size  ***
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

      ! Convert inputs
      CALL c_string_to_fortran(cd_varname_c, cd_varname_f)

      ! Get size
      SELECT CASE (cd_varname_f)

#define field(name, array, time) \
          CASE (name); CALL array_size(array,time,knx,kny,knz)
#include "field_dict.h90"
#undef field

      END SELECT

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
      INTEGER :: kdimt
      REAL(wp) :: buffer(knx,kny,knz)
      !!----------------------------------------------------------------------

      ! Convert inputs
      CALL c_string_to_fortran(cd_varname_c, cd_varname_f)

      ! Default value
      kdimt = Nbb
      
      ! Get field
      SELECT CASE (cd_varname_f)

#define field(name, array, time) \
          CASE (name); CALL copy_array(array,time,kdimt,buffer)
#include "field_dict.h90"
#undef field

      END SELECT

      ! Convert outputs
      pval = REAL( buffer, kind=c_double ) 

ENd SUBROUTINE c_nemo_get_val


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
      INTEGER :: kdimt
      REAL(wp) :: buffer(knx,kny,knz)
      !!----------------------------------------------------------------------

      ! Convert inputs
      CALL c_string_to_fortran(cd_varname_c, cd_varname_f)
      buffer = REAL( pval, kind=wp )

      ! Default value
      kdimt = Nbb
      
      ! Set
      SELECT CASE (cd_varname_f)

#define field(name, array, time) \
          CASE (name); CALL copy_buffer(array,time,kdimt,buffer)
#include "field_dict.h90"
#undef field

      END SELECT

END SUBROUTINE c_nemo_set_val
