/****** Object:  View [dbo].[V_RNA_Prep_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_RNA_Prep_Request_Entry
AS
    SELECT  SPR.Request_Name AS RequestName ,
            SPR.Requester_PRN AS RequesterPRN ,
            SPR.Reason ,
            SPR.Cell_Culture_List AS BiomaterialList ,
            SPR.Organism ,
            SPR.Biohazard_Level AS BiohazardLevel ,
            SPR.Campaign ,
            SPR.Number_of_Samples AS NumberofSamples ,
            SPR.Sample_Name_List AS SampleNameList ,
            SPR.Sample_Type AS SampleType ,
            SPR.Prep_Method AS PrepMethod ,
            SPR.Sample_Naming_Convention AS SampleNamingConvention ,
            SPR.Estimated_Completion AS EstimatedCompletion ,
            SPR.Work_Package_Number AS WorkPackageNumber ,
            SPR.Instrument_Name AS InstrumentName ,
            SPR.Dataset_Type AS DatasetType ,
            SPR.Instrument_Analysis_Specifications AS InstrumentAnalysisSpecifications ,
            T_Sample_Prep_Request_State_Name.State_Name AS State ,
            SPR.ID ,
            SPR.EUS_UsageType AS eusUsageType ,
            SPR.EUS_Proposal_ID AS eusProposalID ,
            SPR.EUS_User_List AS eusUsersList ,
            SPR.Project_Number AS ProjectNumber ,
            Number_Of_Biomaterial_Reps_Received AS NumberOfBiomaterialRepsReceived
    FROM    T_Sample_Prep_Request AS SPR
            INNER JOIN T_Sample_Prep_Request_State_Name ON SPR.State = T_Sample_Prep_Request_State_Name.State_ID

GO
