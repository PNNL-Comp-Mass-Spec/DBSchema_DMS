/****** Object:  View [dbo].[V_Settings_Files_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Settings_Files_Entry]
AS
SELECT id,
       analysis_tool,
       file_name,
       description,
       active,
       CONVERT(varchar(MAX), Contents) AS contents,
       HMS_AutoSupersede AS hms_auto_supersede,
       MSGFPlus_AutoCentroid AS auto_centroid
FROM dbo.T_Settings_Files


GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_Files_Entry] TO [DDL_Viewer] AS [dbo]
GO
