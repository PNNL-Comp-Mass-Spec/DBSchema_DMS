/****** Object:  Table [dbo].[T_Job_Parameters_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Job_Parameters_History](
	[Job] [int] NOT NULL,
	[Parameters] [xml] NULL,
	[Saved] [datetime] NOT NULL,
	[Most_Recent_Entry] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Job_Parameters_History] PRIMARY KEY CLUSTERED 
(
	[Job] ASC,
	[Saved] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Job_Parameters_History_MostRecentEntry] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Parameters_History_MostRecentEntry] ON [dbo].[T_Job_Parameters_History] 
(
	[Most_Recent_Entry] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_d_T_Job_Parameters_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_d_T_Job_Parameters_History] on [dbo].[T_Job_Parameters_History]
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

	UPDATE T_Job_Parameters_History
	SET Most_Recent_Entry = CASE WHEN SaveRank = 1 THEN 1 ELSE 0 END
	FROM ( SELECT Job,
	              Saved,
	              Row_Number() OVER ( PARTITION BY Job ORDER BY Saved DESC ) AS SaveRank
	       FROM T_Job_Parameters_History
	       WHERE Job IN (SELECT Job FROM deleted)
	     ) LookupQ
	     INNER JOIN T_Job_Parameters_History Target
	       ON LookupQ.Job = Target.Job AND
	          LookupQ.Saved = Target.Saved

GO
/****** Object:  Trigger [dbo].[trig_iu_T_Job_Parameters_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_iu_T_Job_Parameters_History] on [dbo].[T_Job_Parameters_History]
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
		UPDATE T_Job_Parameters_History
		SET Most_Recent_Entry = CASE WHEN SaveRank = 1 THEN 1 ELSE 0 END
		FROM ( SELECT Job,
		              Saved,
		              Row_Number() OVER ( PARTITION BY Job ORDER BY Saved DESC ) AS SaveRank
		       FROM T_Job_Parameters_History
		       WHERE Job IN (SELECT Job FROM inserted)
		     ) LookupQ
		     INNER JOIN T_Job_Parameters_History Target
		       ON LookupQ.Job = Target.Job AND
		          LookupQ.Saved = Target.Saved

	End

GO
ALTER TABLE [dbo].[T_Job_Parameters_History] ADD  CONSTRAINT [DF_T_Job_Parameters_History_Saved]  DEFAULT (getdate()) FOR [Saved]
GO
ALTER TABLE [dbo].[T_Job_Parameters_History] ADD  CONSTRAINT [DF_T_Job_Parameters_History_Most_Recent_Entry]  DEFAULT ((0)) FOR [Most_Recent_Entry]
GO
