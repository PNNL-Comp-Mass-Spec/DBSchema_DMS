/****** Object:  Table [dbo].[T_Dataset_Archive] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Archive](
	[AS_Dataset_ID] [int] NOT NULL,
	[AS_state_ID] [int] NOT NULL,
	[AS_state_Last_Affected] [datetime] NULL CONSTRAINT [DF_T_Dataset_Archive_AS_state_Last_Affected]  DEFAULT (getdate()),
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
 CONSTRAINT [PK_T_Dataset_Archive] PRIMARY KEY CLUSTERED 
(
	[AS_Dataset_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Dataset_Archive_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Archive_State] ON [dbo].[T_Dataset_Archive] 
(
	[AS_state_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Trigger [trig_d_Dataset_Archive] ******/
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

/****** Object:  Trigger [trig_i_Dataset_Archive] ******/
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


GO

/****** Object:  Trigger [trig_u_Dataset_Archive] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_Dataset_Archive] on [dbo].[T_Dataset_Archive]
For Update
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the updated dataset archive task
**
**	Auth:	grk
**	Date:	01/01/2003
**			08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**			09/04/2007 mem - Now updating AS_state_Last_Affected when the state changes (Ticket #527)
**			10/31/2007 mem - Updated to track changes to AS_update_state_ID (Ticket #569)
**						   - Updated to make entries in T_Event_Log only if the state actually changes (Ticket #569)
**			12/12/2007 mem - Now updating AJ_StateNameCached in T_Analysis_Job (Ticket #585)
**			08/04/2008 mem - Now updating AS_instrument_data_purged if AS_state_ID changes for 4 (Ticket #683)
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
		INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
		SELECT 6, inserted.AS_Dataset_ID, inserted.AS_state_ID, deleted.AS_state_ID, @CurrentDate
		FROM deleted INNER JOIN inserted ON deleted.AS_Dataset_ID = inserted.AS_Dataset_ID
		WHERE inserted.AS_state_ID <> deleted.AS_state_ID
		ORDER BY inserted.AS_Dataset_ID

		UPDATE T_Dataset_Archive
		SET AS_state_Last_Affected = @CurrentDate
		FROM T_Dataset_Archive DA INNER JOIN
			 inserted ON DA.AS_Dataset_ID = inserted.AS_Dataset_ID

		UPDATE T_Dataset_Archive
		SET AS_instrument_data_purged = 1
		FROM T_Dataset_Archive DA INNER JOIN
			 inserted ON DA.AS_Dataset_ID = inserted.AS_Dataset_ID
		WHERE inserted.AS_state_ID = 4 AND IsNull(inserted.AS_instrument_data_purged, 0) = 0
	End

	If Update(AS_update_state_ID)
	Begin
		INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
		SELECT 7, inserted.AS_Dataset_ID, inserted.AS_update_state_ID, deleted.AS_update_state_ID, @CurrentDate
		FROM deleted INNER JOIN inserted ON deleted.AS_Dataset_ID = inserted.AS_Dataset_ID
		WHERE inserted.AS_update_state_ID <> deleted.AS_update_state_ID
		ORDER BY inserted.AS_Dataset_ID

		UPDATE T_Dataset_Archive
		SET AS_update_state_Last_Affected = @CurrentDate
		FROM T_Dataset_Archive DA INNER JOIN
			 inserted ON DA.AS_Dataset_ID = inserted.AS_Dataset_ID
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

GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Path] FOREIGN KEY([AS_storage_path_ID])
REFERENCES [T_Archive_Path] ([AP_path_ID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Path]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Update_State_Name] FOREIGN KEY([AS_update_state_ID])
REFERENCES [T_Archive_Update_State_Name] ([AUS_stateID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Update_State_Name]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_Dataset] FOREIGN KEY([AS_Dataset_ID])
REFERENCES [T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_Dataset]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_DatasetArchiveStateName] FOREIGN KEY([AS_state_ID])
REFERENCES [T_DatasetArchiveStateName] ([DASN_StateID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_DatasetArchiveStateName]
GO
