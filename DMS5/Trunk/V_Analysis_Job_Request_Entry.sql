/****** Object:  View [dbo].[V_Analysis_Job_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  VIEW dbo.V_Analysis_Job_Request_Entry
AS
SELECT  AR.AJR_requestID, AR.AJR_requestName, AR.AJR_created, 
        AR.AJR_analysisToolName, AR.AJR_parmFileName, 
        AR.AJR_settingsFileName, AR.AJR_organismDBName, 
        AR.AJR_organismName, AR.AJR_datasets, AR.AJR_comment, 
        ARS.StateName AS State, U.U_PRN AS requestor, AR.AJR_workPackage as workPackage, 
        AR.AJR_proteinCollectionList AS protCollNameList, 
        AR.AJR_proteinOptionsList AS protCollOptionsList
FROM    dbo.T_Analysis_Job_Request AR INNER JOIN
        dbo.T_Analysis_Job_Request_State ARS ON AR.AJR_state = ARS.ID INNER JOIN
        dbo.T_Users U ON AR.AJR_requestor = U.ID



GO
