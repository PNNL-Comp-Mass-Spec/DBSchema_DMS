/****** Object:  View [dbo].[V_Analysis_Results_XFer_Folder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW dbo.V_Analysis_Results_XFer_Folder
AS
SELECT Server, Client
FROM T_MiscPaths
WHERE ([Function] = 'AnalysisXfer')

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Results_XFer_Folder] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Results_XFer_Folder] TO [PNL\D3M580] AS [dbo]
GO
