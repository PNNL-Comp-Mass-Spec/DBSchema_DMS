/****** Object:  View [dbo].[V_Experiment_Plex_Members_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Experiment_Plex_Members_Entry]
As
Select ExpIDPivotQ.Plex_Exp_ID As Exp_ID,
       E.Experiment_Num AS Experiment,
       dbo.GetExperimentPlexMembersForEntry(ExpIDPivotQ.Plex_Exp_ID) As Plex_Members,
       ExpIDPivotQ.Channel1_ExpID, 
       ExpIDPivotQ.Channel2_ExpID, 
       ExpIDPivotQ.Channel3_ExpID, 
       ExpIDPivotQ.Channel4_ExpID, 
       ExpIDPivotQ.Channel5_ExpID, 
       ExpIDPivotQ.Channel6_ExpID, 
       ExpIDPivotQ.Channel7_ExpID, 
       ExpIDPivotQ.Channel8_ExpID, 
       ExpIDPivotQ.Channel9_ExpID, 
       ExpIDPivotQ.Channel10_ExpID, 
       ExpIDPivotQ.Channel11_ExpID,
       ChannelTypePivotQ.Channel1_Type, 
       ChannelTypePivotQ.Channel2_Type, 
       ChannelTypePivotQ.Channel3_Type, 
       ChannelTypePivotQ.Channel4_Type, 
       ChannelTypePivotQ.Channel5_Type, 
       ChannelTypePivotQ.Channel6_Type, 
       ChannelTypePivotQ.Channel7_Type, 
       ChannelTypePivotQ.Channel8_Type, 
       ChannelTypePivotQ.Channel9_Type,
       ChannelTypePivotQ.Channel10_Type,
       ChannelTypePivotQ.Channel11_Type
From (
       SELECT Plex_Exp_ID,
              [1] As Channel1_ExpID, 
              [2] As Channel2_ExpID, 
              [3] As Channel3_ExpID, 
              [4] As Channel4_ExpID, 
              [5] As Channel5_ExpID, 
              [6] As Channel6_ExpID, 
              [7] As Channel7_ExpID, 
              [8] As Channel8_ExpID, 
              [9] As Channel9_ExpID, 
              [10] As Channel10_ExpID, 
              [11] As Channel11_ExpID
       FROM  ( SELECT Plex_Exp_ID,
                   Channel,
                   Exp_ID
            FROM T_Experiment_Plex_Members) AS SourceTable
            PIVOT ( Max(Exp_ID)
                    FOR Channel
                    IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12] ) ) AS PivotData
    ) ExpIDPivotQ
    Inner Join T_Experiments E On ExpIDPivotQ.Plex_Exp_ID = E.Exp_ID
    Inner JOIN
    (
       SELECT Plex_Exp_ID,
              [1] As Channel1_Type, 
              [2] As Channel2_Type, 
              [3] As Channel3_Type, 
              [4] As Channel4_Type, 
              [5] As Channel5_Type, 
              [6] As Channel6_Type, 
              [7] As Channel7_Type, 
              [8] As Channel8_Type, 
              [9] As Channel9_Type, 
              [10] As Channel10_Type, 
              [11] As Channel11_Type
       FROM  ( SELECT PM.Plex_Exp_ID,
                   PM.Channel,
                   ChannelTypeName.Channel_Type_Name
            FROM T_Experiment_Plex_Members PM
                 Inner Join T_Experiment_Plex_Channel_Type_Name ChannelTypeName 
                   On PM.Channel_Type_ID = ChannelTypeName.Channel_Type_ID
               ) AS SourceTable
            PIVOT ( Max(Channel_Type_Name)
                    FOR Channel
                    IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12] ) ) AS PivotData
    ) ChannelTypePivotQ 
       On ExpIDPivotQ.Plex_Exp_ID = ChannelTypePivotQ.Plex_Exp_ID


GO
