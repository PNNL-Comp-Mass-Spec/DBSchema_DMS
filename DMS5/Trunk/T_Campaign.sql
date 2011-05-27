/****** Object:  Table [dbo].[T_Campaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Campaign](
	[Campaign_Num] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CM_Project_Num] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CM_Proj_Mgr_PRN] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_PI_PRN] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_comment] [varchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_created] [datetime] NOT NULL,
	[Campaign_ID] [int] IDENTITY(2100,1) NOT NULL,
	[CM_Technical_Lead] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_State] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CM_Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_External_Links] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_Team_Members] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_EPR_List] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_EUS_Proposal_List] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_Organisms] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_Experiment_Prefixes] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_Research_Team] [int] NULL,
	[CM_Data_Release_Restrictions] [int] NOT NULL,
 CONSTRAINT [PK_T_Campaign] PRIMARY KEY NONCLUSTERED 
(
	[Campaign_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Campaign_Campaign_ID] ******/
CREATE CLUSTERED INDEX [IX_T_Campaign_Campaign_ID] ON [dbo].[T_Campaign] 
(
	[Campaign_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Campaign_Campaign_Num] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Campaign_Campaign_Num] ON [dbo].[T_Campaign] 
(
	[Campaign_Num] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Campaign_CM_created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Campaign_CM_created] ON [dbo].[T_Campaign] 
(
	[CM_created] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Trigger [dbo].[trig_d_Campaign] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_d_Campaign] on [dbo].[T_Campaign]
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the deleted Campaign
**
**	Auth:	mem
**	Date:	10/02/2007 mem - Initial version (Ticket #543)
**			10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Event_Log for each Campaign deleted from T_Campaign
	INSERT INTO T_Event_Log
		(
			Target_Type, 
			Target_ID, 
			Target_State, 
			Prev_Target_State, 
			Entered,
			Entered_By
		)
	SELECT	1 AS Target_Type, 
			Campaign_ID AS Target_ID, 
			0 AS Target_State, 
			1 AS Prev_Target_State, 
			GETDATE(), 
			suser_sname() + '; ' + IsNull(deleted.Campaign_Num, '??')
	FROM deleted
	ORDER BY Campaign_ID

GO

/****** Object:  Trigger [dbo].[trig_i_Campaign] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_i_Campaign] on [dbo].[T_Campaign]
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the new Campaign
**
**	Auth:	mem
**	Date:	10/02/2007 mem - Initial version (Ticket #543)
**			10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 1, inserted.Campaign_ID, 1, 0, GetDate()
	FROM inserted
	ORDER BY inserted.Campaign_ID

GO

/****** Object:  Trigger [dbo].[trig_u_Campaign] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger trig_u_Campaign on T_Campaign
For Update
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Entity_Rename_Log if the campaign is renamed
**
**	Auth:	mem
**	Date:	07/19/2010 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(Campaign_Num)
	Begin
		INSERT INTO T_Entity_Rename_Log (Target_Type, Target_ID, Old_Name, New_Name, Entered)
		SELECT 1, inserted.Campaign_ID, deleted.Campaign_Num, inserted.Campaign_Num, GETDATE()
		FROM deleted INNER JOIN inserted ON deleted.Campaign_ID = inserted.Campaign_ID
		ORDER BY inserted.Campaign_ID
	End

GO
GRANT SELECT ON [dbo].[T_Campaign] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Campaign] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Campaign]  WITH CHECK ADD  CONSTRAINT [FK_T_Campaign_T_Data_Release_Restrictions] FOREIGN KEY([CM_Data_Release_Restrictions])
REFERENCES [T_Data_Release_Restrictions] ([ID])
GO
ALTER TABLE [dbo].[T_Campaign] CHECK CONSTRAINT [FK_T_Campaign_T_Data_Release_Restrictions]
GO
ALTER TABLE [dbo].[T_Campaign]  WITH CHECK ADD  CONSTRAINT [FK_T_Campaign_T_Research_Team] FOREIGN KEY([CM_Research_Team])
REFERENCES [T_Research_Team] ([ID])
GO
ALTER TABLE [dbo].[T_Campaign] CHECK CONSTRAINT [FK_T_Campaign_T_Research_Team]
GO
ALTER TABLE [dbo].[T_Campaign]  WITH CHECK ADD  CONSTRAINT [CK_T_Campaign_CampaignName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([Campaign_Num],(1))=(0)))
GO
ALTER TABLE [dbo].[T_Campaign] CHECK CONSTRAINT [CK_T_Campaign_CampaignName_WhiteSpace]
GO
ALTER TABLE [dbo].[T_Campaign] ADD  CONSTRAINT [DF_T_Campaign_State]  DEFAULT ('Active') FOR [CM_State]
GO
ALTER TABLE [dbo].[T_Campaign] ADD  CONSTRAINT [DF_T_Campaign_CM_Data_Release_Restrictions]  DEFAULT ((0)) FOR [CM_Data_Release_Restrictions]
GO
