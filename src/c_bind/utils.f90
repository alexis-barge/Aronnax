MODULE utils

   IMPLICIT NONE

CONTAINS

    SUBROUTINE c_string_to_fortran(string_c, string_f)
        !!----------------------------------------------------------------------
        !!                     ***  SUBROUTINE c_string_to_fortran  ***
        !!
        !! ** Purpose :   convert C string to Fortran character
        !!----------------------------------------------------------------------

        USE iso_c_binding, ONLY: c_ptr, c_int, c_f_pointer, C_NULL_CHAR

        IMPLICIT NONE

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

END MODULE utils
