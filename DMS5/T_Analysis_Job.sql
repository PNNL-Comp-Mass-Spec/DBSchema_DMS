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
	[AJ_settingsFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJ_organismDBName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
	[AJ_Purged] [tinyint] NOT NULL,
	[AJ_MyEMSLState] [tinyint] NOT NULL,
	[AJ_RowVersion] [timestamp] NOT NULL,
	[AJ_ToolNameCached] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Progress] [real] NULL,
	[ETA_Minutes] [real] NULL,
 CONSTRAINT [T_Analysis_Job_PK] PRIMARY KEY CLUSTERED 
(
	[AJ_jobID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Analysis_Job] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
/****** Object:  Index [IX_T_Analysis_Job_AJ_datasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_datasetID] ON [dbo].[T_Analysis_Job]
(
	[AJ_datasetID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_AJ_finish] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_finish] ON [dbo].[T_Analysis_Job]
(
	[AJ_finish] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_AJ_Last_Affected] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_Last_Affected] ON [dbo].[T_Analysis_Job]
(
	[AJ_Last_Affected] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_AJ_StateID_AJ_JobID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_StateID_AJ_JobID] ON [dbo].[T_Analysis_Job]
(
	[AJ_StateID] ASC,
	[AJ_jobID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Analysis_Job_AJ_StateNameCached] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_StateNameCached] ON [dbo].[T_Analysis_Job]
(
	[AJ_StateNameCached] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Analysis_Job_AJ_ToolNameCached] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_AJ_ToolNameCached] ON [dbo].[T_Analysis_Job]
(
	[AJ_ToolNameCached] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_BatchID_include_JobID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_BatchID_include_JobID] ON [dbo].[T_Analysis_Job]
(
	[AJ_batchID] ASC
)
INCLUDE([AJ_jobID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_Created_include_Job_StateID_Progress] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Created_include_Job_StateID_Progress] ON [dbo].[T_Analysis_Job]
(
	[AJ_created] ASC
)
INCLUDE([AJ_jobID],[AJ_StateID],[Progress]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_DatasetID_JobID_StateID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_DatasetID_JobID_StateID] ON [dbo].[T_Analysis_Job]
(
	[AJ_datasetID] ASC,
	[AJ_jobID] ASC,
	[AJ_StateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Analysis_Job_OrganismDBName] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_OrganismDBName] ON [dbo].[T_Analysis_Job]
(
	[AJ_organismDBName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Analysis_Job_Param_File_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Param_File_Name] ON [dbo].[T_Analysis_Job]
(
	[AJ_parmFileName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_RequestID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_RequestID] ON [dbo].[T_Analysis_Job]
(
	[AJ_requestID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Analysis_Job_Settings_File_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Settings_File_Name] ON [dbo].[T_Analysis_Job]
(
	[AJ_settingsFileName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_Started_include_Job_StateID_Progress] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Started_include_Job_StateID_Progress] ON [dbo].[T_Analysis_Job]
(
	[AJ_start] ASC
)
INCLUDE([AJ_jobID],[AJ_StateID],[Progress]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_StateID_include_JobPriorityToolDataset] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_StateID_include_JobPriorityToolDataset] ON [dbo].[T_Analysis_Job]
(
	[AJ_StateID] ASC
)
INCLUDE([AJ_priority],[AJ_jobID],[AJ_datasetID],[AJ_analysisToolID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_ToolID_include_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_ToolID_include_DatasetID] ON [dbo].[T_Analysis_Job]
(
	[AJ_analysisToolID] ASC
)
INCLUDE([AJ_datasetID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_ToolID_include_ParmFile_Created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_ToolID_include_ParmFile_Created] ON [dbo].[T_Analysis_Job]
(
	[AJ_analysisToolID] ASC
)
INCLUDE([AJ_parmFileName],[AJ_created]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_ToolID_JobID_DatasetID_include_AJStart] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_ToolID_JobID_DatasetID_include_AJStart] ON [dbo].[T_Analysis_Job]
(
	[AJ_analysisToolID] ASC,
	[AJ_jobID] ASC,
	[AJ_datasetID] ASC
)
INCLUDE([AJ_start]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Analysis_Job_ToolID_StateID_include_Job_Priority_DatasetID_Comment_Owner_SpecialProcessing] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_ToolID_StateID_include_Job_Priority_DatasetID_Comment_Owner_SpecialProcessing] ON [dbo].[T_Analysis_Job]
(
	[AJ_analysisToolID] ASC,
	[AJ_StateID] ASC
)
INCLUDE([AJ_jobID],[AJ_priority],[AJ_datasetID],[AJ_comment],[AJ_owner],[AJ_specialProcessing]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_priority]  DEFAULT ((2)) FOR [AJ_priority]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_Created]  DEFAULT (getdate()) FOR [AJ_created]
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
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_Purged]  DEFAULT ((0)) FOR [AJ_Purged]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_MyEMSLState]  DEFAULT ((0)) FOR [AJ_MyEMSLState]
GO
ALTER TABLE [dbo].[T_Analysis_Job] ADD  CONSTRAINT [DF_T_Analysis_Job_AJ_ToolNameCached]  DEFAULT ('') FOR [AJ_ToolNameCached]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Job_Batches] FOREIGN KEY([AJ_batchID])
REFERENCES [dbo].[T_Analysis_Job_Batches] ([Batch_ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Job_Batches]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Job_Request] FOREIGN KEY([AJ_requestID])
REFERENCES [dbo].[T_Analysis_Job_Request] ([AJR_requestID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Job_Request]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Analysis_State_Name] FOREIGN KEY([AJ_StateID])
REFERENCES [dbo].[T_Analysis_State_Name] ([AJS_stateID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Analysis_State_Name]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Tool] FOREIGN KEY([AJ_analysisToolID])
REFERENCES [dbo].[T_Analysis_Tool] ([AJT_toolID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Analysis_Tool]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Dataset] FOREIGN KEY([AJ_datasetID])
REFERENCES [dbo].[T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Dataset]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_MyEMSLState] FOREIGN KEY([AJ_MyEMSLState])
REFERENCES [dbo].[T_MyEMSLState] ([MyEMSLState])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_MyEMSLState]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Organisms] FOREIGN KEY([AJ_organismID])
REFERENCES [dbo].[T_Organisms] ([Organism_ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Organisms]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_Param_Files] FOREIGN KEY([AJ_parmFileName])
REFERENCES [dbo].[T_Param_Files] ([Param_File_Name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_Param_Files]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_T_YesNo] FOREIGN KEY([AJ_DatasetUnreviewed])
REFERENCES [dbo].[T_YesNo] ([Flag])
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [FK_T_Analysis_Job_T_YesNo]
GO
ALTER TABLE [dbo].[T_Analysis_Job]  WITH CHECK ADD  CONSTRAINT [CK_T_Analysis_Job_PropagationMode] CHECK  (([AJ_propagationMode]=(1) OR [AJ_propagationMode]=(0)))
GO
ALTER TABLE [dbo].[T_Analysis_Job] CHECK CONSTRAINT [CK_T_Analysis_Job_PropagationMode]
GO
/****** Object:  Trigger [dbo].[trig_d_AnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_d_AnalysisJob] ON [dbo].[T_Analysis_Job]
FOR DELETE
/****************************************************
**
**	Desc:
**		Makes an entry in T_Event_Log for the deleted analysis job
**
**	Auth:	grk
**	Date:	01/01/2003
**			08/15/2007 mem - Update to use an Insert query (Ticket #519)
**			10/02/2007 mem - Update to append the analysis tool name and dataset name for the deleted job to the Entered_By field (Ticket #543)
**			10/31/2007 mem - Add Set NoCount statement (Ticket #569)
**			11/25/2013 mem - Update DeconTools_Job_for_QC in T_Dataset
**          05/08/2024 mem - Set Update_Required to 1 in T_Cached_Dataset_Stats
**
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Event_Log for each job deleted from T_Analysis_Job
	INSERT INTO T_Event_Log (Target_Type,
	                         Target_ID,
	                         Target_State,
	                         Prev_Target_State,
	                         Entered,
	                         Entered_By)
	SELECT 5 AS Target_Type,
	       deleted.AJ_JobID AS Target_ID,
	       0 AS Target_State,
	       deleted.AJ_StateID AS Prev_Target_State,
	       GETDATE(),
	       suser_sname() + '; ' + IsNull(AnalysisTool.AJT_toolName, 'Unknown Tool') + ' on ' + IsNull(DS.Dataset_Num, 'Unknown Dataset')
	FROM deleted
	     LEFT OUTER JOIN dbo.T_Dataset DS
	       ON deleted.AJ_DatasetID = DS.Dataset_ID
	     LEFT OUTER JOIN dbo.T_Analysis_Tool AnalysisTool
	       ON deleted.AJ_analysisToolID = AnalysisTool.AJT_toolID
	ORDER BY deleted.AJ_JobID

	UPDATE target
	SET DeconTools_Job_for_QC = Job
	FROM T_Dataset target
	     LEFT OUTER JOIN ( SELECT Dataset_ID,
	                              J.AJ_JobID AS Job,
	                              Row_number() OVER ( PARTITION BY J.AJ_DatasetID ORDER BY J.AJ_jobID DESC ) AS JobRank
	                       FROM T_Dataset DS
	                            LEFT OUTER JOIN T_Analysis_Tool Tool
	                                            INNER JOIN T_Analysis_Job J
	                                              ON Tool.AJT_toolID = J.AJ_analysisToolID AND
	                                                 Tool.AJT_toolBasename = 'Decon2LS'
	                              ON J.AJ_DatasetID = DS.Dataset_ID AND
	                                 NOT J.AJ_jobID IN ( SELECT AJ_jobID
	                                                     FROM deleted )
	                       WHERE DS.Dataset_ID IN ( SELECT AJ_DatasetID
	                                                FROM deleted ) AND
	                             J.AJ_StateID IN (2, 4) ) SourceQ
	       ON target.Dataset_ID = SourceQ.Dataset_ID AND
	          SourceQ.JobRank = 1
	WHERE target.Dataset_ID IN ( SELECT AJ_DatasetID
	                             FROM deleted ) AND
	      IsNull(target.DeconTools_Job_for_QC, 0) <> IsNull(SourceQ.Job, - 1)

    -- Set Update_Required to 1 for datasets associated with the deleted job(s)
    UPDATE T_Cached_Dataset_Stats
    SET Update_Required = 1, Last_Affected = GetDate()
    WHERE Dataset_ID IN (SELECT AJ_DatasetID FROM deleted)

GO
ALTER TABLE [dbo].[T_Analysis_Job] ENABLE TRIGGER [trig_d_AnalysisJob]
GO
/****** Object:  Trigger [dbo].[trig_i_AnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_i_AnalysisJob] ON [dbo].[T_Analysis_Job]
FOR INSERT
/****************************************************
**
**	Desc:
**		Makes an entry in T_Event_Log for the new analysis job
**
**	Auth:	grk
**	Date:	01/01/2003
**			08/15/2007 mem - Update to use an Insert query (Ticket #519)
**			10/31/2007 mem - Add Set NoCount statement (Ticket #569)
**			12/12/2007 mem - Update AJ_StateNameCached (Ticket #585)
**			04/03/2014 mem - Update AJ_ToolNameCached
**          05/08/2024 mem - Set Update_Required to 1 in T_Cached_Dataset_Stats
**
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Event_Log (Target_Type,
	                         Target_ID,
	                         Target_State,
	                         Prev_Target_State,
	                         Entered)
	SELECT 5,
	       inserted.AJ_jobID,
	       inserted.AJ_StateID,
	       0,
	       GetDate()
	FROM inserted
	ORDER BY inserted.AJ_jobID

	UPDATE T_Analysis_Job
	SET AJ_StateNameCached = IsNull(AJDAS.Job_State, ''),
	    AJ_ToolNameCached = IsNull(ATool.AJT_toolName, '')
	FROM T_Analysis_Job AJ
	     INNER JOIN inserted
	       ON AJ.AJ_jobID = inserted.AJ_jobID
	     INNER JOIN V_Analysis_Job_and_Dataset_Archive_State AJDAS
	       ON AJ.AJ_jobID = AJDAS.Job
	     INNER JOIN T_Analysis_Tool ATool
	       ON AJ.AJ_analysisToolID = ATool.AJT_toolID

    UPDATE T_Cached_Dataset_Stats
    SET Update_Required = 1, Last_Affected = GetDate()
    WHERE Dataset_ID IN (SELECT AJ_DatasetID FROM inserted)

GO
ALTER TABLE [dbo].[T_Analysis_Job] ENABLE TRIGGER [trig_i_AnalysisJob]
GO
/****** Object:  Trigger [dbo].[trig_iu_AnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_iu_AnalysisJob] ON [dbo].[T_Analysis_Job]
FOR INSERT, UPDATE
/****************************************************
**
**	Desc:
**		Validates that the settings file name is valid
**		Note: this procedure does not perform a tool-specific validation; it simply checks for a valid file name
**
**	Auth:	mem
**			01/24/2013 mem - Initial version
**			11/25/2013 mem - Update DeconTools_Job_for_QC in T_Dataset
**			12/02/2013 mem - Refactor logic for updating DeconTools_Job_for_QC to use multiple small queries instead of one large Update query
**
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(AJ_settingsFileName)
	Begin
		Declare @InvalidSettingsFile varchar(128) = ''

		SELECT TOP 1 @InvalidSettingsFile = inserted.AJ_settingsFileName
		FROM inserted
			 LEFT OUTER JOIN T_Settings_Files SF
			   ON inserted.AJ_settingsFileName = SF.File_Name
		WHERE (SF.File_Name IS NULL)

		If IsNull(@InvalidSettingsFile, '') <> ''
		Begin
			Declare @message varchar(256) = 'Invalid settings file: ' + @InvalidSettingsFile + ' (see trigger trig_iu_AnalysisJob)'
			RAISERROR(@message,16,1)
			ROLLBACK TRANSACTION
			RETURN;
		End
	End

	If Update(AJ_StateID)
	Begin
		Declare @BestJobByDataset Table (Dataset_ID int, Job int)

		INSERT INTO @BestJobByDataset (Dataset_ID, Job)
		SELECT SourceQ.Dataset_ID, Job
		FROM ( SELECT DS.Dataset_ID,
					  J.AJ_jobID AS Job,
					  Row_number() OVER ( PARTITION BY J.AJ_DatasetID ORDER BY J.AJ_jobID DESC ) AS JobRank
			   FROM T_Dataset DS
					INNER JOIN T_Analysis_Job J
					  ON J.AJ_DatasetID = DS.Dataset_ID
					INNER JOIN T_Analysis_Tool Tool
					  ON Tool.AJT_toolID = J.AJ_analysisToolID AND
						 Tool.AJT_toolBasename = 'Decon2LS'
			   WHERE J.AJ_DatasetID IN ( SELECT AJ_DatasetID FROM inserted ) AND
					 J.AJ_StateID IN (2, 4)
		     ) SourceQ
		WHERE SourceQ.JobRank = 1

		UPDATE target
		SET DeconTools_Job_for_QC = SourceQ.Job
		FROM T_Dataset Target
			 INNER JOIN @BestJobByDataset SourceQ
			   ON Target.Dataset_ID = SourceQ.Dataset_ID
		WHERE IsNull(target.DeconTools_Job_for_QC, 0) <> IsNull(SourceQ.Job, -1)
	End

GO
ALTER TABLE [dbo].[T_Analysis_Job] ENABLE TRIGGER [trig_iu_AnalysisJob]
GO
/****** Object:  Trigger [dbo].[trig_u_AnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_u_AnalysisJob] ON [dbo].[T_Analysis_Job]
FOR UPDATE
/****************************************************
**
**  Desc:
**      Makes an entry in T_Event_Log for the updated analysis job
**      Updates AJ_Last_Affected, AJ_StateNameCached, Progress, ETA_Minutes, and AJ_ToolNameCached in T_Analysis_Job
**
**  Auth:   grk
**   Date:  01/01/2003
**          05/16/2007 mem - Update DS_Last_Affected when DS_State_ID changes (Ticket #478)
**          08/15/2007 mem - Update to use an Insert query (Ticket #519)
**          11/01/2007 mem - Add Set NoCount statement (Ticket #569)
**          12/12/2007 mem - Update AJ_StateNameCached (Ticket #585)
**          04/03/2014 mem - Update AJ_ToolNameCached
**          09/01/2016 mem - Update Progress and ETA_Minutes
**          10/30/2017 mem - Set progress to 0 for inactive jobs (state 13)
**                         - Fix StateID bug, switching from 17 to 14
**          09/13/2018 mem - When Started and Finished are non-null, use the larger of Started and Finished for Last_Affected
**          05/08/2024 mem - Set Update_Required to 1 in T_Cached_Dataset_Stats
**
*****************************************************/
AS
    If @@RowCount = 0
        Return

    Set NoCount On

    If Update(AJ_StateID)
    Begin
        INSERT INTO T_Event_Log (Target_Type,
                                 Target_ID,
                                 Target_State,
                                 Prev_Target_State,
                                 Entered)
        SELECT 5,
               inserted.AJ_jobID,
               inserted.AJ_StateID,
               deleted.AJ_StateID,
               GetDate()
        FROM deleted
             INNER JOIN inserted
               ON deleted.AJ_jobID = inserted.AJ_jobID
        ORDER BY inserted.AJ_jobID

        UPDATE T_Analysis_Job
        SET AJ_Last_Affected = CASE WHEN NOT inserted.AJ_finish Is Null AND inserted.AJ_finish >= inserted.AJ_start THEN inserted.AJ_finish
                                    WHEN NOT inserted.AJ_start Is Null  AND inserted.AJ_start >= inserted.AJ_finish THEN inserted.AJ_start
                                    ELSE GetDate()
                               END,
            AJ_StateNameCached = IsNull(AJDAS.Job_State, ''),
            Progress = CASE
                           WHEN inserted.AJ_StateID = 5 THEN -1
                           WHEN inserted.AJ_StateID IN (1, 8, 13, 19) THEN 0
                           WHEN inserted.AJ_StateID IN (4, 7, 14) THEN 100
                           ELSE inserted.Progress
                       END,
            ETA_Minutes = CASE
                              WHEN inserted.AJ_StateID IN (1, 5, 8, 13, 19) THEN NULL
                              WHEN inserted.AJ_StateID IN (4, 7, 14) THEN 0
                              ELSE inserted.ETA_Minutes
                          END
        FROM T_Analysis_Job AJ
             INNER JOIN inserted
               ON AJ.AJ_jobID = inserted.AJ_jobID
             INNER JOIN V_Analysis_Job_and_Dataset_Archive_State AJDAS
               ON AJ.AJ_jobID = AJDAS.Job
    End

    If Update(AJ_analysisToolID)
    Begin
        UPDATE T_Analysis_Job
        SET AJ_ToolNameCached = IsNull(ATool.AJT_toolName, '')
        FROM T_Analysis_Job AJ
             INNER JOIN inserted
               ON AJ.AJ_jobID = inserted.AJ_jobID
             INNER JOIN T_Analysis_Tool ATool
               ON AJ.AJ_analysisToolID = ATool.AJT_toolID
    End

    If Update(AJ_DatasetID)
    Begin
        UPDATE T_Cached_Dataset_Stats
        SET Update_Required = 1, Last_Affected = GetDate()
        WHERE Dataset_ID IN (SELECT AJ_DatasetID FROM inserted UNION SELECT AJ_DatasetID FROM deleted)
    End

GO
ALTER TABLE [dbo].[T_Analysis_Job] ENABLE TRIGGER [trig_u_AnalysisJob]
GO
/****** Object:  Trigger [dbo].[trig_ud_T_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_ud_T_Analysis_Job] ON [dbo].[T_Analysis_Job]
FOR UPDATE, DELETE
/****************************************************
**
**	Desc:
**		Prevents updating or deleting all rows in the table
**
**	Auth:	mem
**	Date:	02/08/2011
**			09/11/2015 mem - Add support for the table being empty
**
*****************************************************/
AS
    DECLARE @Count int
    SET @Count = @@ROWCOUNT;

	DECLARE @ExistingRows int=0
	SELECT @ExistingRows = i.rowcnt
    FROM dbo.sysobjects o INNER JOIN dbo.sysindexes i ON o.id = i.id
    WHERE o.name = 'T_Analysis_Job' AND o.type = 'u' AND i.indid < 2

    If @Count > 0 AND @ExistingRows > 1 AND @Count >= @ExistingRows
    Begin
        RAISERROR('Cannot update or delete all rows. Use a WHERE clause (see trigger trig_ud_T_Analysis_Job)',16,1)
        ROLLBACK TRANSACTION
        RETURN;
    End

GO
ALTER TABLE [dbo].[T_Analysis_Job] ENABLE TRIGGER [trig_ud_T_Analysis_Job]
GO
