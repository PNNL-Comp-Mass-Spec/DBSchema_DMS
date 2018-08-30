/****** Object:  View [dbo].[V_RNA_Prep_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_RNA_Prep_Request_Detail_Report]
AS
SELECT  SPR.ID,
        SPR.Request_Name AS [Request Name],
        QP.Name_with_PRN AS Requester,
        SPR.Campaign,
        SPR.Reason,
        -- Deprecated in August 2018: SPR.Cell_Culture_List AS [Biomaterial List],
        SPR.Organism,
        -- Deprecated in August 2018: SPR.Number_Of_Biomaterial_Reps_Received AS [Number Of Biomaterial Reps Received],
        SPR.Biohazard_Level AS [Biohazard Level],
        SPR.Number_of_Samples AS [Number of Samples],
        SPR.Sample_Name_List AS [Sample Name List],
        SPR.Sample_Type AS [Sample Type],
        SPR.Prep_Method AS [Prep Method],
        SPR.Instrument_Name AS [Instrument Name],
        SPR.Dataset_Type AS [Dataset Type],
        SPR.Instrument_Analysis_Specifications AS [Instrument Analysis Specifications],
        SPR.Sample_Naming_Convention AS [Sample Group Naming Prefix],
        SPR.Work_Package_Number [Work Package Number],
        ISNULL(CC.Activation_State_Name, 'Invalid') AS [Work Package State],
        -- Deprecated in August 2018: SPR.Project_Number AS [Project Number],
        SPR.EUS_UsageType AS [EUS Usage Type],
        SPR.EUS_Proposal_ID AS [EUS Proposal],
        dbo.GetSamplePrepRequestEUSUsersList(SPR.ID, 'V') As [EUS User],            
        SPR.Estimated_Completion AS [Estimated Completion],
        SN.State_Name AS State,
        SPR.Created,
        dbo.ExperimentsFromRequest(SPR.ID) AS Experiments,
        NU.Updates,
        CASE
        WHEN SPR.State <> 5 AND
             CC.Activation_State >= 3 THEN 10    -- If the request is not closed, but the charge code is inactive, return 10 for #WPActivationState
        ELSE CC.Activation_State
        END AS #WPActivationState
FROM T_Sample_Prep_Request AS SPR
     INNER JOIN T_Sample_Prep_Request_State_Name AS SN
       ON SPR.State = SN.State_ID
     LEFT OUTER JOIN T_Users AS QP
       ON SPR.Requester_PRN = QP.U_PRN
     LEFT OUTER JOIN ( SELECT Request_ID,
                              COUNT(*) AS Updates
                       FROM T_Sample_Prep_Request_Updates
                       GROUP BY Request_ID ) AS NU
       ON SPR.ID = NU.Request_ID
     LEFT OUTER JOIN V_Charge_Code_Status CC
       ON SPR.Work_Package_Number = CC.Charge_Code
WHERE SPR.Request_Type = 'RNA'


GO
GRANT VIEW DEFINITION ON [dbo].[V_RNA_Prep_Request_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
