/****** Object:  View [dbo].[V_Sample_Submission_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Sample_Submission_Detail_Report
as
SELECT     TSS.ID, TC.Campaign_Num AS Campaign, TU.U_Name + ' (' + TU.U_PRN + ')' AS [Received By], TSS.Description, 
                      TSS.Container_List AS [Container List], CASE WHEN TPFS.Path_Shared_Root IS NULL 
                      THEN '' ELSE TPFS.Path_Shared_Root + dbo.GetDMSFileStoragePath(TC.Campaign_Num, TSS.ID, 'sample_submission') END AS [Storage Folder], 
                      TSS.Created
FROM         T_Sample_Submission AS TSS INNER JOIN
                      T_Campaign AS TC ON TSS.Campaign_ID = TC.Campaign_ID INNER JOIN
                      T_Users AS TU ON TSS.Received_By_User_ID = TU.ID LEFT OUTER JOIN
                      T_Prep_File_Storage AS TPFS ON TSS.Storage_Path = TPFS.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Submission_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Submission_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
