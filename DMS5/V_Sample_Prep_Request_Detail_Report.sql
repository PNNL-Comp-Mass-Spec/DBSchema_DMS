/****** Object:  View [dbo].[V_Sample_Prep_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Sample_Prep_Request_Detail_Report
AS
    SELECT  SPR.ID ,
            SPR.Request_Name AS [Request Name] ,
            QP.U_Name + ' (' + SPR.Requester_PRN + ')' AS Requester ,
            SPR.Campaign ,
            SPR.Reason ,
            SPR.Cell_Culture_List AS [Biomaterial List] ,
            SPR.Organism ,
            SPR.Number_Of_Biomaterial_Reps_Received AS [Number Of Biomaterial Reps Received] ,
            SPR.Biohazard_Level AS [Biohazard Level] ,
            SPR.Number_of_Samples AS [Number of Samples] ,
            SPR.BlockAndRandomizeSamples AS [Block And Randomize Samples] ,
            SPR.Sample_Name_List AS [Sample Name List] ,
            SPR.Sample_Type AS [Sample Type] ,
            SPR.Prep_Method AS [Prep Method] ,
            SPR.Replicates_of_Samples AS [Process Replicates] ,
            SPR.Special_Instructions AS [Special Instructions] ,
            SPR.Comment ,
            SPR.Estimated_MS_runs AS [MS Runs To Be Generated] ,
            SPR.Technical_Replicates AS [Technical Replicates] ,
            SPR.Instrument_Group AS [Instrument Group] ,
            SPR.Dataset_Type AS [Dataset Type] ,
            SPR.Separation_Type AS [Separation Group] ,
            SPR.Instrument_Analysis_Specifications AS [Instrument Analysis Specifications] ,
            SPR.UseSingleLCColumn AS [Use single LC column] ,
            SPR.BlockAndRandomizeRuns AS [Block And Randomize Runs] ,
            SPR.Sample_Naming_Convention AS [Sample Group Naming Prefix] ,
            SPR.Work_Package_Number [Work Package Number] ,
            ISNULL(CC.Activation_State_Name, 'Invalid') AS [Work Package State] ,
            SPR.Project_Number AS [Project Number] ,
            SPR.EUS_UsageType AS [EUS Usage Type] ,
            SPR.EUS_Proposal_ID AS [EUS Proposal] ,
			dbo.GetSamplePrepRequestEUSUsersList(SPR.ID, 'V') As [EUS User],            
            SPR.Requested_Personnel AS [Requested Personnel] ,
            SPR.Assigned_Personnel AS [Assigned Personnel] ,
            SPR.Estimated_Completion AS [Estimated Completion] ,
            SPR.IOPSPermitsCurrent AS [IOPS Permits Current] ,
            SPR.Priority ,
            SPR.Reason_For_High_Priority AS [Reason For High Priority] ,
            SN.State_Name AS State ,
            SPR.Created ,
            QT.[Complete or Closed] ,
            QT.[Days In Queue] ,
            dbo.ExperimentsFromRequest(SPR.ID) AS Experiments ,
            NU.Updates ,
            Biomaterial_Item_Count AS [Biomaterial Item Count] ,
            Experiment_Item_Count AS [Experiment Item Count] ,
            Experiment_Group_Item_Count AS [Experiment Group Item Count] ,
            Material_Containers_Item_Count AS [Material Containers Item Count] ,
            Requested_Run_Item_Count AS [Requested Run Item Count] ,
            Dataset_Item_Count AS [Dataset Item Count] ,
            HPLC_Runs_Item_Count AS [HPLC Runs Item Count] ,
            SPR.Total_Item_Count,
			Case
            When SPR.State <> 5 AND
                 CC.Activation_State >= 3 THEN 10	-- If the request is not closed, but the charge code is inactive, then return 10 for #WPActivationState
            Else CC.Activation_State
            End AS #WPActivationState
    FROM    T_Sample_Prep_Request AS SPR
            INNER JOIN T_Sample_Prep_Request_State_Name AS SN ON SPR.State = SN.State_ID
            LEFT OUTER JOIN T_Users AS QP ON SPR.Requester_PRN = QP.U_PRN
            LEFT OUTER JOIN ( SELECT    Request_ID ,
                                        COUNT(*) AS Updates
                              FROM      T_Sample_Prep_Request_Updates
                              GROUP BY  Request_ID
                            ) AS NU ON SPR.ID = NU.Request_ID
            LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times AS QT ON SPR.ID = QT.Request_ID
            LEFT OUTER JOIN V_Charge_Code_Status CC ON SPR.Work_Package_Number = CC.Charge_Code

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
