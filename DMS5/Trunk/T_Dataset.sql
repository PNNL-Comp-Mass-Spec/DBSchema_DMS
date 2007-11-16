/****** Object:  Table [dbo].[T_Dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset](
	[Dataset_Num] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DS_Oper_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DS_comment] [varchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DS_created] [datetime] NOT NULL,
	[DS_instrument_name_ID] [int] NULL,
	[DS_LC_column_ID] [int] NULL CONSTRAINT [DF_T_Dataset_DS_LC_column_ID]  DEFAULT (0),
	[DS_type_ID] [int] NULL,
	[DS_wellplate_num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Dataset_DS_wellplate_num]  DEFAULT ('na'),
	[DS_well_num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DS_sec_sep] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DS_state_ID] [int] NOT NULL CONSTRAINT [DF_T_Dataset_DS_state_ID]  DEFAULT (1),
	[DS_Last_Affected] [datetime] NOT NULL CONSTRAINT [DF_T_Dataset_DS_Last_Affected]  DEFAULT (getdate()),
	[DS_folder_name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DS_storage_path_ID] [int] NULL,
	[Exp_ID] [int] NOT NULL,
	[Dataset_ID] [int] IDENTITY(9000,1) NOT NULL,
	[DS_internal_standard_ID] [int] NULL CONSTRAINT [DF_T_Dataset_DS_internal_standard_ID]  DEFAULT (0),
	[DS_rating] [smallint] NOT NULL CONSTRAINT [DF_T_Dataset_DS_rating]  DEFAULT (2),
	[DS_Comp_State] [smallint] NULL,
	[DS_Compress_Date] [datetime] NULL,
	[DS_PrepServerName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Dataset_DS_PrepServerName]  DEFAULT ('na'),
	[Acq_Time_Start] [datetime] NULL,
	[Acq_Time_End] [datetime] NULL,
	[Scan_Count] [int] NULL,
	[File_Size_Bytes] [bigint] NULL,
	[File_Info_Last_Modified] [datetime] NULL,
 CONSTRAINT [PK_T_Dataset] PRIMARY KEY NONCLUSTERED 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Dataset_Created] ******/
CREATE CLUSTERED INDEX [IX_T_Dataset_Created] ON [dbo].[T_Dataset] 
(
	[DS_created] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Dataset_Acq_Time_Start] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Acq_Time_Start] ON [dbo].[T_Dataset] 
(
	[Acq_Time_Start] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Dataset_Dataset_ID_Exp_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Dataset_ID_Exp_ID] ON [dbo].[T_Dataset] 
(
	[Dataset_ID] ASC,
	[Exp_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Dataset_Dataset_Num] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Dataset_Dataset_Num] ON [dbo].[T_Dataset] 
(
	[Dataset_Num] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Dataset_Exp_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Exp_ID] ON [dbo].[T_Dataset] 
(
	[Exp_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Dataset_State_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_State_ID] ON [dbo].[T_Dataset] 
(
	[DS_state_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Trigger [dbo].[trig_d_Dataset] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_d_Dataset] on [dbo].[T_Dataset]
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the deleted dataset
**
**	Auth:	grk
**	Date:	01/01/2003
**			08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**			10/02/2007 mem - Updated to append the dataset name to the Entered_By field (Ticket #543)
**			10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Event_Log for each dataset deleted from T_Dataset
	INSERT INTO T_Event_Log
		(
			Target_Type, 
			Target_ID, 
			Target_State, 
			Prev_Target_State, 
			Entered,
			Entered_By
		)
	SELECT	4 AS Target_Type, 
			Dataset_ID AS Target_ID, 
			0 AS Target_State, 
			DS_State_ID AS Prev_Target_State, 
			GETDATE(), 
			suser_sname() + '; ' + IsNull(deleted.Dataset_Num, '??')
	FROM deleted
	ORDER BY Dataset_ID

GO

/****** Object:  Trigger [dbo].[trig_i_Dataset] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_i_Dataset] on [dbo].[T_Dataset]
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the new dataset
**
**	Auth:	grk
**	Date:	01/01/2003
**			08/15/2007 mem - Updated to use an Insert query and to make an entry for DS_Rating (Ticket #519)
**			10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 4, inserted.Dataset_ID, inserted.DS_State_ID, 0, GetDate()
	FROM inserted
	ORDER BY inserted.Dataset_ID

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 8, inserted.Dataset_ID, inserted.DS_Rating, 0, GetDate()
	FROM inserted
	ORDER BY inserted.Dataset_ID

GO

/****** Object:  Trigger [dbo].[trig_u_Dataset] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_Dataset] on [dbo].[T_Dataset]
For Update
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the updated dataset
**
**	Auth:	grk
**	Date:	01/01/2003
**			05/16/2007 mem - Now updating DS_Last_Affected when DS_State_ID changes (Ticket #478)
**			08/15/2007 mem - Updated to use an Insert query and to make an entry if DS_Rating is changed (Ticket #519)
**			11/01/2007 mem - Updated to make entries in T_Event_Log only if the state actually changes (Ticket #569)
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(DS_State_ID)
	Begin
		INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
		SELECT 4, inserted.Dataset_ID, inserted.DS_State_ID, deleted.DS_State_ID, GetDate()
		FROM deleted INNER JOIN inserted ON deleted.Dataset_ID = inserted.Dataset_ID
		ORDER BY inserted.Dataset_ID

		UPDATE T_Dataset
		Set DS_Last_Affected = GetDate()
		WHERE Dataset_ID IN (SELECT Dataset_ID FROM inserted)
	End

	If Update(DS_Rating)
	Begin
		INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
		SELECT 8, inserted.Dataset_ID, inserted.DS_Rating, deleted.DS_Rating, GetDate()
		FROM deleted INNER JOIN inserted ON deleted.Dataset_ID = inserted.Dataset_ID
		WHERE inserted.DS_Rating <> deleted.DS_Rating
		ORDER BY inserted.Dataset_ID
	End

GO
GRANT SELECT ON [dbo].[T_Dataset] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_T_DatasetRatingName] FOREIGN KEY([DS_rating])
REFERENCES [T_DatasetRatingName] ([DRN_state_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_DatasetRatingName]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_T_DatasetStateName] FOREIGN KEY([DS_state_ID])
REFERENCES [T_DatasetStateName] ([Dataset_state_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_DatasetStateName]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_T_DatasetTypeName] FOREIGN KEY([DS_type_ID])
REFERENCES [T_DatasetTypeName] ([DST_Type_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_DatasetTypeName]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_T_Experiments] FOREIGN KEY([Exp_ID])
REFERENCES [T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_Experiments]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_T_Instrument_Name] FOREIGN KEY([DS_instrument_name_ID])
REFERENCES [T_Instrument_Name] ([Instrument_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_Instrument_Name]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_T_Internal_Standards] FOREIGN KEY([DS_internal_standard_ID])
REFERENCES [T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_Internal_Standards]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_T_LC_Column] FOREIGN KEY([DS_LC_column_ID])
REFERENCES [T_LC_Column] ([ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_LC_Column]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_T_Secondary_Sep] FOREIGN KEY([DS_sec_sep])
REFERENCES [T_Secondary_Sep] ([SS_name])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_Secondary_Sep]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_t_storage_path] FOREIGN KEY([DS_storage_path_ID])
REFERENCES [t_storage_path] ([SP_path_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_t_storage_path]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Dataset_T_Users] FOREIGN KEY([DS_Oper_PRN])
REFERENCES [T_Users] ([U_PRN])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_Users]
GO
