/****** Object:  Table [dbo].[T_Requested_Run_Batches] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run_Batches](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[Batch] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Owner] [int] NULL,
	[Created] [datetime] NOT NULL,
	[Locked] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Last_Ordered] [datetime] NULL,
	[Requested_Batch_Priority] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Actual_Batch_Priority] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requested_Completion_Date] [smalldatetime] NULL,
	[Justification_for_High_Priority] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requested_Instrument] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Requested_Run_Batches] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Trigger [dbo].[trig_u_Requested_Run_Batches] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_Requested_Run_Batches] on [dbo].[T_Requested_Run_Batches]
After Update
/****************************************************
**
**	Desc: 
**		Updates column RDS_NameCode for requested runs
**		associated with the updated batches
**
**	Auth:	mem
**	Date:	08/05/2010 mem - Initial version
**			08/10/2010 mem - Now passing dataset type and separation type to GetRequestedRunNameCode
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update (Batch) OR
	   Update (Created) OR
	   Update (Owner)
	Begin
		UPDATE T_Requested_Run
		SET RDS_NameCode = dbo.[GetRequestedRunNameCode](RR.RDS_Name, RR.RDS_Created, RR.RDS_Oper_PRN, 
														 RR.RDS_BatchID, RRB.Batch, RRB.Created, U.U_PRN,
														 RR.RDS_type_ID, RR.RDS_Sec_Sep)
		FROM T_Requested_Run RR
			 INNER JOIN inserted
			   ON RR.RDS_BatchID = inserted.ID
			 INNER JOIN T_Requested_Run_Batches RRB
			   ON RRB.ID = RR.RDS_BatchID
			 INNER JOIN T_Users U
			   ON RRB.Owner = U.ID
	End


GO
GRANT DELETE ON [dbo].[T_Requested_Run_Batches] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Requested_Run_Batches] TO [Limited_Table_Write] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[T_Requested_Run_Batches] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Requested_Run_Batches] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_Batches] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_Batches_T_Users] FOREIGN KEY([Owner])
REFERENCES [T_Users] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] CHECK CONSTRAINT [FK_T_Requested_Run_Batches_T_Users]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] ADD  CONSTRAINT [DF_T_Requested_Run_Batches_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] ADD  CONSTRAINT [DF_T_Requested_Run_Batches_Locking]  DEFAULT ('Yes') FOR [Locked]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] ADD  CONSTRAINT [DF_T_Requested_Run_Batches_Requested_Batch_Priority]  DEFAULT ('Normal') FOR [Requested_Batch_Priority]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] ADD  CONSTRAINT [DF_T_Requested_Run_Batches_Requested_Instrument]  DEFAULT ('na') FOR [Requested_Instrument]
GO
