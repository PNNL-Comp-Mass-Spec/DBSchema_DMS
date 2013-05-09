/****** Object:  View [dbo].[V_Sample_Prep_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Sample_Prep_Request_Entry]
AS
    SELECT  SPR.Request_Name AS RequestName ,
            SPR.Requester_PRN AS RequesterPRN ,
            SPR.Reason ,
            SPR.Cell_Culture_List AS CellCultureList ,
            SPR.Organism ,
            SPR.Biohazard_Level AS BiohazardLevel ,
            SPR.Campaign ,
            SPR.Number_of_Samples AS NumberofSamples ,
            SPR.Sample_Name_List AS SampleNameList ,
            SPR.Sample_Type AS SampleType ,
            SPR.Prep_Method AS PrepMethod ,
            SPR.Prep_By_Robot AS PrepByRobot ,
            SPR.Special_Instructions AS SpecialInstructions ,
            SPR.Sample_Naming_Convention AS SampleNamingConvention ,
            SPR.Requested_Personnel AS RequestedPersonnel ,
            SPR.Assigned_Personnel AS AssignedPersonnel ,
            SPR.Estimated_Completion AS EstimatedCompletion ,
            SPR.Estimated_MS_runs AS EstimatedMSRuns ,
            SPR.Work_Package_Number AS WorkPackageNumber ,
            SPR.Replicates_of_Samples AS ReplicatesofSamples ,
            SPR.Instrument_Name AS InstrumentGroup ,
            SPR.Technical_Replicates AS TechnicalReplicates ,
            SPR.Dataset_Type AS DatasetType ,
            SPR.Instrument_Analysis_Specifications AS InstrumentAnalysisSpecifications ,
            SPR.Comment ,
            SPR.Priority ,
            T_Sample_Prep_Request_State_Name.State_Name AS State ,
            SPR.ID ,
            SPR.UseSingleLCColumn ,
            SPR.EUS_UsageType AS eusUsageType ,
            SPR.EUS_Proposal_ID AS eusProposalID ,
            SPR.EUS_User_List AS eusUsersList ,
            SPR.Project_Number AS ProjectNumber ,
            SPR.Facility ,
            SPR.Separation_Type AS SeparationGroup ,
            SPR.BlockAndRandomizeSamples ,
            SPR.BlockAndRandomizeRuns ,
            SPR.IOPSPermitsCurrent,
            Reason_For_High_Priority AS ReasonForHighPriority,
            Number_Of_Biomaterial_Reps_Received AS NumberOfBiomaterialRepsReceived
    FROM    T_Sample_Prep_Request AS SPR
            INNER JOIN T_Sample_Prep_Request_State_Name ON SPR.State = T_Sample_Prep_Request_State_Name.State_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Entry] TO [PNL\D3M580] AS [dbo]
GO
