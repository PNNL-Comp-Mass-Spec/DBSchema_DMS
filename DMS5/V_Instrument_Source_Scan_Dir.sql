/****** Object:  View [dbo].[V_Instrument_Source_Scan_Dir] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Instrument_Source_Scan_Dir
AS
SELECT     Server AS ScanFileDir
FROM         dbo.T_MiscPaths
WHERE     ([Function] = 'InstrumentSourceScanDir')

GO
