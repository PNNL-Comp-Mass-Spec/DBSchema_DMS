/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Association_Recent] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Processor_Group_Association_Recent]
AS
SELECT AJPG.Group_Name,
       AJPGA.Job_ID AS Job,
       ASN.AJS_name AS State,
       DS.Dataset_Num AS Dataset,
       Tool.AJT_toolName AS Tool,
       AJ.AJ_parmFileName AS [Parm File],
       AJ.AJ_settingsFileName AS [Settings File]
FROM dbo.T_Analysis_Job_Processor_Group_Membership AJPGM
     RIGHT OUTER JOIN dbo.T_Analysis_Job_Processor_Group_Associations AJPGA
                      INNER JOIN dbo.T_Analysis_Job AJ
                        ON AJPGA.Job_ID = AJ.AJ_jobID
                      INNER JOIN dbo.T_Dataset DS
                        ON AJ.AJ_datasetID = DS.Dataset_ID
                      INNER JOIN dbo.T_Analysis_Tool Tool
                        ON AJ.AJ_analysisToolID = Tool.AJT_toolID
                      INNER JOIN dbo.T_Analysis_State_Name ASN
                        ON AJ.AJ_StateID = ASN.AJS_stateID
                      INNER JOIN dbo.T_Analysis_Job_Processor_Group AJPG
                        ON AJPGA.Group_ID = AJPG.ID
       ON AJPGM.Group_ID = AJPG.ID AND
          AJPGM.Membership_Enabled = 'Y'
WHERE (AJ.AJ_StateID IN (1, 2, 3, 8, 9, 10, 11, 16, 17)) OR
      AJ.AJ_Finish >= DateAdd(day, -5, GetDate())
GROUP BY AJPGA.Job_ID, ASN.AJS_name, DS.Dataset_Num, Tool.AJT_toolName, AJ.AJ_parmFileName,
         AJ.AJ_settingsFileName, AJPGA.Group_ID, AJPG.Group_Name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Association_Recent] TO [PNL\D3M578] AS [dbo]
GO
