/****** Object:  Table [dbo].[T_Sample_Prep_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Sample_Prep_Request](
	[ID] [int] IDENTITY(1000,1) NOT NULL,
	[Request_Type] [varchar](16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Request_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requester_PRN] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Reason] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Cell_Culture_List] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Organism] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Biohazard_Level] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Campaign] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Number_of_Samples] [int] NULL,
	[Sample_Name_List] [varchar](1500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Prep_Method] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Prep_By_Robot] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Special_Instructions] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Naming_Convention] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Assigned_Personnel] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Work_Package_Number] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[User_Proposal_Number] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Replicates_of_Samples] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Technical_Replicates] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_Group] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_Analysis_Specifications] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Priority] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
	[State] [tinyint] NOT NULL,
	[Requested_Personnel] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StateChanged] [datetime] NOT NULL,
	[UseSingleLCColumn] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Internal_standard_ID] [int] NOT NULL,
	[Postdigest_internal_std_ID] [int] NOT NULL,
	[Estimated_Completion] [datetime] NULL,
	[Estimated_MS_runs] [varchar](16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_UsageType] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_User_List] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Project_Number] [varchar](15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Facility] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Separation_Type] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[BlockAndRandomizeSamples] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[BlockAndRandomizeRuns] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IOPSPermitsCurrent] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Reason_For_High_Priority] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Number_Of_Biomaterial_Reps_Received] [int] NOT NULL,
	[Sample_Submission_Item_Count] [int] NULL,
	[Biomaterial_Item_Count] [int] NULL,
	[Experiment_Item_Count] [int] NULL,
	[Experiment_Group_Item_Count] [int] NULL,
	[Material_Containers_Item_Count] [int] NULL,
	[Requested_Run_Item_Count] [int] NULL,
	[Dataset_Item_Count] [int] NULL,
	[HPLC_Runs_Item_Count] [int] NULL,
	[Total_Item_Count] [int] NULL,
	[Material_Container_List] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Sample_Prep_Request] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Sample_Prep_Request] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Sample_Prep_Request] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Sample_Prep_Request] ON [dbo].[T_Sample_Prep_Request]
(
	[Request_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Request_Type]  DEFAULT ('Default') FOR [Request_Type]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Dataset_Type]  DEFAULT ('Normal') FOR [Dataset_Type]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Priority]  DEFAULT ('Normal') FOR [Priority]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_State]  DEFAULT ((1)) FOR [State]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_StateChanged]  DEFAULT (getdate()) FOR [StateChanged]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_UseSingleLCColumn]  DEFAULT ('No') FOR [UseSingleLCColumn]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Internal_standard_ID]  DEFAULT ((0)) FOR [Internal_standard_ID]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Postdigest_internal_std_ID]  DEFAULT ((0)) FOR [Postdigest_internal_std_ID]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Factility]  DEFAULT ('EMSL') FOR [Facility]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] ADD  CONSTRAINT [DF_T_Sample_Prep_Request_Number_Of_Biomaterial_Reps_Received]  DEFAULT ((0)) FOR [Number_Of_Biomaterial_Reps_Received]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_EUS_Proposals] FOREIGN KEY([EUS_Proposal_ID])
REFERENCES [dbo].[T_EUS_Proposals] ([Proposal_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_EUS_Proposals]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_EUS_UsageType] FOREIGN KEY([EUS_UsageType])
REFERENCES [dbo].[T_EUS_UsageType] ([Name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_EUS_UsageType]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards] FOREIGN KEY([Internal_standard_ID])
REFERENCES [dbo].[T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards1] FOREIGN KEY([Postdigest_internal_std_ID])
REFERENCES [dbo].[T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards1]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_Sample_Prep_Request_State_Name] FOREIGN KEY([State])
REFERENCES [dbo].[T_Sample_Prep_Request_State_Name] ([State_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_Sample_Prep_Request_State_Name]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_Sample_Prep_Request_Type_Name] FOREIGN KEY([Request_Type])
REFERENCES [dbo].[T_Sample_Prep_Request_Type_Name] ([Request_Type])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_Sample_Prep_Request_Type_Name]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH CHECK ADD  CONSTRAINT [CK_T_Sample_Prep_Request_SamplePrepRequestName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([Request_Name],(1))=(0)))
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [CK_T_Sample_Prep_Request_SamplePrepRequestName_WhiteSpace]
GO
/****** Object:  Trigger [dbo].[trig_d_Sample_Prep_Req] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_d_Sample_Prep_Req] on [dbo].[T_Sample_Prep_Request]
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Sample_Prep_Request_Updates for the deleted sample prep request
**
**	Auth:	mem
**	Date:	05/16/2008
**			11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**			11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Sample_Prep_Request_Updates for each entry deleted from T_Sample_Prep_Request
	INSERT INTO T_Sample_Prep_Request_Updates (
			Request_ID, 
			System_Account, 
			Beginning_State_ID, 
			End_State_ID)
	SELECT 	deleted.ID, 
		   	dbo.GetUserLoginWithoutDomain('') + '; ' + ISNULL(deleted.Request_Name, 'Unknown Request'),
			deleted.state,
			0 AS End_State_ID
	FROM deleted
	ORDER BY deleted.ID



GO
/****** Object:  Trigger [dbo].[trig_i_Sample_Prep_Req] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_i_Sample_Prep_Req] on [dbo].[T_Sample_Prep_Request]
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Sample_Prep_Request_Updates for the new sample prep request
**
**	Auth:	mem
**	Date:	05/16/2008
**			11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**			11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Sample_Prep_Request_Updates (
			Request_ID, 
			System_Account, 
			Beginning_State_ID, 
			End_State_ID)
	SELECT 	inserted.ID, 
		   	dbo.GetUserLoginWithoutDomain(''),
			0,
			inserted.state
	FROM inserted
	ORDER BY inserted.ID



GO
/****** Object:  Trigger [dbo].[trig_u_Sample_Prep_Req] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_Sample_Prep_Req] on [dbo].[T_Sample_Prep_Request]
For Update
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Sample_Prep_Request_Updates for the updated sample prep request
**
**	Auth:	grk
**	Date:	01/01/2003
**			08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**			05/16/2008 mem - Fixed bug that was inserting the Beginning_State_ID and End_State_ID values backward
**			11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**			11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Sample_Prep_Request_Updates (
			Request_ID, 
			System_Account, 
			Beginning_State_ID, 
			End_State_ID)
	SELECT 	inserted.ID, 
		   	dbo.GetUserLoginWithoutDomain(''),
			deleted.state,
			inserted.state
	FROM deleted INNER JOIN inserted ON deleted.ID = inserted.ID
	ORDER BY inserted.ID



GO
