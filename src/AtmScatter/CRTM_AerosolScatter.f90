!--------------------------------------------------------------------------------
!M+
! NAME:
!       CRTM_AerosolScatter
!
! PURPOSE:
!       Module to compute the aerosol absorption and scattering properties
!       required for radiative transfer in an atmosphere with aerosols.
!       
! CATEGORY:
!       CRTM : AtmScatter
!
! LANGUAGE:
!       Fortran-95
!
! CALLING SEQUENCE:
!       USE CRTM_AerosolScatter
!
! MODULES:
!       Type_Kinds:                Module containing definitions for kinds
!                                  of variable types.
!
!       Message_Handler:           Module to define simple error codes and
!                                  handle error conditions
!                                  USEs: FILE_UTILITY module
!
!       CRTM_Parameters:           Module of parameter definitions for the CRTM.
!                                  USEs: TYPE_KINDS module
!
!       CRTM_SpcCoeff:             Module containing the shared CRTM spectral
!                                  coefficients (SpcCoeff) and their
!                                  load/destruction routines. 
!                                  USEs TYPE_KINDS module
!                                       ERROR_HANDLER module
!                                       SPCCOEFF_DEFINE module
!                                       SPCCOEFF_BINARY_IO module
!                                       CRTM_PARAMETERS module
!
!       CRTM_AerosolCoeff:         Module containing the shared CRTM aerosol
!                                  coefficients (AerosolCoeff) and their
!                                  load/destruction routines. 
!                                  USEs TYPE_KINDS module
!                                       ERROR_HANDLER module
!                                       AEROSOLCOEFF_DEFINE module
!                                       AEROSOLCOEFF_BINARY_IO module
!                                       CRTM_PARAMETERS module
!
!       CRTM_Atmosphere_Define:    Module defining the CRTM Atmosphere
!                                  structure and containing routines to 
!                                  manipulate it.
!                                  USEs: TYPE_KINDS module
!                                        ERROR_HANDLER module
!                                        CRTM_CLOUD_DEFINE module
!
!       CRTM_GeometryInfo_Define:  Module defining the CRTM GeometryInfo
!                                  structure and containing routines to 
!                                  manipulate it.
!                                  USEs: TYPE_KINDS module
!                                        ERROR_HANDLER module
!
!       CRTM_AtmScatter_Define:    Module defining the CRTM AtmScatter
!                                  structure and containing routines to 
!                                  manipulate it.
!                                  USEs: TYPE_KINDS module
!                                        ERROR_HANDLER module
!
! CONTAINS:
!       PUBLIC subprograms
!       ------------------
!         CRTM_Compute_AerosolScatter:     Function to compute aerosol absorption
!                                          and scattering properties.
!
!         CRTM_Compute_AerosolScatter_TL:  Function to compute the tangent-linear
!                                          aerosol absorption and scattering
!                                          properties.
!
!         CRTM_Compute_AerosolScatter_AD:  Function to compute the adjoint
!                                          of the aerosol absorption and scattering
!                                          properties.
!
!       PRIVATE subprograms
!       -------------------
!       
!         *** USERS ADD INFO HERE FOR ANY PRIVATE SUBPROGRAMS ***
!
!
!
! USE ASSOCIATED PUBLIC SUBPROGRAMS:
!       CRTM_Associated_AtmScatter:  Function to test the association status of
!                                    the pointer members of a AtmScatter
!                                    structure.
!                                    SOURCE: CRTM_ATMSCATTER_DEFINE module
!
!       CRTM_Destroy_AtmScatter:     Function to re-initialize an
!                                    CRTM_AtmScatter structure.
!                                    SOURCE: CRTM_ATMSCATTER_DEFINE module
!
!       CRTM_Allocate_AtmScatter:    Function to allocate the pointer
!                                    members of an CRTM_AtmScatter
!                                    structure.
!                                    SOURCE: CRTM_ATMSCATTER_DEFINE module
!
!       CRTM_Assign_AtmScatter:      Function to copy an CRTM_AtmScatter
!                                    structure.
!                                    SOURCE: CRTM_ATMSCATTER_DEFINE module
!
! INCLUDE FILES:
!       None.
!
! EXTERNALS:
!       None.
!
! COMMON BLOCKS:
!       None.
!
! FILES ACCESSED:
!       None.
!
! CREATION HISTORY:
!       Written by:     Paul van Delst, CIMSS/SSEC 15-Feb-2005
!                       paul.vandelst@ssec.wisc.edu
!       Modified by     Quanhua Liu, 03-Oct-2006
!                       Quanhua.Liu@noaa.gov
!
!  Copyright (C) 2005 Paul van Delst
!
!  This program is free software; you can redistribute it and/or
!  modify it under the terms of the GNU General Public License
!  as published by the Free Software Foundation; either version 2
!  of the License, or (at your option) any later version.
!
!  This program is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!  GNU General Public License for more details.
!
!  You should have received a copy of the GNU General Public License
!  along with this program; if not, write to the Free Software
!  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
!M-
!--------------------------------------------------------------------------------

