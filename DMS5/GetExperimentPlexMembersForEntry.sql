/****** Object:  UserDefinedFunction [dbo].[GetExperimentPlexMembersForEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetExperimentPlexMembersForEntry]
/****************************************************
**
**	Desc:   Builds delimited list of experiment plex members for a given experiment plex
**
**	Auth:	mem
**	Date:	11/09/2018 mem
**    
*****************************************************/
(
	@plexExperimentID int
)
RETURNS varchar(4000)
AS
	BEGIN
		Declare @list varchar(4000) = 'Channel or Tag, Exp_ID, Channel Type, Comment'
		
		SELECT @list = @list + Char(10) + PlexMemberInfo
        FROM ( SELECT PlexMembers.Channel,
                      IsNull(ReporterIons.Tag_Name, Cast(PlexMembers.Channel AS varchar(12))) + ', ' + 
                      Cast(PlexMembers.Exp_ID AS varchar(12)) + ', ' + 
                      ChannelType.Channel_Type_Name + ', ' + 
                      IsNull(PlexMembers.[Comment], '') AS PlexMemberInfo
               FROM T_Experiment_Plex_Members PlexMembers
                    INNER JOIN dbo.T_Experiments ChannelExperiment
                      ON PlexMembers.Exp_ID = ChannelExperiment.Exp_ID
                    INNER JOIN dbo.T_Experiment_Plex_Channel_Type_Name ChannelType
                      ON PlexMembers.Channel_Type_ID = ChannelType.Channel_Type_ID
                    INNER JOIN dbo.T_Experiments E
                      ON PlexMembers.Plex_Exp_ID = E.Exp_ID
                    LEFT OUTER JOIN dbo.T_Sample_Labelling_Reporter_Ions ReporterIons
                      ON PlexMembers.Channel = ReporterIons.Channel AND
                         E.EX_Labelling = ReporterIons.Label
               WHERE PlexMembers.Plex_Exp_ID = @plexExperimentID ) LookupQ
        ORDER BY LookupQ.Channel

		If ISNULL(@list,'') = '' 
			Set @list = ''

		RETURN @list
	END


GO
