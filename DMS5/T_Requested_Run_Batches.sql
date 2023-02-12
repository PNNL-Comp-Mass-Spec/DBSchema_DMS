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
	[Requested_Batch_Priority] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Actual_Batch_Priority] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Requested_Completion_Date] [smalldatetime] NULL,
	[Justification_for_High_Priority] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requested_Instrument] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Batch_Group_ID] [int] NULL,
	[Batch_Group_Order] [int] NULL,
	[RFID_Hex_ID]  AS (left(concat(CONVERT([varchar](24),CONVERT([varbinary],CONVERT([varchar],[ID])),(2)),'000000000000000000000000'),(24))) PERSISTED,
 CONSTRAINT [PK_T_Requested_Run_Batches] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Requested_Run_Batches] TO [DDL_Viewer] AS [dbo]
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
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Requested_Run_Batches] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Requested_Run_Batches] ON [dbo].[T_Requested_Run_Batches]
(
	[Batch] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Requested_Run_Batches_Batch_Group_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Batches_Batch_Group_ID] ON [dbo].[T_Requested_Run_Batches]
(
	[Batch_Group_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] ADD  CONSTRAINT [DF_T_Requested_Run_Batches_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] ADD  CONSTRAINT [DF_T_Requested_Run_Batches_Locking]  DEFAULT ('Yes') FOR [Locked]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] ADD  CONSTRAINT [DF_T_Requested_Run_Batches_Requested_Batch_Priority]  DEFAULT ('Normal') FOR [Requested_Batch_Priority]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] ADD  CONSTRAINT [DF_T_Requested_Run_Batches_Actual_Batch_Priority]  DEFAULT ('Normal') FOR [Actual_Batch_Priority]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] ADD  CONSTRAINT [DF_T_Requested_Run_Batches_Requested_Instrument]  DEFAULT ('na') FOR [Requested_Instrument]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_Batches_T_Requested_Run_Batch_Group] FOREIGN KEY([Batch_Group_ID])
REFERENCES [dbo].[T_Requested_Run_Batch_Group] ([Batch_Group_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] CHECK CONSTRAINT [FK_T_Requested_Run_Batches_T_Requested_Run_Batch_Group]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_Batches_T_Users] FOREIGN KEY([Owner])
REFERENCES [dbo].[T_Users] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] CHECK CONSTRAINT [FK_T_Requested_Run_Batches_T_Users]
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
**  Desc: 
**      Updates column RDS_NameCode for requested runs
**      associated with the updated batches
**
**  Auth:   mem
**  Date:   08/05/2010 mem - Initial version
**          08/10/2010 mem - Now passing dataset type and separation type to GetRequestedRunNameCode
**          06/27/2022 mem - No longer pass the username of the batch owner to GetRequestedRunNameCode
**          08/01/2022 mem - Only update RDS_NameCode if the name code has changed; 
**                           this is important for requested runs with BatchID = 0 (since we want to avoid 
**                           updating large numbers of rows if the name code didn't actually change)
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
        SET RDS_NameCode = dbo.[GetRequestedRunNameCode](RR.RDS_Name, RR.RDS_Created, RR.RDS_Requestor_PRN, 
                                                         RR.RDS_BatchID, RRB.Batch, RRB.Created,
                                                         RR.RDS_type_ID, RR.RDS_Sec_Sep)
        FROM T_Requested_Run RR
             INNER JOIN inserted
               ON RR.RDS_BatchID = inserted.ID
             INNER JOIN T_Requested_Run_Batches RRB
               ON RRB.ID = RR.RDS_BatchID
        WHERE RR.RDS_NameCode <> dbo.[GetRequestedRunNameCode](RR.RDS_Name, RR.RDS_Created, RR.RDS_Requestor_PRN, 
                                                               RR.RDS_BatchID, RRB.Batch, RRB.Created,
                                                               RR.RDS_type_ID, RR.RDS_Sec_Sep)
    End

GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] ENABLE TRIGGER [trig_u_Requested_Run_Batches]
GO