MODULE CRTM_AerosolScatter


  ! ----------
  ! Module use
  ! ----------

  USE Type_Kinds
  USE Message_Handler

  ! -- CRTM modules
  USE CRTM_Parameters
  USE CRTM_SpcCoeff
  USE CRTM_Atmosphere_Define,   ONLY: CRTM_Atmosphere_type
  USE CRTM_GeometryInfo_Define, ONLY: CRTM_GeometryInfo_type

  ! -- The AtmScatter structure definition module
  ! -- The PUBLIC entities in CRTM_AtmScatter_Define
  ! -- are also explicitly defined as PUBLIC here
  ! -- (down below) so a user need only USE this
  ! -- module (CRTM_AerosolScatter).
  USE CRTM_AtmScatter_Define

  USE CRTM_Aerosol_Define
  USE CRTM_AerosolCoeff,   ONLY: AeroC 

  ! -----------------------
  ! Disable implicit typing
  ! -----------------------

  IMPLICIT NONE


  ! ------------
  ! Visibilities
  ! ------------

  ! -- Everything private by default
  PRIVATE

  ! -- CRTM_AtmScatter structure data type
  ! -- in the CRTM_AtmScatter_Define module
  PUBLIC :: CRTM_AtmScatter_type

  ! -- CRTM_AtmScatter structure routines inherited
  ! -- from the CRTM_AtmScatter_Define module
  PUBLIC :: CRTM_Associated_AtmScatter
  PUBLIC :: CRTM_Destroy_AtmScatter
  PUBLIC :: CRTM_Allocate_AtmScatter
  PUBLIC :: CRTM_Assign_AtmScatter

  ! -- Science routines in this modules
  PUBLIC :: CRTM_Compute_AerosolScatter
  PUBLIC :: CRTM_Compute_AerosolScatter_TL
  PUBLIC :: CRTM_Compute_AerosolScatter_AD


  ! -------------------------
  ! PRIVATE Module parameters
  ! -------------------------

  ! -- RCS Id for the module
  CHARACTER( * ), PRIVATE, PARAMETER :: MODULE_RCS_ID = &
  '$Id$'


CONTAINS





!##################################################################################
!##################################################################################
!##                                                                              ##
!##                          ## PRIVATE MODULE ROUTINES ##                       ##
!##                                                                              ##
!##################################################################################
!##################################################################################



!  *** USERS INSERT PRIVATE SUBPROGRAMS HERE ***




!################################################################################
!################################################################################
!##                                                                            ##
!##                         ## PUBLIC MODULE ROUTINES ##                       ##
!##                                                                            ##
!################################################################################
!################################################################################


