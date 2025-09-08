SUBROUTINE c_nemo_init(klocal_comm,kit000) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_init  ***
      !!
      !! ** Purpose :   initialization of the NEMO GCM with imposed comm
      !!----------------------------------------------------------------------

      USE iso_c_binding, ONLY: c_int
      USE nemo_mod

      !!----------------------------------------------------------------------
      ! I/O
      INTEGER (c_int), INTENT(IN)  ::   klocal_comm   ! imposed communicator
      INTEGER (c_int), INTENT(OUT) ::   kit000        ! first iteration
      ! Local variables
      INTEGER ::              ios           ! local integers
      !
      NAMELIST/namctl/ sn_cfctl, ln_timing, ln_diacfl, nn_isplt, nn_jsplt , nn_ictls,   &
         &                                             nn_ictle, nn_jctls , nn_jctle
      NAMELIST/namcfg/ ln_read_cfg, cn_domcfg, ln_closea, ln_write_cfg, cn_domcfg_out
      !!----------------------------------------------------------------------
      !
      ! Flag start of init
      CALL timing_start( 'full code' )
      CALL timing_start( 'before step' )
      !
      cxios_context = 'nemo'
      !
      !                             !-------------------------------------------------!
      !                             !     set communicator & select the local rank    !
      !                             !  must be done as soon as possible to get narea  !
      !                             !-------------------------------------------------!
      !
      IF( Agrif_Root() ) THEN
            CALL xios_initialize( "for_xios_mpi_id", local_comm=klocal_comm )   ! nemo local communicator given by xios
      ENDIF
      CALL mpp_start( klocal_comm )
      !
      narea = mpprank + 1               ! mpprank: the rank of proc (0 --> mppsize -1 )
      lwm = (narea == 1)                ! control of output namelists
      !
      !                             !---------------------------------------------------------------!
      !                             ! Open output files, reference and configuration namelist files !
      !                             !---------------------------------------------------------------!
      !
      ! open ocean.output as soon as possible to get all output prints (including errors messages)
      IF( lwm )   CALL ctl_opn(     numout,        'ocean.output', 'REPLACE', 'FORMATTED', 'SEQUENTIAL', -1, -1, .FALSE. )
      ! open reference and configuration namelist files
                  CALL load_nml( numnam_ref,        'namelist_ref',                                           -1, lwm )
                  CALL load_nml( numnam_cfg,        'namelist_cfg',                                           -1, lwm )
      IF( lwm )   CALL ctl_opn(     numond, 'output.namelist.dyn', 'REPLACE', 'FORMATTED', 'SEQUENTIAL', -1, -1, .FALSE. )
      ! open /dev/null file to be able to supress output write easily
      IF( Agrif_Root() ) THEN
                  CALL ctl_opn(     numnul,           '/dev/null', 'UNKNOWN', 'FORMATTED', 'SEQUENTIAL', -1, -1, .FALSE. )
      ENDIF
      !                             !--------------------!
      !                             ! Open listing units !  -> need sn_cfctl from namctl to define lwp
      !                             !--------------------!
      !
      READ(numnam_ref(MAX(INDEX(numnam_ref,"&namctl "),1):),namctl,IOSTAT=ios);CALL ctl_nam(ios,"namctl (ref)",.TRUE.)
      READ(numnam_cfg(MAX(INDEX(numnam_cfg,"&namctl "),1):),namctl,IOSTAT=ios);CALL ctl_nam(ios,"namctl (cfg)",.FALSE.)
      !
      ! finalize the definition of namctl variables
      IF( narea < sn_cfctl%procmin .OR. narea > sn_cfctl%procmax .OR. MOD( narea - sn_cfctl%procmin, sn_cfctl%procincr ) /= 0 )   &
         &   CALL nemo_set_cfctl( sn_cfctl, .FALSE. )
      !
      lwp = (narea == 1) .OR. sn_cfctl%l_oceout    ! control of all listing output print
      !
      IF(lwp) THEN                      ! open listing units
         !
         IF( .NOT. lwm )   &            ! alreay opened for narea == 1
            &            CALL ctl_opn( numout, 'ocean.output', 'REPLACE', 'FORMATTED', 'SEQUENTIAL', -1, -1, .FALSE., narea )
         !
         WRITE(numout,*)
         WRITE(numout,*) '   CNRS - NERC - Met OFFICE - MERCATOR-ocean - CMCC'
         WRITE(numout,*) '                       NEMO team'
         WRITE(numout,*) '            Ocean General Circulation Model'
         WRITE(numout,*) '                NEMO version 5.0  (2024) '
         WRITE(numout,*)
         WRITE(numout,*) "           ._      ._      ._      ._      ._    "
         WRITE(numout,*) "       _.-._)`\_.-._)`\_.-._)`\_.-._)`\_.-._)`\_ "
         WRITE(numout,*)
         WRITE(numout,*) "           o         _,           _,             "
         WRITE(numout,*) "            o      .' (        .-' /             "
         WRITE(numout,*) "           o     _/..._'.    .'   /              "
         WRITE(numout,*) "      (    o .-'`      ` '-./  _.'               "
         WRITE(numout,*) "       )    ( o)           ;= <_         (       "
         WRITE(numout,*) "      (      '-.,\\__ __.-;`\   '.        )      "
         WRITE(numout,*) "       )  )       \) |`\ \)  '.   \      (   (   "
         WRITE(numout,*) "      (  (           \_/       '-._\      )   )  "
         WRITE(numout,*) "       )  ) jgs                     `    (   (   "
         WRITE(numout,*) "     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ "
         WRITE(numout,*)
         !
         WRITE(numout,cform_aaa)    ! Flag AAAAAAA
         !
         !                          ! Control print of the working precision
         WRITE(numout,*)
         IF( wp == dp ) THEN   ;   WRITE(numout,*) "par_kind : wp = Working precision = dp = double-precision"
         ELSE                  ;   WRITE(numout,*) "par_kind : wp = Working precision = sp = single-precision"
         ENDIF
                                   WRITE(numout,*) "~~~~~~~~                                 ****************"
                                   WRITE(numout,*)
         !
      ENDIF
      !
      IF(lwm) WRITE( numond, namctl )
      !
      !                             !------------------------------------!
      !                             !  Set global domain size parameters !
      !                             !------------------------------------!
      !
      READ(numnam_ref(MAX(INDEX(numnam_ref,"&namcfg "),1):),namcfg,IOSTAT=ios);CALL ctl_nam(ios,"namcfg (ref)",.TRUE.)
      READ(numnam_cfg(MAX(INDEX(numnam_cfg,"&namcfg "),1):),namcfg,IOSTAT=ios);CALL ctl_nam(ios,"namcfg (cfg)",.FALSE.)
      !
      IF( ln_read_cfg ) THEN            ! Read sizes in domain configuration file
         CALL domain_cfg ( cn_cfg, nn_cfg, Ni0glo, Nj0glo, jpkglo, l_Iperio, l_Jperio, l_NFold, c_NFtype )
      ELSE                              ! user-defined namelist
         CALL usr_def_nam( cn_cfg, nn_cfg, Ni0glo, Nj0glo, jpkglo, l_Iperio, l_Jperio, l_NFold, c_NFtype )
      ENDIF
      !
      IF(lwm)   WRITE( numond, namcfg )
      !
      !                             !-----------------------------------------!
      !                             ! mpp parameters and domain decomposition !
      !                             !-----------------------------------------!
      CALL mpp_init
      !
      ! Now we know the dimensions of the grid and numout has been set: we can allocate arrays
      CALL nemo_alloc()

      ! Initialise time level indices
      Nbb = 1   ;   Nnn = 2   ;   Naa = 3   ;   Nrhs = Naa
      !                             !-------------------------------!
      !                             !  NEMO general initialization  !
      !                             !-------------------------------!

      CALL nemo_ctl                          ! Control prints of namctl and namcfg
      !
      !                                      ! General initialization
                           CALL timing_open( lwp, mpi_comm_oce )   ! open timing report file
      IF( ln_timing    )   CALL timing_start( 'nemo_init' )
      !
                           CALL     phy_cst         ! Physical constants
                           CALL     eos_init        ! Equation of state
                           CALL     wad_init        ! Wetting and drying options

                           CALL     dom_init( Nbb, Nnn, Naa )   ! Domain
      IF( sn_cfctl%l_prtctl )   &
         &                 CALL prt_ctl_init        ! Print control

                           CALL diurnal_sst_bulk_init       ! diurnal sst
      IF( ln_diurnal   )   CALL diurnal_sst_coolskin_init   ! cool skin
      !
      IF( ln_diurnal_only ) THEN                    ! diurnal only: a subset of the initialisation routines
         CALL  istate_init( Nbb, Nnn, Naa )         ! ocean initial state (Dynamics and tracers)
         CALL     sbc_init( Nbb, Nnn, Naa )         ! Forcings : surface module
         CALL tra_qsr_init                          ! penetrative solar radiation qsr
         IF( ln_diaobs ) THEN                       ! Observation & model comparison
            CALL dia_obs_init( Nnn )                ! Initialize observational data
            CALL dia_obs( nit000 - 1, Nnn )         ! Observation operator for restart
         ENDIF
         IF( lk_asminc )   CALL asm_inc_init( Nbb, Nnn, Nrhs )   ! Assimilation increments
         !
         RETURN                                       ! end of initialization
      ENDIF
      !

                           CALL  istate_init( Nbb, Nnn, Naa )    ! ocean initial state (Dynamics and tracers)

      !                                      ! external forcing
                           CALL    tide_init                     ! tidal harmonics
                           CALL     sbc_init( Nbb, Nnn, Naa )    ! surface boundary conditions (including sea-ice)
                           CALL     bdy_init                     ! Open boundaries initialisation

      !                                      ! Ocean physics
                           CALL zdf_phy_init( Nnn )    ! Vertical physics

      !                                      ! Lateral physics
                           CALL ldf_tra_init             ! Lateral ocean tracer physics
                           CALL ldf_eiv_init             ! eddy induced velocity param.
      IF( l_ldfeke     )   CALL ldf_eke_init( Nbb )      ! GEOMETRIC param. RK3
                           CALL ldf_dyn_init             ! Lateral ocean momentum physics

      !                                      ! Active tracers
      IF( ln_traqsr    )   CALL tra_qsr_init      ! penetrative solar radiation qsr
                           CALL tra_bbc_init      ! bottom heat flux
                           CALL tra_bbl_init      ! advective (and/or diffusive) bottom boundary layer scheme
                           CALL tra_dmp_init      ! internal tracer damping
                           CALL tra_adv_init      ! horizontal & vertical advection
                           CALL tra_ldf_init      ! lateral mixing

      !                                      ! Dynamics
      IF( ln_c1d       )   CALL dyn_dmp_init         ! internal momentum damping
                           CALL dyn_adv_init         ! advection (vector or flux form)
                           CALL dyn_vor_init         ! vorticity term including Coriolis
                           CALL dyn_ldf_init         ! lateral mixing
                           CALL dyn_hpg_init( Nnn )  ! horizontal gradient of Hydrostatic pressure
                           CALL dyn_spg_init         ! surface pressure gradient

      !                                      ! Icebergs
                           CALL icb_init( rn_Dt, nit000, Nnn )   ! initialise icebergs instance

                                                ! ice shelf
                           CALL isf_init( Nbb, Nnn, Naa )
      IF( l_ldfslp     )   CALL ldf_slp_init    ! slope of lateral mixing

      !                                      ! Misc. options
                           CALL sto_par_init    ! Stochastic parametrization
      IF( ln_sto_eos   )   CALL sto_pts_init    ! RRandom T/S fluctuations

      !                                      ! Diagnostics
      IF( ln_diacfl    )   CALL dia_cfl_init    ! Initialise CFL diagnostics
                           CALL dia_dct_init    ! Sections tranports
                           CALL     trd_init( Nnn )    ! Mixed-layer/Vorticity/Integral constraints trends
                           CALL dia_obs_init( Nnn )    ! Initialize observational data
      ! move to stprk3 !   CALL dia_25h_init( Nbb )    ! 25h mean  outputs
                           CALL dia_detide_init ! Weights computation for daily detiding of model diagnostics
      IF( ln_diaobs    )   CALL dia_obs( nit000-1, Nnn )   ! Observation operator for restart
                           CALL dia_mlr_init    ! Initialisation of IOM context management for multiple-linear-regression analysis

      !                                      ! Assimilation increments
      IF( lk_asminc    )   CALL asm_inc_init( Nbb, Nnn, Nrhs )   ! Initialize assimilation increments
      !
      IF(lwp) WRITE(numout,cform_aaa)           ! Flag AAAAAAA
      !
      IF( ln_timing    )   CALL timing_stop( 'nemo_init' )
      ! 
      ! -------------------
      ! Check all processes
      CALL mpp_max( 'nemogcm', nstop )
      !
      ! Flag end of init
      IF(lwp) WRITE(numout,cform_aaa)
      CALL timing_stop( 'before step' )
      !
      ! Wrapper: return starting iteration
      kit000 = nit000
      !
