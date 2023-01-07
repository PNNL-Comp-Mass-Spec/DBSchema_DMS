/****** Object:  View [dbo].[V_OSM_Package_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_OSM_Package_List_Report]
AS
SELECT TOSM.id,
       TOSM.name,
       TOSM.Package_Type AS type,
       TOSM.description,
       TOSM.keywords,
       TOSM.comment,
       TONR.U_Name + ' (' + ISNULL(TOSM.owner, '') + ')' AS owner,
       TOSM.created,
       TOSM.state,
       TOSM.Last_Modified AS modified,
       TOSM.Sample_Prep_Requests AS sample_prep
FROM dbo.T_OSM_Package AS TOSM
        LEFT OUTER JOIN dbo.S_V_Users AS TONR ON TONR.U_PRN = TOSM.Owner


GO
GRANT VIEW DEFINITION ON [dbo].[V_OSM_Package_List_Report] TO [DDL_Viewer] AS [dbo]
GO