!------------------------------------------------------------------------------
!S+
! NAME:
!       CRTM_Compute_AerosolScatter
!
! PURPOSE:
!       Function to compute the aerosol absorption and scattering properties
!       and populate the output AerosolScatter structure for a single channel.
!
! CATEGORY:
!       CRTM : AtmScatter
!
! LANGUAGE:
!       Fortran-95
!
! CALLING SEQUENCE:
!       Error_Status = CRTM_Compute_AerosolScatter( Atmosphere,               &  ! Input
!                                                   GeometryInfo,             &  ! Input
!                                                   Channel_Index,            &  ! Input, scalar
!                                                   AerosolScatter,           &  ! Output        
!                                                   Message_Log = Message_Log )  ! Error messaging 
!
! INPUT ARGUMENTS:
!       Atmosphere:      CRTM_Atmosphere structure containing the atmospheric
!                        profile data.
!                        UNITS:      N/A
!                        TYPE:       TYPE( CRTM_Atmosphere_type )
!                        DIMENSION:  Scalar
!                        ATTRIBUTES: INTENT( IN )
!
!       GeometryInfo:    CRTM_GeometryInfo structure containing the 
!                        view geometry information.
!                        UNITS:      N/A
!                        TYPE:       TYPE( CRTM_GeometryInfo_type )
!                        DIMENSION:  Scalar
!                        ATTRIBUTES: INTENT( IN )
!
!       Channel_Index:   Channel index id. This is a unique index associated
!                        with a (supported) sensor channel used to access the
!                        shared coefficient data.
!                        UNITS:      N/A
!                        TYPE:       INTEGER
!                        DIMENSION:  Scalar
!                        ATTRIBUTES: INTENT( IN )
!
!
! OPTIONAL INPUT ARGUMENTS:
!       Message_Log:     Character string specifying a filename in which any
!                        messages will be logged. If not specified, or if an
!                        error occurs opening the log file, the default action
!                        is to output messages to standard output.
!                        UNITS:      N/A
!                        TYPE:       CHARACTER(*)
!                        DIMENSION:  Scalar
!                        ATTRIBUTES: INTENT( IN ), OPTIONAL
!
! OUTPUT ARGUMENTS:
!        AerosolScatter: CRTM_AtmScatter structure containing the aerosol
!                        absorption and scattering properties required by
!                        the radiative transfer.
!                        UNITS:      N/A
!                        TYPE:       TYPE( CRTM_AtmScatter_type )
!                        DIMENSION:  Scalar
!                        ATTRIBUTES: INTENT( IN OUT )
!
!
! OPTIONAL OUTUPT ARGUMENTS:
!       None.
!
! FUNCTION RESULT:
!       Error_Status:    The return value is an integer defining the error status.
!                        The error codes are defined in the ERROR_HANDLER module.
!                        If == SUCCESS the computation was sucessful
!                           == FAILURE an unrecoverable error occurred
!                        UNITS:      N/A
!                        TYPE:       INTEGER
!                        DIMENSION:  Scalar
!
! CALLS:
!
! SIDE EFFECTS:
!
! RESTRICTIONS:
!
! COMMENTS:
!       Note the INTENT on the output AerosolScatter argument is IN OUT rather than
!       just OUT. This is necessary because the argument may be defined upon
!       input. To prevent memory leaks, the IN OUT INTENT is a must.
!
!S-
!------------------------------------------------------------------------------

  FUNCTION CRTM_Compute_AerosolScatter( Atmosphere,     &  ! Input
                                        GeometryInfo,   &  ! Input
                                        Channel_Index,  &  ! Input
                                        AerosolScatter, &  ! Output
                                        Message_Log )   &  ! Error messaging
                                      RESULT ( Error_Status )


    !#--------------------------------------------------------------------------#
    !#                         -- TYPE DECLARATIONS --                          #
    !#--------------------------------------------------------------------------#

    ! ---------
    ! Arguments
    ! ---------

    ! -- Input
    TYPE( CRTM_Atmosphere_type ),   INTENT( IN )     :: Atmosphere
    TYPE( CRTM_GeometryInfo_type ), INTENT( IN )     :: GeometryInfo
    INTEGER,                        INTENT( IN )     :: Channel_Index

    ! -- Output 
    TYPE( CRTM_AtmScatter_type ),   INTENT( IN OUT ) :: AerosolScatter

    ! -- Error messaging
    CHARACTER( * ), OPTIONAL,       INTENT( IN )     :: Message_Log


    ! ---------------
    ! Function result
    ! ---------------

    INTEGER :: Error_Status


    ! ----------------
    ! Local parameters
    ! ----------------

    CHARACTER( * ), PARAMETER :: ROUTINE_NAME = 'CRTM_Compute_AerosolScatter'
    INTEGER :: i, j, k, n, L, kuse
    INTEGER :: Sensor_Type
    REAL( fp_kind ) :: Wavenumber
    INTEGER, DIMENSION( Atmosphere%Max_Layers ) :: kidx
    REAL( fp_kind ) :: Water_Content,eff_radius,eff_v,Temperature
    INTEGER :: Aerosol_Type
    REAL( fp_kind ) :: Scattering_Coefficient, ext, w0, g, Aerosol_Content
    REAL( fp_kind ) :: Aerosol_Reff, Wavelength
    REAL( fp_kind ) :: p_coef(0:32,6) 
    INTEGER :: n_Legendre_Terms, n_Phase_Elements
    !#--------------------------------------------------------------------------#
    !#                -- INITIALISE SUCCESSFUL RETURN STATUS --                 #
    !#--------------------------------------------------------------------------#

    Error_Status = SUCCESS

    IF(Atmosphere%n_Aerosols == 0) RETURN

      n_Legendre_Terms = AeroC%n_Legendre_Terms
      n_Phase_Elements = AeroC%n_Phase_Elements 

    Sensor_Type = SC%Sensor_Type(Channel_Index)
    ! wavelength in micron
    Wavelength = 10000.0_fp_kind/SC%Wavenumber(Channel_Index)

    !#--------------------------------------------------------------------------#
    !#                -- LOOP OVER CLOUD TYPE --                                #
    !#--------------------------------------------------------------------------#
                                                                                                                        
  DO n = 1, Atmosphere%n_Aerosols
     kuse = count(Atmosphere%aerosol(n)%Concentration(:) > AEROSOL_CONTENT_THRESHOLD)
     IF(kuse > 0 ) THEN
       kidx(1:kuse) = PACK((/(k,k=1,Atmosphere%aerosol(n)%n_layers)/), &
                           Atmosphere%aerosol(n)%Concentration(:) > AEROSOL_CONTENT_THRESHOLD)
       Aerosol_Type = Atmosphere%aerosol(n)%Type

      !  LOOP OVER LAYERS
      DO i = 1, kuse
         j = kidx(i)
         Aerosol_Content = Atmosphere%aerosol(n)%Concentration(j)
         Aerosol_Reff = Atmosphere%aerosol(n)%Effective_Radius(j)
        !   INFRARED RANGE
        IF( Sensor_Type == INFRARED_SENSOR .OR. Sensor_Type == VISIBLE_SENSOR) THEN
          call Get_Aerosol_Opt(n_Legendre_Terms,n_Phase_Elements,Aerosol_Type,Aerosol_Reff,Wavelength, & !INPUT
                ext,w0,g,p_coef) !OUTPUT

         Scattering_Coefficient = ext * Aerosol_Content * w0 
         AerosolScatter%Optical_Depth(j) = AerosolScatter%Optical_Depth(j)  &
                                         + ext * Aerosol_Content
         AerosolScatter%Single_Scatter_Albedo(j) =  &
           AerosolScatter%Single_Scatter_Albedo(j) + Scattering_Coefficient
         AerosolScatter%Asymmetry_Factor(j) = AerosolScatter%Asymmetry_Factor(j) &
                                            + g * Scattering_Coefficient

       IF(n_Phase_Elements > 0 .AND. n_Legendre_Terms > 2) THEN
          DO k = 1, n_Phase_Elements
           DO L = 0, n_Legendre_Terms
           AerosolScatter%Phase_Coefficient(L, k, j) =   &
             AerosolScatter%Phase_Coefficient(L, k, j)   &
             + p_coef(L,k)*Scattering_Coefficient
           ENDDO
          ENDDO
        ENDIF

        ENDIF
      ENDDO     ! END of LOOP over layers (i)
     ENDIF      ! kuse
  ENDDO       ! END of LOOP over aerosol type (n)
                                                                                                                        
