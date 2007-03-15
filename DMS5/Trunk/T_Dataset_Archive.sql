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

CREATE Trigger trig_i_Dataset_Archive on T_Dataset_Archive
For Insert
AS
	declare @oldState int
	set @oldState = 0
	declare @newState int
	declare @datasetID int
	
	declare @done int
	set @done = 0

	declare curStateChange Cursor
	For
	select 
		inserted.AS_Dataset_ID,
		inserted.AS_state_ID 
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
					6, 
					@datasetID, 
					@newState, 
					@oldState, 
					GETDATE()
				)
			end 
		end-- while
	
	Deallocate curStateChange

GO

/****** Object:  Trigger [dbo].[trig_u_Dataset_Archive] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger trig_u_Dataset_Archive on T_Dataset_Archive  
For Update
AS
	if update(AS_state_ID)
	Begin -- if update
		declare @oldState int
		declare @newState int
		declare @datasetID int
		declare @done int
		set @done = 0

		declare curStateChange Cursor
		For
		select 
			deleted.AS_Dataset_ID,
			deleted.AS_state_ID, 
			inserted.AS_state_ID 
		From 
			deleted inner join 
			inserted on deleted.AS_Dataset_ID = inserted.AS_Dataset_ID
			
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
						6, 
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
