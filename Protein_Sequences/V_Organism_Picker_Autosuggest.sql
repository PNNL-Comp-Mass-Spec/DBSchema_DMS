/****** Object:  View [dbo].[V_Organism_Picker_Autosuggest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Organism_Picker_Autosuggest
AS
SELECT     id, organism_name AS value, abbrev_name AS info
FROM         dbo.V_Organism_Picker_For_Web

GO