!

  END FUNCTION CRTM_Compute_AerosolScatter


!
  SUBROUTINE Get_Aerosol_Opt(n_Legendre_Terms,n_Phase_Elements,Aerosol_Type, Aerosol_Reff, Wavelength, & !INPUT
                                   ext, w0, g, p_coef) !OUTPUT
! ---------------------------------------------------------------------------------------
!    Function:
!      obtaining extinction (ext), scattereing (w0) coefficients
!      asymmetry factor (g)
! ---------------------------------------------------------------------------------------
    REAL( fp_kind ) , INTENT( IN ) ::  Aerosol_Reff, Wavelength 
    INTEGER, INTENT( IN ) :: Aerosol_Type,n_Legendre_Terms,n_Phase_Elements
    INTEGER :: Offset_LegTerm
    REAL( fp_kind ) , INTENT( OUT ) :: ext, w0, g
    REAL( fp_kind ) :: d1, d2, a1,a2 
    REAL( fp_kind ) , INTENT( INOUT ), DIMENSION(0:,:) :: p_coef
    INTEGER :: i, j, k, L, i1, i2, j1, j2,L1,L2,L3A
! temporal set Offset_LegTerm = 0
    Offset_LegTerm = 0

  ! find index for wavelength (micron)
    DO i = 1, AeroC%n_Wavelength - 1
        IF( Wavelength <= AeroC%Wavelength(i) ) GO TO 101
    END DO
    i = AeroC%n_Wavelength
 101 CONTINUE
    ! find index for wavelength
    IF( i == 1 ) THEN
       d2 = ZERO
       i1 = 1
       i2 = 1
    ELSE
      i1 = i-1
      i2 = i
      d2 = (Wavelength - AeroC%Wavelength(i1))/(AeroC%Wavelength(i2)-AeroC%Wavelength(i1)) 
    END IF
    ! find index for effective radius
    DO j = 1, AeroC%n_Reff
        IF( Aerosol_Reff <= AeroC%Aerosol_Reff(j,Aerosol_Type) ) GO TO 102 
    END DO

     j = AeroC%n_Reff
 102 IF( j == 1 ) THEN
       j1 = 1
       j2 = 1
       d1 = ZERO
      ELSE
        j1 = j-1
        j2 = j
        d1 = (Aerosol_Reff - AeroC%Aerosol_Reff(j1,Aerosol_Type))/  &
        (AeroC%Aerosol_Reff(j2,Aerosol_Type)-AeroC%Aerosol_Reff(j1,Aerosol_Type))
      END IF

     ! interpolation for both wavelength and relative humidity
     ext = (ONE-d1)*(ONE-d2)*AeroC%Mass_Extinction(j1,Aerosol_Type,i1)  &
         + (ONE-d1)*d2*AeroC%Mass_Extinction(j1,Aerosol_Type,i2)          &
         + (ONE-d2)*d1*AeroC%Mass_Extinction(j2,Aerosol_Type,i1)      &
         + d1*d2*AeroC%Mass_Extinction(j2,Aerosol_Type,i2)
 
     w0  = (ONE-d1)*(ONE-d2)*AeroC%Scattering_Albedo(j1,Aerosol_Type,i1)  &
         + (ONE-d1)*d2*AeroC%Scattering_Albedo(j1,Aerosol_Type,i2)          &
         + (ONE-d2)*d1*AeroC%Scattering_Albedo(j2,Aerosol_Type,i1)      &
         + d1*d2*AeroC%Scattering_Albedo(j2,Aerosol_Type,i2)

     g   = (ONE-d1)*(ONE-d2)*AeroC%Asymmetry_Factor(j1,Aerosol_Type,i1)  &
         + (ONE-d1)*d2*AeroC%Asymmetry_Factor(j1,Aerosol_Type,i2)          &
         + (ONE-d2)*d1*AeroC%Asymmetry_Factor(j2,Aerosol_Type,i1)      &
         + d1*d2*AeroC%Asymmetry_Factor(j2,Aerosol_Type,i2)

       IF(n_Phase_Elements > 0 .AND. n_Legendre_Terms > 2) THEN
          DO L = 0, n_Legendre_Terms
           p_coef(L,1) = (ONE-d1)*(ONE-d2)*AeroC%Phase_Coef(L+Offset_LegTerm,j1,Aerosol_Type,i1)  &
               + (ONE-d1)*d2*AeroC%Phase_Coef(L+Offset_LegTerm,j1,Aerosol_Type,i2)  &
               + (ONE-d2)*d1*AeroC%Phase_Coef(L+Offset_LegTerm,j2,Aerosol_Type,i1)  &
               +  d1*d2*AeroC%Phase_Coef(L+Offset_LegTerm,j2,Aerosol_Type,i2)
          ENDDO
       ENDIF

    RETURN
  END SUBROUTINE Get_Aerosol_Opt
