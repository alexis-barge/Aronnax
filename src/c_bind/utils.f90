MODULE utils

   USE nemo_api, ONLY: wp

   IMPLICIT NONE

CONTAINS

    SUBROUTINE array_size(array,time,knx,kny,knz)
        !!----------------------------------------------------------------------
        !!                     ***  SUBROUTINE array_size  ***
        !!
        !! ** Purpose :   return size of spatial dimensions of array
        !!----------------------------------------------------------------------
        ! I/O
        REAL(wp), INTENT(IN) :: array(..)
        INTEGER, INTENT(IN) :: time
        INTEGER, INTENT(OUT) :: knx,kny,knz
        ! local variables
        INTEGER :: isize
        !!----------------------------------------------------------------------
        
        ! Default values 
        knx = 1
        kny = 1
        knz = 1

        ! Number of spatial dimensions
        isize = RANK(array) - time
        IF (isize >= 1) knx = SIZE(array, dim=1)
        IF (isize >= 2) kny = SIZE(array, dim=2)
        IF (isize >= 3) knz = SIZE(array, dim=3)

    END SUBROUTINE array_size


    SUBROUTINE copy_array(array,time,kdimt,buffer)
        !!----------------------------------------------------------------------
        !!                     ***  SUBROUTINE copy_array  ***
        !!
        !! ** Purpose :   copy array in buffer
        !!----------------------------------------------------------------------
        ! I/O
        REAL(wp), INTENT(IN) :: array(..)
        INTEGER, INTENT(IN) :: time, kdimt
        REAL(wp), INTENT(OUT) :: buffer(:,:,:)
        ! local variables
        !!----------------------------------------------------------------------

        SELECT RANK (array)

           RANK (1)
              buffer(1:SIZE(array),1,1) = array

           RANK (2)
              IF ( time == 0 ) THEN
                 buffer(1:SIZE(array,1),1:SIZE(array,2),1) = array
              ELSE
                 buffer(1:SIZE(array),1,1) = array(:,kdimt)
              END IF

           RANK (3)
              IF ( time == 0 ) THEN
                 buffer(1:SIZE(array,1),1:SIZE(array,2),1:SIZE(array,3)) = array
              ELSE
                 buffer(1:SIZE(array,1),1:SIZE(array,2),1) = array(:,:,kdimt)
              END IF

           RANK (4)
              buffer(1:SIZE(array,1),1:SIZE(array,2),1:SIZE(array,3)) = array(:,:,:,kdimt)
    
        END SELECT

    END SUBROUTINE copy_array


    SUBROUTINE copy_buffer(array,time,kdimt,buffer)
        !!----------------------------------------------------------------------
        !!                     ***  SUBROUTINE array_size  ***
        !!
        !! ** Purpose :   copy buffer in array
        !!----------------------------------------------------------------------
        ! I/O
        REAL(wp), INTENT(OUT) :: array(..)
        INTEGER, INTENT(IN) :: time, kdimt
        REAL(wp), INTENT(IN) :: buffer(:,:,:)
        ! local variables
        !!----------------------------------------------------------------------
        
        SELECT RANK (array)

           RANK (1)
              array = buffer(1:SIZE(array),1,1)

           RANK (2)
              IF ( time == 0 ) THEN
                 array = buffer(1:SIZE(array,1),1:SIZE(array,2),1)
              ELSE
                 array(:,kdimt) = buffer(1:SIZE(array),1,1)
              END IF

           RANK (3)
              IF ( time == 0 ) THEN
                 array = buffer(1:SIZE(array,1),1:SIZE(array,2),1:SIZE(array,3))
              ELSE
                 array(:,:,kdimt) = buffer(1:SIZE(array,1),1:SIZE(array,2),1)
              END IF

           RANK (4)
              array(:,:,:,kdimt) = buffer(1:SIZE(array,1),1:SIZE(array,2),1:SIZE(array,3))
    
        END SELECT

    END SUBROUTINE copy_buffer


    SUBROUTINE c_string_to_fortran(string_c, string_f)
        !!----------------------------------------------------------------------
        !!                     ***  SUBROUTINE c_string_to_fortran  ***
        !!
        !! ** Purpose :   convert C string to Fortran character
        !!----------------------------------------------------------------------

        USE iso_c_binding, ONLY: c_ptr, c_int, c_f_pointer, C_NULL_CHAR

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
