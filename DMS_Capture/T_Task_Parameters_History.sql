/****** Object:  Table [dbo].[T_Task_Parameters_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Task_Parameters_History](
	[Job] [int] NOT NULL,
	[Parameters] [xml] NULL,
	[Saved] [datetime] NOT NULL,
	[Most_Recent_Entry] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Task_Parameters_History] PRIMARY KEY CLUSTERED 
(
	[Job] ASC,
	[Saved] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Task_Parameters_History] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Task_Parameters_History_MostRecentEntry] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Parameters_History_MostRecentEntry] ON [dbo].[T_Task_Parameters_History]
(
	[Most_Recent_Entry] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Task_Parameters_History] ADD  CONSTRAINT [DF_T_Task_Parameters_History_Saved]  DEFAULT (getdate()) FOR [Saved]
GO
ALTER TABLE [dbo].[T_Task_Parameters_History] ADD  CONSTRAINT [DF_T_Task_Parameters_History_Most_Recent_Entry]  DEFAULT ((0)) FOR [Most_Recent_Entry]
GO
/****** Object:  Trigger [dbo].[trig_d_T_Task_Parameters_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER trig_d_T_Task_Parameters_History on T_Task_Parameters_History
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

	UPDATE T_Task_Parameters_History
	SET Most_Recent_Entry = CASE WHEN SaveRank = 1 THEN 1 ELSE 0 END
	FROM ( SELECT Job,
	              Saved,
	              Row_Number() OVER ( PARTITION BY Job ORDER BY Saved DESC ) AS SaveRank
	       FROM T_Task_Parameters_History
	       WHERE Job IN (SELECT Job FROM deleted)
	     ) LookupQ
	     INNER JOIN T_Task_Parameters_History Target
	       ON LookupQ.Job = Target.Job AND
	          LookupQ.Saved = Target.Saved

GO
ALTER TABLE [dbo].[T_Task_Parameters_History] ENABLE TRIGGER [trig_d_T_Task_Parameters_History]
GO
/****** Object:  Trigger [dbo].[trig_iu_T_Task_Parameters_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER trig_iu_T_Task_Parameters_History on T_Task_Parameters_History
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
		UPDATE T_Task_Parameters_History
		SET Most_Recent_Entry = CASE WHEN SaveRank = 1 THEN 1 ELSE 0 END
		FROM ( SELECT Job,
		              Saved,
		              Row_Number() OVER ( PARTITION BY Job ORDER BY Saved DESC ) AS SaveRank
		       FROM T_Task_Parameters_History
		       WHERE Job IN (SELECT Job FROM inserted)
		     ) LookupQ
		     INNER JOIN T_Task_Parameters_History Target
		       ON LookupQ.Job = Target.Job AND
		          LookupQ.Saved = Target.Saved

	End

GO
ALTER TABLE [dbo].[T_Task_Parameters_History] ENABLE TRIGGER [trig_iu_T_Task_Parameters_History]
GO
