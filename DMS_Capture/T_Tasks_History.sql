/****** Object:  Table [dbo].[T_Tasks_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Tasks_History](
	[Job] [int] NOT NULL,
	[Priority] [int] NULL,
	[Script] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[State] [int] NOT NULL,
	[Dataset] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_ID] [int] NULL,
	[Results_Folder_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Imported] [datetime] NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Saved] [datetime] NOT NULL,
	[Most_Recent_Entry] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Tasks_History] PRIMARY KEY NONCLUSTERED 
(
	[Job] ASC,
	[Saved] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Tasks_History] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Tasks_History_Job] ******/
CREATE CLUSTERED INDEX [IX_T_Tasks_History_Job] ON [dbo].[T_Tasks_History]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Tasks_History_Dataset] ******/
CREATE NONCLUSTERED INDEX [IX_T_Tasks_History_Dataset] ON [dbo].[T_Tasks_History]
(
	[Dataset] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Tasks_History_Newest_Entry_Include_Job_Script_DS] ******/
CREATE NONCLUSTERED INDEX [IX_T_Tasks_History_Newest_Entry_Include_Job_Script_DS] ON [dbo].[T_Tasks_History]
(
	[Most_Recent_Entry] ASC
)
INCLUDE([Job],[Script],[Dataset]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Tasks_History_ScripT_Task] ******/
CREATE NONCLUSTERED INDEX [IX_T_Tasks_History_ScripT_Task] ON [dbo].[T_Tasks_History]
(
	[Script] ASC
)
INCLUDE([Job]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Tasks_History_State_include_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_Tasks_History_State_include_Job] ON [dbo].[T_Tasks_History]
(
	[State] ASC
)
INCLUDE([Job]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Tasks_History] ADD  CONSTRAINT [DF_T_Tasks_History_Most_Recent_Entry]  DEFAULT ((0)) FOR [Most_Recent_Entry]
GO
/****** Object:  Trigger [dbo].[trig_d_T_Tasks_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER trig_d_T_Tasks_History ON dbo.T_Tasks_History
For Delete
/****************************************************
**
**	Desc:
**		Updates column MostRecentEntry for the affected jobs
**
**	Auth:	mem
**	Date:	01/25/2011 mem - Initial version
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	UPDATE T_Tasks_History
	SET Most_Recent_Entry = CASE WHEN SaveRank = 1 THEN 1 ELSE 0 END
	FROM ( SELECT Job,
	              Saved,
	              Row_Number() OVER ( PARTITION BY Job ORDER BY Saved DESC ) AS SaveRank
	       FROM T_Tasks_History
	       WHERE Job IN (SELECT Job FROM deleted)
	     ) LookupQ
	     INNER JOIN T_Tasks_History Target
	       ON LookupQ.Job = Target.Job AND
	          LookupQ.Saved = Target.Saved

GO
ALTER TABLE [dbo].[T_Tasks_History] ENABLE TRIGGER [trig_d_T_Tasks_History]
GO
/****** Object:  Trigger [dbo].[trig_iu_T_Tasks_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER trig_iu_T_Tasks_History ON dbo.T_Tasks_History
For Insert, Update
/****************************************************
**
**	Desc:
**		Updates column MostRecentEntry for the affected jobs
**
**	Auth:	mem
**	Date:	01/25/2011 mem - Initial version
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(Saved)
	Begin
		UPDATE T_Tasks_History
		SET Most_Recent_Entry = CASE WHEN SaveRank = 1 THEN 1 ELSE 0 END
		FROM ( SELECT Job,
		              Saved,
		              Row_Number() OVER ( PARTITION BY Job ORDER BY Saved DESC ) AS SaveRank
		       FROM T_Tasks_History
		       WHERE Job IN (SELECT Job FROM inserted)
		     ) LookupQ
		     INNER JOIN T_Tasks_History Target
		       ON LookupQ.Job = Target.Job AND
		          LookupQ.Saved = Target.Saved

	End

GO
ALTER TABLE [dbo].[T_Tasks_History] ENABLE TRIGGER [trig_iu_T_Tasks_History]
GO
