/****** Object:  Table [dbo].[T_Dataset_Archive] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Archive](
	[AS_Dataset_ID] [int] NOT NULL,
	[AS_state_ID] [int] NOT NULL,
	[AS_storage_path_ID] [int] NOT NULL,
	[AS_datetime] [datetime] NULL,
	[AS_last_update] [datetime] NULL,
	[AS_last_verify] [datetime] NULL,
	[AS_update_state_ID] [int] NULL,
	[AS_purge_holdoff_date] [datetime] NULL,
 CONSTRAINT [PK_T_Dataset_Archive] PRIMARY KEY CLUSTERED 
(
	[AS_Dataset_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Dataset_Archive_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Archive_State] ON [dbo].[T_Dataset_Archive] 
(
	[AS_state_ID] ASC
) ON [PRIMARY]
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
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 6, inserted.AS_Dataset_ID, inserted.AS_state_ID, 0, GetDate()
	FROM inserted
	ORDER BY inserted.AS_Dataset_ID

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
**	Desc: 
**		Makes an entry in T_Event_Log for the updated dataset archive task
**
**	Auth:	grk
**	Date:	01/01/2003
**			08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	If Update(AS_state_ID)
	Begin
		INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
		SELECT 6, inserted.AS_Dataset_ID, inserted.AS_state_ID, deleted.AS_state_ID, GetDate()
		FROM deleted INNER JOIN inserted ON deleted.AS_Dataset_ID = inserted.AS_Dataset_ID
		ORDER BY inserted.AS_Dataset_ID
	End

GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Path] FOREIGN KEY([AS_storage_path_ID])
REFERENCES [T_Archive_Path] ([AP_path_ID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Path]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Update_State_Name] FOREIGN KEY([AS_update_state_ID])
REFERENCES [T_Archive_Update_State_Name] ([AUS_stateID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_Archive_Update_State_Name]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_Dataset] FOREIGN KEY([AS_Dataset_ID])
REFERENCES [T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_Dataset]
GO
ALTER TABLE [dbo].[T_Dataset_Archive]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Archive_T_DatasetArchiveStateName] FOREIGN KEY([AS_state_ID])
REFERENCES [T_DatasetArchiveStateName] ([DASN_StateID])
GO
ALTER TABLE [dbo].[T_Dataset_Archive] CHECK CONSTRAINT [FK_T_Dataset_Archive_T_DatasetArchiveStateName]
GO
