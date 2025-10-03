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

      ! Get size
      knx = jpi
      kny = jpj
      SELECT CASE (cd_varname_f)

          CASE ("u","v","w","t","s","rhop")
             knz = jpk

          CASE ("ssh","e1t","e2t","e1u","e2u","e1v","e2v","e1f","e2f")
             knz = 1

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
      !!----------------------------------------------------------------------

      ! Convert
      CALL c_string_to_fortran(cd_varname_c, cd_varname_f)

      ! API
      SELECT CASE (cd_varname_f)

          CASE ("t") 
             pval(:,:,:) = REAL( ts(:,:,:,jp_tem,Nnn), kind=c_double)

          CASE ("s")
             pval(:,:,:) = REAL( ts(:,:,:,jp_sal,Nnn), kind=c_double)

          CASE ("u")
             pval(:,:,:) = REAL( uu(:,:,:,Nnn), kind=c_double)

          CASE ("v")
             pval(:,:,:) = REAL( vv(:,:,:,Nnn), kind=c_double)

          CASE ("w")
             pval(:,:,:) = REAL( ww(:,:,:), kind=c_double)

          CASE ("ssh")
             pval(:,:,knz) = REAL( ssh(:,:,Nnn), kind=c_double)

          CASE ("e1t")
             pval(:,:,knz) = REAL( e1t(:,:), kind=c_double)

          CASE ("e2t")
             pval(:,:,knz) = REAL( e2t(:,:), kind=c_double)

          CASE ("e1u")
             pval(:,:,knz) = REAL( e1u(:,:), kind=c_double)

          CASE ("e2u")
             pval(:,:,knz) = REAL( e2u(:,:), kind=c_double)

          CASE ("e1v")
             pval(:,:,knz) = REAL( e1v(:,:), kind=c_double)

          CASE ("e2v")
             pval(:,:,knz) = REAL( e2v(:,:), kind=c_double)

          CASE ("e1f")
             pval(:,:,knz) = REAL( e1f(:,:), kind=c_double)

          CASE ("e2f")
             pval(:,:,knz) = REAL( e2f(:,:), kind=c_double)

          CASE DEFAULT
             pval(:,:,:) = 0.0

      END SELECT

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
      SELECT CASE (cd_varname_f)

          CASE ("t") 
             ts(:,:,:,jp_tem,Nnn) = REAL( pval(:,:,:), kind=wp )

          CASE ("s") 
             ts(:,:,:,jp_sal,Nnn) = REAL( pval(:,:,:), kind=wp )

          CASE ("u") 
             uu(:,:,:,Nnn) = REAL( pval(:,:,:), kind=wp )

          CASE ("v") 
             vv(:,:,:,Nnn) = REAL( pval(:,:,:), kind=wp )

          CASE ("w") 
             ww(:,:,:) = REAL( pval(:,:,:), kind=wp )

          CASE ("ssh") 
             ssh(:,:,Nnn) = REAL( pval(:,:,knz), kind=wp )

          CASE ("e1t") 
             e1t(:,:) = REAL( pval(:,:,knz), kind=wp )

          CASE ("e2t") 
             e2t(:,:) = REAL( pval(:,:,knz), kind=wp )

          CASE ("e1u") 
             e1u(:,:) = REAL( pval(:,:,knz), kind=wp )

          CASE ("e2u") 
             e2u(:,:) = REAL( pval(:,:,knz), kind=wp )

          CASE ("e1v") 
             e1v(:,:) = REAL( pval(:,:,knz), kind=wp )

          CASE ("e2v") 
             e2v(:,:) = REAL( pval(:,:,knz), kind=wp )

          CASE ("e1f") 
             e1f(:,:) = REAL( pval(:,:,knz), kind=wp )

          CASE ("e2f") 
             e2f(:,:) = REAL( pval(:,:,knz), kind=wp )

      END SELECT

END SUBROUTINE c_nemo_set_val
