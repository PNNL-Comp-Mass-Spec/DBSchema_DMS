/****** Object:  Table [dbo].[T_Dataset_Archive] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Archive](
	[AS_Dataset_ID] [int] NOT NULL,
	[AS_state_ID] [int] NOT NULL,
	[AS_state_Last_Affected] [datetime] NULL,
	[AS_storage_path_ID] [int] NOT NULL,
	[AS_datetime] [datetime] NULL,
	[AS_last_update] [datetime] NULL,
	[AS_last_verify] [datetime] NULL,
	[AS_update_state_ID] [int] NULL,
	[AS_update_state_Last_Affected] [datetime] NULL,
	[AS_purge_holdoff_date] [datetime] NULL,
	[AS_archive_processor] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AS_update_processor] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AS_verification_processor] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AS_instrument_data_purged] [tinyint] NOT NULL,
	[AS_Last_Successful_Archive] [datetime] NULL,
	[AS_StageMD5_Required] [tinyint] NOT NULL,
	[QC_Data_Purged] [tinyint] NOT NULL,
	[Purge_Policy] [tinyint] NOT NULL,
	[Purge_Priority] [tinyint] NOT NULL,
	[MyEMSLState] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Dataset_Archive] PRIMARY KEY CLUSTERED 
(
	[AS_Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Dataset_Archive] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_Dataset_Archive_DatasetID_StateID] ******/
CREATE NONCLUSTERED INDEX [IX_Dataset_Archive_DatasetID_StateID] ON [dbo].[T_Dataset_Archive]
(
	[AS_Dataset_ID] ASC,
	[AS_state_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_Archive_Last_Successful_Archive] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Archive_Last_Successful_Archive] ON [dbo].[T_Dataset_Archive]
(
	[AS_Last_Successful_Archive] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_Archive_StageMD5_Required_include_DatasetID_PurgeHoldoffDate] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Archive_StageMD5_Required_include_DatasetID_PurgeHoldoffDate] ON [dbo].[T_Dataset_Archive]
(
	[AS_StageMD5_Required] ASC
)
INCLUDE ( 	[AS_Dataset_ID],
	[AS_purge_holdoff_date]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_Archive_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Archive_State] ON [dbo].[T_Dataset_Archive]
(
	[AS_state_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_Archive_StateID_UpdateStateID_Include_DatasetID_PurgeHoldoff_StageMD5Required] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Archive_StateID_UpdateStateID_Include_DatasetID_PurgeHoldoff_StageMD5Required] ON [dbo].[T_Dataset_Archive]
(
	[AS_state_ID] ASC,
	[AS_update_state_ID] ASC
)
INCLUDE ( 	[AS_Dataset_ID],
	[AS_purge_holdoff_date],
	[AS_StageMD5_Required]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_Archive_StoragePathID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Archive_StoragePathID] ON [dbo].[T_Dataset_Archive]
(
	[AS_storage_path_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_Archive_UpdateStateID_DatasetID_StateID_Include_PurgeHoldoffDate] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Archive_UpdateStateID_DatasetID_StateID_Include_PurgeHoldoffDate] ON [dbo].[T_Dataset_Archive]
