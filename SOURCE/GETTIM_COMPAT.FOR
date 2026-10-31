      SUBROUTINE GETTIM(IHR, IMIN, ISEC, IHUND)
C     Compatibility shim for Compaq Visual Fortran GETTIM
C     on Linux/gfortran.
      INTEGER IHR, IMIN, ISEC, IHUND
      INTEGER ITIME_ARRAY(3)
C     Get hour/minute/second using gfortran's ITIME extension
      CALL ITIME(ITIME_ARRAY)
      IHR  = ITIME_ARRAY(1)
      IMIN = ITIME_ARRAY(2)
      ISEC = ITIME_ARRAY(3)
C     Hundredths of a second is not easily available via ITIME;
C     return 0 to keep timing functional (output accuracy may be
C     reduced, but it won't cause crashes).
      IHUND = 0
      RETURN
      END