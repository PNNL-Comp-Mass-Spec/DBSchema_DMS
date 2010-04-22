/****** Object:  View [dbo].[V_Analysis_Job_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Request_Entry
AS
SELECT     AR.AJR_requestID, AR.AJR_requestName, AR.AJR_created, AR.AJR_analysisToolName, AR.AJR_parmFileName, AR.AJR_settingsFileName, 
                      AR.AJR_organismDBName, Org.OG_name AS AJR_organismName, AR.AJR_datasets, AR.AJR_comment, ARS.StateName AS State, 
                      U.U_PRN AS requestor, AR.AJR_workPackage AS workPackage, AR.AJR_proteinCollectionList AS protCollNameList, 
                      AR.AJR_proteinOptionsList AS protCollOptionsList, 'No' AS adminReviewReqd
FROM         dbo.T_Analysis_Job_Request AS AR INNER JOIN
                      dbo.T_Analysis_Job_Request_State AS ARS ON AR.AJR_state = ARS.ID INNER JOIN
                      dbo.T_Users AS U ON AR.AJR_requestor = U.ID INNER JOIN
                      dbo.T_Organisms AS Org ON AR.AJR_organism_ID = Org.Organism_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_Entry] TO [PNL\D3M580] AS [dbo]
GO
