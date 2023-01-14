/****** Object:  View [dbo].[V_DMS_Dataset_Scans] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Dataset_Scans]
AS
SELECT Dataset_ID,
       Dataset,
       Instrument,
       Dataset_Type,
       Scan_Type,
       Scan_Count,
       Scan_Filter,
       Scan_Count_Total,
       Entry_ID
FROM S_DMS_V_Dataset_Scans


GO
