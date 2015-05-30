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
	[DS_LC_column_ID] [int] NULL,
	[DS_type_ID] [int] NULL,
	[DS_wellplate_num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DS_well_num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DS_sec_sep] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DS_state_ID] [int] NOT NULL,
	[DS_Last_Affected] [datetime] NOT NULL,
	[DS_folder_name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DS_storage_path_ID] [int] NULL,
	[Exp_ID] [int] NOT NULL,
	[Dataset_ID] [int] IDENTITY(9000,1) NOT NULL,
	[DS_internal_standard_ID] [int] NULL,
	[DS_rating] [smallint] NOT NULL,
	[DS_Comp_State] [smallint] NULL,
	[DS_Compress_Date] [datetime] NULL,
	[DS_PrepServerName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Acq_Time_Start] [datetime] NULL,
	[Acq_Time_End] [datetime] NULL,
	[Scan_Count] [int] NULL,
	[File_Size_Bytes] [bigint] NULL,
	[File_Info_Last_Modified] [datetime] NULL,
	[Interval_to_Next_DS] [int] NULL,
	[Acq_Length_Minutes]  AS (isnull(datediff(minute,[Acq_Time_Start],[Acq_Time_End]),(0))) PERSISTED NOT NULL,
	[DateSortKey] [datetime] NOT NULL,
	[DS_RowVersion] [timestamp] NOT NULL,
	[DeconTools_Job_for_QC] [int] NULL,
	[Capture_Subfolder] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Dataset] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_Dataset] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Dataset] TO [Limited_Table_Write] AS [dbo]
