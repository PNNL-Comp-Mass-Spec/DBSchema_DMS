/****** Object:  Table [dbo].[T_Deleted_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Deleted_Requested_Run](
	[Entry_Id] [int] IDENTITY(1,1) NOT NULL,
	[Request_Id] [int] NOT NULL,
	[Request_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Requester_Username] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
	[Instrument_Group] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Request_Type_Id] [int] NULL,
	[Instrument_Setting] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Special_Instructions] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Wellplate] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Well] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Priority] [tinyint] NULL,
	[Note] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Exp_Id] [int] NOT NULL,
	[Request_Run_Start] [datetime] NULL,
	[Request_Run_Finish] [datetime] NULL,
	[Request_Internal_Standard] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Work_Package] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Batch_Id] [int] NOT NULL,
	[Blocking_Factor] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Block] [int] NULL,
	[Run_Order] [int] NULL,
	[EUS_Proposal_Id] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Usage_Type_Id] [smallint] NOT NULL,
	[EUS_Person_Id] [int] NULL,
	[Cart_Id] [int] NOT NULL,
	[Cart_Config_Id] [int] NULL,
	[Cart_Column] [smallint] NULL,
	[Separation_Group] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mrm_Attachment] [int] NULL,
	[Dataset_Id] [int] NULL,
	[Origin] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[State_Name] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Request_Name_Code] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Vialing_Conc] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Vialing_Vol] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Location_Id] [int] NULL,
	[Queue_State] [tinyint] NOT NULL,
	[Queue_Instrument_Id] [int] NULL,
	[Queue_Date] [smalldatetime] NULL,
	[Entered] [datetime] NULL,
	[Updated] [smalldatetime] NULL,
	[Updated_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Deleted] [datetime] NOT NULL,
	[Deleted_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Deleted_Requested_Run] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Deleted_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Deleted_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Deleted_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Deleted_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
/****** Object:  Index [IX_T_Deleted_Requested_Run_Batch_Id] ******/
CREATE NONCLUSTERED INDEX [IX_T_Deleted_Requested_Run_Batch_Id] ON [dbo].[T_Deleted_Requested_Run]
(
	[Batch_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Deleted_Requested_Run_Dataset_Id] ******/
CREATE NONCLUSTERED INDEX [IX_T_Deleted_Requested_Run_Dataset_Id] ON [dbo].[T_Deleted_Requested_Run]
(
	[Dataset_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Deleted_Requested_Run_Exp_Id] ******/
CREATE NONCLUSTERED INDEX [IX_T_Deleted_Requested_Run_Exp_Id] ON [dbo].[T_Deleted_Requested_Run]
(
	[Exp_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Deleted_Requested_Run_Request_Id] ******/
CREATE NONCLUSTERED INDEX [IX_T_Deleted_Requested_Run_Request_Id] ON [dbo].[T_Deleted_Requested_Run]
(
	[Request_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Deleted_Requested_Run] ADD  CONSTRAINT [DF_T_Deleted_Requested_Run_Deleted]  DEFAULT (getdate()) FOR [Deleted]
GO
ALTER TABLE [dbo].[T_Deleted_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Deleted_Requested_Run_T_Dataset_Type_Name] FOREIGN KEY([Request_Type_Id])
REFERENCES [dbo].[T_Dataset_Type_Name] ([DST_Type_ID])
GO
ALTER TABLE [dbo].[T_Deleted_Requested_Run] CHECK CONSTRAINT [FK_T_Deleted_Requested_Run_T_Dataset_Type_Name]
GO
ALTER TABLE [dbo].[T_Deleted_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Deleted_Requested_Run_T_EUS_UsageType] FOREIGN KEY([EUS_Usage_Type_Id])
REFERENCES [dbo].[T_EUS_UsageType] ([ID])
GO
ALTER TABLE [dbo].[T_Deleted_Requested_Run] CHECK CONSTRAINT [FK_T_Deleted_Requested_Run_T_EUS_UsageType]
GO
ALTER TABLE [dbo].[T_Deleted_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Deleted_Requested_Run_T_Requested_Run_State_Name] FOREIGN KEY([State_Name])
REFERENCES [dbo].[T_Requested_Run_State_Name] ([State_Name])
GO
ALTER TABLE [dbo].[T_Deleted_Requested_Run] CHECK CONSTRAINT [FK_T_Deleted_Requested_Run_T_Requested_Run_State_Name]
GO