!
!------------------------------------------------------------------------------
!S+
! NAME:
!       CRTM_Compute_AerosolScatter_TL
!
! PURPOSE:
!       Function to compute the tangent-linear aerosol absorption and 
!       scattering properties and populate the output AerosolScatter_TL
!       structure for a single channel.
!
! CATEGORY:
!       CRTM : AtmScatter
!
! LANGUAGE:
!       Fortran-95
!
! CALLING SEQUENCE:
!       Error_Status = CRTM_Compute_AerosolScatter_TL( Atmosphere,               &  ! Input
!                                                      AerosolScatter,           &  ! Input
!                                                      Atmosphere_TL,            &  ! Input
!                                                      GeometryInfo,             &  ! Input
!                                                      Channel_Index,            &  ! Input, scalar
!                                                      AerosolScatter_TL,        &  ! Output  
!                                                      Message_Log = Message_Log )  ! Error messaging
!
! INPUT ARGUMENTS:
!       Atmosphere:         CRTM_Atmosphere structure containing the atmospheric
!                           profile data.
!                           UNITS:      N/A
!                           TYPE:       TYPE( CRTM_Atmosphere_type )
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN )
!
!       AerosolScatter:     CRTM_AtmScatter structure containing the forward model
!                           aerosol absorption and scattering properties required
!                           for radiative transfer.
!                           UNITS:      N/A
!                           TYPE:       TYPE( CRTM_AtmScatter_type )
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN )
!
!       Atmosphere_TL:      CRTM Atmosphere structure containing the tangent-linear
!                           atmospheric state data.
!                           UNITS:      N/A
!                           TYPE:       TYPE( CRTM_Atmosphere_type )
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN )
!
!       GeometryInfo:       CRTM_GeometryInfo structure containing the 
!                           view geometry information.
!                           UNITS:      N/A
!                           TYPE:       TYPE( CRTM_GeometryInfo_type )
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN )
!
!       Channel_Index:      Channel index id. This is a unique index associated
!                           with a (supported) sensor channel used to access the
!                           shared coefficient data.
!                           UNITS:      N/A
!                           TYPE:       INTEGER
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN )
!
!
! OPTIONAL INPUT ARGUMENTS:
!       Message_Log:        Character string specifying a filename in which any
!                           messages will be logged. If not specified, or if an
!                           error occurs opening the log file, the default action
!                           is to output messages to standard output.
!                           UNITS:      N/A
!                           TYPE:       CHARACTER(*)
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN ), OPTIONAL
!
! OUTPUT ARGUMENTS:
!        AerosolScatter_TL: CRTM_AtmScatter structure containing the tangent-linear
!                           aerosol absorption and scattering properties required
!                           for radiative transfer.
!                           UNITS:      N/A
!                           TYPE:       TYPE( CRTM_AtmScatter_type )
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN OUT )
!
!
! OPTIONAL OUTUPT ARGUMENTS:
!       None.
!
! FUNCTION RESULT:
!       Error_Status:    The return value is an integer defining the error status.
!                        The error codes are defined in the ERROR_HANDLER module.
!                        If == SUCCESS the computation was sucessful
!                           == FAILURE an unrecoverable error occurred
!                        UNITS:      N/A
!                        TYPE:       INTEGER
!                        DIMENSION:  Scalar
!
! CALLS:
!
! SIDE EFFECTS:
!
! RESTRICTIONS:
!
! COMMENTS:
!       Note the INTENT on the output AerosolScatter_TL argument is IN OUT
!       rather than just OUT. This is necessary because the argument may be
!       defined upon input. To prevent memory leaks, the IN OUT INTENT is
!       a must.
!
!S-
!------------------------------------------------------------------------------

  FUNCTION CRTM_Compute_AerosolScatter_TL( Atmosphere,        &  ! Input
                                           AerosolScatter,    &  ! Input
                                           Atmosphere_TL,     &  ! Input
                                           GeometryInfo,      &  ! Input
                                           Channel_Index,     &  ! Input
                                           AerosolScatter_TL, &  ! Output
                                           Message_Log )      &  ! Error messaging
                                         RESULT ( Error_Status )


    !#--------------------------------------------------------------------------#
    !#                         -- TYPE DECLARATIONS --                          #
    !#--------------------------------------------------------------------------#

    ! ---------
    ! Arguments
    ! ---------

    ! -- Input
    TYPE( CRTM_Atmosphere_type ),   INTENT( IN )     :: Atmosphere
    TYPE( CRTM_AtmScatter_type ),   INTENT( IN )     :: AerosolScatter
    TYPE( CRTM_Atmosphere_type ),   INTENT( IN )     :: Atmosphere_TL
    TYPE( CRTM_GeometryInfo_type ), INTENT( IN )     :: GeometryInfo
    INTEGER,                        INTENT( IN )     :: Channel_Index

    ! -- Output 
    TYPE( CRTM_AtmScatter_type ),   INTENT( IN OUT ) :: AerosolScatter_TL

    ! -- Error messaging
    CHARACTER( * ), OPTIONAL,       INTENT( IN )     :: Message_Log


    ! ---------------
    ! Function result
    ! ---------------

    INTEGER :: Error_Status


    ! ----------------
    ! Local parameters
    ! ----------------

    CHARACTER( * ), PARAMETER :: ROUTINE_NAME = 'CRTM_Compute_AerosolScatter_TL'


    ! ---------------
    ! Local variables
    ! ---------------




    !#--------------------------------------------------------------------------#
    !#                -- INITIALISE SUCCESSFUL RETURN STATUS --                 #
    !#--------------------------------------------------------------------------#

    Error_Status = SUCCESS



