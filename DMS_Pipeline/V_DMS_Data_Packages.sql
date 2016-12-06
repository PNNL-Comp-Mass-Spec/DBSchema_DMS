/****** Object:  View [dbo].[V_DMS_Data_Packages] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Data_Packages]
AS
SELECT 	ID,
		Name,
		[Package Type],
		Description,
		Comment,
		Owner,
		Requester,
		Team,
		Created,
		[Last Modified],
		State,
		[Package File Folder],
		[Share Path],
		[Web Path],
		[MyEMSL URL],
		[AMT Tag Database],
		[Biomaterial Item Count],
		[Experiment Item Count],
		[EUS Proposals Count],
		[Dataset Item Count],
		[Analysis Job Item Count],
		[Total Item Count],
		[PRISM Wiki]
FROM S_Data_Package_Details


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Data_Packages] TO [DDL_Viewer] AS [dbo]
GO
