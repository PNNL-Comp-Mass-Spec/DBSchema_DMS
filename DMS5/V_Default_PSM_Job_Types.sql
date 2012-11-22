/****** Object:  View [dbo].[V_Default_PSM_Job_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Default_PSM_Job_Types]
AS
SELECT Job_Type_Name,
       Job_Type_Description,
       Job_Type_ID
FROM dbo.T_Default_PSM_Job_Types


GO
