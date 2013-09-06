/****** Object:  View [dbo].[V_OSM_Package_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_OSM_Package_List_Report]
AS
    SELECT  TOSM.ID ,
            TOSM.Name ,
            TOSM.Package_Type AS Type ,
            TOSM.Description ,
            TOSM.Keywords ,
            TOSM.Comment ,
            TONR.U_Name + ' (' + ISNULL(TOSM.Owner, '') + ')' AS Owner ,
            TOSM.Created ,
            TOSM.State,
            TOSM.Last_Modified AS Modified ,
            TOSM.Sample_Prep_Requests AS [Sample Prep] 
    FROM    dbo.T_OSM_Package AS TOSM
            LEFT OUTER JOIN dbo.S_V_Users AS TONR ON TONR.U_PRN = TOSM.Owner




GO
