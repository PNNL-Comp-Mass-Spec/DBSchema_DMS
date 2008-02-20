/****** Object:  Table [dbo].[T_Requested_Run_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run_History](
	[RDS_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RDS_Oper_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RDS_comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_created] [datetime] NOT NULL,
	[RDS_instrument_name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_type_ID] [int] NULL,
	[RDS_instrument_setting] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_special_instructions] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_note] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Exp_ID] [int] NOT NULL,
	[RDS_Run_Start] [datetime] NULL,
	[RDS_Run_Finish] [datetime] NULL,
	[RDS_internal_standard] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ID] [int] NOT NULL,
	[DatasetID] [int] NOT NULL,
	[RDS_WorkPackage] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_BatchID] [int] NULL,
	[RDS_Blocking_Factor] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_Block] [int] NULL,
	[RDS_Run_Order] [int] NULL,
	[RDS_EUS_Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_EUS_UsageType] [int] NOT NULL CONSTRAINT [DF_T_Requested_Run_History_RDS_EUS_UsageType]  DEFAULT (1),
	[RDS_Cart_ID] [int] NOT NULL CONSTRAINT [DF_T_Requested_Run_History_RDS_Cart_ID]  DEFAULT (1),
 CONSTRAINT [PK_T_Requested_Run_History] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Requested_Run_History] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_History] ON [dbo].[T_Requested_Run_History] 
(
	[DatasetID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
GRANT DELETE ON [dbo].[T_Requested_Run_History] TO [LOC-DMS_EUS_Admin]
GO
GRANT INSERT ON [dbo].[T_Requested_Run_History] TO [LOC-DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_Requested_Run_History] TO [LOC-DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_History] TO [LOC-DMS_EUS_Admin]
GO
ALTER TABLE [dbo].[T_Requested_Run_History]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Requested_Run_History_T_Dataset] FOREIGN KEY([DatasetID])
REFERENCES [T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_History] CHECK CONSTRAINT [FK_T_Requested_Run_History_T_Dataset]
GO
ALTER TABLE [dbo].[T_Requested_Run_History]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_History_T_DatasetTypeName] FOREIGN KEY([RDS_type_ID])
REFERENCES [T_DatasetTypeName] ([DST_Type_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_History]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_History_T_EUS_Proposals] FOREIGN KEY([RDS_EUS_Proposal_ID])
REFERENCES [T_EUS_Proposals] ([PROPOSAL_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_History]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_History_T_EUS_UsageType] FOREIGN KEY([RDS_EUS_UsageType])
REFERENCES [T_EUS_UsageType] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_History]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Requested_Run_History_T_Experiments] FOREIGN KEY([Exp_ID])
REFERENCES [T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_History] CHECK CONSTRAINT [FK_T_Requested_Run_History_T_Experiments]
GO
ALTER TABLE [dbo].[T_Requested_Run_History]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_History_T_LC_Cart] FOREIGN KEY([RDS_Cart_ID])
REFERENCES [T_LC_Cart] ([ID])
GO
