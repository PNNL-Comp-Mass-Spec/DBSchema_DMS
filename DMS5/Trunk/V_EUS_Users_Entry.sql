/****** Object:  View [dbo].[V_EUS_Users_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW dbo.V_EUS_Users_Entry
AS
SELECT  PERSON_ID AS ID, NAME_FM AS Name, Site_Status AS SiteStatus
FROM T_EUS_Users



GO
