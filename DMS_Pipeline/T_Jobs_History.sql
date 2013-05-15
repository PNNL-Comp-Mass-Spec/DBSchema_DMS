/****** Object:  Table [dbo].[T_Jobs_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Jobs_History](
	[Job] [int] NOT NULL,
	[Priority] [int] NULL,
	[Script] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[State] [int] NOT NULL,
	[Dataset] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_ID] [int] NULL,
	[Results_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Organism_DB_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Special_Processing] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Imported] [datetime] NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Saved] [datetime] NULL,
	[Most_Recent_Entry] [tinyint] NOT NULL,
	[Transfer_Folder_Path] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Owner] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DataPkgID] [int] NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Jobs_History_Job] ******/
CREATE CLUSTERED INDEX [IX_T_Jobs_History_Job] ON [dbo].[T_Jobs_History] 
(
	[Job] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Jobs_History_DataPkgID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_History_DataPkgID] ON [dbo].[T_Jobs_History] 
(
	[DataPkgID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Jobs_History_Dataset] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_History_Dataset] ON [dbo].[T_Jobs_History] 
(
	[Dataset] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Jobs_History_MostRecentEntry_Include_JobScriptDataset] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_History_MostRecentEntry_Include_JobScriptDataset] ON [dbo].[T_Jobs_History] 
(
	[Most_Recent_Entry] ASC
)
INCLUDE ( [Job],
[Script],
[Dataset]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Jobs_History_Script_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_History_Script_Job] ON [dbo].[T_Jobs_History] 
(
	[Script] ASC
)
INCLUDE ( [Job]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Jobs_History_State_include_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_Jobs_History_State_include_Job] ON [dbo].[T_Jobs_History] 
(
	[State] ASC
)
INCLUDE ( [Job]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_d_T_Jobs_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_d_T_Jobs_History] on [dbo].[T_Jobs_History]
For Delete
/****************************************************
**
**	Desc: 
**		Updates column MostRecentEntry for the affected jobs
**
**	Auth:	mem
**	Date:	01/25/2011
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	UPDATE T_Jobs_History
	SET Most_Recent_Entry = CASE WHEN SaveRank = 1 THEN 1 ELSE 0 END
	FROM ( SELECT Job,
	              Saved,
	              Row_Number() OVER ( PARTITION BY Job ORDER BY Saved DESC ) AS SaveRank
	       FROM T_Jobs_History
	       WHERE Job IN (SELECT Job FROM deleted)
	     ) LookupQ
	     INNER JOIN T_Jobs_History Target
	       ON LookupQ.Job = Target.Job AND
	          LookupQ.Saved = Target.Saved

GO
/****** Object:  Trigger [dbo].[trig_iu_T_Jobs_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_iu_T_Jobs_History] on [dbo].[T_Jobs_History]
For Insert, Update
/****************************************************
**
**	Desc: 
**		Updates column MostRecentEntry for the affected jobs
**
**	Auth:	mem
**	Date:	01/25/2011
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(Saved)
	Begin
		UPDATE T_Jobs_History
		SET Most_Recent_Entry = CASE WHEN SaveRank = 1 THEN 1 ELSE 0 END
		FROM ( SELECT Job,
		              Saved,
		              Row_Number() OVER ( PARTITION BY Job ORDER BY Saved DESC ) AS SaveRank
		       FROM T_Jobs_History
		       WHERE Job IN (SELECT Job FROM inserted)
		     ) LookupQ
		     INNER JOIN T_Jobs_History Target
		       ON LookupQ.Job = Target.Job AND
		          LookupQ.Saved = Target.Saved

	End

GO
ALTER TABLE [dbo].[T_Jobs_History] ADD  CONSTRAINT [DF_T_Jobs_History_Saved]  DEFAULT (getdate()) FOR [Saved]
GO
ALTER TABLE [dbo].[T_Jobs_History] ADD  CONSTRAINT [DF_T_Jobs_History_Most_Recent_Entry]  DEFAULT ((0)) FOR [Most_Recent_Entry]
GO
