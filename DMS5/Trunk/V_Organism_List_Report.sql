/****** Object:  View [dbo].[V_Organism_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Organism_List_Report
AS
SELECT     Organism_ID AS ID, OG_name AS Name, OG_description AS Description, OG_created AS Created
FROM         dbo.T_Organisms

GO
