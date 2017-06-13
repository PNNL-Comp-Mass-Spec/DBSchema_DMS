/****** Object:  View [dbo].[V_Sample_Prep_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Entry]
AS
    SELECT SPR.Request_Name AS RequestName,
           SPR.Requester_PRN AS RequesterPRN,
           SPR.Reason,
           SPR.Organism,
           SPR.Biohazard_Level AS BiohazardLevel,
           SPR.Campaign,
           SPR.Number_of_Samples AS NumberofSamples,
           SPR.Sample_Name_List AS SampleNameList,
           SPR.Sample_Type AS SampleType,
           SPR.Prep_Method AS PrepMethod,
           SPR.Sample_Naming_Convention AS SampleNamingConvention,
           SPR.Requested_Personnel AS RequestedPersonnel,
           SPR.Assigned_Personnel AS AssignedPersonnel,
           SPR.Estimated_Completion AS EstimatedCompletion,
           SPR.Estimated_MS_runs AS EstimatedMSRuns,
           SPR.Work_Package_Number AS WorkPackageNumber,
           SPR.Instrument_Group AS InstrumentGroup,
           SPR.Dataset_Type AS DatasetType,
           SPR.Instrument_Analysis_Specifications AS InstrumentAnalysisSpecifications,
           SPR.[Comment],
           SPR.Priority,
           T_Sample_Prep_Request_State_Name.State_Name AS State,
           SPR.ID,
           SPR.EUS_UsageType AS eusUsageType,
           SPR.EUS_Proposal_ID AS eusProposalID,
           SPR.EUS_User_List AS eusUsersList,
           SPR.Facility,
           SPR.Separation_Type AS SeparationGroup,
           SPR.BlockAndRandomizeSamples,
           SPR.BlockAndRandomizeRuns,
           SPR.Reason_For_High_Priority AS ReasonForHighPriority,
           SPR.Material_Container_List AS MaterialContainerList
    FROM T_Sample_Prep_Request AS SPR
         INNER JOIN T_Sample_Prep_Request_State_Name
           ON SPR.State = T_Sample_Prep_Request_State_Name.State_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Entry] TO [DDL_Viewer] AS [dbo]
GO
