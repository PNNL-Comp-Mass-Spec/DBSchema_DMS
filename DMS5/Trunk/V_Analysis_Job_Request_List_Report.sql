/****** Object:  View [dbo].[V_Analysis_Job_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Analysis_Job_Request_List_Report
AS
SELECT AJR.AJR_requestID AS Request, 
    AJR.AJR_requestName AS Name, AJRS.StateName AS State, 
    U.U_Name AS Requestor, AJR.AJR_created AS Created, 
    AJR.AJR_analysisToolName AS Tool, 
    AJR.AJR_parmFileName AS [Param File], 
    Org.OG_name AS Organism, 
    AJR.AJR_organismDBName AS [Organism DB File], 
    AJR.AJR_proteinCollectionList AS ProteinCollectionList, 
    AJR.AJR_proteinOptionsList AS ProteinOptions, 
    CAST(AJR.AJR_datasets AS char(40)) AS Datasets, 
    AJR.AJR_comment AS Comment, COUNT(AJ.AJ_jobID) 
    AS Jobs
FROM T_Analysis_Job_Request AJR INNER JOIN
    T_Users U ON AJR.AJR_requestor = U.ID INNER JOIN
    T_Analysis_Job_Request_State AJRS ON 
    AJR.AJR_state = AJRS.ID INNER JOIN
    T_Organisms Org ON 
    AJR.AJR_organism_ID = Org.Organism_ID LEFT OUTER JOIN
    T_Analysis_Job AJ ON 
    AJR.AJR_requestID = AJ.AJ_requestID
GROUP BY AJR.AJR_requestID, AJR.AJR_requestName, 
    AJRS.StateName, AJR.AJR_created, 
    AJR.AJR_analysisToolName, Org.OG_name, 
    CAST(AJR.AJR_datasets AS char(40)), U.U_Name, 
    AJR.AJR_comment, AJR.AJR_parmFileName, 
    AJR.AJR_organismDBName, AJR.AJR_proteinCollectionList, 
    AJR.AJR_proteinOptionsList


GO
