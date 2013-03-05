/****** Object:  View [dbo].[V_OSM_Package_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_OSM_Package_List_Report
AS
SELECT        TOSM.ID, TOSM.Name, TOSM.Package_Type AS Type, TOSM.Description, TOSM.Keywords, TOSM.Comment, TONR.U_Name + ' (' + ISNULL(TOSM.Owner, '') 
                         + ')' AS Owner, TOSM.Created, TOSM.Last_Modified AS Modified, TOSM.State, TOSM.Sample_Submission_Item_Count AS [Sample Sub.], 
                         TOSM.Sample_Prep_Request_Item_Count AS [Sample Prep], TOSM.Material_Containers_Item_Count AS [Matl. Cont.], 
                         TOSM.Experiment_Group_Item_Count AS [Exp. Groups], TOSM.Experiment_Item_Count AS Exps, TOSM.HPLC_Runs_Item_Count AS HPLC, 
                         TOSM.Requested_Run_Item_Count AS [Req. Runs], TOSM.Dataset_Item_Count AS Datasets, TOSM.Total_Item_Count AS Total
FROM            dbo.T_OSM_Package AS TOSM LEFT OUTER JOIN
                         dbo.S_V_Users AS TONR ON TONR.U_PRN = TOSM.Owner

GO