!  *** USERS INSERT CODE HERE ***




  END FUNCTION CRTM_Compute_AerosolScatter_TL





!------------------------------------------------------------------------------
!S+
! NAME:
!       CRTM_Compute_AerosolScatter_AD
!
! PURPOSE:
!       Function to compute the adjoint aerosol absorption and scattering
!       properties for a single channel.
!
! CATEGORY:
!       CRTM : AtmScatter
!
! LANGUAGE:
!       Fortran-95
!
! CALLING SEQUENCE:
!       Error_Status = CRTM_Compute_AerosolScatter_AD(  Atmosphere,               &  ! Input
!                                                       AerosolScatter,           &  ! Input
!                                                       AerosolScatter_AD,        &  ! Input
!                                                       GeometryInfo,             &  ! Input
!                                                       Channel_Index,            &  ! Input
!                                                       Atmosphere_AD,            &  ! Output  
!                                                       Message_Log = Message_Log )  ! Error messaging 
!
! INPUT ARGUMENTS:
!       Atmosphere:         CRTM_Atmosphere structure containing the atmospheric
!                           profile data.
!                           UNITS:      N/A
!                           TYPE:       TYPE( CRTM_Atmosphere_type )
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN )
!
!       AerosolScatter:     CRTM_AtmScatter structure containing the forward model
!                           aerosol absorption and scattering properties required
!                           for radiative transfer.
!                           UNITS:      N/A
!                           TYPE:       TYPE( CRTM_AtmScatter_type )
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN )
!
!       AerosolScatter_AD:  CRTM_AtmScatter structure containing the adjoint
!                           aerosol absorption and scattering properties.
!                           **NOTE: On EXIT from this function, the contents of
!                                   this structure may be modified (e.g. set to
!                                   zero.)
!                           UNITS:      N/A
!                           TYPE:       TYPE( CRTM_AtmScatter_type )
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN OUT )
!
!       GeometryInfo:       CRTM_GeometryInfo structure containing the 
!                           view geometry information.
!                           UNITS:      N/A
!                           TYPE:       TYPE( CRTM_GeometryInfo_type )
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN )
!
!       Channel_Index:      Channel index id. This is a unique index associated
!                           with a (supported) sensor channel used to access the
!                           shared coefficient data.
!                           UNITS:      N/A
!                           TYPE:       INTEGER
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN )
!
!
! OPTIONAL INPUT ARGUMENTS:
!       Message_Log:        Character string specifying a filename in which any
!                           messages will be logged. If not specified, or if an
!                           error occurs opening the log file, the default action
!                           is to output messages to standard output.
!                           UNITS:      N/A
!                           TYPE:       CHARACTER(*)
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN ), OPTIONAL
!
! OUTPUT ARGUMENTS:
!       Atmosphere_AD:      CRTM Atmosphere structure containing the adjoint
!                           atmospheric state data.
!                           **NOTE: On ENTRY to this function, the contents of
!                                   this structure should be defined (e.g.
!                                   initialized to some value based on the
!                                   position of this function in the call chain.)
!                           UNITS:      N/A
!                           TYPE:       TYPE( CRTM_Atmosphere_type )
!                           DIMENSION:  Scalar
!                           ATTRIBUTES: INTENT( IN OUT )
!
!
! OPTIONAL OUTUPT ARGUMENTS:
!       None.
!
! FUNCTION RESULT:
!       Error_Status:       The return value is an integer defining the error
!                           status. The error codes are defined in the
!                           ERROR_HANDLER module.
!                           If == SUCCESS the computation was sucessful
!                              == FAILURE an unrecoverable error occurred
!                           UNITS:      N/A
!                           TYPE:       INTEGER
!                           DIMENSION:  Scalar
!
! CALLS:
!
! SIDE EFFECTS:
!
! RESTRICTIONS:
!
! COMMENTS:
!       Note the INTENT on all of the adjoint arguments (whether input or output)
!       is IN OUT rather than just OUT. This is necessary because the INPUT
!       adjoint arguments are modified, and the OUTPUT adjoint arguments must
!       be defined prior to entry to this routine. So, anytime a structure is
!       to be output, to prevent memory leaks the IN OUT INTENT is a must.
!
!S-
!------------------------------------------------------------------------------

  FUNCTION CRTM_Compute_AerosolScatter_AD( Atmosphere,        &  ! Input
                                           AerosolScatter,    &  ! Input
                                           AerosolScatter_AD, &  ! Input
                                           GeometryInfo,      &  ! Input
                                           Channel_Index,     &  ! Input
                                           Atmosphere_AD,     &  ! Output
                                           Message_Log )      &  ! Error messaging
                                         RESULT ( Error_Status )               


    !#--------------------------------------------------------------------------#
    !#                         -- TYPE DECLARATIONS --                          #
    !#--------------------------------------------------------------------------#

    ! ---------
    ! Arguments
    ! ---------

    ! -- Input
    TYPE( CRTM_Atmosphere_type ),   INTENT( IN )     :: Atmosphere
    TYPE( CRTM_AtmScatter_type ),   INTENT( IN )     :: AerosolScatter
    TYPE( CRTM_AtmScatter_type ),   INTENT( IN OUT ) :: AerosolScatter_AD
    TYPE( CRTM_GeometryInfo_type ), INTENT( IN )     :: GeometryInfo
    INTEGER,                        INTENT( IN )     :: Channel_Index

    ! -- Output 
    TYPE( CRTM_Atmosphere_type ),   INTENT( IN OUT ) :: Atmosphere_AD

    ! -- Error messaging
    CHARACTER( * ), OPTIONAL,       INTENT( IN )     :: Message_Log


    ! ---------------
    ! Function result
    ! ---------------

    INTEGER :: Error_Status


    ! ----------------
    ! Local parameters
    ! ----------------

    CHARACTER( * ), PARAMETER :: ROUTINE_NAME = 'CRTM_Compute_AerosolScatter_AD'


    ! ---------------
    ! Local variables
    ! ---------------




    !#--------------------------------------------------------------------------#
    !#                -- INITIALISE SUCCESSFUL RETURN STATUS --                 #
    !#--------------------------------------------------------------------------#

    Error_Status = SUCCESS



!  *** USERS INSERT CODE HERE ***




  END FUNCTION CRTM_Compute_AerosolScatter_AD

END MODULE CRTM_AerosolScatter


!---------------------------------------------------------------------------------
!                          -- MODIFICATION HISTORY --
!---------------------------------------------------------------------------------
!
! $Id$
!
! $Date: 2006/05/25 19:27:59 $
!
! $Revision: 1.4 $
!
! $Name:  $
!
! $State: Exp $
!
! $Log: CRTM_AerosolScatter.f90,v $
! Revision 1.4  2006/05/25 19:27:59  wd20pd
! Removed redundant parameter definitions.
!
! Revision 1.3  2006/05/02 14:58:34  dgroff
! - Replaced all references of Error_Handler with Message_Handler
!
! Revision 1.2  2005/02/25 17:49:48  paulv
! - Fixed incorrect function names.
!
! Revision 1.1  2005/02/25 00:13:14  paulv
! Initial checkin.
!
!
!