END SUBROUTINE c_nemo_init


SUBROUTINE c_nemo_advance(kite,kite_start,pstp_c,ldiag_c) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_init  ***
      !!
      !! ** Purpose :   initialization of the NEMO GCM with imposed comm
      !!----------------------------------------------------------------------

      USE iso_c_binding, ONLY: c_int, c_float
      USE nemo_mod

      !!----------------------------------------------------------------------
      ! I/O
      INTEGER (c_int), INTENT(IN) ::   kite, kite_start ! number of time iteration
      INTEGER (c_int), INTENT(IN) ::   ldiag_c          ! logical for diagnostic - C
      INTEGER (c_float), INTENT(IN) :: pstp_c           ! time step - C
      ! Local variables
      LOGICAL  :: ldiag_f       ! logical for diagnostic - Fortran
      INTEGER  :: istp, iend
      REAL(wp) :: pstp_f        ! time step - Fortran
      !!----------------------------------------------------------------------
      !
      ! convert
      pstp_f = REAL(pstpt_c, kind=wp)
      ldiag_f = (ldiag_c.NE.0)
      !
      ! Time loop
      istp = kite_start
      iend = kite_start + kite - 1
      !
      IF( .NOT.ln_diurnal_only ) THEN                 !==  Standard time-stepping  ==!
         !
         DO WHILE( istp <= iend .AND. nstop == 0 )
            !
            ncom_stp = istp
            CALL timing_start( 'step', istp, nit000, iend, nn_fsbc, 1000 )
            !
            CALL stp_RK3( istp )
            CALL timing_stop( 'step', istp )
            istp = istp + 1
            !
         END DO
         !
      ELSE                                            !==  diurnal SST time-steeping only  ==!
         !
         DO WHILE( istp <= iend .AND. nstop == 0 )
            ncom_stp = istp
            CALL timing_start( 'stp_diurnal', istp, nit000, iend, nn_fsbc, 1000 )
            CALL stp_diurnal( istp )   ! time step only the diurnal SST
            CALL timing_stop( 'stp_diurnal', istp )
            istp = istp + 1
         END DO
         !
      ENDIF
      !
      IF( ln_diaobs .AND. ldiag_f )   CALL dia_obs_wri
      !
