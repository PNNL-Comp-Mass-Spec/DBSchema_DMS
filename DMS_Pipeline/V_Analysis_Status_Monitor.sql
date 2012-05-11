/****** Object:  View [dbo].[V_Analysis_Status_Monitor] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Analysis_Status_Monitor
AS
SELECT ISNULL(ASM.ID, LP.ID) AS ID,
       ISNULL(ASM.Name, PS.Processor_Name) AS Name,
       CASE
           WHEN ASM.Name IS NULL THEN dbo.GetProcessorStepToolList(PS.Processor_Name)
           ELSE CASE
                    WHEN dbo.GetProcessorStepToolList(ASM.Name) = '' THEN ASM.Tools
                    ELSE dbo.GetProcessorStepToolList(ASM.Name)
                END
       END AS Tools,
       ISNULL(ASM.EnabledGroups, '') AS EnabledGroups,
       ISNULL(ASM.DisabledGroups, '') AS DisabledGroups,
       ISNULL(ASM.StatusFileNamePath, '') AS StatusFileNamePath,
       ISNULL(ASM.CheckBoxState, 1) AS CheckBoxState,
       ISNULL(ASM.UseForStatusCheck, 1) AS UseForStatusCheck,
       ISNULL(PS.Mgr_Status, 'Unknown_Status') AS Status_Name,
       PS.Job,
       PS.Job_Step,
       PS.Step_Tool,
       PS.Dataset,
       PS.Duration_Hours,
       PS.Progress,
       PS.Spectrum_Count AS DS_Scan_Count,
       PS.Most_Recent_Job_Info,
       PS.Most_Recent_Log_Message,
       PS.Most_Recent_Error_Message,
       PS.Status_Date,
       CONVERT(decimal(9, 1), DATEDIFF(SECOND, PS.Status_Date, GETDATE()) / 60.0) AS 
         LastCPUStatus_Minutes
FROM dbo.T_Local_Processors AS LP
     RIGHT OUTER JOIN dbo.T_Processor_Status AS PS
       ON LP.Processor_Name = PS.Processor_Name
     FULL OUTER JOIN dbo.S_DMS_Analysis_Status_Monitor AS ASM
       ON PS.Processor_Name = ASM.Name
WHERE (ISNULL(ASM.UseForStatusCheck, 1) > 0)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Status_Monitor] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Status_Monitor] TO [PNL\D3M580] AS [dbo]
GO
