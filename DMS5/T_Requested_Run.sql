/****** Object:  Table [dbo].[T_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run](
	[RDS_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RDS_Oper_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RDS_comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RDS_WorkPackage] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_BatchID] [int] NOT NULL,
	[RDS_Blocking_Factor] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_Block] [int] NULL,
	[RDS_Run_Order] [int] NULL,
	[RDS_EUS_Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_EUS_UsageType] [int] NOT NULL,
	[RDS_Cart_ID] [int] NOT NULL,
	[RDS_Cart_Col] [smallint] NULL,
	[RDS_Sec_Sep] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_MRM_Attachment] [int] NULL,
	[DatasetID] [int] NULL,
	[RDS_Origin] [char](4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_Status] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RDS_NameCode] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NULL,
 CONSTRAINT [PK_T_Requested_Run] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Requested_Run_BatchID_include_ExpID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_BatchID_include_ExpID] ON [dbo].[T_Requested_Run] 
(
	[RDS_BatchID] ASC
)
INCLUDE ( [Exp_ID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Requested_Run_Dataset_ID_Include_Created_ID_Batch] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Dataset_ID_Include_Created_ID_Batch] ON [dbo].[T_Requested_Run] 
(
	[DatasetID] ASC
)
INCLUDE ( [RDS_created],
[ID],
[RDS_BatchID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Requested_Run_DatasetID_Status] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_DatasetID_Status] ON [dbo].[T_Requested_Run] 
(
	[DatasetID] ASC,
	[RDS_Status] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Requested_Run_Exp_ID_Include_NameIDStatus] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Exp_ID_Include_NameIDStatus] ON [dbo].[T_Requested_Run] 
(
	[Exp_ID] ASC
)
INCLUDE ( [RDS_Name],
[ID],
[RDS_Status]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Requested_Run_RDS_Block_include_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_RDS_Block_include_ID] ON [dbo].[T_Requested_Run] 
(
	[RDS_Block] ASC
)
INCLUDE ( [ID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Requested_Run_RDS_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_RDS_Name] ON [dbo].[T_Requested_Run] 
(
	[RDS_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Requested_Run_RDS_NameCode] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_RDS_NameCode] ON [dbo].[T_Requested_Run] 
(
	[RDS_NameCode] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Requested_Run_RDS_Run_Order_include_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_RDS_Run_Order_include_ID] ON [dbo].[T_Requested_Run] 
(
	[RDS_Run_Order] ASC
)
INCLUDE ( [ID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_d_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Trigger trig_d_Requested_Run on T_Requested_Run
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the deleted Requested Run
**
**	Auth:	mem
**	Date:	12/12/2011 mem - Initial version
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Event_Log for each Requested Run deleted from T_Requested_Run
	INSERT INTO T_Event_Log
		(
			Target_Type, 
			Target_ID, 
			Target_State, 
			Prev_Target_State, 
			Entered,
			Entered_By
		)
	SELECT 11 AS Target_Type,
	       ID AS Target_ID,
	       0 AS Target_State,
	       RRS.State_ID AS Prev_Target_State,
	       GETDATE(),
	       suser_sname() + '; ' + IsNull(deleted.RDS_Name, '??')
	FROM deleted
	     INNER JOIN T_Requested_Run_State_Name RRS
	       ON deleted.RDS_Status = RRS.State_Name
	ORDER BY deleted.ID

GO
/****** Object:  Trigger [dbo].[trig_i_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Trigger trig_i_Requested_Run on T_Requested_Run
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the new Requested Run
**
**	Auth:	mem
**	Date:	12/12/2011 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 11 AS Target_Type, inserted.ID, RRS.State_ID, 0, GetDate()
	FROM inserted INNER JOIN T_Requested_Run_State_Name RRS
		   ON inserted.RDS_Status = RRS.State_Name
	ORDER BY inserted.ID

GO
/****** Object:  Trigger [dbo].[trig_u_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger trig_u_Requested_Run on T_Requested_Run
After Insert, Update
/****************************************************
**
**	Desc: 
**		Updates column RDS_NameCode for new or updated requested run(s)
**
**	Auth:	mem
**	Date:	08/05/2010 mem - Initial version
**			08/10/2010 mem - Now passing dataset type and separation type to GetRequestedRunNameCode
**			12/12/2011 mem - Now updating T_Event_Log
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(RDS_Name) OR
	   Update(RDS_Created) OR
	   Update(RDS_Oper_PRN) OR
	   Update(RDS_BatchID) OR
	   Update(RDS_NameCode) OR
	   Update(RDS_Type_ID) OR
	   Update(RDS_Sec_Sep)
	Begin
		UPDATE T_Requested_Run
		SET RDS_NameCode = dbo.[GetRequestedRunNameCode](RR.RDS_Name, RR.RDS_Created, RR.RDS_Oper_PRN, 
														 RR.RDS_BatchID, RRB.Batch, RRB.Created, U.U_PRN,
														 RR.RDS_type_ID, RR.RDS_Sec_Sep)
		FROM T_Requested_Run RR
			 INNER JOIN inserted
			   ON RR.ID = inserted.ID
			 LEFT OUTER JOIN T_Requested_Run_Batches RRB
			   ON RRB.ID = RR.RDS_BatchID
			 INNER JOIN T_Users U
			   ON RRB.Owner = U.ID
	End
	
	If Update(RDS_Status)
	Begin
		INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
		SELECT 11 AS Target_Type, inserted.ID, RRSNew.State_ID, RRSOld.State_ID, GetDate()
		FROM deleted
		     INNER JOIN inserted
		       ON deleted.ID = inserted.ID
		     INNER JOIN T_Requested_Run_State_Name RRSOld
		       ON deleted.RDS_Status = RRSOld.State_Name
		     INNER JOIN T_Requested_Run_State_Name RRSNew
		       ON inserted.RDS_Status = RRSNew.State_Name
		WHERE deleted.RDS_Status <> inserted.RDS_Status
		ORDER BY inserted.ID
	End

GO
GRANT DELETE ON [dbo].[T_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Attachments] FOREIGN KEY([RDS_MRM_Attachment])
REFERENCES [T_Attachments] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Attachments]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Dataset] FOREIGN KEY([DatasetID])
REFERENCES [T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Dataset]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_DatasetTypeName] FOREIGN KEY([RDS_type_ID])
REFERENCES [T_DatasetTypeName] ([DST_Type_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_DatasetTypeName]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_EUS_Proposals] FOREIGN KEY([RDS_EUS_Proposal_ID])
REFERENCES [T_EUS_Proposals] ([Proposal_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_EUS_Proposals]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_EUS_UsageType] FOREIGN KEY([RDS_EUS_UsageType])
REFERENCES [T_EUS_UsageType] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_EUS_UsageType]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Experiments] FOREIGN KEY([Exp_ID])
REFERENCES [T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Experiments]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_LC_Cart] FOREIGN KEY([RDS_Cart_ID])
REFERENCES [T_LC_Cart] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_LC_Cart]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Requested_Run_Batches] FOREIGN KEY([RDS_BatchID])
REFERENCES [T_Requested_Run_Batches] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Requested_Run_Batches]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Requested_Run_State_Name] FOREIGN KEY([RDS_Status])
REFERENCES [T_Requested_Run_State_Name] ([State_Name])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Requested_Run_State_Name]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Separation_Group] FOREIGN KEY([RDS_Sec_Sep])
REFERENCES [T_Separation_Group] ([Sep_Group])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Separation_Group]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Users] FOREIGN KEY([RDS_Oper_PRN])
REFERENCES [T_Users] ([U_PRN])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Users]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [CK_T_Requested_Run_RequestedRunName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([RDS_Name],(0))=(0)))
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [CK_T_Requested_Run_RequestedRunName_WhiteSpace]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_BatchID]  DEFAULT ((0)) FOR [RDS_BatchID]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_EUS_UsageType]  DEFAULT ((1)) FOR [RDS_EUS_UsageType]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_Cart_ID]  DEFAULT ((1)) FOR [RDS_Cart_ID]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_Sec_Sep]  DEFAULT ('none') FOR [RDS_Sec_Sep]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_Status]  DEFAULT ('Active') FOR [RDS_Status]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
