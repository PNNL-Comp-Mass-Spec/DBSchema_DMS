/****** Object:  Table [dbo].[T_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job](
	[AJ_jobID] [int] NOT NULL,
	[AJ_batchID] [int] NULL,
	[AJ_priority] [int] NOT NULL,
	[AJ_created] [datetime] NOT NULL,
	[AJ_start] [datetime] NULL,
	[AJ_finish] [datetime] NULL,
	[AJ_analysisToolID] [int] NOT NULL,
	[AJ_parmFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJ_settingsFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJ_organismDBName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJ_organismID] [int] NOT NULL,
	[AJ_datasetID] [int] NOT NULL,
	[AJ_comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJ_owner] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJ_StateID] [int] NOT NULL,
	[AJ_Last_Affected] [datetime] NOT NULL,
	[AJ_assignedProcessorName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJ_resultsFolderName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJ_proteinCollectionList] [varchar](2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJ_proteinOptionsList] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJ_requestID] [int] NOT NULL,
	[AJ_extractionProcessor] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJ_extractionStart] [datetime] NULL,
	[AJ_extractionFinish] [datetime] NULL,
	[AJ_Analysis_Manager_Error] [smallint] NOT NULL,
	[AJ_Data_Extraction_Error] [smallint] NOT NULL,
	[AJ_propagationMode] [smallint] NOT NULL,
	[AJ_StateNameCached] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJ_ProcessingTimeMinutes] [real] NULL,
	[AJ_specialProcessing] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJ_DatasetUnreviewed] [tinyint] NOT NULL,
 CONSTRAINT [T_Analysis_Job_PK] PRIMARY KEY CLUSTERED 
(
	[AJ_jobID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Analysis_Job_AJ_created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_created] ON [dbo].[T_Analysis_Job] 
(
	[AJ_created] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_AJ_datasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_datasetID] ON [dbo].[T_Analysis_Job] 
(
	[AJ_datasetID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_AJ_finish] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_finish] ON [dbo].[T_Analysis_Job] 
(
	[AJ_finish] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_AJ_Last_Affected] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_Last_Affected] ON [dbo].[T_Analysis_Job] 
(
	[AJ_Last_Affected] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_AJ_StateID_AJ_JobID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_StateID_AJ_JobID] ON [dbo].[T_Analysis_Job] 
(
	[AJ_StateID] ASC,
	[AJ_jobID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_AJ_StateNameCached] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_StateNameCached] ON [dbo].[T_Analysis_Job] 
(
	[AJ_StateNameCached] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_DatasetID_JobID_StateID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_DatasetID_JobID_StateID] ON [dbo].[T_Analysis_Job] 
(
	[AJ_datasetID] ASC,
	[AJ_jobID] ASC,
	[AJ_StateID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_OrganismDBName] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_OrganismDBName] ON [dbo].[T_Analysis_Job] 
(
	[AJ_organismDBName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_RequestID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_RequestID] ON [dbo].[T_Analysis_Job] 
(
	[AJ_requestID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_StateID_include_JobPriorityToolDataset] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_StateID_include_JobPriorityToolDataset] ON [dbo].[T_Analysis_Job] 
(
	[AJ_StateID] ASC
)
INCLUDE ( [AJ_priority],
[AJ_jobID],
[AJ_datasetID],
[AJ_analysisToolID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_ToolID_include_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_ToolID_include_DatasetID] ON [dbo].[T_Analysis_Job] 
(
	[AJ_analysisToolID] ASC
)
INCLUDE ( [AJ_datasetID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_ToolID_JobID_DatasetID_include_AJStart] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_ToolID_JobID_DatasetID_include_AJStart] ON [dbo].[T_Analysis_Job] 
(
	[AJ_analysisToolID] ASC,
	[AJ_jobID] ASC,
	[AJ_datasetID] ASC
)
INCLUDE ( [AJ_start]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_ToolID_JobID_OrganismID_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_ToolID_JobID_OrganismID_DatasetID] ON [dbo].[T_Analysis_Job] 
(
	[AJ_analysisToolID] ASC,
	[AJ_jobID] ASC,
	[AJ_organismID] ASC,
	[AJ_datasetID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_ToolID_JobID_StateName_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_ToolID_JobID_StateName_DatasetID] ON [dbo].[T_Analysis_Job] 
(
	[AJ_analysisToolID] ASC,
	[AJ_jobID] ASC,
	[AJ_StateNameCached] ASC,
	[AJ_datasetID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Trigger [dbo].[trig_d_AnalysisJob] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create Trigger [dbo].[trig_d_AnalysisJob] on [dbo].[T_Analysis_Job]
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the deleted analysis job
**
**	Auth:	grk
**	Date:	01/01/2003
**			08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**			10/02/2007 mem - Updated to append the analysis tool name and 
**							 dataset name for the deleted job to the Entered_By field (Ticket #543)
**			10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Event_Log for each job deleted from T_Analysis_Job
	INSERT INTO T_Event_Log
		(
			Target_Type, 
			Target_ID, 
			Target_State, 
			Prev_Target_State, 
			Entered,
			Entered_By
		)
	SELECT 5 AS Target_Type,
	       deleted.AJ_JobID AS Target_ID,
	       0 AS Target_State,
	       deleted.AJ_StateID AS Prev_Target_State,
	       GETDATE(),
           suser_sname() + '; ' + ISNULL(AnalysisTool.AJT_toolName, 'Unknown Tool') + ' on '
                                + ISNULL(DS.Dataset_Num, 'Unknown Dataset')
	FROM deleted
	     LEFT OUTER JOIN dbo.T_Dataset DS
	       ON deleted.AJ_datasetID = DS.Dataset_ID
	     LEFT OUTER JOIN dbo.T_Analysis_Tool AnalysisTool
	       ON deleted.AJ_analysisToolID = AnalysisTool.AJT_toolID
	ORDER BY deleted.AJ_JobID

GO

/****** Object:  Trigger [dbo].[trig_i_AnalysisJob] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create Trigger [dbo].[trig_i_AnalysisJob] on [dbo].[T_Analysis_Job]
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the new analysis job
**
**	Auth:	grk
**	Date:	01/01/2003
**			08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**			10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**			12/12/2007 mem - Now updating AJ_StateNameCached (Ticket #585)
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 5, inserted.AJ_jobID, inserted.AJ_StateID, 0, GetDate()
	FROM inserted
	ORDER BY inserted.AJ_jobID

	UPDATE T_Analysis_Job
	SET AJ_StateNameCached = IsNull(AJDAS.Job_State, '')
	FROM T_Analysis_Job AJ INNER JOIN
		 inserted ON AJ.AJ_jobID = inserted.AJ_jobID INNER JOIN
		 V_Analysis_Job_and_Dataset_Archive_State AJDAS ON AJ.AJ_jobID = AJDAS.Job

GO

/****** Object:  Trigger [dbo].[trig_u_AnalysisJob] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create Trigger [dbo].[trig_u_AnalysisJob] on [dbo].[T_Analysis_Job]
For Update
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the updated analysis job
**
**	Auth:	grk
**	Date:	01/01/2003
**			05/16/2007 mem - Now updating DS_Last_Affected when DS_State_ID changes (Ticket #478)
**			08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**			11/01/2007 mem - Added Set NoCount statement (Ticket #569)
**			12/12/2007 mem - Now updating AJ_StateNameCached (Ticket #585)
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(AJ_StateID)
	Begin
		INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
		SELECT 5, inserted.AJ_jobID, inserted.AJ_StateID, deleted.AJ_StateID, GetDate()
		FROM deleted INNER JOIN inserted ON deleted.AJ_jobID = inserted.AJ_jobID
		ORDER BY inserted.AJ_jobID

		UPDATE T_Analysis_Job
		SET AJ_Last_Affected = GetDate(), 
			AJ_StateNameCached = IsNull(AJDAS.Job_State, '')
		FROM T_Analysis_Job AJ INNER JOIN
			 inserted ON AJ.AJ_jobID = inserted.AJ_jobID INNER JOIN
			 V_Analysis_Job_and_Dataset_Archive_State AJDAS ON AJ.AJ_jobID = AJDAS.Job

	End

GO
/****** Object:  Trigger [dbo].[trig_ud_T_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_ud_T_Analysis_Job]ON [dbo].[T_Analysis_Job]FOR UPDATE, DELETE AS/********************************************************	Desc: **		Prevents updating or deleting all rows in the table****	Auth:	mem**	Date:	02/08/2011*******************************************************/BEGIN    DECLARE @Count int    SET @Count = @@ROWCOUNT;    IF @Count >= (	SELECT i.rowcnt AS TableRowCount                     FROM dbo.sysobjects o INNER JOIN dbo.sysindexes i ON o.id = i.id                     WHERE o.name = 'T_Analysis_Job' AND o.type = 'u' AND i.indid < 2                 )    BEGIN        RAISERROR('Cannot update or delete all rows. Use a WHERE clause (see trigger trig_ud_T_Analysis_Job)',16,1)        ROLLBACK TRANSACTION        RETURN;    ENDEND
GO
GRANT SELECT ON [dbo].[T_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Job_Batches] FOREIGN KEY([AJ_batchID])
REFERENCES [T_Analysis_Job_Batches] ([Batch_ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Job_Batches]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Job_Request] FOREIGN KEY([AJ_requestID])
REFERENCES [T_Analysis_Job_Request] ([AJR_requestID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Job_Request]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Analysis_State_Name] FOREIGN KEY([AJ_StateID])
REFERENCES [T_Analysis_State_Name] ([AJS_stateID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Analysis_State_Name]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Tool] FOREIGN KEY([AJ_analysisToolID])
REFERENCES [T_Analysis_Tool] ([AJT_toolID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Tool]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Dataset] FOREIGN KEY([AJ_datasetID])
REFERENCES [T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Dataset]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Organisms] FOREIGN KEY([AJ_organismID])
REFERENCES [T_Organisms] ([Organism_ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Organisms]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_priority]  DEFAULT ((2)) FOR [AJ_priority]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_analysisToolID]  DEFAULT ((0)) FOR [AJ_analysisToolID]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_comment]  DEFAULT ('') FOR [AJ_comment]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_StateID]  DEFAULT ((1)) FOR [AJ_StateID]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_Last_Affected]  DEFAULT (getdate()) FOR [AJ_Last_Affected]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_proteinCollectionList]  DEFAULT ('na') FOR [AJ_proteinCollectionList]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_proteinOptionsList]  DEFAULT ('na') FOR [AJ_proteinOptionsList]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_requestID]  DEFAULT ((1)) FOR [AJ_requestID]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_Analysis_Manager_Error]  DEFAULT ((0)) FOR [AJ_Analysis_Manager_Error]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_Data_Extraction_Error]  DEFAULT ((0)) FOR [AJ_Data_Extraction_Error]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_propogation_mode]  DEFAULT ((0)) FOR [AJ_propagationMode]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_StateNameCached]  DEFAULT ('') FOR [AJ_StateNameCached]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_DatasetUnreviewed]  DEFAULT ((0)) FOR [AJ_DatasetUnreviewed]
GO
