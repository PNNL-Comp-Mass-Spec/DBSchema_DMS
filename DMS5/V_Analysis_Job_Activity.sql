/****** Object:  View [dbo].[V_Analysis_Job_Activity] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Activity]
AS
SELECT J.AJ_batchID AS Batch, J.AJ_jobID AS Job, 
    ISNULL(AJPG.Group_Name, '') AS Proc_Group, 
    J.Dataset_Num AS Dataset, J.AJ_priority AS Priority, 
    J.AJ_StateID AS State, J.AJS_Name AS StateName, 
    J.AJT_toolName AS Tool, J.AJ_parmFileName AS Param_File, 
    J.AJ_proteinCollectionList AS Protein_Collection, 
    J.AJ_proteinOptionsList AS Protein_Options, 
    ISNULL(J.AJR_workPackage, '') AS Work_Pkg, 
    J.AJ_created AS Created
FROM dbo.T_Analysis_Job_Processor_Group_Associations AJPGA INNER
     JOIN
    dbo.T_Analysis_Job_Processor_Group AJPG ON 
    AJPGA.Group_ID = AJPG.ID RIGHT OUTER JOIN
        (SELECT AJ.AJ_batchID, AJ.AJ_jobID, DS.Dataset_Num, 
           AJ.AJ_priority, AJ.AJ_StateID, ASN.AJS_Name, 
           Tool.AJT_toolName, AJ.AJ_parmFileName, 
           AJ.AJ_proteinCollectionList, AJ.AJ_proteinOptionsList, 
           AJR.AJR_workPackage, AJ.AJ_created
      FROM dbo.T_Analysis_Job AJ INNER JOIN
           dbo.T_Analysis_Tool Tool ON 
           AJ.AJ_analysisToolID = Tool.AJT_toolID INNER JOIN
           dbo.T_Dataset DS ON 
           AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
           dbo.T_Analysis_Job_Request AJR ON 
           AJ.AJ_requestID = AJR.AJR_requestID INNER JOIN
           dbo.T_Analysis_State_Name ASN ON 
           AJ.AJ_StateID = ASN.AJS_stateID
      WHERE (Tool.AJT_toolID IN
               (SELECT AJT_toolID
             FROM dbo.T_Analysis_Tool
             WHERE (AJT_active <> 0))) AND 
           (AJ.AJ_StateID IN (1, 2, 8) OR
           AJ.AJ_StateID = 5 AND DateDiff(DAY, AJ_Start, 
           GetDate()) < 14)
      GROUP BY AJ.AJ_jobID, Tool.AJT_toolName, 
           Tool.AJT_toolID, AJ.AJ_batchID, DS.Dataset_Num, 
           AJ.AJ_parmFileName, AJ.AJ_proteinCollectionList, 
           AJ.AJ_proteinOptionsList, AJR.AJR_workPackage, 
           AJ.AJ_priority, AJ.AJ_StateID, AJ.AJ_created, 
           ASN.AJS_Name) J ON 
    AJPGA.Job_ID = J.AJ_jobID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Activity] TO [DDL_Viewer] AS [dbo]
GO
