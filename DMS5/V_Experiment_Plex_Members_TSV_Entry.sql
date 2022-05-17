/****** Object:  View [dbo].[V_Experiment_Plex_Members_TSV_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Plex_Members_TSV_Entry]
As
SELECT ExpIDPivotQ.Plex_Exp_ID As exp_id,
       E.Experiment_Num As experiment,
       ExpIDPivotQ.channel1_expid AS channel1_exp_id,
       ExpIDPivotQ.channel2_expid AS channel2_exp_id,
       ExpIDPivotQ.channel3_expid AS channel3_exp_id,
       ExpIDPivotQ.channel4_expid AS channel4_exp_id,
       ExpIDPivotQ.channel5_expid AS channel5_exp_id,
       ExpIDPivotQ.channel6_expid AS channel6_exp_id,
       ExpIDPivotQ.channel7_expid AS channel7_exp_id,
       ExpIDPivotQ.channel8_expid AS channel8_exp_id,
       ExpIDPivotQ.channel9_expid AS channel9_exp_id,
       ExpIDPivotQ.channel10_expid AS channel10_exp_id,
       ExpIDPivotQ.channel11_expid AS channel11_exp_id,
       ExpIDPivotQ.channel12_expid AS channel12_exp_id,
       ExpIDPivotQ.channel13_expid AS channel13_exp_id,
       ExpIDPivotQ.channel14_expid AS channel14_exp_id,
       ExpIDPivotQ.channel15_expid AS channel15_exp_id,
       ExpIDPivotQ.channel16_expid AS channel16_exp_id,
       ExpIDPivotQ.channel17_expid AS channel17_exp_id,
       ExpIDPivotQ.channel18_expid AS channel18_exp_id,
       ChannelTypePivotQ.channel1_type,
       ChannelTypePivotQ.channel2_type,
       ChannelTypePivotQ.channel3_type,
       ChannelTypePivotQ.channel4_type,
       ChannelTypePivotQ.channel5_type,
       ChannelTypePivotQ.channel6_type,
       ChannelTypePivotQ.channel7_type,
       ChannelTypePivotQ.channel8_type,
       ChannelTypePivotQ.channel9_type,
       ChannelTypePivotQ.channel10_type,
       ChannelTypePivotQ.channel11_type,
       ChannelTypePivotQ.channel12_type,
       ChannelTypePivotQ.channel13_type,
       ChannelTypePivotQ.channel14_type,
       ChannelTypePivotQ.channel15_type,
       ChannelTypePivotQ.channel16_type,
       ChannelTypePivotQ.channel17_type,
       ChannelTypePivotQ.channel18_type,
       CommentPivotQ.channel1_comment,
       CommentPivotQ.channel2_comment,
       CommentPivotQ.channel3_comment,
       CommentPivotQ.channel4_comment,
       CommentPivotQ.channel5_comment,
       CommentPivotQ.channel6_comment,
       CommentPivotQ.channel7_comment,
       CommentPivotQ.channel8_comment,
       CommentPivotQ.channel9_comment,
       CommentPivotQ.channel10_comment,
       CommentPivotQ.channel11_comment,
       CommentPivotQ.channel12_comment,
       CommentPivotQ.channel13_comment,
       CommentPivotQ.channel14_comment,
       CommentPivotQ.channel15_comment,
       CommentPivotQ.channel16_comment,
       CommentPivotQ.channel17_comment,
       CommentPivotQ.channel18_comment
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
              [11] As Channel11_ExpID,
              [12] As Channel12_ExpID,
              [13] As Channel13_ExpID,
              [14] As Channel14_ExpID,
              [15] As Channel15_ExpID,
              [16] As Channel16_ExpID,
              [17] As Channel17_ExpID,
              [18] As Channel18_ExpID
       FROM  ( SELECT PlexMembers.Plex_Exp_ID,
                      PlexMembers.Channel,
                      Cast(PlexMembers.Exp_ID As varchar(12)) + ': ' + E.Experiment_Num As ChannelExperiment
            FROM T_Experiment_Plex_Members PlexMembers
                 INNER JOIN T_Experiments E
                   On PlexMembers.Exp_ID = E.Exp_ID) AS SourceTable
            PIVOT ( Max(ChannelExperiment)
                    FOR Channel
                    IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18] ) ) AS PivotData
    ) ExpIDPivotQ
    INNER JOIN T_Experiments E
      On ExpIDPivotQ.Plex_Exp_ID = E.Exp_ID
    INNER JOIN
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
              [11] As Channel11_Type,
              [12] As Channel12_Type,
              [13] As Channel13_Type,
              [14] As Channel14_Type,
              [15] As Channel15_Type,
              [16] As Channel16_Type,
              [17] As Channel17_Type,
              [18] As Channel18_Type
       FROM  ( SELECT PM.Plex_Exp_ID,
                   PM.Channel,
                   ChannelTypeName.Channel_Type_Name
            FROM T_Experiment_Plex_Members PM
                 INNER JOIN T_Experiment_Plex_Channel_Type_Name ChannelTypeName
                   On PM.Channel_Type_ID = ChannelTypeName.Channel_Type_ID
               ) AS SourceTable
            PIVOT ( Max(Channel_Type_Name)
                    FOR Channel
                    IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18] ) ) AS PivotData
    ) ChannelTypePivotQ
       On ExpIDPivotQ.Plex_Exp_ID = ChannelTypePivotQ.Plex_Exp_ID
    INNER JOIN
    (
       SELECT Plex_Exp_ID,
              [1] As Channel1_Comment,
              [2] As Channel2_Comment,
              [3] As Channel3_Comment,
              [4] As Channel4_Comment,
              [5] As Channel5_Comment,
              [6] As Channel6_Comment,
              [7] As Channel7_Comment,
              [8] As Channel8_Comment,
              [9] As Channel9_Comment,
              [10] As Channel10_Comment,
              [11] As Channel11_Comment,
              [12] As Channel12_Comment,
              [13] As Channel13_Comment,
              [14] As Channel14_Comment,
              [15] As Channel15_Comment,
              [16] As Channel16_Comment,
              [17] As Channel17_Comment,
              [18] As Channel18_Comment
       FROM  ( SELECT PM.Plex_Exp_ID,
                   PM.Channel,
                   PM.Comment
            FROM T_Experiment_Plex_Members PM
               ) AS SourceTable
            PIVOT ( Max(Comment)
                    FOR Channel
                    IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18] ) ) AS PivotData
    ) CommentPivotQ
       On ExpIDPivotQ.Plex_Exp_ID = CommentPivotQ.Plex_Exp_ID


GO
