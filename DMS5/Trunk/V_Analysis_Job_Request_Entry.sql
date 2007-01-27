/****** Object:  View [dbo].[V_Analysis_Job_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Analysis_Job_Request_Entry
AS
SELECT AR.AJR_requestID, AR.AJR_requestName, AR.AJR_created, 
    AR.AJR_analysisToolName, AR.AJR_parmFileName, 
    AR.AJR_settingsFileName, AR.AJR_organismDBName, 
    Org.OG_name AS AJR_organismName, AR.AJR_datasets, 
    AR.AJR_comment, ARS.StateName AS State, 
    U.U_PRN AS requestor, 
    AR.AJR_workPackage AS workPackage, 
    AR.AJR_proteinCollectionList AS protCollNameList, 
    AR.AJR_proteinOptionsList AS protCollOptionsList
FROM T_Analysis_Job_Request AR INNER JOIN
    T_Analysis_Job_Request_State ARS ON 
    AR.AJR_state = ARS.ID INNER JOIN
    T_Users U ON AR.AJR_requestor = U.ID INNER JOIN
    T_Organisms Org ON 
    AR.AJR_organism_ID = Org.Organism_ID


GO
