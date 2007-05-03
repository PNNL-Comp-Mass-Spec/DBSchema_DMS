/****** Object:  Table [dbo].[T_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run](
	[RDS_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RDS_Oper_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RDS_comment] [varchar](244) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_created] [datetime] NOT NULL,
	[RDS_instrument_name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_type_ID] [int] NULL,
	[RDS_instrument_setting] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_special_instructions] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_Well_Plate_Num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_Well_Num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_priority] [int] NULL,
	[RDS_note] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Exp_ID] [int] NOT NULL,
	[RDS_Run_Start] [datetime] NULL,
	[RDS_Run_Finish] [datetime] NULL,
	[RDS_internal_standard] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ID] [int] NOT NULL,
	[RDS_WorkPackage] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_BatchID] [int] NOT NULL CONSTRAINT [DF_T_Requested_Run_RDS_BatchID]  DEFAULT (0),
	[RDS_Blocking_Factor] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_Block] [int] NULL,
	[RDS_Run_Order] [int] NULL,
	[RDS_EUS_Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_EUS_UsageType] [int] NOT NULL CONSTRAINT [DF_T_Requested_Run_RDS_EUS_UsageType]  DEFAULT (1),
	[RDS_Cart_ID] [int] NOT NULL CONSTRAINT [DF_T_Requested_Run_RDS_Cart_ID]  DEFAULT (1),
	[RDS_Cart_Col] [smallint] NULL,
 CONSTRAINT [PK_T_Requested_Run] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_Requested_Run] TO [Limited_Table_Write]
GO
GRANT INSERT ON [dbo].[T_Requested_Run] TO [Limited_Table_Write]
GO
GRANT DELETE ON [dbo].[T_Requested_Run] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_Name]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_Name]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_Oper_PRN]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_Oper_PRN]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_comment]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_comment]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_created]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_created]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_instrument_name]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_instrument_name]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_type_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_type_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_instrument_setting]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_instrument_setting]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_special_instructions]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_special_instructions]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_Well_Plate_Num]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_Well_Plate_Num]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_Well_Num]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_Well_Num]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_priority]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_priority]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_note]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_note]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([Exp_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([Exp_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_Run_Start]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_Run_Start]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_Run_Finish]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_Run_Finish]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_internal_standard]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_internal_standard]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_WorkPackage]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_WorkPackage]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_BatchID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_BatchID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_Blocking_Factor]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_Blocking_Factor]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_Block]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_Block]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_Run_Order]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_Run_Order]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_EUS_Proposal_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_EUS_Proposal_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_EUS_UsageType]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_EUS_UsageType]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_Cart_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_Cart_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] ([RDS_Cart_Col]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] ([RDS_Cart_Col]) TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_DatasetTypeName] FOREIGN KEY([RDS_type_ID])
REFERENCES [T_DatasetTypeName] ([DST_Type_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_DatasetTypeName]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_EUS_Proposals] FOREIGN KEY([RDS_EUS_Proposal_ID])
REFERENCES [T_EUS_Proposals] ([PROPOSAL_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_EUS_UsageType] FOREIGN KEY([RDS_EUS_UsageType])
REFERENCES [T_EUS_UsageType] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Experiments] FOREIGN KEY([Exp_ID])
REFERENCES [T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Experiments]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_LC_Cart] FOREIGN KEY([RDS_Cart_ID])
REFERENCES [T_LC_Cart] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Requested_Run_Batches] FOREIGN KEY([RDS_BatchID])
REFERENCES [T_Requested_Run_Batches] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Users] FOREIGN KEY([RDS_Oper_PRN])
REFERENCES [T_Users] ([U_PRN])
GO
