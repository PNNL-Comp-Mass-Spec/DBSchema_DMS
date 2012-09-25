/****** Object:  Table [dbo].[T_Protein_Collections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Protein_Collections](
	[Protein_Collection_ID] [int] IDENTITY(1000,1) NOT NULL,
	[FileName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](900) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Collection_Type_ID] [tinyint] NULL,
	[Collection_State_ID] [tinyint] NULL,
	[Primary_Annotation_Type_ID] [int] NULL,
	[NumProteins] [int] NULL,
	[NumResidues] [int] NULL,
	[DateCreated] [datetime] NULL,
	[DateModified] [datetime] NULL,
	[Authentication_Hash] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Contents_Encrypted] [tinyint] NULL,
	[Uploaded_By] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Collection_RowVersion] [timestamp] NOT NULL,
 CONSTRAINT [PK_T_Protein_Collections] PRIMARY KEY CLUSTERED 
(
	[Protein_Collection_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Protein_Collections_FileName] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Protein_Collections_FileName] ON [dbo].[T_Protein_Collections] 
(
	[FileName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_d_Protein_Collections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Trigger [dbo].[trig_d_Protein_Collections] on [dbo].[T_Protein_Collections]
For Delete
AS
	-- Add entries to T_Event_Log for each job deleted from T_Protein_Collections
	INSERT INTO T_Event_Log
		(
			Target_Type, Target_ID, 
			Target_State, Prev_Target_State, 
			Entered
		)
	SELECT	1 AS Target_Type, Protein_Collection_ID, 
			0 AS Target_State, Collection_State_ID, 
			GETDATE()
	FROM deleted
	ORDER BY Protein_Collection_ID

GO
/****** Object:  Trigger [dbo].[trig_i_Protein_Collections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Trigger [dbo].[trig_i_Protein_Collections] on [dbo].[T_Protein_Collections]
For Insert
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 1, inserted.Protein_Collection_ID, inserted.Collection_State_ID, 0, GetDate()
	FROM inserted

GO
/****** Object:  Trigger [dbo].[trig_u_Protein_Collections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Trigger [dbo].[trig_u_Protein_Collections] on [dbo].[T_Protein_Collections]
For Update
AS
	If @@RowCount = 0
		Return

	if update(Collection_State_ID)
		INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
		SELECT 1, inserted.Protein_Collection_ID, inserted.Collection_State_ID, deleted.Collection_State_ID, GetDate()
		FROM deleted INNER JOIN inserted ON deleted.Protein_Collection_ID = inserted.Protein_Collection_ID

GO
GRANT DELETE ON [dbo].[T_Protein_Collections] TO [d3p214] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Protein_Collections] TO [d3p214] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Protein_Collections] TO [d3p214] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Protein_Collections] TO [d3p214] AS [dbo]
GO
ALTER TABLE [dbo].[T_Protein_Collections]  WITH CHECK ADD  CONSTRAINT [FK_T_Protein_Collections_T_Annotation_Types] FOREIGN KEY([Primary_Annotation_Type_ID])
REFERENCES [T_Annotation_Types] ([Annotation_Type_ID])
GO
ALTER TABLE [dbo].[T_Protein_Collections] CHECK CONSTRAINT [FK_T_Protein_Collections_T_Annotation_Types]
GO
ALTER TABLE [dbo].[T_Protein_Collections]  WITH CHECK ADD  CONSTRAINT [FK_T_Protein_Collections_T_Protein_Collection_States] FOREIGN KEY([Collection_State_ID])
REFERENCES [T_Protein_Collection_States] ([Collection_State_ID])
GO
ALTER TABLE [dbo].[T_Protein_Collections] CHECK CONSTRAINT [FK_T_Protein_Collections_T_Protein_Collection_States]
GO
ALTER TABLE [dbo].[T_Protein_Collections]  WITH CHECK ADD  CONSTRAINT [FK_T_Protein_Collections_T_Protein_Collection_Types] FOREIGN KEY([Collection_Type_ID])
REFERENCES [T_Protein_Collection_Types] ([Collection_Type_ID])
GO
ALTER TABLE [dbo].[T_Protein_Collections] CHECK CONSTRAINT [FK_T_Protein_Collections_T_Protein_Collection_Types]
GO
ALTER TABLE [dbo].[T_Protein_Collections] ADD  CONSTRAINT [DF_T_Protein_Collections_Collection_Type_ID]  DEFAULT ((1)) FOR [Collection_Type_ID]
GO
ALTER TABLE [dbo].[T_Protein_Collections] ADD  CONSTRAINT [DF_T_Protein_Collections_Collection_State_ID]  DEFAULT ((1)) FOR [Collection_State_ID]
GO
ALTER TABLE [dbo].[T_Protein_Collections] ADD  CONSTRAINT [DF_T_Protein_Collections_DateCreated]  DEFAULT (getdate()) FOR [DateCreated]
GO
ALTER TABLE [dbo].[T_Protein_Collections] ADD  CONSTRAINT [DF_T_Protein_Collections_DateModified]  DEFAULT (getdate()) FOR [DateModified]
GO
ALTER TABLE [dbo].[T_Protein_Collections] ADD  CONSTRAINT [DF_T_Protein_Collections_Contents_Encrypted]  DEFAULT (0) FOR [Contents_Encrypted]
GO
ALTER TABLE [dbo].[T_Protein_Collections] ADD  CONSTRAINT [DF_T_Protein_Collections_Uploaded_By]  DEFAULT (suser_sname()) FOR [Uploaded_By]
GO
