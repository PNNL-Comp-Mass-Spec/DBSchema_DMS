/****** Object:  View [dbo].[V_Web_Organism_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Web_Organism_Info
AS
SELECT     ID AS Organism_ID, Expr2 AS Name, Organism_Name AS [Full Name]
FROM         dbo.V_Organism_Picker

GO
