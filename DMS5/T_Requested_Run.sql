/****** Object:  Table [dbo].[T_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run](
	[RDS_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RDS_Requestor_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RDS_comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_created] [datetime] NOT NULL,
	[RDS_instrument_group] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_type_ID] [int] NULL,
	[RDS_instrument_setting] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_special_instructions] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_Well_Plate_Num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_Well_Num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_priority] [tinyint] NULL,
	[RDS_note] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Exp_ID] [int] NOT NULL,
	[RDS_Run_Start] [datetime] NULL,
	[RDS_Run_Finish] [datetime] NULL,
	[RDS_internal_standard] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RDS_WorkPackage] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Cached_WP_Activation_State] [tinyint] NOT NULL,
	[RDS_BatchID] [int] NOT NULL,
	[RDS_Blocking_Factor] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_Block] [int] NULL,
	[RDS_Run_Order] [int] NULL,
	[RDS_EUS_Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_EUS_UsageType] [smallint] NOT NULL,
	[RDS_Cart_ID] [int] NOT NULL,
	[RDS_Cart_Config_ID] [int] NULL,
	[RDS_Cart_Col] [smallint] NULL,
	[RDS_Sec_Sep] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_MRM_Attachment] [int] NULL,
	[DatasetID] [int] NULL,
	[RDS_Origin] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RDS_Status] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RDS_NameCode] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Vialing_Conc] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Vialing_Vol] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Location_ID] [int] NULL,
	[Queue_State] [tinyint] NOT NULL,
	[Queue_Instrument_ID] [int] NULL,
	[Queue_Date] [smalldatetime] NULL,
	[Entered] [datetime] NULL,
	[Updated] [smalldatetime] NULL,
	[Updated_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Requested_Run] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Requested_Run] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run] TO [Limited_Table_Write] AS [dbo]
GO
/****** Object:  Index [IX_T_Requested_Run_BatchID_include_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_BatchID_include_DatasetID] ON [dbo].[T_Requested_Run]
(
	[RDS_BatchID] ASC
)
INCLUDE([DatasetID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Requested_Run_BatchID_include_ExpID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_BatchID_include_ExpID] ON [dbo].[T_Requested_Run]
(
	[RDS_BatchID] ASC
)
INCLUDE([Exp_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Requested_Run_Cached_WP_Activation_State_Include_Request_Type_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Cached_WP_Activation_State_Include_Request_Type_ID] ON [dbo].[T_Requested_Run]
(
	[Cached_WP_Activation_State] ASC
)
INCLUDE([RDS_type_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Requested_Run_Created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Created] ON [dbo].[T_Requested_Run]
(
	[RDS_created] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Requested_Run_Dataset_ID_Include_Created_ID_Batch] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Dataset_ID_Include_Created_ID_Batch] ON [dbo].[T_Requested_Run]
(
	[DatasetID] ASC
)
INCLUDE([RDS_created],[ID],[RDS_BatchID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Requested_Run_DatasetID_Status] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_DatasetID_Status] ON [dbo].[T_Requested_Run]
(
	[DatasetID] ASC,
	[RDS_Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Requested_Run_EUS_Proposal_ID_include_ID_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_EUS_Proposal_ID_include_ID_DatasetID] ON [dbo].[T_Requested_Run]
(
	[RDS_EUS_Proposal_ID] ASC
)
INCLUDE([ID],[DatasetID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Requested_Run_EUS_UsageType_Include_EUS_Proposal_ID_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_EUS_UsageType_Include_EUS_Proposal_ID_DatasetID] ON [dbo].[T_Requested_Run]
(
	[RDS_EUS_UsageType] ASC
)
INCLUDE([RDS_EUS_Proposal_ID],[DatasetID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Requested_Run_Exp_ID_Include_NameIDStatus] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Exp_ID_Include_NameIDStatus] ON [dbo].[T_Requested_Run]
(
	[Exp_ID] ASC
)
INCLUDE([RDS_Name],[ID],[RDS_Status]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Requested_Run_Name_Status_include_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Name_Status_include_ID] ON [dbo].[T_Requested_Run]
(
	[RDS_Name] ASC,
	[RDS_Status] ASC
)
INCLUDE([ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Requested_Run_Proposal_ID_WorkPackage_Entered] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Proposal_ID_WorkPackage_Entered] ON [dbo].[T_Requested_Run]
(
	[RDS_EUS_Proposal_ID] ASC,
	[RDS_WorkPackage] ASC,
	[Entered] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Requested_Run_Queue_State_include_RDS_Type_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Queue_State_include_RDS_Type_ID] ON [dbo].[T_Requested_Run]
(
	[Queue_State] ASC
)
INCLUDE([RDS_type_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Requested_Run_RDS_Block_include_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_RDS_Block_include_ID] ON [dbo].[T_Requested_Run]
(
	[RDS_Block] ASC
)
INCLUDE([ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Requested_Run_RDS_NameCode] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_RDS_NameCode] ON [dbo].[T_Requested_Run]
(
	[RDS_NameCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Requested_Run_RDS_Run_Order_include_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_RDS_Run_Order_include_ID] ON [dbo].[T_Requested_Run]
(
	[RDS_Run_Order] ASC
)
INCLUDE([ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Requested_Run_RDS_Status] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_RDS_Status] ON [dbo].[T_Requested_Run]
(
	[RDS_Status] ASC
)
INCLUDE([ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Requested_Run_Updated] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Updated] ON [dbo].[T_Requested_Run]
(
	[Updated] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Requested_Run_WorkPackage_Include_Request_ID_Cached_WP_Activation_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_WorkPackage_Include_Request_ID_Cached_WP_Activation_State] ON [dbo].[T_Requested_Run]
(
	[RDS_WorkPackage] ASC
)
INCLUDE([ID],[Cached_WP_Activation_State]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_created]  DEFAULT (getdate()) FOR [RDS_created]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_Cached_WP_Activation_State]  DEFAULT ((0)) FOR [Cached_WP_Activation_State]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_BatchID]  DEFAULT ((0)) FOR [RDS_BatchID]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_EUS_UsageType]  DEFAULT ((1)) FOR [RDS_EUS_UsageType]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_Cart_ID]  DEFAULT ((1)) FOR [RDS_Cart_ID]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_Sec_Sep]  DEFAULT ('none') FOR [RDS_Sec_Sep]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_Origin]  DEFAULT ('user') FOR [RDS_Origin]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_RDS_Status]  DEFAULT ('Active') FOR [RDS_Status]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_Queue_State]  DEFAULT ((1)) FOR [Queue_State]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Requested_Run] ADD  CONSTRAINT [DF_T_Requested_Run_Updated]  DEFAULT (getdate()) FOR [Updated]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Attachments] FOREIGN KEY([RDS_MRM_Attachment])
REFERENCES [dbo].[T_Attachments] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Attachments]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Dataset] FOREIGN KEY([DatasetID])
REFERENCES [dbo].[T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Dataset]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Dataset_Type_Name] FOREIGN KEY([RDS_type_ID])
REFERENCES [dbo].[T_Dataset_Type_Name] ([DST_Type_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Dataset_Type_Name]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_EUS_Proposals] FOREIGN KEY([RDS_EUS_Proposal_ID])
REFERENCES [dbo].[T_EUS_Proposals] ([Proposal_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_EUS_Proposals]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_EUS_UsageType] FOREIGN KEY([RDS_EUS_UsageType])
REFERENCES [dbo].[T_EUS_UsageType] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_EUS_UsageType]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Experiments] FOREIGN KEY([Exp_ID])
REFERENCES [dbo].[T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Experiments]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_LC_Cart] FOREIGN KEY([RDS_Cart_ID])
REFERENCES [dbo].[T_LC_Cart] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_LC_Cart]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_LC_Cart_Configuration] FOREIGN KEY([RDS_Cart_Config_ID])
REFERENCES [dbo].[T_LC_Cart_Configuration] ([Cart_Config_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_LC_Cart_Configuration]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Material_Locations] FOREIGN KEY([Location_ID])
REFERENCES [dbo].[T_Material_Locations] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Material_Locations]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Requested_Run_Batches] FOREIGN KEY([RDS_BatchID])
REFERENCES [dbo].[T_Requested_Run_Batches] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Requested_Run_Batches]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Requested_Run_Queue_State] FOREIGN KEY([Queue_State])
REFERENCES [dbo].[T_Requested_Run_Queue_State] ([Queue_State])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Requested_Run_Queue_State]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Requested_Run_State_Name] FOREIGN KEY([RDS_Status])
REFERENCES [dbo].[T_Requested_Run_State_Name] ([State_Name])
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Requested_Run_State_Name]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Separation_Group] FOREIGN KEY([RDS_Sec_Sep])
REFERENCES [dbo].[T_Separation_Group] ([Sep_Group])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Separation_Group]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_T_Users] FOREIGN KEY([RDS_Requestor_PRN])
REFERENCES [dbo].[T_Users] ([U_PRN])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [FK_T_Requested_Run_T_Users]
GO
ALTER TABLE [dbo].[T_Requested_Run]  WITH CHECK ADD  CONSTRAINT [CK_T_Requested_Run_RequestedRunName_WhiteSpace] CHECK  (([dbo].[has_whitespace_chars]([RDS_Name],(0))=(0)))
GO
ALTER TABLE [dbo].[T_Requested_Run] CHECK CONSTRAINT [CK_T_Requested_Run_RequestedRunName_WhiteSpace]
GO
/****** Object:  Trigger [dbo].[trig_d_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_d_Requested_Run] on [dbo].[T_Requested_Run]
For Delete
/****************************************************
**
**  Desc:
**      Makes an entry in T_Event_Log for the deleted Requested Run
**
**  Auth:   mem
**  Date:   12/12/2011 mem - Initial version
**
*****************************************************/
AS
    Set NoCount On

    -- Add entries to T_Event_Log for each Requested Run deleted from T_Requested_Run
    INSERT INTO T_Event_Log (
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
ALTER TABLE [dbo].[T_Requested_Run] ENABLE TRIGGER [trig_d_Requested_Run]
GO
/****** Object:  Trigger [dbo].[trig_i_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_i_Requested_Run] on [dbo].[T_Requested_Run]
For Insert
/****************************************************
**
**  Desc:
**      Makes an entry in T_Event_Log for the new Requested Run
**
**  Auth:   mem
**  Date:   12/12/2011 mem - Initial version
**
*****************************************************/
AS
    If @@RowCount = 0
        Return

    Set NoCount On

    INSERT INTO T_Event_Log    (Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
    SELECT 11 AS Target_Type, inserted.ID, RRS.State_ID, 0, GetDate()
    FROM inserted
         INNER JOIN T_Requested_Run_State_Name RRS
           ON inserted.RDS_Status = RRS.State_Name
    ORDER BY inserted.ID

GO
ALTER TABLE [dbo].[T_Requested_Run] ENABLE TRIGGER [trig_i_Requested_Run]
GO
/****** Object:  Trigger [dbo].[trig_u_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_u_Requested_Run] on [dbo].[T_Requested_Run]
After Insert, Update
/****************************************************
**
**  Desc:
**      Updates various columns for new or updated requested run(s)
**
**  Auth:   mem
**  Date:   08/05/2010 mem - Initial version
**          08/10/2010 mem - Now passing dataset type and separation type to GetRequestedRunNameCode
**          12/12/2011 mem - Now updating T_Event_Log
**          06/27/2018 mem - Update the Updated column
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          10/20/2020 mem - Change Queue_State to 3 (Analyzed) if the requested run status is Completed
**          06/22/2022 mem - No longer pass the username of the batch owner to GetRequestedRunNameCode
**          08/01/2022 mem - Update column Updated_By
**          08/06/2022 mem - Only update RDS_NameCode if it has changed
**          08/16/2022 mem - Log renamed requested runs
**                         - Log dataset_id changes (ignoring change from null to a value)
**                         - Log exp_id changes
**                         - Log requested runs that have the same dataset_id
**          02/21/2023 mem - Pass batch group ID to get_requested_run_name_code
**
*****************************************************/
AS
    If @@RowCount = 0
        Return

    Set NoCount On

    If Update(RDS_Name) OR
       Update(RDS_Created) OR
       Update(RDS_Requestor_PRN) OR
       Update(RDS_BatchID) OR
       Update(RDS_NameCode) OR
       Update(RDS_Type_ID) OR
       Update(RDS_Sec_Sep)
    Begin
        UPDATE T_Requested_Run
        SET RDS_NameCode = dbo.get_requested_run_name_code(RR.RDS_Name, RR.RDS_Created, RR.RDS_Requestor_PRN,
                                                           RR.RDS_BatchID, RRB.Batch, RRB.Batch_Group_ID, RRB.Created,
                                                           RR.RDS_type_ID, RR.RDS_Sec_Sep)
        FROM T_Requested_Run RR
             INNER JOIN inserted
               ON RR.ID = inserted.ID
             LEFT OUTER JOIN T_Requested_Run_Batches RRB
               ON RRB.ID = RR.RDS_BatchID
        WHERE Coalesce(RR.RDS_NameCode, '') <> dbo.get_requested_run_name_code(RR.RDS_Name, RR.RDS_Created, RR.RDS_Requestor_PRN,
                                                                               RR.RDS_BatchID, RRB.Batch, RRB.Batch_Group_ID, RRB.Created,
                                                                               RR.RDS_type_ID, RR.RDS_Sec_Sep)
    End

    If Update(RDS_Status)
    Begin
        INSERT INTO T_Event_Log (Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
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

    UPDATE T_Requested_Run
    SET Updated = GetDate(),
        Queue_State = CASE WHEN inserted.RDS_Status = 'Completed' THEN 3 ELSE inserted.Queue_State End,
        Updated_By = Suser_Sname()      -- + ' from ' + HOST_NAME()
    FROM T_Requested_Run RR
         INNER JOIN inserted
           ON RR.ID = inserted.ID

    If Exists (SELECT * FROM deleted)
    Begin
        -- Update Trigger

        -- Check for renamed requested run
        If Update(RDS_Name)
        Begin
            INSERT INTO T_Entity_Rename_Log (Target_Type, Target_ID, Old_Name, New_Name)
            SELECT 11 AS Target_Type,
                   inserted.ID,
                   deleted.RDS_Name,
                   inserted.RDS_Name
            FROM deleted
                 INNER JOIN inserted
                   ON deleted.ID = inserted.ID
            WHERE deleted.RDS_Name <> inserted.RDS_Name
            ORDER BY inserted.ID
        End

        -- Check for updated Dataset ID (including changing to null)
        -- If changing from null to a value, log only if another requested run already has the given Dataset ID
        If Update(DatasetID)
        Begin
            INSERT INTO T_Entity_Rename_Log (Target_Type, Target_ID, Old_Name, New_Name)
            SELECT 14 AS Target_Type,
                   inserted.ID,
                   Cast(deleted.DatasetID AS varchar(12)) + ': ' + Coalesce(OldDataset.Dataset_Num, '??'),
                   CASE
                       WHEN inserted.DatasetID IS NULL THEN 'null'
                       ELSE Cast(inserted.DatasetID AS varchar(12)) + ': ' + Coalesce(NewDataset.Dataset_Num, '??')
                   END
            FROM deleted
                 INNER JOIN inserted
                   ON deleted.ID = inserted.ID
                 LEFT OUTER JOIN T_Dataset AS OldDataset
                   ON deleted.DatasetID = OldDataset.Dataset_ID
                 LEFT OUTER JOIN T_Dataset AS NewDataset
                   ON inserted.DatasetID = NewDataset.Dataset_ID
            WHERE NOT deleted.DatasetID IS Null AND deleted.DatasetID <> Coalesce(inserted.DatasetID, 0)
            ORDER BY inserted.ID
        End

        -- Check for updated Experiment ID
        If Update(Exp_ID)
        Begin
            INSERT INTO T_Entity_Rename_Log (Target_Type, Target_ID, Old_Name, New_Name)
            SELECT 15 AS Target_Type,
                   inserted.ID,
                   Cast(deleted.Exp_ID AS varchar(12)) + ': ' + OldExperiment.Experiment_Num,
                   Cast(inserted.Exp_ID AS varchar(12)) + ': ' + NewExperiment.Experiment_Num
            FROM deleted
                 INNER JOIN inserted
                   ON deleted.ID = inserted.ID
                 LEFT OUTER JOIN T_Experiments AS OldExperiment
                   ON deleted.Exp_ID = OldExperiment.Exp_ID
                 LEFT OUTER JOIN T_Experiments AS NewExperiment
                   ON inserted.Exp_ID = NewExperiment.Exp_ID
            WHERE deleted.Exp_ID <> inserted.Exp_ID
            ORDER BY inserted.ID
        End
    End

    If Update(DatasetID)
    Begin
        -- Check whether another requested run already has the new Dataset ID
        INSERT INTO T_Entity_Rename_Log (Target_Type, Target_ID, Old_Name, New_Name)
        SELECT 14 AS Target_Type,
               inserted.ID,
               'Dataset ID ' + Cast(inserted.DatasetID AS varchar(12)) + ' is already referenced by Request ID ' + Cast(RR.ID As varchar(12)),
               Cast(inserted.DatasetID AS varchar(12)) + ': ' + Coalesce(NewDataset.Dataset_Num, '??')
        FROM T_Requested_Run RR
             INNER JOIN inserted
                ON inserted.DatasetID = RR.DatasetID AND
                   inserted.ID <> RR.ID
             LEFT OUTER JOIN T_Dataset AS NewDataset
                ON inserted.DatasetID = NewDataset.Dataset_ID
        WHERE Not inserted.DatasetID Is Null
        ORDER BY inserted.DatasetID, RR.ID

    End

GO
ALTER TABLE [dbo].[T_Requested_Run] ENABLE TRIGGER [trig_u_Requested_Run]
GO
