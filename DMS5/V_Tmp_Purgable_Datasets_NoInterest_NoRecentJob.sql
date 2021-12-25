/****** Object:  View [dbo].[V_Tmp_Purgable_Datasets_NoInterest_NoRecentJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Tmp_Purgable_Datasets_NoInterest_NoRecentJob]
AS
SELECT Dataset_ID,
       StorageServerName,
       ServerVol,
       Created,
       raw_data_type,
       StageMD5_Required,
       MostRecentJob,
       Purge_Priority,
       Archive_State_ID
FROM V_Tmp_Purgable_Datasets_NoInterest
WHERE MostRecentJob < DateAdd(day, -60, GetDate())

GO
