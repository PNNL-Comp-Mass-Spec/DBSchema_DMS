/****** Object:  View [dbo].[V_DMS_Pipeline_Existing_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Pipeline_Existing_Jobs]
AS
SELECT Job,
       State
FROM S_DMS_V_Get_Pipeline_Existing_Jobs


GO
