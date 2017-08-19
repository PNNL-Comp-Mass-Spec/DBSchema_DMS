/****** Object:  View [dbo].[V_BTO_ID_to_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_BTO_ID_to_Name]
AS
	SELECT identifier AS Identifier, Min(Term_Name) AS Tissue
	FROM T_CV_BTO
	GROUP BY identifier


GO
