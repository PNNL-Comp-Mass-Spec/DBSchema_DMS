/****** Object:  View [dbo].[V_Instrument_Group_PickList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Group_PickList] As
SELECT Instrument_Group,
       Usage,
       Instruments,
       Comment,
       Allowed_Dataset_Types,
       Sample_Prep_Visible,
       Requested_Run_Visible,
       CASE WHEN Instruments = '' 
       THEN Instrument_Group + ' (no active instruments)' 
       ELSE Instrument_Group + ' (' + Instruments + ')' 
       END As Instrument_Group_and_Instruments
From (  SELECT I.IN_Group AS Instrument_Group,
               I.Usage,
               dbo.GetInstrumentGroupMembershipList(I.IN_Group, 1, 64) AS Instruments,
               I.Comment,
               dbo.GetInstrumentGroupDatasetTypeList(I.IN_Group, ', ') AS Allowed_Dataset_Types,
               I.Sample_Prep_Visible,
               I.Requested_Run_Visible
        FROM dbo.T_Instrument_Group I
             LEFT OUTER JOIN dbo.T_DatasetTypeName DT
               ON I.Default_Dataset_Type = DT.DST_Type_ID
        WHERE I.Active > 0
    ) LookupQ

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Group_PickList] TO [DDL_Viewer] AS [dbo]
GO
