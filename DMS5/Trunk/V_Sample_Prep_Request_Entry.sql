/****** Object:  View [dbo].[V_Sample_Prep_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Sample_Prep_Request_Entry
AS
SELECT     dbo.T_Sample_Prep_Request.Request_Name AS RequestName, dbo.T_Sample_Prep_Request.Requester_PRN AS RequesterPRN, 
                      dbo.T_Sample_Prep_Request.Reason, dbo.T_Sample_Prep_Request.Cell_Culture_List AS CellCultureList, dbo.T_Sample_Prep_Request.Organism, 
                      dbo.T_Sample_Prep_Request.Biohazard_Level AS BiohazardLevel, dbo.T_Sample_Prep_Request.Campaign, 
                      dbo.T_Sample_Prep_Request.Number_of_Samples AS NumberofSamples, dbo.T_Sample_Prep_Request.Sample_Name_List AS SampleNameList, 
                      dbo.T_Sample_Prep_Request.Sample_Type AS SampleType, dbo.T_Sample_Prep_Request.Prep_Method AS PrepMethod, 
                      dbo.T_Sample_Prep_Request.Prep_By_Robot AS PrepByRobot, dbo.T_Sample_Prep_Request.Special_Instructions AS SpecialInstructions, 
                      dbo.T_Sample_Prep_Request.Sample_Naming_Convention AS SampleNamingConvention, 
                      dbo.T_Sample_Prep_Request.Requested_Personnel AS RequestedPersonnel, 
                      dbo.T_Sample_Prep_Request.Assigned_Personnel AS AssignedPersonnel, 
                      dbo.T_Sample_Prep_Request.Estimated_Completion AS EstimatedCompletion, 
                      dbo.T_Sample_Prep_Request.Estimated_MS_runs AS EstimatedMSRuns, 
                      dbo.T_Sample_Prep_Request.Work_Package_Number AS WorkPackageNumber, 
                      dbo.T_Sample_Prep_Request.User_Proposal_Number AS UserProposalNumber, 
                      dbo.T_Sample_Prep_Request.Replicates_of_Samples AS ReplicatesofSamples, 
                      dbo.T_Sample_Prep_Request.Instrument_Analysis_Specifications AS InstrumentAnalysisSpecifications, dbo.T_Sample_Prep_Request.Comment, 
                      dbo.T_Sample_Prep_Request.Priority, dbo.T_Sample_Prep_Request_State_Name.State_Name AS State, dbo.T_Sample_Prep_Request.ID, 
                      dbo.T_Sample_Prep_Request.UseSingleLCColumn, dbo.T_Internal_Standards.Name AS internalStandard, 
                      T_Internal_Standards_1.Name AS postdigestIntStd
FROM         dbo.T_Sample_Prep_Request INNER JOIN
                      dbo.T_Sample_Prep_Request_State_Name ON dbo.T_Sample_Prep_Request.State = dbo.T_Sample_Prep_Request_State_Name.State_ID INNER JOIN
                      dbo.T_Internal_Standards ON dbo.T_Sample_Prep_Request.Internal_standard_ID = dbo.T_Internal_Standards.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Internal_Standards T_Internal_Standards_1 ON 
                      dbo.T_Sample_Prep_Request.Postdigest_internal_std_ID = T_Internal_Standards_1.Internal_Std_Mix_ID

GO
