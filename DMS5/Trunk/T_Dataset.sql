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
	[DS_state_ID] [int] NULL,
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
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Dataset_Acq_Time_Start] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Acq_Time_Start] ON [dbo].[T_Dataset] 
(
	[Acq_Time_Start] ASC
) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Dataset_Dataset_Num] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Dataset_Num] ON [dbo].[T_Dataset] 
(
	[Dataset_Num] ASC
) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Dataset_Exp_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Exp_ID] ON [dbo].[T_Dataset] 
(
	[Exp_ID] ASC
) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Dataset_State_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_State_ID] ON [dbo].[T_Dataset] 
(
	[DS_state_ID] ASC
) ON [PRIMARY]
GO

/****** Object:  Trigger [dbo].[trig_d_Dataset] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_d_Dataset] on [dbo].[T_Dataset]
For Insert
AS
	-- Add entries to T_Event_Log for each dataset deleted from T_Dataset
	INSERT INTO T_Event_Log
		(
			Target_Type, 
			Target_ID, 
			Target_State, 
			Prev_Target_State, 
			Entered
		)
	SELECT	4 AS Target_Type, Dataset_ID, 
			0 AS Target_State, DS_State_ID, GETDATE()
	FROM deleted
	ORDER BY Dataset_ID


GO

/****** Object:  Trigger [dbo].[trig_i_Dataset] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger trig_i_Dataset on T_Dataset
For Insert
AS
	declare @oldState int
	set @oldState = 1
	declare @newState int
	declare @datasetID int
	
	declare @done int
	set @done = 0

	declare curStateChange Cursor
	For
	select 
		inserted.Dataset_ID,
		inserted.DS_State_ID 
	From 
		inserted
		
	Open curStateChange
	while(@done = 0)
		begin -- while
		
		Fetch Next From curStateChange Into @datasetID, @newState
		if @@fetch_status = -1
			begin
				set @done = 1
			end
		else
			begin
				INSERT INTO T_Event_Log
				(
					Target_Type, 
					Target_ID, 
					Target_State, 
					Prev_Target_State, 
					Entered
				)
				VALUES
				(
					4, 
					@datasetID, 
					@newState, 
					@oldState, 
					GETDATE()
				)
			end 
		end-- while
	
	Deallocate curStateChange

GO

/****** Object:  Trigger [dbo].[trig_u_Dataset] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger trig_u_Dataset on T_Dataset
For Update
AS
	if update(DS_State_ID)
	Begin -- if update
		declare @oldState int
		declare @newState int
		declare @datasetID int
		declare @done int
		set @done = 0

		declare curStateChange Cursor
		For
		select 
			deleted.Dataset_ID,
			deleted.DS_State_ID, 
			inserted.DS_State_ID 
		From 
			deleted inner join 
			inserted on deleted.Dataset_ID = inserted.Dataset_ID
			
		Open curStateChange
		while(@done = 0)
			begin -- while
			
			Fetch Next From curStateChange Into @datasetID, @oldState, @newState
			if @@fetch_status = -1
				begin
					set @done = 1
				end
			else
				begin
					INSERT INTO T_Event_Log
					(
						Target_Type, 
						Target_ID, 
						Target_State, 
						Prev_Target_State, 
						Entered
					)
					VALUES
					(
						4, 
						@datasetID, 
						@newState, 
						@oldState, 
						GETDATE()
					)
				end 
			end-- while
		
		Deallocate curStateChange
	End  -- if update

GO
GRANT SELECT ON [dbo].[T_Dataset] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([Dataset_Num]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([Dataset_Num]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_Oper_PRN]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_Oper_PRN]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_comment]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_comment]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_created]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_created]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_instrument_name_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_instrument_name_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_LC_column_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_LC_column_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_type_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_type_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_wellplate_num]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_wellplate_num]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_well_num]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_well_num]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_sec_sep]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_sec_sep]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_state_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_state_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_folder_name]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_folder_name]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_storage_path_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_storage_path_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([Exp_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([Exp_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([Dataset_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([Dataset_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_internal_standard_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_internal_standard_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_rating]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_rating]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_Comp_State]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_Comp_State]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_Compress_Date]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_Compress_Date]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([DS_PrepServerName]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([DS_PrepServerName]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([Acq_Time_Start]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([Acq_Time_Start]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([Acq_Time_End]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([Acq_Time_End]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([Scan_Count]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([Scan_Count]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([File_Size_Bytes]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([File_Size_Bytes]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Dataset] ([File_Info_Last_Modified]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Dataset] ([File_Info_Last_Modified]) TO [Limited_Table_Write]
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
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_T_LC_Column] FOREIGN KEY([DS_LC_column_ID])
REFERENCES [T_LC_Column] ([ID])
GO
ALTER TABLE [dbo].[T_Dataset] CHECK CONSTRAINT [FK_T_Dataset_T_LC_Column]
GO
ALTER TABLE [dbo].[T_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_T_Secondary_Sep] FOREIGN KEY([DS_sec_sep])
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
