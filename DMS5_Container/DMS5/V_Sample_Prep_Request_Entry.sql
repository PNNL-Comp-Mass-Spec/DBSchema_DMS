/****** Object:  View [dbo].[V_Sample_Prep_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Sample_Prep_Request_Entry as
SELECT        T_Sample_Prep_Request.Request_Name AS RequestName, T_Sample_Prep_Request.Requester_PRN AS RequesterPRN, T_Sample_Prep_Request.Reason, 
                         T_Sample_Prep_Request.Cell_Culture_List AS CellCultureList, T_Sample_Prep_Request.Organism, T_Sample_Prep_Request.Biohazard_Level AS BiohazardLevel, 
                         T_Sample_Prep_Request.Campaign, T_Sample_Prep_Request.Number_of_Samples AS NumberofSamples, 
                         T_Sample_Prep_Request.Sample_Name_List AS SampleNameList, T_Sample_Prep_Request.Sample_Type AS SampleType, 
                         T_Sample_Prep_Request.Prep_Method AS PrepMethod, T_Sample_Prep_Request.Prep_By_Robot AS PrepByRobot, 
                         T_Sample_Prep_Request.Special_Instructions AS SpecialInstructions, T_Sample_Prep_Request.Sample_Naming_Convention AS SampleNamingConvention, 
                         T_Sample_Prep_Request.Requested_Personnel AS RequestedPersonnel, T_Sample_Prep_Request.Assigned_Personnel AS AssignedPersonnel, 
                         T_Sample_Prep_Request.Estimated_Completion AS EstimatedCompletion, T_Sample_Prep_Request.Estimated_MS_runs AS EstimatedMSRuns, 
                         T_Sample_Prep_Request.Work_Package_Number AS WorkPackageNumber, T_Sample_Prep_Request.Replicates_of_Samples AS ReplicatesofSamples, 
                         T_Sample_Prep_Request.Instrument_Name AS InstrumentName, T_Sample_Prep_Request.Technical_Replicates AS TechnicalReplicates, 
                         T_Sample_Prep_Request.Dataset_Type AS DatasetType, T_Sample_Prep_Request.Instrument_Analysis_Specifications AS InstrumentAnalysisSpecifications, 
                         T_Sample_Prep_Request.Comment, T_Sample_Prep_Request.Priority, T_Sample_Prep_Request_State_Name.State_Name AS State, T_Sample_Prep_Request.ID, 
                         T_Sample_Prep_Request.UseSingleLCColumn, T_Internal_Standards.Name AS internalStandard, T_Internal_Standards_1.Name AS postdigestIntStd, 
                         T_Sample_Prep_Request.EUS_UsageType AS eusUsageType, T_Sample_Prep_Request.EUS_Proposal_ID AS eusProposalID, 
                         T_Sample_Prep_Request.EUS_User_List AS eusUsersList, T_Sample_Prep_Request.Project_Number AS ProjectNumber, T_Sample_Prep_Request.Facility, 
                         T_Sample_Prep_Request.Separation_Type AS SeparationType
FROM            T_Sample_Prep_Request INNER JOIN
                         T_Sample_Prep_Request_State_Name ON T_Sample_Prep_Request.State = T_Sample_Prep_Request_State_Name.State_ID INNER JOIN
                         T_Internal_Standards ON T_Sample_Prep_Request.Internal_standard_ID = T_Internal_Standards.Internal_Std_Mix_ID INNER JOIN
                         T_Internal_Standards AS T_Internal_Standards_1 ON T_Sample_Prep_Request.Postdigest_internal_std_ID = T_Internal_Standards_1.Internal_Std_Mix_ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Entry] TO [PNL\D3M580] AS [dbo]
GO
