/****** Object:  Table [dbo].[T_Sample_Prep_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Sample_Prep_Request](
	[Request_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requester_PRN] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Reason] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Cell_Culture_List] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Organism] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Biohazard_Level] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Campaign] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Number_of_Samples] [int] NULL,
	[Sample_Name_List] [varchar](1500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Prep_Method] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Prep_By_Robot] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Special_Instructions] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Naming_Convention] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Assigned_Personnel] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Work_Package_Number] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[User_Proposal_Number] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Replicates_of_Samples] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_Analysis_Specifications] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Priority] [tinyint] NULL,
	[Created] [datetime] NOT NULL CONSTRAINT [DF_T_Sample_Prep_Request_Created]  DEFAULT (getdate()),
	[State] [tinyint] NOT NULL CONSTRAINT [DF_T_Sample_Prep_Request_State]  DEFAULT (1),
	[ID] [int] IDENTITY(1000,1) NOT NULL,
	[Requested_Personnel] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[StateChanged] [datetime] NOT NULL CONSTRAINT [DF_T_Sample_Prep_Request_StateChanged]  DEFAULT (getdate()),
	[UseSingleLCColumn] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Sample_Prep_Request_UseSingleLCColumn]  DEFAULT ('No'),
	[Internal_standard_ID] [int] NOT NULL CONSTRAINT [DF_T_Sample_Prep_Request_Internal_standard_ID]  DEFAULT (0),
	[Postdigest_internal_std_ID] [int] NOT NULL CONSTRAINT [DF_T_Sample_Prep_Request_Postdigest_internal_std_ID]  DEFAULT (0),
	[Estimated_Completion] [datetime] NULL,
	[Estimated_MS_runs] [varchar](16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_UsageType] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_User_List] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Sample_Prep_Request] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Sample_Prep_Request] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Sample_Prep_Request] ON [dbo].[T_Sample_Prep_Request] 
(
	[Request_Name] ASC
) ON [PRIMARY]
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
		   	REPLACE (SUSER_SNAME() , 'pnl\' , '' ),
			inserted.state, 
			deleted.state
	FROM deleted INNER JOIN inserted ON deleted.ID = inserted.ID
	ORDER BY inserted.ID


GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write]
GO
GRANT INSERT ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write]
GO
GRANT DELETE ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Request_Name]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Request_Name]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Requester_PRN]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Requester_PRN]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Reason]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Reason]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Cell_Culture_List]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Cell_Culture_List]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Organism]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Organism]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Biohazard_Level]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Biohazard_Level]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Campaign]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Campaign]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Number_of_Samples]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Number_of_Samples]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Sample_Name_List]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Sample_Name_List]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Sample_Type]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Sample_Type]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Prep_Method]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Prep_Method]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Prep_By_Robot]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Prep_By_Robot]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Special_Instructions]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Special_Instructions]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Sample_Naming_Convention]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Sample_Naming_Convention]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Assigned_Personnel]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Assigned_Personnel]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Work_Package_Number]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Work_Package_Number]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([User_Proposal_Number]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([User_Proposal_Number]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Replicates_of_Samples]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Replicates_of_Samples]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Instrument_Analysis_Specifications]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Instrument_Analysis_Specifications]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Comment]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Comment]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Priority]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Priority]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Created]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Created]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([State]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([State]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Requested_Personnel]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Requested_Personnel]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([StateChanged]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([StateChanged]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([UseSingleLCColumn]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([UseSingleLCColumn]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Internal_standard_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Internal_standard_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Postdigest_internal_std_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Postdigest_internal_std_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Estimated_Completion]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Estimated_Completion]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([Estimated_MS_runs]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([Estimated_MS_runs]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([EUS_UsageType]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([EUS_UsageType]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([EUS_Proposal_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([EUS_Proposal_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Sample_Prep_Request] ([EUS_User_List]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Sample_Prep_Request] ([EUS_User_List]) TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards] FOREIGN KEY([Internal_standard_ID])
REFERENCES [T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards1] FOREIGN KEY([Postdigest_internal_std_ID])
REFERENCES [T_Internal_Standards] ([Internal_Std_Mix_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_Internal_Standards1]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_T_Sample_Prep_Request_State_Name] FOREIGN KEY([State])
REFERENCES [T_Sample_Prep_Request_State_Name] ([State_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_T_Sample_Prep_Request_State_Name]
GO