END SUBROUTINE c_nemo_advance


SUBROUTINE c_nemo_finalization(kitend) BIND(C)
      !!----------------------------------------------------------------------
      !!                     ***  ROUTINE c_nemo_finalization  ***
      !!
      !! ** Purpose :   gathers all NEMO finalization steps
      !!----------------------------------------------------------------------

      USE iso_c_binding, ONLY: c_int
      USE nemo_mod

      !!----------------------------------------------------------------------
      ! I/O
      INTEGER (c_int), INTENT(IN) :: kitend   
      ! Local variables
      !!----------------------------------------------------------------------
      !
      ! Flag start of finalization
      IF(lwp) WRITE(numout,cform_aaa)
      !
      IF( ln_icebergs )   CALL icb_end( kitend )
      !
      IF( nstop /= 0 .AND. lwp ) THEN        ! error print
         WRITE(ctmp1,*) '   ==>>>   nemo_gcm: a total of ', nstop, ' errors have been found'
         IF( ngrdstop > 0 ) THEN
            WRITE(ctmp9,'(i2)') ngrdstop
            WRITE(ctmp2,*) '           E R R O R detected in Agrif grid '//TRIM(ctmp9)
            WRITE(ctmp3,*) '           Look for "E R R O R" messages in all existing '//TRIM(ctmp9)//'_ocean_output* files'
            CALL ctl_stop( ' ', ctmp1, ' ', ctmp2, ' ', ctmp3 )
         ELSE
            WRITE(ctmp2,*) '           Look for "E R R O R" messages in all existing ocean_output* files'
            CALL ctl_stop( ' ', ctmp1, ' ', ctmp2 )
         ENDIF
      ENDIF
      !
      ! Free memory
      CALL nemo_dealloc()
      !
      CALL timing_stop( 'full code', ld_finalize = .TRUE. )
      !
      CALL nemo_closefile
      !
      ! End xios
      CALL xios_finalize
      !
      IF(lwm) THEN
         IF( nstop == 0 ) THEN   ;   STOP 0
         ELSE                    ;   STOP 123
         ENDIF
      ENDIF
      !
END SUBROUTINE c_nemo_finalization
