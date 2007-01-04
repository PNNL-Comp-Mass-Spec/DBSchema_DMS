/****** Object:  View [dbo].[V_Organism_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Organism_List_Report
AS
SELECT TOP 100 PERCENT Organism_ID AS ID, 
    OG_name AS Name, OG_description AS Description, 
    OG_created AS Created, OG_Active AS Active
FROM dbo.T_Organisms

GO
