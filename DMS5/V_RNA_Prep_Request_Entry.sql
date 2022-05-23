/****** Object:  View [dbo].[V_RNA_Prep_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_RNA_Prep_Request_Entry]
AS
SELECT SPR.request_name,
       SPR.requester_prn ,
       SPR.reason,
       SPR.organism,
       SPR.biohazard_level,
       SPR.campaign,
       SPR.number_of_samples,
       SPR.sample_name_list,
       SPR.sample_type,
       SPR.prep_method,
       SPR.sample_naming_convention,
       SPR.estimated_completion,
       SPR.work_package_number,
       SPR.instrument_name,
       SPR.dataset_type,
       SPR.instrument_analysis_specifications,
       SN.State_Name AS state,
       SPR.id,
       SPR.EUS_UsageType AS eus_usage_type,
       SPR.eus_proposal_id,
       SPR.eus_user_id
FROM T_Sample_Prep_Request AS SPR
     INNER JOIN T_Sample_Prep_Request_State_Name SN
       ON SPR.State = SN.State_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_RNA_Prep_Request_Entry] TO [DDL_Viewer] AS [dbo]
GO
