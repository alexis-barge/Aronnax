MODULE test_utils
    USE iso_c_binding, ONLY: c_ptr, c_f_pointer, C_NULL_CHAR
    IMPLICIT NONE

    INTEGER, PUBLIC, PARAMETER :: wp = SELECTED_REAL_KIND(15,307)

    CONTAINS

        SUBROUTINE c_string_to_fortran(string_c, string_f)
            !!----------------------------------------------------------------------
            !!                     ***  SUBROUTINE c_string_to_fortran  ***
            !!
            !! ** Purpose :   convert C string to Fortran character
            !!----------------------------------------------------------------------
            ! I/O
            TYPE(c_ptr), INTENT(IN) :: string_c
            CHARACTER(len=:), ALLOCATABLE, INTENT(OUT) :: string_f
            ! Local variables
            INTEGER :: i
            INTEGER, PARAMETER :: MAX_LEN = 50
            CHARACTER(len=MAX_LEN) :: long_string
            CHARACTER, POINTER :: p_char(:)
            CHARACTER :: char
            !!----------------------------------------------------------------------

            ! convert C pointer to Fortran
            CALL c_f_pointer(string_c, p_char, [MAX_LEN])

            ! browse and concatenate each character
            DO i = 1, MAX_LEN
                char = p_char(i)
                IF (char == C_NULL_CHAR) THEN
                    EXIT
                END IF
                long_string(i:i) = char
            END DO

            ! store final character chain
            ALLOCATE(CHARACTER(len=i-1) :: string_f)
            string_f = long_string(1:i-1)

        END SUBROUTINE c_string_to_fortran

END MODULE test_utils


SUBROUTINE c_nemo_init(klocal_comm,kit000,kdastp) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_init  ***
      !!
      !! ** Purpose :   C interface for NEMO initialization
      !!----------------------------------------------------------------------
      USE iso_c_binding, ONLY: c_int

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      INTEGER (c_int), INTENT(IN)  ::   klocal_comm   ! imposed communicator
      INTEGER (c_int), INTENT(OUT) ::   kit000        ! first iteration
      INTEGER (c_int), INTENT(OUT) ::   kdastp        ! date at first iteration
      !!----------------------------------------------------------------------
      
      ! Outputs
      kit000 = 5
      kdastp = 10105
      
END SUBROUTINE c_nemo_init


SUBROUTINE c_nemo_advance(kite_start,kite_end,ld_rst,kdastp,kinfo) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_init  ***
      !!
      !! ** Purpose :   C interface for advancing time loop
      !!----------------------------------------------------------------------
      USE iso_c_binding, ONLY: c_int

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      INTEGER (c_int), INTENT(IN)  ::   kite_end, kite_start ! number of time iteration
      INTEGER (c_int), INTENT(IN)  ::   ld_rst               ! write restart at kite_end
      INTEGER (c_int), INTENT(OUT) ::   kinfo, kdastp
      ! Local variables
      INTEGER :: ierr = 0
      !!----------------------------------------------------------------------

      ! check inputs
      IF (kite_start .NE. 5) ierr = 1
      IF (kite_end .NE. 10) ierr = 1
      IF (ld_rst .GT. 1) ierr = 1

      ! Outputs
      IF (ld_rst .EQ. 1) THEN
          kdastp = 123456
          kinfo = 0
      ELSE IF (ld_rst .EQ. 0) THEN
          kdastp = 456789
          kinfo = 1
      END IF
      
      IF (ierr .EQ. 1) THEN
          kdastp = -1
          kinfo = -1
      END IF

END SUBROUTINE c_nemo_advance


SUBROUTINE c_nemo_finalization() BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_finalization  ***
      !!
      !! ** Purpose :   C interface for NEMO finalization
      !!----------------------------------------------------------------------

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      ! Local variables
      !!----------------------------------------------------------------------
      ! convert

      ! API
      
END SUBROUTINE c_nemo_finalization


SUBROUTINE c_nemo_get_size(cd_varname_c,knx,kny,knz) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  FUNCTION c_nemo_get_size  ***
      !!
      !! ** Purpose :   C interface to get NEMO array size
      !!----------------------------------------------------------------------
      USE iso_c_binding, ONLY: c_int, c_ptr
      USE test_utils

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

          CASE ('t')
              knx = 100
              kny = 50
              knz = 10
          
          CASE ('s')
              knx = 200
              kny = 100
              knz = 20
      
          CASE DEFAULT
              knx = 5
              kny = 5
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
      USE test_utils

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      TYPE (c_ptr), INTENT(IN) :: cd_varname_c
      INTEGER (c_int), INTENT(IN) :: knx, kny, knz
      REAL (c_double), INTENT(OUT) :: pval(knx,kny,knz)
      ! Local variables
      CHARACTER(len=:), ALLOCATABLE :: cd_varname_f
      INTEGER :: kdimt, ierr
      REAL(wp) :: buffer(knx,kny,knz)
      !!----------------------------------------------------------------------

      ! test error
      ierr = 0

      ! Convert inputs
      CALL c_string_to_fortran(cd_varname_c, cd_varname_f)

      IF (cd_varname_f .NE. 't' .AND. cd_varname_f .NE. 's') ierr = 1
      
      ! Get field
      SELECT CASE (cd_varname_f)

          CASE ('t')
              buffer = 5.0

          CASE ('s')
              buffer = 10.0

      END SELECT

      IF (ierr .EQ. 1) THEN
          buffer = -1.0
      END IF
      
      ! Convert outputs
      pval = REAL( buffer, kind=c_double ) 

ENd SUBROUTINE c_nemo_get_val


SUBROUTINE c_nemo_set_val(cd_varname_c,knx,kny,knz,pval,kerr) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_get  ***
      !!
      !! ** Purpose :   C interface to set NEMO variables values
      !!----------------------------------------------------------------------
      USE iso_c_binding, ONLY: c_ptr, c_double, c_int
      USE test_utils

      IMPLICIT NONE

      !!----------------------------------------------------------------------
      ! I/O
      TYPE (c_ptr), INTENT(IN) :: cd_varname_c
      INTEGER (c_int), INTENT(IN) :: knx, kny, knz
      REAL (c_double), INTENT(IN) :: pval(knx,kny,knz)
      INTEGER (c_int), INTENT(OUT) :: kerr
      ! Local variables
      CHARACTER(len=:), ALLOCATABLE :: cd_varname_f
      INTEGER :: kdimt
      REAL(wp) :: buffer(knx,kny,knz)
      !!----------------------------------------------------------------------

      ! test error
      kerr = 0

      ! Convert inputs
      CALL c_string_to_fortran(cd_varname_c, cd_varname_f)

      IF (cd_varname_f .NE. 't') kerr = 1

      ! check size
      IF (SIZE(pval,1) .NE. 100) kerr = 1
      IF (SIZE(pval,2) .NE. 50) kerr = 1
      IF (SIZE(pval,3) .NE. 10) kerr = 1

      ! check set      
      buffer = REAL( pval, kind=wp )
      IF (.NOT. ALL(buffer .EQ. 20.0)) kerr = 1

END SUBROUTINE c_nemo_set_val