GO
/****** Object:  Index [IX_T_Dataset_Acq_Time_Start] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Acq_Time_Start] ON [dbo].[T_Dataset]
(
	[Acq_Time_Start] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_Created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Created] ON [dbo].[T_Dataset]
(
	[DS_created] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Dataset_Dataset_ID_DS_Created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Dataset_ID_DS_Created] ON [dbo].[T_Dataset]
(
	[Dataset_ID] ASC,
	[DS_created] ASC
)
INCLUDE ( 	[Dataset_Num]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_Dataset_ID_Exp_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Dataset_ID_Exp_ID] ON [dbo].[T_Dataset]
(
	[Dataset_ID] ASC,
	[Exp_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Dataset_Dataset_Num] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Dataset_Dataset_Num] ON [dbo].[T_Dataset]
(
	[Dataset_Num] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Dataset_DatasetID_Created_StoragePathID_Include_DatasetNum] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_DatasetID_Created_StoragePathID_Include_DatasetNum] ON [dbo].[T_Dataset]
(
	[Dataset_ID] ASC,
	[DS_created] ASC,
	[DS_storage_path_ID] ASC
)
INCLUDE ( 	[Dataset_Num]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Dataset_DatasetID_include_DatasetNum_InstrumentNameID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_DatasetID_include_DatasetNum_InstrumentNameID] ON [dbo].[T_Dataset]
(
	[Dataset_ID] ASC
)
INCLUDE ( 	[Dataset_Num],
	[DS_instrument_name_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_DatasetID_InstrumentNameID_StoragePathID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_DatasetID_InstrumentNameID_StoragePathID] ON [dbo].[T_Dataset]
(
	[Dataset_ID] ASC,
	[DS_instrument_name_ID] ASC,
	[DS_storage_path_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_DateSortKey] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_DateSortKey] ON [dbo].[T_Dataset]
(
	[DateSortKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_Exp_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Exp_ID] ON [dbo].[T_Dataset]
(
	[Exp_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_ID_Created_ExpID_SPathID_InstrumentNameID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_ID_Created_ExpID_SPathID_InstrumentNameID] ON [dbo].[T_Dataset]
(
	[Dataset_ID] ASC,
	[DS_created] ASC,
	[Exp_ID] ASC,
	[DS_storage_path_ID] ASC,
	[DS_instrument_name_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Dataset_InstNameID_Dataset_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_InstNameID_Dataset_DatasetID] ON [dbo].[T_Dataset]
(
	[DS_instrument_name_ID] ASC,
	[Dataset_Num] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_InstrumentNameID_AcqTimeStart_include_DatasetID_DSRating] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_InstrumentNameID_AcqTimeStart_include_DatasetID_DSRating] ON [dbo].[T_Dataset]
(
	[DS_instrument_name_ID] ASC,
	[Acq_Time_Start] ASC
)
INCLUDE ( 	[Dataset_ID],
	[DS_rating]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_InstrumentNameID_LastAffected_include_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_InstrumentNameID_LastAffected_include_State] ON [dbo].[T_Dataset]
(
	[DS_instrument_name_ID] ASC,
	[DS_Last_Affected] ASC
)
INCLUDE ( 	[DS_state_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_InstrumentNameID_TypeID_include_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_InstrumentNameID_TypeID_include_DatasetID] ON [dbo].[T_Dataset]
(
	[DS_instrument_name_ID] ASC,
	[DS_type_ID] ASC
)
INCLUDE ( 	[Dataset_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_LC_column_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_LC_column_ID] ON [dbo].[T_Dataset]
(
	[DS_LC_column_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_Rating_include_InstrumentID_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Rating_include_InstrumentID_DatasetID] ON [dbo].[T_Dataset]
(
	[DS_rating] ASC
)
INCLUDE ( 	[DS_instrument_name_ID],
	[Dataset_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Dataset_Sec_Sep] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Sec_Sep] ON [dbo].[T_Dataset]
(
	[DS_sec_sep] ASC
)
INCLUDE ( 	[DS_created],
	[Dataset_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_State_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_State_ID] ON [dbo].[T_Dataset]
(
	[DS_state_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_StoragePathID_Created_ExpID_InstrumentNameID_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_StoragePathID_Created_ExpID_InstrumentNameID_DatasetID] ON [dbo].[T_Dataset]
(
	[DS_storage_path_ID] ASC,
	[DS_created] ASC,
	[Exp_ID] ASC,
	[DS_instrument_name_ID] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Dataset_StoragePathID_Created_InstrumentNameID_Rating_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_StoragePathID_Created_InstrumentNameID_Rating_DatasetID] ON [dbo].[T_Dataset]
(
	[DS_storage_path_ID] ASC,
	[DS_created] ASC,
	[DS_instrument_name_ID] ASC,
	[DS_rating] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Dataset] ADD  CONSTRAINT [DF_T_Dataset_DS_LC_column_ID]  DEFAULT (0) FOR [DS_LC_column_ID]
GO
ALTER TABLE [dbo].[T_Dataset] ADD  CONSTRAINT [DF_T_Dataset_DS_wellplate_num]  DEFAULT ('na') FOR [DS_wellplate_num]
GO
ALTER TABLE [dbo].[T_Dataset] ADD  CONSTRAINT [DF_T_Dataset_DS_state_ID]  DEFAULT (1) FOR [DS_state_ID]
GO
ALTER TABLE [dbo].[T_Dataset] ADD  CONSTRAINT [DF_T_Dataset_DS_Last_Affected]  DEFAULT (getdate()) FOR [DS_Last_Affected]
GO
ALTER TABLE [dbo].[T_Dataset] ADD  CONSTRAINT [DF_T_Dataset_DS_internal_standard_ID]  DEFAULT (0) FOR [DS_internal_standard_ID]
GO
ALTER TABLE [dbo].[T_Dataset] ADD  CONSTRAINT [DF_T_Dataset_DS_rating]  DEFAULT (2) FOR [DS_rating]
GO
ALTER TABLE [dbo].[T_Dataset] ADD  CONSTRAINT [DF_T_Dataset_DS_PrepServerName]  DEFAULT ('na') FOR [DS_PrepServerName]
GO
ALTER TABLE [dbo].[T_Dataset] ADD  CONSTRAINT [DF_T_Dataset_DateSortKey]  DEFAULT (getdate()) FOR [DateSortKey]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_T_DatasetRatingName] FOREIGN KEY([DS_rating])
REFERENCES [dbo].[T_DatasetRatingName] ([DRN_state_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_DatasetRatingName]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_T_DatasetStateName] FOREIGN KEY([DS_state_ID])
REFERENCES [dbo].[T_DatasetStateName] ([Dataset_state_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_DatasetStateName]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_T_DatasetTypeName] FOREIGN KEY([DS_type_ID])
REFERENCES [dbo].[T_DatasetTypeName] ([DST_Type_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_DatasetTypeName]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_T_Experiments] FOREIGN KEY([Exp_ID])
REFERENCES [dbo].[T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_Experiments]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_T_Instrument_Name] FOREIGN KEY([DS_instrument_name_ID])
REFERENCES [dbo].[T_Instrument_Name] ([Instrument_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_Instrument_Name]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_T_Internal_Standards] FOREIGN KEY([DS_internal_standard_ID])
REFERENCES [dbo].[T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_Internal_Standards]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_T_LC_Column] FOREIGN KEY([DS_LC_column_ID])
REFERENCES [dbo].[T_LC_Column] ([ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_LC_Column]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_T_Secondary_Sep] FOREIGN KEY([DS_sec_sep])
REFERENCES [dbo].[T_Secondary_Sep] ([SS_name])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_Secondary_Sep]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_t_storage_path] FOREIGN KEY([DS_storage_path_ID])
REFERENCES [dbo].[T_Storage_Path] ([SP_path_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_t_storage_path]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_T_Users] FOREIGN KEY([DS_Oper_PRN])
REFERENCES [dbo].[T_Users] ([U_PRN])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_Users]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [CK_T_Dataset_DatasetName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([Dataset_Num],(0))=(0)))
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [CK_T_Dataset_DatasetName_WhiteSpace]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [CK_T_Dataset_DS_folder_name_Not_Empty] CHECK  ((isnull([DS_folder_name],'')<>''))
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [CK_T_Dataset_DS_folder_name_Not_Empty]
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
**			11/22/2013 mem - Now updating DateSortKey
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

	-- This query must stay sync'd where the Update query in trigger trig_u_Dataset
	UPDATE T_Dataset
	SET DateSortKey = CASE
	                      WHEN E.Experiment_Num = 'Tracking' THEN DS.DS_created
	                      ELSE Isnull(DS.Acq_Time_Start, DS.DS_created)
	                  END
	FROM T_Dataset DS
	     INNER JOIN inserted
	       ON DS.Dataset_ID = INSERTED.Dataset_ID
	     INNER JOIN T_Experiments E
	       ON DS.Exp_ID = E.Exp_ID


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
**			07/19/2010 mem - Now updating T_Entity_Rename_Log if the dataset is renamed
**			11/15/2013 mem - Now updating T_Cached_Dataset_Folder_Paths
**			11/22/2013 mem - Now updating DateSortKey
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

	If Update(Dataset_Num)
	Begin
		INSERT INTO T_Entity_Rename_Log (Target_Type, Target_ID, Old_Name, New_Name, Entered)
		SELECT 4, inserted.Dataset_ID, deleted.Dataset_Num, inserted.Dataset_Num, GETDATE()
		FROM deleted INNER JOIN inserted ON deleted.Dataset_ID = inserted.Dataset_ID
		ORDER BY inserted.Dataset_ID
	End

	If Update(Dataset_Num) OR Update(DS_folder_name)
	Begin
		UPDATE T_Cached_Dataset_Folder_Paths
		SET UpdateRequired = 1
		FROM T_Cached_Dataset_Folder_Paths DFP INNER JOIN
			 inserted ON DFP.Dataset_ID = inserted.Dataset_ID
	End

	If Update(Acq_Time_Start) Or Update(DS_created)
	Begin
		-- This query must stay sync'd where the Update query in trigger trig_i_Dataset
		UPDATE T_Dataset
		SET DateSortKey = CASE
		                      WHEN E.Experiment_Num = 'Tracking' THEN DS.DS_created
		                      ELSE Isnull(DS.Acq_Time_Start, DS.DS_created)
		                  END
		FROM T_Dataset DS
		     INNER JOIN inserted
		       ON DS.Dataset_ID = INSERTED.Dataset_ID
		     INNER JOIN T_Experiments E
		       ON DS.Exp_ID = E.Exp_ID
	End


GO
/****** Object:  Trigger [dbo].[trig_ud_T_Dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_ud_T_Dataset]ON [dbo].[T_Dataset]FOR UPDATE, DELETE AS/********************************************************	Desc: **		Prevents updating or deleting all rows in the table****	Auth:	mem**	Date:	02/08/2011*******************************************************/BEGIN    DECLARE @Count int    SET @Count = @@ROWCOUNT;    IF @Count >= (	SELECT i.rowcnt AS TableRowCount                     FROM dbo.sysobjects o INNER JOIN dbo.sysindexes i ON o.id = i.id                     WHERE o.name = 'T_Dataset' AND o.type = 'u' AND i.indid < 2                 )    BEGIN        RAISERROR('Cannot update or delete all rows. Use a WHERE clause (see trigger trig_ud_T_Dataset)',16,1)        ROLLBACK TRANSACTION        RETURN;    ENDEND
GO