(
	[AS_update_state_ID] ASC,
	[AS_Dataset_ID] ASC,
	[AS_state_ID] ASC
)
INCLUDE ( 	[AS_purge_holdoff_date]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Dataset_Archive] ADD  CONSTRAINT [DF_T_Dataset_Archive_AS_state_Last_Affected]  DEFAULT (getdate()) FOR [AS_state_Last_Affected]
GO
ALTER TABLE [dbo].[T_Dataset_Archive] ADD  CONSTRAINT [DF_T_Dataset_Archive_AS_instrument_data_purged]  DEFAULT ((0)) FOR [AS_instrument_data_purged]
GO
ALTER TABLE [dbo].[T_Dataset_Archive] ADD  CONSTRAINT [DF_T_Dataset_Archive_AS_StageMD5_Required]  DEFAULT ((0)) FOR [AS_StageMD5_Required]
GO
ALTER TABLE [dbo].[T_Dataset_Archive] ADD  CONSTRAINT [DF_T_Dataset_Archive_QC_Data_Purged]  DEFAULT ((0)) FOR [QC_Data_Purged]
GO
ALTER TABLE [dbo].[T_Dataset_Archive] ADD  CONSTRAINT [DF_T_Dataset_Archive_Purge_Policy]  DEFAULT ((0)) FOR [Purge_Policy]
GO
ALTER TABLE [dbo].[T_Dataset_Archive] ADD  CONSTRAINT [DF_T_Dataset_Archive_Purge_Priority]  DEFAULT ((3)) FOR [Purge_Priority]
GO
ALTER TABLE [dbo].[T_Dataset_Archive] ADD  CONSTRAINT [DF_T_Dataset_Archive_MyEMSLState]  DEFAULT ((0)) FOR [MyEMSLState]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Path] FOREIGN KEY([AS_storage_path_ID])
REFERENCES [dbo].[T_Archive_Path] ([AP_path_ID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Path]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Update_State_Name] FOREIGN KEY([AS_update_state_ID])
REFERENCES [dbo].[T_Archive_Update_State_Name] ([AUS_stateID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Update_State_Name]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_Dataset] FOREIGN KEY([AS_Dataset_ID])
REFERENCES [dbo].[T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_Dataset]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_DatasetArchiveStateName] FOREIGN KEY([AS_state_ID])
REFERENCES [dbo].[T_DatasetArchiveStateName] ([DASN_StateID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_DatasetArchiveStateName]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_MyEMSLState] FOREIGN KEY([MyEMSLState])
REFERENCES [dbo].[T_MyEMSLState] ([MyEMSLState])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_MyEMSLState]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_YesNo] FOREIGN KEY([AS_instrument_data_purged])
REFERENCES [dbo].[T_YesNo] ([Flag])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_YesNo]
GO
/****** Object:  Trigger [dbo].[trig_d_Dataset_Archive] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_d_Dataset_Archive] on [dbo].[T_Dataset_Archive]
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the deleted dataset archive entry
**
**	Auth:	mem
**	Date:	10/31/2007
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Event_Log for each entry deleted from T_Dataset_Archive
	INSERT INTO T_Event_Log
		(
			Target_Type, 
			Target_ID, 
			Target_State, 
			Prev_Target_State, 
			Entered,
			Entered_By
		)
	SELECT	6 AS Target_Type, 
			AS_Dataset_ID AS Target_ID, 
			0 AS Target_State, 
			AS_state_ID AS Prev_Target_State, 
			GETDATE(), 
			suser_sname()
	FROM deleted
	ORDER BY AS_Dataset_ID

GO
ALTER TABLE [dbo].[T_Dataset_Archive] ENABLE TRIGGER [trig_d_Dataset_Archive]
GO
/****** Object:  Trigger [dbo].[trig_i_Dataset_Archive] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Trigger [dbo].[trig_i_Dataset_Archive] on [dbo].[T_Dataset_Archive]
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the new dataset archive task
**
**	Auth:	grk
**	Date:	01/01/2003
**			08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**			10/31/2007 mem - Updated to track changes to AS_update_state_ID (Ticket #569)
**			12/12/2007 mem - Now updating AJ_StateNameCached in T_Analysis_Job (Ticket #585)
**			11/14/2013 mem - Now updating T_Cached_Dataset_Folder_Paths
**			07/25/2017 mem - Now updating T_Cached_Dataset_Links
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 6, inserted.AS_Dataset_ID, inserted.AS_state_ID, 0, GetDate()
	FROM inserted
	ORDER BY inserted.AS_Dataset_ID

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 7, inserted.AS_Dataset_ID, inserted.AS_update_state_ID, 0, GetDate()
	FROM inserted
	ORDER BY inserted.AS_Dataset_ID

	UPDATE T_Analysis_Job
	SET AJ_StateNameCached = IsNull(AJDAS.Job_State, '')
	FROM T_Analysis_Job AJ INNER JOIN
		 inserted ON AJ.AJ_datasetID = inserted.AS_Dataset_ID INNER JOIN
		 V_Analysis_Job_and_Dataset_Archive_State AJDAS ON AJ.AJ_jobID = AJDAS.Job

	UPDATE T_Cached_Dataset_Folder_Paths
	SET UpdateRequired = 1
	FROM T_Cached_Dataset_Folder_Paths DFP INNER JOIN
	     inserted ON DFP.Dataset_ID = inserted.AS_Dataset_ID
	
	UPDATE T_Cached_Dataset_Links
	SET UpdateRequired = 1
	FROM T_Cached_Dataset_Links DL INNER JOIN
	     inserted ON DL.Dataset_ID = inserted.AS_Dataset_ID


GO
ALTER TABLE [dbo].[T_Dataset_Archive] ENABLE TRIGGER [trig_i_Dataset_Archive]
GO
/****** Object:  Trigger [dbo].[trig_u_Dataset_Archive] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_Dataset_Archive] on [dbo].[T_Dataset_Archive]
For Update
/****************************************************
**
**  Desc:   Makes an entry in T_Event_Log for the updated dataset archive task
**
**  Auth:   grk
**  Date:   01/01/2003
**          08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**          09/04/2007 mem - Now updating AS_state_Last_Affected when the state changes (Ticket #527)
**          10/31/2007 mem - Updated to track changes to AS_update_state_ID (Ticket #569)
**                         - Updated to make entries in T_Event_Log only if the state actually changes (Ticket #569)
**          12/12/2007 mem - Now updating AJ_StateNameCached in T_Analysis_Job (Ticket #585)
**          08/04/2008 mem - Now updating AS_instrument_data_purged if AS_state_ID changes to 4 (Ticket #683)
**          06/06/2012 mem - Now updating AS_state_Last_Affected and AS_update_state_Last_Affected only if the state actually changes
**          06/11/2012 mem - Now updating QC_Data_Purged to 1 if AS_state_ID changes to 4
**          06/12/2012 mem - Now updating AS_instrument_data_purged if AS_state_ID changes to 4 or 14
**          11/14/2013 mem - Now updating T_Cached_Dataset_Folder_Paths
**          07/25/2017 mem - Now updating T_Cached_Dataset_Links
**    
*****************************************************/
AS
    If @@RowCount = 0
        Return

    Set Nocount On

    Declare @CurrentDate DateTime
    Set @CurrentDate = GetDate()

    If Update(AS_state_ID)
    Begin
        INSERT INTO T_Event_Log    (Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
        SELECT 6, inserted.AS_Dataset_ID, inserted.AS_state_ID, deleted.AS_state_ID, @CurrentDate
        FROM deleted INNER JOIN inserted ON deleted.AS_Dataset_ID = inserted.AS_Dataset_ID
        WHERE inserted.AS_state_ID <> deleted.AS_state_ID
        ORDER BY inserted.AS_Dataset_ID

        UPDATE T_Dataset_Archive
        SET AS_state_Last_Affected = @CurrentDate
        FROM T_Dataset_Archive DA
             INNER JOIN inserted
               ON DA.AS_Dataset_ID = inserted.AS_Dataset_ID
             INNER JOIN deleted
               ON DA.AS_Dataset_ID = deleted.AS_Dataset_ID
        WHERE inserted.AS_state_ID <> deleted.AS_state_ID

        UPDATE T_Dataset_Archive
        SET AS_instrument_data_purged = 1
        FROM T_Dataset_Archive DA INNER JOIN
             inserted ON DA.AS_Dataset_ID = inserted.AS_Dataset_ID
        WHERE inserted.AS_state_ID in (4, 14) AND IsNull(inserted.AS_instrument_data_purged, 0) = 0
        
        UPDATE T_Dataset_Archive
        SET QC_Data_Purged = 1
        FROM T_Dataset_Archive DA INNER JOIN
             inserted ON DA.AS_Dataset_ID = inserted.AS_Dataset_ID
        WHERE inserted.AS_state_ID = 4 AND IsNull(inserted.QC_Data_Purged, 0) = 0
        
    End

    If Update(AS_update_state_ID)
    Begin
        INSERT INTO T_Event_Log    (Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
        SELECT 7, inserted.AS_Dataset_ID, inserted.AS_update_state_ID, deleted.AS_update_state_ID, @CurrentDate
        FROM deleted INNER JOIN inserted ON deleted.AS_Dataset_ID = inserted.AS_Dataset_ID
        WHERE inserted.AS_update_state_ID <> deleted.AS_update_state_ID
        ORDER BY inserted.AS_Dataset_ID

        UPDATE T_Dataset_Archive
        SET AS_update_state_Last_Affected = @CurrentDate
        FROM T_Dataset_Archive DA
             INNER JOIN inserted
               ON DA.AS_Dataset_ID = inserted.AS_Dataset_ID
             INNER JOIN deleted
               ON DA.AS_Dataset_ID = deleted.AS_Dataset_ID
        WHERE inserted.AS_update_state_ID <> deleted.AS_update_state_ID
    End

    If Update(AS_state_ID) OR
       Update(AS_update_state_ID)
    Begin
        UPDATE T_Analysis_Job
        SET AJ_StateNameCached = IsNull(AJDAS.Job_State, '')
        FROM T_Analysis_Job AJ INNER JOIN
             inserted ON AJ.AJ_datasetID = inserted.AS_Dataset_ID INNER JOIN
             V_Analysis_Job_and_Dataset_Archive_State AJDAS ON AJ.AJ_jobID = AJDAS.Job
        WHERE AJ.AJ_StateNameCached <> IsNull(AJDAS.Job_State, '')
    End

    If Update(AS_storage_path_ID)
    Begin
        UPDATE T_Cached_Dataset_Folder_Paths
        SET UpdateRequired = 1
        FROM T_Cached_Dataset_Folder_Paths DFP INNER JOIN
             inserted ON DFP.Dataset_ID = inserted.AS_Dataset_ID        
    End
    
    If Update(AS_state_ID) OR
       Update(AS_storage_path_ID) OR
       Update(AS_instrument_data_purged) OR
       Update(QC_Data_Purged) OR       
       Update(MyEMSLState)
    Begin
        UPDATE T_Cached_Dataset_Links
        SET UpdateRequired = 1
        FROM T_Cached_Dataset_Links DL INNER JOIN
             inserted ON DL.Dataset_ID = inserted.AS_Dataset_ID
    End


GO
ALTER TABLE [dbo].[T_Dataset_Archive] ENABLE TRIGGER [trig_u_Dataset_Archive]
GO
