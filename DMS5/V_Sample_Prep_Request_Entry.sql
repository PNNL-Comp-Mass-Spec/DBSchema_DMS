/****** Object:  View [dbo].[V_Sample_Prep_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Entry]
AS
SELECT  SPR.Request_Name AS RequestName,
        SPR.Requester_PRN AS RequesterPRN,
        SPR.Reason + '__NoCopy__' As Reason,
        SPR.Organism,
        BTO.Tissue,
        SPR.Biohazard_Level AS BiohazardLevel,
        SPR.Campaign,
        Cast(SPR.Number_of_Samples As Varchar(12)) + '__NoCopy__' AS NumberofSamples,
        SPR.Sample_Name_List AS SampleNameList,
        SPR.Sample_Type AS SampleType,
        SPR.Prep_Method AS PrepMethod,
        SPR.Sample_Naming_Convention AS SampleNamingConvention,
        SPR.Requested_Personnel AS RequestedPersonnel,
        SPR.Assigned_Personnel AS AssignedPersonnel,
        SPR.Estimated_Prep_Time_Days AS EstimatedPrepTimeDays,
        Cast(SPR.Estimated_MS_runs As Varchar(12)) + '__NoCopy__' AS EstimatedMSRuns,
        SPR.Work_Package_Number AS WorkPackage,
        SPR.Instrument_Group AS InstrumentGroup,
        SPR.Dataset_Type AS DatasetType,
        SPR.Instrument_Analysis_Specifications AS InstrumentAnalysisSpecifications,
        SPR.[Comment] + '__NoCopy__' As [Comment],
        SPR.Priority,
        T_Sample_Prep_Request_State_Name.State_Name AS [State],
        SPR.State_Comment As StateComment,
        SPR.ID,
        SPR.EUS_UsageType AS eusUsageType,
        SPR.EUS_Proposal_ID AS eusProposalID,
        SPR.EUS_User_ID AS eusUserID,
        SPR.Facility,
        SPR.Separation_Type AS SeparationGroup,
        SPR.BlockAndRandomizeSamples,
        SPR.BlockAndRandomizeRuns,
        SPR.Reason_For_High_Priority + '__NoCopy__' AS ReasonForHighPriority,
        SPR.Material_Container_List + '__NoCopy__' AS MaterialContainerList
FROM T_Sample_Prep_Request AS SPR
     INNER JOIN T_Sample_Prep_Request_State_Name
       ON SPR.State = T_Sample_Prep_Request_State_Name.State_ID
     LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
       ON SPR.Tissue_ID = BTO.Identifier

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Entry] TO [DDL_Viewer] AS [dbo]
GO
